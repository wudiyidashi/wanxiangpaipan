import 'assets.dart';
import 'canonical_contract.dart';
import 'canonical_json.dart';
import 'constants.dart';
import 'hard_gates.dart';
import 'security.dart';

const String _defaultTransportRetryPolicyVersion = transportRetryPolicyVersion;

class ComparisonIdentity {
  const ComparisonIdentity({
    required this.runId,
    required this.runHash,
    required this.fixtureHash,
    required this.rubricHash,
    required this.adapterHash,
    required this.projectionSetHash,
    required this.caseInputSetHash,
    required this.modelHash,
    required this.judgeModelHash,
    required this.transportEndpointHash,
    required this.transportTimeoutSeconds,
    required this.transportRetryPolicyVersion,
    required this.requestParametersHash,
    required this.judgeRequestContractHash,
    required this.baselineRequestSetHash,
    required this.candidateRequestSetHash,
  });

  final String runId;
  final String runHash;
  final String fixtureHash;
  final String rubricHash;
  final String adapterHash;
  final String projectionSetHash;
  final String caseInputSetHash;
  final String modelHash;
  final String judgeModelHash;
  final String transportEndpointHash;
  final int transportTimeoutSeconds;
  final String transportRetryPolicyVersion;
  final String requestParametersHash;
  final String judgeRequestContractHash;
  final String baselineRequestSetHash;
  final String candidateRequestSetHash;

  factory ComparisonIdentity.create({
    required String runId,
    required String fixtureHash,
    required String rubricHash,
    required String adapterHash,
    required String projectionSetHash,
    required String caseInputSetHash,
    required String modelHash,
    required String judgeModelHash,
    required String transportEndpointHash,
    int transportTimeoutSeconds = defaultTransportTimeoutSeconds,
    String transportRetryPolicyVersion = _defaultTransportRetryPolicyVersion,
    required String requestParametersHash,
    required String judgeRequestContractHash,
    required String baselineRequestSetHash,
    required String candidateRequestSetHash,
  }) {
    if (transportTimeoutSeconds < minimumTransportTimeoutSeconds ||
        transportTimeoutSeconds > maximumTransportTimeoutSeconds) {
      throw const FormatException('Transport timeout is outside bounds.');
    }
    if (transportRetryPolicyVersion.isEmpty) {
      throw const FormatException('Transport retry policy is missing.');
    }
    final String runHash = sha256Json(<String, Object?>{
      'runId': runId,
      'fixtureHash': fixtureHash,
      'rubricHash': rubricHash,
      'adapterHash': adapterHash,
      'projectionSetHash': projectionSetHash,
      'caseInputSetHash': caseInputSetHash,
      'modelHash': modelHash,
      'judgeModelHash': judgeModelHash,
      'transportEndpointHash': transportEndpointHash,
      'transportTimeoutSeconds': transportTimeoutSeconds,
      'transportRetryPolicyVersion': transportRetryPolicyVersion,
      'requestParametersHash': requestParametersHash,
      'judgeRequestContractHash': judgeRequestContractHash,
      'baselineRequestSetHash': baselineRequestSetHash,
      'candidateRequestSetHash': candidateRequestSetHash,
    });
    return ComparisonIdentity(
      runId: runId,
      runHash: runHash,
      fixtureHash: fixtureHash,
      rubricHash: rubricHash,
      adapterHash: adapterHash,
      projectionSetHash: projectionSetHash,
      caseInputSetHash: caseInputSetHash,
      modelHash: modelHash,
      judgeModelHash: judgeModelHash,
      transportEndpointHash: transportEndpointHash,
      transportTimeoutSeconds: transportTimeoutSeconds,
      transportRetryPolicyVersion: transportRetryPolicyVersion,
      requestParametersHash: requestParametersHash,
      judgeRequestContractHash: judgeRequestContractHash,
      baselineRequestSetHash: baselineRequestSetHash,
      candidateRequestSetHash: candidateRequestSetHash,
    );
  }

  factory ComparisonIdentity.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'runId',
        'runHash',
        'fixtureHash',
        'rubricHash',
        'adapterHash',
        'projectionSetHash',
        'caseInputSetHash',
        'modelHash',
        'judgeModelHash',
        'transportEndpointHash',
        'transportTimeoutSeconds',
        'transportRetryPolicyVersion',
        'requestParametersHash',
        'judgeRequestContractHash',
        'baselineRequestSetHash',
        'candidateRequestSetHash',
      },
    );
    return ComparisonIdentity(
      runId: requireString(json, 'runId'),
      runHash: _requireHash(json, 'runHash'),
      fixtureHash: _requireHash(json, 'fixtureHash'),
      rubricHash: _requireHash(json, 'rubricHash'),
      adapterHash: _requireHash(json, 'adapterHash'),
      projectionSetHash: _requireHash(json, 'projectionSetHash'),
      caseInputSetHash: _requireHash(json, 'caseInputSetHash'),
      modelHash: _requireHash(json, 'modelHash'),
      judgeModelHash: _requireHash(json, 'judgeModelHash'),
      transportEndpointHash: _requireHash(json, 'transportEndpointHash'),
      transportTimeoutSeconds: _requireTransportTimeout(json),
      transportRetryPolicyVersion:
          requireString(json, 'transportRetryPolicyVersion'),
      requestParametersHash: _requireHash(json, 'requestParametersHash'),
      judgeRequestContractHash: _requireHash(json, 'judgeRequestContractHash'),
      baselineRequestSetHash: _requireHash(json, 'baselineRequestSetHash'),
      candidateRequestSetHash: _requireHash(json, 'candidateRequestSetHash'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'runId': runId,
        'runHash': runHash,
        'fixtureHash': fixtureHash,
        'rubricHash': rubricHash,
        'adapterHash': adapterHash,
        'projectionSetHash': projectionSetHash,
        'caseInputSetHash': caseInputSetHash,
        'modelHash': modelHash,
        'judgeModelHash': judgeModelHash,
        'transportEndpointHash': transportEndpointHash,
        'transportTimeoutSeconds': transportTimeoutSeconds,
        'transportRetryPolicyVersion': transportRetryPolicyVersion,
        'requestParametersHash': requestParametersHash,
        'judgeRequestContractHash': judgeRequestContractHash,
        'baselineRequestSetHash': baselineRequestSetHash,
        'candidateRequestSetHash': candidateRequestSetHash,
      };
}

class VariantEvaluation {
  const VariantEvaluation({
    required this.variant,
    required this.requestHash,
    required this.projectionHash,
    required this.caseInputHash,
    required this.normalizedOutput,
    required this.hardGates,
  });

  final String variant;
  final String requestHash;
  final String projectionHash;
  final String caseInputHash;
  final Map<String, Object?> normalizedOutput;
  final Map<String, bool> hardGates;

  factory VariantEvaluation.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'variant',
        'requestHash',
        'projectionHash',
        'caseInputHash',
        'normalizedOutput',
        'hardGates',
      },
    );
    final Map<String, Object?> gateJson = requireObject(json, 'hardGates');
    requireExactKeys(gateJson, hardGateIds);
    final Map<String, bool> gates = <String, bool>{
      for (final String gateId in hardGateIds)
        gateId: requireBool(gateJson, gateId),
    };
    final String variant = requireString(json, 'variant');
    if (!<String>{baselineVariant, candidateVariant}.contains(variant)) {
      throw const FormatException('Unknown comparison variant.');
    }
    final Map<String, Object?> normalizedOutput =
        requireObject(json, 'normalizedOutput');
    if (normalizedOutput.isEmpty) {
      throw const FormatException('Redacted normalized output is required.');
    }
    return VariantEvaluation(
      variant: variant,
      requestHash: _requireHash(json, 'requestHash'),
      projectionHash: _requireHash(json, 'projectionHash'),
      caseInputHash: _requireHash(json, 'caseInputHash'),
      normalizedOutput: Map<String, Object?>.unmodifiable(normalizedOutput),
      hardGates: Map<String, bool>.unmodifiable(gates),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'variant': variant,
        'requestHash': requestHash,
        'projectionHash': projectionHash,
        'caseInputHash': caseInputHash,
        'normalizedOutput': normalizedOutput,
        'hardGates': hardGates,
      };
}

class DimensionScore {
  const DimensionScore({
    required this.baseline,
    required this.candidate,
    required this.reason,
  });

  final double baseline;
  final double candidate;
  final String reason;

  double get delta => candidate - baseline;

  factory DimensionScore.fromJson(Map<String, Object?> json) {
    requireExactKeys(json, <String>{'baseline', 'candidate', 'reason'});
    final Object? baseline = json['baseline'];
    final Object? candidate = json['candidate'];
    if (baseline is! num ||
        candidate is! num ||
        baseline < 0 ||
        baseline > 2 ||
        candidate < 0 ||
        candidate > 2) {
      throw const FormatException('Judge score is outside the frozen rubric.');
    }
    return DimensionScore(
      baseline: baseline.toDouble(),
      candidate: candidate.toDouble(),
      reason: requireString(json, 'reason'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'baseline': baseline,
        'candidate': candidate,
        'reason': reason,
      };
}

class PairedEvaluation {
  const PairedEvaluation({
    required this.runId,
    required this.runHash,
    required this.caseId,
    required this.repetition,
    required this.baseline,
    required this.candidate,
    required this.blindLabelMapping,
    required this.judgeRequest,
    required this.judgeResponse,
    required this.scores,
  });

  final String runId;
  final String runHash;
  final String caseId;
  final int repetition;
  final VariantEvaluation baseline;
  final VariantEvaluation candidate;
  final Map<String, String> blindLabelMapping;
  final Map<String, Object?> judgeRequest;
  final Map<String, Object?> judgeResponse;
  final Map<String, DimensionScore> scores;

  String get pairId => '$caseId:$repetition';

  factory PairedEvaluation.fromJson(
    Map<String, Object?> json,
    EvalRubric rubric,
  ) {
    requireExactKeys(
      json,
      <String>{
        'runId',
        'runHash',
        'caseId',
        'repetition',
        'baseline',
        'candidate',
        'blindLabelMapping',
        'judgeRequest',
        'judgeResponse',
        'scores',
      },
    );
    final VariantEvaluation baseline = VariantEvaluation.fromJson(
      requireObject(json, 'baseline'),
    );
    final VariantEvaluation candidate = VariantEvaluation.fromJson(
      requireObject(json, 'candidate'),
    );
    if (baseline.variant != baselineVariant ||
        candidate.variant != candidateVariant) {
      throw const FormatException(
          'A complete baseline/candidate pair is required.');
    }
    final Map<String, Object?> blindJson =
        requireObject(json, 'blindLabelMapping');
    requireExactKeys(blindJson, <String>{'A', 'B'});
    final Map<String, String> blind = <String, String>{
      'A': requireString(blindJson, 'A'),
      'B': requireString(blindJson, 'B'),
    };
    if (!_setEquals(blind.values.toSet(), <String>{'baseline', 'candidate'})) {
      throw const FormatException(
          'Blind labels must map both variants exactly once.');
    }
    final Map<String, Object?> scoreJson = requireObject(json, 'scores');
    final Set<String> dimensionIds = rubric.dimensions
        .map((RubricDimension dimension) => dimension.dimensionId)
        .toSet();
    requireExactKeys(scoreJson, dimensionIds);
    final Map<String, DimensionScore> scores = <String, DimensionScore>{
      for (final String dimensionId in dimensionIds)
        dimensionId: DimensionScore.fromJson(
          (scoreJson[dimensionId]! as Map).cast<String, Object?>(),
        ),
    };
    final Map<String, Object?> judgeRequest =
        requireObject(json, 'judgeRequest');
    final Map<String, Object?> judgeResponse =
        requireObject(json, 'judgeResponse');
    if (judgeRequest.isEmpty || judgeResponse.isEmpty) {
      throw const FormatException('Redacted judge artifacts are required.');
    }
    return PairedEvaluation(
      runId: requireString(json, 'runId'),
      runHash: _requireHash(json, 'runHash'),
      caseId: requireString(json, 'caseId'),
      repetition: requireInt(json, 'repetition', minimum: 1),
      baseline: baseline,
      candidate: candidate,
      blindLabelMapping: Map<String, String>.unmodifiable(blind),
      judgeRequest: Map<String, Object?>.unmodifiable(judgeRequest),
      judgeResponse: Map<String, Object?>.unmodifiable(judgeResponse),
      scores: Map<String, DimensionScore>.unmodifiable(scores),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'runId': runId,
        'runHash': runHash,
        'caseId': caseId,
        'repetition': repetition,
        'baseline': baseline.toJson(),
        'candidate': candidate.toJson(),
        'blindLabelMapping': blindLabelMapping,
        'judgeRequest': judgeRequest,
        'judgeResponse': judgeResponse,
        'scores': <String, Object?>{
          for (final String dimensionId in (scores.keys.toList()..sort()))
            dimensionId: scores[dimensionId]!.toJson(),
        },
      };
}

class MatrixCell {
  const MatrixCell({
    required this.dimensionId,
    required this.cohortId,
    required this.caseCount,
    required this.pairCount,
    required this.baselineMean,
    required this.candidateMean,
    required this.delta,
    required this.nonTieWinRate,
  });

  final String dimensionId;
  final String cohortId;
  final int caseCount;
  final int pairCount;
  final double baselineMean;
  final double candidateMean;
  final double delta;
  final double? nonTieWinRate;

  Map<String, Object?> toJson() => <String, Object?>{
        'dimensionId': dimensionId,
        'cohortId': cohortId,
        'caseCount': caseCount,
        'pairCount': pairCount,
        'baselineMean': baselineMean,
        'candidateMean': candidateMean,
        'delta': delta,
        'nonTieWinRate': nonTieWinRate,
      };
}

class ComparisonResult {
  const ComparisonResult({
    required this.passed,
    required this.issues,
    required this.matrix,
    required this.repeatableImprovementDimensions,
  });

  final bool passed;
  final List<String> issues;
  final List<MatrixCell> matrix;
  final Set<String> repeatableImprovementDimensions;

  Map<String, Object?> toJson() => <String, Object?>{
        'passed': passed,
        'issues': issues,
        'repeatableImprovementDimensions':
            repeatableImprovementDimensions.toList()..sort(),
        'dimensionCohortMatrix': matrix
            .map((MatrixCell cell) => cell.toJson())
            .toList(growable: false),
      };
}

class EvaluationComparator {
  const EvaluationComparator();

  ComparisonResult compare({
    required ComparisonIdentity identity,
    required EvalFixture fixture,
    required EvalRubric rubric,
    required List<PairedEvaluation> pairs,
  }) {
    _validateIdentity(identity, fixture, rubric);
    final Map<String, List<PairedEvaluation>> pairsByCase =
        <String, List<PairedEvaluation>>{};
    final Set<String> pairIds = <String>{};
    final Map<String, String> baselineRequestHashByCase = <String, String>{};
    final Map<String, String> candidateRequestHashByCase = <String, String>{};
    final Map<String, String> projectionHashByCase = <String, String>{};
    final Map<String, String> inputHashByCase = <String, String>{};

    for (final PairedEvaluation pair in pairs) {
      if (pair.runId != identity.runId ||
          pair.runHash != identity.runHash ||
          !pairIds.add(pair.pairId)) {
        throw const EvalFailure('pairRunOrIdentityMismatch');
      }
      fixture.caseById(pair.caseId);
      if (pair.repetition > 3) {
        throw const EvalFailure('unexpectedPairRepetition');
      }
      if (pair.baseline.projectionHash != pair.candidate.projectionHash ||
          pair.baseline.caseInputHash != pair.candidate.caseInputHash) {
        throw const EvalFailure('pairedProjectionOrInputHashMismatch');
      }
      _bindStableCaseHash(
        baselineRequestHashByCase,
        pair.caseId,
        pair.baseline.requestHash,
        'mixedBaselineRequestHash',
      );
      _bindStableCaseHash(
        candidateRequestHashByCase,
        pair.caseId,
        pair.candidate.requestHash,
        'mixedCandidateRequestHash',
      );
      _bindStableCaseHash(
        projectionHashByCase,
        pair.caseId,
        pair.baseline.projectionHash,
        'mixedProjectionHash',
      );
      _bindStableCaseHash(
        inputHashByCase,
        pair.caseId,
        pair.baseline.caseInputHash,
        'mixedCaseInputHash',
      );
      final Map<String, String> expectedBlind = blindLabelMapping(
        runId: identity.runId,
        caseId: pair.caseId,
        repetition: pair.repetition,
      );
      if (!_mapEquals(expectedBlind, pair.blindLabelMapping)) {
        throw const EvalFailure('blindLabelMappingMismatch');
      }
      pairsByCase
          .putIfAbsent(pair.caseId, () => <PairedEvaluation>[])
          .add(pair);
    }

    for (final EvalCase evalCase in fixture.cases) {
      final List<PairedEvaluation> casePairs =
          pairsByCase[evalCase.caseId] ?? const <PairedEvaluation>[];
      casePairs.sort(
        (PairedEvaluation left, PairedEvaluation right) =>
            left.repetition.compareTo(right.repetition),
      );
      if (casePairs.length != 3 ||
          !_listEquals(
            casePairs.map((PairedEvaluation pair) => pair.repetition).toList(),
            <int>[1, 2, 3],
          )) {
        throw const EvalFailure('missingCompletePairs');
      }
    }
    if (pairsByCase.length != fixture.cases.length) {
      throw const EvalFailure('unexpectedOrMissingCases');
    }
    if (canonicalRequestSetHash(
              baselineVariant,
              baselineRequestHashByCase,
            ) !=
            identity.baselineRequestSetHash ||
        canonicalRequestSetHash(
              candidateVariant,
              candidateRequestHashByCase,
            ) !=
            identity.candidateRequestSetHash) {
      throw const EvalFailure('requestSetHashMismatch');
    }
    if (sha256Json(projectionHashByCase) != identity.projectionSetHash ||
        sha256Json(inputHashByCase) != identity.caseInputSetHash) {
      throw const EvalFailure('projectionOrInputSetHashMismatch');
    }

    final List<String> issues = <String>[];
    for (final PairedEvaluation pair in pairs) {
      for (final String gateId in hardGateIds) {
        final bool baselinePassed = pair.baseline.hardGates[gateId]!;
        final bool candidatePassed = pair.candidate.hardGates[gateId]!;
        if (!candidatePassed) {
          issues.add('candidateHardGateFailure');
        }
        if (baselinePassed && !candidatePassed) {
          issues.add('hardGateRegression');
        }
      }
    }

    final Map<String, Map<String, _CaseScore>> caseScores =
        _aggregateCases(fixture, rubric, pairsByCase);
    final List<MatrixCell> matrix = <MatrixCell>[];
    for (final RubricDimension dimension in rubric.dimensions) {
      for (final String cohort in rubric.cohorts) {
        final List<EvalCase> cohortCases = fixture.cases
            .where((EvalCase evalCase) => evalCase.belongsTo(cohort))
            .toList(growable: false);
        if (cohortCases.isEmpty) {
          throw const EvalFailure('emptyDeclaredCohort');
        }
        final List<_CaseScore> scores = cohortCases
            .map(
              (EvalCase evalCase) =>
                  caseScores[evalCase.caseId]![dimension.dimensionId]!,
            )
            .toList(growable: false);
        final double baselineMean =
            _mean(scores.map((_CaseScore score) => score.baselineMean));
        final double candidateMean =
            _mean(scores.map((_CaseScore score) => score.candidateMean));
        final List<double> pairDeltas = <double>[
          for (final EvalCase evalCase in cohortCases)
            ...pairsByCase[evalCase.caseId]!.map(
              (PairedEvaluation pair) =>
                  pair.scores[dimension.dimensionId]!.delta,
            ),
        ];
        final List<double> nonTies = pairDeltas
            .where((double delta) => delta != 0)
            .toList(growable: false);
        final double delta = candidateMean - baselineMean;
        if (delta < 0) {
          issues.add('dimensionCohortRegression');
        }
        matrix.add(MatrixCell(
          dimensionId: dimension.dimensionId,
          cohortId: cohort,
          caseCount: cohortCases.length,
          pairCount: pairDeltas.length,
          baselineMean: baselineMean,
          candidateMean: candidateMean,
          delta: delta,
          nonTieWinRate: nonTies.isEmpty
              ? null
              : nonTies.where((double value) => value > 0).length /
                  nonTies.length,
        ));
      }
    }
    final Set<String> improvements = _repeatableImprovements(
      fixture: fixture,
      rubric: rubric,
      pairsByCase: pairsByCase,
      matrix: matrix,
      caseScores: caseScores,
    );
    if (improvements.isEmpty) {
      issues.add('repeatableImprovementMissing');
    }
    final List<String> normalizedIssues = issues.toSet().toList()..sort();
    return ComparisonResult(
      passed: normalizedIssues.isEmpty,
      issues: List<String>.unmodifiable(normalizedIssues),
      matrix: List<MatrixCell>.unmodifiable(matrix),
      repeatableImprovementDimensions: Set<String>.unmodifiable(improvements),
    );
  }

  void _validateIdentity(
    ComparisonIdentity identity,
    EvalFixture fixture,
    EvalRubric rubric,
  ) {
    if (identity.fixtureHash != fixture.hash ||
        identity.rubricHash != rubric.hash ||
        identity.modelHash != identity.judgeModelHash ||
        identity.runHash != comparisonRunHash(identity)) {
      throw const EvalFailure('comparisonIdentityMismatch');
    }
  }

  Map<String, Map<String, _CaseScore>> _aggregateCases(
    EvalFixture fixture,
    EvalRubric rubric,
    Map<String, List<PairedEvaluation>> pairsByCase,
  ) {
    return <String, Map<String, _CaseScore>>{
      for (final EvalCase evalCase in fixture.cases)
        evalCase.caseId: <String, _CaseScore>{
          for (final RubricDimension dimension in rubric.dimensions)
            dimension.dimensionId: _CaseScore(
              baselineMean: _mean(
                pairsByCase[evalCase.caseId]!.map(
                  (PairedEvaluation pair) =>
                      pair.scores[dimension.dimensionId]!.baseline,
                ),
              ),
              candidateMean: _mean(
                pairsByCase[evalCase.caseId]!.map(
                  (PairedEvaluation pair) =>
                      pair.scores[dimension.dimensionId]!.candidate,
                ),
              ),
            ),
        },
    };
  }

  Set<String> _repeatableImprovements({
    required EvalFixture fixture,
    required EvalRubric rubric,
    required Map<String, List<PairedEvaluation>> pairsByCase,
    required List<MatrixCell> matrix,
    required Map<String, Map<String, _CaseScore>> caseScores,
  }) {
    final Set<String> result = <String>{};
    for (final RubricDimension dimension
        in rubric.dimensions.where((RubricDimension value) => value.core)) {
      final MatrixCell overall = matrix.singleWhere(
        (MatrixCell cell) =>
            cell.dimensionId == dimension.dimensionId &&
            cell.cohortId == 'overall',
      );
      final MatrixCell holdout = matrix.singleWhere(
        (MatrixCell cell) =>
            cell.dimensionId == dimension.dimensionId &&
            cell.cohortId == 'holdout',
      );
      if (overall.delta < 0.2 ||
          holdout.delta < 0.2 ||
          (overall.nonTieWinRate ?? 0) < 0.6 ||
          (holdout.nonTieWinRate ?? 0) < 0.6) {
        continue;
      }
      bool consistentForCohort(String cohort) {
        final List<EvalCase> improvedCases = fixture.cases
            .where(
              (EvalCase evalCase) =>
                  evalCase.belongsTo(cohort) &&
                  caseScores[evalCase.caseId]![dimension.dimensionId]!.delta >
                      0,
            )
            .toList(growable: false);
        return improvedCases.isNotEmpty &&
            improvedCases.every((EvalCase evalCase) {
              final int positiveRepetitions = pairsByCase[evalCase.caseId]!
                  .where(
                    (PairedEvaluation pair) =>
                        pair.scores[dimension.dimensionId]!.delta > 0,
                  )
                  .length;
              return positiveRepetitions >= 2;
            });
      }

      if (consistentForCohort('overall') && consistentForCohort('holdout')) {
        result.add(dimension.dimensionId);
      }
    }
    return result;
  }
}

Map<String, String> blindLabelMapping({
  required String runId,
  required String caseId,
  required int repetition,
}) {
  final String hash = sha256Text(
    '$judgeOrderSalt\n$runId\n$caseId\n$repetition',
  );
  final bool baselineFirst =
      int.parse(hash.substring(hash.length - 2), radix: 16).isEven;
  return baselineFirst
      ? const <String, String>{'A': 'baseline', 'B': 'candidate'}
      : const <String, String>{'A': 'candidate', 'B': 'baseline'};
}

String comparisonRunHash(ComparisonIdentity identity) =>
    sha256Json(<String, Object?>{
      'runId': identity.runId,
      'fixtureHash': identity.fixtureHash,
      'rubricHash': identity.rubricHash,
      'adapterHash': identity.adapterHash,
      'projectionSetHash': identity.projectionSetHash,
      'caseInputSetHash': identity.caseInputSetHash,
      'modelHash': identity.modelHash,
      'judgeModelHash': identity.judgeModelHash,
      'transportEndpointHash': identity.transportEndpointHash,
      'transportTimeoutSeconds': identity.transportTimeoutSeconds,
      'transportRetryPolicyVersion': identity.transportRetryPolicyVersion,
      'requestParametersHash': identity.requestParametersHash,
      'judgeRequestContractHash': identity.judgeRequestContractHash,
      'baselineRequestSetHash': identity.baselineRequestSetHash,
      'candidateRequestSetHash': identity.candidateRequestSetHash,
    });

class _CaseScore {
  const _CaseScore({
    required this.baselineMean,
    required this.candidateMean,
  });

  final double baselineMean;
  final double candidateMean;

  double get delta => candidateMean - baselineMean;
}

String _requireHash(Map<String, Object?> json, String key) {
  final String value = requireString(json, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw const FormatException('Expected a lowercase SHA-256 hash.');
  }
  return value;
}

int _requireTransportTimeout(Map<String, Object?> json) {
  final value = requireInt(
    json,
    'transportTimeoutSeconds',
    minimum: minimumTransportTimeoutSeconds,
  );
  if (value > maximumTransportTimeoutSeconds) {
    throw const FormatException('Transport timeout exceeds maximum.');
  }
  return value;
}

void _bindStableCaseHash(
  Map<String, String> target,
  String caseId,
  String value,
  String failure,
) {
  final String? existing = target[caseId];
  if (existing != null && existing != value) {
    throw EvalFailure(failure);
  }
  target[caseId] = value;
}

double _mean(Iterable<double> values) {
  final List<double> materialized = values.toList(growable: false);
  if (materialized.isEmpty) {
    throw const EvalFailure('emptyAggregation');
  }
  return materialized.fold(0.0, (double sum, double value) => sum + value) /
      materialized.length;
}

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every(
      (MapEntry<String, String> entry) => right[entry.key] == entry.value,
    );
