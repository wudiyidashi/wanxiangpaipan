import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_fact_support.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_ying_qi_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_verdict_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_ying_qi_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_source_catalog.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';

void main() {
  group('QimenYingQiService', () {
    test('deduplicates evidence and orders explicit day/month scales', () {
      final voidFact = _fact(
        ruleId: QimenRuleCatalog.voidState,
        target: 'void',
        category: QimenFactCategory.constraint,
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
      final verdict = QimenVerdictService.judge(
        status: QimenAnalysisStatus.complete,
        diagnostics: const <QimenAnalysisDiagnostic>[],
        focuses: const <QimenFocus>[],
        hasUniquePrimaryFocus: true,
        activeFacts: <QimenFact>[voidFact],
        conflicts: const <QimenConflictResolution>[],
      ).result;
      final annualCondition = QimenVerdictCondition(
        conditionId: 'QMV1-COND@annual',
        sourceFactId: voidFact.occurrenceId,
        ruleId: QimenRuleCatalog.voidState,
        condition: const VerdictCondition(
          label: '待子年填实',
          branch: '子',
          reason: '年尺度条件样例',
        ),
        releaseTriggerKind: 'branch',
        releaseTriggerValue: '子',
        releaseScale: YingQiScale.nian,
        sourceIds: const <String>[QimenSourceCatalog.projectV1],
      );
      final verdictWithAnnual = QimenVerdictResult(
        judgment: verdict.judgment,
        matchedDecisionRowId: verdict.matchedDecisionRowId,
        participatingFactIds: verdict.participatingFactIds,
        conflictResolutionIds: verdict.conflictResolutionIds,
        sourceIds: verdict.sourceIds,
        conditionLinks: <QimenVerdictCondition>[
          ...verdict.conditionLinks,
          annualCondition,
        ],
      );
      final firstHorse = _horse('first');
      final secondHorse = _horse('second');
      final star = _fact(
        ruleId: QimenRuleCatalog.starStateWang,
        target: 'star',
        category: QimenFactCategory.starState,
        role: QimenFactRole.support,
        tier: QimenConflictTier.contextual,
        focusRoles: const <String>['self'],
        refs: const <QimenInputRef>[
          QimenInputRef(
            path: r'$.temporalContext.currentSolarTerm',
            value: '霜降',
          ),
        ],
      );

      final evaluation = QimenYingQiService.calculate(
        activeFacts: <QimenFact>[
          voidFact,
          firstHorse,
          secondHorse,
          star,
        ],
        verdict: verdictWithAnnual,
      );

      expect(
        evaluation.candidates.map((value) => value.orderBand),
        <QimenYingQiOrderBand>[
          QimenYingQiOrderBand.conditionRelease,
          QimenYingQiOrderBand.conditionRelease,
          QimenYingQiOrderBand.focusActivation,
          QimenYingQiOrderBand.contextWindow,
        ],
      );
      expect(
        evaluation.candidates.map((value) => value.scale).toSet(),
        <YingQiScale>{
          YingQiScale.ri,
          YingQiScale.yue,
          YingQiScale.nian,
        },
      );
      expect(
        evaluation.candidates
            .where((candidate) => candidate.triggerValue == '子')
            .map((candidate) => candidate.scale)
            .toSet(),
        <YingQiScale>{YingQiScale.ri, YingQiScale.nian},
      );
      final horse = evaluation.candidates.singleWhere(
        (candidate) => candidate.ruleId == QimenRuleCatalog.yingQiHorse,
      );
      expect(
        horse.relatedFactIds,
        <String>[firstHorse.occurrenceId, secondHorse.occurrenceId]..sort(),
      );
      for (final candidate in evaluation.candidates) {
        expect(candidate.sourceIds, isNotEmpty);
        expect(candidate.reason, contains('保证'));
      }
      expect(
        () => horse.relatedFactIds.add('mutate'),
        throwsUnsupportedError,
      );
    });

    test('rejects a condition candidate without its upstream fact', () {
      final condition = QimenVerdictCondition(
        conditionId: 'QMV1-COND@missing',
        sourceFactId: 'missing',
        ruleId: QimenRuleCatalog.voidState,
        condition: const VerdictCondition(
          label: '待填实',
          branch: '子',
          reason: 'test',
        ),
        releaseTriggerKind: 'branch',
        releaseTriggerValue: '子',
        releaseScale: YingQiScale.ri,
        sourceIds: const <String>[QimenSourceCatalog.projectV1],
      );
      final verdict = QimenVerdictResult(
        judgment: const VerdictJudgment(
          trend: VerdictTrend.daiTiaoJian,
          summary: 'test',
        ),
        matchedDecisionRowId: QimenRuleCatalog.decision20,
        participatingFactIds: const <String>[],
        conflictResolutionIds: const <String>[],
        sourceIds: const <String>[QimenSourceCatalog.projectV1],
        conditionLinks: <QimenVerdictCondition>[condition],
      );

      expect(
        () => QimenYingQiService.calculate(
          activeFacts: const <QimenFact>[],
          verdict: verdict,
        ),
        throwsStateError,
      );
    });

    test('emits no candidate from facts lacking admitted trigger links', () {
      final background = _fact(
        ruleId: QimenRuleCatalog.starStateXiu,
        target: 'background',
        category: QimenFactCategory.starState,
        role: QimenFactRole.neutral,
        tier: QimenConflictTier.contextual,
      );
      final verdict = QimenVerdictService.judge(
        status: QimenAnalysisStatus.complete,
        diagnostics: const <QimenAnalysisDiagnostic>[],
        focuses: const <QimenFocus>[],
        hasUniquePrimaryFocus: true,
        activeFacts: <QimenFact>[background],
        conflicts: const <QimenConflictResolution>[],
      ).result;

      final result = QimenYingQiService.calculate(
        activeFacts: <QimenFact>[background],
        verdict: verdict,
      );
      expect(result.candidates, isEmpty);
      expect(
        result.trace.every(
          (step) =>
              step.status == QimenEvaluationStatus.notMatched ||
              step.status == QimenEvaluationStatus.notApplicable,
        ),
        true,
      );
      for (final ruleId in const <String>[
        QimenRuleCatalog.yingQiFuYin,
        QimenRuleCatalog.yingQiFanYin,
        QimenRuleCatalog.yingQiStem,
      ]) {
        expect(
          result.trace.singleWhere((step) => step.ruleId == ruleId).status,
          QimenEvaluationStatus.notApplicable,
          reason: ruleId,
        );
      }
    });

    test('secondary horse does not create a focus activation candidate', () {
      final secondaryHorse = _fact(
        ruleId: QimenRuleCatalog.horseActivation,
        target: 'secondary-horse',
        category: QimenFactCategory.activation,
        role: QimenFactRole.support,
        tier: QimenConflictTier.corroborating,
        focusRoles: const <String>['travelHorse'],
        refs: const <QimenInputRef>[
          QimenInputRef(path: r'$.horseBranch', value: '申'),
        ],
      );
      final verdict = QimenVerdictService.judge(
        status: QimenAnalysisStatus.complete,
        diagnostics: const <QimenAnalysisDiagnostic>[],
        focuses: const <QimenFocus>[],
        hasUniquePrimaryFocus: true,
        activeFacts: <QimenFact>[secondaryHorse],
        conflicts: const <QimenConflictResolution>[],
      ).result;

      final evaluation = QimenYingQiService.calculate(
        activeFacts: <QimenFact>[secondaryHorse],
        verdict: verdict,
      );
      expect(
        evaluation.candidates.where(
          (candidate) => candidate.ruleId == QimenRuleCatalog.yingQiHorse,
        ),
        isEmpty,
      );
    });
  });
}

QimenFact _horse(String suffix) => _fact(
      ruleId: QimenRuleCatalog.horseActivation,
      target: 'horse:$suffix',
      category: QimenFactCategory.activation,
      role: QimenFactRole.support,
      tier: QimenConflictTier.corroborating,
      focusRoles: const <String>['self'],
      refs: const <QimenInputRef>[
        QimenInputRef(path: r'$.horseBranch', value: '申'),
      ],
    );

QimenFact _fact({
  required String ruleId,
  required String target,
  required QimenFactCategory category,
  required QimenFactRole role,
  required QimenConflictTier tier,
  List<String> focusRoles = const <String>[],
  List<QimenInputRef> refs = const <QimenInputRef>[],
}) =>
    QimenFactSupport.fact(
      ruleId: ruleId,
      ruleSetVersion: QimenRuleCatalog.v1,
      targetKey: target,
      category: category,
      scope: QimenFactScope.palace,
      reason: 'test fact $ruleId',
      inputRefs: refs,
      palaceNumbers: const <int>[],
      focusRoleIds: focusRoles,
      role: role,
      tier: tier,
    );
