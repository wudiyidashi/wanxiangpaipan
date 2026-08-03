import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/classics_representative_contract.dart';
import '../../../tool/liuyao_ai_eval/classics_representative_evaluation.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/hard_gates.dart';
import '../../../tool/liuyao_ai_eval/model_transport.dart';
import '../../../tool/liuyao_ai_eval/runner.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

void main() {
  test('CLI exposes only the fixed three-case representative command shape',
      () {
    const EvalCliParser parser = EvalCliParser();
    final CliInvocation invocation = parser.parse(<String>[
      classicsRepresentativeCommand,
      '--run-id',
      'representative-cli-r1',
      '--output',
      evalOutputRootRelativePath,
      '--repetitions',
      '3',
      '--confirm-real-model',
    ]);
    expect(invocation.command, classicsRepresentativeCommand);
    expect(invocation.repetitions, 3);
    expect(invocation.confirmRealModel, isTrue);

    expect(
      () => parser.parse(<String>[
        classicsRepresentativeCommand,
        '--run-id',
        'representative-cli-r1',
        '--output',
        evalOutputRootRelativePath,
        '--repetitions',
        '3',
        '--case-id',
        classicsRepresentativeCaseIds.first,
        '--confirm-real-model',
      ]),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'unknownOption',
        ),
      ),
    );
    expect(
      () => parser.parse(<String>[
        classicsRepresentativeCommand,
        '--run-id',
        'representative-cli-r1',
        '--variant',
        candidateVariant,
        '--output',
        evalOutputRootRelativePath,
        '--repetitions',
        '3',
        '--confirm-real-model',
      ]),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'commandOptionContractMismatch',
        ),
      ),
    );
    expect(
      () => parser.parse(<String>[
        classicsRepresentativeCommand,
        '--run-id',
        'representative-cli-r1',
        '--output',
        evalOutputRootRelativePath,
        '--repetitions',
        '2',
        '--confirm-real-model',
      ]),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'exactlyThreeRepetitionsRequired',
        ),
      ),
    );
  });

  test('representative runner writes nine pairs without a reveal directory',
      () async {
    final Directory repository = _temporaryRepository();
    addTearDown(() => repository.deleteSync(recursive: true));
    final _SuccessfulTransport transport = _SuccessfulTransport();
    final runner = LiuYaoEvalRunner(
      repositoryRoot: repository.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'representative-test-secret',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://representative.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'representative-test-model',
        'LIUYAO_AI_EVAL_PROVIDER_LABEL': 'representative-test-provider',
      },
      modelTransport: transport,
    );
    final CliResult result = await runner.execute(
      const CliInvocation(
        command: classicsRepresentativeCommand,
        runId: 'representative-three-r1',
        output: evalOutputRootRelativePath,
        repetitions: 3,
        confirmRealModel: true,
      ),
    );

    expect(result.exitCode, 0, reason: result.payload.toString());
    expect(result.payload['pairCount'], 9);
    expect(transport.requests, hasLength(27));
    final Directory outputRoot = Directory(
      p.join(repository.path, evalOutputRootRelativePath),
    );
    expect(Directory(p.join(outputRoot.path, '_holdout_reveals')).existsSync(),
        isFalse);
    final Directory commandDirectory = Directory(p.join(
      outputRoot.path,
      'representative-three-r1',
      classicsRepresentativeCommand,
    ));
    final Map<String, Object?> manifest = decodeObject(
      File(p.join(commandDirectory.path, 'manifest.json')).readAsStringSync(),
    );
    expect(requireString(manifest, 'schemaVersion'),
        classicsRepresentativeRunSchemaVersion);
    expect(
        requireStringList(manifest, 'caseIds'), classicsRepresentativeCaseIds);
    expect(requireInt(manifest, 'repetitions'), 3);
    expect(requireInt(manifest, 'caseCount'), 3);
    expect(requireInt(manifest, 'pairCount'), 9);
    expect(requireStringList(manifest, 'hardGateIds').toSet(), hardGateIds);
    expect(
      requireStringList(manifest, 'rawHardGateIds').toSet(),
      hardGateIds,
    );
    expect(requireBool(manifest, 'candidateHardGatesPassed'), isTrue);
    expect(requireBool(manifest, 'candidateRawHardGatesPassed'), isTrue);
    expect(
      requireBool(manifest, 'candidateReferenceHardGatesPassed'),
      isTrue,
    );
    final Map<String, Object?> identity =
        requireObject(manifest, 'candidateProductionIdentity');
    expect(identity['analysisSchemaVersion'], '2');
    expect(identity['projectionSchemaVersion'], '2');
    expect(identity['ruleSetVersion'], 'v3');
    expect(
      identity['promptPolicyVersion'],
      candidatePromptPolicyVersion,
    );
    final List<Object?> pairs = requireList(manifest, 'pairs');
    expect(
      pairs
          .map((raw) => requireString(
                (raw as Map).cast<String, Object?>(),
                'caseId',
              ))
          .toSet(),
      classicsRepresentativeCaseIds.toSet(),
    );
    for (final Object? raw in pairs) {
      final Map<String, Object?> pair = (raw as Map).cast<String, Object?>();
      final Map<String, Object?> candidate = requireObject(pair, 'candidate');
      final Map<String, Object?> rawGates =
          requireObject(candidate, 'rawHardGates');
      expect(rawGates.keys.toSet(), hardGateIds);
      expect(rawGates.values, everyElement(isTrue));
      final Map<String, Object?> gates = requireObject(candidate, 'hardGates');
      expect(gates.keys.toSet(), hardGateIds);
      expect(gates.values, everyElement(isTrue));
    }
  });

  test('generation failure never reads or parses the judge reference',
      () async {
    final Directory repository = _temporaryRepository();
    addTearDown(() => repository.deleteSync(recursive: true));
    final _GenerationFailureTransport transport = _GenerationFailureTransport();
    final _TrackingRepresentativeAssetLoader loader =
        _TrackingRepresentativeAssetLoader(repository.path);
    final runner = ClassicsRepresentativeEvaluationRunner(
      repositoryRoot: repository.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'representative-test-secret',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://representative.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'representative-test-model',
      },
      modelTransport: transport,
      assetLoader: loader,
    );

    final result = await runner.run(
      runId: 'representative-generation-failure-r1',
      output: evalOutputRootRelativePath,
      repetitions: 3,
    );

    expect(result.exitCode, 5, reason: result.payload.toString());
    expect(result.payload['status'], 'generationFailed');
    expect(transport.requests, hasLength(1));
    expect(loader.referenceManifestReadCount, 1);
    expect(loader.judgeReferenceReadCount, 0);
  });

  test('candidate raw-gate failure skips reference and judge', () async {
    final Directory repository = _temporaryRepository();
    addTearDown(() => repository.deleteSync(recursive: true));
    final _SuccessfulTransport transport = _SuccessfulTransport(
      rejectCandidateRawGate: true,
    );
    final _TrackingRepresentativeAssetLoader loader =
        _TrackingRepresentativeAssetLoader(repository.path);
    final runner = ClassicsRepresentativeEvaluationRunner(
      repositoryRoot: repository.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'representative-test-secret',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://representative.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'representative-test-model',
      },
      modelTransport: transport,
      assetLoader: loader,
    );

    final result = await runner.run(
      runId: 'representative-raw-gate-r1',
      output: evalOutputRootRelativePath,
      repetitions: 3,
    );

    expect(result.exitCode, 6, reason: result.payload.toString());
    expect(result.payload['status'], 'rejected');
    expect(transport.requests, hasLength(2));
    expect(
      transport.requests.every((request) => request.responseFormat == 'text'),
      isTrue,
    );
    expect(loader.referenceManifestReadCount, 1);
    expect(loader.judgeReferenceReadCount, 0);

    final Map<String, Object?> manifest = decodeObject(
      File(p.join(
        repository.path,
        evalOutputRootRelativePath,
        'representative-raw-gate-r1',
        classicsRepresentativeCommand,
        'manifest.json',
      )).readAsStringSync(),
    );
    expect(requireBool(manifest, 'candidateRawHardGatesPassed'), isFalse);
    expect(manifest['candidateReferenceHardGatesPassed'], isNull);
    final Map<String, Object?> pair =
        (requireList(manifest, 'pairs').single as Map<Object?, Object?>)
            .cast<String, Object?>();
    expect(pair['judgeStatus'], 'skippedBeforeReferenceLoad');
  });

  test('pre-existing reveal sibling is neither scanned nor modified', () async {
    final Directory repository = _temporaryRepository();
    addTearDown(() => repository.deleteSync(recursive: true));
    final Directory reveal = Directory(p.join(
      repository.path,
      evalOutputRootRelativePath,
      '_holdout_reveals',
    ))
      ..createSync(recursive: true);
    final File sentinel = File(p.join(reveal.path, 'sentinel.txt'))
      ..writeAsStringSync('representative-test-secret');
    final DateTime modified = sentinel.lastModifiedSync();
    final _TrackingRepresentativeAssetLoader loader =
        _TrackingRepresentativeAssetLoader(repository.path);
    final runner = ClassicsRepresentativeEvaluationRunner(
      repositoryRoot: repository.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'representative-test-secret',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://representative.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'representative-test-model',
      },
      modelTransport: _SuccessfulTransport(),
      assetLoader: loader,
    );
    final result = await runner.run(
      runId: 'representative-sibling-r1',
      output: evalOutputRootRelativePath,
      repetitions: 3,
    );

    expect(result.exitCode, 0, reason: result.payload.toString());
    expect(reveal.listSync().map((item) => p.basename(item.path)).toList(),
        <String>['sentinel.txt']);
    expect(sentinel.readAsStringSync(), 'representative-test-secret');
    expect(sentinel.lastModifiedSync(), modified);
    expect(loader.referenceManifestReadCount, 1);
    expect(loader.judgeReferenceReadCount, 9);
  });
}

Directory _temporaryRepository() {
  final Directory repository =
      Directory.systemTemp.createTempSync('liuyao-representative-');
  File(p.join(repository.path, '.gitignore')).writeAsStringSync(
    '$evalLocalConfigIgnoreRule\n/$evalOutputRootRelativePath/\n',
  );
  final ProcessResult git = Process.runSync(
    'git',
    <String>['init', '--quiet'],
    workingDirectory: repository.path,
    runInShell: Platform.isWindows,
  );
  if (git.exitCode != 0) {
    throw StateError('Failed to create temporary Git repository.');
  }
  Directory(
    p.join(repository.path, evalOutputRootRelativePath),
  ).createSync(recursive: true);
  for (final String relativePath in <String>[
    classicsRepresentativeGenerationRelativePath,
    classicsRepresentativeReferenceRelativePath,
    classicsRepresentativeReferenceManifestRelativePath,
    classicsRepresentativeAdapterRelativePath,
    'tool/liuyao_ai_eval/fixtures/rubric.json',
  ]) {
    final File target = File(p.join(repository.path, relativePath));
    target.parent.createSync(recursive: true);
    File(relativePath).copySync(target.path);
  }
  return repository;
}

class _TrackingRepresentativeAssetLoader
    extends ClassicsRepresentativeAssetLoader {
  _TrackingRepresentativeAssetLoader(super.repositoryRoot);

  int referenceManifestReadCount = 0;
  int judgeReferenceReadCount = 0;

  @override
  ClassicsRepresentativeJudgeReferenceManifest loadJudgeReferenceManifest() {
    referenceManifestReadCount += 1;
    return super.loadJudgeReferenceManifest();
  }

  @override
  ClassicsRepresentativeJudgeReference loadJudgeReference({
    required ClassicsRepresentativeGenerationFixture generationFixture,
    required ClassicsRepresentativeJudgeReferenceManifest manifest,
  }) {
    judgeReferenceReadCount += 1;
    return super.loadJudgeReference(
      generationFixture: generationFixture,
      manifest: manifest,
    );
  }
}

class _GenerationFailureTransport implements EvalModelTransport {
  final List<ModelCallRequest> requests = <ModelCallRequest>[];

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) async {
    requests.add(request);
    return const ModelCallResult(
      completed: false,
      content: null,
      tokensUsed: null,
      latencyMilliseconds: 1,
      seedSupported: true,
      errorKind: 'simulatedGenerationFailure',
      statusCode: 503,
      retryCount: 0,
    );
  }
}

class _SuccessfulTransport implements EvalModelTransport {
  _SuccessfulTransport({this.rejectCandidateRawGate = false});

  final List<ModelCallRequest> requests = <ModelCallRequest>[];
  final bool rejectCandidateRawGate;

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) async {
    requests.add(request);
    if (request.responseFormat == 'text') {
      final Map<String, Object?>? projection =
          _candidateProjection(request.userPrompt);
      return ModelCallResult(
        completed: true,
        content: projection == null
            ? 'representative baseline generation ${requests.length}'
            : rejectCandidateRawGate
                ? 'invalid candidate generation'
                : _validCandidateRawOutput(projection),
        tokensUsed: 32,
        latencyMilliseconds: 1,
        seedSupported: true,
        errorKind: null,
        statusCode: 200,
        retryCount: 0,
      );
    }
    final Map<String, Object?> judgeRequest = decodeObject(request.userPrompt);
    final Map<String, Object?> scoring =
        requireObject(judgeRequest, 'scoringReference');
    final List<String> sourceIds = requireList(scoring, 'allowedSources')
        .map((raw) => requireString(
              (raw as Map).cast<String, Object?>(),
              'sourceId',
            ))
        .toList(growable: false);
    final Map<String, Object?> normalized = <String, Object?>{
      'caseId': requireString(judgeRequest, 'caseId'),
      'verdictTrend': scoring['expectedVerdictTrend'],
      'conditionIds': requireStringList(scoring, 'requiredConditionIds'),
      'panFactIds': requireStringList(scoring, 'allowedPanFactIds'),
      'yongShenActorId': scoring['expectedYongShenActorId'],
      'timingClaims': <Object?>[
        for (final String timingId
            in requireStringList(scoring, 'allowedTimingIds'))
          <String, Object?>{'timingId': timingId, 'guaranteed': false},
      ],
      'sourceIds': sourceIds,
      'citations': <Object?>[],
    };
    final Map<String, Object?> responseSchema =
        requireObject(judgeRequest, 'requiredResponseSchema');
    final Map<String, Object?> scoreSchema =
        requireObject(responseSchema, 'scores');
    return ModelCallResult(
      completed: true,
      content: jsonEncode(<String, Object?>{
        'schemaVersion': evalJudgeResponseSchemaVersion,
        'caseId': requireString(judgeRequest, 'caseId'),
        'repetition': requireInt(judgeRequest, 'repetition'),
        'normalizedOutputs': <String, Object?>{
          'A': normalized,
          'B': normalized,
        },
        'scores': <String, Object?>{
          for (final String dimensionId in scoreSchema.keys)
            dimensionId: <String, Object?>{
              'A': 1,
              'B': 1,
              'reason': 'deterministic test score',
            },
        },
      }),
      tokensUsed: 64,
      latencyMilliseconds: 1,
      seedSupported: true,
      errorKind: null,
      statusCode: 200,
      retryCount: 0,
    );
  }
}

Map<String, Object?>? _candidateProjection(String userPrompt) {
  const String opening = '[LIUYAO_CANONICAL_PROJECTION]';
  const String closing = '[/LIUYAO_CANONICAL_PROJECTION]';
  final int start = userPrompt.indexOf(opening);
  final int end = userPrompt.indexOf(closing);
  if (start < 0 || end <= start) return null;
  final Map<String, Object?> projection = decodeObject(
    userPrompt.substring(start + opening.length, end).trim(),
  );
  return projection['projectionSchemaVersion'] == 2 ? projection : null;
}

String _validCandidateRawOutput(Map<String, Object?> projection) {
  final Map<String, Object?> policy = requireObject(projection, 'policy');
  final String mode = requireString(policy, 'verdictMode');
  final List<Object?> timing = requireList(projection, 'timingCandidates');
  final String timingState = timing.isEmpty ? 'withheld' : 'provided';
  final String marker = '[LIUYAO_DECISION] mode=$mode;'
      'overall=withheld;timing=$timingState';
  final Map<String, Object?> verdict = requireObject(projection, 'verdict');
  final List<String> lines = <String>[
    marker,
    'trend=${requireString(verdict, 'trend')}; '
        'matchedDecisionRowId=${requireString(verdict, 'matchedDecisionRowId')}',
  ];
  final Object? nuance = verdict['nuance'];
  if (nuance is String) lines.add('nuance=$nuance');
  for (final Object? raw in requireList(projection, 'conditions')) {
    final Map<String, Object?> condition =
        (raw as Map<Object?, Object?>).cast<String, Object?>();
    lines.add(requireString(condition, 'label'));
  }
  final Map<String, Object?> selectedRole = requireList(projection, 'roles')
      .map((raw) => (raw as Map<Object?, Object?>).cast<String, Object?>())
      .singleWhere((role) => requireBool(role, 'selected'));
  final Map<String, Object?> actor = selectedRole['actor'] is Map
      ? (selectedRole['actor']! as Map<Object?, Object?>)
          .cast<String, Object?>()
      : selectedRole;
  lines.add('用神 ${requireString(actor, 'actorId')}');
  for (final Object? raw in timing) {
    final Map<String, Object?> candidate =
        (raw as Map<Object?, Object?>).cast<String, Object?>();
    lines.add('${requireString(candidate, 'label')}，不保证结果。');
  }
  final Map<String, Object?> source =
      (requireList(projection, 'sources').first as Map<Object?, Object?>)
          .cast<String, Object?>();
  lines.add('来源 ${requireString(source, 'sourceId')}');
  return lines.join('\n');
}
