import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide ComparisonResult;

import '../../../tool/liuyao_ai_eval/assets.dart';
import '../../../tool/liuyao_ai_eval/canonical_contract.dart';
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/comparison.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

void main() {
  late EvalRubric rubric;
  late EvalFixture fixture;

  setUpAll(() {
    rubric = EvalAssets(Directory.current.path).loadRubric();
    fixture = _comparisonFixture();
  });

  test('comparison builds the explicit 7 x 4 case-level matrix', () {
    final List<PairedEvaluation> pairs = _completePairs(rubric, fixture);
    final ComparisonIdentity identity = _identity(fixture, rubric, pairs);

    final ComparisonResult result = const EvaluationComparator().compare(
      identity: identity,
      fixture: fixture,
      rubric: rubric,
      pairs: pairs,
    );

    expect(result.passed, isTrue, reason: result.issues.join(', '));
    expect(result.matrix, hasLength(28));
    expect(
        result.repeatableImprovementDimensions, contains('evidenceCoverage'));
    final MatrixCell overallEvidence = result.matrix.singleWhere(
      (MatrixCell cell) =>
          cell.dimensionId == 'evidenceCoverage' && cell.cohortId == 'overall',
    );
    expect(overallEvidence.caseCount, 3);
    expect(overallEvidence.pairCount, 9);
    expect(overallEvidence.delta, closeTo(1 / 3, 0.000001));
  });

  test('comparison fails closed when any pair is missing', () {
    final List<PairedEvaluation> pairs = _completePairs(rubric, fixture)
      ..removeLast();
    final ComparisonIdentity identity = _identity(fixture, rubric, pairs);

    expect(
      () => const EvaluationComparator().compare(
        identity: identity,
        fixture: fixture,
        rubric: rubric,
        pairs: pairs,
      ),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'missingCompletePairs',
        ),
      ),
    );
  });

  test('comparison rejects mixed projection hashes across repetitions', () {
    final List<PairedEvaluation> pairs = _completePairs(rubric, fixture);
    final PairedEvaluation original = pairs[1];
    pairs[1] = _pair(
      rubric: rubric,
      evalCase: fixture.cases.first,
      repetition: original.repetition,
      projectionHash: sha256Text('changed-projection'),
    );
    final ComparisonIdentity identity = _identity(fixture, rubric, pairs);

    expect(
      () => const EvaluationComparator().compare(
        identity: identity,
        fixture: fixture,
        rubric: rubric,
        pairs: pairs,
      ),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'mixedProjectionHash',
        ),
      ),
    );
  });

  test('comparison rejects a pair bound to a different run hash', () {
    final List<PairedEvaluation> pairs = _completePairs(rubric, fixture);
    final ComparisonIdentity identity = _identity(fixture, rubric, pairs);
    final PairedEvaluation original = pairs.first;
    pairs.first = PairedEvaluation(
      runId: original.runId,
      runHash: sha256Text('different-run'),
      caseId: original.caseId,
      repetition: original.repetition,
      baseline: original.baseline,
      candidate: original.candidate,
      blindLabelMapping: original.blindLabelMapping,
      judgeRequest: original.judgeRequest,
      judgeResponse: original.judgeResponse,
      scores: original.scores,
    );

    expect(
      () => const EvaluationComparator().compare(
        identity: identity,
        fixture: fixture,
        rubric: rubric,
        pairs: pairs,
      ),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'pairRunOrIdentityMismatch',
        ),
      ),
    );
  });

  test('comparison rejects a judge model different from generation model', () {
    final List<PairedEvaluation> pairs = _completePairs(rubric, fixture);
    final ComparisonIdentity valid = _identity(fixture, rubric, pairs);
    final ComparisonIdentity invalid = ComparisonIdentity.create(
      runId: valid.runId,
      fixtureHash: valid.fixtureHash,
      rubricHash: valid.rubricHash,
      adapterHash: valid.adapterHash,
      projectionSetHash: valid.projectionSetHash,
      caseInputSetHash: valid.caseInputSetHash,
      modelHash: valid.modelHash,
      judgeModelHash: sha256Text('different-judge-model'),
      requestParametersHash: valid.requestParametersHash,
      baselineRequestSetHash: valid.baselineRequestSetHash,
      candidateRequestSetHash: valid.candidateRequestSetHash,
    );

    expect(
      () => const EvaluationComparator().compare(
        identity: invalid,
        fixture: fixture,
        rubric: rubric,
        pairs: pairs,
      ),
      throwsA(isA<EvalFailure>()),
    );
  });

  test('blind labels are deterministic and bound to run, case, and repetition',
      () {
    final Map<String, String> first = blindLabelMapping(
      runId: 'canonical-v2-r1',
      caseId: 'case-a',
      repetition: 1,
    );
    final Map<String, String> second = blindLabelMapping(
      runId: 'canonical-v2-r1',
      caseId: 'case-a',
      repetition: 1,
    );

    expect(first, second);
    expect(first.values.toSet(), <String>{'baseline', 'candidate'});
  });
}

EvalFixture _comparisonFixture() {
  final ScoringReference reference = ScoringReference(
    expectedVerdictTrend: 'trend',
    requiredConditionIds: const <String>{},
    allowedPanFactIds: const <String>{'fact'},
    expectedYongShenActorId: 'main:yao:1',
    allowedTimingIds: const <String>{},
    allowedSources: const <String, AllowedSource>{},
  );
  final List<EvalCase> cases = <EvalCase>[
    EvalCase(
      caseId: 'case-original-calibration',
      caseKind: 'originalBook',
      evaluationSplit: 'calibration',
      cohortIds: const <String>{
        'overall',
        'originalBook',
        'calibration',
      },
      requestInput: const <String, Object?>{},
      scoringReference: reference,
    ),
    EvalCase(
      caseId: 'case-original-holdout',
      caseKind: 'originalBook',
      evaluationSplit: 'holdout',
      cohortIds: const <String>{'overall', 'originalBook', 'holdout'},
      requestInput: const <String, Object?>{},
      scoringReference: reference,
    ),
    EvalCase(
      caseId: 'case-rule-validation',
      caseKind: 'ruleValidation',
      evaluationSplit: 'calibration',
      cohortIds: const <String>{
        'overall',
        'ruleValidation',
        'calibration',
      },
      requestInput: const <String, Object?>{},
      scoringReference: reference,
    ),
  ];
  return EvalFixture(
    fixtureVersion: 'test-fixture',
    rubricVersion: 'test-rubric',
    projectionSchemaVersion: 'test-projection',
    requestSchemaVersion: 'test-request',
    cases: cases,
    hash: sha256Text('comparison-fixture'),
  );
}

List<PairedEvaluation> _completePairs(
  EvalRubric rubric,
  EvalFixture fixture,
) =>
    <PairedEvaluation>[
      for (final EvalCase evalCase in fixture.cases)
        for (int repetition = 1; repetition <= 3; repetition += 1)
          _pair(
            rubric: rubric,
            evalCase: evalCase,
            repetition: repetition,
          ),
    ];

PairedEvaluation _pair({
  required EvalRubric rubric,
  required EvalCase evalCase,
  required int repetition,
  String? projectionHash,
}) {
  final String projection = projectionHash ?? sha256Text(evalCase.caseId);
  final bool evidenceWin = repetition <= 2;
  final Map<String, DimensionScore> scores = <String, DimensionScore>{
    for (final RubricDimension dimension in rubric.dimensions)
      dimension.dimensionId: DimensionScore(
        baseline:
            dimension.dimensionId == 'evidenceCoverage' && !evidenceWin ? 2 : 1,
        candidate:
            dimension.dimensionId == 'evidenceCoverage' && evidenceWin ? 2 : 1,
        reason: 'frozen judge reason',
      ),
  };
  VariantEvaluation variant(String name) => VariantEvaluation(
        variant: name,
        requestHash: sha256Text('$name:${evalCase.caseId}'),
        projectionHash: projection,
        caseInputHash: sha256Text('input:${evalCase.caseId}'),
        normalizedOutput: const <String, Object?>{'redacted': true},
        hardGates: const <String, bool>{
          'verdictPreserved': true,
          'conditionsComplete': true,
          'panAndYongShenGrounded': true,
          'timingBounded': true,
          'sourcesAllowlisted': true,
          'citationsAllowlisted': true,
        },
      );
  return PairedEvaluation(
    runId: 'canonical-v2-r1',
    runHash: _runHashForFixture(evalCase.caseId),
    caseId: evalCase.caseId,
    repetition: repetition,
    baseline: variant(baselineVariant),
    candidate: variant(candidateVariant),
    blindLabelMapping: blindLabelMapping(
      runId: 'canonical-v2-r1',
      caseId: evalCase.caseId,
      repetition: repetition,
    ),
    judgeRequest: const <String, Object?>{'redactedRequest': true},
    judgeResponse: const <String, Object?>{'redactedResponse': true},
    scores: scores,
  );
}

ComparisonIdentity _identity(
  EvalFixture fixture,
  EvalRubric rubric,
  List<PairedEvaluation> pairs,
) {
  final Map<String, String> baselineHashes = <String, String>{};
  final Map<String, String> candidateHashes = <String, String>{};
  final Map<String, String> projectionHashes = <String, String>{};
  final Map<String, String> inputHashes = <String, String>{};
  for (final PairedEvaluation pair in pairs) {
    baselineHashes[pair.caseId] = pair.baseline.requestHash;
    candidateHashes[pair.caseId] = pair.candidate.requestHash;
    projectionHashes[pair.caseId] = pair.baseline.projectionHash;
    inputHashes[pair.caseId] = pair.baseline.caseInputHash;
  }
  final ComparisonIdentity identity = ComparisonIdentity.create(
    runId: 'canonical-v2-r1',
    fixtureHash: fixture.hash,
    rubricHash: rubric.hash,
    adapterHash: sha256Text('adapter'),
    projectionSetHash: sha256Json(projectionHashes),
    caseInputSetHash: sha256Json(inputHashes),
    modelHash: sha256Text('same-model'),
    judgeModelHash: sha256Text('same-model'),
    requestParametersHash: sha256Text('same-request-parameters'),
    baselineRequestSetHash:
        canonicalRequestSetHash(baselineVariant, baselineHashes),
    candidateRequestSetHash:
        canonicalRequestSetHash(candidateVariant, candidateHashes),
  );
  for (int index = 0; index < pairs.length; index += 1) {
    final PairedEvaluation pair = pairs[index];
    pairs[index] = PairedEvaluation(
      runId: pair.runId,
      runHash: identity.runHash,
      caseId: pair.caseId,
      repetition: pair.repetition,
      baseline: pair.baseline,
      candidate: pair.candidate,
      blindLabelMapping: pair.blindLabelMapping,
      judgeRequest: pair.judgeRequest,
      judgeResponse: pair.judgeResponse,
      scores: pair.scores,
    );
  }
  return identity;
}

String _runHashForFixture(String caseId) => sha256Text('pending-run:$caseId');
