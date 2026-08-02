import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/model_transport.dart';
import '../../../tool/liuyao_ai_eval/runner.dart';
import '../../../tool/liuyao_ai_eval/security.dart';
import 'eval_filesystem_test_lock.dart';
import 'phase6_test_support.dart';

void main() {
  late String repositoryRoot;
  late Phase6FixtureBundle bundle;
  late EvalFilesystemTestLock filesystemLock;

  setUpAll(() async {
    repositoryRoot = Directory.current.path;
    filesystemLock = EvalFilesystemTestLock();
    await filesystemLock.acquire(repositoryRoot);
    bundle = buildPhase6FixtureBundle(repositoryRoot);
  });

  tearDownAll(() => filesystemLock.release());

  test('CLI exposes the exact Phase 6 command contracts', () {
    const EvalCliParser parser = EvalCliParser();
    expect(
      parser.parse(<String>[
        'compare-offline',
        '--run-id',
        'phase6-parser-r1',
        '--output',
        evalOutputRootRelativePath,
      ]).command,
      'compare-offline',
    );
    expect(
      parser.parse(<String>[
        'paired-model',
        '--run-id',
        'phase6-parser-r1',
        '--output',
        evalOutputRootRelativePath,
        '--repetitions',
        '3',
        '--confirm-real-model',
      ]).repetitions,
      3,
    );
    expect(
      parser.parse(<String>[
        'compare',
        '--run-id',
        'phase6-parser-r1',
        '--output',
        evalOutputRootRelativePath,
      ]).command,
      'compare',
    );
    expect(
      () => parser.parse(<String>[
        'paired-model',
        '--run-id',
        'phase6-parser-r1',
        '--output',
        evalOutputRootRelativePath,
        '--repetitions',
        '4',
        '--confirm-real-model',
      ]),
      throwsA(isA<Exception>()),
    );
  });

  test('model input preflight counts UTF-8 bytes and fails closed', () {
    expect(
      () => validateModelInputUtf8Size(
        systemPrompt: '中',
        userPrompt: 'a',
        byteLimit: 4,
        errorKind: 'inputTooLarge',
      ),
      returnsNormally,
    );
    expect(
      () => validateModelInputUtf8Size(
        systemPrompt: '中',
        userPrompt: 'a',
        byteLimit: 3,
        errorKind: 'inputTooLarge',
      ),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'inputTooLarge',
        ),
      ),
    );
  });

  test('Phase 6 CLI completes 24 strict pairs and comparison', () async {
    const String runId = 'phase6-e2e-complete';
    _cleanRun(repositoryRoot, bundle, runId);
    addTearDown(() => _cleanRun(repositoryRoot, bundle, runId));
    final SuccessfulPairedTransport transport = SuccessfulPairedTransport();
    final LiuYaoEvalRunner runner = _runner(
      repositoryRoot,
      bundle,
      transport,
    );

    await _preparePair(runner, runId);
    final CliResult offline = await runner.execute(const CliInvocation(
      command: 'compare-offline',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));
    expect(offline.exitCode, 0, reason: offline.payload.toString());

    final CliResult paired = await runner.execute(const CliInvocation(
      command: 'paired-model',
      runId: runId,
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    ));
    expect(paired.exitCode, 0, reason: paired.payload.toString());
    expect(paired.payload['pairCount'], 24);

    final CliResult compared = await runner.execute(const CliInvocation(
      command: 'compare',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));
    expect(compared.exitCode, 0, reason: compared.payload.toString());
    expect(compared.payload['status'], 'passed');
    expect(
      compared.payload['repeatableImprovementDimensions'],
      contains('evidenceCoverage'),
    );
    expect(
      transport.requests.where(
          (ModelCallRequest request) => request.responseFormat == 'text'),
      hasLength(48),
    );
    expect(
      transport.requests.where(
          (ModelCallRequest request) => request.responseFormat == 'json'),
      hasLength(24),
    );
    final Directory runDirectory = _runDirectory(repositoryRoot, runId);
    expect(
      File(p.join(runDirectory.path, 'paired-model', '_SUCCESS')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(runDirectory.path, 'compare', '_SUCCESS')).existsSync(),
      isTrue,
    );
  });

  test('same frozen candidate resumes after a post-reveal transport failure',
      () async {
    const String runId = 'phase6-e2e-resume';
    _cleanRun(repositoryRoot, bundle, runId);
    addTearDown(() => _cleanRun(repositoryRoot, bundle, runId));
    final int calibrationCases = bundle.fixture.cases
        .where((evalCase) => evalCase.evaluationSplit != 'holdout')
        .length;
    final _FailOnceAfterCalibrationTransport transport =
        _FailOnceAfterCalibrationTransport(
      failOnTextCall: calibrationCases * 6 + 1,
    );
    final LiuYaoEvalRunner runner = _runner(
      repositoryRoot,
      bundle,
      transport,
    );

    await _preparePair(runner, runId);
    expect(
      (await runner.execute(const CliInvocation(
        command: 'compare-offline',
        runId: runId,
        output: evalOutputRootRelativePath,
      )))
          .exitCode,
      0,
    );
    final CliResult failed = await runner.execute(const CliInvocation(
      command: 'paired-model',
      runId: runId,
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    ));
    expect(failed.exitCode, 5);
    expect(_revealMarker(repositoryRoot, bundle).existsSync(), isTrue);

    final CliResult resumed = await runner.execute(const CliInvocation(
      command: 'paired-model',
      runId: runId,
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    ));
    expect(resumed.exitCode, 0, reason: resumed.payload.toString());
    expect(
      File(p.join(
        _runDirectory(repositoryRoot, runId).path,
        'paired-model-2',
        '_SUCCESS',
      )).existsSync(),
      isTrue,
    );

    final CliResult compared = await runner.execute(const CliInvocation(
      command: 'compare',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));
    expect(compared.exitCode, 0, reason: compared.payload.toString());
  });

  test('paired model fails closed on a malformed judge response', () async {
    const String runId = 'phase6-e2e-malformed';
    _cleanRun(repositoryRoot, bundle, runId);
    addTearDown(() => _cleanRun(repositoryRoot, bundle, runId));
    final LiuYaoEvalRunner runner = _runner(
      repositoryRoot,
      bundle,
      _MalformedJudgeTransport(),
    );

    await _preparePair(runner, runId);
    final CliResult offline = await runner.execute(const CliInvocation(
      command: 'compare-offline',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));
    expect(offline.exitCode, 0, reason: offline.payload.toString());
    final CliResult paired = await runner.execute(const CliInvocation(
      command: 'paired-model',
      runId: runId,
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    ));

    expect(paired.exitCode, 6);
    expect(paired.payload['status'], 'malformedJudgeResult');
    final Directory pairedDirectory = Directory(p.join(
      _runDirectory(repositoryRoot, runId).path,
      'paired-model',
    ));
    expect(File(p.join(pairedDirectory.path, '_BLOCKED')).existsSync(), isTrue);
    expect(
      File(p.join(pairedDirectory.path, 'paired_results.json')).existsSync(),
      isFalse,
    );
    expect(_revealMarker(repositoryRoot, bundle).existsSync(), isFalse);
  });

  test('compare-offline rejects missing prepared artifacts', () async {
    const String runId = 'phase6-e2e-missing';
    _cleanRun(repositoryRoot, bundle, runId);
    addTearDown(() => _cleanRun(repositoryRoot, bundle, runId));
    final LiuYaoEvalRunner runner = _runner(
      repositoryRoot,
      bundle,
      SuccessfulPairedTransport(),
    );

    final CliResult result = await runner.execute(const CliInvocation(
      command: 'compare-offline',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));

    expect(result.exitCode, 2);
    expect(result.payload['errorKind'], 'requiredArtifactMissingOrInvalid');
  });

  test('compare-offline rejects a tampered prepared hash', () async {
    const String runId = 'phase6-e2e-tampered';
    _cleanRun(repositoryRoot, bundle, runId);
    addTearDown(() => _cleanRun(repositoryRoot, bundle, runId));
    final LiuYaoEvalRunner runner = _runner(
      repositoryRoot,
      bundle,
      SuccessfulPairedTransport(),
    );
    await _preparePair(runner, runId);
    final File baselineArtifact = File(p.join(
      _runDirectory(repositoryRoot, runId).path,
      'prepare-$baselineVariant',
      'request_set.json',
    ));
    final Map<String, Object?> json =
        decodeObject(baselineArtifact.readAsStringSync());
    json['projectionSetHash'] = sha256Text('tampered-projection-set');
    baselineArtifact.writeAsStringSync(
      '${canonicalJson(json)}\n',
      flush: true,
    );

    final CliResult result = await runner.execute(const CliInvocation(
      command: 'compare-offline',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));

    expect(result.exitCode, 2);
    expect(result.payload['errorKind'], 'invalidEvaluatorAsset');
  });

  test('compare rejects a tampered judge score artifact', () async {
    const String runId = 'phase6-e2e-tampered-judge';
    _cleanRun(repositoryRoot, bundle, runId);
    addTearDown(() => _cleanRun(repositoryRoot, bundle, runId));
    final LiuYaoEvalRunner runner = _runner(
      repositoryRoot,
      bundle,
      SuccessfulPairedTransport(),
    );
    await _preparePair(runner, runId);
    expect(
      (await runner.execute(const CliInvocation(
        command: 'compare-offline',
        runId: runId,
        output: evalOutputRootRelativePath,
      )))
          .exitCode,
      0,
    );
    expect(
      (await runner.execute(const CliInvocation(
        command: 'paired-model',
        runId: runId,
        output: evalOutputRootRelativePath,
        repetitions: 3,
        confirmRealModel: true,
      )))
          .exitCode,
      0,
    );
    final File pairedArtifact = File(p.join(
      _runDirectory(repositoryRoot, runId).path,
      'paired-model',
      'paired_results.json',
    ));
    final Map<String, Object?> json =
        decodeObject(pairedArtifact.readAsStringSync());
    final Map<String, Object?> firstPair =
        (requireList(json, 'pairs').first! as Map).cast<String, Object?>();
    final Map<String, Object?> scores = requireObject(firstPair, 'scores');
    final Map<String, Object?> evidence =
        (scores['evidenceCoverage']! as Map).cast<String, Object?>();
    evidence['candidate'] = 0;
    pairedArtifact.writeAsStringSync(
      '${canonicalJson(json)}\n',
      flush: true,
    );

    final CliResult result = await runner.execute(const CliInvocation(
      command: 'compare',
      runId: runId,
      output: evalOutputRootRelativePath,
    ));

    expect(result.exitCode, 2);
    expect(result.payload['errorKind'], 'invalidEvaluatorAsset');
  });
}

LiuYaoEvalRunner _runner(
  String repositoryRoot,
  Phase6FixtureBundle bundle,
  EvalModelTransport transport,
) =>
    LiuYaoEvalRunner(
      repositoryRoot: repositoryRoot,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'phase6-test-secret-value',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://phase6.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'phase6-test-model',
        'LIUYAO_AI_EVAL_PROVIDER_LABEL': 'phase6-test-provider',
      },
      modelTransport: transport,
      assets: Phase6EvalAssets(
        repositoryRoot: repositoryRoot,
        fixture: bundle.fixture,
        rubric: bundle.rubric,
      ),
      canonicalAdapterProvider: (_, __) => bundle.adapter,
    );

Future<void> _preparePair(LiuYaoEvalRunner runner, String runId) async {
  for (final String variant in <String>[baselineVariant, candidateVariant]) {
    final CliResult result = await runner.execute(CliInvocation(
      command: 'prepare',
      runId: runId,
      variant: variant,
      output: evalOutputRootRelativePath,
    ));
    expect(result.exitCode, 0, reason: result.payload.toString());
  }
}

Directory _runDirectory(String repositoryRoot, String runId) => Directory(
      p.join(repositoryRoot, evalOutputRootRelativePath, runId),
    );

File _revealMarker(String repositoryRoot, Phase6FixtureBundle bundle) => File(
      p.join(
        repositoryRoot,
        evalOutputRootRelativePath,
        '_holdout_reveals',
        '${bundle.holdout.cohortHash}.json',
      ),
    );

void _cleanRun(
  String repositoryRoot,
  Phase6FixtureBundle bundle,
  String runId,
) {
  final Directory runDirectory = _runDirectory(repositoryRoot, runId);
  if (runDirectory.existsSync()) {
    runDirectory.deleteSync(recursive: true);
  }
  final File marker = _revealMarker(repositoryRoot, bundle);
  if (marker.existsSync()) {
    marker.deleteSync();
  }
}

class _MalformedJudgeTransport implements EvalModelTransport {
  final SuccessfulPairedTransport _delegate = SuccessfulPairedTransport();

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) {
    if (request.responseFormat == 'json') {
      return Future<ModelCallResult>.value(const ModelCallResult(
        completed: true,
        content: '{}',
        tokensUsed: 1,
        latencyMilliseconds: 1,
        seedSupported: true,
        errorKind: null,
        statusCode: 200,
        retryCount: 0,
      ));
    }
    return _delegate.call(credentials: credentials, request: request);
  }
}

class _FailOnceAfterCalibrationTransport implements EvalModelTransport {
  _FailOnceAfterCalibrationTransport({required this.failOnTextCall});

  final int failOnTextCall;
  final SuccessfulPairedTransport _delegate = SuccessfulPairedTransport();
  int _textCalls = 0;

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) {
    if (request.responseFormat == 'text' && ++_textCalls == failOnTextCall) {
      return Future<ModelCallResult>.value(const ModelCallResult(
        completed: false,
        content: null,
        tokensUsed: null,
        latencyMilliseconds: 1,
        seedSupported: true,
        errorKind: 'simulatedTransportFailure',
        statusCode: 503,
        retryCount: 3,
      ));
    }
    return _delegate.call(credentials: credentials, request: request);
  }
}
