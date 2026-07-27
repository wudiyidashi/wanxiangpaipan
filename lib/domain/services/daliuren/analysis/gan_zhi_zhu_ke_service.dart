import '../../../../divination_systems/daliuren/models/si_ke.dart';
import '../../shared/analysis/models/polarity.dart';
import '../../shared/wuxing_service.dart';
import 'models/daliuren_analysis_models.dart';

/// 干支主客服务（纯静态函数）。
///
/// 日干为人（我），日支为事（彼/事体）。以五行论干上神/支上神
/// 对日干/日支的生克关系。措辞为本项目约定（大六壬断课 v1）。
class GanZhiZhuKeService {
  GanZhiZhuKeService._();

  /// 分析干支主客标签（含干上/支上空亡）
  static List<DlrAnalysisTag> analyze({
    required SiKe siKe,
    required List<String> kongWang,
  }) {
    final tags = <DlrAnalysisTag>[];

    final ganShang = siKe.ke1.shangShen;
    final zhiShang = siKe.ke3.shangShen;

    // 干上神 vs 日干
    final riGanWuXing = WuXingService.getWuXingFromStem(siKe.riGan);
    final ganShangWuXing = WuXingService.getWuXingFromBranch(ganShang);
    if (riGanWuXing != null && ganShangWuXing != null) {
      final relation = WuXingService.getRelation(riGanWuXing, ganShangWuXing);
      tags.add(switch (relation) {
        WuXingRelation.shengWo => DlrAnalysisTag(
            term: '干上生身',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.ji,
            priority: 1,
            reason: '干上神$ganShang生日干${siKe.riGan}，人得生扶',
            relatedPositions: const ['干上'],
          ),
        WuXingRelation.keWo => DlrAnalysisTag(
            term: '干上克身',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.xiong,
            priority: 1,
            reason: '干上神$ganShang克日干${siKe.riGan}，人受其制',
            relatedPositions: const ['干上'],
          ),
        WuXingRelation.woKe => DlrAnalysisTag(
            term: '身制干上',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.neutral,
            priority: 2,
            reason: '日干${siKe.riGan}克干上神$ganShang，我能制上',
            relatedPositions: const ['干上'],
          ),
        WuXingRelation.woSheng => DlrAnalysisTag(
            term: '身泄于上',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.neutral,
            priority: 2,
            reason: '日干${siKe.riGan}生干上神$ganShang，气泄于上',
            relatedPositions: const ['干上'],
          ),
        WuXingRelation.biHe => DlrAnalysisTag(
            term: '干上比助',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.neutral,
            priority: 2,
            reason: '干上神$ganShang与日干${siKe.riGan}比和，同气相助',
            relatedPositions: const ['干上'],
          ),
      });
    }

    // 支上神 vs 日支
    final riZhiWuXing = WuXingService.getWuXingFromBranch(siKe.riZhi);
    final zhiShangWuXing = WuXingService.getWuXingFromBranch(zhiShang);
    if (riZhiWuXing != null && zhiShangWuXing != null) {
      final relation = WuXingService.getRelation(riZhiWuXing, zhiShangWuXing);
      tags.add(switch (relation) {
        WuXingRelation.shengWo => DlrAnalysisTag(
            term: '事得生扶',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.ji,
            priority: 1,
            reason: '支上神$zhiShang生日支${siKe.riZhi}，事体得生扶',
            relatedPositions: const ['支上'],
          ),
        WuXingRelation.keWo => DlrAnalysisTag(
            term: '事体受制',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.xiong,
            priority: 1,
            reason: '支上神$zhiShang克日支${siKe.riZhi}，事体受制',
            relatedPositions: const ['支上'],
          ),
        WuXingRelation.woKe => DlrAnalysisTag(
            term: '事制其上',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.neutral,
            priority: 2,
            reason: '日支${siKe.riZhi}克支上神$zhiShang，事体能制其上',
            relatedPositions: const ['支上'],
          ),
        WuXingRelation.woSheng => DlrAnalysisTag(
            term: '事泄于上',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.neutral,
            priority: 2,
            reason: '日支${siKe.riZhi}生支上神$zhiShang，事体气泄于上',
            relatedPositions: const ['支上'],
          ),
        WuXingRelation.biHe => DlrAnalysisTag(
            term: '支上比助',
            category: DlrTagCategory.ganZhi,
            polarity: Polarity.neutral,
            priority: 2,
            reason: '支上神$zhiShang与日支${siKe.riZhi}比和，事得同气',
            relatedPositions: const ['支上'],
          ),
      });
    }

    // 干上/支上落旬空
    if (kongWang.contains(ganShang)) {
      tags.add(DlrAnalysisTag(
        term: '干上空亡',
        category: DlrTagCategory.kongWang,
        polarity: Polarity.xiong,
        priority: 1,
        reason: '干上神$ganShang落旬空，人事无着，待$ganShang填实',
        relatedPositions: const ['干上'],
      ));
    }
    if (kongWang.contains(zhiShang)) {
      tags.add(DlrAnalysisTag(
        term: '支上空亡',
        category: DlrTagCategory.kongWang,
        polarity: Polarity.xiong,
        priority: 1,
        reason: '支上神$zhiShang落旬空，事体无着，待$zhiShang填实',
        relatedPositions: const ['支上'],
      ));
    }

    return tags;
  }
}
