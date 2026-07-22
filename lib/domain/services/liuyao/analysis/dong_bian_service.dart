import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_tag.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';
import 'wang_shuai_service.dart';

/// 动静与动爻变化分析。
///
/// 覆盖：暗动、日破、冲散、独发、独静、化进神、化退神、回头生、回头克、
/// 化泄、化空、化破、化墓、化绝、化合、化冲。
/// 规则依据《增删卜易》：旺相静爻逢日冲为暗动，休囚静爻逢日冲为日破，
/// 休囚动爻逢日冲为冲散，旺相动爻冲之不散；旬空之爻逢冲论冲空不论暗动。
/// 化扶不单独标注（同五行必构成进神或退神，词典中说明）。
class DongBianService {
  DongBianService._();

  /// 进神对：变支为本支同五行顺行
  static const Map<String, String> jinShen = {
    '寅': '卯', '巳': '午', '申': '酉', '亥': '子',
    '丑': '辰', '辰': '未', '未': '戌', '戌': '丑',
  };

  static Map<int, List<YaoAnalysisTag>> analyzeGua(
      Gua gua, Gua? changingGua, LunarInfo lunarInfo) {
    final result = <int, List<YaoAnalysisTag>>{};
    final movingCount = gua.movingYaos.length;

    for (final yao in gua.yaos) {
      final tags = <YaoAnalysisTag>[];

      tags.addAll(_analyzeRiChong(yao, lunarInfo));

      if (movingCount == 1 && yao.isMoving) {
        tags.add(YaoAnalysisTag(
          term: '独发',
          category: TagCategory.dongBian,
          polarity: Polarity.neutral,
          priority: 18,
          reason: '六爻唯此爻独动，事应专一',
        ));
      }
      if (movingCount == 5 && !yao.isMoving) {
        tags.add(YaoAnalysisTag(
          term: '独静',
          category: TagCategory.dongBian,
          polarity: Polarity.neutral,
          priority: 18,
          reason: '五爻皆动唯此爻独静',
        ));
      }

      if (yao.isMoving && changingGua != null) {
        tags.addAll(analyzeTransform(
            yao, changingGua.yaos[yao.position - 1], lunarInfo));
      }

      if (tags.isNotEmpty) result[yao.position] = tags;
    }
    return result;
  }

  /// 日冲的定性：暗动 / 日破 / 冲散。旬空之爻不在此论（由空亡服务判定冲空）。
  static List<YaoAnalysisTag> _analyzeRiChong(Yao yao, LunarInfo lunarInfo) {
    if (!DiZhiRelations.isLiuChong(lunarInfo.riZhi, yao.branch)) {
      return const [];
    }
    if (lunarInfo.isKongWang(yao.branch)) return const [];

    final wangXiang = WangShuaiService.isWangXiang(yao, lunarInfo);
    if (!yao.isMoving) {
      if (wangXiang) {
        return [
          YaoAnalysisTag(
            term: '暗动',
            category: TagCategory.dongBian,
            polarity: Polarity.neutral,
            priority: 10,
            reason: '旺相静爻逢日辰${lunarInfo.riZhi}冲，冲起暗动',
          ),
        ];
      }
      return [
        YaoAnalysisTag(
          term: '日破',
          category: TagCategory.dongBian,
          polarity: Polarity.xiong,
          priority: 4,
          reason: '休囚静爻逢日辰${lunarInfo.riZhi}冲，日破冲散',
        ),
      ];
    }
    if (!wangXiang) {
      return [
        YaoAnalysisTag(
          term: '冲散',
          category: TagCategory.dongBian,
          polarity: Polarity.xiong,
          priority: 8,
          reason: '休囚动爻逢日辰${lunarInfo.riZhi}冲散',
        ),
      ];
    }
    return const []; // 旺相动爻冲之不散
  }

  /// 动爻与其化出变爻的变化标签
  static List<YaoAnalysisTag> analyzeTransform(
      Yao original, Yao changed, LunarInfo lunarInfo) {
    if (original.branch == changed.branch) return const []; // 爻伏吟，卦级判定

    final tags = <YaoAnalysisTag>[];
    final from = original.branch;
    final to = changed.branch;

    if (original.wuXing == changed.wuXing) {
      if (jinShen[from] == to) {
        tags.add(YaoAnalysisTag(
          term: '化进神',
          category: TagCategory.dongBian,
          polarity: Polarity.ji,
          priority: 17,
          reason: '$from化$to，同气顺行为进',
        ));
      } else if (jinShen[to] == from) {
        tags.add(YaoAnalysisTag(
          term: '化退神',
          category: TagCategory.dongBian,
          polarity: Polarity.xiong,
          priority: 17,
          reason: '$from化$to，同气逆行为退',
        ));
      }
    } else {
      if (WuXingService.isSheng(changed.wuXing, original.wuXing)) {
        tags.add(YaoAnalysisTag(
          term: '回头生',
          category: TagCategory.dongBian,
          polarity: Polarity.ji,
          priority: 19,
          reason: '变爻${changed.wuXing.name}回头生${original.wuXing.name}',
        ));
      } else if (WuXingService.isKe(changed.wuXing, original.wuXing)) {
        tags.add(YaoAnalysisTag(
          term: '回头克',
          category: TagCategory.dongBian,
          polarity: Polarity.xiong,
          priority: 6,
          reason: '变爻${changed.wuXing.name}回头克${original.wuXing.name}',
        ));
      } else if (WuXingService.isSheng(original.wuXing, changed.wuXing)) {
        tags.add(YaoAnalysisTag(
          term: '化泄',
          category: TagCategory.dongBian,
          polarity: Polarity.xiong,
          priority: 27,
          reason: '本爻${original.wuXing.name}生变爻${changed.wuXing.name}，泄气',
        ));
      }
    }

    if (lunarInfo.isKongWang(to)) {
      tags.add(YaoAnalysisTag(
        term: '化空',
        category: TagCategory.dongBian,
        polarity: Polarity.neutral,
        priority: 24,
        reason: '变爻$to旬空，出空之日应之',
      ));
    }
    if (DiZhiRelations.isLiuChong(lunarInfo.yueJian, to)) {
      tags.add(YaoAnalysisTag(
        term: '化破',
        category: TagCategory.dongBian,
        polarity: Polarity.xiong,
        priority: 25,
        reason: '变爻$to逢月建${lunarInfo.yueJian}冲破',
      ));
    }
    if (to == ChangShengTable.getMuBranch(original.wuXing)) {
      tags.add(YaoAnalysisTag(
        term: '化墓',
        category: TagCategory.dongBian,
        polarity: Polarity.xiong,
        priority: 24,
        reason: '${original.wuXing.name}墓于$to，动而化墓',
      ));
    }
    if (to == ChangShengTable.getJueBranch(original.wuXing)) {
      tags.add(YaoAnalysisTag(
        term: '化绝',
        category: TagCategory.dongBian,
        polarity: Polarity.xiong,
        priority: 24,
        reason: '${original.wuXing.name}绝于$to，动而化绝',
      ));
    }
    if (DiZhiRelations.isLiuHe(from, to)) {
      tags.add(YaoAnalysisTag(
        term: '化合',
        category: TagCategory.dongBian,
        polarity: Polarity.neutral,
        priority: 26,
        reason: '$from与变爻$to六合，回头合住',
      ));
    }
    if (DiZhiRelations.isLiuChong(from, to)) {
      tags.add(YaoAnalysisTag(
        term: '化冲',
        category: TagCategory.dongBian,
        polarity: Polarity.xiong,
        priority: 26,
        reason: '$from与变爻$to六冲',
      ));
    }

    return tags;
  }
}
