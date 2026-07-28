import '../../shared/analysis/models/verdict_models.dart';
import 'models/qimen_analysis_models.dart';
import 'models/qimen_rule_models.dart';
import 'models/qimen_ying_qi_models.dart';
import 'rules/qimen_rule_catalog.dart';

class QimenYingQiEvaluation {
  const QimenYingQiEvaluation({
    required this.candidates,
    required this.trace,
  });

  final List<QimenYingQiCandidate> candidates;
  final List<QimenTraceStep> trace;
}

class QimenYingQiService {
  QimenYingQiService._();

  static QimenYingQiEvaluation calculate({
    required List<QimenFact> activeFacts,
    required QimenVerdictResult verdict,
  }) {
    final raw = <QimenYingQiCandidate>[];
    final factsById = <String, QimenFact>{
      for (final fact in activeFacts) fact.occurrenceId: fact,
    };

    for (final condition in verdict.conditionLinks) {
      final fact = factsById[condition.sourceFactId];
      if (fact == null) {
        throw StateError(
          'Qimen YingQi condition has no upstream fact: '
          '${condition.conditionId}',
        );
      }
      raw.add(_candidate(
        ruleId: QimenRuleCatalog.yingQiConditionRelease,
        triggerKind:
            QimenYingQiTriggerKind.fromId(condition.releaseTriggerKind),
        triggerValue: condition.releaseTriggerValue,
        scale: condition.releaseScale,
        orderBand: QimenYingQiOrderBand.conditionRelease,
        targetFocusRoleId: _primaryTarget(fact),
        reason:
            '${condition.condition.reason} ${_scaleLabel(condition.releaseScale)}尺度'
            '只观察条件成熟或状态解除，'
            '不保证事情发生，也不改变程序裁决。',
        relatedFactIds: <String>[fact.occurrenceId],
        relatedConditionIds: <String>[condition.conditionId],
        sourceIds: condition.sourceIds,
      ));
    }

    for (final fact in activeFacts) {
      if (fact.ruleId == QimenRuleCatalog.horseActivation &&
          fact.relatedFocusRoleIds.isNotEmpty) {
        final branch = _refValue(fact, r'$.horseBranch');
        if (branch != null) {
          for (final role in fact.relatedFocusRoleIds.where(
            (value) => value == 'self' || value == 'matter',
          )) {
            raw.add(_candidate(
              ruleId: QimenRuleCatalog.yingQiHorse,
              triggerKind: QimenYingQiTriggerKind.branch,
              triggerValue: branch,
              scale: YingQiScale.ri,
              orderBand: QimenYingQiOrderBand.focusActivation,
              targetFocusRoleId: role,
              reason: '驿马$branch与焦点$role同宫，按日尺度观察发动；'
                  '不保证成败或具体事件发生。',
              relatedFactIds: <String>[fact.occurrenceId],
              sourceIds: fact.sourceIds,
            ));
          }
        }
      }
      if (fact.category == QimenFactCategory.starState &&
          fact.role == QimenFactRole.support &&
          fact.relatedFocusRoleIds.isNotEmpty) {
        final term = _refValue(fact, r'$.temporalContext.currentSolarTerm');
        if (term != null) {
          for (final role in fact.relatedFocusRoleIds) {
            raw.add(_candidate(
              ruleId: QimenRuleCatalog.yingQiSolarTerm,
              triggerKind: QimenYingQiTriggerKind.solarTerm,
              triggerValue: term,
              scale: YingQiScale.yue,
              orderBand: QimenYingQiOrderBand.contextWindow,
              targetFocusRoleId: role,
              reason: '$term令支持焦点$role的星态，按月尺度观察同类季令；'
                  '不据此保证事件发生。',
              relatedFactIds: <String>[fact.occurrenceId],
              sourceIds: fact.sourceIds,
            ));
          }
        }
      }
    }

    final merged = <String, QimenYingQiCandidate>{};
    for (final candidate in raw) {
      final existing = merged[candidate.deduplicationKey];
      if (existing == null) {
        merged[candidate.deduplicationKey] = candidate;
      } else {
        merged[candidate.deduplicationKey] = _merge(existing, candidate);
      }
    }
    final candidates = merged.values.toList(growable: false)
      ..sort(_compareCandidates);
    for (final candidate in candidates) {
      if ((candidate.relatedFactIds.isEmpty &&
              candidate.relatedConditionIds.isEmpty) ||
          candidate.sourceIds.isEmpty) {
        throw StateError(
          'Orphan Qimen YingQi candidate: ${candidate.candidateId}',
        );
      }
    }

    final trace = <QimenTraceStep>[
      for (final candidate in candidates)
        QimenTraceStep(
          stepId: 'yingQi:${candidate.candidateId}',
          sequence: -1,
          stage: QimenTraceStage.yingQi,
          ruleId: candidate.ruleId,
          status: QimenEvaluationStatus.matched,
          inputRefs: const <QimenInputRef>[],
          outputOccurrenceIds: <String>[candidate.candidateId],
          sourceIds: candidate.sourceIds,
          explanation: candidate.reason,
        ),
    ];
    final matchedRules = candidates.map((value) => value.ruleId).toSet();
    for (final ruleId in const <String>[
      QimenRuleCatalog.yingQiConditionRelease,
      QimenRuleCatalog.yingQiHorse,
      QimenRuleCatalog.yingQiFuYin,
      QimenRuleCatalog.yingQiFanYin,
      QimenRuleCatalog.yingQiStem,
      QimenRuleCatalog.yingQiSolarTerm,
    ]) {
      if (!matchedRules.contains(ruleId)) {
        final explicitlyExcluded = ruleId == QimenRuleCatalog.yingQiFuYin ||
            ruleId == QimenRuleCatalog.yingQiFanYin ||
            ruleId == QimenRuleCatalog.yingQiStem;
        trace.add(QimenTraceStep(
          stepId: 'yingQi:$ruleId@none',
          sequence: -1,
          stage: QimenTraceStage.yingQi,
          ruleId: ruleId,
          status: explicitlyExcluded
              ? QimenEvaluationStatus.notApplicable
              : QimenEvaluationStatus.notMatched,
          inputRefs: const <QimenInputRef>[],
          outputOccurrenceIds: const <String>[],
          sourceIds: QimenRuleCatalog.rule(ruleId).sourceIds,
          explanation: explicitlyExcluded
              ? 'v1没有锁定可由该事实直接推出的干支到临谓词，显式不生成候选。'
              : '没有满足来源链与适用条件的应期观察窗。',
        ));
      }
    }
    return QimenYingQiEvaluation(
      candidates: List<QimenYingQiCandidate>.unmodifiable(candidates),
      trace: List<QimenTraceStep>.unmodifiable(trace),
    );
  }

  static QimenYingQiCandidate _candidate({
    required String ruleId,
    required QimenYingQiTriggerKind triggerKind,
    required String triggerValue,
    required YingQiScale scale,
    required QimenYingQiOrderBand orderBand,
    required String reason,
    required List<String> relatedFactIds,
    required List<String> sourceIds,
    String? targetFocusRoleId,
    List<String> relatedConditionIds = const <String>[],
  }) {
    final target = targetFocusRoleId ?? 'global';
    final scaleId = qimenYingQiScaleId(scale);
    return QimenYingQiCandidate(
      candidateId: '$ruleId@$scaleId:${triggerKind.id}:$triggerValue:$target',
      ruleId: ruleId,
      triggerKind: triggerKind,
      triggerValue: triggerValue,
      scale: scale,
      orderBand: orderBand,
      targetFocusRoleId: targetFocusRoleId,
      reason: reason,
      relatedFactIds: _sorted(relatedFactIds),
      relatedConditionIds: _sorted(relatedConditionIds),
      sourceIds: _sorted(<String>[
        ...QimenRuleCatalog.rule(ruleId).sourceIds,
        ...sourceIds,
      ]),
    );
  }

  static QimenYingQiCandidate _merge(
    QimenYingQiCandidate left,
    QimenYingQiCandidate right,
  ) {
    final reasons = <String>{left.reason, right.reason}.toList(growable: false)
      ..sort();
    final ruleId =
        left.ruleId.compareTo(right.ruleId) <= 0 ? left.ruleId : right.ruleId;
    final band = left.orderBand.order <= right.orderBand.order
        ? left.orderBand
        : right.orderBand;
    return QimenYingQiCandidate(
      candidateId: left.candidateId.compareTo(right.candidateId) <= 0
          ? left.candidateId
          : right.candidateId,
      ruleId: ruleId,
      triggerKind: left.triggerKind,
      triggerValue: left.triggerValue,
      scale: left.scale,
      orderBand: band,
      targetFocusRoleId: left.targetFocusRoleId,
      reason: reasons.join('；'),
      relatedFactIds: _sorted(
        <String>[...left.relatedFactIds, ...right.relatedFactIds],
      ),
      relatedConditionIds: _sorted(
        <String>[
          ...left.relatedConditionIds,
          ...right.relatedConditionIds,
        ],
      ),
      sourceIds: _sorted(<String>[...left.sourceIds, ...right.sourceIds]),
    );
  }

  static int _compareCandidates(
    QimenYingQiCandidate left,
    QimenYingQiCandidate right,
  ) {
    var comparison = left.orderBand.order.compareTo(right.orderBand.order);
    if (comparison != 0) return comparison;
    comparison = left.ruleId.compareTo(right.ruleId);
    if (comparison != 0) return comparison;
    comparison = left.triggerKind.id.compareTo(right.triggerKind.id);
    if (comparison != 0) return comparison;
    comparison = left.triggerValue.compareTo(right.triggerValue);
    if (comparison != 0) return comparison;
    return (left.targetFocusRoleId ?? '')
        .compareTo(right.targetFocusRoleId ?? '');
  }

  static List<String> _sorted(Iterable<String> values) {
    final result = values.toSet().toList(growable: false)..sort();
    return result;
  }

  static String? _primaryTarget(QimenFact fact) {
    if (fact.relatedFocusRoleIds.contains('self')) return 'self';
    if (fact.relatedFocusRoleIds.contains('matter')) return 'matter';
    return fact.relatedFocusRoleIds.firstOrNull;
  }

  static String? _refValue(QimenFact fact, String path) {
    for (final ref in fact.inputRefs) {
      if (ref.path == path || ref.path.endsWith(path)) return ref.value;
    }
    return null;
  }

  static String _scaleLabel(YingQiScale scale) => switch (scale) {
        YingQiScale.ri => '日',
        YingQiScale.yue => '月',
        YingQiScale.nian => '年',
      };
}
