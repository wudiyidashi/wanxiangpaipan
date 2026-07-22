import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import 'models/analysis_tag.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';

/// 墓绝状态分析。
///
/// 覆盖：入日墓、入月墓、入动墓、出墓、临绝。
/// 化墓（入变墓）、化绝属动爻变化，由 DongBianService 判定。
/// 规则依据《增删卜易》：随鬼入墓与动爻用神入墓最凶，冲墓之日为出墓。
class MuJueService {
  MuJueService._();

  static List<YaoAnalysisTag> analyzeYao(
      Yao yao, Gua gua, LunarInfo lunarInfo) {
    final tags = <YaoAnalysisTag>[];
    final muBranch = ChangShengTable.getMuBranch(yao.wuXing);
    final jueBranch = ChangShengTable.getJueBranch(yao.wuXing);
    var inMu = false;

    if (lunarInfo.riZhi == muBranch) {
      inMu = true;
      tags.add(YaoAnalysisTag(
        term: '入日墓',
        category: TagCategory.muJue,
        polarity: Polarity.xiong,
        priority: 20,
        reason: '${yao.wuXing.name}墓于$muBranch，日辰即墓库',
      ));
    }
    if (lunarInfo.yueJian == muBranch) {
      inMu = true;
      tags.add(YaoAnalysisTag(
        term: '入月墓',
        category: TagCategory.muJue,
        polarity: Polarity.xiong,
        priority: 21,
        reason: '${yao.wuXing.name}墓于$muBranch，月建即墓库',
      ));
    }

    for (final other in gua.yaos) {
      if (other.position == yao.position) continue;
      if (other.isMoving && other.branch == muBranch) {
        inMu = true;
        tags.add(YaoAnalysisTag(
          term: '入动墓',
          category: TagCategory.muJue,
          polarity: Polarity.xiong,
          priority: 22,
          reason: '${other.position}爻$muBranch发动，${yao.wuXing.name}随之入墓',
          relatedYao: [other.position],
        ));
        break;
      }
    }

    // 入墓而日辰冲开墓库为出墓（日辰本身为墓库时不冲）
    if (inMu &&
        lunarInfo.riZhi != muBranch &&
        DiZhiRelations.isLiuChong(lunarInfo.riZhi, muBranch)) {
      tags.add(YaoAnalysisTag(
        term: '出墓',
        category: TagCategory.muJue,
        polarity: Polarity.ji,
        priority: 16,
        reason: '日辰${lunarInfo.riZhi}冲开墓库$muBranch',
      ));
    }

    if (lunarInfo.riZhi == jueBranch || lunarInfo.yueJian == jueBranch) {
      final source = lunarInfo.riZhi == jueBranch ? '日辰' : '月建';
      tags.add(YaoAnalysisTag(
        term: '临绝',
        category: TagCategory.muJue,
        polarity: Polarity.xiong,
        priority: 23,
        reason: '${yao.wuXing.name}绝于$jueBranch，$source即绝地',
      ));
    }

    return tags;
  }
}
