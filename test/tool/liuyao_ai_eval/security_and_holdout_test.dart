import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/holdout.dart';
import '../../../tool/liuyao_ai_eval/model_transport.dart';
import '../../../tool/liuyao_ai_eval/runner.dart';
import '../../../tool/liuyao_ai_eval/security.dart';
import 'eval_filesystem_test_lock.dart';

class _FakeGitInspector extends GitInspector {
  const _FakeGitInspector({this.ignored = true, this.tracked = false});

  final bool ignored;
  final bool tracked;

  @override
  bool isIgnored(String repositoryRoot, String relativePath) => ignored;

  @override
  bool isTracked(String repositoryRoot, String relativePath) => tracked;
}

class _FailIfCalledTransport implements EvalModelTransport {
  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) {
    throw StateError('Transport must not run without credentials.');
  }
}

void main() {
  late Directory temporaryRoot;
  late EvalFilesystemTestLock filesystemLock;

  setUpAll(() async {
    filesystemLock = EvalFilesystemTestLock();
    await filesystemLock.acquire(Directory.current.path);
  });

  setUp(() {
    temporaryRoot = Directory.systemTemp.createTempSync('liuyao-eval-test-');
    File(p.join(temporaryRoot.path, '.gitignore')).writeAsStringSync(
      '/tool/liuyao_ai_eval/eval.local.json\n',
    );
  });

  tearDown(() {
    if (temporaryRoot.existsSync()) {
      temporaryRoot.deleteSync(recursive: true);
    }
  });

  tearDownAll(() => filesystemLock.release());

  test('CLI requires one explicit run ID and rejects credential arguments', () {
    const EvalCliParser parser = EvalCliParser();

    expect(
      () => parser.parse(<String>['validate']),
      throwsA(isA<EvalFailure>()),
    );
    expect(
      parser.parse(<String>['validate', '--run-id', 'gate0-validate']).runId,
      'gate0-validate',
    );
    expect(
      () => parser.parse(<String>[
        'model',
        '--run-id',
        'gate0-model',
        '--variant',
        'legacy-e2e-diagnostic',
        '--output',
        'out',
        '--repetitions',
        '3',
        '--api-key',
        'never-allowed',
      ]),
      throwsA(isA<EvalFailure>()),
    );
  });

  test('config loader returns the one frozen missing-credentials status', () {
    final ConfigLoadResult result = EvalConfigLoader(
      repositoryRoot: temporaryRoot.path,
      environment: const <String, String>{},
      gitInspector: const _FakeGitInspector(),
    ).load();

    expect(result.realModelStatus, 'blockedMissingCredentials');
    expect(result.credentials, isNull);
  });

  test('config loader rejects unknown local keys and tracked config', () {
    final File config = File(
      p.join(temporaryRoot.path, 'tool/liuyao_ai_eval/eval.local.json'),
    )..createSync(recursive: true);
    config.writeAsStringSync(jsonEncode(<String, Object?>{
      'apiKey': 'secret-value',
      'baseUrl': 'https://example.invalid/v1',
      'model': 'model-id',
      'unexpected': true,
    }));

    final ConfigLoadResult unknownKey = EvalConfigLoader(
      repositoryRoot: temporaryRoot.path,
      environment: const <String, String>{},
      gitInspector: const _FakeGitInspector(),
    ).load();
    expect(unknownKey.realModelStatus, 'blockedInvalidConfiguration');

    final ConfigLoadResult tracked = EvalConfigLoader(
      repositoryRoot: temporaryRoot.path,
      environment: const <String, String>{},
      gitInspector: const _FakeGitInspector(tracked: true),
    ).load();
    expect(tracked.realModelStatus, 'blockedInvalidConfiguration');
  });

  test('environment values override local config field by field', () {
    final File config = File(
      p.join(temporaryRoot.path, 'tool/liuyao_ai_eval/eval.local.json'),
    )..createSync(recursive: true);
    config.writeAsStringSync(jsonEncode(<String, Object?>{
      'apiKey': 'local-secret-value',
      'baseUrl': 'https://local.invalid/v1',
      'model': 'local-model',
    }));

    final ConfigLoadResult result = EvalConfigLoader(
      repositoryRoot: temporaryRoot.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_MODEL': 'environment-model',
      },
      gitInspector: const _FakeGitInspector(),
    ).load();

    expect(result.realModelStatus, 'ready');
    expect(result.credentials!.model, 'environment-model');
    expect(
      result.credentials!.timeoutSeconds,
      defaultTransportTimeoutSeconds,
    );
    expect(
        result.credentials.toString(), isNot(contains('local-secret-value')));
  });

  test('transport timeout is bounded and exposed only as safe metadata', () {
    final ConfigLoadResult configured = EvalConfigLoader(
      repositoryRoot: temporaryRoot.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'secret-value',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://example.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'model-id',
        'LIUYAO_AI_EVAL_TIMEOUT_SECONDS': '360',
      },
      gitInspector: const _FakeGitInspector(),
    ).load();
    expect(configured.realModelStatus, 'ready');
    expect(configured.credentials!.timeoutSeconds, 360);
    expect(configured.credentials!.safeMetadata(), <String, Object?>{
      'providerLabel': null,
      'model': 'model-id',
      'timeoutSeconds': 360,
    });

    final ConfigLoadResult rejected = EvalConfigLoader(
      repositoryRoot: temporaryRoot.path,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_API_KEY': 'secret-value',
        'LIUYAO_AI_EVAL_BASE_URL': 'https://example.invalid/v1',
        'LIUYAO_AI_EVAL_MODEL': 'model-id',
        'LIUYAO_AI_EVAL_TIMEOUT_SECONDS': '601',
      },
      gitInspector: const _FakeGitInspector(),
    ).load();
    expect(rejected.realModelStatus, 'blockedInvalidConfiguration');
    expect(rejected.errorKind, 'invalidTimeoutSeconds');
  });

  test('retry identity persists the complete non-secret run contract', () {
    final Directory outputRoot = Directory(
      p.join(temporaryRoot.path, 'retry-output'),
    )..createSync();
    final RunWorkspace workspace = RunWorkspace.open(
      outputRoot: outputRoot,
      runId: 'retry-manifest-r1',
    );
    final String identityHash = 'a' * 64;
    final Map<String, Object?> identity = <String, Object?>{
      'runHash': identityHash,
      'modelHash': 'b' * 64,
      'transportEndpointHash': 'c' * 64,
      'transportTimeoutSeconds': 360,
      'generationRequestHash': 'd' * 64,
      'judgeRequestContractHash': 'e' * 64,
      'judgeReferenceAssetHash': 'f' * 64,
      'transportRetryPolicyVersion': transportRetryPolicyVersion,
    };

    workspace.bindRetryIdentity(
      command: 'paired-model',
      identityHash: identityHash,
      identity: identity,
    );

    final Map<String, Object?> document = decodeObject(
      File(p.join(
        workspace.directory.path,
        'paired-model.identity.json',
      )).readAsStringSync(),
    );
    expect(requireString(document, 'identityHash'), identityHash);
    expect(requireObject(document, 'identity'), normalizeJson(identity));

    workspace.bindRetryIdentity(
      command: 'paired-model',
      identityHash: identityHash,
      identity: identity,
    );
    expect(
      () => workspace.bindRetryIdentity(
        command: 'paired-model',
        identityHash: identityHash,
        identity: <String, Object?>{
          ...identity,
          'transportTimeoutSeconds': 361,
        },
      ),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'retryIdentityMismatch',
        ),
      ),
    );
  });

  test('output guard rejects every path except the exact task eval root', () {
    final OutputPathGuard guard = OutputPathGuard(
      repositoryRoot: temporaryRoot.path,
      gitInspector: const _FakeGitInspector(),
    );
    final String allowed = p.join(
      temporaryRoot.path,
      evalOutputRootRelativePath,
    );

    expect(guard.validateAndCreateRoot(allowed).path, p.normalize(allowed));
    expect(
      () => guard.validateAndCreateRoot(p.join(temporaryRoot.path, 'outside')),
      throwsA(isA<EvalFailure>()),
    );
  });

  test('output guard fails closed when the eval root is not ignored or tracked',
      () {
    final String allowed = p.join(
      temporaryRoot.path,
      evalOutputRootRelativePath,
    );
    final OutputPathGuard notIgnored = OutputPathGuard(
      repositoryRoot: temporaryRoot.path,
      gitInspector: const _FakeGitInspector(ignored: false),
    );
    final OutputPathGuard tracked = OutputPathGuard(
      repositoryRoot: temporaryRoot.path,
      gitInspector: const _FakeGitInspector(tracked: true),
    );

    expect(
      () => notIgnored.validateAndCreateRoot(allowed),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'outputPathNotIgnored',
        ),
      ),
    );
    expect(
      () => tracked.validateAndCreateRoot(allowed),
      throwsA(
        isA<EvalFailure>().having(
          (error) => error.kind,
          'kind',
          'outputPathTracked',
        ),
      ),
    );
    expect(Directory(allowed).existsSync(), isFalse);
  });

  test('artifact writer redacts known and header-shaped secrets before write',
      () {
    final Directory artifacts =
        Directory(p.join(temporaryRoot.path, 'artifacts'))..createSync();
    final SensitiveDataFilter filter = SensitiveDataFilter(
      knownSensitiveValues: const <String>{'known-secret-value'},
    );
    final SafeArtifactWriter writer = SafeArtifactWriter(
      root: artifacts,
      filter: filter,
    );

    final File file = writer.writeJson('result.json', <String, Object?>{
      'message': 'known-secret-value',
      'header': 'Authorization: Bearer hidden-token-value',
    });
    final String content = file.readAsStringSync();
    expect(content, isNot(contains('known-secret-value')));
    expect(content, isNot(contains('hidden-token-value')));
    expect(filter.scanDirectory(artifacts).isClean, isTrue);
  });

  test('artifact writer rejects a broken temporary symbolic link', () {
    final Directory artifacts =
        Directory(p.join(temporaryRoot.path, 'artifacts'))..createSync();
    final SafeArtifactWriter writer = SafeArtifactWriter(
      root: artifacts,
      filter: SensitiveDataFilter(knownSensitiveValues: const <String>{}),
    );
    final String outsidePath = p.join(temporaryRoot.path, 'outside.json');
    final Link temporaryLink = Link(
      p.join(artifacts.path, 'result.json.tmp'),
    );
    try {
      temporaryLink.createSync(outsidePath);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable on this platform.');
      return;
    }

    expect(
      FileSystemEntity.typeSync(temporaryLink.path, followLinks: false),
      FileSystemEntityType.link,
    );
    expect(
      () => writer.writeJson('result.json', const <String, Object?>{
        'status': 'must-not-write',
      }),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'artifactTemporaryFileExists',
        ),
      ),
    );
    expect(File(outsidePath).existsSync(), isFalse);
    expect(File(p.join(artifacts.path, 'result.json')).existsSync(), isFalse);
  });

  test('artifact reader rejects malformed and traversal inputs', () {
    final Directory artifacts =
        Directory(p.join(temporaryRoot.path, 'artifacts'))..createSync();
    File(p.join(artifacts.path, 'malformed.json')).writeAsStringSync('{');
    final File outside = File(p.join(temporaryRoot.path, 'outside.json'))
      ..writeAsStringSync('{"outside":true}');
    final SafeArtifactReader reader = SafeArtifactReader(root: artifacts);

    expect(
      () => reader.readJson('malformed.json'),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'requiredArtifactMalformed',
        ),
      ),
    );
    expect(
      () => reader.readJson('../outside.json'),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'artifactPathInvalid',
        ),
      ),
    );
    expect(
      () => reader.readJson(outside.path),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'artifactPathInvalid',
        ),
      ),
    );
  });

  test('holdout selection is fixed and reveal marker cannot be overwritten',
      () {
    final List<String> ids = List<String>.generate(
      12,
      (int index) => 'liuyao.case.${index + 1}',
    );
    final HoldoutSelection first = selectHoldout(ids);
    final HoldoutSelection second = selectHoldout(ids.reversed);

    expect(first.members, hasLength(6));
    expect(
      first.members.map((HoldoutMember member) => member.caseId),
      <String>[
        'liuyao.case.4',
        'liuyao.case.8',
        'liuyao.case.3',
        'liuyao.case.1',
        'liuyao.case.7',
        'liuyao.case.5',
      ],
    );
    expect(
      first.members.map((HoldoutMember member) => member.selectionHash),
      <String>[
        '139718c348a40a0fe7ca0c532482ab80d81fceeb912dabb4beb4f958c661b676',
        '262c69e5c41c891cbc2622fe0884694c4151dbbaa28570302e713bed327fd911',
        '31421f7085cd7f8e882ba265bdc5f3362a106e2f586f531deb2277aa92ad2c87',
        '40debe95e6490cf61796c51e0bf30da32da69635f78630a1674c24aca0b7efe0',
        '49c04bafe46d76ddd16aa2937449681e58fae371032c01c249495958dc83770c',
        '70d860147562a3ad9d13f862d2b3ff88735c339c6dc8039056cc4ba9382c8c3d',
      ],
    );
    expect(
      first.members.map((HoldoutMember member) => member.caseId),
      second.members.map((HoldoutMember member) => member.caseId),
    );
    expect(first.cohortHash, second.cohortHash);

    final HoldoutRevealStore store = HoldoutRevealStore(
      outputRoot: temporaryRoot,
    );
    store.reveal(
      runId: 'candidate-r1',
      candidateHash: List<String>.filled(64, 'a').join(),
      cohortHash: first.cohortHash,
      revealedAtUtc: DateTime.utc(2026, 8, 2),
    );
    store.validateReveal(
      runId: 'candidate-r1',
      candidateHash: List<String>.filled(64, 'a').join(),
      cohortHash: first.cohortHash,
    );
    final File resumedMarker = store.reveal(
      runId: 'candidate-r1',
      candidateHash: List<String>.filled(64, 'a').join(),
      cohortHash: first.cohortHash,
    );
    expect(resumedMarker.existsSync(), isTrue);
    expect(
      () => store.validateReveal(
        runId: 'candidate-r1',
        candidateHash: List<String>.filled(64, 'b').join(),
        cohortHash: first.cohortHash,
      ),
      throwsA(isA<EvalFailure>()),
    );
    expect(
      () => store.reveal(
        runId: 'candidate-r2',
        candidateHash: List<String>.filled(64, 'b').join(),
        cohortHash: first.cohortHash,
      ),
      throwsA(isA<EvalFailure>()),
    );

    expect(
      () => store.validateReveal(
        runId: 'candidate-r1',
        candidateHash: List<String>.filled(64, 'a').join(),
        cohortHash: '../outside',
      ),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'invalidHoldoutRevealHash',
        ),
      ),
    );

    final String freshCohortHash = List<String>.filled(64, 'b').join();
    expect(
      () => store.reveal(
        runId: 'candidate-r3',
        candidateHash: List<String>.filled(64, 'c').join(),
        cohortHash: freshCohortHash,
        revealedAtUtc: DateTime(2026, 8, 2),
      ),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'invalidHoldoutRevealTimestamp',
        ),
      ),
    );
    expect(store.isRevealed(freshCohortHash), isFalse);
    store.reveal(
      runId: 'candidate-r3',
      candidateHash: List<String>.filled(64, 'c').join(),
      cohortHash: freshCohortHash,
      revealedAtUtc: DateTime.utc(2026, 8, 2),
    );
    expect(store.isRevealed(freshCohortHash), isTrue);
  });

  test('model command records blocked configuration without fake output',
      () async {
    final String repositoryRoot = Directory.current.path;
    const String runId = 'gate0-test-blocked-model';
    final Directory runDirectory = Directory(p.join(
      repositoryRoot,
      evalOutputRootRelativePath,
      runId,
    ));
    if (runDirectory.existsSync()) {
      runDirectory.deleteSync(recursive: true);
    }
    addTearDown(() {
      if (runDirectory.existsSync()) {
        runDirectory.deleteSync(recursive: true);
      }
    });

    final CliResult result = await LiuYaoEvalRunner(
      repositoryRoot: repositoryRoot,
      environment: const <String, String>{
        'LIUYAO_AI_EVAL_BASE_URL': 'not-a-url',
      },
      modelTransport: _FailIfCalledTransport(),
    ).execute(const CliInvocation(
      command: 'model',
      runId: runId,
      variant: 'legacy-e2e-diagnostic',
      output: evalOutputRootRelativePath,
      repetitions: 3,
      confirmRealModel: true,
    ));

    expect(result.payload['realModelStatus'], 'blockedInvalidConfiguration');
    expect(
      File(p.join(
        runDirectory.path,
        'model-legacy-e2e-diagnostic',
        '_BLOCKED',
      )).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(
        runDirectory.path,
        'model-legacy-e2e-diagnostic',
        '_SUCCESS',
      )).existsSync(),
      isFalse,
    );
  });
}
