import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/lifecycle_assessment_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_trace.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/liuyao_analysis_projection.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';

void main() {
  late LiuYaoResult base;

  setUpAll(() async {
    base = await LiuYaoSystem().castByManualYaoNumbers(
      const <int>[8, 8, 6, 7, 8, 6],
      castTime: DateTime(2026, 2, 28, 8),
    );
  });

  test('v3 preserves early attack and later return restraint', () {
    final report = LiuYaoAnalyzer.analyze(
      base.mainGua,
      base.changingGua,
      base.lunarInfo,
      yongShenPosition: 1,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final earlyAttack = report.directedEffects.singleWhere(
      (effect) =>
          effect.fromActor.actorId == 'main:yao:3' &&
          effect.toActor.actorId == 'main:yao:1' &&
          effect.effect == DirectedEffectKind.ke,
    );
    final laterRestraint = report.directedEffects.singleWhere(
      (effect) =>
          effect.ruleId == LiuYaoRuleIds.ruleReturnOvercomes &&
          effect.toActor.actorId == 'main:yao:3',
    );

    expect(earlyAttack.isActive, isTrue);
    expect(earlyAttack.phase, DirectedEffectPhase.earlyProcess);
    expect(laterRestraint.isActive, isTrue);
    expect(laterRestraint.phase, DirectedEffectPhase.laterProcess);
  });

  test('selected main-1 freezes rental lifecycle and complete evidence', () {
    final result = base.copyWith(
      yongShenPosition: 1,
      yongShenIsFuShen: false,
    );
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: 1,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: result,
      report: report,
      question: '租房是否顺利',
    ).toJson();

    expect(projection['projectionSchemaVersion'], 2);
    final policy = projection['policy'] as Map<String, Object?>;
    expect(policy.keys.toList(), <String>[
      'calculationOwner',
      'mayRecalculatePan',
      'mayRecalculateAnalysis',
      'mayReselectYongShen',
      'mayOverrideVerdict',
      'mayInventSources',
      'mayInventTiming',
      'timingIsGuarantee',
      'maySuggestYongShen',
      'verdictMode',
      'mayOverrideLifecycle',
      'mustPreserveLifecycleDimensions',
      'mayIssueOverallOutcome',
      'legacyVerdictScope',
      'releaseConditionIsTiming',
    ]);
    expect(policy['verdictMode'], 'explainLifecycle');
    expect(policy['mayOverrideLifecycle'], isFalse);
    expect(policy['mustPreserveLifecycleDimensions'], isTrue);
    expect(policy['mayIssueOverallOutcome'], isTrue);
    expect(policy['legacyVerdictScope'], 'selectedUseSpiritAxis');
    expect(policy['releaseConditionIsTiming'], isFalse);
    expect(
      projection['questionFocus'],
      containsPair('classification', 'rentalFullCycle'),
    );
    final focus = projection['questionFocus'] as Map<String, Object?>;
    expect(focus['autoSelectsUseSpirit'], isFalse);
    expect(focus['aspects'], hasLength(7));
    expect(
      (focus['aspects'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map((aspect) => aspect['role']),
      containsAll(
          <String>['shi', 'ying', 'qiCai', 'fuMu', 'xiongDi', 'guanGui']),
    );
    expect(
      projection['lifecycleVerdict'],
      containsPair('formation', 'willForm'),
    );
    expect(
      projection['lifecycleVerdict'],
      containsPair('quality', 'adverse'),
    );
    expect(
      projection['lifecycleVerdict'],
      containsPair('continuity', 'unstable'),
    );
    expect(
      projection['lifecycleVerdict'],
      containsPair('persistence', 'entangled'),
    );
    expect(
      projection['lifecycleVerdict'],
      containsPair('headlineCode', 'formsButAdverse'),
    );

    final actorFacts = (projection['actorFacts'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      actorFacts.where((fact) => fact['actorLayer'] == 'main'),
      hasLength(6),
    );
    expect(
      actorFacts.any((fact) =>
          (fact['actor'] as Map<String, Object?>)['actorId'] ==
          'hidden:host-yao:1'),
      isTrue,
    );
    final yao3 = actorFacts.singleWhere(
      (fact) =>
          (fact['actor'] as Map<String, Object?>)['actorId'] == 'main:yao:3',
    );
    final returnOvercomes = (yao3['tags'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .singleWhere(
          (tag) => tag['ruleId'] == LiuYaoRuleIds.ruleReturnOvercomes,
        );
    expect(returnOvercomes['phase'], 'laterProcess');
    expect(returnOvercomes['horizon'], 'subsequent');
    expect(
      returnOvercomes['decisionScopes'],
      <String>['continuity', 'persistence'],
    );
    expect(returnOvercomes['decisionScopes'], isNot(contains('quality')));
    final occurrences = (projection['useSpiritOccurrences'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(occurrences, hasLength(2));
    expect(
      occurrences.map((item) => item['occurrenceRole']),
      containsAll(<String>['selected', 'alternate']),
    );

    final harmony = (projection['auxiliaryEvidence'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(harmony, hasLength(2));
    for (final tag in harmony) {
      expect(tag['polarity'], 'neutral');
      expect(tag['decisionScopes'], <String>['formation', 'persistence']);
      expect(tag['forbiddenDecisionScopes'], contains('quality'));
    }

    expect(
      projection['shiYingRelation'],
      containsPair('direction', 'yingGeneratesShi'),
    );
    final lifecycle = projection['lifecycleVerdict'] as Map<String, Object?>;
    final evidence =
        (lifecycle['evidenceOccurrenceIds'] as Map<String, Object?>).map(
            (key, value) =>
                MapEntry(key, (value as List<Object?>).cast<String>()));
    expect(
      evidence.keys.toList(),
      LiuYaoLifecycleAssessmentService.dimensionIds,
    );
    final yingFact = actorFacts.singleWhere((fact) => fact['isYing'] == true);
    final yingMovingTomb = (yingFact['tags'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .singleWhere(
          (tag) => tag['ruleId'] == LiuYaoRuleIds.ruleMovingTomb,
        );
    expect(yingMovingTomb['active'], isTrue);
    expect(
      evidence['continuity'],
      contains(yingMovingTomb['occurrenceId']),
    );
    expect(
      evidence['continuity'],
      contains('lyo-e89f5132a3438acd946f1753'),
    );
    final knownEvidenceIds = <String>{
      (projection['shiYingRelation'] as Map<String, Object?>)['evidenceId']!
          as String,
      ...(projection['directedEffects'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map((effect) => effect['occurrenceId']! as String),
      ...(projection['actorFacts'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .expand((fact) =>
              (fact['tags'] as List<Object?>).cast<Map<String, Object?>>())
          .map((tag) => tag['occurrenceId']! as String),
      ...(projection['selectedUseSpiritFacts'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map((tag) => tag['occurrenceId']! as String),
      ...(projection['auxiliaryEvidence'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map((tag) => tag['occurrenceId']! as String),
    };
    final orphanEvidence = evidence.values
        .expand((ids) => ids)
        .where((id) => !knownEvidenceIds.contains(id))
        .toSet();
    expect(orphanEvidence, isEmpty);
  });

  test('main-6 preserves apparent void and later-state facts separately', () {
    final result = base.copyWith(yongShenPosition: 6);
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: 6,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: result,
      report: report,
      question: '租房是否顺利',
    ).toJson();
    final selected = (projection['useSpiritOccurrences'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .singleWhere((item) => item['occurrenceRole'] == 'selected');
    final tags =
        (selected['tags'] as List<Object?>).cast<Map<String, Object?>>();
    final terms = tags.map((tag) => tag['term']).toSet();

    expect(terms, containsAll(<String>['旬空', '假空', '回头生', '化绝']));
    final apparentVoid = tags.singleWhere((tag) => tag['term'] == '假空');
    expect(apparentVoid['authority'], 'programMechanical');
    expect(apparentVoid['decisionEligible'], isTrue);
    final returnGenerates = tags.singleWhere((tag) => tag['term'] == '回头生');
    expect(returnGenerates['phase'], 'laterProcess');
    expect(returnGenerates['horizon'], 'subsequent');
    expect(
      returnGenerates['decisionScopes'],
      <String>['continuity', 'persistence'],
    );
    final changedTerminal = tags.singleWhere((tag) => tag['term'] == '化绝');
    expect(changedTerminal['phase'], 'finalState');
    expect(changedTerminal['horizon'], 'terminal');
    expect(
      changedTerminal['decisionScopes'],
      <String>['continuity', 'persistence'],
    );
    expect(
      tags.map((tag) => tag['reason'].toString()).join('\n'),
      isNot(contains('不存在')),
    );
  });

  test('hidden-1 keeps contract scope local to the rental focus', () {
    final result = base.copyWith(
      yongShenPosition: 1,
      yongShenIsFuShen: true,
    );
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: 1,
      yongShenIsFuShen: true,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: result,
      report: report,
      question: '租房是否顺利',
    ).toJson();
    final selected = (projection['useSpiritOccurrences'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .singleWhere((item) => item['occurrenceRole'] == 'selected');
    final actor = selected['actor'] as Map<String, Object?>;
    final conditions = (projection['conditions'] as List<Object?>)
        .cast<Map<String, Object?>>();

    expect(actor['actorId'], 'hidden:host-yao:1');
    expect(actor['kind'], 'hiddenYao');
    expect(projection['lifecycleVerdict'], isNull);
    expect(
      projection['policy'],
      containsPair('verdictMode', 'explainSelectedVerdict'),
    );
    expect(
      conditions,
      contains(predicate<Map<String, Object?>>(
        (condition) =>
            condition['scope'] == 'questionFocus' &&
            condition['dimension'] == 'contractOwnership' &&
            condition['hasRescue'] == false,
      )),
    );
  });

  test(
      'double harmony follows favorable main evidence without forcing adversity',
      () {
    final result = base.copyWith(yongShenPosition: 1);
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: 1,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final supportRule =
        LiuYaoRuleCatalog.ruleById[LiuYaoRuleIds.ruleDayGenerates]!;
    final supportiveTag = report.yongShenTags.first.copyWith(
      term: '日生',
      ruleId: supportRule.ruleId,
      occurrenceId: 'lyo-test-rental-support',
      sourceIds: supportRule.sourceIds,
      active: true,
    );
    final favorableReport = report.copyWith(
      yaoTags: <int, List<YaoAnalysisTag>>{
        for (var position = 1; position <= 6; position++)
          position: const <YaoAnalysisTag>[],
      },
      yongShenTags: <YaoAnalysisTag>[supportiveTag],
      directedEffects: const <DirectedEffectOccurrence>[],
      judgment: report.judgment!.copyWith(conditions: const []),
    );
    final lifecycle = LiuYaoLifecycleAssessmentService.assess(
      question: '租房是否顺利',
      result: result,
      report: favorableReport,
    )!;

    expect(lifecycle.formation, LiuYaoFormation.willForm);
    expect(lifecycle.quality, LiuYaoQuality.favorable);
    expect(lifecycle.continuity, LiuYaoContinuity.stable);
    expect(lifecycle.persistence, LiuYaoPersistence.smooth);
    expect(lifecycle.matchedDecisionRowId,
        LiuYaoLifecycleAssessmentService.fallbackRowId);
  });

  test('unselected schema 2 enforces abstention without lifecycle', () {
    final report = LiuYaoAnalyzer.analyze(
      base.mainGua,
      base.changingGua,
      base.lunarInfo,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: base,
      report: report,
      question: '租房是否顺利',
    ).toJson();

    expect(projection['verdict'], isNull);
    expect(projection['lifecycleVerdict'], isNull);
    expect(projection['conditions'], isEmpty);
    expect(projection['timingCandidates'], isEmpty);
    expect(
      projection['policy'],
      containsPair('verdictMode', 'abstain'),
    );
    expect(
      projection['policy'],
      containsPair('mayIssueOverallOutcome', false),
    );

    final actorFacts = (projection['actorFacts'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      actorFacts.where((fact) => fact['actorLayer'] == 'main'),
      hasLength(6),
    );
    expect(
      actorFacts.where((fact) => fact['actorLayer'] == 'changed'),
      hasLength(base.mainGua.movingYaos.length),
    );
    expect(actorFacts.every((fact) => fact['availability'] != null), isTrue);
    expect(
      actorFacts.every((fact) => (fact['tags'] as List<Object?>).isNotEmpty),
      isTrue,
    );

    Map<String, Object?> actorFact(String actorId) => actorFacts.singleWhere(
          (fact) =>
              (fact['actor'] as Map<String, Object?>)['actorId'] == actorId,
        );
    Set<String> termsOf(String actorId) =>
        (actorFact(actorId)['tags'] as List<Object?>)
            .cast<Map<String, Object?>>()
            .map((tag) => tag['term']! as String)
            .toSet();

    expect(
      (actorFact('main:yao:1')['tags'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map((tag) => tag['category']),
      isNot(contains('fuShen')),
    );
    expect(
      termsOf('hidden:host-yao:1'),
      contains('飞克伏'),
    );
    expect(
      termsOf('hidden:host-yao:1'),
      anyOf(contains('旺'), contains('相'), contains('休'), contains('囚'),
          contains('死')),
    );
    expect(termsOf('changed:yao:3'), contains('回头克'));
    expect(
      termsOf('changed:yao:3'),
      anyOf(contains('旺'), contains('相'), contains('休'), contains('囚'),
          contains('死')),
    );
  });

  test(
      'selected non-rental question explains program verdict without lifecycle',
      () {
    final result = base.copyWith(yongShenPosition: 1);
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: 1,
      ruleSetVersion: LiuYaoRuleCatalog.v3,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: result,
      report: report,
      question: '这次求职能否成功',
    ).toJson();
    final verdict = projection['verdict'] as Map<String, Object?>;

    expect(projection['lifecycleVerdict'], isNull);
    expect(
      projection['policy'],
      containsPair('verdictMode', 'explainSelectedVerdict'),
    );
    expect(
      projection['policy'],
      containsPair('mayIssueOverallOutcome', false),
    );
    expect(verdict['trend'], report.judgment!.trend.code);
    expect(verdict['nuance'], report.judgment!.nuance);
    expect(
      verdict['matchedDecisionRowId'],
      report.judgment!.matchedDecisionRowId,
    );
    expect(projection['conditions'],
        hasLength(report.judgment!.conditions.length));
    expect(
      projection['timingCandidates'],
      hasLength(report.yingQi?.length ?? 0),
    );
  });

  test('explicit v2 keeps schema 1 shape and suppression semantics', () {
    final result = base.copyWith(yongShenPosition: 1);
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: 1,
      ruleSetVersion: LiuYaoRuleCatalog.v2,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: result,
      report: report,
      question: '租房是否顺利',
    ).toJson();
    final attack = report.directedEffects.singleWhere(
      (effect) =>
          effect.fromActor.actorId == 'main:yao:3' &&
          effect.toActor.actorId == 'main:yao:1' &&
          effect.effect == DirectedEffectKind.ke,
    );

    expect(report.analysisSchemaVersion, 1);
    expect(
        report.sourceCatalogVersion, LiuYaoRuleCatalog.v2SourceCatalogVersion);
    expect(projection['projectionSchemaVersion'], 1);
    expect(
      sha256.convert(utf8.encode(jsonEncode(projection))).toString(),
      '98778b5d9891db215b35466fab3bcd16196ec605e7aed87f0bd52d70ecc1fa69',
    );
    expect(projection.keys.toList(), LiuYaoAnalysisProjection.topLevelKeys);
    expect(projection, isNot(contains('lifecycleVerdict')));
    expect(
      (projection['directedEffects'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .every((effect) => !effect.containsKey('phase')),
      isTrue,
    );
    expect(attack.isActive, isFalse);
    expect(
      report.guaTags.where((tag) => tag.term.contains('六合')).every(
            (tag) => tag.polarity == Polarity.ji,
          ),
      isTrue,
    );
  });
}
