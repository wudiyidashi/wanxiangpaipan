import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/tiangan_dizhi_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'models/analysis_trace.dart';
import 'rules/liuyao_catalog.dart';
import 'rules/liuyao_trace_id_factory.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';

/// Condition-driven timing for v2, with an explicit frozen legacy entry point.
class YingQiService {
  YingQiService._();

  static List<YingQiCandidate> calculate({
    required Yao yongShen,
    Yao? changedYao,
    List<YaoAnalysisTag>? yongShenTags,
    List<VerdictCondition> conditions = const <VerdictCondition>[],
    LiuYaoActorRef? selectedActor,
    String? hiddenFlightBranch,
    required LunarInfo lunarInfo,
    String ruleSetVersion = LiuYaoRuleCatalog.current,
    LiuYaoTraceIdFactory? traceIdFactory,
  }) {
    final version = LiuYaoRuleCatalog.resolve(ruleSetVersion).version;
    if (version == LiuYaoRuleCatalog.v1Compat) {
      return calculateLegacy(
        yongShen: yongShen,
        changedYao: changedYao,
        yongShenTags: yongShenTags ?? const <YaoAnalysisTag>[],
        lunarInfo: lunarInfo,
      );
    }
    if (yongShenTags != null) {
      throw ArgumentError.value(
        yongShenTags,
        'yongShenTags',
        'v2 timing accepts verdict conditions only',
      );
    }
    final eligible = conditions
        .where((condition) =>
            condition.status == 'unresolved' && condition.hasRescue)
        .toList();
    if (eligible.isEmpty) return const <YingQiCandidate>[];

    final actor = selectedActor ??
        LiuYaoActorRef(
          actorId: 'main:yao:${yongShen.position}',
          kind: LiuYaoActorKind.mainYao,
          position: yongShen.position,
          branch: yongShen.branch,
          wuXing: yongShen.wuXing,
          liuQin: yongShen.liuQin,
          isMoving: yongShen.isMoving,
        );
    final ids = traceIdFactory ?? LiuYaoTraceIdFactory();
    final nextMonthBranch =
        TianGanDiZhiService.getNextDiZhi(lunarInfo.yueJian)!;
    final candidates = <_TimingSeed>[];

    void add({
      required VerdictCondition condition,
      required String timingRuleId,
      required String branch,
      required String reason,
      required int priority,
      YingQiScale scale = YingQiScale.ri,
    }) {
      candidates.add(_TimingSeed(
        timingRuleId: timingRuleId,
        branch: branch,
        scale: scale,
        reason: reason,
        priority: priority,
        conditionIds: <String>[condition.conditionId],
        upstreamRuleIds: <String>[
          condition.conditionRuleId,
          timingRuleId,
        ],
        sourceIds: <String>{
          ...condition.sourceIds,
          ...LiuYaoRuleCatalog.ruleById[timingRuleId]!.sourceIds,
        }.toList()
          ..sort(),
      ));
    }

    for (final condition in eligible) {
      switch (condition.conditionRuleId) {
        case LiuYaoRuleIds.conditionVoid:
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingVoidFill,
            branch: yongShen.branch,
            reason: '值日填实旬空',
            priority: 1,
          );
          if (!yongShen.isMoving) {
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingVoidClash,
              branch: DiZhiRelations.getLiuChong(yongShen.branch)!,
              reason: '冲空则起',
              priority: 2,
            );
          }
        case LiuYaoRuleIds.conditionMonthBreak:
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingMonthBreakExit,
            branch: nextMonthBranch,
            reason: '出月解除月破',
            priority: 1,
            scale: YingQiScale.yue,
          );
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingMonthBreakFill,
            branch: yongShen.branch,
            reason: '值日填实月破',
            priority: 2,
          );
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingMonthBreakJoin,
            branch: DiZhiRelations.getLiuHe(yongShen.branch)!,
            reason: '逢合解破',
            priority: 3,
          );
        case LiuYaoRuleIds.conditionTomb || LiuYaoRuleIds.conditionChangedTomb:
          if (condition.branch != null) {
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingTombOpen,
              branch: condition.branch!,
              reason: condition.conditionRuleId ==
                      LiuYaoRuleIds.conditionChangedTomb
                  ? '冲开化墓'
                  : '冲开墓库',
              priority: 2,
            );
          }
        case LiuYaoRuleIds.conditionBinding:
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingBindingTargetClash,
            branch: DiZhiRelations.getLiuChong(yongShen.branch)!,
            reason: '冲用神解合',
            priority: 3,
          );
          final partner = DiZhiRelations.getLiuHe(yongShen.branch)!;
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingBindingPartnerClash,
            branch: DiZhiRelations.getLiuChong(partner)!,
            reason: '冲合神解合',
            priority: 3,
          );
        case LiuYaoRuleIds.conditionChangedVoid:
          final changedBranch = condition.branch ?? changedYao?.branch;
          if (changedBranch != null) {
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingChangedVoidFill,
              branch: changedBranch,
              reason: '变爻值日填实化空',
              priority: 2,
            );
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingChangedVoidClash,
              branch: DiZhiRelations.getLiuChong(changedBranch)!,
              reason: '冲起化空',
              priority: 3,
            );
          }
        case LiuYaoRuleIds.conditionChangedBreak:
          final changedBranch = condition.branch ?? changedYao?.branch;
          if (changedBranch != null) {
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingChangedBreakExit,
              branch: nextMonthBranch,
              reason: '出月解除化破',
              priority: 1,
              scale: YingQiScale.yue,
            );
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingChangedBreakFill,
              branch: changedBranch,
              reason: '变爻值日填实化破',
              priority: 2,
            );
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingChangedBreakJoin,
              branch: DiZhiRelations.getLiuHe(changedBranch)!,
              reason: '变爻逢合解破',
              priority: 3,
            );
          }
        case LiuYaoRuleIds.conditionTerminal:
          final branch = condition.branch ??
              ChangShengTable.getChangShengBranch(yongShen.wuXing);
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingTerminalChangSheng,
            branch: branch,
            reason: '绝处逢生',
            priority: 7,
          );
        case LiuYaoRuleIds.conditionHiddenRelease:
          add(
            condition: condition,
            timingRuleId: LiuYaoRuleIds.timingHiddenFill,
            branch: yongShen.branch,
            reason: '伏神值日引出',
            priority: 2,
          );
          if (hiddenFlightBranch != null) {
            add(
              condition: condition,
              timingRuleId: LiuYaoRuleIds.timingHiddenFlightClash,
              branch: DiZhiRelations.getLiuChong(hiddenFlightBranch)!,
              reason: '冲飞引伏',
              priority: 3,
            );
          }
      }
    }

    final byTimingKey = <String, _TimingSeed>{};
    for (final seed in candidates) {
      final key = '${seed.scale.code}:branch:${seed.branch}:${actor.actorId}';
      final existing = byTimingKey[key];
      byTimingKey[key] = existing == null ? seed : existing.merge(seed);
    }
    final result = <YingQiCandidate>[
      for (final seed in byTimingKey.values)
        YingQiCandidate(
          label: '${seed.branch}${seed.scale.name}（${seed.reasons.join('；')}）',
          branch: seed.branch,
          scale: seed.scale,
          reason: seed.reasons.join('；'),
          priority: seed.priority,
          timingId: ids.timing(
            timingRuleId: seed.timingRuleId,
            scale: seed.scale.code,
            triggerKind: 'branch',
            triggerValue: seed.branch,
            targetActorId: actor.actorId,
            upstreamConditionIds: seed.conditionIds,
          ),
          timingRuleId: seed.timingRuleId,
          upstreamConditionIds: seed.conditionIds,
          upstreamRuleIds: seed.upstreamRuleIds,
          sourceIds: seed.sourceIds,
          triggerKind: 'branch',
          triggerValue: seed.branch,
          targetActorId: actor.actorId,
        ),
    ];
    result.sort((left, right) {
      final priority = left.priority.compareTo(right.priority);
      if (priority != 0) return priority;
      final scale = left.scale.index.compareTo(right.scale.index);
      if (scale != 0) return scale;
      final branch = left.branch.compareTo(right.branch);
      return branch != 0 ? branch : left.timingId.compareTo(right.timingId);
    });
    return result;
  }

  /// Frozen term-driven behavior used only by `v1-compat`.
  static List<YingQiCandidate> calculateLegacy({
    required Yao yongShen,
    Yao? changedYao,
    required List<YaoAnalysisTag> yongShenTags,
    required LunarInfo lunarInfo,
  }) {
    final terms = yongShenTags.map((tag) => tag.term).toSet();
    final branch = yongShen.branch;
    final clashBranch = DiZhiRelations.getLiuChong(branch)!;
    final joinBranch = DiZhiRelations.getLiuHe(branch)!;
    final nextMonthBranch =
        TianGanDiZhiService.getNextDiZhi(lunarInfo.yueJian)!;
    final candidates = <YingQiCandidate>[];

    void add(String candidateBranch, String reason, int priority,
        {YingQiScale scale = YingQiScale.ri}) {
      candidates.add(YingQiCandidate(
        label: '$candidateBranch${scale.name}（$reason）',
        branch: candidateBranch,
        scale: scale,
        reason: reason,
        priority: priority,
      ));
    }

    if (terms.contains('旬空')) {
      add(branch, '值日填实旬空', 1);
      if (!yongShen.isMoving) add(clashBranch, '冲空则起', 2);
    }
    if (terms.contains('月破')) {
      add(nextMonthBranch, '出月解除月破', 1, scale: YingQiScale.yue);
      add(branch, '值日填实月破', 2);
      add(joinBranch, '逢合解破', 3);
    }
    if ((terms.contains('入日墓') ||
            terms.contains('入月墓') ||
            terms.contains('入动墓')) &&
        !terms.contains('出墓')) {
      final tombBranch = ChangShengTable.getMuBranch(yongShen.wuXing);
      add(DiZhiRelations.getLiuChong(tombBranch)!, '冲开墓库', 2);
    }
    final held = terms.contains('合住') ||
        terms.contains('合绊') ||
        (yongShen.isMoving && (terms.contains('日合') || terms.contains('月合')));
    if (held && !terms.contains('冲开')) {
      add(clashBranch, '冲用神解合', 3);
      add(DiZhiRelations.getLiuChong(joinBranch)!, '冲合神解合', 3);
    }
    if (terms.contains('临绝') || terms.contains('化绝')) {
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
    add(branch, '用神值日', 5);
    if (yongShen.isMoving) {
      add(joinBranch, '动而逢合', 6);
    } else {
      add(clashBranch, '冲动用神', 6);
    }

    final byScaleAndBranch = <String, YingQiCandidate>{};
    for (final candidate in candidates) {
      final key = '${candidate.scale.name}:${candidate.branch}';
      final existing = byScaleAndBranch[key];
      if (existing == null || candidate.priority < existing.priority) {
        byScaleAndBranch[key] = candidate;
      }
    }
    return byScaleAndBranch.values.toList()
      ..sort((left, right) => left.priority.compareTo(right.priority));
  }
}

class _TimingSeed {
  _TimingSeed({
    required this.timingRuleId,
    required this.branch,
    required this.scale,
    required this.reason,
    required this.priority,
    required List<String> conditionIds,
    required List<String> upstreamRuleIds,
    required List<String> sourceIds,
  })  : conditionIds = conditionIds.toSet().toList()..sort(),
        upstreamRuleIds = upstreamRuleIds.toSet().toList()..sort(),
        sourceIds = sourceIds.toSet().toList()..sort();

  final String timingRuleId;
  final String branch;
  final YingQiScale scale;
  final String reason;
  final int priority;
  final List<String> conditionIds;
  final List<String> upstreamRuleIds;
  final List<String> sourceIds;

  List<String> get reasons => <String>[reason];

  _TimingSeed merge(_TimingSeed other) {
    final allReasons = <String>{...reasons, ...other.reasons}.toList()..sort();
    return _MergedTimingSeed(
      timingRuleId: <String>[timingRuleId, other.timingRuleId]..sort(),
      branch: branch,
      scale: scale,
      reasons: allReasons,
      priority: priority < other.priority ? priority : other.priority,
      conditionIds: <String>[...conditionIds, ...other.conditionIds],
      upstreamRuleIds: <String>[
        ...upstreamRuleIds,
        ...other.upstreamRuleIds,
      ],
      sourceIds: <String>[...sourceIds, ...other.sourceIds],
    );
  }
}

class _MergedTimingSeed extends _TimingSeed {
  _MergedTimingSeed({
    required List<String> timingRuleId,
    required super.branch,
    required super.scale,
    required List<String> reasons,
    required super.priority,
    required super.conditionIds,
    required super.upstreamRuleIds,
    required super.sourceIds,
  })  : _reasons = reasons,
        super(
          timingRuleId: timingRuleId.first,
          reason: reasons.first,
        );

  final List<String> _reasons;

  @override
  List<String> get reasons => _reasons;
}
