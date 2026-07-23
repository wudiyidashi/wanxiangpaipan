import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/tiangan_dizhi_service.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';

/// 日月太岁对爻的特殊作用。
///
/// 覆盖：日合、月合、太岁入爻。
/// 日月入爻即临日建/临月建（旺衰服务），日月冲爻即月破与暗动/日破
/// （旺衰与动变服务），三合成局见合冲服务，此处不重复标注。
/// 规则依据《增删卜易》：日月合静爻为合起，合动爻为合绊。
class SpecialService {
  SpecialService._();

  static List<YaoAnalysisTag> analyzeYao(Yao yao, LunarInfo lunarInfo) {
    final tags = <YaoAnalysisTag>[];

    void addHe(String term, String source, String zhi, int priority) {
      if (!DiZhiRelations.isLiuHe(zhi, yao.branch)) return;
      final effect = yao.isMoving ? '合绊动爻' : '合起静爻';
      tags.add(YaoAnalysisTag(
        term: term,
        category: TagCategory.special,
        polarity: yao.isMoving ? Polarity.neutral : Polarity.ji,
        priority: priority,
        reason: '$source$zhi合${yao.branch}，$effect',
      ));
    }

    addHe('日合', '日辰', lunarInfo.riZhi, 22);
    addHe('月合', '月建', lunarInfo.yueJian, 23);

    final taiSui = TianGanDiZhiService.splitGanZhi(lunarInfo.yearGanZhi)?.last;
    if (taiSui == yao.branch) {
      tags.add(YaoAnalysisTag(
        term: '太岁入爻',
        category: TagCategory.special,
        polarity: Polarity.neutral,
        priority: 28,
        reason: '爻支${yao.branch}临太岁，事关久远或官事',
      ));
    }

    return tags;
  }
}
