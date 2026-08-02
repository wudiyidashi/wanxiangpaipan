import 'dart:convert';

import '../../../tool/liuyao_ai_eval/assets.dart';
import '../../../tool/liuyao_ai_eval/canonical_contract.dart';
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/holdout.dart';
import '../../../tool/liuyao_ai_eval/model_transport.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

class Phase6FixtureBundle {
  const Phase6FixtureBundle({
    required this.fixture,
    required this.rubric,
    required this.adapter,
    required this.holdout,
  });

  final EvalFixture fixture;
  final EvalRubric rubric;
  final CanonicalEvalAdapter adapter;
  final HoldoutSelection holdout;
}

Phase6FixtureBundle buildPhase6FixtureBundle(String repositoryRoot) {
  final EvalRubric rubric = EvalAssets(repositoryRoot).loadRubric();
  final List<String> originalIds = List<String>.generate(
    7,
    (int index) => 'phase6.original.${index + 1}',
  );
  final HoldoutSelection holdout = selectHoldout(originalIds);
  final Set<String> holdoutIds =
      holdout.members.map((HoldoutMember member) => member.caseId).toSet();
  final List<String> allIds = <String>[
    ...originalIds,
    'phase6.rule.1',
  ]..sort();
  final List<EvalCase> cases = <EvalCase>[
    for (final String caseId in allIds)
      _evalCase(
        caseId,
        caseId.startsWith('phase6.original.')
            ? 'originalBook'
            : 'ruleValidation',
        holdoutIds.contains(caseId) ? 'holdout' : 'calibration',
      ),
  ];
  final EvalFixture fixture = EvalFixture(
    fixtureVersion: evalFixtureVersion,
    rubricVersion: evalRubricVersion,
    projectionSchemaVersion: canonicalProjectionSchemaVersion,
    requestSchemaVersion: evalRequestSchemaVersion,
    cases: List<EvalCase>.unmodifiable(cases),
    hash: sha256Json(<String, Object?>{
      'schemaVersion': evalFixtureVersion,
      'caseIds': allIds,
      'projectionSchemaVersion': canonicalProjectionSchemaVersion,
    }),
    sourceFixtureVersion: 'phase6-synthetic/1',
    sourceFixtureHash: sha256Text('phase6-synthetic-source'),
  );
  final Map<String, Object?> adapterJson = <String, Object?>{
    'schemaVersion': evalCanonicalAdapterSchemaVersion,
    'fixtureHash': fixture.hash,
    'rubricHash': rubric.hash,
    'projectionSchemaVersion': canonicalProjectionSchemaVersion,
    'ruleSetId': canonicalRuleSetId,
    'ruleSetVersion': canonicalRuleSetVersion,
    'requestParameters': const GenerationRequestParameters().toJson(),
    'cases': <Object?>[
      for (final EvalCase evalCase in cases)
        <String, Object?>{
          'caseId': evalCase.caseId,
          'caseInputHash': sha256Json(evalCase.requestInput),
          'projectionHash': sha256Json(
            requireObject(evalCase.requestInput, 'projection'),
          ),
          'variants': <String, Object?>{
            baselineVariant: <String, Object?>{
              'systemTemplateId': 'builtin_liuyao_system',
              'analysisTemplateId': 'builtin_liuyao_analysis',
              'promptPolicyVersion': 'legacy-frozen',
              'systemPrompt': '$baselineVariant system ${evalCase.caseId}',
              'userPrompt': '$baselineVariant user ${evalCase.caseId}',
            },
            candidateVariant: <String, Object?>{
              'systemTemplateId': 'builtin_liuyao_system',
              'analysisTemplateId': 'builtin_liuyao_analysis',
              'promptPolicyVersion': 'liuyao-ai-policy/1.0.0',
              'systemPrompt': '$candidateVariant system ${evalCase.caseId}',
              'userPrompt': '$candidateVariant user ${evalCase.caseId}',
            },
          },
        },
    ],
    'sourceFixtureVersion': fixture.sourceFixtureVersion,
    'sourceFixtureHash': fixture.sourceFixtureHash,
  };
  return Phase6FixtureBundle(
    fixture: fixture,
    rubric: rubric,
    adapter: CanonicalEvalAdapter.fromJson(
      adapterJson,
      fixture: fixture,
      rubric: rubric,
    ),
    holdout: holdout,
  );
}

class Phase6EvalAssets extends EvalAssets {
  Phase6EvalAssets({
    required String repositoryRoot,
    required this.fixture,
    required this.rubric,
  }) : super(repositoryRoot);

  final EvalFixture fixture;
  final EvalRubric rubric;

  @override
  EvalFixture loadFixture() => fixture;

  @override
  EvalFixture loadCanonicalFixture() => fixture;

  @override
  EvalRubric loadRubric() => rubric;
}

class SuccessfulPairedTransport implements EvalModelTransport {
  final List<ModelCallRequest> requests = <ModelCallRequest>[];
  String? model;

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) async {
    model ??= credentials.model;
    if (credentials.model != model) {
      throw StateError('Generation and judge model diverged.');
    }
    requests.add(request);
    if (request.responseFormat == 'text') {
      if (request.seed != generationSeed ||
          request.temperature != 0 ||
          request.maxTokens != generationMaxTokens) {
        throw StateError('Generation request parameters changed.');
      }
      final String variant = request.systemPrompt.contains(candidateVariant)
          ? candidateVariant
          : baselineVariant;
      return _completed('$variant response');
    }
    if (request.responseFormat != 'json' ||
        request.seed != judgeSeed ||
        request.temperature != 0 ||
        request.maxTokens != judgeMaxTokens) {
      throw StateError('Judge request parameters changed.');
    }
    final Map<String, Object?> judgeRequest = decodeObject(request.userPrompt);
    final String caseId = requireString(judgeRequest, 'caseId');
    final int repetition = requireInt(judgeRequest, 'repetition');
    final ScoringReference reference = ScoringReference.fromJson(
      requireObject(judgeRequest, 'scoringReference'),
    );
    final Map<String, Object?> blindOutputs =
        requireObject(judgeRequest, 'blindOutputs');
    final String candidateLabel = <String>['A', 'B'].singleWhere(
      (String label) =>
          requireString(blindOutputs, label).contains(candidateVariant),
    );
    final Map<String, Object?> rubric = requireObject(judgeRequest, 'rubric');
    final List<String> dimensionIds = requireList(rubric, 'dimensions')
        .map(
          (Object? value) => requireString(
            (value as Map).cast<String, Object?>(),
            'dimensionId',
          ),
        )
        .toList(growable: false);
    final Map<String, Object?> normalized = <String, Object?>{
      'caseId': caseId,
      'verdictTrend': reference.expectedVerdictTrend,
      'conditionIds': reference.requiredConditionIds.toList()..sort(),
      'panFactIds': reference.allowedPanFactIds.toList()..sort(),
      'yongShenActorId': reference.expectedYongShenActorId,
      'timingClaims': <Object?>[
        for (final String timingId
            in (reference.allowedTimingIds.toList()..sort()))
          <String, Object?>{
            'timingId': timingId,
            'guaranteed': false,
          },
      ],
      'sourceIds': reference.allowedSources.keys.toList()..sort(),
      'citations': <Object?>[],
    };
    return _completed(jsonEncode(<String, Object?>{
      'schemaVersion': evalJudgeResponseSchemaVersion,
      'caseId': caseId,
      'repetition': repetition,
      'normalizedOutputs': <String, Object?>{
        'A': normalized,
        'B': normalized,
      },
      'scores': <String, Object?>{
        for (final String dimensionId in dimensionIds)
          dimensionId: <String, Object?>{
            'A': candidateLabel == 'A' ? 2 : 1,
            'B': candidateLabel == 'B' ? 2 : 1,
            'reason': 'candidate explains the supplied evidence better',
          },
      },
    }));
  }

  ModelCallResult _completed(String content) => ModelCallResult(
        completed: true,
        content: content,
        tokensUsed: 10,
        latencyMilliseconds: 1,
        seedSupported: true,
        errorKind: null,
        statusCode: 200,
        retryCount: 0,
      );
}

EvalCase _evalCase(String caseId, String caseKind, String evaluationSplit) {
  final String factId = 'pan:$caseId';
  final String conditionId = 'condition:$caseId';
  final String timingId = 'timing:$caseId';
  const AllowedSource source = AllowedSource(
    sourceId: 'liuyao.source.project.analysis-contract',
    locators: <String>{'analysis-contract-v1'},
    exactQuotes: <String>{},
  );
  final ScoringReference reference = ScoringReference(
    expectedVerdictTrend: 'daiTiaoJian',
    requiredConditionIds: <String>{conditionId},
    allowedPanFactIds: <String>{factId},
    expectedYongShenActorId: 'main:yao:1',
    allowedTimingIds: <String>{timingId},
    allowedSources: const <String, AllowedSource>{
      'liuyao.source.project.analysis-contract': source,
    },
  );
  return EvalCase(
    caseId: caseId,
    caseKind: caseKind,
    evaluationSplit: evaluationSplit,
    cohortIds: <String>{'overall', caseKind, evaluationSplit},
    requestInput: <String, Object?>{
      'question': 'Question for $caseId',
      'projection': <String, Object?>{
        'panFactIds': <String>[factId],
        'yongShenActorId': 'main:yao:1',
        'verdictTrend': 'daiTiaoJian',
        'conditions': <Object?>[
          <String, Object?>{
            'conditionId': conditionId,
            'hasRescue': true,
          },
        ],
        'timingCandidates': <Object?>[
          <String, Object?>{
            'timingId': timingId,
            'triggerValue': 'zi',
          },
        ],
        'sources': <Object?>[source.toJson()],
      },
    },
    scoringReference: reference,
  );
}
