import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/liuyao_ai_eval/canonical_contract.dart';
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/comparison.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/paired_evaluation.dart';
import '../../../tool/liuyao_ai_eval/security.dart';
import 'phase6_test_support.dart';

void main() {
  late Phase6FixtureBundle bundle;

  setUpAll(() {
    bundle = buildPhase6FixtureBundle(Directory.current.path);
  });

  test('canonical adapter creates byte-identical paired inputs', () {
    final CanonicalRequestSet baseline = CanonicalRequestSet.create(
      runId: 'phase6-contract-r1',
      variant: baselineVariant,
      adapter: bundle.adapter,
      fixture: bundle.fixture,
      rubric: bundle.rubric,
    );
    final CanonicalRequestSet candidate = CanonicalRequestSet.create(
      runId: 'phase6-contract-r1',
      variant: candidateVariant,
      adapter: bundle.adapter,
      fixture: bundle.fixture,
      rubric: bundle.rubric,
    );

    final CanonicalPairContract pair = validateCanonicalRequestPair(
      baseline: CanonicalRequestSet.fromJson(
        baseline.toJson(),
        expectedRunId: baseline.runId,
        expectedVariant: baselineVariant,
        fixture: bundle.fixture,
        rubric: bundle.rubric,
      ),
      candidate: CanonicalRequestSet.fromJson(
        candidate.toJson(),
        expectedRunId: candidate.runId,
        expectedVariant: candidateVariant,
        fixture: bundle.fixture,
        rubric: bundle.rubric,
      ),
      fixture: bundle.fixture,
    );

    expect(pair.baseline.projectionSetHash, pair.candidate.projectionSetHash);
    expect(pair.baseline.caseInputSetHash, pair.candidate.caseInputSetHash);
    expect(
      pair.baseline.requestParametersHash,
      pair.candidate.requestParametersHash,
    );
    expect(pair.baseline.requestSetHash, isNot(pair.candidate.requestSetHash));
    expect(pair.holdout.members, hasLength(6));
    for (int index = 0; index < pair.baseline.requests.length; index += 1) {
      expect(
        sha256Json(pair.baseline.requests[index].caseInput),
        sha256Json(pair.candidate.requests[index].caseInput),
      );
    }
  });

  test('canonical adapter rejects a stale projection hash', () {
    final Map<String, Object?> json =
        decodeObject(canonicalJson(bundle.adapter.toJson()));
    final List<Object?> cases = requireList(json, 'cases');
    final Map<String, Object?> first =
        (cases.first! as Map).cast<String, Object?>();
    first['projectionHash'] = sha256Text('stale-projection');

    expect(
      () => CanonicalEvalAdapter.fromJson(
        json,
        fixture: bundle.fixture,
        rubric: bundle.rubric,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('pair contract rejects mixed request parameter identity', () {
    final CanonicalRequestSet baseline = CanonicalRequestSet.create(
      runId: 'phase6-contract-r2',
      variant: baselineVariant,
      adapter: bundle.adapter,
      fixture: bundle.fixture,
      rubric: bundle.rubric,
    );
    final CanonicalRequestSet validCandidate = CanonicalRequestSet.create(
      runId: 'phase6-contract-r2',
      variant: candidateVariant,
      adapter: bundle.adapter,
      fixture: bundle.fixture,
      rubric: bundle.rubric,
    );
    final CanonicalRequestSet candidate = CanonicalRequestSet(
      runId: validCandidate.runId,
      variant: validCandidate.variant,
      adapterHash: validCandidate.adapterHash,
      fixtureHash: validCandidate.fixtureHash,
      rubricHash: validCandidate.rubricHash,
      projectionSchemaVersion: validCandidate.projectionSchemaVersion,
      ruleSetId: validCandidate.ruleSetId,
      ruleSetVersion: validCandidate.ruleSetVersion,
      requestParameters: validCandidate.requestParameters,
      requestParametersHash: sha256Text('mixed-parameters'),
      projectionSetHash: validCandidate.projectionSetHash,
      caseInputSetHash: validCandidate.caseInputSetHash,
      requestSetHash: validCandidate.requestSetHash,
      requests: validCandidate.requests,
    );

    expect(
      () => validateCanonicalRequestPair(
        baseline: baseline,
        candidate: candidate,
        fixture: bundle.fixture,
      ),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'canonicalRequestSetIdentityMismatch',
        ),
      ),
    );
  });

  test('generation and blind judge orders are stable and independently salted',
      () {
    final Set<String> generationFirst = <String>{};
    final Set<String> judgeFirst = <String>{};
    for (final String caseId
        in bundle.fixture.cases.map((evalCase) => evalCase.caseId)) {
      for (int repetition = 1; repetition <= 3; repetition += 1) {
        final List<String> first = pairedGenerationOrder(
          runId: 'phase6-order-r1',
          caseId: caseId,
          repetition: repetition,
        );
        expect(
          pairedGenerationOrder(
            runId: 'phase6-order-r1',
            caseId: caseId,
            repetition: repetition,
          ),
          first,
        );
        generationFirst.add(first.first);
        judgeFirst.add(
          blindLabelMapping(
            runId: 'phase6-order-r1',
            caseId: caseId,
            repetition: repetition,
          )['A']!,
        );
      }
    }

    expect(generationFirst, <String>{baselineVariant, candidateVariant});
    expect(judgeFirst, <String>{'baseline', 'candidate'});
  });
}
