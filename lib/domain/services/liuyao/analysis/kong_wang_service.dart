import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';
import 'wang_shuai_service.dart';

/// 空亡状态分析。
///
/// 覆盖：旬空、真空、假空（动不为空/旺不为空）、冲空。
/// 填实、出空为未来事件，由应期服务推算。
/// 规则依据《增删卜易》：旬空之爻，旺相不为空、动不为空；
/// 唯休囚安静之空为真空，到底不能用。
class KongWangService {
  KongWangService._();

  static List<YaoAnalysisTag> analyzeYao(
      Yao yao, Gua gua, LunarInfo lunarInfo) {
    if (!lunarInfo.isKongWang(yao.branch)) return const [];

    final tags = <YaoAnalysisTag>[
      YaoAnalysisTag(
        term: '旬空',
        category: TagCategory.kongWang,
        polarity: Polarity.neutral,
        priority: 5,
        reason: '${lunarInfo.riGanZhi}旬中${yao.branch}空亡',
      ),
    ];

    if (yao.isMoving) {
      tags.add(YaoAnalysisTag(
        term: '假空',
        category: TagCategory.kongWang,
        polarity: Polarity.neutral,
        priority: 15,
        reason: '动不为空，出空之日可用',
      ));
    } else if (WangShuaiService.isWangXiang(yao, lunarInfo)) {
      tags.add(YaoAnalysisTag(
        term: '假空',
        category: TagCategory.kongWang,
        polarity: Polarity.neutral,
        priority: 15,
        reason: '旺不为空，出空之日可用',
      ));
    } else {
      tags.add(YaoAnalysisTag(
        term: '真空',
        category: TagCategory.kongWang,
        polarity: Polarity.xiong,
        priority: 3,
        reason: '休囚安静逢空，到底无用',
      ));
    }

    if (DiZhiRelations.isLiuChong(lunarInfo.riZhi, yao.branch)) {
      tags.add(YaoAnalysisTag(
        term: '冲空',
        category: TagCategory.kongWang,
        polarity: Polarity.ji,
        priority: 14,
        reason: '日辰${lunarInfo.riZhi}冲空爻${yao.branch}，冲空则起',
      ));
    }

    return tags;
  }
}
