import 'models/qimen_analysis_models.dart';
import 'models/qimen_rule_models.dart';
import 'rules/qimen_rule_catalog.dart';

class QimenConflictResult {
  const QimenConflictResult({
    required this.activeFacts,
    required this.resolutions,
    required this.trace,
  });

  final List<QimenFact> activeFacts;
  final List<QimenConflictResolution> resolutions;
  final List<QimenTraceStep> trace;
}

class QimenConflictResolver {
  QimenConflictResolver._();

  static QimenConflictResult resolve(List<QimenFact> facts) {
    final orderedFacts = [...facts]
      ..sort((left, right) => left.occurrenceId.compareTo(right.occurrenceId));
    final suppressed = <String>{};
    final resolutions = <QimenConflictResolution>[];
    final trace = <QimenTraceStep>[];

    void record({
      required String policyId,
      required QimenFact left,
      required QimenFact right,
      required String reason,
      QimenFact? winner,
      QimenFact? loser,
    }) {
      final contenders = <String>[left.occurrenceId, right.occurrenceId]
        ..sort();
      final resolution = QimenConflictResolution(
        resolutionId: '$policyId@${contenders.join('|')}',
        policyId: policyId,
        contenderOccurrenceIds: contenders,
        winnerOccurrenceId: winner?.occurrenceId,
        suppressedOccurrenceIds:
            loser == null ? const <String>[] : <String>[loser.occurrenceId],
        reason: reason,
      );
      resolutions.add(resolution);
      if (loser != null) suppressed.add(loser.occurrenceId);
      trace.add(QimenTraceStep(
        stepId: 'conflict:${resolution.resolutionId}',
        sequence: -1,
        stage: QimenTraceStage.conflict,
        ruleId: policyId,
        status: QimenEvaluationStatus.matched,
        inputRefs: const <QimenInputRef>[],
        outputOccurrenceIds: contenders,
        sourceIds: QimenRuleCatalog.rule(policyId).sourceIds,
        explanation: reason,
      ));
      if (loser != null) {
        trace.add(QimenTraceStep(
          stepId: 'conflict:suppressed:${loser.occurrenceId}',
          sequence: -1,
          stage: QimenTraceStage.conflict,
          ruleId: loser.ruleId,
          status: QimenEvaluationStatus.suppressed,
          inputRefs: loser.inputRefs,
          outputOccurrenceIds: <String>[loser.occurrenceId],
          sourceIds: loser.sourceIds,
          explanation: '${loser.occurrenceId}由$policyId压制；胜出事实为'
              '${winner!.occurrenceId}。',
        ));
      }
    }

    for (var leftIndex = 0; leftIndex < orderedFacts.length; leftIndex++) {
      final left = orderedFacts[leftIndex];
      if (suppressed.contains(left.occurrenceId)) continue;
      for (var rightIndex = leftIndex + 1;
          rightIndex < orderedFacts.length;
          rightIndex++) {
        final right = orderedFacts[rightIndex];
        if (suppressed.contains(right.occurrenceId) ||
            !_overlaps(left, right)) {
          continue;
        }
        final explicitResolver = _explicitResolver(left, right);
        final directionalOpposition = _isDirectional(left) &&
            _isDirectional(right) &&
            left.role != right.role;
        if (explicitResolver == null && !directionalOpposition) continue;

        if (explicitResolver != null) {
          final loser = identical(explicitResolver, left) ? right : left;
          record(
            policyId: QimenRuleCatalog.conflictExplicitPair,
            left: left,
            right: right,
            winner: explicitResolver,
            loser: loser,
            reason: '${explicitResolver.ruleId}按目录显式覆盖${loser.ruleId}；'
                '显式成对规则先于焦点特异性与规则层级，被覆盖事实仍保留供审计。',
          );
          if (identical(loser, left)) break;
          continue;
        }

        final leftSpecificity = _specificity(left);
        final rightSpecificity = _specificity(right);
        if (leftSpecificity != rightSpecificity) {
          final winner = leftSpecificity > rightSpecificity ? left : right;
          final loser = identical(winner, left) ? right : left;
          record(
            policyId: QimenRuleCatalog.conflictFocusSpecificity,
            left: left,
            right: right,
            winner: winner,
            loser: loser,
            reason: '${winner.occurrenceId}直接关联更具体的问事焦点，'
                '优先于${loser.occurrenceId}。',
          );
          if (identical(loser, left)) break;
          continue;
        }

        if (left.conflictTier.order != right.conflictTier.order) {
          final winner =
              left.conflictTier.order < right.conflictTier.order ? left : right;
          final loser = identical(winner, left) ? right : left;
          record(
            policyId: QimenRuleCatalog.conflictTierPrecedence,
            left: left,
            right: right,
            winner: winner,
            loser: loser,
            reason: '${winner.conflictTier.id}层${winner.occurrenceId}优先于'
                '${loser.conflictTier.id}层${loser.occurrenceId}。',
          );
          if (identical(loser, left)) break;
          continue;
        }

        record(
          policyId: QimenRuleCatalog.conflictUnresolved,
          left: left,
          right: right,
          reason: '同一目标的扶抑事实处于相同层级且无显式解救，双方均保留为未决冲突。',
        );
      }
    }

    final matchedPolicies = resolutions.map((value) => value.policyId).toSet();
    for (final policyId in const <String>[
      QimenRuleCatalog.conflictExplicitPair,
      QimenRuleCatalog.conflictFocusSpecificity,
      QimenRuleCatalog.conflictTierPrecedence,
      QimenRuleCatalog.conflictUnresolved,
    ]) {
      if (!matchedPolicies.contains(policyId)) {
        trace.add(QimenTraceStep(
          stepId: 'conflict:$policyId@none',
          sequence: -1,
          stage: QimenTraceStage.conflict,
          ruleId: policyId,
          status: QimenEvaluationStatus.notMatched,
          inputRefs: const <QimenInputRef>[],
          outputOccurrenceIds: const <String>[],
          sourceIds: QimenRuleCatalog.rule(policyId).sourceIds,
          explanation: '本次分析未触发${QimenRuleCatalog.rule(policyId).displayTerm}。',
        ));
      }
    }

    resolutions.sort(
      (left, right) => left.resolutionId.compareTo(right.resolutionId),
    );
    final active = orderedFacts
        .where((fact) => !suppressed.contains(fact.occurrenceId))
        .toList(growable: false);
    return QimenConflictResult(
      activeFacts: List<QimenFact>.unmodifiable(active),
      resolutions: List<QimenConflictResolution>.unmodifiable(resolutions),
      trace: List<QimenTraceStep>.unmodifiable(trace),
    );
  }

  static bool _isDirectional(QimenFact fact) =>
      fact.role == QimenFactRole.support || fact.role == QimenFactRole.inhibit;

  static QimenFact? _explicitResolver(QimenFact left, QimenFact right) {
    final leftDefinition = QimenRuleCatalog.rule(left.ruleId);
    final rightDefinition = QimenRuleCatalog.rule(right.ruleId);
    final QimenFact? resolver;
    if (leftDefinition.resolvesRuleIds.contains(right.ruleId) ||
        rightDefinition.suppressedByRuleIds.contains(left.ruleId)) {
      resolver = left;
    } else if (rightDefinition.resolvesRuleIds.contains(left.ruleId) ||
        leftDefinition.suppressedByRuleIds.contains(right.ruleId)) {
      resolver = right;
    } else {
      return null;
    }

    return resolver;
  }

  static int _specificity(QimenFact fact) {
    if (fact.relatedFocusRoleIds.any(
      (role) => role == 'self' || role == 'matter',
    )) {
      return 2;
    }
    if (fact.relatedFocusRoleIds.isNotEmpty) return 1;
    return 0;
  }

  static bool _overlaps(QimenFact left, QimenFact right) {
    if (left.relatedFocusRoleIds.any(right.relatedFocusRoleIds.contains)) {
      return true;
    }
    if (left.relatedPalaceNumbers.any(right.relatedPalaceNumbers.contains)) {
      return true;
    }
    return left.scope == QimenFactScope.global &&
        right.scope == QimenFactScope.global;
  }
}
