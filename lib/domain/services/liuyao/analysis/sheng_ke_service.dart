import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';

/// 爻间生克与贪生贪合分析。
///
/// 覆盖：动爻生、动爻克、动爻扶（拱）、贪生忘克、贪合忘生、贪合忘克、
/// 连续相生、连续相克。
/// 规则依据《增删卜易》：静不生克，动方能作用；动爻遇可生之动爻则
/// 贪生忘克；动爻被合住则忘生忘克；泄、耗、制、化等表述见术语词典。
class ShengKeService {
  ShengKeService._();

  static Map<int, List<YaoAnalysisTag>> analyzeGua(
      Gua gua, LunarInfo lunarInfo) {
    final result = <int, List<YaoAnalysisTag>>{};
    final moving = gua.movingYaos;
    if (moving.isEmpty) return result;

    void add(int position, YaoAnalysisTag tag) {
      result.putIfAbsent(position, () => []).add(tag);
    }

    for (final m in moving) {
      final hePartner = _hePartnerOf(m, gua, lunarInfo);
      // 贪生对象：另一动爻为本动爻所生
      final tanSheng = moving
          .where((s) =>
              s.position != m.position &&
              WuXingService.isSheng(m.wuXing, s.wuXing))
          .toList();

      for (final t in gua.yaos) {
        if (t.position == m.position) continue;
        if (WuXingService.isSheng(m.wuXing, t.wuXing)) {
          if (hePartner != null) {
            add(t.position, YaoAnalysisTag(
              term: '贪合忘生',
              category: TagCategory.shengKe,
              polarity: Polarity.neutral,
              priority: 34,
              reason: '${m.position}爻${m.branch}被$hePartner合住，忘生本爻',
              relatedYao: [m.position],
            ));
          } else {
            add(t.position, YaoAnalysisTag(
              term: '动爻生',
              category: TagCategory.shengKe,
              polarity: Polarity.ji,
              priority: 38,
              reason: '${m.position}爻${m.branch}动来生本爻',
              relatedYao: [m.position],
            ));
          }
        } else if (WuXingService.isKe(m.wuXing, t.wuXing)) {
          if (hePartner != null) {
            add(t.position, YaoAnalysisTag(
              term: '贪合忘克',
              category: TagCategory.shengKe,
              polarity: Polarity.ji,
              priority: 34,
              reason: '${m.position}爻${m.branch}被$hePartner合住，忘克本爻',
              relatedYao: [m.position],
            ));
          } else if (tanSheng.isNotEmpty) {
            add(t.position, YaoAnalysisTag(
              term: '贪生忘克',
              category: TagCategory.shengKe,
              polarity: Polarity.ji,
              priority: 21,
              reason:
                  '${m.position}爻${m.branch}贪生${tanSheng.first.position}爻'
                  '${tanSheng.first.branch}，忘克本爻',
              relatedYao: [m.position, tanSheng.first.position],
            ));
          } else {
            add(t.position, YaoAnalysisTag(
              term: '动爻克',
              category: TagCategory.shengKe,
              polarity: Polarity.xiong,
              priority: 37,
              reason: '${m.position}爻${m.branch}动来克本爻',
              relatedYao: [m.position],
            ));
          }
        } else if (m.wuXing == t.wuXing && hePartner == null) {
          add(t.position, YaoAnalysisTag(
            term: '动爻扶',
            category: TagCategory.shengKe,
            polarity: Polarity.ji,
            priority: 39,
            reason: '${m.position}爻${m.branch}动来拱扶本爻',
            relatedYao: [m.position],
          ));
        }
      }
    }

    _analyzeChains(moving, add);
    return result;
  }

  /// 动爻的合住来源：他爻六合或日辰相合；无则返回 null
  static String? _hePartnerOf(Yao m, Gua gua, LunarInfo lunarInfo) {
    for (final o in gua.yaos) {
      if (o.position != m.position &&
          DiZhiRelations.isLiuHe(m.branch, o.branch)) {
        return '${o.position}爻${o.branch}';
      }
    }
    if (DiZhiRelations.isLiuHe(lunarInfo.riZhi, m.branch)) {
      return '日辰${lunarInfo.riZhi}';
    }
    return null;
  }

  /// 三个及以上动爻递相生/克成链
  static void _analyzeChains(
      List<Yao> moving, void Function(int, YaoAnalysisTag) add) {
    if (moving.length < 3) return;

    final shengMembers = <int, List<int>>{};
    final keMembers = <int, List<int>>{};

    for (final a in moving) {
      for (final b in moving) {
        for (final c in moving) {
          if (a.position == b.position ||
              b.position == c.position ||
              a.position == c.position) {
            continue;
          }
          final positions = [a.position, b.position, c.position];
          if (WuXingService.isSheng(a.wuXing, b.wuXing) &&
              WuXingService.isSheng(b.wuXing, c.wuXing)) {
            for (final p in positions) {
              shengMembers
                  .putIfAbsent(p, () => [])
                  .addAll(positions.where((x) => x != p));
            }
          }
          if (WuXingService.isKe(a.wuXing, b.wuXing) &&
              WuXingService.isKe(b.wuXing, c.wuXing)) {
            for (final p in positions) {
              keMembers
                  .putIfAbsent(p, () => [])
                  .addAll(positions.where((x) => x != p));
            }
          }
        }
      }
    }

    shengMembers.forEach((position, related) {
      add(position, YaoAnalysisTag(
        term: '连续相生',
        category: TagCategory.shengKe,
        polarity: Polarity.ji,
        priority: 13,
        reason: '动爻递相生，气脉相连',
        relatedYao: related.toSet().toList()..sort(),
      ));
    });
    keMembers.forEach((position, related) {
      add(position, YaoAnalysisTag(
        term: '连续相克',
        category: TagCategory.shengKe,
        polarity: Polarity.xiong,
        priority: 13,
        reason: '动爻递相克，祸患相连',
        relatedYao: related.toSet().toList()..sort(),
      ));
    });
  }
}
