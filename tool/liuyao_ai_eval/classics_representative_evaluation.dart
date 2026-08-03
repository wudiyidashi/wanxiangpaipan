import 'dart:convert';
import 'dart:io';

import 'assets.dart';
import 'canonical_json.dart';
import 'classics_representative_contract.dart';
import 'classics_representative_raw_hard_gates.dart';
import 'comparison.dart' show DimensionScore, blindLabelMapping;
import 'constants.dart';
import 'hard_gates.dart';
import 'model_transport.dart';
import 'paired_evaluation.dart';
import 'security.dart';

class ClassicsRepresentativeRunResult {
  const ClassicsRepresentativeRunResult({
    required this.exitCode,
    required this.payload,
  });

  final int exitCode;
  final Map<String, Object?> payload;
}

Map<String, Object?> classicsRepresentativeRunIdentity({
  required String runId,
  required ClassicsRepresentativeGenerationFixture fixture,
  required ClassicsRepresentativeAdapter adapter,
  required EvalRubric rubric,
  required String modelHash,
  required String transportEndpointHash,
  required int transportTimeoutSeconds,
  required String judgeReferenceAssetHash,
}) {
  final Map<String, Object?> identity = <String, Object?>{
    'schemaVersion': classicsRepresentativeRunSchemaVersion,
    'runId': runId,
    'caseIds': classicsRepresentativeCaseIds,
    'repetitions': 3,
    'generationFixtureHash': fixture.hash,
    'adapterHash': adapter.hash,
    'rubricHash': rubric.hash,
    'baselineSourceCommit': adapter.baselineSourceCommit,
    'generationInputSetHash': adapter.generationInputSetHash,
    'baselineProjectionSetHash': adapter.baselineProjectionSetHash,
    'candidateProjectionSetHash': adapter.candidateProjectionSetHash,
    'baselineRequestSetHash': adapter.baselineRequestSetHash,
    'candidateRequestSetHash': adapter.candidateRequestSetHash,
    'requestParametersHash': adapter.requestParameters.hash,
    'modelHash': modelHash,
    'judgeModelHash': modelHash,
    'transportEndpointHash': transportEndpointHash,
    'transportTimeoutSeconds': transportTimeoutSeconds,
    'transportRetryPolicyVersion': transportRetryPolicyVersion,
    'transportMaxRetryCount': transportMaxRetryCount,
    'judgeRequestContractHash': judgeRequestContractHash,
    'judgeReferenceAssetHash': judgeReferenceAssetHash,
  };
  return <String, Object?>{
    ...identity,
    'runHash': sha256Json(identity),
  };
}

class ClassicsRepresentativeEvaluationRunner {
  ClassicsRepresentativeEvaluationRunner({
    required this.repositoryRoot,
    required this.environment,
    required this.modelTransport,
    EvalAssets? assets,
    ClassicsRepresentativeAssetLoader? assetLoader,
  })  : assets = assets ?? EvalAssets(repositoryRoot),
        assetLoader =
            assetLoader ?? ClassicsRepresentativeAssetLoader(repositoryRoot);

  final String repositoryRoot;
  final Map<String, String>? environment;
  final EvalModelTransport modelTransport;
  final EvalAssets assets;
  final ClassicsRepresentativeAssetLoader assetLoader;

  Future<ClassicsRepresentativeRunResult> run({
    required String runId,
    required String output,
    required int repetitions,
  }) async {
    validateRunId(runId);
    if (repetitions != 3) {
      throw const EvalFailure('exactlyThreeRepetitionsRequired');
    }
    final ConfigLoadResult config = EvalConfigLoader(
      repositoryRoot: repositoryRoot,
      environment: environment,
    ).load();
    if (config.realModelStatus == 'blockedInvalidConfiguration') {
      throw EvalFailure(config.errorKind ?? 'invalidConfiguration');
    }
    final SensitiveDataFilter filter = SensitiveDataFilter(
      knownSensitiveValues:
          config.credentials?.sensitiveValues ?? const <String>{},
    );
    final Directory outputRoot = OutputPathGuard(
      repositoryRoot: repositoryRoot,
    ).validateAndCreateRoot(output);
    final RunWorkspace workspace = RunWorkspace.open(
      outputRoot: outputRoot,
      runId: runId,
    );
    if (!filter.scanDirectory(workspace.directory).isClean) {
      throw const EvalFailure('preWriteSensitiveScanFailed');
    }

    final ClassicsRepresentativeAssetLoader loader = assetLoader;
    final ClassicsRepresentativeGenerationFixture fixture =
        loader.loadGenerationFixture();
    final ClassicsRepresentativeAdapter adapter = loader.loadAdapter(fixture);
    final EvalRubric rubric = assets.loadRubric();
    if (rubric.hardGateIds.length != hardGateIds.length ||
        !rubric.hardGateIds.containsAll(hardGateIds)) {
      throw const EvalFailure('representativeHardGateContractMismatch');
    }
    final ClassicsRepresentativeJudgeReferenceManifest referenceManifest =
        loader.loadJudgeReferenceManifest();
    final String judgeReferenceAssetHash =
        referenceManifest.referenceAssetSha256;
    for (final ClassicsRepresentativeAdapterCase item in adapter.cases) {
      for (final ClassicsRepresentativePromptVariant variant
          in <ClassicsRepresentativePromptVariant>[
        item.baseline,
        item.candidate,
      ]) {
        validateRepresentativeModelInputUtf8Size(
          systemPrompt: variant.systemPrompt,
          userPrompt: variant.userPrompt,
          byteLimit: generationInputUtf8ByteLimit,
          errorKind: 'generationInputTooLarge',
        );
      }
    }

    if (config.realModelStatus != 'ready' || config.credentials == null) {
      final _RepresentativeScope scope = _createRetryableScope(
        workspace,
        filter,
      );
      return _writeStatus(
        runId: runId,
        workspace: workspace,
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
    final Map<String, Object?> identity = classicsRepresentativeRunIdentity(
      runId: runId,
      fixture: fixture,
      adapter: adapter,
      rubric: rubric,
      modelHash: sha256Text(credentials.model),
      transportEndpointHash: transportEndpointHash,
      transportTimeoutSeconds: credentials.timeoutSeconds,
      judgeReferenceAssetHash: judgeReferenceAssetHash,
    );
    workspace.bindRetryIdentity(
      command: classicsRepresentativeCommand,
      identityHash: requireRepresentativeSha256(identity, 'runHash'),
      identity: identity,
    );
    final _RepresentativeScope scope = _createRetryableScope(
      workspace,
      filter,
    );

    String transportRequestHash(String kind, String frozenRequestHash) {
      return sha256Json(<String, Object?>{
        'kind': kind,
        'frozenRequestHash': frozenRequestHash,
        'modelHash': sha256Text(credentials.model),
        'transportEndpointHash': transportEndpointHash,
        'transportTimeoutSeconds': credentials.timeoutSeconds,
        'transportRetryPolicyVersion': transportRetryPolicyVersion,
        'requestContractHash': kind == 'judge'
            ? judgeRequestContractHash
            : adapter.requestParameters.hash,
      });
    }

    final List<Map<String, Object?>> pairs = <Map<String, Object?>>[];
    for (final ClassicsRepresentativeAdapterCase adapterCase in adapter.cases) {
      for (int repetition = 1; repetition <= repetitions; repetition++) {
        final List<String> generationOrder = pairedGenerationOrder(
          runId: runId,
          caseId: adapterCase.caseId,
          repetition: repetition,
        ).map((variant) {
          return variant == baselineVariant
              ? classicsRepresentativeBaselineVariant
              : classicsRepresentativeCandidateVariant;
        }).toList(growable: false);
        final Map<String, ModelCallResult> generationResults =
            <String, ModelCallResult>{};
        final Map<String, String> generationContent = <String, String>{};
        for (final String variant in generationOrder) {
          final ClassicsRepresentativePromptVariant request =
              variant == classicsRepresentativeBaselineVariant
                  ? adapterCase.baseline
                  : adapterCase.candidate;
          final ModelCallResult result = await modelTransport.call(
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
            return _writeStatus(
              runId: runId,
              workspace: workspace,
              scope: scope,
              adapter: adapter,
              judgeReferenceAssetHash: judgeReferenceAssetHash,
              status: 'generationFailed',
              realModelStatus: 'failedTransport',
              errorKind: result.errorKind ?? 'emptyGenerationResponse',
              exitCode: 5,
              caseId: adapterCase.caseId,
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

        Map<String, Object?> rawGenerationArtifact(String variant) {
          final ModelCallResult result = generationResults[variant]!;
          final ClassicsRepresentativePromptVariant request =
              variant == classicsRepresentativeBaselineVariant
                  ? adapterCase.baseline
                  : adapterCase.candidate;
          return <String, Object?>{
            'requestHash': request.requestHash,
            'transportRequestHash': transportRequestHash(
              'generation',
              request.requestHash,
            ),
            'content': result.content,
            'tokensUsed': result.tokensUsed,
            'latencyMilliseconds': result.latencyMilliseconds,
            'seedSupported': result.seedSupported,
            'statusCode': result.statusCode,
            'retryCount': result.retryCount,
          };
        }

        final ClassicsRepresentativeRawHardGateResult candidateRawGates =
            const ClassicsRepresentativeRawHardGateEvaluator().evaluate(
          adapterCase: adapterCase,
          rawOutput: generationContent[classicsRepresentativeCandidateVariant]!,
        );
        if (!candidateRawGates.passed) {
          final Map<String, Object?> pair = <String, Object?>{
            'caseId': adapterCase.caseId,
            'repetition': repetition,
            'generationOrder': generationOrder,
            'baseline': <String, Object?>{
              'generation': rawGenerationArtifact(
                classicsRepresentativeBaselineVariant,
              ),
            },
            'candidate': <String, Object?>{
              'generation': rawGenerationArtifact(
                classicsRepresentativeCandidateVariant,
              ),
              'rawHardGates': candidateRawGates.gates,
            },
            'judgeStatus': 'skippedBeforeReferenceLoad',
          };
          pairs.add(pair);
          scope.writer.writeJson(
            '${adapterCase.caseId}/repetition-$repetition/pair.json',
            pair,
          );
          return _writeRawRejected(
            runId: runId,
            workspace: workspace,
            scope: scope,
            fixture: fixture,
            adapter: adapter,
            rubric: rubric,
            credentials: credentials,
            identity: identity,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            pairs: pairs,
            failedGateIds: candidateRawGates.failedGateIds,
          );
        }

        final ClassicsRepresentativeJudgeReference reference =
            loader.loadJudgeReference(
          generationFixture: fixture,
          manifest: referenceManifest,
        );
        final EvalCase evalCase = reference.caseById(adapterCase.caseId);
        final Map<String, String> blindMapping = blindLabelMapping(
          runId: runId,
          caseId: adapterCase.caseId,
          repetition: repetition,
        );
        final Map<String, String> canonicalGenerationContent = <String, String>{
          baselineVariant:
              generationContent[classicsRepresentativeBaselineVariant]!,
          candidateVariant:
              generationContent[classicsRepresentativeCandidateVariant]!,
        };
        final Map<String, Object?> judgeRequest = buildJudgeRequest(
          runId: runId,
          evalCase: evalCase,
          repetition: repetition,
          rubric: rubric,
          blindMapping: blindMapping,
          generationContentByVariant: canonicalGenerationContent,
        );
        final String judgeRequestHash = sha256Json(judgeRequest);
        try {
          validateRepresentativeModelInputUtf8Size(
            systemPrompt: judgeSystemPrompt,
            userPrompt: canonicalJson(judgeRequest),
            byteLimit: judgeInputUtf8ByteLimit,
            errorKind: 'judgeInputTooLarge',
          );
        } on EvalFailure catch (error) {
          return _writeStatus(
            runId: runId,
            workspace: workspace,
            scope: scope,
            adapter: adapter,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            status: 'judgeInputRejected',
            realModelStatus: 'completed',
            errorKind: error.kind,
            exitCode: 6,
            caseId: adapterCase.caseId,
            repetition: repetition,
            failedVariant: 'judge',
            failedRequestHash: judgeRequestHash,
            failedTransportRequestHash:
                transportRequestHash('judge', judgeRequestHash),
          );
        }
        final ModelCallResult judgeResult = await modelTransport.call(
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
          return _writeStatus(
            runId: runId,
            workspace: workspace,
            scope: scope,
            adapter: adapter,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            status: 'judgeFailed',
            realModelStatus: 'failedTransport',
            errorKind: judgeResult.errorKind ?? 'emptyJudgeResponse',
            exitCode: 5,
            caseId: adapterCase.caseId,
            repetition: repetition,
            failedVariant: 'judge',
            failedRequestHash: judgeRequestHash,
            failedTransportRequestHash:
                transportRequestHash('judge', judgeRequestHash),
            transportResult: judgeResult,
          );
        }

        JudgeEvaluation judge;
        try {
          judge = JudgeEvaluation.fromContent(
            content: judgeResult.content!,
            caseId: adapterCase.caseId,
            repetition: repetition,
            rubric: rubric,
          );
        } on Object {
          return _writeStatus(
            runId: runId,
            workspace: workspace,
            scope: scope,
            adapter: adapter,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            status: 'malformedJudgeResult',
            realModelStatus: 'completed',
            errorKind: 'malformedJudgeResult',
            exitCode: 6,
            caseId: adapterCase.caseId,
            repetition: repetition,
            failedVariant: 'judge',
            failedRequestHash: judgeRequestHash,
            failedTransportRequestHash:
                transportRequestHash('judge', judgeRequestHash),
            transportResult: judgeResult,
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

        Map<String, Object?> generationArtifact(
          String representativeVariant,
          String canonicalVariant,
          NormalizedModelOutput normalized,
        ) {
          final ModelCallResult result =
              generationResults[representativeVariant]!;
          return <String, Object?>{
            'requestHash':
                representativeVariant == classicsRepresentativeBaselineVariant
                    ? adapterCase.baseline.requestHash
                    : adapterCase.candidate.requestHash,
            'transportRequestHash': transportRequestHash(
              'generation',
              representativeVariant == classicsRepresentativeBaselineVariant
                  ? adapterCase.baseline.requestHash
                  : adapterCase.candidate.requestHash,
            ),
            ...generationArtifactJson(
              result: result,
              normalized: normalized,
              logicalRequestId: sha256Text(
                '$runId\n${adapterCase.caseId}\n$repetition\n$canonicalVariant',
              ),
              orderIndex: generationOrder.indexOf(representativeVariant),
            ),
          };
        }

        final Map<String, DimensionScore> scores =
            judge.dimensionScores(blindMapping);
        final Map<String, Object?> pair = <String, Object?>{
          'caseId': adapterCase.caseId,
          'repetition': repetition,
          'generationOrder': generationOrder,
          'blindLabelMapping': blindMapping,
          'baseline': <String, Object?>{
            'generation': generationArtifact(
              classicsRepresentativeBaselineVariant,
              baselineVariant,
              baselineNormalized,
            ),
            'hardGates': baselineGates.gates,
          },
          'candidate': <String, Object?>{
            'generation': generationArtifact(
              classicsRepresentativeCandidateVariant,
              candidateVariant,
              candidateNormalized,
            ),
            'rawHardGates': candidateRawGates.gates,
            'hardGates': candidateGates.gates,
            'referenceHardGates': candidateGates.gates,
          },
          'judgeRequestHash': judgeRequestHash,
          'judgeReferenceHash': reference.hash,
          'judgeResponse': judge.rawResponse,
          'scores': <String, Object?>{
            for (final entry in scores.entries) entry.key: entry.value.toJson(),
          },
        };
        pairs.add(pair);
        scope.writer.writeJson(
          '${adapterCase.caseId}/repetition-$repetition/pair.json',
          pair,
        );
        if (!candidateGates.passed) {
          return _writeRejected(
            runId: runId,
            workspace: workspace,
            scope: scope,
            fixture: fixture,
            adapter: adapter,
            rubric: rubric,
            credentials: credentials,
            identity: identity,
            judgeReferenceAssetHash: judgeReferenceAssetHash,
            pairs: pairs,
            failedGateIds: candidateGates.failedGateIds,
          );
        }
      }
    }

    final Map<String, Object?> manifest = _manifest(
      runId: runId,
      fixture: fixture,
      adapter: adapter,
      rubric: rubric,
      credentials: credentials,
      identity: identity,
      judgeReferenceAssetHash: judgeReferenceAssetHash,
      status: 'passed',
      pairs: pairs,
      candidateHardGatesPassed: true,
      candidateRawHardGatesPassed: true,
      candidateReferenceHardGatesPassed: true,
      failedGateIds: const <String>{},
    );
    scope.writer.writeJson('manifest.json', manifest);
    _writeCleanScan(workspace, scope);
    scope.writer.writeMarker('_SUCCESS');
    return ClassicsRepresentativeRunResult(
      exitCode: 0,
      payload: <String, Object?>{
        'runId': runId,
        'command': classicsRepresentativeCommand,
        'status': 'passed',
        'pairCount': pairs.length,
        'adapterHash': adapter.hash,
        'runHash': identity['runHash'],
      },
    );
  }

  ClassicsRepresentativeRunResult _writeRejected({
    required String runId,
    required RunWorkspace workspace,
    required _RepresentativeScope scope,
    required ClassicsRepresentativeGenerationFixture fixture,
    required ClassicsRepresentativeAdapter adapter,
    required EvalRubric rubric,
    required EvalCredentials credentials,
    required Map<String, Object?> identity,
    required String judgeReferenceAssetHash,
    required List<Map<String, Object?>> pairs,
    required Set<String> failedGateIds,
  }) {
    scope.writer.writeJson(
      'manifest.json',
      _manifest(
        runId: runId,
        fixture: fixture,
        adapter: adapter,
        rubric: rubric,
        credentials: credentials,
        identity: identity,
        judgeReferenceAssetHash: judgeReferenceAssetHash,
        status: 'rejected',
        pairs: pairs,
        candidateHardGatesPassed: false,
        candidateRawHardGatesPassed: true,
        candidateReferenceHardGatesPassed: false,
        failedGateIds: failedGateIds,
      ),
    );
    _writeCleanScan(workspace, scope);
    scope.writer.writeMarker('_FAILED');
    return ClassicsRepresentativeRunResult(
      exitCode: 6,
      payload: <String, Object?>{
        'runId': runId,
        'command': classicsRepresentativeCommand,
        'status': 'rejected',
        'pairCount': pairs.length,
        'adapterHash': adapter.hash,
        'failedGateIds': failedGateIds.toList()..sort(),
      },
    );
  }

  ClassicsRepresentativeRunResult _writeRawRejected({
    required String runId,
    required RunWorkspace workspace,
    required _RepresentativeScope scope,
    required ClassicsRepresentativeGenerationFixture fixture,
    required ClassicsRepresentativeAdapter adapter,
    required EvalRubric rubric,
    required EvalCredentials credentials,
    required Map<String, Object?> identity,
    required String judgeReferenceAssetHash,
    required List<Map<String, Object?>> pairs,
    required Set<String> failedGateIds,
  }) {
    scope.writer.writeJson(
      'manifest.json',
      _manifest(
        runId: runId,
        fixture: fixture,
        adapter: adapter,
        rubric: rubric,
        credentials: credentials,
        identity: identity,
        judgeReferenceAssetHash: judgeReferenceAssetHash,
        status: 'rejected',
        pairs: pairs,
        candidateHardGatesPassed: false,
        candidateRawHardGatesPassed: false,
        candidateReferenceHardGatesPassed: null,
        failedGateIds: failedGateIds,
      ),
    );
    _writeCleanScan(workspace, scope);
    scope.writer.writeMarker('_FAILED');
    return ClassicsRepresentativeRunResult(
      exitCode: 6,
      payload: <String, Object?>{
        'runId': runId,
        'command': classicsRepresentativeCommand,
        'status': 'rejected',
        'pairCount': pairs.length,
        'adapterHash': adapter.hash,
        'failedGateIds': failedGateIds.toList()..sort(),
      },
    );
  }

  Map<String, Object?> _manifest({
    required String runId,
    required ClassicsRepresentativeGenerationFixture fixture,
    required ClassicsRepresentativeAdapter adapter,
    required EvalRubric rubric,
    required EvalCredentials credentials,
    required Map<String, Object?> identity,
    required String judgeReferenceAssetHash,
    required String status,
    required List<Map<String, Object?>> pairs,
    required bool candidateHardGatesPassed,
    required bool candidateRawHardGatesPassed,
    required bool? candidateReferenceHardGatesPassed,
    required Set<String> failedGateIds,
  }) =>
      <String, Object?>{
        'schemaVersion': classicsRepresentativeRunSchemaVersion,
        'runId': runId,
        'runHash': identity['runHash'],
        'status': status,
        'caseIds': classicsRepresentativeCaseIds,
        'repetitions': 3,
        'caseCount': fixture.cases.length,
        'pairCount': pairs.length,
        'generationFixtureHash': fixture.hash,
        'adapterHash': adapter.hash,
        'rubricHash': rubric.hash,
        'baselineSourceCommit': adapter.baselineSourceCommit,
        'requestParameters': adapter.requestParameters.toJson(),
        'requestParametersHash': adapter.requestParameters.hash,
        'judgeRequestContractHash': judgeRequestContractHash,
        'judgeReferenceAssetHash': judgeReferenceAssetHash,
        'transportRetryPolicyVersion': transportRetryPolicyVersion,
        'modelMetadata': credentials.safeMetadata(),
        'candidateProductionIdentity': adapter.cases.first.candidate.metadata,
        'hardGateIds': hardGateIds.toList()..sort(),
        'rawHardGateIds': classicsRepresentativeRawHardGateIds.toList()..sort(),
        'candidateHardGatesPassed': candidateHardGatesPassed,
        'candidateRawHardGatesPassed': candidateRawHardGatesPassed,
        'candidateReferenceHardGatesPassed': candidateReferenceHardGatesPassed,
        'failedGateIds': failedGateIds.toList()..sort(),
        'pairs': pairs,
      };

  ClassicsRepresentativeRunResult _writeStatus({
    required String runId,
    required RunWorkspace workspace,
    required _RepresentativeScope scope,
    required ClassicsRepresentativeAdapter adapter,
    required String judgeReferenceAssetHash,
    required String status,
    required String realModelStatus,
    required String? errorKind,
    required int exitCode,
    String? caseId,
    int? repetition,
    String? failedVariant,
    String? failedRequestHash,
    String? failedTransportRequestHash,
    ModelCallResult? transportResult,
  }) {
    scope.writer.writeJson('status.json', <String, Object?>{
      'schemaVersion': classicsRepresentativeRunSchemaVersion,
      'runId': runId,
      'status': status,
      'realModelStatus': realModelStatus,
      'errorKind': errorKind,
      'caseId': caseId,
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
      'transportRetryPolicyVersion': transportRetryPolicyVersion,
    });
    _writeCleanScan(workspace, scope);
    scope.writer.writeMarker('_BLOCKED');
    return ClassicsRepresentativeRunResult(
      exitCode: exitCode,
      payload: <String, Object?>{
        'runId': runId,
        'command': classicsRepresentativeCommand,
        'status': status,
        'realModelStatus': realModelStatus,
        'errorKind': errorKind,
      },
    );
  }

  _RepresentativeScope _createRetryableScope(
    RunWorkspace workspace,
    SensitiveDataFilter filter,
  ) {
    final Directory directory = workspace.createRetryableCommandDirectory(
      classicsRepresentativeCommand,
    );
    return _RepresentativeScope(
      directory: directory,
      writer: SafeArtifactWriter(root: directory, filter: filter),
      filter: filter,
    );
  }

  void _writeCleanScan(
    RunWorkspace workspace,
    _RepresentativeScope scope,
  ) {
    final ScanReport scan = scope.filter.scanDirectory(workspace.directory);
    if (!scan.isClean) {
      throw const EvalFailure('postWriteSensitiveScanFailed');
    }
    scope.writer.writeJson('scan.json', scan.toJson());
    if (!scope.filter.scanDirectory(workspace.directory).isClean) {
      throw const EvalFailure('postReportSensitiveScanFailed');
    }
  }
}

class _RepresentativeScope {
  const _RepresentativeScope({
    required this.directory,
    required this.writer,
    required this.filter,
  });

  final Directory directory;
  final SafeArtifactWriter writer;
  final SensitiveDataFilter filter;
}

void validateRepresentativeModelInputUtf8Size({
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
