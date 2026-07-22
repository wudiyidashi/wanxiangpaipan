import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/tiangan_dizhi_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';

/// 应期推算：根据用神当前状态推导候选应期。
///
/// 规则依据《增删卜易》：旬空者填实、冲空之日应，月破者出月、实破、合破时应，
/// 入墓者冲开墓库之日应，合住者冲开之日应，静者值日冲动之日应，
/// 动者值日合日应，化进神者变爻当值应，临绝者长生之日应。
/// 同尺度同支候选去重保留优先级最高者，结果按优先级排序。
class YingQiService {
  YingQiService._();

  static List<YingQiCandidate> calculate({
    required Yao yongShen,
    Yao? changedYao,
    required List<YaoAnalysisTag> yongShenTags,
    required LunarInfo lunarInfo,
  }) {
    final terms = yongShenTags.map((t) => t.term).toSet();
    final zhi = yongShen.branch;
    final chongZhi = DiZhiRelations.getLiuChong(zhi)!;
    final heZhi = DiZhiRelations.getLiuHe(zhi)!;
    final nextMonthBranch = TianGanDiZhiService.getNextDiZhi(
      lunarInfo.yueJian,
    )!;
    final candidates = <YingQiCandidate>[];

    void add(String branch, String reason, int priority,
        {YingQiScale scale = YingQiScale.ri}) {
      candidates.add(YingQiCandidate(
        label: '$branch${scale.name}（$reason）',
        branch: branch,
        scale: scale,
        reason: reason,
        priority: priority,
      ));
    }

    if (terms.contains('旬空')) {
      add(zhi, '值日填实旬空', 1);
      if (!yongShen.isMoving) add(chongZhi, '冲空则起', 2);
    }
    if (terms.contains('月破')) {
      add(nextMonthBranch, '出月解除月破', 1, scale: YingQiScale.yue);
      add(zhi, '值日填实月破', 2);
      add(heZhi, '逢合解破', 3);
    }
    if (terms.contains('入日墓') ||
        terms.contains('入月墓') ||
        terms.contains('入动墓')) {
      final muBranch = ChangShengTable.getMuBranch(yongShen.wuXing);
      add(DiZhiRelations.getLiuChong(muBranch)!, '冲开墓库', 2);
    }
    final isHeZhu =
        terms.contains('合住') || terms.contains('合绊') || terms.contains('化合');
    if (isHeZhu && !terms.contains('冲开')) {
      add(chongZhi, '冲用神解合', 3);
      final hePartner = terms.contains('化合') && changedYao != null
          ? changedYao.branch
          : heZhi;
      add(DiZhiRelations.getLiuChong(hePartner)!, '冲合神解合', 3);
    }
    if (terms.contains('临绝')) {
      add(ChangShengTable.getChangShengBranch(yongShen.wuXing), '绝处逢生', 7);
    }
    if (terms.contains('化进神') && changedYao != null) {
      add(changedYao.branch, '进神当值', 7);
    }
    if (terms.contains('化空') && changedYao != null) {
      add(changedYao.branch, '变爻值日填实化空', 2);
      add(DiZhiRelations.getLiuChong(changedYao.branch)!, '冲起化空', 3);
    }
    if (terms.contains('化破') && changedYao != null) {
      add(nextMonthBranch, '出月解除化破', 1, scale: YingQiScale.yue);
      add(changedYao.branch, '变爻值日填实化破', 2);
      add(DiZhiRelations.getLiuHe(changedYao.branch)!, '变爻逢合解破', 3);
    }
    if (terms.contains('化墓') && changedYao != null) {
      add(DiZhiRelations.getLiuChong(changedYao.branch)!, '冲开化墓', 2);
    }

    // 常规应期
    add(zhi, '用神值日', 5);
    if (yongShen.isMoving) {
      add(heZhi, '动而逢合', 6);
    } else {
      add(chongZhi, '冲动用神', 6);
    }

    // 同尺度同支去重（保留优先级最高者）后排序。
    // 同一地支的日、月候选含义不同，不能互相覆盖。
    final byScaleAndBranch = <String, YingQiCandidate>{};
    for (final c in candidates) {
      final key = '${c.scale.name}:${c.branch}';
      final existing = byScaleAndBranch[key];
      if (existing == null || c.priority < existing.priority) {
        byScaleAndBranch[key] = c;
      }
    }
    return byScaleAndBranch.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
