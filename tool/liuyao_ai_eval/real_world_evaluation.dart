import 'canonical_json.dart';
import 'comparison.dart';
import 'constants.dart';
import 'real_world_contract.dart';

class RealWorldJudgeEvaluation {
  const RealWorldJudgeEvaluation({
    required this.scores,
    required this.raw,
  });

  final Map<String, RealWorldBlindDimensionScore> scores;
  final Map<String, Object?> raw;

  factory RealWorldJudgeEvaluation.fromContent({
    required String content,
    required RealWorldJudgeReference reference,
    required String scenarioId,
    required int repetition,
  }) {
    final Map<String, Object?> json = decodeObject(content);
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'caseId',
        'scenarioId',
        'repetition',
        'scores',
      },
    );
    if (requireString(json, 'schemaVersion') !=
            realWorldJudgeResponseSchemaVersion ||
        requireString(json, 'caseId') != reference.caseId ||
        requireString(json, 'scenarioId') != scenarioId ||
        requireInt(json, 'repetition', minimum: 1) != repetition) {
      throw const FormatException('Real-world judge identity mismatch.');
    }
    final Map<String, Object?> rawScores = requireObject(json, 'scores');
    final Set<String> dimensions = requireStringList(
      reference.document,
      'scoreDimensions',
    ).toSet();
    requireExactKeys(rawScores, dimensions);
    return RealWorldJudgeEvaluation(
      scores: Map<String, RealWorldBlindDimensionScore>.unmodifiable(
        <String, RealWorldBlindDimensionScore>{
          for (final String dimension in dimensions)
            dimension: RealWorldBlindDimensionScore.fromJson(
              (rawScores[dimension]! as Map).cast<String, Object?>(),
            ),
        },
      ),
      raw: Map<String, Object?>.unmodifiable(json),
    );
  }
}

Map<String, Object?> realWorldRunIdentity({
  required String runId,
  required RealWorldGenerationFixture fixture,
  required RealWorldEvalAdapter adapter,
  required String modelHash,
  required String transportEndpointHash,
  required int transportTimeoutSeconds,
  required String judgeReferenceAssetHash,
}) {
  final Map<String, Object?> identity = <String, Object?>{
    'schemaVersion': realWorldRunSchemaVersion,
    'runId': runId,
    'generationFixtureHash': fixture.hash,
    'adapterHash': adapter.hash,
    'modelHash': modelHash,
    'transportEndpointHash': transportEndpointHash,
    'transportTimeoutSeconds': transportTimeoutSeconds,
    'transportRetryPolicyVersion': transportRetryPolicyVersion,
    'requestParameters': adapter.requestParameters.toJson(),
    'judgeReferenceAssetHash': judgeReferenceAssetHash,
    'judgeRequestContractHash': realWorldJudgeRequestContractHash,
    'judgeResponseSchemaVersion': realWorldJudgeResponseSchemaVersion,
  };
  return <String, Object?>{
    ...identity,
    'runHash': sha256Json(identity),
  };
}

String realWorldRunIdentityHash({
  required String runId,
  required RealWorldGenerationFixture fixture,
  required RealWorldEvalAdapter adapter,
  required String modelHash,
  required String transportEndpointHash,
  required int transportTimeoutSeconds,
  required String judgeReferenceAssetHash,
}) =>
    requireString(
      realWorldRunIdentity(
        runId: runId,
        fixture: fixture,
        adapter: adapter,
        modelHash: modelHash,
        transportEndpointHash: transportEndpointHash,
        transportTimeoutSeconds: transportTimeoutSeconds,
        judgeReferenceAssetHash: judgeReferenceAssetHash,
      ),
      'runHash',
    );

class RealWorldBlindDimensionScore {
  const RealWorldBlindDimensionScore({
    required this.a,
    required this.b,
    required this.reason,
  });

  final double a;
  final double b;
  final String reason;

  factory RealWorldBlindDimensionScore.fromJson(Map<String, Object?> json) {
    requireExactKeys(json, <String>{'A', 'B', 'reason'});
    final Object? a = json['A'];
    final Object? b = json['B'];
    if (a is! num || b is! num || a < 0 || a > 2 || b < 0 || b > 2) {
      throw const FormatException('Real-world judge score is outside 0-2.');
    }
    return RealWorldBlindDimensionScore(
      a: a.toDouble(),
      b: b.toDouble(),
      reason: requireString(json, 'reason'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'A': a,
        'B': b,
        'reason': reason,
      };
}

Map<String, String> realWorldBlindMapping({
  required String runId,
  required String scenarioId,
  required int repetition,
}) {
  final Map<String, String> canonical = blindLabelMapping(
    runId: runId,
    caseId: scenarioId,
    repetition: repetition,
  );
  return <String, String>{
    for (final MapEntry<String, String> entry in canonical.entries)
      entry.key: entry.value == 'baseline'
          ? realWorldBaselineVariant
          : realWorldCandidateVariant,
  };
}

Map<String, Object?> buildRealWorldJudgeRequest({
  required String runId,
  required RealWorldGenerationFixture fixture,
  required RealWorldJudgeReference reference,
  required RealWorldAdapterCase adapterCase,
  required int repetition,
  required Map<String, String> blindMapping,
  required Map<String, String> generationContent,
}) {
  final List<String> dimensions = requireStringList(
    reference.document,
    'scoreDimensions',
  );
  return <String, Object?>{
    'schemaVersion': 'liuyao-real-world-judge-request/1.0.0',
    'runId': runId,
    'caseId': fixture.caseId,
    'scenarioId': adapterCase.scenarioId,
    'repetition': repetition,
    'generationInput': fixture.generationInput(
      fixture.scenario(adapterCase.scenarioId),
    ),
    'judgeOnlyReference': reference.document,
    'blindOutputs': <String, Object?>{
      for (final MapEntry<String, String> entry in blindMapping.entries)
        entry.key: <String, Object?>{
          'modelOutput': generationContent[entry.value],
        },
    },
    'requiredResponseSchema': <String, Object?>{
      'exactTopLevelKeys': <String>[
        'schemaVersion',
        'caseId',
        'scenarioId',
        'repetition',
        'scores',
      ],
      'schemaVersion': realWorldJudgeResponseSchemaVersion,
      'caseId': fixture.caseId,
      'scenarioId': adapterCase.scenarioId,
      'repetition': repetition,
      'scores': <String, Object?>{
        for (final String dimension in dimensions)
          dimension: <String, Object?>{
            'exactKeys': <String>['A', 'B', 'reason'],
            'types': <String, String>{
              'A': 'number 0..2',
              'B': 'number 0..2',
              'reason': 'non-empty string',
            },
          },
      },
    },
  };
}

String get realWorldJudgeSystemPrompt =>
    'You are a blind evaluator for one real-world Liuyao calibration case. '
    'The judgeOnlyReference is hindsight-only and must be used only for '
    'subjective scoring, never treated as evidence available to either '
    'generation. Deterministic hard gates have already been evaluated from '
    'the raw model outputs; do not normalize or repair them. Return exactly '
    'one JSON object matching requiredResponseSchema. Do not infer which label '
    'is the baseline or candidate.';

String get realWorldJudgeRequestContractHash => sha256Json(<String, Object?>{
      'systemPrompt': realWorldJudgeSystemPrompt,
      'temperature': 0,
      'maxTokens': judgeMaxTokens,
      'responseFormat': 'json',
      'seed': judgeSeed,
      'inputUtf8ByteLimit': judgeInputUtf8ByteLimit,
      'requestSchemaVersion': 'liuyao-real-world-judge-request/1.0.0',
      'responseSchemaVersion': realWorldJudgeResponseSchemaVersion,
    });
