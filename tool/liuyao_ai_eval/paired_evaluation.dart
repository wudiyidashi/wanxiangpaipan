import 'assets.dart';
import 'canonical_contract.dart';
import 'canonical_json.dart';
import 'comparison.dart';
import 'constants.dart';
import 'hard_gates.dart';
import 'holdout.dart';
import 'model_transport.dart';
import 'security.dart';

const String _generationArtifactSchemaVersion =
    'liuyao-ai-generation-artifact/1.0.0';

class CanonicalPairContract {
  const CanonicalPairContract({
    required this.baseline,
    required this.candidate,
    required this.holdout,
    required this.candidateHash,
  });

  final CanonicalRequestSet baseline;
  final CanonicalRequestSet candidate;
  final HoldoutSelection holdout;
  final String candidateHash;
}

CanonicalPairContract validateCanonicalRequestPair({
  required CanonicalRequestSet baseline,
  required CanonicalRequestSet candidate,
  required EvalFixture fixture,
}) {
  if (baseline.runId != candidate.runId ||
      baseline.variant != baselineVariant ||
      candidate.variant != candidateVariant ||
      baseline.adapterHash != candidate.adapterHash ||
      baseline.fixtureHash != candidate.fixtureHash ||
      baseline.rubricHash != candidate.rubricHash ||
      baseline.projectionSchemaVersion != candidate.projectionSchemaVersion ||
      baseline.ruleSetId != candidate.ruleSetId ||
      baseline.ruleSetVersion != candidate.ruleSetVersion ||
      baseline.requestParametersHash != candidate.requestParametersHash ||
      baseline.projectionSetHash != candidate.projectionSetHash ||
      baseline.caseInputSetHash != candidate.caseInputSetHash ||
      baseline.requests.length != candidate.requests.length) {
    throw const EvalFailure('canonicalRequestSetIdentityMismatch');
  }
  for (int index = 0; index < baseline.requests.length; index += 1) {
    final CanonicalPreparedRequest left = baseline.requests[index];
    final CanonicalPreparedRequest right = candidate.requests[index];
    if (left.caseId != right.caseId ||
        left.caseInputHash != right.caseInputHash ||
        left.projectionHash != right.projectionHash ||
        sha256Json(left.caseInput) != sha256Json(right.caseInput)) {
      throw const EvalFailure('canonicalPairedInputMismatch');
    }
  }
  final HoldoutSelection holdout = selectHoldout(
    fixture.cases
        .where((EvalCase evalCase) => evalCase.caseKind == 'originalBook')
        .map((EvalCase evalCase) => evalCase.caseId),
  );
  final List<String> declaredHoldout = fixture.cases
      .where((EvalCase evalCase) => evalCase.evaluationSplit == 'holdout')
      .map((EvalCase evalCase) => evalCase.caseId)
      .toList(growable: false);
  final List<String> expectedHoldout = holdout.members
      .map((HoldoutMember member) => member.caseId)
      .toList(growable: false);
  final List<String> sortedDeclared = List<String>.from(declaredHoldout)
    ..sort();
  final List<String> sortedExpected = List<String>.from(expectedHoldout)
    ..sort();
  if (!_listEquals(sortedDeclared, sortedExpected)) {
    throw const EvalFailure('fixtureHoldoutSelectionMismatch');
  }
  return CanonicalPairContract(
    baseline: baseline,
    candidate: candidate,
    holdout: holdout,
    candidateHash: sha256Json(<String, Object?>{
      'variant': candidate.variant,
      'adapterHash': candidate.adapterHash,
      'fixtureHash': candidate.fixtureHash,
      'rubricHash': candidate.rubricHash,
      'projectionSetHash': candidate.projectionSetHash,
      'caseInputSetHash': candidate.caseInputSetHash,
      'requestParametersHash': candidate.requestParametersHash,
      'requestSetHash': candidate.requestSetHash,
    }),
  );
}

class OfflineComparisonManifest {
  const OfflineComparisonManifest({
    required this.runId,
    required this.candidateHash,
    required this.adapterHash,
    required this.fixtureHash,
    required this.rubricHash,
    required this.projectionSetHash,
    required this.caseInputSetHash,
    required this.requestParametersHash,
    required this.baselineRequestSetHash,
    required this.candidateRequestSetHash,
    required this.holdout,
  });

  final String runId;
  final String candidateHash;
  final String adapterHash;
  final String fixtureHash;
  final String rubricHash;
  final String projectionSetHash;
  final String caseInputSetHash;
  final String requestParametersHash;
  final String baselineRequestSetHash;
  final String candidateRequestSetHash;
  final HoldoutSelection holdout;

  factory OfflineComparisonManifest.create(CanonicalPairContract contract) =>
      OfflineComparisonManifest(
        runId: contract.baseline.runId,
        candidateHash: contract.candidateHash,
        adapterHash: contract.baseline.adapterHash,
        fixtureHash: contract.baseline.fixtureHash,
        rubricHash: contract.baseline.rubricHash,
        projectionSetHash: contract.baseline.projectionSetHash,
        caseInputSetHash: contract.baseline.caseInputSetHash,
        requestParametersHash: contract.baseline.requestParametersHash,
        baselineRequestSetHash: contract.baseline.requestSetHash,
        candidateRequestSetHash: contract.candidate.requestSetHash,
        holdout: contract.holdout,
      );

  factory OfflineComparisonManifest.fromJson(
    Map<String, Object?> json, {
    required CanonicalPairContract contract,
  }) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'status',
        'runId',
        'candidateHash',
        'adapterHash',
        'fixtureHash',
        'rubricHash',
        'projectionSetHash',
        'caseInputSetHash',
        'requestParametersHash',
        'baselineRequestSetHash',
        'candidateRequestSetHash',
        'holdout',
      },
    );
    final Map<String, Object?> holdoutJson = requireObject(json, 'holdout');
    requireExactKeys(
      holdoutJson,
      <String>{'selectionSalt', 'members', 'cohortHash'},
    );
    if (requireString(json, 'schemaVersion') !=
            evalOfflineComparisonSchemaVersion ||
        requireString(json, 'status') != 'ready' ||
        requireString(json, 'runId') != contract.baseline.runId ||
        requireSha256(json, 'candidateHash') != contract.candidateHash ||
        requireSha256(json, 'adapterHash') != contract.baseline.adapterHash ||
        requireSha256(json, 'fixtureHash') != contract.baseline.fixtureHash ||
        requireSha256(json, 'rubricHash') != contract.baseline.rubricHash ||
        requireSha256(json, 'projectionSetHash') !=
            contract.baseline.projectionSetHash ||
        requireSha256(json, 'caseInputSetHash') !=
            contract.baseline.caseInputSetHash ||
        requireSha256(json, 'requestParametersHash') !=
            contract.baseline.requestParametersHash ||
        requireSha256(json, 'baselineRequestSetHash') !=
            contract.baseline.requestSetHash ||
        requireSha256(json, 'candidateRequestSetHash') !=
            contract.candidate.requestSetHash ||
        requireString(holdoutJson, 'selectionSalt') != holdoutSelectionSalt ||
        requireSha256(holdoutJson, 'cohortHash') !=
            contract.holdout.cohortHash ||
        sha256Json(holdoutJson) != sha256Json(contract.holdout.toJson())) {
      throw const FormatException('Offline comparison manifest mismatch.');
    }
    return OfflineComparisonManifest.create(contract);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': evalOfflineComparisonSchemaVersion,
        'status': 'ready',
        'runId': runId,
        'candidateHash': candidateHash,
        'adapterHash': adapterHash,
        'fixtureHash': fixtureHash,
        'rubricHash': rubricHash,
        'projectionSetHash': projectionSetHash,
        'caseInputSetHash': caseInputSetHash,
        'requestParametersHash': requestParametersHash,
        'baselineRequestSetHash': baselineRequestSetHash,
        'candidateRequestSetHash': candidateRequestSetHash,
        'holdout': holdout.toJson(),
      };
}

List<String> pairedGenerationOrder({
  required String runId,
  required String caseId,
  required int repetition,
}) {
  final String hash = sha256Text(
    '$generationOrderSalt\n$runId\n$caseId\n$repetition',
  );
  final bool baselineFirst =
      int.parse(hash.substring(hash.length - 2), radix: 16).isEven;
  return baselineFirst
      ? const <String>[baselineVariant, candidateVariant]
      : const <String>[candidateVariant, baselineVariant];
}

class BlindDimensionScore {
  const BlindDimensionScore({
    required this.a,
    required this.b,
    required this.reason,
  });

  final double a;
  final double b;
  final String reason;

  factory BlindDimensionScore.fromJson(Map<String, Object?> json) {
    requireExactKeys(json, <String>{'A', 'B', 'reason'});
    final Object? a = json['A'];
    final Object? b = json['B'];
    if (a is! num || b is! num || a < 0 || a > 2 || b < 0 || b > 2) {
      throw const FormatException('Blind judge score is outside 0-2.');
    }
    return BlindDimensionScore(
      a: a.toDouble(),
      b: b.toDouble(),
      reason: requireString(json, 'reason'),
    );
  }
}

class JudgeEvaluation {
  const JudgeEvaluation({
    required this.normalizedByLabel,
    required this.scoresByDimension,
    required this.rawResponse,
  });

  final Map<String, NormalizedModelOutput> normalizedByLabel;
  final Map<String, BlindDimensionScore> scoresByDimension;
  final Map<String, Object?> rawResponse;

  factory JudgeEvaluation.fromContent({
    required String content,
    required String caseId,
    required int repetition,
    required EvalRubric rubric,
  }) {
    final Map<String, Object?> json = decodeObject(content);
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'caseId',
        'repetition',
        'normalizedOutputs',
        'scores',
      },
    );
    if (requireString(json, 'schemaVersion') !=
            evalJudgeResponseSchemaVersion ||
        requireString(json, 'caseId') != caseId ||
        requireInt(json, 'repetition', minimum: 1) != repetition) {
      throw const FormatException('Judge response identity mismatch.');
    }
    final Map<String, Object?> normalized =
        requireObject(json, 'normalizedOutputs');
    requireExactKeys(normalized, <String>{'A', 'B'});
    final Map<String, Object?> scores = requireObject(json, 'scores');
    final Set<String> dimensionIds = rubric.dimensions
        .map((RubricDimension dimension) => dimension.dimensionId)
        .toSet();
    requireExactKeys(scores, dimensionIds);
    return JudgeEvaluation(
      normalizedByLabel: Map<String, NormalizedModelOutput>.unmodifiable(
        <String, NormalizedModelOutput>{
          for (final String label in <String>['A', 'B'])
            label: NormalizedModelOutput.fromJson(
              (normalized[label]! as Map).cast<String, Object?>(),
            ),
        },
      ),
      scoresByDimension: Map<String, BlindDimensionScore>.unmodifiable(
        <String, BlindDimensionScore>{
          for (final String dimensionId in dimensionIds)
            dimensionId: BlindDimensionScore.fromJson(
              (scores[dimensionId]! as Map).cast<String, Object?>(),
            ),
        },
      ),
      rawResponse: Map<String, Object?>.unmodifiable(json),
    );
  }

  NormalizedModelOutput normalizedForVariant(
    String variant,
    Map<String, String> blindMapping,
  ) {
    final String blindVariant = switch (variant) {
      baselineVariant => 'baseline',
      candidateVariant => 'candidate',
      _ => throw const FormatException('Unknown canonical variant.'),
    };
    final String label = blindMapping.entries
        .singleWhere(
          (MapEntry<String, String> entry) => entry.value == blindVariant,
        )
        .key;
    return normalizedByLabel[label]!;
  }

  Map<String, DimensionScore> dimensionScores(
    Map<String, String> blindMapping,
  ) {
    final String baselineLabel = blindMapping.entries
        .singleWhere(
          (MapEntry<String, String> entry) => entry.value == 'baseline',
        )
        .key;
    final String candidateLabel = blindMapping.entries
        .singleWhere(
          (MapEntry<String, String> entry) => entry.value == 'candidate',
        )
        .key;
    return <String, DimensionScore>{
      for (final MapEntry<String, BlindDimensionScore> entry
          in scoresByDimension.entries)
        entry.key: DimensionScore(
          baseline: baselineLabel == 'A' ? entry.value.a : entry.value.b,
          candidate: candidateLabel == 'A' ? entry.value.a : entry.value.b,
          reason: entry.value.reason,
        ),
    };
  }
}

Map<String, Object?> buildJudgeRequest({
  required String runId,
  required EvalCase evalCase,
  required int repetition,
  required EvalRubric rubric,
  required Map<String, String> blindMapping,
  required Map<String, String> generationContentByVariant,
}) {
  final Map<String, String> blindOutputs = <String, String>{
    for (final MapEntry<String, String> entry in blindMapping.entries)
      entry.key: generationContentByVariant[
          entry.value == 'baseline' ? baselineVariant : candidateVariant]!,
  };
  return <String, Object?>{
    'schemaVersion': evalJudgeRequestSchemaVersion,
    'runId': runId,
    'caseId': evalCase.caseId,
    'repetition': repetition,
    'caseInput': evalCase.requestInput,
    'scoringReference': evalCase.scoringReference.toJson(),
    'rubric': <String, Object?>{
      'dimensions': <Object?>[
        for (final RubricDimension dimension in rubric.dimensions)
          <String, Object?>{
            'dimensionId': dimension.dimensionId,
            'description': dimension.description,
            'anchors': <String, Object?>{
              for (final int score in <int>[0, 1, 2])
                '$score': dimension.anchors[score],
            },
          },
      ],
    },
    'blindOutputs': blindOutputs,
    'requiredResponseSchema': <String, Object?>{
      'schemaVersion': evalJudgeResponseSchemaVersion,
      'caseId': evalCase.caseId,
      'repetition': repetition,
      'normalizedOutputLabels': <String>['A', 'B'],
      'scoreDimensions': rubric.dimensions
          .map((RubricDimension dimension) => dimension.dimensionId)
          .toList(growable: false),
    },
  };
}

String get judgeSystemPrompt =>
    'You are a blind evaluator. Return only one JSON object matching the '
    'requiredResponseSchema. Normalize factual claims for both labels using '
    'only caseInput and scoringReference, score every frozen rubric dimension '
    'from 0 to 2, and never infer which label is baseline or candidate.';

Map<String, Object?> generationArtifactJson({
  required ModelCallResult result,
  required NormalizedModelOutput normalized,
  required String logicalRequestId,
  required int orderIndex,
}) =>
    <String, Object?>{
      'schemaVersion': _generationArtifactSchemaVersion,
      'logicalRequestId': logicalRequestId,
      'orderIndex': orderIndex,
      'content': result.content,
      'claims': normalized.toJson(),
      'tokensUsed': result.tokensUsed,
      'latencyMilliseconds': result.latencyMilliseconds,
      'seedSupported': result.seedSupported,
      'statusCode': result.statusCode,
      'retryCount': result.retryCount,
    };

class PairedRunArtifact {
  const PairedRunArtifact({
    required this.runId,
    required this.candidateHash,
    required this.model,
    required this.providerLabel,
    required this.identity,
    required this.pairs,
  });

  final String runId;
  final String candidateHash;
  final String model;
  final String? providerLabel;
  final ComparisonIdentity identity;
  final List<PairedEvaluation> pairs;

  factory PairedRunArtifact.fromJson(
    Map<String, Object?> json, {
    required CanonicalPairContract contract,
    required EvalFixture fixture,
    required EvalRubric rubric,
  }) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'status',
        'runId',
        'candidateHash',
        'generationOrderSalt',
        'judgeOrderSalt',
        'modelMetadata',
        'identity',
        'pairs',
      },
    );
    final Map<String, Object?> metadata = requireObject(json, 'modelMetadata');
    requireExactKeys(metadata, <String>{'providerLabel', 'model'});
    final Object? providerLabel = metadata['providerLabel'];
    if (providerLabel != null && providerLabel is! String) {
      throw const FormatException('Invalid provider label artifact.');
    }
    final String model = requireString(metadata, 'model');
    final ComparisonIdentity identity = ComparisonIdentity.fromJson(
      requireObject(json, 'identity'),
    );
    if (requireString(json, 'schemaVersion') != evalPairedRunSchemaVersion ||
        requireString(json, 'status') != 'completed' ||
        requireString(json, 'runId') != contract.baseline.runId ||
        requireSha256(json, 'candidateHash') != contract.candidateHash ||
        requireString(json, 'generationOrderSalt') != generationOrderSalt ||
        requireString(json, 'judgeOrderSalt') != judgeOrderSalt ||
        identity.runId != contract.baseline.runId ||
        identity.fixtureHash != fixture.hash ||
        identity.rubricHash != rubric.hash ||
        identity.adapterHash != contract.baseline.adapterHash ||
        identity.projectionSetHash != contract.baseline.projectionSetHash ||
        identity.caseInputSetHash != contract.baseline.caseInputSetHash ||
        identity.requestParametersHash !=
            contract.baseline.requestParametersHash ||
        identity.baselineRequestSetHash != contract.baseline.requestSetHash ||
        identity.candidateRequestSetHash != contract.candidate.requestSetHash ||
        identity.modelHash != sha256Text(model) ||
        identity.judgeModelHash != sha256Text(model) ||
        identity.runHash != comparisonRunHash(identity)) {
      throw const FormatException('Paired run artifact identity mismatch.');
    }
    final List<PairedEvaluation> pairs = requireList(json, 'pairs')
        .map(
          (Object? value) => PairedEvaluation.fromJson(
            (value as Map).cast<String, Object?>(),
            rubric,
          ),
        )
        .toList(growable: false);
    for (final PairedEvaluation pair in pairs) {
      final EvalCase evalCase = fixture.caseById(pair.caseId);
      final List<String> expectedOrder = pairedGenerationOrder(
        runId: contract.baseline.runId,
        caseId: pair.caseId,
        repetition: pair.repetition,
      );
      final NormalizedModelOutput baselineNormalized =
          _validateGenerationArtifact(
        pair.baseline.normalizedOutput,
        expectedLogicalRequestId: sha256Text(
          '${contract.baseline.runId}\n${pair.caseId}\n${pair.repetition}\n$baselineVariant',
        ),
        expectedOrderIndex: expectedOrder.indexOf(baselineVariant),
      );
      final NormalizedModelOutput candidateNormalized =
          _validateGenerationArtifact(
        pair.candidate.normalizedOutput,
        expectedLogicalRequestId: sha256Text(
          '${contract.baseline.runId}\n${pair.caseId}\n${pair.repetition}\n$candidateVariant',
        ),
        expectedOrderIndex: expectedOrder.indexOf(candidateVariant),
      );
      final Map<String, String> generationContent = <String, String>{
        baselineVariant:
            requireString(pair.baseline.normalizedOutput, 'content'),
        candidateVariant:
            requireString(pair.candidate.normalizedOutput, 'content'),
      };
      final Map<String, Object?> expectedJudgeRequest = buildJudgeRequest(
        runId: contract.baseline.runId,
        evalCase: evalCase,
        repetition: pair.repetition,
        rubric: rubric,
        blindMapping: pair.blindLabelMapping,
        generationContentByVariant: generationContent,
      );
      final JudgeEvaluation judge = JudgeEvaluation.fromContent(
        content: canonicalJson(pair.judgeResponse),
        caseId: pair.caseId,
        repetition: pair.repetition,
        rubric: rubric,
      );
      final NormalizedModelOutput judgedBaseline =
          judge.normalizedForVariant(baselineVariant, pair.blindLabelMapping);
      final NormalizedModelOutput judgedCandidate = judge.normalizedForVariant(
        candidateVariant,
        pair.blindLabelMapping,
      );
      final HardGateResult baselineGates =
          const HardGateEvaluator().evaluate(evalCase, baselineNormalized);
      final HardGateResult candidateGates =
          const HardGateEvaluator().evaluate(evalCase, candidateNormalized);
      final Map<String, DimensionScore> judgedScores =
          judge.dimensionScores(pair.blindLabelMapping);
      if (sha256Json(pair.judgeRequest) != sha256Json(expectedJudgeRequest) ||
          sha256Json(baselineNormalized.toJson()) !=
              sha256Json(judgedBaseline.toJson()) ||
          sha256Json(candidateNormalized.toJson()) !=
              sha256Json(judgedCandidate.toJson()) ||
          !_boolMapEquals(pair.baseline.hardGates, baselineGates.gates) ||
          !_boolMapEquals(pair.candidate.hardGates, candidateGates.gates) ||
          !_scoreMapEquals(pair.scores, judgedScores)) {
        throw const FormatException('Paired judge artifact mismatch.');
      }
    }
    return PairedRunArtifact(
      runId: contract.baseline.runId,
      candidateHash: contract.candidateHash,
      model: model,
      providerLabel: providerLabel as String?,
      identity: identity,
      pairs: List<PairedEvaluation>.unmodifiable(pairs),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': evalPairedRunSchemaVersion,
        'status': 'completed',
        'runId': runId,
        'candidateHash': candidateHash,
        'generationOrderSalt': generationOrderSalt,
        'judgeOrderSalt': judgeOrderSalt,
        'modelMetadata': <String, Object?>{
          'providerLabel': providerLabel,
          'model': model,
        },
        'identity': identity.toJson(),
        'pairs': pairs
            .map((PairedEvaluation pair) => pair.toJson())
            .toList(growable: false),
      };
}

NormalizedModelOutput _validateGenerationArtifact(
  Map<String, Object?> json, {
  required String expectedLogicalRequestId,
  required int expectedOrderIndex,
}) {
  requireExactKeys(
    json,
    <String>{
      'schemaVersion',
      'logicalRequestId',
      'orderIndex',
      'content',
      'claims',
      'tokensUsed',
      'latencyMilliseconds',
      'seedSupported',
      'statusCode',
      'retryCount',
    },
  );
  if (requireString(json, 'schemaVersion') !=
      _generationArtifactSchemaVersion) {
    throw const FormatException('Generation artifact schema mismatch.');
  }
  if (requireSha256(json, 'logicalRequestId') != expectedLogicalRequestId) {
    throw const FormatException('Generation logical request mismatch.');
  }
  final int orderIndex = requireInt(json, 'orderIndex');
  if (orderIndex != expectedOrderIndex) {
    throw const FormatException('Generation order index is invalid.');
  }
  requireString(json, 'content');
  final NormalizedModelOutput normalized =
      NormalizedModelOutput.fromJson(requireObject(json, 'claims'));
  _requireNullableInt(json, 'tokensUsed');
  requireInt(json, 'latencyMilliseconds', minimum: 0);
  _requireNullableBool(json, 'seedSupported');
  _requireNullableInt(json, 'statusCode');
  requireInt(json, 'retryCount', minimum: 0);
  return normalized;
}

void _requireNullableInt(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value != null && value is! int) {
    throw const FormatException('Expected nullable integer.');
  }
}

void _requireNullableBool(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value != null && value is! bool) {
    throw const FormatException('Expected nullable boolean.');
  }
}

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

bool _boolMapEquals(Map<String, bool> left, Map<String, bool> right) =>
    left.length == right.length &&
    left.entries.every(
      (MapEntry<String, bool> entry) => right[entry.key] == entry.value,
    );

bool _scoreMapEquals(
  Map<String, DimensionScore> left,
  Map<String, DimensionScore> right,
) =>
    left.length == right.length &&
    left.entries.every((MapEntry<String, DimensionScore> entry) {
      final DimensionScore? other = right[entry.key];
      return other != null &&
          other.baseline == entry.value.baseline &&
          other.candidate == entry.value.candidate &&
          other.reason == entry.value.reason;
    });
