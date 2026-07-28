import '../../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../../divination_systems/daliuren/models/chuan.dart';
import '../../../../divination_systems/daliuren/models/dlr_rule_contract.dart';
import '../../../../divination_systems/daliuren/models/san_chuan.dart';
import '../../shared/analysis/models/polarity.dart';
import '../../shared/wuxing_service.dart';
import 'models/daliuren_analysis_models.dart';

/// 三传结构分析服务（纯静态函数）。
///
/// 产出每传标签（空亡/天将/发用生克身）与课局级标签
/// （递生递克/传归/三合局）。措辞为本项目约定（大六壬断课 v1）。
class ChuanAnalysisService {
  ChuanAnalysisService._();

  /// 吉将：贵人、六合、青龙、太常、太阴、天后
  static const Set<ShenJiang> _jiJiang = {
    ShenJiang.guiRen,
    ShenJiang.liuHe,
    ShenJiang.qingLong,
    ShenJiang.taiChang,
    ShenJiang.taiYin,
    ShenJiang.tianHou,
  };

  /// 每传标签（挂 chuanTags）
  static Map<ChuanPosition, List<DlrAnalysisTag>> analyzeChuanTags({
    required SanChuan sanChuan,
    required String riGan,
  }) {
    final tags = <ChuanPosition, List<DlrAnalysisTag>>{
      for (final position in ChuanPosition.values) position: <DlrAnalysisTag>[],
    };

    for (final chuan in sanChuan.allChuan) {
      // 传空亡
      if (chuan.isKongWang) {
        tags[chuan.position]!.add(switch (chuan.position) {
          ChuanPosition.chu => DlrAnalysisTag(
              ruleRef: DlrRuleRef.project(
                DlrProjectRuleIds.initialTransmissionVoid,
              ),
              term: '发用落空',
              category: DlrTagCategory.kongWang,
              polarity: Polarity.xiong,
              priority: 1,
              reason: '初传${chuan.diZhi}落旬空，事起无力，待${chuan.diZhi}填实',
              relatedPositions: const ['初传'],
            ),
          ChuanPosition.zhong => DlrAnalysisTag(
              ruleRef: DlrRuleRef.project(
                DlrProjectRuleIds.middleTransmissionVoid,
              ),
              term: '中传落空',
              category: DlrTagCategory.kongWang,
              polarity: Polarity.xiong,
              priority: 1,
              reason: '中传${chuan.diZhi}落旬空，过程有断',
              relatedPositions: const ['中传'],
            ),
          ChuanPosition.mo => DlrAnalysisTag(
              ruleRef: DlrRuleRef.project(
                DlrProjectRuleIds.finalTransmissionVoid,
              ),
              term: '末传落空',
              category: DlrTagCategory.kongWang,
              polarity: Polarity.xiong,
              priority: 1,
              reason: '末传${chuan.diZhi}落旬空，结果易虚，待${chuan.diZhi}填实',
              relatedPositions: const ['末传'],
            ),
        });
      }

      // 天将吉凶
      final jiangJi = _jiJiang.contains(chuan.chengShen);
      tags[chuan.position]!.add(DlrAnalysisTag(
        ruleRef:
            DlrRuleRef.project(DlrProjectRuleIds.transmissionGeneralPolarity),
        term: '${chuan.position.displayName}乘${chuan.chengShen.name}',
        category: DlrTagCategory.tianJiang,
        polarity: jiangJi ? Polarity.ji : Polarity.xiong,
        priority: 3,
        reason: chuan.chengShen.description,
        relatedPositions: [chuan.position.displayName],
      ));
    }

    // 初传对日干的生克
    final riGanWuXing = WuXingService.getWuXingFromStem(riGan);
    final chuWuXing =
        WuXingService.getWuXingFromBranch(sanChuan.chuChuan.diZhi);
    if (riGanWuXing != null && chuWuXing != null) {
      if (WuXingService.isKe(chuWuXing, riGanWuXing)) {
        tags[ChuanPosition.chu]!.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(
            DlrProjectRuleIds.initialTransmissionControlsSelf,
          ),
          term: '发用克身',
          category: DlrTagCategory.chuan,
          polarity: Polarity.xiong,
          priority: 2,
          reason: '初传${sanChuan.chuChuan.diZhi}克日干$riGan，事起即攻身',
          relatedPositions: const ['初传'],
        ));
      } else if (WuXingService.isSheng(chuWuXing, riGanWuXing)) {
        tags[ChuanPosition.chu]!.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(
            DlrProjectRuleIds.initialTransmissionGeneratesSelf,
          ),
          term: '发用生身',
          category: DlrTagCategory.chuan,
          polarity: Polarity.ji,
          priority: 2,
          reason: '初传${sanChuan.chuChuan.diZhi}生日干$riGan，事起助身',
          relatedPositions: const ['初传'],
        ));
      }
    }

    return tags;
  }

  /// 课局级标签（挂 juTags）
  static List<DlrAnalysisTag> analyzeJuTags({
    required SanChuan sanChuan,
    required String riGan,
  }) {
    final tags = <DlrAnalysisTag>[];
    final chu = sanChuan.chuChuan.diZhi;
    final zhong = sanChuan.zhongChuan.diZhi;
    final mo = sanChuan.moChuan.diZhi;

    final chuWx = WuXingService.getWuXingFromBranch(chu);
    final zhongWx = WuXingService.getWuXingFromBranch(zhong);
    final moWx = WuXingService.getWuXingFromBranch(mo);
    final riGanWx = WuXingService.getWuXingFromStem(riGan);

    // 递生传进 / 递克传退
    if (chuWx != null && zhongWx != null && moWx != null) {
      if (WuXingService.isSheng(chuWx, zhongWx) &&
          WuXingService.isSheng(zhongWx, moWx)) {
        tags.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.progressiveGeneration),
          term: '递生传进',
          category: DlrTagCategory.chuan,
          polarity: Polarity.ji,
          priority: 1,
          reason: '初传$chu生中传$zhong，中传$zhong生末传$mo，事渐顺成',
          relatedPositions: const ['初传', '中传', '末传'],
        ));
      } else if (WuXingService.isKe(chuWx, zhongWx) &&
          WuXingService.isKe(zhongWx, moWx)) {
        tags.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.progressiveControl),
          term: '递克传退',
          category: DlrTagCategory.chuan,
          polarity: Polarity.xiong,
          priority: 1,
          reason: '初传$chu克中传$zhong，中传$zhong克末传$mo，事节节受挫',
          relatedPositions: const ['初传', '中传', '末传'],
        ));
      }
    }

    // 传归生身 / 传归克身
    if (moWx != null && riGanWx != null) {
      final jiGong = DaLiuRenConstants.getGanJiGong(riGan);
      final moLiuHeJiGong = DaLiuRenConstants.diZhiLiuHe[mo] == jiGong;
      if (WuXingService.isSheng(moWx, riGanWx) || moLiuHeJiGong) {
        tags.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(
            DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
          ),
          term: '传归生身',
          category: DlrTagCategory.chuan,
          polarity: Polarity.ji,
          priority: 1,
          reason: moLiuHeJiGong && !WuXingService.isSheng(moWx, riGanWx)
              ? '末传$mo与日干$riGan寄宫$jiGong六合，终得其济'
              : '末传$mo生日干$riGan，终得其济',
          relatedPositions: const ['末传'],
        ));
      } else if (WuXingService.isKe(moWx, riGanWx)) {
        tags.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(
            DlrProjectRuleIds.transmissionReturnsToControlSelf,
          ),
          term: '传归克身',
          category: DlrTagCategory.chuan,
          polarity: Polarity.xiong,
          priority: 1,
          reason: '末传$mo克日干$riGan，事终不利',
          relatedPositions: const ['末传'],
        ));
      }
    }

    // 三传合局
    final sanHeJu = _matchSanHeJu(chu, zhong, mo);
    if (sanHeJu != null) {
      tags.add(DlrAnalysisTag(
        ruleRef: DlrRuleRef.project(DlrProjectRuleIds.threeHarmonyFormation),
        term: '三传合局',
        category: DlrTagCategory.chuan,
        polarity: Polarity.neutral,
        priority: 2,
        reason: '三传$chu、$zhong、$mo构成$sanHeJu，事体牵连成局',
        relatedPositions: const ['初传', '中传', '末传'],
      ));
    }

    return tags;
  }

  /// 三传是否构成三合局，返回局名（如"申子辰水局"），否则 null
  static String? _matchSanHeJu(String chu, String zhong, String mo) {
    const juNames = {
      '申子辰': '申子辰水局',
      '寅午戌': '寅午戌火局',
      '巳酉丑': '巳酉丑金局',
      '亥卯未': '亥卯未木局',
    };
    final chuanSet = {chu, zhong, mo};
    if (chuanSet.length != 3) {
      return null;
    }
    for (final ju in DaLiuRenConstants.sanHeOrder) {
      if (chuanSet.containsAll(ju)) {
        return juNames[ju.join()];
      }
    }
    return null;
  }
}
