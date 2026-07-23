import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../fushen_service.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';

/// 伏藏飞神关系分析。
///
/// 覆盖：飞生伏、飞克伏、伏生飞、伏克飞、伏神得出、伏神受制。
/// 标签挂在飞神所在爻位上。规则依据《增删卜易》：飞来生伏得长生，
/// 伏克飞神为出暴；飞神空破或被日冲则伏神得出，飞克伏又逢日月克则受制。
class FuShenRelationService {
  FuShenRelationService._();

  static Map<int, List<YaoAnalysisTag>> analyzeGua(
      Gua gua, LunarInfo lunarInfo) {
    final result = <int, List<YaoAnalysisTag>>{};
    final fuShenMap = FuShenService.calculateFuShen(gua);

    fuShenMap.forEach((position, fuShen) {
      final fei = gua.yaos[position - 1];
      final tags = analyzeFuShen(fei, fuShen.yao, lunarInfo);
      if (tags.isNotEmpty) result[position] = tags;
    });
    return result;
  }

  /// 单组飞伏关系分析；[fei] 为本卦飞神爻，[fu] 为伏神爻
  static List<YaoAnalysisTag> analyzeFuShen(
      Yao fei, Yao fu, LunarInfo lunarInfo) {
    final tags = <YaoAnalysisTag>[];
    final fuDesc = '${fu.liuQin.name}${fu.branch}${fu.wuXing.name}';
    var feiKeFu = false;

    if (WuXingService.isSheng(fei.wuXing, fu.wuXing)) {
      tags.add(_tag('飞生伏', Polarity.ji, 30, '飞神${fei.branch}生伏神$fuDesc，伏神得长生'));
    } else if (WuXingService.isKe(fei.wuXing, fu.wuXing)) {
      feiKeFu = true;
      tags.add(
          _tag('飞克伏', Polarity.xiong, 30, '飞神${fei.branch}克伏神$fuDesc，伏神受压'));
    } else if (WuXingService.isSheng(fu.wuXing, fei.wuXing)) {
      tags.add(
          _tag('伏生飞', Polarity.xiong, 31, '伏神$fuDesc生飞神${fei.branch}，伏神泄气'));
    } else if (WuXingService.isKe(fu.wuXing, fei.wuXing)) {
      tags.add(
          _tag('伏克飞', Polarity.ji, 31, '伏神$fuDesc克飞神${fei.branch}，伏神出暴有力'));
    }

    // 飞神空亡或被日冲，伏神得出
    if (lunarInfo.isKongWang(fei.branch) ||
        DiZhiRelations.isLiuChong(lunarInfo.riZhi, fei.branch)) {
      tags.add(
          _tag('伏神得出', Polarity.ji, 25, '飞神${fei.branch}空破被冲，伏神$fuDesc得出而有用'));
    }

    // 飞克伏且日月再克伏神：受制无用
    final riWuXing = WuXingService.getWuXingFromBranch(lunarInfo.riZhi)!;
    final yueWuXing = WuXingService.getWuXingFromBranch(lunarInfo.yueJian)!;
    if (feiKeFu &&
        (WuXingService.isKe(riWuXing, fu.wuXing) ||
            WuXingService.isKe(yueWuXing, fu.wuXing))) {
      tags.add(_tag('伏神受制', Polarity.xiong, 25, '伏神$fuDesc既被飞神克又遭日月克，受制难出'));
    }

    return tags;
  }

  static YaoAnalysisTag _tag(
      String term, Polarity polarity, int priority, String reason) {
    return YaoAnalysisTag(
      term: term,
      category: TagCategory.fuShen,
      polarity: polarity,
      priority: priority,
      reason: reason,
    );
  }
}
