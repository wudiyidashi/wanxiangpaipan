import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_tag.dart';
import 'models/analysis_trace.dart';
import 'rule_identity_service.dart';
import 'rules/liuyao_catalog.dart';
import 'tables/dizhi_relations.dart';

/// Applies one versioned transmission policy to every helper and attacker.
class ActorAvailabilityService {
  ActorAvailabilityService._();

  static List<ActorAvailability> evaluateGua({
    required Gua mainGua,
    required Gua? changingGua,
    required LunarInfo lunarInfo,
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required String ruleSetVersion,
  }) {
    LiuYaoRuleCatalog.resolve(ruleSetVersion);
    final result = <ActorAvailability>[
      for (final yao in mainGua.yaos)
        evaluateActor(
          actor: mainActor(yao),
          tags: yaoTags[yao.position] ?? const <YaoAnalysisTag>[],
          lunarInfo: lunarInfo,
          ruleSetVersion: ruleSetVersion,
        ),
    ];
    if (changingGua != null) {
      for (final yao in mainGua.movingYaos) {
        result.add(ActorAvailability(
          actor: changedActor(changingGua.yaos[yao.position - 1]),
          state: ActorAvailabilityState.active,
          reasonRuleIds: const <String>[],
        ));
      }
    }
    result
      ..add(ActorAvailability(
        actor: calendarActor(
          kind: LiuYaoActorKind.calendarDay,
          branch: lunarInfo.riZhi,
        ),
        state: ActorAvailabilityState.active,
        reasonRuleIds: const <String>[],
      ))
      ..add(ActorAvailability(
        actor: calendarActor(
          kind: LiuYaoActorKind.calendarMonth,
          branch: lunarInfo.yueJian,
        ),
        state: ActorAvailabilityState.active,
        reasonRuleIds: const <String>[],
      ));
    return result;
  }

  static ActorAvailability evaluateActor({
    required LiuYaoActorRef actor,
    required List<YaoAnalysisTag> tags,
    required LunarInfo lunarInfo,
    required String ruleSetVersion,
  }) {
    final resolved = LiuYaoRuleCatalog.resolve(ruleSetVersion).version;
    if (resolved == LiuYaoRuleCatalog.v1Compat) {
      return ActorAvailability(
        actor: actor,
        state: ActorAvailabilityState.active,
        reasonRuleIds: const <String>[],
      );
    }

    final ruleIds =
        tags.map(RuleIdentityService.resolveRuleId).whereType<String>().toSet();
    List<YaoAnalysisTag> blockerTags(Iterable<String> blockerRuleIds) {
      final wanted = blockerRuleIds.toSet();
      return tags
          .where((tag) => wanted.contains(
                RuleIdentityService.resolveRuleId(tag),
              ))
          .toList();
    }

    ActorAvailability blocked(
      ActorAvailabilityState state,
      String policyRuleId,
      Iterable<String> blockerRuleIds, {
      List<String> releaseConditionRuleIds = const <String>[],
      List<DirectedEffectPhase> blockedPhases = const <DirectedEffectPhase>[],
    }) {
      final matchingTags = blockerTags(blockerRuleIds);
      final reasons = <String>{
        policyRuleId,
        ...matchingTags
            .map((tag) => tag.ruleId)
            .where((ruleId) => ruleId.isNotEmpty),
      }.toList()
        ..sort();
      return ActorAvailability(
        actor: actor,
        state: state,
        reasonRuleIds: reasons,
        releaseConditionRuleIds: releaseConditionRuleIds,
        suppressedByOccurrenceIds: matchingTags
            .map((tag) => tag.occurrenceId)
            .where((occurrenceId) => occurrenceId.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        blockedPhases: blockedPhases,
      );
    }

    ActorAvailability phaseLimited(
      String policyRuleId,
      Iterable<String> blockerRuleIds,
    ) {
      final matchingTags = blockerTags(blockerRuleIds);
      return ActorAvailability(
        actor: actor,
        state: ActorAvailabilityState.active,
        reasonRuleIds: <String>{
          policyRuleId,
          ...matchingTags.map((tag) => tag.ruleId),
        }.toList()
          ..sort(),
        suppressedByOccurrenceIds: matchingTags
            .map((tag) => tag.occurrenceId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        blockedPhases: const <DirectedEffectPhase>[
          DirectedEffectPhase.laterProcess,
          DirectedEffectPhase.finalState,
        ],
      );
    }

    if (ruleIds.contains(LiuYaoRuleIds.ruleTrueVoid)) {
      return blocked(
        ActorAvailabilityState.unavailable,
        LiuYaoRuleIds.actorTrueVoid,
        const <String>[
          LiuYaoRuleIds.ruleTrueVoid,
          LiuYaoRuleIds.ruleVoid,
        ],
      );
    }
    if (ruleIds.contains(LiuYaoRuleIds.ruleHiddenSuppressed)) {
      return blocked(
        ActorAvailabilityState.unavailable,
        LiuYaoRuleIds.actorHiddenSuppressed,
        const <String>[
          LiuYaoRuleIds.ruleHiddenSuppressed,
          LiuYaoRuleIds.ruleFlightOvercomesHidden,
        ],
      );
    }
    if (ruleIds.contains(LiuYaoRuleIds.ruleReturnOvercomes)) {
      if (resolved == LiuYaoRuleCatalog.v3) {
        return phaseLimited(
          LiuYaoRuleIds.actorReturnOvercome,
          const <String>[LiuYaoRuleIds.ruleReturnOvercomes],
        );
      }
      return blocked(
        ActorAvailabilityState.suppressed,
        LiuYaoRuleIds.actorReturnOvercome,
        const <String>[LiuYaoRuleIds.ruleReturnOvercomes],
      );
    }
    if (ruleIds.contains(LiuYaoRuleIds.ruleRetreat)) {
      if (resolved == LiuYaoRuleCatalog.v3) {
        return phaseLimited(
          LiuYaoRuleIds.actorRetreat,
          const <String>[LiuYaoRuleIds.ruleRetreat],
        );
      }
      return blocked(
        ActorAvailabilityState.suppressed,
        LiuYaoRuleIds.actorRetreat,
        const <String>[LiuYaoRuleIds.ruleRetreat],
      );
    }
    if (ruleIds.contains(LiuYaoRuleIds.ruleScattered)) {
      return blocked(
        ActorAvailabilityState.suppressed,
        LiuYaoRuleIds.actorScattered,
        const <String>[LiuYaoRuleIds.ruleScattered],
      );
    }

    final binding = _evaluateBinding(
      actor: actor,
      ruleIds: ruleIds,
      lunarInfo: lunarInfo,
    );
    if (binding.closed) {
      return blocked(
        ActorAvailabilityState.suspended,
        LiuYaoRuleIds.actorBinding,
        const <String>[
          LiuYaoRuleIds.ruleMovingBound,
          LiuYaoRuleIds.ruleMutualBinding,
          LiuYaoRuleIds.ruleDayJoins,
          LiuYaoRuleIds.ruleMonthJoins,
        ],
        releaseConditionRuleIds: const <String>[
          LiuYaoRuleIds.conditionBinding,
        ],
      );
    }

    if (ruleIds.contains(LiuYaoRuleIds.ruleMonthBreak)) {
      return blocked(
        ActorAvailabilityState.suspended,
        LiuYaoRuleIds.actorMonthBreak,
        const <String>[LiuYaoRuleIds.ruleMonthBreak],
        releaseConditionRuleIds: const <String>[
          LiuYaoRuleIds.conditionMonthBreak,
        ],
      );
    }
    if (ruleIds.contains(LiuYaoRuleIds.ruleVoid) &&
        !ruleIds.contains(LiuYaoRuleIds.ruleApparentVoid) &&
        !ruleIds.contains(LiuYaoRuleIds.ruleVoidClashed)) {
      return blocked(
        ActorAvailabilityState.suspended,
        LiuYaoRuleIds.actorVoid,
        const <String>[LiuYaoRuleIds.ruleVoid],
        releaseConditionRuleIds: const <String>[
          LiuYaoRuleIds.conditionVoid,
        ],
      );
    }

    final reasons = <String>[];
    if (binding.opened) {
      reasons.add(LiuYaoRuleIds.actorBindingOpened);
    }
    return ActorAvailability(
      actor: actor,
      state: ActorAvailabilityState.active,
      reasonRuleIds: reasons,
    );
  }

  /// Whether a peer, day, or month binding still suspends [actor].
  ///
  /// Verdict conditions reuse this predicate so availability and timing cannot
  /// disagree when the opposite calendar influence has already opened a bind.
  static bool isBindingClosed({
    required LiuYaoActorRef actor,
    required List<YaoAnalysisTag> tags,
    required LunarInfo lunarInfo,
  }) =>
      _evaluateBinding(
        actor: actor,
        ruleIds: tags
            .map(RuleIdentityService.resolveRuleId)
            .whereType<String>()
            .toSet(),
        lunarInfo: lunarInfo,
      ).closed;

  static ({bool closed, bool opened}) _evaluateBinding({
    required LiuYaoActorRef actor,
    required Set<String> ruleIds,
    required LunarInfo lunarInfo,
  }) {
    final peerBinding = ruleIds.contains(LiuYaoRuleIds.ruleMovingBound) ||
        ruleIds.contains(LiuYaoRuleIds.ruleMutualBinding);
    final peerBindingOpened = ruleIds.contains(LiuYaoRuleIds.ruleBindingOpened);
    final dayBinding =
        actor.isMoving && DiZhiRelations.isLiuHe(lunarInfo.riZhi, actor.branch);
    final monthBinding = actor.isMoving &&
        DiZhiRelations.isLiuHe(lunarInfo.yueJian, actor.branch);
    final dayBindingOpened = dayBinding &&
        DiZhiRelations.isLiuChong(lunarInfo.yueJian, actor.branch);
    final monthBindingOpened = monthBinding &&
        DiZhiRelations.isLiuChong(lunarInfo.riZhi, actor.branch);
    return (
      closed: (peerBinding && !peerBindingOpened) ||
          (dayBinding && !dayBindingOpened) ||
          (monthBinding && !monthBindingOpened),
      opened: peerBindingOpened || dayBindingOpened || monthBindingOpened,
    );
  }

  static LiuYaoActorRef mainActor(Yao yao) => LiuYaoActorRef(
        actorId: 'main:yao:${yao.position}',
        kind: LiuYaoActorKind.mainYao,
        position: yao.position,
        branch: yao.branch,
        wuXing: yao.wuXing,
        liuQin: yao.liuQin,
        isMoving: yao.isMoving,
      );

  static LiuYaoActorRef changedActor(Yao yao) => LiuYaoActorRef(
        actorId: 'changed:yao:${yao.position}',
        kind: LiuYaoActorKind.changedYao,
        position: yao.position,
        branch: yao.branch,
        wuXing: yao.wuXing,
        liuQin: yao.liuQin,
      );

  static LiuYaoActorRef hiddenActor(Yao yao) => LiuYaoActorRef(
        actorId: 'hidden:host-yao:${yao.position}',
        kind: LiuYaoActorKind.hiddenYao,
        position: yao.position,
        branch: yao.branch,
        wuXing: yao.wuXing,
        liuQin: yao.liuQin,
      );

  static LiuYaoActorRef calendarActor({
    required LiuYaoActorKind kind,
    required String branch,
  }) =>
      LiuYaoActorRef(
        actorId: kind == LiuYaoActorKind.calendarDay
            ? 'calendar:day'
            : 'calendar:month',
        kind: kind,
        branch: branch,
        wuXing: WuXingService.getWuXingFromBranch(branch)!,
      );
}
