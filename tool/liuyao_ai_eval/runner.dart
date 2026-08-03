import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'assets.dart';
import 'canonical_contract.dart';
import 'canonical_json.dart';
import 'classics_representative_contract.dart';
import 'classics_representative_evaluation.dart';
import 'comparison.dart';
import 'constants.dart';
import 'hard_gates.dart';
import 'holdout.dart';
import 'model_transport.dart';
import 'paired_evaluation.dart';
import 'real_world_contract.dart';
import 'real_world_evaluation.dart';
import 'real_world_hard_gates.dart';
import 'security.dart';

class CliInvocation {
  const CliInvocation({
    required this.command,
    required this.runId,
    this.variant,
    this.output,
    this.repetitions,
    this.confirmRealModel = false,
  });

  final String command;
  final String runId;
  final String? variant;
  final String? output;
  final int? repetitions;
  final bool confirmRealModel;
}

class CliResult {
  const CliResult({
    required this.exitCode,
    required this.payload,
  });

  final int exitCode;
  final Map<String, Object?> payload;
}

class EvalCliParser {
  const EvalCliParser();

  CliInvocation parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const EvalFailure('commandRequired');
    }
    _rejectCredentialArguments(arguments);
    final String command = arguments.first;
    if (!<String>{
      'validate',
      'prepare',
      'scan',
      'model',
      'compare-offline',
      'paired-model',
      'real-world-paired-model',
      classicsRepresentativeCommand,
      'compare',
    }.contains(command)) {
      throw const EvalFailure('unknownCommand');
    }
    final Map<String, String> values = <String, String>{};
    final Set<String> flags = <String>{};
    int index = 1;
    while (index < arguments.length) {
      final String argument = arguments[index];
      if (argument == '--confirm-real-model') {
        if (!flags.add(argument)) {
          throw const EvalFailure('duplicateOption');
        }
        index += 1;
        continue;
      }
      if (!<String>{'--run-id', '--variant', '--output', '--repetitions'}
          .contains(argument)) {
        throw const EvalFailure('unknownOption');
      }
      if (values.containsKey(argument) || index + 1 >= arguments.length) {
        throw const EvalFailure('missingOrDuplicateOptionValue');
      }
      final String value = arguments[index + 1];
      if (value.startsWith('--')) {
        throw const EvalFailure('missingOrDuplicateOptionValue');
      }
      values[argument] = value;
      index += 2;
    }
    final String? runId = values['--run-id'];
    if (runId == null) {
      throw const EvalFailure('runIdRequired');
    }
    final Set<String> expectedValueOptions = switch (command) {
      'validate' => <String>{'--run-id'},
      'prepare' => <String>{'--run-id', '--variant', '--output'},
      'scan' => <String>{'--run-id', '--output'},
      'compare-offline' => <String>{'--run-id', '--output'},
      'compare' => <String>{'--run-id', '--output'},
      'model' => <String>{
          '--run-id',
          '--variant',
          '--output',
          '--repetitions',
        },
      'paired-model' ||
      'real-world-paired-model' ||
      classicsRepresentativeCommand =>
        <String>{
          '--run-id',
          '--output',
          '--repetitions',
        },
      _ => throw const EvalFailure('unknownCommand'),
    };
    if (!expectedValueOptions.containsAll(values.keys) ||
        !values.keys.toSet().containsAll(expectedValueOptions)) {
      throw const EvalFailure('commandOptionContractMismatch');
    }
    if (!<String>{
          'model',
          'paired-model',
          'real-world-paired-model',
          classicsRepresentativeCommand,
        }.contains(command) &&
        flags.isNotEmpty) {
      throw const EvalFailure('commandOptionContractMismatch');
    }
    final String? variant = values['--variant'];
    if (variant != null && !supportedVariants.contains(variant)) {
      throw const EvalFailure('unknownVariant');
    }
    final int? repetitions = values['--repetitions'] == null
        ? null
        : int.tryParse(values['--repetitions']!);
    if (command == 'model' && (repetitions == null || repetitions < 3)) {
      throw const EvalFailure('minimumThreeRepetitionsRequired');
    }
    if (<String>{
          'paired-model',
          'real-world-paired-model',
          classicsRepresentativeCommand,
        }.contains(command) &&
        repetitions != 3) {
      throw const EvalFailure('exactlyThreeRepetitionsRequired');
    }
    return CliInvocation(
      command: command,
      runId: runId,
      variant: variant,
      output: values['--output'],
      repetitions: repetitions,
      confirmRealModel: flags.contains('--confirm-real-model'),
    );
  }

  void _rejectCredentialArguments(List<String> arguments) {
    final RegExp forbidden = RegExp(
      r'(api.?key|authorization|bearer|base.?url|provider.?label|model.?id|token)',
      caseSensitive: false,
    );
    if (arguments.skip(1).any(forbidden.hasMatch)) {
      throw const EvalFailure('credentialsNotAllowedInArguments');
    }
  }
}

class LiuYaoEvalRunner {
  LiuYaoEvalRunner({
    required this.repositoryRoot,
    Map<String, String>? environment,
    EvalModelTransport? modelTransport,
    EvalAssets? assets,
    CanonicalAdapterProvider? canonicalAdapterProvider,
    RealWorldAssetLoader Function(String repositoryRoot)?
        realWorldAssetLoaderProvider,
  })  : _environment = environment,
        _modelTransport = modelTransport ?? OpenAiCompatibleEvalTransport(),
        _assets = assets ?? EvalAssets(repositoryRoot),
        _canonicalAdapterProvider = canonicalAdapterProvider ??
            CanonicalAdapterFileLoader(repositoryRoot: repositoryRoot).load,
        _realWorldAssetLoaderProvider = realWorldAssetLoaderProvider ??
            ((root) => RealWorldAssetLoader(root));

  final String repositoryRoot;
  final Map<String, String>? _environment;
  final EvalModelTransport _modelTransport;
  final EvalAssets _assets;
  final CanonicalAdapterProvider _canonicalAdapterProvider;
  final RealWorldAssetLoader Function(String repositoryRoot)
      _realWorldAssetLoaderProvider;

  Future<CliResult> execute(CliInvocation invocation) async {
    try {
      return switch (invocation.command) {
        'validate' => _validate(invocation),
        'prepare' => _prepare(invocation),
        'scan' => _scan(invocation),
        'model' => await _model(invocation),
        'compare-offline' => _compareOffline(invocation),
        'paired-model' => await _pairedModel(invocation),
        'real-world-paired-model' => await _realWorldPairedModel(invocation),
        classicsRepresentativeCommand =>
          await _classicsRepresentativePairedModel(invocation),
        'compare' => _compare(invocation),
        _ => throw const EvalFailure('unknownCommand'),
      };
    } on EvalFailure catch (error) {
      return CliResult(
        exitCode: 2,
        payload: <String, Object?>{
          'runId': invocation.runId,
          'command': invocation.command,
          'status': 'failed',
          'errorKind': error.kind,
        },
      );
    } on FormatException {
      return CliResult(
        exitCode: 2,
        payload: <String, Object?>{
          'runId': invocation.runId,
          'command': invocation.command,
          'status': 'failed',
          'errorKind': 'invalidEvaluatorAsset',
        },
      );
    } on FileSystemException {
      return CliResult(
        exitCode: 2,
        payload: <String, Object?>{
          'runId': invocation.runId,
          'command': invocation.command,
          'status': 'failed',
          'errorKind': 'filesystemOperationFailed',
        },
      );
    }
  }

  Future<CliResult> _classicsRepresentativePairedModel(
    CliInvocation invocation,
  ) async {
    if (!invocation.confirmRealModel) {
      throw const EvalFailure('realModelConfirmationRequired');
    }
    final ClassicsRepresentativeRunResult result =
        await ClassicsRepresentativeEvaluationRunner(
      repositoryRoot: repositoryRoot,
      environment: _environment,
      modelTransport: _modelTransport,
      assets: _assets,
    ).run(
      runId: invocation.runId,
      output: invocation.output!,
      repetitions: invocation.repetitions!,
    );
    return CliResult(exitCode: result.exitCode, payload: result.payload);
  }

  CliResult _validate(CliInvocation invocation) {
    _validateRunId(invocation.runId);
    final EvalFixture fixture = _assets.loadFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final FrozenValidation frozen = _assets.validateFrozenAssets();
    validateOfflineHardGateFixtures(
      fixture,
      rubric,
      _assets.loadOfflineOutputs(),
    );
    final ConfigLoadResult config = _configLoader().load();
    if (config.realModelStatus == 'blockedInvalidConfiguration') {
      throw EvalFailure(config.errorKind ?? 'invalidConfiguration');
    }
    String canonicalV2Status = 'ready';
    String? canonicalFixtureHash;
    try {
      final EvalFixture canonicalFixture = _assets.loadCanonicalFixture();
      canonicalFixtureHash = canonicalFixture.hash;
      _canonicalAdapterProvider(canonicalFixture, rubric);
    } on EvalFailure catch (error) {
      if (error.kind == 'canonicalV2FixtureMissing') {
        canonicalV2Status = 'blockedMissingCanonicalFixture';
      } else if (error.kind == 'canonicalV2AdapterMissing') {
        canonicalV2Status = 'blockedMissingCanonicalAdapter';
      } else {
        rethrow;
      }
    }
    final RealWorldAssetLoader realWorldLoader =
        _realWorldAssetLoaderProvider(repositoryRoot);
    final RealWorldGenerationFixture realWorldFixture =
        realWorldLoader.loadGenerationFixture();
    final RealWorldEvalAdapter realWorldAdapter =
        realWorldLoader.loadAdapter(realWorldFixture);
    final RealWorldJudgeReferenceManifest realWorldReferenceManifest =
        realWorldLoader.loadJudgeReferenceManifest();
    final RealWorldJudgeReference realWorldReference =
        realWorldLoader.loadJudgeReference(
      manifest: realWorldReferenceManifest,
    );
    if (realWorldReference.caseId != realWorldFixture.caseId) {
      throw const FormatException('Real-world reference identity mismatch.');
    }
    final String realWorldReferenceAssetHash =
        realWorldReferenceManifest.referenceAssetSha256;
    return CliResult(
      exitCode: 0,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': 'validated',
        'fixtureHash': fixture.hash,
        'rubricHash': rubric.hash,
        'legacyTemplateSetHash': frozen.templatesHash,
        'legacyRequestSetHash': frozen.requestsHash,
        'legacySourceCommit': frozen.sourceCommit,
        'realModelStatus': config.realModelStatus,
        'canonicalV2Status': canonicalV2Status,
        'canonicalFixtureHash': canonicalFixtureHash,
        'canonicalFixturePath': evalCanonicalFixtureRelativePath,
        'canonicalAdapterPath': evalCanonicalAdapterRelativePath,
        'realWorldStatus': 'ready',
        'realWorldGenerationFixtureHash': realWorldFixture.hash,
        'realWorldAdapterHash': realWorldAdapter.hash,
        'realWorldJudgeReferenceHash': realWorldReference.hash,
        'realWorldJudgeReferenceAssetHash': realWorldReferenceAssetHash,
      },
    );
  }

  CliResult _prepare(CliInvocation invocation) {
    _validateRunId(invocation.runId);
    if (invocation.variant != legacyDiagnosticVariant) {
      return _prepareCanonical(invocation);
    }
    final EvalFixture fixture = _assets.loadFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final FrozenValidation frozen = _assets.validateFrozenAssets();
    final Map<String, Object?> requestSet = _legacyRequestSet(
      invocation.runId,
      fixture,
      rubric,
      frozen,
    );
    for (final Object? raw in requestSet['requests']! as List<Object?>) {
      final Map<String, Object?> request =
          (raw! as Map).cast<String, Object?>();
      validateModelInputUtf8Size(
        systemPrompt: request['systemPrompt']! as String,
        userPrompt: request['userPrompt']! as String,
        byteLimit: generationInputUtf8ByteLimit,
        errorKind: 'generationInputTooLarge',
      );
    }
    final _Scope scope = _openScope(invocation, 'prepare');
    scope.writer.writeJson('request_set.json', requestSet);
    final ScanReport postWrite = scope.filter.scanDirectory(scope.directory);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', postWrite.toJson());
    if (!scope.filter.scanDirectory(scope.directory).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    scope.writer.writeMarker('_SUCCESS');
    return CliResult(
      exitCode: 0,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'variant': invocation.variant,
        'status': 'prepared',
        'requestSetHash': requestSet['requestSetHash'],
        'artifactScope': p.relative(
          scope.directory.path,
          from: repositoryRoot,
        ),
      },
    );
  }

  CliResult _prepareCanonical(CliInvocation invocation) {
    final String variant = invocation.variant!;
    if (!<String>{baselineVariant, candidateVariant}.contains(variant)) {
      throw const EvalFailure('unknownCanonicalVariant');
    }
    final EvalFixture fixture = _assets.loadCanonicalFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final CanonicalEvalAdapter adapter =
        _canonicalAdapterProvider(fixture, rubric);
    final CanonicalRequestSet requestSet = CanonicalRequestSet.create(
      runId: invocation.runId,
      variant: variant,
      adapter: adapter,
      fixture: fixture,
      rubric: rubric,
    );
    final _Scope scope = _openScope(invocation, 'prepare');
    scope.writer.writeJson('request_set.json', requestSet.toJson());
    final ScanReport postWrite = scope.filter.scanDirectory(scope.directory);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', postWrite.toJson());
    if (!scope.filter.scanDirectory(scope.directory).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    scope.writer.writeMarker('_SUCCESS');
    return CliResult(
      exitCode: 0,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'variant': variant,
        'status': 'prepared',
        'adapterHash': adapter.hash,
        'projectionSetHash': requestSet.projectionSetHash,
        'caseInputSetHash': requestSet.caseInputSetHash,
        'requestParametersHash': requestSet.requestParametersHash,
        'requestSetHash': requestSet.requestSetHash,
        'artifactScope': p.relative(
          scope.directory.path,
          from: repositoryRoot,
        ),
      },
    );
  }

  CliResult _scan(CliInvocation invocation) {
    _validateRunId(invocation.runId);
    final Directory outputRoot = _outputRoot(invocation.output!);
    final RunWorkspace workspace = RunWorkspace.open(
      outputRoot: outputRoot,
      runId: invocation.runId,
    );
    final ConfigLoadResult config = _configLoader().load();
    if (config.realModelStatus == 'blockedInvalidConfiguration') {
      throw EvalFailure(config.errorKind ?? 'invalidConfiguration');
    }
    final SensitiveDataFilter filter = SensitiveDataFilter(
      knownSensitiveValues:
          config.credentials?.sensitiveValues ?? const <String>{},
    );
    final ScanReport report = filter.scanDirectory(workspace.directory);
    final Directory scopeDirectory =
        workspace.createSequencedCommandDirectory('scan');
    final SafeArtifactWriter writer = SafeArtifactWriter(
      root: scopeDirectory,
      filter: filter,
    );
    writer.writeJson('scan.json', <String, Object?>{
      'schemaVersion': evalArtifactSchemaVersion,
      'runId': invocation.runId,
      ...report.toJson(),
    });
    if (report.isClean) {
      writer.writeMarker('_SUCCESS');
    }
    return CliResult(
      exitCode: report.isClean ? 0 : 3,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': report.isClean ? 'clean' : 'sensitiveMatchesFound',
        'totalMatches': report.totalMatches,
      },
    );
  }

  Future<CliResult> _model(CliInvocation invocation) async {
    _validateRunId(invocation.runId);
    if (!invocation.confirmRealModel) {
      throw const EvalFailure('realModelConfirmationRequired');
    }
    if (invocation.variant != legacyDiagnosticVariant) {
      throw const EvalFailure('canonicalV2PrerequisiteNotAvailable');
    }
    final Directory outputRoot = _outputRoot(invocation.output!);
    final RunWorkspace workspace = RunWorkspace.open(
      outputRoot: outputRoot,
      runId: invocation.runId,
    );
    final ConfigLoadResult config = _configLoader().load();
    final SensitiveDataFilter filter = SensitiveDataFilter(
      knownSensitiveValues:
          config.credentials?.sensitiveValues ?? const <String>{},
    );
    final ScanReport preScan = filter.scanDirectory(outputRoot);
    if (!preScan.isClean) {
      throw const EvalFailure('preWriteSensitiveScanFailed');
    }
    final Directory scopeDirectory = workspace.createCommandDirectory(
      'model',
      variant: invocation.variant,
    );
    final SafeArtifactWriter writer = SafeArtifactWriter(
      root: scopeDirectory,
      filter: filter,
    );
    final EvalFixture fixture = _assets.loadFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final FrozenValidation frozen = _assets.validateFrozenAssets();
    final Map<String, Object?> requestSet = _legacyRequestSet(
      invocation.runId,
      fixture,
      rubric,
      frozen,
    );

    if (config.realModelStatus != 'ready' || config.credentials == null) {
      final String status = config.realModelStatus;
      if (!supportedRealModelStatuses.contains(status)) {
        throw const EvalFailure('invalidRealModelStatus');
      }
      writer.writeJson('model_status.json', <String, Object?>{
        'schemaVersion': evalArtifactSchemaVersion,
        'runId': invocation.runId,
        'variant': invocation.variant,
        'realModelStatus': status,
        'errorKind': config.errorKind,
        'requestSetHash': requestSet['requestSetHash'],
        'requestHashes': <Object?>[
          for (final Object? raw in requestSet['requests']! as List<Object?>)
            <String, Object?>{
              'requestId': (raw! as Map<String, Object?>)['requestId'],
              'requestHash': (raw as Map<String, Object?>)['requestHash'],
            },
        ],
      });
      if (!filter.scanDirectory(scopeDirectory).isClean) {
        throw const EvalFailure('postWriteSensitiveScanFailed');
      }
      writer.writeMarker('_BLOCKED');
      return CliResult(
        exitCode: status == 'blockedMissingCredentials' ? 4 : 2,
        payload: <String, Object?>{
          'runId': invocation.runId,
          'command': invocation.command,
          'variant': invocation.variant,
          'status': status,
          'realModelStatus': status,
        },
      );
    }

    final EvalCredentials credentials = config.credentials!;
    final List<Object?> responses = <Object?>[];
    bool allCompleted = true;
    for (final Object? raw in requestSet['requests']! as List<Object?>) {
      final Map<String, Object?> request =
          (raw! as Map).cast<String, Object?>();
      for (int repetition = 1;
          repetition <= invocation.repetitions!;
          repetition += 1) {
        final ModelCallResult result = await _modelTransport.call(
          credentials: credentials,
          request: ModelCallRequest(
            systemPrompt: request['systemPrompt']! as String,
            userPrompt: request['userPrompt']! as String,
            temperature: 0,
            maxTokens: generationMaxTokens,
          ),
        );
        allCompleted = allCompleted && result.completed;
        responses.add(<String, Object?>{
          'logicalRequestId': sha256Text(
            '${invocation.runId}\n${request['requestId']}\n$repetition',
          ),
          'requestId': request['requestId'],
          'repetition': repetition,
          'completed': result.completed,
          'content': result.content,
          'tokensUsed': result.tokensUsed,
          'latencyMilliseconds': result.latencyMilliseconds,
          'seedSupported': result.seedSupported,
          'errorKind': result.errorKind,
          'statusCode': result.statusCode,
          'retryCount': result.retryCount,
          'normalizationStatus': 'notRunDiagnostic',
        });
      }
    }
    final String realModelStatus =
        allCompleted ? 'completed' : 'failedTransport';
    writer.writeJson('model_results.json', <String, Object?>{
      'schemaVersion': evalArtifactSchemaVersion,
      'runId': invocation.runId,
      'variant': invocation.variant,
      'realModelStatus': realModelStatus,
      'modelMetadata': credentials.safeMetadata(),
      'requestSetHash': requestSet['requestSetHash'],
      'requestParametersHash': requestSet['requestParametersHash'],
      'responses': responses,
    });
    final ScanReport postWrite = filter.scanDirectory(scopeDirectory);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    writer.writeJson('scan.json', postWrite.toJson());
    if (!filter.scanDirectory(scopeDirectory).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    if (allCompleted) {
      writer.writeMarker('_SUCCESS');
    }
    return CliResult(
      exitCode: allCompleted ? 0 : 5,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'variant': invocation.variant,
        'status': realModelStatus,
        'realModelStatus': realModelStatus,
      },
    );
  }

  CliResult _compareOffline(CliInvocation invocation) {
    _validateRunId(invocation.runId);
    final _EvaluationWorkspace context = _openEvaluationWorkspace(invocation);
    final EvalFixture fixture = _assets.loadCanonicalFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final CanonicalPairContract contract = _loadCanonicalPair(
      context.workspace,
      fixture,
      rubric,
    );
    final OfflineComparisonManifest manifest =
        OfflineComparisonManifest.create(contract);
    final _Scope scope = context.createScope('compare-offline');
    scope.writer.writeJson('offline_comparison.json', manifest.toJson());
    final ScanReport postWrite =
        context.filter.scanDirectory(context.outputRoot);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', postWrite.toJson());
    if (!context.filter.scanDirectory(context.outputRoot).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    scope.writer.writeMarker('_SUCCESS');
    return CliResult(
      exitCode: 0,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': 'ready',
        'candidateHash': manifest.candidateHash,
        'holdoutCohortHash': manifest.holdout.cohortHash,
        'holdoutCaseCount': manifest.holdout.members.length,
      },
    );
  }

  Future<CliResult> _pairedModel(CliInvocation invocation) async {
    _validateRunId(invocation.runId);
    if (!invocation.confirmRealModel) {
      throw const EvalFailure('realModelConfirmationRequired');
    }
    if (invocation.repetitions != 3) {
      throw const EvalFailure('exactlyThreeRepetitionsRequired');
    }
    final _EvaluationWorkspace context = _openEvaluationWorkspace(invocation);
    final EvalFixture fixture = _assets.loadCanonicalFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final CanonicalPairContract contract = _loadCanonicalPair(
      context.workspace,
      fixture,
      rubric,
    );
    _loadOfflineManifest(context.workspace, contract);
    for (final CanonicalPreparedRequest request in <CanonicalPreparedRequest>[
      ...contract.baseline.requests,
      ...contract.candidate.requests,
    ]) {
      validateModelInputUtf8Size(
        systemPrompt: request.systemPrompt,
        userPrompt: request.userPrompt,
        byteLimit: generationInputUtf8ByteLimit,
        errorKind: 'generationInputTooLarge',
      );
    }
    final ConfigLoadResult config = context.config;
    if (config.realModelStatus != 'ready' || config.credentials == null) {
      final _Scope scope = context.createRetryableScope('paired-model');
      return _writePairedStatus(
        invocation: invocation,
        context: context,
        scope: scope,
        contract: contract,
        realModelStatus: config.realModelStatus,
        evaluationStatus: 'blocked',
        errorKind: config.errorKind,
        exitCode: config.realModelStatus == 'blockedMissingCredentials' ? 4 : 2,
      );
    }

    final EvalCredentials credentials = config.credentials!;
    final String modelHash = sha256Text(credentials.model);
    final ComparisonIdentity identity = ComparisonIdentity.create(
      runId: invocation.runId,
      fixtureHash: fixture.hash,
      rubricHash: rubric.hash,
      adapterHash: contract.baseline.adapterHash,
      projectionSetHash: contract.baseline.projectionSetHash,
      caseInputSetHash: contract.baseline.caseInputSetHash,
      modelHash: modelHash,
      judgeModelHash: modelHash,
      transportEndpointHash: sha256Text(credentials.baseUrl),
      transportTimeoutSeconds: credentials.timeoutSeconds,
      requestParametersHash: contract.baseline.requestParametersHash,
      judgeRequestContractHash: judgeRequestContractHash,
      baselineRequestSetHash: contract.baseline.requestSetHash,
      candidateRequestSetHash: contract.candidate.requestSetHash,
    );
    context.workspace.bindRetryIdentity(
      command: 'paired-model',
      identityHash: identity.runHash,
      identity: identity.toJson(),
    );
    final _Scope scope = context.createRetryableScope('paired-model');
    final List<PairedEvaluation> pairs = <PairedEvaluation>[];
    final List<EvalCase> orderedCases = <EvalCase>[
      ...fixture.cases.where(
        (EvalCase evalCase) => evalCase.evaluationSplit != 'holdout',
      ),
      ...fixture.cases.where(
        (EvalCase evalCase) => evalCase.evaluationSplit == 'holdout',
      ),
    ];
    bool holdoutRevealed = false;
    for (final EvalCase evalCase in orderedCases) {
      if (evalCase.evaluationSplit == 'holdout' && !holdoutRevealed) {
        HoldoutRevealStore(outputRoot: context.outputRoot).reveal(
          runId: invocation.runId,
          candidateHash: contract.candidateHash,
          cohortHash: contract.holdout.cohortHash,
        );
        holdoutRevealed = true;
      }
      for (int repetition = 1; repetition <= 3; repetition += 1) {
        final List<String> generationOrder = pairedGenerationOrder(
          runId: invocation.runId,
          caseId: evalCase.caseId,
          repetition: repetition,
        );
        final Map<String, ModelCallResult> generationResults =
            <String, ModelCallResult>{};
        final Map<String, String> generationContent = <String, String>{};
        for (int orderIndex = 0;
            orderIndex < generationOrder.length;
            orderIndex += 1) {
          final String variant = generationOrder[orderIndex];
          final CanonicalPreparedRequest request = (variant == baselineVariant
                  ? contract.baseline
                  : contract.candidate)
              .requestByCaseId(evalCase.caseId);
          final ModelCallResult result = await _modelTransport.call(
            credentials: credentials,
            request: ModelCallRequest(
              systemPrompt: request.systemPrompt,
              userPrompt: request.userPrompt,
              temperature: 0,
              maxTokens: generationMaxTokens,
              responseFormat: 'text',
              seed: generationSeed,
            ),
          );
          if (!result.completed ||
              result.content == null ||
              result.content!.trim().isEmpty) {
            return _writePairedStatus(
              invocation: invocation,
              context: context,
              scope: scope,
              contract: contract,
              realModelStatus: 'failedTransport',
              evaluationStatus: 'generationFailed',
              errorKind: result.errorKind ?? 'emptyGenerationResponse',
              exitCode: 5,
              caseId: evalCase.caseId,
              repetition: repetition,
            );
          }
          generationResults[variant] = result;
          generationContent[variant] = result.content!;
        }

        final Map<String, String> blindMapping = blindLabelMapping(
          runId: invocation.runId,
          caseId: evalCase.caseId,
          repetition: repetition,
        );
        final Map<String, Object?> judgeRequest = buildJudgeRequest(
          runId: invocation.runId,
          evalCase: evalCase,
          repetition: repetition,
          rubric: rubric,
          blindMapping: blindMapping,
          generationContentByVariant: generationContent,
        );
        try {
          validateModelInputUtf8Size(
            systemPrompt: judgeSystemPrompt,
            userPrompt: canonicalJson(judgeRequest),
            byteLimit: judgeInputUtf8ByteLimit,
            errorKind: 'judgeInputTooLarge',
          );
        } on EvalFailure catch (error) {
          return _writePairedStatus(
            invocation: invocation,
            context: context,
            scope: scope,
            contract: contract,
            realModelStatus: 'completed',
            evaluationStatus: 'judgeInputRejected',
            errorKind: error.kind,
            exitCode: 6,
            caseId: evalCase.caseId,
            repetition: repetition,
          );
        }
        final ModelCallResult judgeResult = await _modelTransport.call(
          credentials: credentials,
          request: ModelCallRequest(
            systemPrompt: judgeSystemPrompt,
            userPrompt: canonicalJson(judgeRequest),
            temperature: 0,
            maxTokens: judgeMaxTokens,
            responseFormat: 'json',
            seed: judgeSeed,
          ),
        );
        if (!judgeResult.completed ||
            judgeResult.content == null ||
            judgeResult.content!.trim().isEmpty) {
          return _writePairedStatus(
            invocation: invocation,
            context: context,
            scope: scope,
            contract: contract,
            realModelStatus: 'failedTransport',
            evaluationStatus: 'judgeFailed',
            errorKind: judgeResult.errorKind ?? 'emptyJudgeResponse',
            exitCode: 5,
            caseId: evalCase.caseId,
            repetition: repetition,
          );
        }
        JudgeEvaluation judge;
        try {
          judge = JudgeEvaluation.fromContent(
            content: judgeResult.content!,
            caseId: evalCase.caseId,
            repetition: repetition,
            rubric: rubric,
          );
        } on Object {
          return _writePairedStatus(
            invocation: invocation,
            context: context,
            scope: scope,
            contract: contract,
            realModelStatus: 'completed',
            evaluationStatus: 'malformedJudgeResult',
            errorKind: 'malformedJudgeResult',
            exitCode: 6,
            caseId: evalCase.caseId,
            repetition: repetition,
          );
        }
        final NormalizedModelOutput baselineNormalized =
            judge.normalizedForVariant(baselineVariant, blindMapping);
        final NormalizedModelOutput candidateNormalized =
            judge.normalizedForVariant(candidateVariant, blindMapping);
        final HardGateResult baselineGates =
            const HardGateEvaluator().evaluate(evalCase, baselineNormalized);
        final HardGateResult candidateGates =
            const HardGateEvaluator().evaluate(evalCase, candidateNormalized);
        VariantEvaluation variantEvaluation(
          String variant,
          NormalizedModelOutput normalized,
          HardGateResult gates,
        ) {
          final CanonicalPreparedRequest request = (variant == baselineVariant
                  ? contract.baseline
                  : contract.candidate)
              .requestByCaseId(evalCase.caseId);
          final int orderIndex = generationOrder.indexOf(variant);
          return VariantEvaluation(
            variant: variant,
            requestHash: request.requestHash,
            projectionHash: request.projectionHash,
            caseInputHash: request.caseInputHash,
            normalizedOutput: generationArtifactJson(
              result: generationResults[variant]!,
              normalized: normalized,
              logicalRequestId: sha256Text(
                '${invocation.runId}\n${evalCase.caseId}\n$repetition\n$variant',
              ),
              orderIndex: orderIndex,
            ),
            hardGates: gates.gates,
          );
        }

        pairs.add(PairedEvaluation(
          runId: invocation.runId,
          runHash: identity.runHash,
          caseId: evalCase.caseId,
          repetition: repetition,
          baseline: variantEvaluation(
            baselineVariant,
            baselineNormalized,
            baselineGates,
          ),
          candidate: variantEvaluation(
            candidateVariant,
            candidateNormalized,
            candidateGates,
          ),
          blindLabelMapping: blindMapping,
          judgeRequest: judgeRequest,
          judgeResponse: judge.rawResponse,
          scores: judge.dimensionScores(blindMapping),
        ));
      }
    }

    final PairedRunArtifact artifact = PairedRunArtifact(
      runId: invocation.runId,
      candidateHash: contract.candidateHash,
      model: credentials.model,
      providerLabel: credentials.providerLabel,
      timeoutSeconds: credentials.timeoutSeconds,
      identity: identity,
      pairs: List<PairedEvaluation>.unmodifiable(pairs),
    );
    scope.writer.writeJson('paired_results.json', artifact.toJson());
    final ScanReport postWrite =
        context.filter.scanDirectory(context.outputRoot);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', postWrite.toJson());
    if (!context.filter.scanDirectory(context.outputRoot).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    scope.writer.writeMarker('_SUCCESS');
    return CliResult(
      exitCode: 0,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': 'completed',
        'realModelStatus': 'completed',
        'candidateHash': contract.candidateHash,
        'runHash': identity.runHash,
        'pairCount': pairs.length,
      },
    );
  }

  Future<CliResult> _realWorldPairedModel(CliInvocation invocation) async {
    _validateRunId(invocation.runId);
    if (!invocation.confirmRealModel) {
      throw const EvalFailure('realModelConfirmationRequired');
    }
    if (invocation.repetitions != 3) {
      throw const EvalFailure('exactlyThreeRepetitionsRequired');
    }
    final _EvaluationWorkspace context = _openEvaluationWorkspace(invocation);
    final RealWorldAssetLoader loader =
        _realWorldAssetLoaderProvider(repositoryRoot);
    final RealWorldGenerationFixture fixture = loader.loadGenerationFixture();
    final RealWorldEvalAdapter adapter = loader.loadAdapter(fixture);
    final RealWorldJudgeReferenceManifest referenceManifest =
        loader.loadJudgeReferenceManifest();
    if (referenceManifest.caseId != fixture.caseId) {
      throw const EvalFailure('realWorldReferenceIdentityMismatch');
    }
    final String judgeReferenceAssetHash =
        referenceManifest.referenceAssetSha256;
    for (final RealWorldAdapterCase item in adapter.cases) {
      for (final RealWorldPromptVariant variant in <RealWorldPromptVariant>[
        item.baseline,
        item.candidate,
      ]) {
        validateModelInputUtf8Size(
          systemPrompt: variant.systemPrompt,
          userPrompt: variant.userPrompt,
          byteLimit: generationInputUtf8ByteLimit,
          errorKind: 'generationInputTooLarge',
        );
      }
    }
    final ConfigLoadResult config = context.config;
    if (config.realModelStatus != 'ready' || config.credentials == null) {
      final _Scope scope = context.createRetryableScope(
        'real-world-paired-model',
      );
      return _writeRealWorldStatus(
        invocation: invocation,
        context: context,
        scope: scope,
        adapter: adapter,
        judgeReferenceAssetHash: judgeReferenceAssetHash,
        status: 'blocked',
        realModelStatus: config.realModelStatus,
        errorKind: config.errorKind,
        exitCode: config.realModelStatus == 'blockedMissingCredentials' ? 4 : 2,
      );
    }
    final EvalCredentials credentials = config.credentials!;
    final String transportEndpointHash = sha256Text(credentials.baseUrl);
    final Map<String, Object?> realWorldIdentity = realWorldRunIdentity(
      runId: invocation.runId,
      fixture: fixture,
      adapter: adapter,
      modelHash: sha256Text(credentials.model),
      transportEndpointHash: transportEndpointHash,
      transportTimeoutSeconds: credentials.timeoutSeconds,
      judgeReferenceAssetHash: judgeReferenceAssetHash,
    );
    final String realWorldRunHash = requireString(realWorldIdentity, 'runHash');
    context.workspace.bindRetryIdentity(
      command: 'real-world-paired-model',
      identityHash: realWorldRunHash,
      identity: realWorldIdentity,
    );
    final _Scope scope = context.createRetryableScope(
      'real-world-paired-model',
    );
    String transportRequestHash(String kind, String frozenRequestHash) {
      final String requestContractHash = kind == 'judge'
          ? realWorldJudgeRequestContractHash
          : adapter.requestParameters.hash;
      return sha256Json(<String, Object?>{
        'kind': kind,
        'frozenRequestHash': frozenRequestHash,
        'modelHash': sha256Text(credentials.model),
        'transportEndpointHash': transportEndpointHash,
        'transportTimeoutSeconds': credentials.timeoutSeconds,
        'transportRetryPolicyVersion': transportRetryPolicyVersion,
        'requestContractHash': requestContractHash,
      });
    }

    final List<Map<String, Object?>> pairs = <Map<String, Object?>>[];
    bool candidatePassed = true;
    for (final RealWorldAdapterCase adapterCase in adapter.cases) {
      for (int repetition = 1; repetition <= 3; repetition += 1) {
        final List<String> order = pairedGenerationOrder(
          runId: invocation.runId,
          caseId: adapterCase.scenarioId,
          repetition: repetition,
        )
            .map(
              (variant) => variant == baselineVariant
                  ? realWorldBaselineVariant
                  : realWorldCandidateVariant,
            )
            .toList(growable: false);
        final Map<String, ModelCallResult> generationResults =
            <String, ModelCallResult>{};
        final Map<String, String> generationContent = <String, String>{};
        for (final String variant in order) {
          final RealWorldPromptVariant request =
              variant == realWorldBaselineVariant
                  ? adapterCase.baseline
                  : adapterCase.candidate;
          final ModelCallResult result = await _modelTransport.call(
            credentials: credentials,
            request: ModelCallRequest(
              systemPrompt: request.systemPrompt,
              userPrompt: request.userPrompt,
              temperature: 0,
              maxTokens: generationMaxTokens,
              responseFormat: 'text',
              seed: generationSeed,
            ),
          );
          if (!result.completed ||
              result.content == null ||
              result.content!.trim().isEmpty) {
            return _writeRealWorldStatus(
              invocation: invocation,
              context: context,
              scope: scope,
              adapter: adapter,
              judgeReferenceAssetHash: judgeReferenceAssetHash,
              status: 'generationFailed',
              realModelStatus: 'failedTransport',
              errorKind: result.errorKind ?? 'emptyGenerationResponse',
              exitCode: 5,
              scenarioId: adapterCase.scenarioId,
              repetition: repetition,
              failedVariant: variant,
              failedRequestHash: request.requestHash,
              failedTransportRequestHash:
                  transportRequestHash('generation', request.requestHash),
              transportResult: result,
            );
          }
          generationResults[variant] = result;
          generationContent[variant] = result.content!;
        }

        Map<String, Object?> generationArtifact(String variant) {
          final ModelCallResult result = generationResults[variant]!;
          return <String, Object?>{
            'requestHash': variant == realWorldBaselineVariant
                ? adapterCase.baseline.requestHash
                : adapterCase.candidate.requestHash,
            'transportRequestHash': transportRequestHash(
              'generation',
              variant == realWorldBaselineVariant
                  ? adapterCase.baseline.requestHash
                  : adapterCase.candidate.requestHash,
            ),
            'content': result.content,
            'tokensUsed': result.tokensUsed,
            'latencyMilliseconds': result.latencyMilliseconds,
            'seedSupported': result.seedSupported,
            'statusCode': result.statusCode,
            'retryCount': result.retryCount,
          };
        }

        final RealWorldHardGateResult baselineGates =
            const RealWorldHardGateEvaluator().evaluate(
          adapterCase: adapterCase,
          rawOutput: generationContent[realWorldBaselineVariant]!,
        );
        final RealWorldHardGateResult candidateGates =
            const RealWorldHardGateEvaluator().evaluate(
          adapterCase: adapterCase,
          rawOutput: generationContent[realWorldCandidateVariant]!,
        );
        candidatePassed = candidatePassed && candidateGates.passed;
        if (!candidateGates.passed) {
          final Map<String, Object?> pair = <String, Object?>{
            'caseId': fixture.caseId,
            'scenarioId': adapterCase.scenarioId,
            'repetition': repetition,
            'generationOrder': order,
            'baseline': <String, Object?>{
              'generation': generationArtifact(realWorldBaselineVariant),
              'hardGates': baselineGates.gates,
              'hardGateDiagnostics': baselineGates.diagnostics,
            },
            'candidate': <String, Object?>{
              'generation': generationArtifact(realWorldCandidateVariant),
              'hardGates': candidateGates.gates,
              'hardGateDiagnostics': candidateGates.diagnostics,
            },
            'judgeStatus': 'skippedBeforeReferenceLoad',
          };
          pairs.add(pair);
          scope.writer.writeJson(
            '${adapterCase.scenarioId}/repetition-$repetition/pair.json',
            pair,
          );
          final Map<String, Object?> manifest = <String, Object?>{
            'schemaVersion': realWorldRunSchemaVersion,
            'runId': invocation.runId,
            'runHash': realWorldRunHash,
            'status': 'rejected',
            'generationFixtureHash': fixture.hash,
            'adapterHash': adapter.hash,
            'baselineSourceCommit': adapter.baselineSourceCommit,
            'requestParameters': adapter.requestParameters.toJson(),
            'requestParametersHash': adapter.requestParameters.hash,
            'judgeRequestContractHash': realWorldJudgeRequestContractHash,
            'judgeReferenceAssetHash': judgeReferenceAssetHash,
            'transportEndpointHash': transportEndpointHash,
            'transportRetryPolicyVersion': transportRetryPolicyVersion,
            'modelMetadata': credentials.safeMetadata(),
            'repetitions': 3,
            'scenarioCount': adapter.cases.length,
            'pairCount': pairs.length,
            'candidateHardGatesPassed': false,
            'failedGateIds': candidateGates.failedGateIds.toList()..sort(),
            'pairs': pairs,
          };
          scope.writer.writeJson('manifest.json', manifest);
          final ScanReport scan =
              context.filter.scanDirectory(context.outputRoot);
          if (!scan.isClean) {
            throw const EvalFailure('postWriteSensitiveScanFailed');
          }
          scope.writer.writeJson('scan.json', scan.toJson());
          scope.writer.writeMarker('_FAILED');
          return CliResult(
            exitCode: 6,
            payload: <String, Object?>{
              'runId': invocation.runId,
              'command': invocation.command,
              'status': 'rejected',
              'pairCount': pairs.length,
              'adapterHash': adapter.hash,
              'failedGateIds': candidateGates.failedGateIds.toList()..sort(),
            },
          );
        }

        // The manifest is generation-safe. The hindsight-bearing asset itself
        // is opened only after both raw generations are gated and the candidate
        // passes. Baseline failures remain judgeable comparison evidence.
        final RealWorldJudgeReference reference = loader.loadJudgeReference(
          manifest: referenceManifest,
        );
        final Map<String, String> blindMapping = realWorldBlindMapping(
          runId: invocation.runId,
          scenarioId: adapterCase.scenarioId,
          repetition: repetition,
        );
        final Map<String, Object?> judgeRequest = buildRealWorldJudgeRequest(
          runId: invocation.runId,
          fixture: fixture,
          reference: reference,
          adapterCase: adapterCase,
          repetition: repetition,
          blindMapping: blindMapping,
          generationContent: generationContent,
        );
        final String judgeRequestHash = sha256Json(judgeRequest);
        try {
          validateModelInputUtf8Size(
            systemPrompt: realWorldJudgeSystemPrompt,
            userPrompt: canonicalJson(judgeRequest),
            byteLimit: judgeInputUtf8ByteLimit,
            errorKind: 'judgeInputTooLarge',
          );
        } on EvalFailure catch (error) {
          return _writeRealWorldStatus(
            invocation: invocation,
            context: context,
            scope: scope,
            adapter: adapter,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            status: 'judgeInputRejected',
            realModelStatus: 'completed',
            errorKind: error.kind,
            exitCode: 6,
            scenarioId: adapterCase.scenarioId,
            repetition: repetition,
            failedVariant: 'judge',
            failedRequestHash: judgeRequestHash,
            failedTransportRequestHash:
                transportRequestHash('judge', judgeRequestHash),
          );
        }
        final ModelCallResult judgeResult = await _modelTransport.call(
          credentials: credentials,
          request: ModelCallRequest(
            systemPrompt: realWorldJudgeSystemPrompt,
            userPrompt: canonicalJson(judgeRequest),
            temperature: 0,
            maxTokens: judgeMaxTokens,
            responseFormat: 'json',
            seed: judgeSeed,
          ),
        );
        if (!judgeResult.completed ||
            judgeResult.content == null ||
            judgeResult.content!.trim().isEmpty) {
          return _writeRealWorldStatus(
            invocation: invocation,
            context: context,
            scope: scope,
            adapter: adapter,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            status: 'judgeFailed',
            realModelStatus: 'failedTransport',
            errorKind: judgeResult.errorKind ?? 'emptyJudgeResponse',
            exitCode: 5,
            scenarioId: adapterCase.scenarioId,
            repetition: repetition,
            failedVariant: 'judge',
            failedRequestHash: judgeRequestHash,
            failedTransportRequestHash:
                transportRequestHash('judge', judgeRequestHash),
            transportResult: judgeResult,
          );
        }
        RealWorldJudgeEvaluation judge;
        try {
          judge = RealWorldJudgeEvaluation.fromContent(
            content: judgeResult.content!,
            reference: reference,
            scenarioId: adapterCase.scenarioId,
            repetition: repetition,
          );
        } on Object {
          return _writeRealWorldStatus(
            invocation: invocation,
            context: context,
            scope: scope,
            adapter: adapter,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            status: 'malformedJudgeResult',
            realModelStatus: 'completed',
            errorKind: 'malformedJudgeResult',
            exitCode: 6,
            scenarioId: adapterCase.scenarioId,
            repetition: repetition,
            failedVariant: 'judge',
            failedRequestHash: judgeRequestHash,
            failedTransportRequestHash:
                transportRequestHash('judge', judgeRequestHash),
            transportResult: judgeResult,
          );
        }

        final Map<String, Object?> pair = <String, Object?>{
          'caseId': fixture.caseId,
          'scenarioId': adapterCase.scenarioId,
          'repetition': repetition,
          'generationOrder': order,
          'blindLabelMapping': blindMapping,
          'baseline': <String, Object?>{
            'generation': generationArtifact(realWorldBaselineVariant),
            'hardGates': baselineGates.gates,
            'hardGateDiagnostics': baselineGates.diagnostics,
          },
          'candidate': <String, Object?>{
            'generation': generationArtifact(realWorldCandidateVariant),
            'hardGates': candidateGates.gates,
            'hardGateDiagnostics': candidateGates.diagnostics,
          },
          'judgeRequestHash': judgeRequestHash,
          'judgeReferenceHash': reference.hash,
          'judgeResponse': judge.raw,
          'scores': <String, Object?>{
            for (final MapEntry<String, RealWorldBlindDimensionScore> entry
                in judge.scores.entries)
              entry.key: entry.value.toJson(),
          },
        };
        pairs.add(pair);
        scope.writer.writeJson(
          '${adapterCase.scenarioId}/repetition-$repetition/pair.json',
          pair,
        );
      }
    }
    final Map<String, Object?> manifest = <String, Object?>{
      'schemaVersion': realWorldRunSchemaVersion,
      'runId': invocation.runId,
      'runHash': realWorldRunHash,
      'status': candidatePassed ? 'passed' : 'rejected',
      'generationFixtureHash': fixture.hash,
      'adapterHash': adapter.hash,
      'baselineSourceCommit': adapter.baselineSourceCommit,
      'requestParameters': adapter.requestParameters.toJson(),
      'requestParametersHash': adapter.requestParameters.hash,
      'judgeRequestContractHash': realWorldJudgeRequestContractHash,
      'judgeReferenceAssetHash': judgeReferenceAssetHash,
      'transportEndpointHash': transportEndpointHash,
      'transportRetryPolicyVersion': transportRetryPolicyVersion,
      'modelMetadata': credentials.safeMetadata(),
      'repetitions': 3,
      'scenarioCount': adapter.cases.length,
      'pairCount': pairs.length,
      'candidateHardGatesPassed': candidatePassed,
      'pairs': pairs,
    };
    scope.writer.writeJson('manifest.json', manifest);
    final ScanReport scan = context.filter.scanDirectory(context.outputRoot);
    if (!scan.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', scan.toJson());
    scope.writer.writeMarker(candidatePassed ? '_SUCCESS' : '_FAILED');
    return CliResult(
      exitCode: candidatePassed ? 0 : 6,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': candidatePassed ? 'passed' : 'rejected',
        'pairCount': pairs.length,
        'adapterHash': adapter.hash,
      },
    );
  }

  CliResult _writeRealWorldStatus({
    required CliInvocation invocation,
    required _EvaluationWorkspace context,
    required _Scope scope,
    required RealWorldEvalAdapter adapter,
    required String judgeReferenceAssetHash,
    required String status,
    required String realModelStatus,
    required String? errorKind,
    required int exitCode,
    String? scenarioId,
    int? repetition,
    String? failedVariant,
    String? failedRequestHash,
    String? failedTransportRequestHash,
    ModelCallResult? transportResult,
  }) {
    scope.writer.writeJson('status.json', <String, Object?>{
      'schemaVersion': realWorldRunSchemaVersion,
      'runId': invocation.runId,
      'status': status,
      'realModelStatus': realModelStatus,
      'errorKind': errorKind,
      'scenarioId': scenarioId,
      'repetition': repetition,
      'failedVariant': failedVariant,
      'failedRequestHash': failedRequestHash,
      'failedTransportRequestHash': failedTransportRequestHash,
      'statusCode': transportResult?.statusCode,
      'retryCount': transportResult?.retryCount,
      'latencyMilliseconds': transportResult?.latencyMilliseconds,
      'seedSupported': transportResult?.seedSupported,
      'adapterHash': adapter.hash,
      'judgeReferenceAssetHash': judgeReferenceAssetHash,
      'transportTimeoutSeconds': context.config.credentials?.timeoutSeconds ??
          defaultTransportTimeoutSeconds,
      'transportRetryPolicyVersion': transportRetryPolicyVersion,
    });
    final ScanReport scan = context.filter.scanDirectory(context.outputRoot);
    if (!scan.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', scan.toJson());
    scope.writer.writeMarker('_BLOCKED');
    return CliResult(
      exitCode: exitCode,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': status,
        'realModelStatus': realModelStatus,
        'errorKind': errorKind,
      },
    );
  }

  CliResult _compare(CliInvocation invocation) {
    _validateRunId(invocation.runId);
    final _EvaluationWorkspace context = _openEvaluationWorkspace(invocation);
    final EvalFixture fixture = _assets.loadCanonicalFixture();
    final EvalRubric rubric = _assets.loadRubric();
    final CanonicalPairContract contract = _loadCanonicalPair(
      context.workspace,
      fixture,
      rubric,
    );
    _loadOfflineManifest(context.workspace, contract);
    final Directory pairedDirectory =
        context.workspace.requireSuccessfulCommandDirectory('paired-model');
    final SafeArtifactReader reader = SafeArtifactReader(root: pairedDirectory);
    final PairedRunArtifact paired = PairedRunArtifact.fromJson(
      reader.readJson('paired_results.json'),
      contract: contract,
      fixture: fixture,
      rubric: rubric,
    );
    HoldoutRevealStore(outputRoot: context.outputRoot).validateReveal(
      runId: invocation.runId,
      candidateHash: contract.candidateHash,
      cohortHash: contract.holdout.cohortHash,
    );
    final ComparisonResult comparison = const EvaluationComparator().compare(
      identity: paired.identity,
      fixture: fixture,
      rubric: rubric,
      pairs: paired.pairs,
    );
    final _Scope scope = context.createScope('compare');
    scope.writer.writeJson('comparison.json', <String, Object?>{
      'schemaVersion': evalArtifactSchemaVersion,
      'runId': invocation.runId,
      'candidateHash': contract.candidateHash,
      'modelMetadata': <String, Object?>{
        'providerLabel': paired.providerLabel,
        'model': paired.model,
        'timeoutSeconds': paired.timeoutSeconds,
      },
      'identity': paired.identity.toJson(),
      'result': comparison.toJson(),
    });
    final ScanReport postWrite =
        context.filter.scanDirectory(context.outputRoot);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', postWrite.toJson());
    if (!context.filter.scanDirectory(context.outputRoot).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    scope.writer.writeMarker(comparison.passed ? '_SUCCESS' : '_FAILED');
    return CliResult(
      exitCode: comparison.passed ? 0 : 6,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': comparison.passed ? 'passed' : 'rejected',
        'candidateHash': contract.candidateHash,
        'runHash': paired.identity.runHash,
        'issues': comparison.issues,
        'repeatableImprovementDimensions':
            comparison.repeatableImprovementDimensions.toList()..sort(),
      },
    );
  }

  CliResult _writePairedStatus({
    required CliInvocation invocation,
    required _EvaluationWorkspace context,
    required _Scope scope,
    required CanonicalPairContract contract,
    required String realModelStatus,
    required String evaluationStatus,
    required String? errorKind,
    required int exitCode,
    String? caseId,
    int? repetition,
  }) {
    scope.writer.writeJson('paired_status.json', <String, Object?>{
      'schemaVersion': evalPairedRunSchemaVersion,
      'runId': invocation.runId,
      'candidateHash': contract.candidateHash,
      'realModelStatus': realModelStatus,
      'evaluationStatus': evaluationStatus,
      'errorKind': errorKind,
      'caseId': caseId,
      'repetition': repetition,
      'baselineRequestSetHash': contract.baseline.requestSetHash,
      'candidateRequestSetHash': contract.candidate.requestSetHash,
      'transportTimeoutSeconds': context.config.credentials?.timeoutSeconds ??
          defaultTransportTimeoutSeconds,
      'transportRetryPolicyVersion': transportRetryPolicyVersion,
    });
    final ScanReport postWrite =
        context.filter.scanDirectory(context.outputRoot);
    if (!postWrite.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', postWrite.toJson());
    if (!context.filter.scanDirectory(context.outputRoot).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
    scope.writer.writeMarker('_BLOCKED');
    return CliResult(
      exitCode: exitCode,
      payload: <String, Object?>{
        'runId': invocation.runId,
        'command': invocation.command,
        'status': evaluationStatus,
        'realModelStatus': realModelStatus,
        'errorKind': errorKind,
      },
    );
  }

  CanonicalPairContract _loadCanonicalPair(
    RunWorkspace workspace,
    EvalFixture fixture,
    EvalRubric rubric,
  ) {
    final SafeArtifactReader reader =
        SafeArtifactReader(root: workspace.directory);
    final CanonicalRequestSet baseline = CanonicalRequestSet.fromJson(
      reader.readJson('prepare-$baselineVariant/request_set.json'),
      expectedRunId: workspace.runId,
      expectedVariant: baselineVariant,
      fixture: fixture,
      rubric: rubric,
    );
    final CanonicalRequestSet candidate = CanonicalRequestSet.fromJson(
      reader.readJson('prepare-$candidateVariant/request_set.json'),
      expectedRunId: workspace.runId,
      expectedVariant: candidateVariant,
      fixture: fixture,
      rubric: rubric,
    );
    final CanonicalEvalAdapter adapter =
        _canonicalAdapterProvider(fixture, rubric);
    final CanonicalRequestSet expectedBaseline = CanonicalRequestSet.create(
      runId: workspace.runId,
      variant: baselineVariant,
      adapter: adapter,
      fixture: fixture,
      rubric: rubric,
    );
    final CanonicalRequestSet expectedCandidate = CanonicalRequestSet.create(
      runId: workspace.runId,
      variant: candidateVariant,
      adapter: adapter,
      fixture: fixture,
      rubric: rubric,
    );
    if (sha256Json(baseline.toJson()) !=
            sha256Json(expectedBaseline.toJson()) ||
        sha256Json(candidate.toJson()) !=
            sha256Json(expectedCandidate.toJson())) {
      throw const EvalFailure('preparedRequestSetDoesNotMatchAdapter');
    }
    return validateCanonicalRequestPair(
      baseline: baseline,
      candidate: candidate,
      fixture: fixture,
    );
  }

  OfflineComparisonManifest _loadOfflineManifest(
    RunWorkspace workspace,
    CanonicalPairContract contract,
  ) {
    final SafeArtifactReader reader =
        SafeArtifactReader(root: workspace.directory);
    return OfflineComparisonManifest.fromJson(
      reader.readJson('compare-offline/offline_comparison.json'),
      contract: contract,
    );
  }

  _EvaluationWorkspace _openEvaluationWorkspace(CliInvocation invocation) {
    final Directory outputRoot = _outputRoot(invocation.output!);
    final ConfigLoadResult config = _configLoader().load();
    if (config.realModelStatus == 'blockedInvalidConfiguration') {
      throw EvalFailure(config.errorKind ?? 'invalidConfiguration');
    }
    final SensitiveDataFilter filter = SensitiveDataFilter(
      knownSensitiveValues:
          config.credentials?.sensitiveValues ?? const <String>{},
    );
    if (!filter.scanDirectory(outputRoot).isClean) {
      throw const EvalFailure('preWriteSensitiveScanFailed');
    }
    return _EvaluationWorkspace(
      outputRoot: outputRoot,
      workspace: RunWorkspace.open(
        outputRoot: outputRoot,
        runId: invocation.runId,
      ),
      config: config,
      filter: filter,
    );
  }

  _Scope _openScope(CliInvocation invocation, String command) {
    final Directory outputRoot = _outputRoot(invocation.output!);
    final ConfigLoadResult config = _configLoader().load();
    if (config.realModelStatus == 'blockedInvalidConfiguration') {
      throw EvalFailure(config.errorKind ?? 'invalidConfiguration');
    }
    final SensitiveDataFilter filter = SensitiveDataFilter(
      knownSensitiveValues:
          config.credentials?.sensitiveValues ?? const <String>{},
    );
    if (!filter.scanDirectory(outputRoot).isClean) {
      throw const EvalFailure('preWriteSensitiveScanFailed');
    }
    final RunWorkspace workspace = RunWorkspace.open(
      outputRoot: outputRoot,
      runId: invocation.runId,
    );
    final Directory directory = workspace.createCommandDirectory(
      command,
      variant: invocation.variant,
    );
    return _Scope(
      directory: directory,
      filter: filter,
      writer: SafeArtifactWriter(root: directory, filter: filter),
    );
  }

  Directory _outputRoot(String output) => OutputPathGuard(
        repositoryRoot: repositoryRoot,
      ).validateAndCreateRoot(output);

  EvalConfigLoader _configLoader() => EvalConfigLoader(
        repositoryRoot: repositoryRoot,
        environment: _environment,
      );

  void _validateRunId(String runId) {
    validateRunId(runId);
  }

  Map<String, Object?> _legacyRequestSet(
    String runId,
    EvalFixture fixture,
    EvalRubric rubric,
    FrozenValidation frozen,
  ) {
    final List<Map<String, Object?>> requests = frozen.requests
        .map(
          (Map<String, Object?> request) => <String, Object?>{
            'requestId': request['requestId'],
            'systemTemplateId': request['systemTemplateId'],
            'analysisTemplateId': request['analysisTemplateId'],
            'systemPrompt': request['systemPrompt'],
            'userPrompt': request['userPrompt'],
            'projectionHash': request['structuredOutputSha256'],
            'caseInputHash': request['structuredOutputSha256'],
            'requestHash': request['requestSha256'],
          },
        )
        .toList(growable: false);
    final String projectionSetHash = sha256Json(<String, Object?>{
      for (final Map<String, Object?> request in requests)
        request['requestId']! as String: request['projectionHash'],
    });
    final String caseInputSetHash = sha256Json(<String, Object?>{
      for (final Map<String, Object?> request in requests)
        request['requestId']! as String: request['caseInputHash'],
    });
    final String requestParametersHash = sha256Json(<String, Object?>{
      'temperature': 0,
      'maxTokens': generationMaxTokens,
      'stream': false,
      'responseFormat': 'text',
      'stop': <Object?>[],
      'seed': generationSeed,
    });
    final String requestSetHash = sha256Json(<String, Object?>{
      for (final Map<String, Object?> request in requests)
        request['requestId']! as String: request['requestHash'],
    });
    final String runHash = sha256Json(<String, Object?>{
      'runId': runId,
      'variant': legacyDiagnosticVariant,
      'fixtureHash': fixture.hash,
      'rubricHash': rubric.hash,
      'projectionSetHash': projectionSetHash,
      'caseInputSetHash': caseInputSetHash,
      'requestParametersHash': requestParametersHash,
      'requestSetHash': requestSetHash,
    });
    return <String, Object?>{
      'schemaVersion': evalRequestSchemaVersion,
      'runId': runId,
      'runHash': runHash,
      'variant': legacyDiagnosticVariant,
      'evaluationPurpose': 'diagnosticOnly',
      'sourceCommit': frozen.sourceCommit,
      'fixtureHash': fixture.hash,
      'rubricHash': rubric.hash,
      'legacyTemplateSetHash': frozen.templatesHash,
      'legacyCaptureHash': frozen.requestsHash,
      'projectionSetHash': projectionSetHash,
      'caseInputSetHash': caseInputSetHash,
      'requestParametersHash': requestParametersHash,
      'requestSetHash': requestSetHash,
      'requests': requests,
    };
  }
}

void validateModelInputUtf8Size({
  required String systemPrompt,
  required String userPrompt,
  required int byteLimit,
  required String errorKind,
}) {
  if (byteLimit <= 0 ||
      utf8.encode(systemPrompt).length + utf8.encode(userPrompt).length >
          byteLimit) {
    throw EvalFailure(errorKind);
  }
}

class _Scope {
  const _Scope({
    required this.directory,
    required this.filter,
    required this.writer,
  });

  final Directory directory;
  final SensitiveDataFilter filter;
  final SafeArtifactWriter writer;
}

class _EvaluationWorkspace {
  const _EvaluationWorkspace({
    required this.outputRoot,
    required this.workspace,
    required this.config,
    required this.filter,
  });

  final Directory outputRoot;
  final RunWorkspace workspace;
  final ConfigLoadResult config;
  final SensitiveDataFilter filter;

  _Scope createScope(String command) {
    final Directory directory = workspace.createCommandDirectory(command);
    return _Scope(
      directory: directory,
      filter: filter,
      writer: SafeArtifactWriter(root: directory, filter: filter),
    );
  }

  _Scope createRetryableScope(String command) {
    final Directory directory =
        workspace.createRetryableCommandDirectory(command);
    return _Scope(
      directory: directory,
      filter: filter,
      writer: SafeArtifactWriter(root: directory, filter: filter),
    );
  }
}
