import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_fact_support.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_conflict_resolver.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_verdict_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';

void main() {
  group('QimenConflictResolver', () {
    test('combined Fu-Yin explicitly subsumes equal-tier component facts', () {
      final star = _fact(
        ruleId: QimenRuleCatalog.starFuYin,
        target: 'global',
        role: QimenFactRole.neutral,
        tier: QimenConflictTier.conditional,
        scope: QimenFactScope.global,
        palaces: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      );
      final door = _fact(
        ruleId: QimenRuleCatalog.doorFuYin,
        target: 'global',
        role: QimenFactRole.neutral,
        tier: QimenConflictTier.conditional,
        scope: QimenFactScope.global,
        palaces: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      );
      final combined = _fact(
        ruleId: QimenRuleCatalog.combinedFuYin,
        target: 'global',
        role: QimenFactRole.suspend,
        tier: QimenConflictTier.conditional,
        scope: QimenFactScope.global,
        palaces: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      );

      final resolved = QimenConflictResolver.resolve(
        <QimenFact>[star, door, combined],
      );

      expect(resolved.resolutions, hasLength(2));
      expect(
        resolved.resolutions.map((value) => value.policyId).toSet(),
        <String>{QimenRuleCatalog.conflictExplicitPair},
      );
      expect(resolved.activeFacts, <QimenFact>[combined]);
      expect(
        resolved.trace.where(
          (step) => step.status == QimenEvaluationStatus.suppressed,
        ),
        hasLength(2),
      );
    });

    test('horse never suppresses or removes global combined Fu-Yin', () {
      final fuYin = _fact(
        ruleId: QimenRuleCatalog.combinedFuYin,
        target: 'global',
        role: QimenFactRole.suspend,
        tier: QimenConflictTier.conditional,
        scope: QimenFactScope.global,
        palaces: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        focusRoles: const <String>['self', 'matter'],
      );
      final primaryHorse = _fact(
        ruleId: QimenRuleCatalog.horseActivation,
        target: 'p2:申',
        role: QimenFactRole.support,
        tier: QimenConflictTier.corroborating,
        palaces: const <int>[2],
        focusRoles: const <String>['self'],
      );
      final resolved = QimenConflictResolver.resolve(<QimenFact>[
        fuYin,
        primaryHorse,
      ]);

      expect(resolved.resolutions, isEmpty);
      expect(resolved.activeFacts, contains(primaryHorse));
      expect(resolved.activeFacts, contains(fuYin));
      expect(
        QimenRuleCatalog.rule(QimenRuleCatalog.horseActivation).resolvesRuleIds,
        isNot(contains(QimenRuleCatalog.combinedFuYin)),
      );

      final secondaryHorse = _fact(
        ruleId: QimenRuleCatalog.horseActivation,
        target: 'p2:申:secondary',
        role: QimenFactRole.support,
        tier: QimenConflictTier.conditional,
        palaces: const <int>[2],
        focusRoles: const <String>['travelHorse'],
      );
      final unrelated = QimenConflictResolver.resolve(<QimenFact>[
        fuYin,
        secondaryHorse,
      ]);
      expect(unrelated.resolutions, isEmpty);
      expect(unrelated.activeFacts, contains(fuYin));
    });

    test('explicit pair runs before focus specificity and tier', () {
      final combined = _fact(
        ruleId: QimenRuleCatalog.combinedFuYin,
        target: 'global-tier',
        role: QimenFactRole.suspend,
        tier: QimenConflictTier.contextual,
        scope: QimenFactScope.global,
        palaces: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      );
      final component = _fact(
        ruleId: QimenRuleCatalog.starFuYin,
        target: 'component-tier',
        role: QimenFactRole.neutral,
        tier: QimenConflictTier.decisive,
        scope: QimenFactScope.global,
        palaces: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        focusRoles: const <String>['self'],
      );

      final result = QimenConflictResolver.resolve(<QimenFact>[
        combined,
        component,
      ]);

      expect(result.resolutions.single.policyId,
          QimenRuleCatalog.conflictExplicitPair);
      expect(
          result.resolutions.single.winnerOccurrenceId, combined.occurrenceId);
      expect(result.resolutions.single.suppressedOccurrenceIds,
          <String>[component.occurrenceId]);
    });

    test('applies focus specificity before tier precedence', () {
      final focused = _fact(
        ruleId: QimenRuleCatalog.starStateWang,
        target: 'focused',
        role: QimenFactRole.support,
        tier: QimenConflictTier.contextual,
        palaces: const <int>[1],
        focusRoles: const <String>['self'],
      );
      final global = _fact(
        ruleId: QimenRuleCatalog.starStateQiu,
        target: 'global',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        palaces: const <int>[1],
      );
      final result =
          QimenConflictResolver.resolve(<QimenFact>[focused, global]);

      expect(
        result.resolutions.single.policyId,
        QimenRuleCatalog.conflictFocusSpecificity,
      );
      expect(
          result.resolutions.single.winnerOccurrenceId, focused.occurrenceId);
    });

    test('applies tier precedence when focus specificity is equal', () {
      final contextual = _fact(
        ruleId: QimenRuleCatalog.starStateWang,
        target: 'contextual',
        role: QimenFactRole.support,
        tier: QimenConflictTier.contextual,
        palaces: const <int>[1],
        focusRoles: const <String>['self'],
      );
      final decisive = _fact(
        ruleId: QimenRuleCatalog.fiveNotMeeting,
        target: 'decisive',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        palaces: const <int>[1],
        focusRoles: const <String>['self'],
      );
      final result =
          QimenConflictResolver.resolve(<QimenFact>[contextual, decisive]);

      expect(
        result.resolutions.single.policyId,
        QimenRuleCatalog.conflictTierPrecedence,
      );
      expect(
          result.resolutions.single.winnerOccurrenceId, decisive.occurrenceId);
    });

    test('retains same-tier opposition as an unresolved conflict', () {
      final support = _fact(
        ruleId: QimenRuleCatalog.starStateWang,
        target: 'support',
        role: QimenFactRole.support,
        tier: QimenConflictTier.decisive,
        palaces: const <int>[1],
        focusRoles: const <String>['self'],
      );
      final inhibit = _fact(
        ruleId: QimenRuleCatalog.starStateQiu,
        target: 'inhibit',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        palaces: const <int>[1],
        focusRoles: const <String>['self'],
      );
      final result =
          QimenConflictResolver.resolve(<QimenFact>[support, inhibit]);

      expect(
        result.resolutions.single.policyId,
        QimenRuleCatalog.conflictUnresolved,
      );
      expect(result.resolutions.single.isUnresolved, true);
      expect(result.activeFacts, containsAll(<QimenFact>[support, inhibit]));
    });
  });

  group('QimenVerdictService', () {
    for (final rowId in const <String>[
      QimenRuleCatalog.decision00,
      QimenRuleCatalog.decision10,
      QimenRuleCatalog.decision20,
      QimenRuleCatalog.decision30,
      QimenRuleCatalog.decision40,
      QimenRuleCatalog.decision50,
      QimenRuleCatalog.decision60,
    ]) {
      test('isolates decision row $rowId', () {
        final evaluation = _isolatedDecisionEvaluation(rowId);
        expect(evaluation.result.matchedDecisionRowId, rowId);
        expect(
          evaluation.trace
              .where((step) => step.status == QimenEvaluationStatus.matched),
          hasLength(1),
        );
      });
    }

    test('covers every decision row with a unique first match', () {
      final decisiveBlocker = _fact(
        ruleId: QimenRuleCatalog.fiveNotMeeting,
        target: 'blocker',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        focusRoles: const <String>['self', 'matter'],
      );
      final voidFact = _fact(
        ruleId: QimenRuleCatalog.voidState,
        target: 'void',
        role: QimenFactRole.suspend,
        tier: QimenConflictTier.conditional,
        palaces: const <int>[1],
        focusRoles: const <String>['self'],
        refs: <QimenInputRef>[
          const QimenInputRef(
            path: r'$.palaces[number=1].voidBranches',
            value: '子',
          ),
        ],
      );
      final adverse = _fact(
        ruleId: QimenRuleCatalog.adverseConvergence,
        target: 'adverse',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        focusRoles: const <String>['self', 'matter'],
      );
      final favorable = _fact(
        ruleId: QimenRuleCatalog.favorableConvergence,
        target: 'favorable',
        role: QimenFactRole.support,
        tier: QimenConflictTier.decisive,
        focusRoles: const <String>['self', 'matter'],
      );
      final unresolvedFacts = <QimenFact>[
        _fact(
          ruleId: QimenRuleCatalog.starStateWang,
          target: 'unresolved-support',
          role: QimenFactRole.support,
          tier: QimenConflictTier.decisive,
          palaces: const <int>[1],
          focusRoles: const <String>['self'],
        ),
        _fact(
          ruleId: QimenRuleCatalog.starStateQiu,
          target: 'unresolved-inhibit',
          role: QimenFactRole.inhibit,
          tier: QimenConflictTier.decisive,
          palaces: const <int>[1],
          focusRoles: const <String>['self'],
        ),
      ];
      final unresolved = QimenConflictResolver.resolve(unresolvedFacts);

      final cases = <({
        String rowId,
        QimenAnalysisStatus status,
        bool uniqueFocus,
        List<QimenFact> facts,
        List<QimenConflictResolution> conflicts,
      })>[
        (
          rowId: QimenRuleCatalog.decision00,
          status: QimenAnalysisStatus.invalidPanFacts,
          uniqueFocus: false,
          facts: const <QimenFact>[],
          conflicts: const <QimenConflictResolution>[],
        ),
        (
          rowId: QimenRuleCatalog.decision10,
          status: QimenAnalysisStatus.complete,
          uniqueFocus: true,
          facts: <QimenFact>[decisiveBlocker],
          conflicts: const <QimenConflictResolution>[],
        ),
        (
          rowId: QimenRuleCatalog.decision20,
          status: QimenAnalysisStatus.complete,
          uniqueFocus: true,
          facts: <QimenFact>[voidFact],
          conflicts: const <QimenConflictResolution>[],
        ),
        (
          rowId: QimenRuleCatalog.decision30,
          status: QimenAnalysisStatus.complete,
          uniqueFocus: true,
          facts: <QimenFact>[adverse],
          conflicts: const <QimenConflictResolution>[],
        ),
        (
          rowId: QimenRuleCatalog.decision40,
          status: QimenAnalysisStatus.complete,
          uniqueFocus: true,
          facts: <QimenFact>[favorable],
          conflicts: const <QimenConflictResolution>[],
        ),
        (
          rowId: QimenRuleCatalog.decision50,
          status: QimenAnalysisStatus.complete,
          uniqueFocus: true,
          facts: unresolved.activeFacts,
          conflicts: unresolved.resolutions,
        ),
        (
          rowId: QimenRuleCatalog.decision60,
          status: QimenAnalysisStatus.complete,
          uniqueFocus: true,
          facts: const <QimenFact>[],
          conflicts: const <QimenConflictResolution>[],
        ),
      ];

      for (final testCase in cases) {
        final evaluation = _judge(
          status: testCase.status,
          uniqueFocus: testCase.uniqueFocus,
          facts: testCase.facts,
          conflicts: testCase.conflicts,
        );
        expect(
          evaluation.result.matchedDecisionRowId,
          testCase.rowId,
          reason: testCase.rowId,
        );
        expect(
          evaluation.trace
              .where((step) => step.status == QimenEvaluationStatus.matched),
          hasLength(1),
          reason: testCase.rowId,
        );
      }
    });

    test('higher decision row wins and irrelevant context cannot outvote it',
        () {
      final blocker = _fact(
        ruleId: QimenRuleCatalog.fiveNotMeeting,
        target: 'blocker',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        focusRoles: const <String>['self'],
      );
      final condition = _fact(
        ruleId: QimenRuleCatalog.voidState,
        target: 'condition',
        role: QimenFactRole.suspend,
        tier: QimenConflictTier.conditional,
        focusRoles: const <String>['self'],
        refs: const <QimenInputRef>[
          QimenInputRef(
            path: r'$.palaces[number=1].voidBranches',
            value: '子',
          ),
        ],
      );
      final context = _fact(
        ruleId: QimenRuleCatalog.starStateXiang,
        target: 'context',
        role: QimenFactRole.support,
        tier: QimenConflictTier.contextual,
      );

      expect(
        _judge(facts: <QimenFact>[blocker, condition])
            .result
            .matchedDecisionRowId,
        QimenRuleCatalog.decision10,
      );
      expect(
        _judge(facts: <QimenFact>[blocker, condition, context])
            .result
            .matchedDecisionRowId,
        QimenRuleCatalog.decision10,
      );
    });

    test('unresolved decisive conflict precedes adverse convergence', () {
      final support = _fact(
        ruleId: QimenRuleCatalog.favorableConvergence,
        target: 'overlap-support',
        role: QimenFactRole.support,
        tier: QimenConflictTier.decisive,
        focusRoles: const <String>['self', 'matter'],
      );
      final adverse = _fact(
        ruleId: QimenRuleCatalog.adverseConvergence,
        target: 'overlap-adverse',
        role: QimenFactRole.inhibit,
        tier: QimenConflictTier.decisive,
        focusRoles: const <String>['self', 'matter'],
      );
      final conflict =
          QimenConflictResolver.resolve(<QimenFact>[support, adverse]);

      expect(
        _judge(
          facts: conflict.activeFacts,
          conflicts: conflict.resolutions,
        ).result.matchedDecisionRowId,
        QimenRuleCatalog.decision50,
      );
    });

    test('tomb fact creates the adopted opposite-branch release condition', () {
      final tomb = _fact(
        ruleId: QimenRuleCatalog.qiYiTomb,
        target: 'yi-p2',
        role: QimenFactRole.suspend,
        tier: QimenConflictTier.conditional,
        palaces: const <int>[2],
        focusRoles: const <String>['self'],
        refs: const <QimenInputRef>[
          QimenInputRef(
            path: r'$.palaces[number=2].heavenStem',
            value: '乙',
          ),
        ],
      );
      final verdict = _judge(facts: <QimenFact>[tomb]).result;
      final condition = verdict.conditionLinks.single;

      expect(verdict.matchedDecisionRowId, QimenRuleCatalog.decision20);
      expect(condition.condition.branch, '丑');
      expect(condition.releaseTriggerKind, 'branch');
      expect(condition.releaseTriggerValue, '丑');
      expect(condition.releaseScale, YingQiScale.ri);
    });
  });
}

QimenFact _fact({
  required String ruleId,
  required String target,
  required QimenFactRole role,
  required QimenConflictTier tier,
  QimenFactScope scope = QimenFactScope.palace,
  List<int> palaces = const <int>[],
  List<String> focusRoles = const <String>[],
  List<QimenInputRef> refs = const <QimenInputRef>[],
}) =>
    QimenFactSupport.fact(
      ruleSetVersion: QimenRuleCatalog.v1,
      ruleId: ruleId,
      targetKey: target,
      category: QimenFactCategory.relation,
      scope: scope,
      reason: 'test fact $ruleId',
      inputRefs: refs,
      palaceNumbers: palaces,
      focusRoleIds: focusRoles,
      role: role,
      tier: tier,
    );

QimenVerdictEvaluation _judge({
  QimenAnalysisStatus status = QimenAnalysisStatus.complete,
  bool uniqueFocus = true,
  List<QimenFact> facts = const <QimenFact>[],
  List<QimenConflictResolution> conflicts = const <QimenConflictResolution>[],
}) =>
    QimenVerdictService.judge(
      status: status,
      diagnostics: const <QimenAnalysisDiagnostic>[],
      focuses: const <QimenFocus>[],
      hasUniquePrimaryFocus: uniqueFocus,
      activeFacts: facts,
      conflicts: conflicts,
    );

QimenVerdictEvaluation _isolatedDecisionEvaluation(String rowId) {
  switch (rowId) {
    case QimenRuleCatalog.decision00:
      return _judge(
        status: QimenAnalysisStatus.invalidPanFacts,
        uniqueFocus: false,
      );
    case QimenRuleCatalog.decision10:
      return _judge(facts: <QimenFact>[
        _fact(
          ruleId: QimenRuleCatalog.fiveNotMeeting,
          target: 'isolated-blocker',
          role: QimenFactRole.inhibit,
          tier: QimenConflictTier.decisive,
          focusRoles: const <String>['self'],
        ),
      ]);
    case QimenRuleCatalog.decision20:
      return _judge(facts: <QimenFact>[
        _fact(
          ruleId: QimenRuleCatalog.voidState,
          target: 'isolated-condition',
          role: QimenFactRole.suspend,
          tier: QimenConflictTier.conditional,
          palaces: const <int>[1],
          focusRoles: const <String>['self'],
          refs: const <QimenInputRef>[
            QimenInputRef(
              path: r'$.palaces[number=1].voidBranches',
              value: '子',
            ),
          ],
        ),
      ]);
    case QimenRuleCatalog.decision30:
      return _judge(facts: <QimenFact>[
        _fact(
          ruleId: QimenRuleCatalog.adverseConvergence,
          target: 'isolated-adverse',
          role: QimenFactRole.inhibit,
          tier: QimenConflictTier.decisive,
          focusRoles: const <String>['self', 'matter'],
        ),
      ]);
    case QimenRuleCatalog.decision40:
      return _judge(facts: <QimenFact>[
        _fact(
          ruleId: QimenRuleCatalog.favorableConvergence,
          target: 'isolated-favorable',
          role: QimenFactRole.support,
          tier: QimenConflictTier.decisive,
          focusRoles: const <String>['self', 'matter'],
        ),
      ]);
    case QimenRuleCatalog.decision50:
      final facts = <QimenFact>[
        _fact(
          ruleId: QimenRuleCatalog.starStateWang,
          target: 'isolated-support',
          role: QimenFactRole.support,
          tier: QimenConflictTier.decisive,
          palaces: const <int>[1],
          focusRoles: const <String>['self'],
        ),
        _fact(
          ruleId: QimenRuleCatalog.starStateQiu,
          target: 'isolated-inhibit',
          role: QimenFactRole.inhibit,
          tier: QimenConflictTier.decisive,
          palaces: const <int>[1],
          focusRoles: const <String>['self'],
        ),
      ];
      final conflict = QimenConflictResolver.resolve(facts);
      return _judge(
        facts: conflict.activeFacts,
        conflicts: conflict.resolutions,
      );
    case QimenRuleCatalog.decision60:
      return _judge();
    default:
      throw ArgumentError.value(rowId, 'rowId');
  }
}
