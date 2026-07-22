import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';

/// 应期推算：根据用神当前状态推导候选应期。
///
/// 规则依据《增删卜易》：旬空者出空填实之日应，月破者出月实破合破之日应，
/// 入墓者冲开墓库之日应，合住者冲开之日应，静者值日冲动之日应，
/// 动者值日合日应，化进神者变爻当值应，临绝者长生之日应。
/// 同支候选去重保留优先级最高者，结果按优先级排序。
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
      add(zhi, '出空填实', 1);
      if (!yongShen.isMoving) add(chongZhi, '冲空则起', 2);
    }
    if (terms.contains('月破')) {
      add(zhi, '出月实破', 1);
      add(heZhi, '逢合实破', 3);
    }
    if (terms.contains('入日墓') ||
        terms.contains('入月墓') ||
        terms.contains('入动墓')) {
      final muBranch = ChangShengTable.getMuBranch(yongShen.wuXing);
      add(DiZhiRelations.getLiuChong(muBranch)!, '冲开墓库', 2);
    }
    if (terms.contains('合住') || terms.contains('合绊') || terms.contains('化合')) {
      add(chongZhi, '冲开合绊', 3);
    }
    if (terms.contains('临绝')) {
      add(ChangShengTable.getChangShengBranch(yongShen.wuXing), '绝处逢生', 7);
    }
    if (terms.contains('化进神') && changedYao != null) {
      add(changedYao.branch, '进神当值', 7);
    }

    // 常规应期
    add(zhi, '用神值日', 5);
    if (yongShen.isMoving) {
      add(heZhi, '动而逢合', 6);
    } else {
      add(chongZhi, '冲动用神', 6);
    }

    // 同支去重（保留优先级最高者）后排序
    final byBranch = <String, YingQiCandidate>{};
    for (final c in candidates) {
      final existing = byBranch[c.branch];
      if (existing == null || c.priority < existing.priority) {
        byBranch[c.branch] = c;
      }
    }
    return byBranch.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
