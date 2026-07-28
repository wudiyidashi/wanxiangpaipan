import '../../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../../divination_systems/daliuren/models/dlr_rule_contract.dart';
import '../../../../divination_systems/daliuren/models/san_chuan.dart';
import '../../../../divination_systems/daliuren/models/si_ke.dart';
import '../../shared/analysis/models/polarity.dart';
import '../../shared/wuxing_service.dart';
import 'models/daliuren_analysis_models.dart';

/// 课格定性服务（纯静态函数）。
///
/// 由 `SanChuan.keType` + `SiKe` + 日干刚柔重推格名，不解析
/// keTypeExplanation 文本。格名基调为本项目约定（大六壬断课 v1），
/// 措辞参照《大六壬指南》课体章。
class KeGeService {
  KeGeService._();

  /// 课格定性：按 design §3.1 表格判定格名与吉凶基调
  static KeGeInfo analyze({
    required SanChuan sanChuan,
    required SiKe siKe,
  }) {
    final keTypeName = sanChuan.keType.name;
    final isYang = DaLiuRenConstants.isYangGan(siKe.riGan);
    final hasAnyKe = siKe.hasZeiKe || siKe.hasBiYong;

    switch (sanChuan.keType) {
      case KeType.zeiKe:
        if (siKe.hasZeiKe) {
          return KeGeInfo(
            ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeChongShen),
            keTypeName: keTypeName,
            geName: '重审',
            polarity: Polarity.neutral,
            reason: '事从卑下而起，先难后易，审慎则吉',
          );
        }
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeYuanShou),
          keTypeName: keTypeName,
          geName: '元首',
          polarity: Polarity.ji,
          reason: '尊临卑、事顺理正',
        );
      case KeType.biYong:
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeZhiYi),
          keTypeName: keTypeName,
          geName: '知一',
          polarity: Polarity.neutral,
          reason: '事在同类，择亲近者而就',
        );
      case KeType.sheHai:
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeSheHai),
          keTypeName: keTypeName,
          geName: '涉害',
          polarity: Polarity.xiong,
          reason: '历涉艰难，事迟滞乃成',
        );
      case KeType.yaoKe:
        if (_hasShangShenKeRiGan(siKe)) {
          return KeGeInfo(
            ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeHaoShi),
            keTypeName: keTypeName,
            geName: '蒿矢',
            polarity: Polarity.neutral,
            reason: '克自远来，虚惊多实害少',
          );
        }
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeTanShe),
          keTypeName: keTypeName,
          geName: '弹射',
          polarity: Polarity.neutral,
          reason: '我克在远，事轻微',
        );
      case KeType.maoXing:
        if (isYang) {
          return KeGeInfo(
            ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeHuShi),
            keTypeName: keTypeName,
            geName: '虎视',
            polarity: Polarity.xiong,
            reason: '事多惊疑，防伺伏之患',
          );
        }
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeDongSheYanMu),
          keTypeName: keTypeName,
          geName: '冬蛇掩目',
          polarity: Polarity.xiong,
          reason: '暗昧不明，事宜静守',
        );
      case KeType.bieZe:
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeBieZe),
          keTypeName: keTypeName,
          geName: '别责',
          polarity: Polarity.neutral,
          reason: '事不专一，别有所托',
        );
      case KeType.baZhuan:
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeBaZhuan),
          keTypeName: keTypeName,
          geName: '八专',
          polarity: Polarity.neutral,
          reason: '干支同体，事涉同谋或内外不分',
        );
      case KeType.fuYin:
        if (hasAnyKe) {
          return KeGeInfo(
            ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeBuYu),
            keTypeName: keTypeName,
            geName: '不虞',
            polarity: Polarity.xiong,
            reason: '静中生变，防不虞之事',
          );
        }
        if (isYang) {
          return KeGeInfo(
            ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeZiRen),
            keTypeName: keTypeName,
            geName: '自任',
            polarity: Polarity.neutral,
            reason: '伏而不动，宜守不宜进',
          );
        }
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeZiXin),
          keTypeName: keTypeName,
          geName: '自信',
          polarity: Polarity.neutral,
          reason: '伏而自省，事迟',
        );
      case KeType.fanYin:
        if (!hasAnyKe) {
          return KeGeInfo(
            ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeJingLanShe),
            keTypeName: keTypeName,
            geName: '井栏射',
            polarity: Polarity.neutral,
            reason: '动极思迁，去而复来',
          );
        }
        return KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeFanYin),
          keTypeName: keTypeName,
          geName: '反吟',
          polarity: Polarity.xiong,
          reason: '反复动荡，事多往返',
        );
    }
  }

  /// 遥克判据：二三四课上神是否有克日干者（蒿矢先于弹射）
  static bool _hasShangShenKeRiGan(SiKe siKe) {
    final riGanWuXing = WuXingService.getWuXingFromStem(siKe.riGan);
    if (riGanWuXing == null) {
      return false;
    }
    return [siKe.ke2, siKe.ke3, siKe.ke4].any((ke) {
      final wx = WuXingService.getWuXingFromBranch(ke.shangShen);
      return wx != null && WuXingService.isKe(wx, riGanWuXing);
    });
  }
}
