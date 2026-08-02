import '../../../../services/shared/liuqin_service.dart';
import '../../../../services/shared/wuxing_service.dart';

enum LiuYaoAnalysisStatus {
  success,
  invalid,
}

enum LiuYaoActorKind {
  mainYao,
  changedYao,
  hiddenYao,
  calendarDay,
  calendarMonth,
}

enum LiuYaoRole {
  yongShen,
  duplicateYongShen,
  yuanShen,
  jiShen,
  chouShen,
  xianShen,
}

enum ActorAvailabilityState {
  active,
  suspended,
  suppressed,
  unavailable,
}

enum DirectedEffectKind {
  sheng,
  ke,
  fu,
  xie,
  hao,
  he,
  chong,
}

enum DirectedEffectStatus {
  active,
  suppressed,
}

class LiuYaoActorRef {
  const LiuYaoActorRef({
    required this.actorId,
    required this.kind,
    required this.branch,
    required this.wuXing,
    this.position,
    this.liuQin,
    this.isMoving = false,
  });

  final String actorId;
  final LiuYaoActorKind kind;
  final int? position;
  final String branch;
  final WuXing wuXing;
  final LiuQin? liuQin;
  final bool isMoving;
}

class LiuYaoRoleOccurrence {
  const LiuYaoRoleOccurrence({
    required this.actor,
    required this.role,
    required this.roleRuleId,
    required this.reason,
    this.selected = false,
    this.representative = false,
  });

  final LiuYaoActorRef actor;
  final LiuYaoRole role;
  final String roleRuleId;
  final String reason;
  final bool selected;
  final bool representative;
}

class ActorAvailability {
  const ActorAvailability({
    required this.actor,
    required this.state,
    required this.reasonRuleIds,
    this.releaseConditionRuleIds = const <String>[],
    this.suppressedByOccurrenceIds = const <String>[],
  });

  final LiuYaoActorRef actor;
  final ActorAvailabilityState state;
  final List<String> reasonRuleIds;
  final List<String> releaseConditionRuleIds;
  final List<String> suppressedByOccurrenceIds;

  bool get canTransmit => state == ActorAvailabilityState.active;
}

class DirectedEffectOccurrence {
  const DirectedEffectOccurrence({
    required this.occurrenceId,
    required this.ruleId,
    required this.fromActor,
    required this.toActor,
    required this.effect,
    required this.status,
    required this.pathActorIds,
    required this.pathStep,
    required this.sourceIds,
    this.suppressedByRuleIds = const <String>[],
    this.suppressedByOccurrenceIds = const <String>[],
    this.inputRefs = const <String>[],
  });

  final String occurrenceId;
  final String ruleId;
  final LiuYaoActorRef fromActor;
  final LiuYaoActorRef toActor;
  final DirectedEffectKind effect;
  final DirectedEffectStatus status;
  final List<String> pathActorIds;
  final int pathStep;
  final List<String> suppressedByRuleIds;
  final List<String> suppressedByOccurrenceIds;
  final List<String> sourceIds;
  final List<String> inputRefs;

  bool get isActive => status == DirectedEffectStatus.active;
}

class LiuYaoAnalysisTraceStep {
  const LiuYaoAnalysisTraceStep({
    required this.stageId,
    this.ruleIds = const <String>[],
    this.occurrenceIds = const <String>[],
    this.notes = const <String>[],
  });

  final String stageId;
  final List<String> ruleIds;
  final List<String> occurrenceIds;
  final List<String> notes;
}

class LiuYaoAnalysisStages {
  LiuYaoAnalysisStages._();

  static const String validateInput = 'liuyao.stage.01.validate-input';
  static const String freezeFacts = 'liuyao.stage.02.freeze-facts';
  static const String buildRoles = 'liuyao.stage.03.build-roles';
  static const String calculateState = 'liuyao.stage.04.calculate-state';
  static const String calculateAvailability =
      'liuyao.stage.05.calculate-availability';
  static const String calculateEffects =
      'liuyao.stage.06.calculate-directed-effects';
  static const String auxiliaryEvidence = 'liuyao.stage.07.auxiliary-evidence';
  static const String arbitrateConflicts =
      'liuyao.stage.08.arbitrate-conflicts';
  static const String judgeVerdict = 'liuyao.stage.09.judge-verdict';
  static const String calculateTiming = 'liuyao.stage.10.calculate-timing';
  static const String buildProjection = 'liuyao.stage.11.build-projection';

  static const List<String> ordered = <String>[
    validateInput,
    freezeFacts,
    buildRoles,
    calculateState,
    calculateAvailability,
    calculateEffects,
    auxiliaryEvidence,
    arbitrateConflicts,
    judgeVerdict,
    calculateTiming,
    buildProjection,
  ];
}
