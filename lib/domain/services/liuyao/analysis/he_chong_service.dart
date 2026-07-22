import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';

/// 爻间合冲刑害分析。
///
/// 覆盖：合住、合起、合绊、冲开、相冲、三合局、三合成局（借日月）、
/// 半合、相刑、相害。
/// 规则依据《增删卜易》：静爻之间不论生克合冲，动方能作用；
/// 三刑、相害按《卜筮正宗》补充，仅作低优先级参考。
/// 日月对单爻的合冲（合起/冲起等日辰作用）由其他服务判定。
class HeChongService {
  HeChongService._();

  static Map<int, List<YaoAnalysisTag>> analyzeGua(
      Gua gua, LunarInfo lunarInfo) {
    final result = <int, List<YaoAnalysisTag>>{
      for (final yao in gua.yaos) yao.position: <YaoAnalysisTag>[],
    };

    _analyzePairs(gua, lunarInfo, result);
    _analyzeSanHe(gua, lunarInfo, result);

    result.removeWhere((_, tags) => tags.isEmpty);
    return result;
  }

  static void _analyzePairs(
    Gua gua,
    LunarInfo lunarInfo,
    Map<int, List<YaoAnalysisTag>> result,
  ) {
    for (var i = 0; i < gua.yaos.length; i++) {
      for (var j = i + 1; j < gua.yaos.length; j++) {
        final a = gua.yaos[i];
        final b = gua.yaos[j];
        // 静爻之间不发生作用
        if (!a.isMoving && !b.isMoving) continue;

        if (DiZhiRelations.isLiuHe(a.branch, b.branch)) {
          _addHePair(a, b, lunarInfo, result);
        }
        if (DiZhiRelations.isLiuChong(a.branch, b.branch)) {
          _addPair(result, a, b, '相冲', Polarity.neutral, 28,
              '${a.branch}${b.branch}相冲');
        }
        if (DiZhiRelations.isXing(a.branch, b.branch)) {
          _addPair(result, a, b, '相刑', Polarity.xiong, 45,
              '${a.branch}${b.branch}相刑');
        }
        if (DiZhiRelations.isHai(a.branch, b.branch)) {
          _addPair(result, a, b, '相害', Polarity.xiong, 46,
              '${a.branch}${b.branch}相害');
        }
      }
    }
  }

  static void _addHePair(
    Yao a,
    Yao b,
    LunarInfo lunarInfo,
    Map<int, List<YaoAnalysisTag>> result,
  ) {
    final reason = '${a.branch}${b.branch}六合';
    if (a.isMoving && b.isMoving) {
      _addPair(result, a, b, '合绊', Polarity.neutral, 26, '$reason，两动相合互绊');
    } else {
      final moving = a.isMoving ? a : b;
      final still = a.isMoving ? b : a;
      result[moving.position]!.add(YaoAnalysisTag(
        term: '合住',
        category: TagCategory.heChong,
        polarity: Polarity.neutral,
        priority: 26,
        reason: '$reason，动爻被合住',
        relatedYao: [still.position],
      ));
      result[still.position]!.add(YaoAnalysisTag(
        term: '合起',
        category: TagCategory.heChong,
        polarity: Polarity.ji,
        priority: 26,
        reason: '$reason，静爻被合起',
        relatedYao: [moving.position],
      ));
    }
    // 合处逢冲：日辰冲合中任一支则合解
    if (DiZhiRelations.isLiuChong(lunarInfo.riZhi, a.branch) ||
        DiZhiRelations.isLiuChong(lunarInfo.riZhi, b.branch)) {
      _addPair(result, a, b, '冲开', Polarity.neutral, 15,
          '日辰${lunarInfo.riZhi}冲开$reason');
    }
  }

  static void _analyzeSanHe(
    Gua gua,
    LunarInfo lunarInfo,
    Map<int, List<YaoAnalysisTag>> result,
  ) {
    final yaos = gua.yaos;
    final claimed = <int>{};

    // 卦内三爻成局：三支齐备且至少两爻动
    for (var i = 0; i < yaos.length; i++) {
      for (var j = i + 1; j < yaos.length; j++) {
        for (var k = j + 1; k < yaos.length; k++) {
          final trio = [yaos[i], yaos[j], yaos[k]];
          final element = DiZhiRelations.getSanHeElement(
              trio[0].branch, trio[1].branch, trio[2].branch);
          if (element == null) continue;
          if (trio.where((y) => y.isMoving).length < 2) continue;
          final positions = trio.map((y) => y.position).toList();
          for (final yao in trio) {
            result[yao.position]!.add(YaoAnalysisTag(
              term: '三合局',
              category: TagCategory.heChong,
              polarity: Polarity.ji,
              priority: 11,
              reason:
                  '${trio.map((y) => y.branch).join()}三合${element.name}局',
              relatedYao:
                  positions.where((p) => p != yao.position).toList(),
            ));
            claimed.add(yao.position);
          }
        }
      }
    }

    // 两动爻借日辰/月建凑局，或含旺支半合
    for (var i = 0; i < yaos.length; i++) {
      for (var j = i + 1; j < yaos.length; j++) {
        final a = yaos[i];
        final b = yaos[j];
        if (!a.isMoving || !b.isMoving) continue;
        if (claimed.contains(a.position) || claimed.contains(b.position)) {
          continue;
        }
        for (final outer in [lunarInfo.riZhi, lunarInfo.yueJian]) {
          final element =
              DiZhiRelations.getSanHeElement(a.branch, b.branch, outer);
          if (element != null) {
            final source = outer == lunarInfo.riZhi ? '日辰' : '月建';
            _addPair(result, a, b, '三合成局', Polarity.ji, 11,
                '${a.branch}${b.branch}借$source$outer三合${element.name}局');
            claimed.addAll([a.position, b.position]);
            break;
          }
        }
        if (claimed.contains(a.position)) continue;
        final banHe = DiZhiRelations.getBanHeElement(a.branch, b.branch);
        if (banHe != null) {
          _addPair(result, a, b, '半合', Polarity.ji, 27,
              '${a.branch}${b.branch}半合${banHe.name}局');
        }
      }
    }
  }

  static void _addPair(
    Map<int, List<YaoAnalysisTag>> result,
    Yao a,
    Yao b,
    String term,
    Polarity polarity,
    int priority,
    String reason,
  ) {
    result[a.position]!.add(YaoAnalysisTag(
      term: term,
      category: TagCategory.heChong,
      polarity: polarity,
      priority: priority,
      reason: reason,
      relatedYao: [b.position],
    ));
    result[b.position]!.add(YaoAnalysisTag(
      term: term,
      category: TagCategory.heChong,
      polarity: polarity,
      priority: priority,
      reason: reason,
      relatedYao: [a.position],
    ));
  }
}
