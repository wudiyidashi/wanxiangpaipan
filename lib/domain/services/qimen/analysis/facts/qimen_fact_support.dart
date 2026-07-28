import '../../../shared/analysis/models/polarity.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../qimen_input_ref_resolver.dart';
import '../rules/qimen_rule_catalog.dart';

class QimenFactBatch {
  const QimenFactBatch({required this.facts, required this.trace});

  final List<QimenFact> facts;
  final List<QimenTraceStep> trace;
}

class QimenFactSupport {
  QimenFactSupport._();

  static const Map<String, String> starElements = <String, String>{
    '天蓬': '水',
    '天芮': '土',
    '天冲': '木',
    '天辅': '木',
    '天禽': '土',
    '天心': '金',
    '天柱': '金',
    '天任': '土',
    '天英': '火',
  };

  static const Map<String, String> doorElements = <String, String>{
    '休门': '水',
    '生门': '土',
    '伤门': '木',
    '杜门': '木',
    '景门': '火',
    '死门': '土',
    '惊门': '金',
    '开门': '金',
  };

  static const Map<String, String> generates = <String, String>{
    '木': '火',
    '火': '土',
    '土': '金',
    '金': '水',
    '水': '木',
  };

  static const Map<String, String> controls = <String, String>{
    '木': '土',
    '土': '水',
    '水': '火',
    '火': '金',
    '金': '木',
  };

  static List<String> focusRolesAt(
    int palaceNumber,
    List<QimenFocus> focuses,
  ) {
    final roles = focuses
        .where((focus) => focus.palaceNumber == palaceNumber)
        .map((focus) => focus.roleId)
        .toSet()
        .toList(growable: false)
      ..sort();
    return roles;
  }

  static QimenFact fact({
    required String ruleId,
    required String ruleSetVersion,
    required String targetKey,
    required QimenFactCategory category,
    required QimenFactScope scope,
    required String reason,
    required List<QimenInputRef> inputRefs,
    required List<int> palaceNumbers,
    required List<String> focusRoleIds,
    Polarity? polarity,
    QimenFactRole? role,
    QimenConflictTier? tier,
  }) {
    final definition = QimenRuleCatalog.rule(ruleId);
    final occurrenceId = '$ruleId@$targetKey';
    final sortedPalaces = palaceNumbers.toSet().toList(growable: false)..sort();
    final sortedRoles = focusRoleIds.toSet().toList(growable: false)..sort();
    final sortedSources = definition.sourceIds.toSet().toList(growable: false)
      ..sort();
    final actualRole = role ?? definition.factRole;
    return QimenFact(
      occurrenceId: occurrenceId,
      ruleId: ruleId,
      ruleSetVersion: ruleSetVersion,
      category: category,
      polarity: polarity ?? _polarityForRole(actualRole),
      role: actualRole,
      scope: scope,
      relatedPalaceNumbers: sortedPalaces,
      relatedFocusRoleIds: sortedRoles,
      reason: reason,
      inputRefs: inputRefs,
      sourceIds: sortedSources,
      traceStepId: 'fact:$occurrenceId',
      conflictTier: tier ?? definition.conflictTier,
    );
  }

  static QimenTraceStep matchedTrace(QimenFact fact) => QimenTraceStep(
        stepId: fact.traceStepId,
        sequence: -1,
        stage: QimenTraceStage.fact,
        ruleId: fact.ruleId,
        status: QimenEvaluationStatus.matched,
        inputRefs: fact.inputRefs,
        outputOccurrenceIds: <String>[fact.occurrenceId],
        sourceIds: fact.sourceIds,
        explanation: fact.reason,
      );

  static QimenTraceStep notMatchedTrace({
    required String ruleId,
    required String targetKey,
    required List<QimenInputRef> inputRefs,
    required String explanation,
    QimenEvaluationStatus status = QimenEvaluationStatus.notMatched,
  }) {
    final sourceIds = [...QimenRuleCatalog.rule(ruleId).sourceIds]..sort();
    return QimenTraceStep(
      stepId: 'fact:$ruleId@$targetKey',
      sequence: -1,
      stage: QimenTraceStage.fact,
      ruleId: ruleId,
      status: status,
      inputRefs: inputRefs,
      outputOccurrenceIds: const <String>[],
      sourceIds: sourceIds,
      explanation: explanation,
    );
  }

  static QimenFactBatch batch(
    List<QimenFact> facts,
    List<QimenTraceStep> trace,
  ) =>
      QimenFactBatch(
        facts: List<QimenFact>.unmodifiable(facts),
        trace: List<QimenTraceStep>.unmodifiable(trace),
      );

  static QimenFactBatch factsWithTraces(List<QimenFact> facts) => batch(
        facts,
        facts.map(matchedTrace).toList(growable: false),
      );

  static String palacePath(int number, String field) =>
      QimenInputPath.palace(number, field);

  static Polarity _polarityForRole(QimenFactRole role) => switch (role) {
        QimenFactRole.support => Polarity.ji,
        QimenFactRole.inhibit => Polarity.xiong,
        QimenFactRole.suspend => Polarity.neutral,
        QimenFactRole.neutral => Polarity.neutral,
      };
}
