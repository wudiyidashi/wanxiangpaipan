import '../../../../divination_systems/liuyao/models/gua.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';

/// 卦象整体变化分析（卦级标签）。
///
/// 覆盖：六冲卦、六合卦、游魂卦、归魂卦、卦变六合、卦变六冲、伏吟、反吟。
/// 伏吟：动卦内/外卦变后纳支不变；反吟：变后纳支逐位相冲。
/// 规则依据《增删卜易》。
class GuaChangeService {
  GuaChangeService._();

  static List<YaoAnalysisTag> analyzeGua(Gua mainGua, Gua? changingGua) {
    final tags = <YaoAnalysisTag>[];

    switch (mainGua.specialType) {
      case GuaSpecialType.liuChong:
        tags.add(_guaTag('六冲卦', Polarity.neutral, 9, '本卦六爻逐位相冲，主散、主快'));
      case GuaSpecialType.liuHe:
        tags.add(_guaTag('六合卦', Polarity.ji, 9, '本卦六爻逐位相合，主成、主缓'));
      case GuaSpecialType.youHun:
        tags.add(_guaTag('游魂卦', Polarity.neutral, 29, '游魂主心神不定、行走他乡'));
      case GuaSpecialType.guiHun:
        tags.add(_guaTag('归魂卦', Polarity.neutral, 29, '归魂主返本还原、事归故处'));
      case GuaSpecialType.none:
        break;
    }

    if (changingGua == null) return tags;

    switch (changingGua.specialType) {
      case GuaSpecialType.liuHe:
        tags.add(_guaTag('卦变六合', Polarity.ji, 12, '变卦六合，事渐入佳境而成'));
      case GuaSpecialType.liuChong:
        tags.add(_guaTag('卦变六冲', Polarity.xiong, 12, '变卦六冲，事将散乱不终'));
      default:
        break;
    }

    for (final half in const [(1, '内卦'), (4, '外卦')]) {
      final (start, label) = half;
      final mainHalf = mainGua.yaos.sublist(start - 1, start + 2);
      if (!mainHalf.any((y) => y.isMoving)) continue;
      final changedHalf = changingGua.yaos.sublist(start - 1, start + 2);

      final allSame =
          List.generate(3, (i) => mainHalf[i].branch == changedHalf[i].branch)
              .every((x) => x);
      final allChong = List.generate(
          3,
          (i) => DiZhiRelations.isLiuChong(
              mainHalf[i].branch, changedHalf[i].branch)).every((x) => x);

      if (allSame) {
        tags.add(_guaTag('伏吟', Polarity.xiong, 7, '$label变后纳支不变，伏吟呻吟，主忧虑迁延'));
      } else if (allChong) {
        tags.add(_guaTag('反吟', Polarity.xiong, 7, '$label变后纳支逐位相冲，反吟反复，主往复不宁'));
      }
    }

    return tags;
  }

  static YaoAnalysisTag _guaTag(
      String term, Polarity polarity, int priority, String reason) {
    return YaoAnalysisTag(
      term: term,
      category: TagCategory.guaChange,
      polarity: polarity,
      priority: priority,
      reason: reason,
    );
  }
}
