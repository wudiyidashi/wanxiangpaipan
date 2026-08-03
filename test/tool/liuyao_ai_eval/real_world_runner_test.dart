import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/model_transport.dart';
import '../../../tool/liuyao_ai_eval/real_world_contract.dart';
import '../../../tool/liuyao_ai_eval/real_world_evaluation.dart';
import '../../../tool/liuyao_ai_eval/runner.dart';
import '../../../tool/liuyao_ai_eval/security.dart';
import 'eval_filesystem_test_lock.dart';

void main() {
  late String repositoryRoot;
  late EvalFilesystemTestLock filesystemLock;

  setUpAll(() async {
    repositoryRoot = Directory.current.path;
    filesystemLock = EvalFilesystemTestLock();
    await filesystemLock.acquire(repositoryRoot);
  });

  tearDownAll(() => filesystemLock.release());

  test('validate command loads every frozen real-world asset', () async {
    final runner = LiuYaoEvalRunner(
      repositoryRoot: repositoryRoot,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'real-world-validate-secret',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://real-world.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'real-world-test-model',
      },
    );
    final result = await runner.execute(
      const CliInvocation(command: 'validate', runId: 'real-world-validate'),
    );

    expect(result.exitCode, 0, reason: result.payload.toString());
    expect(result.payload['realWorldStatus'], 'ready');
    for (final key in <String>[
      'realWorldGenerationFixtureHash',
      'realWorldAdapterHash',
      'realWorldJudgeReferenceHash',
      'realWorldJudgeReferenceAssetHash',
    ]) {
      expect(result.payload[key], matches(RegExp(r'^[0-9a-f]{64}$')));
    }
  });

  test('judge reference freezes scenario and scoring identities', () {
    Map<String, Object?> source() => decodeObject(
          File(p.join(
            repositoryRoot,
            realWorldJudgeReferenceRelativePath,
          )).readAsStringSync(),
        );

    final scoreDrift = source();
    scoreDrift['scoreDimensions'] = <String>[
      ...realWorldScoreDimensionIds.reversed,
    ];
    expect(
      () => RealWorldJudgeReference.fromJson(scoreDrift),
      throwsA(isA<FormatException>()),
    );

    final scenarioDrift = source();
    final lifecycleByScenario = Map<String, Object?>.from(
      requireObject(scenarioDrift, 'expectedLifecycleByScenario'),
    )..remove('unselected');
    scenarioDrift['expectedLifecycleByScenario'] = lifecycleByScenario;
    expect(
      () => RealWorldJudgeReference.fromJson(scenarioDrift),
      throwsA(isA<FormatException>()),
    );

    final lifecycleDrift = source();
    final lifecycle = Map<String, Object?>.from(
      requireObject(
        requireObject(lifecycleDrift, 'expectedLifecycleByScenario'),
        'selected-main-1',
      ),
    )..['quality'] = 'favorable';
    lifecycleDrift['expectedLifecycleByScenario'] = <String, Object?>{
      'unselected': null,
      'selected-main-1': lifecycle,
    };
    expect(
      () => RealWorldJudgeReference.fromJson(lifecycleDrift),
      throwsA(isA<FormatException>()),
    );
  });

  test('judge reference manifest is non-sensitive and binds exact asset', () {
    final String manifestSource = File(p.join(
      repositoryRoot,
      realWorldJudgeReferenceManifestRelativePath,
    )).readAsStringSync();
    final Map<String, Object?> manifestJson = decodeObject(manifestSource);
    expect(manifestJson.keys.toSet(), <String>{
      'schemaVersion',
      'caseId',
      'referenceAssetSha256',
    });
    for (final marker in <String>[
      'actualOutcome',
      'retrospectiveMappings',
      '二房东',
      '三千',
    ]) {
      expect(manifestSource, isNot(contains(marker)));
    }

    final loader = RealWorldAssetLoader(repositoryRoot);
    final manifest = loader.loadJudgeReferenceManifest();
    final reference = loader.loadJudgeReference(manifest: manifest);
    expect(reference.caseId, manifest.caseId);

    final driftedManifest = RealWorldJudgeReferenceManifest.fromJson(
      <String, Object?>{
        ...manifestJson,
        'referenceAssetSha256': '0' * 64,
      },
    );
    expect(
      () => loader.loadJudgeReference(manifest: driftedManifest),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'realWorldReferenceAssetDrift',
        ),
      ),
    );
  });

  test('real-world retry identity binds the opaque judge reference asset', () {
    final loader = RealWorldAssetLoader(repositoryRoot);
    final fixture = loader.loadGenerationFixture();
    final adapter = loader.loadAdapter(fixture);
    String identity(String referenceHash) => realWorldRunIdentityHash(
          runId: 'real-world-reference-identity',
          fixture: fixture,
          adapter: adapter,
          modelHash: 'model-hash',
          transportEndpointHash: 'endpoint-hash',
          transportTimeoutSeconds: defaultTransportTimeoutSeconds,
          judgeReferenceAssetHash: referenceHash,
        );

    expect(identity('a' * 64), isNot(identity('b' * 64)));
  });

  test('real-world runner completes six blind pairs on numbered retry',
      () async {
    const String runId = 'real-world-fake-transport-r1';
    final Directory runDirectory = Directory(
      p.join(repositoryRoot, evalOutputRootRelativePath, runId),
    );
    _cleanRunDirectory(runDirectory);
    addTearDown(() => _cleanRunDirectory(runDirectory));

    final _RealWorldTransport transport = _RealWorldTransport();
    final LiuYaoEvalRunner runner = LiuYaoEvalRunner(
      repositoryRoot: repositoryRoot,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'real-world-test-secret-value',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://real-world.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'real-world-test-model',
        'LIUYAO_AI_EVAL_PROVIDER_LABEL': 'real-world-test-provider',
      },
      modelTransport: transport,
    );
    const CliInvocation invocation = CliInvocation(
      command: 'real-world-paired-model',
      runId: runId,
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    );

    final CliResult failed = await runner.execute(invocation);
    expect(failed.exitCode, 5, reason: failed.payload.toString());
    expect(
      File(p.join(
        runDirectory.path,
        'real-world-paired-model',
        '_BLOCKED',
      )).existsSync(),
      isTrue,
    );
    final Map<String, Object?> failedStatus = decodeObject(
      File(p.join(
        runDirectory.path,
        'real-world-paired-model',
        'status.json',
      )).readAsStringSync(),
    );
    expect(failedStatus.keys.toSet(), <String>{
      'schemaVersion',
      'runId',
      'status',
      'realModelStatus',
      'errorKind',
      'scenarioId',
      'repetition',
      'failedVariant',
      'failedRequestHash',
      'failedTransportRequestHash',
      'statusCode',
      'retryCount',
      'latencyMilliseconds',
      'seedSupported',
      'adapterHash',
      'judgeReferenceAssetHash',
      'transportTimeoutSeconds',
      'transportRetryPolicyVersion',
    });
    expect(
      requireString(failedStatus, 'schemaVersion'),
      realWorldRunSchemaVersion,
    );
    expect(
      requireString(failedStatus, 'transportRetryPolicyVersion'),
      transportRetryPolicyVersion,
    );
    expect(requireString(failedStatus, 'failedVariant'), isNotEmpty);
    expect(
      requireString(failedStatus, 'failedRequestHash'),
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
    expect(
      requireString(failedStatus, 'failedTransportRequestHash'),
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
    expect(requireInt(failedStatus, 'statusCode'), 503);
    expect(
      requireInt(failedStatus, 'retryCount'),
      transportMaxRetryCount,
    );
    expect(requireInt(failedStatus, 'latencyMilliseconds'), 1);
    expect(failedStatus['seedSupported'], isTrue);

    final driftedRunner = LiuYaoEvalRunner(
      repositoryRoot: repositoryRoot,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'real-world-test-secret-value',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://real-world.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'real-world-test-model',
        'LIUYAO_AI_EVAL_PROVIDER_LABEL': 'real-world-test-provider',
        'LIUYAO_AI_EVAL_TIMEOUT_SECONDS': '241',
      },
      modelTransport: transport,
    );
    final CliResult drifted = await driftedRunner.execute(invocation);
    expect(drifted.exitCode, 2, reason: drifted.payload.toString());
    expect(drifted.payload['errorKind'], 'retryIdentityMismatch');
    expect(transport.requests, hasLength(1));

    final CliResult completed = await runner.execute(invocation);
    expect(completed.exitCode, 0, reason: completed.payload.toString());
    expect(completed.payload['pairCount'], 6);

    final Directory retryDirectory = Directory(
      p.join(runDirectory.path, 'real-world-paired-model-2'),
    );
    expect(File(p.join(retryDirectory.path, '_SUCCESS')).existsSync(), isTrue);
    final Map<String, Object?> manifest = decodeObject(
      File(p.join(retryDirectory.path, 'manifest.json')).readAsStringSync(),
    );
    expect(manifest.keys.toSet(), <String>{
      'schemaVersion',
      'runId',
      'runHash',
      'status',
      'generationFixtureHash',
      'adapterHash',
      'baselineSourceCommit',
      'requestParameters',
      'requestParametersHash',
      'judgeRequestContractHash',
      'judgeReferenceAssetHash',
      'transportEndpointHash',
      'transportRetryPolicyVersion',
      'modelMetadata',
      'repetitions',
      'scenarioCount',
      'pairCount',
      'candidateHardGatesPassed',
      'pairs',
    });
    expect(
      requireString(manifest, 'schemaVersion'),
      realWorldRunSchemaVersion,
    );
    expect(
      requireString(manifest, 'transportRetryPolicyVersion'),
      transportRetryPolicyVersion,
    );
    expect(requireInt(manifest, 'scenarioCount'), 2);
    expect(requireInt(manifest, 'pairCount'), 6);
    expect(requireList(manifest, 'pairs'), hasLength(6));
    expect(
      requireString(manifest, 'runHash'),
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
    for (final String key in <String>[
      'requestParametersHash',
      'judgeRequestContractHash',
      'judgeReferenceAssetHash',
      'transportEndpointHash',
    ]) {
      expect(
        requireString(manifest, key),
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
    }
    final firstPair =
        (requireList(manifest, 'pairs').first as Map).cast<String, Object?>();
    for (final variant in <String>['baseline', 'candidate']) {
      final variantResult = requireObject(firstPair, variant);
      final generation = requireObject(variantResult, 'generation');
      expect(
        requireString(generation, 'transportRequestHash'),
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(
        requireObject(variantResult, 'hardGateDiagnostics').values,
        everyElement(isA<bool>()),
      );
    }

    final List<ModelCallRequest> retryRequests =
        transport.requests.skip(1).toList(growable: false);
    expect(retryRequests, hasLength(18));
    for (int offset = 0; offset < retryRequests.length; offset += 3) {
      expect(
        retryRequests
            .skip(offset)
            .take(3)
            .map((request) => request.responseFormat),
        <String>['text', 'text', 'json'],
      );
    }
    expect(transport.judgeRequests, hasLength(6));
    for (final Map<String, Object?> judgeRequest in transport.judgeRequests) {
      _expectExactJudgeSchema(judgeRequest);
    }
  });

  test('candidate raw-gate failure rejects before any judge request', () async {
    const String runId = 'real-world-raw-gate-r1';
    final Directory runDirectory = Directory(
      p.join(repositoryRoot, evalOutputRootRelativePath, runId),
    );
    _cleanRunDirectory(runDirectory);
    addTearDown(() => _cleanRunDirectory(runDirectory));

    final transport = _RealWorldTransport(
      failFirstTransport: false,
      rejectCandidateRawGate: true,
    );
    final assetLoader = _TrackingRealWorldAssetLoader(repositoryRoot);
    final runner = LiuYaoEvalRunner(
      repositoryRoot: repositoryRoot,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'real-world-test-secret-value',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://real-world.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'real-world-test-model',
        'LIUYAO_AI_EVAL_PROVIDER_LABEL': 'real-world-test-provider',
      },
      modelTransport: transport,
      realWorldAssetLoaderProvider: (_) => assetLoader,
    );
    const invocation = CliInvocation(
      command: 'real-world-paired-model',
      runId: runId,
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    );

    final result = await runner.execute(invocation);
    expect(result.exitCode, 6, reason: result.payload.toString());
    expect(result.payload['status'], 'rejected');
    expect(transport.requests, hasLength(2));
    expect(
      transport.requests.every((request) => request.responseFormat == 'text'),
      isTrue,
    );
    expect(transport.judgeRequests, isEmpty);
    expect(assetLoader.judgeReferenceReadCount, 0);
    expect(
      File(p.join(
        runDirectory.path,
        'real-world-paired-model',
        '_FAILED',
      )).existsSync(),
      isTrue,
    );
  });
}

class _TrackingRealWorldAssetLoader extends RealWorldAssetLoader {
  _TrackingRealWorldAssetLoader(String repositoryRoot) : super(repositoryRoot);

  int judgeReferenceReadCount = 0;

  @override
  RealWorldJudgeReference loadJudgeReference({
    required RealWorldJudgeReferenceManifest manifest,
  }) {
    judgeReferenceReadCount += 1;
    return super.loadJudgeReference(manifest: manifest);
  }
}

void _cleanRunDirectory(Directory directory) {
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}

void _expectExactJudgeSchema(Map<String, Object?> judgeRequest) {
  final Map<String, Object?> schema =
      requireObject(judgeRequest, 'requiredResponseSchema');
  expect(requireStringList(schema, 'exactTopLevelKeys'), <String>[
    'schemaVersion',
    'caseId',
    'scenarioId',
    'repetition',
    'scores',
  ]);
  final blindOutputs = requireObject(judgeRequest, 'blindOutputs');
  for (final output in blindOutputs.values) {
    expect((output as Map).keys.toSet(), <String>{'modelOutput'});
  }
  final Map<String, Object?> scores = requireObject(schema, 'scores');
  expect(scores, isNotEmpty);
  for (final Object? score in scores.values) {
    final Map<String, Object?> scoreSchema =
        (score! as Map).cast<String, Object?>();
    expect(
      requireStringList(scoreSchema, 'exactKeys'),
      <String>['A', 'B', 'reason'],
    );
  }
}

class _RealWorldTransport implements EvalModelTransport {
  _RealWorldTransport({
    this.failFirstTransport = true,
    this.rejectCandidateRawGate = false,
  }) : _failedOnce = !failFirstTransport;

  final List<ModelCallRequest> requests = <ModelCallRequest>[];
  final List<Map<String, Object?>> judgeRequests = <Map<String, Object?>>[];
  final bool failFirstTransport;
  final bool rejectCandidateRawGate;
  bool _failedOnce;

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) async {
    requests.add(request);
    if (request.responseFormat == 'text') {
      const forbiddenReferenceMarkers = <String>[
        'actualOutcome',
        'retrospectiveMappings',
        '二房东',
        '三千',
      ];
      final String generationInput =
          '${request.systemPrompt}\n${request.userPrompt}';
      if (forbiddenReferenceMarkers.any(generationInput.contains)) {
        throw StateError('Judge-only reference leaked into generation.');
      }
      if (!_failedOnce) {
        _failedOnce = true;
        return const ModelCallResult(
          completed: false,
          content: null,
          tokensUsed: null,
          latencyMilliseconds: 1,
          seedSupported: true,
          errorKind: 'simulatedTransportFailure',
          statusCode: 503,
          retryCount: transportMaxRetryCount,
        );
      }
      final bool candidate = generationInput.contains(
        '"projectionSchemaVersion":2',
      );
      if (rejectCandidateRawGate && candidate) {
        return _completed('blind generation output');
      }
      final bool unselected = generationInput.contains('"mode":"unselected"');
      return _completed(unselected ? _unselectedOutput : _selectedOutput);
    }
    if (request.responseFormat != 'json' ||
        request.systemPrompt != realWorldJudgeSystemPrompt) {
      throw StateError('Unexpected real-world judge request.');
    }
    final Map<String, Object?> judgeRequest = decodeObject(request.userPrompt);
    judgeRequests.add(judgeRequest);
    final String caseId = requireString(judgeRequest, 'caseId');
    final String scenarioId = requireString(judgeRequest, 'scenarioId');
    final int repetition = requireInt(judgeRequest, 'repetition');
    final List<String> dimensions = requireStringList(
      requireObject(judgeRequest, 'judgeOnlyReference'),
      'scoreDimensions',
    );
    return _completed(jsonEncode(<String, Object?>{
      'schemaVersion': realWorldJudgeResponseSchemaVersion,
      'caseId': caseId,
      'scenarioId': scenarioId,
      'repetition': repetition,
      'scores': <String, Object?>{
        for (final String dimension in dimensions)
          dimension: <String, Object?>{
            'A': 2,
            'B': 2,
            'reason': 'Both outputs satisfy the synthetic contract.',
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

const String _unselectedOutput = '''
[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
verdictMode=abstain。当前未选定用神，不能作总体成败、最终吉凶或顺利程度判断。
这里只列候选用神与核验维度，不提供应期。
''';

const String _selectedOutput = '''
[LIUYAO_DECISION] mode=explainLifecycle;overall=lifecycle;timing=withheld
formation: willForm
quality: adverse
continuity: unstable
persistence: entangled
事必成，成而受困；合非吉兆，是套。
main:yao:3 在 earlyProcess 对 main:yao:1 的克制已发生；changed:yao:3 在 laterProcess 限制 main:yao:3，不能倒推前段无作用。
出租权、合同主体与权属需要核验；收费与费用存在暴露；房屋交付占有与入住、完整租期能否持续履约要分别判断。
六合不能单独决定总体结果。假空按动不为空理解，不等于收费不存在。
''';
