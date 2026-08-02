import 'dart:io';

import 'assets.dart';
import 'canonical_json.dart';
import 'constants.dart';
import 'security.dart';

typedef CanonicalAdapterProvider = CanonicalEvalAdapter Function(
  EvalFixture fixture,
  EvalRubric rubric,
);

class GenerationRequestParameters {
  const GenerationRequestParameters();

  factory GenerationRequestParameters.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'stream',
        'temperature',
        'maxTokens',
        'responseFormat',
        'stop',
        'seed',
      },
    );
    if (requireBool(json, 'stream') ||
        requireInt(json, 'temperature') != 0 ||
        requireInt(json, 'maxTokens') != generationMaxTokens ||
        requireString(json, 'responseFormat') != 'text' ||
        requireList(json, 'stop').isNotEmpty ||
        requireInt(json, 'seed') != generationSeed) {
      throw const FormatException(
        'Canonical generation request parameters changed.',
      );
    }
    return const GenerationRequestParameters();
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'stream': false,
        'temperature': 0,
        'maxTokens': generationMaxTokens,
        'responseFormat': 'text',
        'stop': <Object?>[],
        'seed': generationSeed,
      };

  String get hash => sha256Json(toJson());
}

class CanonicalAssemblyVariant {
  const CanonicalAssemblyVariant({
    required this.systemTemplateId,
    required this.analysisTemplateId,
    required this.promptPolicyVersion,
    required this.systemPrompt,
    required this.userPrompt,
  });

  final String systemTemplateId;
  final String analysisTemplateId;
  final String promptPolicyVersion;
  final String systemPrompt;
  final String userPrompt;

  factory CanonicalAssemblyVariant.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'systemTemplateId',
        'analysisTemplateId',
        'promptPolicyVersion',
        'systemPrompt',
        'userPrompt',
      },
    );
    return CanonicalAssemblyVariant(
      systemTemplateId: requireString(json, 'systemTemplateId'),
      analysisTemplateId: requireString(json, 'analysisTemplateId'),
      promptPolicyVersion: requireString(json, 'promptPolicyVersion'),
      systemPrompt: requireString(json, 'systemPrompt'),
      userPrompt: requireString(json, 'userPrompt'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'systemTemplateId': systemTemplateId,
        'analysisTemplateId': analysisTemplateId,
        'promptPolicyVersion': promptPolicyVersion,
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
      };
}

class CanonicalAdapterCase {
  const CanonicalAdapterCase({
    required this.caseId,
    required this.caseInputHash,
    required this.projectionHash,
    required this.variants,
  });

  final String caseId;
  final String caseInputHash;
  final String projectionHash;
  final Map<String, CanonicalAssemblyVariant> variants;

  factory CanonicalAdapterCase.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{'caseId', 'caseInputHash', 'projectionHash', 'variants'},
    );
    final Map<String, Object?> variants = requireObject(json, 'variants');
    requireExactKeys(variants, <String>{baselineVariant, candidateVariant});
    return CanonicalAdapterCase(
      caseId: requireString(json, 'caseId'),
      caseInputHash: requireSha256(json, 'caseInputHash'),
      projectionHash: requireSha256(json, 'projectionHash'),
      variants: Map<String, CanonicalAssemblyVariant>.unmodifiable(
        <String, CanonicalAssemblyVariant>{
          for (final String variant in <String>[
            baselineVariant,
            candidateVariant,
          ])
            variant: CanonicalAssemblyVariant.fromJson(
              (variants[variant]! as Map).cast<String, Object?>(),
            ),
        },
      ),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'caseId': caseId,
        'caseInputHash': caseInputHash,
        'projectionHash': projectionHash,
        'variants': <String, Object?>{
          for (final String variant in <String>[
            baselineVariant,
            candidateVariant,
          ])
            variant: variants[variant]!.toJson(),
        },
      };
}

class CanonicalEvalAdapter {
  const CanonicalEvalAdapter({
    required this.fixtureHash,
    required this.rubricHash,
    required this.projectionSchemaVersion,
    required this.ruleSetId,
    required this.ruleSetVersion,
    required this.requestParameters,
    required this.cases,
    required this.hash,
    required this.sourceFixtureVersion,
    required this.sourceFixtureHash,
  });

  final String fixtureHash;
  final String rubricHash;
  final String projectionSchemaVersion;
  final String ruleSetId;
  final String ruleSetVersion;
  final GenerationRequestParameters requestParameters;
  final List<CanonicalAdapterCase> cases;
  final String hash;
  final String sourceFixtureVersion;
  final String sourceFixtureHash;

  factory CanonicalEvalAdapter.fromJson(
    Map<String, Object?> json, {
    required EvalFixture fixture,
    required EvalRubric rubric,
  }) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'fixtureHash',
        'rubricHash',
        'projectionSchemaVersion',
        'ruleSetId',
        'ruleSetVersion',
        'requestParameters',
        'cases',
        'sourceFixtureVersion',
        'sourceFixtureHash',
      },
    );
    if (requireString(json, 'schemaVersion') !=
            evalCanonicalAdapterSchemaVersion ||
        requireSha256(json, 'fixtureHash') != fixture.hash ||
        requireSha256(json, 'rubricHash') != rubric.hash ||
        requireString(json, 'projectionSchemaVersion') !=
            canonicalProjectionSchemaVersion ||
        fixture.projectionSchemaVersion != canonicalProjectionSchemaVersion ||
        requireString(json, 'ruleSetId') != canonicalRuleSetId ||
        requireString(json, 'ruleSetVersion') != canonicalRuleSetVersion ||
        requireString(json, 'sourceFixtureVersion') !=
            fixture.sourceFixtureVersion ||
        requireSha256(json, 'sourceFixtureHash') != fixture.sourceFixtureHash) {
      throw const FormatException('Canonical adapter identity mismatch.');
    }
    final List<CanonicalAdapterCase> cases = requireList(json, 'cases')
        .map(
          (Object? value) => CanonicalAdapterCase.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    final List<String> expectedIds = fixture.cases
        .map((EvalCase evalCase) => evalCase.caseId)
        .toList(growable: false);
    final List<String> actualIds = cases
        .map((CanonicalAdapterCase evalCase) => evalCase.caseId)
        .toList(growable: false);
    if (!_listEquals(expectedIds, actualIds)) {
      throw const FormatException('Canonical adapter case order mismatch.');
    }
    for (int index = 0; index < cases.length; index += 1) {
      final EvalCase evalCase = fixture.cases[index];
      final CanonicalAdapterCase adapterCase = cases[index];
      final Map<String, Object?> projection =
          requireObject(evalCase.requestInput, 'projection');
      if (adapterCase.caseInputHash != sha256Json(evalCase.requestInput) ||
          adapterCase.projectionHash != sha256Json(projection)) {
        throw const FormatException(
          'Canonical adapter projection or case input hash mismatch.',
        );
      }
    }
    return CanonicalEvalAdapter(
      fixtureHash: fixture.hash,
      rubricHash: rubric.hash,
      projectionSchemaVersion: canonicalProjectionSchemaVersion,
      ruleSetId: canonicalRuleSetId,
      ruleSetVersion: canonicalRuleSetVersion,
      requestParameters: GenerationRequestParameters.fromJson(
        requireObject(json, 'requestParameters'),
      ),
      cases: List<CanonicalAdapterCase>.unmodifiable(cases),
      hash: sha256Json(json),
      sourceFixtureVersion: requireString(json, 'sourceFixtureVersion'),
      sourceFixtureHash: requireSha256(json, 'sourceFixtureHash'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': evalCanonicalAdapterSchemaVersion,
        'fixtureHash': fixtureHash,
        'rubricHash': rubricHash,
        'projectionSchemaVersion': projectionSchemaVersion,
        'ruleSetId': ruleSetId,
        'ruleSetVersion': ruleSetVersion,
        'requestParameters': requestParameters.toJson(),
        'cases': cases
            .map((CanonicalAdapterCase evalCase) => evalCase.toJson())
            .toList(growable: false),
        'sourceFixtureVersion': sourceFixtureVersion,
        'sourceFixtureHash': sourceFixtureHash,
      };
}

class CanonicalAdapterFileLoader {
  const CanonicalAdapterFileLoader({required this.repositoryRoot});

  final String repositoryRoot;

  CanonicalEvalAdapter load(EvalFixture fixture, EvalRubric rubric) {
    final Map<String, Object?> json;
    try {
      json = SafeArtifactReader(root: Directory(repositoryRoot)).readJson(
        evalCanonicalAdapterRelativePath,
      );
    } on EvalFailure catch (error) {
      if (error.kind == 'requiredArtifactMissingOrInvalid') {
        throw const EvalFailure('canonicalV2AdapterMissing');
      }
      rethrow;
    }
    if (json.isEmpty) {
      throw const EvalFailure('canonicalV2AdapterMissing');
    }
    final CanonicalEvalAdapter adapter = CanonicalEvalAdapter.fromJson(
      json,
      fixture: fixture,
      rubric: rubric,
    );
    if (adapter.hash != canonicalV2AdapterHash) {
      throw const EvalFailure('canonicalV2AdapterHashMismatch');
    }
    return adapter;
  }
}

class CanonicalPreparedRequest {
  const CanonicalPreparedRequest({
    required this.caseId,
    required this.caseKind,
    required this.evaluationSplit,
    required this.cohortIds,
    required this.caseInput,
    required this.caseInputHash,
    required this.projectionHash,
    required this.systemTemplateId,
    required this.analysisTemplateId,
    required this.promptPolicyVersion,
    required this.systemPrompt,
    required this.userPrompt,
    required this.requestHash,
  });

  final String caseId;
  final String caseKind;
  final String evaluationSplit;
  final List<String> cohortIds;
  final Map<String, Object?> caseInput;
  final String caseInputHash;
  final String projectionHash;
  final String systemTemplateId;
  final String analysisTemplateId;
  final String promptPolicyVersion;
  final String systemPrompt;
  final String userPrompt;
  final String requestHash;

  factory CanonicalPreparedRequest.create({
    required String variant,
    required EvalCase evalCase,
    required CanonicalAdapterCase adapterCase,
    required String requestParametersHash,
  }) {
    final CanonicalAssemblyVariant assembly = adapterCase.variants[variant]!;
    final CanonicalPreparedRequest request = CanonicalPreparedRequest(
      caseId: evalCase.caseId,
      caseKind: evalCase.caseKind,
      evaluationSplit: evalCase.evaluationSplit,
      cohortIds: evalCase.cohortIds.toList()..sort(),
      caseInput: evalCase.requestInput,
      caseInputHash: adapterCase.caseInputHash,
      projectionHash: adapterCase.projectionHash,
      systemTemplateId: assembly.systemTemplateId,
      analysisTemplateId: assembly.analysisTemplateId,
      promptPolicyVersion: assembly.promptPolicyVersion,
      systemPrompt: assembly.systemPrompt,
      userPrompt: assembly.userPrompt,
      requestHash: '',
    );
    return request._withRequestHash(
      canonicalPreparedRequestHash(
        variant: variant,
        request: request,
        requestParametersHash: requestParametersHash,
      ),
    );
  }

  factory CanonicalPreparedRequest.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'caseId',
        'caseKind',
        'evaluationSplit',
        'cohortIds',
        'caseInput',
        'caseInputHash',
        'projectionHash',
        'systemTemplateId',
        'analysisTemplateId',
        'promptPolicyVersion',
        'systemPrompt',
        'userPrompt',
        'requestHash',
      },
    );
    return CanonicalPreparedRequest(
      caseId: requireString(json, 'caseId'),
      caseKind: requireString(json, 'caseKind'),
      evaluationSplit: requireString(json, 'evaluationSplit'),
      cohortIds: requireStringList(json, 'cohortIds'),
      caseInput: Map<String, Object?>.unmodifiable(
        requireObject(json, 'caseInput'),
      ),
      caseInputHash: requireSha256(json, 'caseInputHash'),
      projectionHash: requireSha256(json, 'projectionHash'),
      systemTemplateId: requireString(json, 'systemTemplateId'),
      analysisTemplateId: requireString(json, 'analysisTemplateId'),
      promptPolicyVersion: requireString(json, 'promptPolicyVersion'),
      systemPrompt: requireString(json, 'systemPrompt'),
      userPrompt: requireString(json, 'userPrompt'),
      requestHash: requireSha256(json, 'requestHash'),
    );
  }

  CanonicalPreparedRequest _withRequestHash(String value) =>
      CanonicalPreparedRequest(
        caseId: caseId,
        caseKind: caseKind,
        evaluationSplit: evaluationSplit,
        cohortIds: cohortIds,
        caseInput: caseInput,
        caseInputHash: caseInputHash,
        projectionHash: projectionHash,
        systemTemplateId: systemTemplateId,
        analysisTemplateId: analysisTemplateId,
        promptPolicyVersion: promptPolicyVersion,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        requestHash: value,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'caseId': caseId,
        'caseKind': caseKind,
        'evaluationSplit': evaluationSplit,
        'cohortIds': cohortIds,
        'caseInput': caseInput,
        'caseInputHash': caseInputHash,
        'projectionHash': projectionHash,
        'systemTemplateId': systemTemplateId,
        'analysisTemplateId': analysisTemplateId,
        'promptPolicyVersion': promptPolicyVersion,
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'requestHash': requestHash,
      };
}

class CanonicalRequestSet {
  const CanonicalRequestSet({
    required this.runId,
    required this.variant,
    required this.adapterHash,
    required this.fixtureHash,
    required this.rubricHash,
    required this.projectionSchemaVersion,
    required this.ruleSetId,
    required this.ruleSetVersion,
    required this.requestParameters,
    required this.requestParametersHash,
    required this.projectionSetHash,
    required this.caseInputSetHash,
    required this.requestSetHash,
    required this.requests,
  });

  final String runId;
  final String variant;
  final String adapterHash;
  final String fixtureHash;
  final String rubricHash;
  final String projectionSchemaVersion;
  final String ruleSetId;
  final String ruleSetVersion;
  final GenerationRequestParameters requestParameters;
  final String requestParametersHash;
  final String projectionSetHash;
  final String caseInputSetHash;
  final String requestSetHash;
  final List<CanonicalPreparedRequest> requests;

  factory CanonicalRequestSet.create({
    required String runId,
    required String variant,
    required CanonicalEvalAdapter adapter,
    required EvalFixture fixture,
    required EvalRubric rubric,
  }) {
    validateRunId(runId);
    _requireCanonicalVariant(variant);
    final String parameterHash = adapter.requestParameters.hash;
    final List<CanonicalPreparedRequest> requests = <CanonicalPreparedRequest>[
      for (int index = 0; index < fixture.cases.length; index += 1)
        CanonicalPreparedRequest.create(
          variant: variant,
          evalCase: fixture.cases[index],
          adapterCase: adapter.cases[index],
          requestParametersHash: parameterHash,
        ),
    ];
    return CanonicalRequestSet(
      runId: runId,
      variant: variant,
      adapterHash: adapter.hash,
      fixtureHash: fixture.hash,
      rubricHash: rubric.hash,
      projectionSchemaVersion: adapter.projectionSchemaVersion,
      ruleSetId: adapter.ruleSetId,
      ruleSetVersion: adapter.ruleSetVersion,
      requestParameters: adapter.requestParameters,
      requestParametersHash: parameterHash,
      projectionSetHash: _caseHashSet(
        requests,
        (CanonicalPreparedRequest request) => request.projectionHash,
      ),
      caseInputSetHash: _caseHashSet(
        requests,
        (CanonicalPreparedRequest request) => request.caseInputHash,
      ),
      requestSetHash: canonicalRequestSetHash(
        variant,
        <String, String>{
          for (final CanonicalPreparedRequest request in requests)
            request.caseId: request.requestHash,
        },
      ),
      requests: List<CanonicalPreparedRequest>.unmodifiable(requests),
    );
  }

  factory CanonicalRequestSet.fromJson(
    Map<String, Object?> json, {
    required String expectedRunId,
    required String expectedVariant,
    required EvalFixture fixture,
    required EvalRubric rubric,
  }) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'evaluationPurpose',
        'runId',
        'variant',
        'adapterHash',
        'fixtureHash',
        'rubricHash',
        'projectionSchemaVersion',
        'ruleSetId',
        'ruleSetVersion',
        'requestParameters',
        'requestParametersHash',
        'projectionSetHash',
        'caseInputSetHash',
        'requestSetHash',
        'requests',
      },
    );
    _requireCanonicalVariant(expectedVariant);
    if (requireString(json, 'schemaVersion') != evalRequestSchemaVersion ||
        requireString(json, 'evaluationPurpose') != 'pairedPromptComparison' ||
        requireString(json, 'runId') != expectedRunId ||
        requireString(json, 'variant') != expectedVariant ||
        requireSha256(json, 'fixtureHash') != fixture.hash ||
        requireSha256(json, 'rubricHash') != rubric.hash ||
        requireString(json, 'projectionSchemaVersion') !=
            canonicalProjectionSchemaVersion ||
        fixture.projectionSchemaVersion != canonicalProjectionSchemaVersion ||
        requireString(json, 'ruleSetId') != canonicalRuleSetId ||
        requireString(json, 'ruleSetVersion') != canonicalRuleSetVersion) {
      throw const FormatException('Prepared request set identity mismatch.');
    }
    final GenerationRequestParameters parameters =
        GenerationRequestParameters.fromJson(
      requireObject(json, 'requestParameters'),
    );
    final String parameterHash = requireSha256(json, 'requestParametersHash');
    if (parameterHash != parameters.hash) {
      throw const FormatException('Request parameter hash mismatch.');
    }
    final List<CanonicalPreparedRequest> requests =
        requireList(json, 'requests')
            .map(
              (Object? value) => CanonicalPreparedRequest.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(growable: false);
    if (requests.length != fixture.cases.length) {
      throw const FormatException('Prepared request count mismatch.');
    }
    for (int index = 0; index < requests.length; index += 1) {
      final CanonicalPreparedRequest request = requests[index];
      final EvalCase evalCase = fixture.cases[index];
      final Map<String, Object?> projection =
          requireObject(evalCase.requestInput, 'projection');
      if (request.caseId != evalCase.caseId ||
          request.caseKind != evalCase.caseKind ||
          request.evaluationSplit != evalCase.evaluationSplit ||
          !_setEquals(request.cohortIds.toSet(), evalCase.cohortIds) ||
          request.caseInputHash != sha256Json(evalCase.requestInput) ||
          request.projectionHash != sha256Json(projection) ||
          sha256Json(request.caseInput) != request.caseInputHash ||
          request.requestHash !=
              canonicalPreparedRequestHash(
                variant: expectedVariant,
                request: request,
                requestParametersHash: parameterHash,
              )) {
        throw const FormatException('Prepared request contract mismatch.');
      }
    }
    final String projectionSetHash = _caseHashSet(
      requests,
      (CanonicalPreparedRequest request) => request.projectionHash,
    );
    final String caseInputSetHash = _caseHashSet(
      requests,
      (CanonicalPreparedRequest request) => request.caseInputHash,
    );
    final String requestSetHash = canonicalRequestSetHash(
      expectedVariant,
      <String, String>{
        for (final CanonicalPreparedRequest request in requests)
          request.caseId: request.requestHash,
      },
    );
    if (requireSha256(json, 'projectionSetHash') != projectionSetHash ||
        requireSha256(json, 'caseInputSetHash') != caseInputSetHash ||
        requireSha256(json, 'requestSetHash') != requestSetHash) {
      throw const FormatException('Prepared request set hash mismatch.');
    }
    return CanonicalRequestSet(
      runId: expectedRunId,
      variant: expectedVariant,
      adapterHash: requireSha256(json, 'adapterHash'),
      fixtureHash: fixture.hash,
      rubricHash: rubric.hash,
      projectionSchemaVersion: canonicalProjectionSchemaVersion,
      ruleSetId: canonicalRuleSetId,
      ruleSetVersion: canonicalRuleSetVersion,
      requestParameters: parameters,
      requestParametersHash: parameterHash,
      projectionSetHash: projectionSetHash,
      caseInputSetHash: caseInputSetHash,
      requestSetHash: requestSetHash,
      requests: List<CanonicalPreparedRequest>.unmodifiable(requests),
    );
  }

  CanonicalPreparedRequest requestByCaseId(String caseId) =>
      requests.singleWhere(
        (CanonicalPreparedRequest request) => request.caseId == caseId,
        orElse: () => throw const EvalFailure('preparedRequestMissing'),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': evalRequestSchemaVersion,
        'evaluationPurpose': 'pairedPromptComparison',
        'runId': runId,
        'variant': variant,
        'adapterHash': adapterHash,
        'fixtureHash': fixtureHash,
        'rubricHash': rubricHash,
        'projectionSchemaVersion': projectionSchemaVersion,
        'ruleSetId': ruleSetId,
        'ruleSetVersion': ruleSetVersion,
        'requestParameters': requestParameters.toJson(),
        'requestParametersHash': requestParametersHash,
        'projectionSetHash': projectionSetHash,
        'caseInputSetHash': caseInputSetHash,
        'requestSetHash': requestSetHash,
        'requests': requests
            .map((CanonicalPreparedRequest request) => request.toJson())
            .toList(growable: false),
      };
}

String canonicalPreparedRequestHash({
  required String variant,
  required CanonicalPreparedRequest request,
  required String requestParametersHash,
}) =>
    sha256Json(<String, Object?>{
      'variant': variant,
      'caseId': request.caseId,
      'messages': <Object?>[
        <String, Object?>{
          'role': 'system',
          'content': request.systemPrompt,
        },
        <String, Object?>{
          'role': 'user',
          'content': request.userPrompt,
        },
      ],
      'systemTemplateId': request.systemTemplateId,
      'analysisTemplateId': request.analysisTemplateId,
      'promptPolicyVersion': request.promptPolicyVersion,
      'projectionHash': request.projectionHash,
      'caseInputHash': request.caseInputHash,
      'requestParametersHash': requestParametersHash,
    });

String canonicalRequestSetHash(
  String variant,
  Map<String, String> requestHashesByCase,
) =>
    sha256Json(<String, Object?>{
      'variant': variant,
      'requests': <String, Object?>{
        for (final String caseId in (requestHashesByCase.keys.toList()..sort()))
          caseId: requestHashesByCase[caseId],
      },
    });

String requireSha256(Map<String, Object?> json, String key) {
  final String value = requireString(json, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw const FormatException('Expected a lowercase SHA-256 hash.');
  }
  return value;
}

String _caseHashSet(
  List<CanonicalPreparedRequest> requests,
  String Function(CanonicalPreparedRequest request) select,
) =>
    sha256Json(<String, Object?>{
      for (final CanonicalPreparedRequest request in requests)
        request.caseId: select(request),
    });

void _requireCanonicalVariant(String variant) {
  if (!<String>{baselineVariant, candidateVariant}.contains(variant)) {
    throw const FormatException('Expected a canonical comparison variant.');
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

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
