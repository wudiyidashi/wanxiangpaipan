import '../../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../../divination_systems/daliuren/models/chuan.dart';
import '../../../../divination_systems/daliuren/models/dlr_rule_contract.dart';
import '../../../../divination_systems/daliuren/models/san_chuan.dart';
import '../../../../divination_systems/daliuren/models/shen_sha.dart';
import '../../shared/analysis/models/polarity.dart';
import 'models/daliuren_analysis_models.dart';

/// 神煞落传服务（纯静态函数）。
///
/// 神煞地支命中三传之支时挂标签到对应传；polarity 按神煞吉凶类型。
/// 措辞为本项目约定（大六壬断课 v1）；不修改神煞计算服务。
class ShenShaChuanService {
  ShenShaChuanService._();

  /// 分析神煞落传，返回每传追加标签
  static Map<ChuanPosition, List<DlrAnalysisTag>> analyze({
    required SanChuan sanChuan,
    required ShenShaList shenShaList,
  }) {
    final tags = <ChuanPosition, List<DlrAnalysisTag>>{
      for (final position in ChuanPosition.values) position: <DlrAnalysisTag>[],
    };

    for (final shenSha in shenShaList.allShenSha) {
      for (final chuan in sanChuan.allChuan) {
        if (shenSha.diZhi != chuan.diZhi) {
          continue;
        }
        final polarity = switch (shenSha.type) {
          ShenShaType.ji => Polarity.ji,
          ShenShaType.xiong => Polarity.xiong,
          ShenShaType.zhong => Polarity.neutral,
        };
        final isYiMaFaYong =
            shenSha.name == '驿马' && chuan.position == ChuanPosition.chu;
        tags[chuan.position]!.add(DlrAnalysisTag(
          ruleRef: DlrRuleRef.project(
            isYiMaFaYong
                ? DlrProjectRuleIds.travellingHorseInitial
                : DlrProjectRuleIds.shenShaOnTransmission,
          ),
          term: isYiMaFaYong
              ? '驿马发用'
              : '${shenSha.name}临${chuan.position.displayName}',
          category: DlrTagCategory.shenSha,
          polarity: polarity,
          priority: 4,
          reason: isYiMaFaYong
              ? '驿马${shenSha.diZhi}临初传，事动而速'
              : '${shenSha.name}${shenSha.diZhi}临${chuan.position.displayName}，'
                  '${shenSha.description}',
          relatedPositions: [chuan.position.displayName],
        ));
      }
    }

    return tags;
  }
}
