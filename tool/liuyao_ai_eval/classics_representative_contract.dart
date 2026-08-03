import 'dart:io';

import 'assets.dart';
import 'canonical_json.dart';
import 'constants.dart';
import 'security.dart';

const String classicsRepresentativeCommand =
    'classics-representative-paired-model';
const String classicsRepresentativeGenerationSchemaVersion =
    'liuyao-classics-representative-generation/1.0.0';
const String classicsRepresentativeReferenceSchemaVersion =
    'liuyao-classics-representative-reference/1.0.0';
const String classicsRepresentativeReferenceManifestSchemaVersion =
    'liuyao-classics-representative-reference-manifest/1.0.0';
const String classicsRepresentativeBaselineSchemaVersion =
    'liuyao-classics-representative-baseline/1.0.0';
const String classicsRepresentativeAdapterSchemaVersion =
    'liuyao-classics-representative-adapter/1.0.0';
const String classicsRepresentativeRunSchemaVersion =
    'liuyao-classics-representative-run/1.0.0';
const String classicsRepresentativeBaselineVariant = 'baseline-v1.6.0';
const String classicsRepresentativeCandidateVariant =
    'candidate-v3-policy-$candidatePromptPolicyRevision';
const String classicsRepresentativeBaselineSourceTag = 'v1.6.0';
const String classicsRepresentativeBaselineSourceCommit =
    'e97d94b54b7ac02edcca00b6ab08b8835fad8090';

const List<String> classicsRepresentativeCaseIds = <String>[
  'liuyao.case.golden.001',
  'liuyao.case.golden.007',
  'liuyao.case.golden.037',
];

const String classicsRepresentativeGenerationRelativePath =
    'tool/liuyao_ai_eval/fixtures/classics_representative_generation.json';
const String classicsRepresentativeReferenceRelativePath =
    'tool/liuyao_ai_eval/fixtures/classics_representative_reference.json';
const String classicsRepresentativeReferenceManifestRelativePath =
    'tool/liuyao_ai_eval/fixtures/classics_representative_reference_manifest.json';
const String classicsRepresentativeBaselineRelativePath =
    'tool/liuyao_ai_eval/frozen/classics_representative_v160_requests.json';
const String classicsRepresentativeAdapterRelativePath =
    'tool/liuyao_ai_eval/fixtures/classics_representative_adapter.json';

const Map<String, String> _expectedCaseKinds = <String, String>{
  'liuyao.case.golden.001': 'ruleValidation',
  'liuyao.case.golden.007': 'originalBook',
  'liuyao.case.golden.037': 'ruleValidation',
};

class ClassicsRepresentativeGenerationCase {
  const ClassicsRepresentativeGenerationCase({
    required this.caseId,
    required this.caseKind,
    required this.question,
    required this.numbers,
    required this.monthBranch,
    required this.dayGanZhi,
    required this.declaredMainGuaName,
    required this.declaredChangingGuaName,
    required this.declaredMovingPositions,
    required this.useSpiritMode,
    required this.useSpiritPosition,
    required this.declaredActorId,
    required this.declaredLiuQin,
    required this.declaredBranch,
    required this.declaredWuXing,
  });

  final String caseId;
  final String caseKind;
  final String question;
  final List<int> numbers;
  final String monthBranch;
  final String dayGanZhi;
  final String declaredMainGuaName;
  final String? declaredChangingGuaName;
  final List<int> declaredMovingPositions;
  final String useSpiritMode;
  final int useSpiritPosition;
  final String declaredActorId;
  final String declaredLiuQin;
  final String declaredBranch;
  final String declaredWuXing;

  factory ClassicsRepresentativeGenerationCase.fromJson(
    Map<String, Object?> json,
  ) {
    requireExactKeys(
      json,
      <String>{'caseId', 'caseKind', 'question', 'pan', 'useSpirit'},
    );
    final String caseId = requireString(json, 'caseId');
    final String caseKind = requireString(json, 'caseKind');
    if (_expectedCaseKinds[caseId] != caseKind) {
      throw const FormatException('Representative case kind changed.');
    }
    final Map<String, Object?> pan = requireObject(json, 'pan');
    requireExactKeys(
      pan,
      <String>{
        'numbers',
        'monthBranch',
        'dayGanZhi',
        'declaredMainGuaName',
        'declaredChangingGuaName',
        'declaredMovingPositions',
      },
    );
    final List<int> numbers = requireList(pan, 'numbers').map((value) {
      if (value is! int || value < 6 || value > 9) {
        throw const FormatException('Invalid representative yao number.');
      }
      return value;
    }).toList(growable: false);
    if (numbers.length != 6) {
      throw const FormatException('Representative case needs six lines.');
    }
    final List<int> movingPositions = requireList(
      pan,
      'declaredMovingPositions',
    ).map((value) {
      if (value is! int || value < 1 || value > 6) {
        throw const FormatException('Invalid representative moving line.');
      }
      return value;
    }).toList(growable: false);
    final Object? changingName = pan['declaredChangingGuaName'];
    if (changingName != null && changingName is! String) {
      throw const FormatException('Invalid representative changing gua.');
    }
    final Map<String, Object?> useSpirit = requireObject(json, 'useSpirit');
    requireExactKeys(
      useSpirit,
      <String>{
        'mode',
        'position',
        'declaredActorId',
        'declaredLiuQin',
        'declaredBranch',
        'declaredWuXing',
      },
    );
    final String mode = requireString(useSpirit, 'mode');
    final int position = requireInt(
      useSpirit,
      'position',
      minimum: 1,
    );
    if (position > 6 ||
        !<String>{'selectedVisible', 'selectedHidden'}.contains(mode)) {
      throw const FormatException('Invalid representative use spirit.');
    }
    final String expectedActor = mode == 'selectedHidden'
        ? 'hidden:host-yao:$position'
        : 'main:yao:$position';
    if (requireString(useSpirit, 'declaredActorId') != expectedActor) {
      throw const FormatException('Representative use-spirit actor changed.');
    }
    return ClassicsRepresentativeGenerationCase(
      caseId: caseId,
      caseKind: caseKind,
      question: requireString(json, 'question'),
      numbers: List<int>.unmodifiable(numbers),
      monthBranch: requireString(pan, 'monthBranch'),
      dayGanZhi: requireString(pan, 'dayGanZhi'),
      declaredMainGuaName: requireString(pan, 'declaredMainGuaName'),
      declaredChangingGuaName: changingName as String?,
      declaredMovingPositions: List<int>.unmodifiable(movingPositions),
      useSpiritMode: mode,
      useSpiritPosition: position,
      declaredActorId: expectedActor,
      declaredLiuQin: requireString(useSpirit, 'declaredLiuQin'),
      declaredBranch: requireString(useSpirit, 'declaredBranch'),
      declaredWuXing: requireString(useSpirit, 'declaredWuXing'),
    );
  }

  bool get selectedHidden => useSpiritMode == 'selectedHidden';

  Map<String, Object?> generationInput() => <String, Object?>{
        'caseId': caseId,
        'caseKind': caseKind,
        'question': question,
        'pan': <String, Object?>{
          'numbers': numbers,
          'monthBranch': monthBranch,
          'dayGanZhi': dayGanZhi,
          'declaredMainGuaName': declaredMainGuaName,
          'declaredChangingGuaName': declaredChangingGuaName,
          'declaredMovingPositions': declaredMovingPositions,
        },
        'useSpirit': <String, Object?>{
          'mode': useSpiritMode,
          'position': useSpiritPosition,
          'declaredActorId': declaredActorId,
          'declaredLiuQin': declaredLiuQin,
          'declaredBranch': declaredBranch,
          'declaredWuXing': declaredWuXing,
        },
      };
}

class ClassicsRepresentativeGenerationFixture {
  const ClassicsRepresentativeGenerationFixture({
    required this.cases,
    required this.hash,
  });

  final List<ClassicsRepresentativeGenerationCase> cases;
  final String hash;

  factory ClassicsRepresentativeGenerationFixture.fromJson(
    Map<String, Object?> json,
  ) {
    requireExactKeys(json, <String>{'schemaVersion', 'cases'});
    if (requireString(json, 'schemaVersion') !=
        classicsRepresentativeGenerationSchemaVersion) {
      throw const FormatException(
        'Unsupported representative generation fixture.',
      );
    }
    final List<ClassicsRepresentativeGenerationCase> cases = requireList(
      json,
      'cases',
    ).map((value) {
      return ClassicsRepresentativeGenerationCase.fromJson(
        (value as Map).cast<String, Object?>(),
      );
    }).toList(growable: false);
    _requireFrozenCaseOrder(cases.map((item) => item.caseId).toList());
    return ClassicsRepresentativeGenerationFixture(
      cases: List<ClassicsRepresentativeGenerationCase>.unmodifiable(cases),
      hash: sha256Json(json),
    );
  }

  ClassicsRepresentativeGenerationCase caseById(String caseId) =>
      cases.singleWhere((item) => item.caseId == caseId);
}

class ClassicsRepresentativeRequestParameters {
  const ClassicsRepresentativeRequestParameters();

  factory ClassicsRepresentativeRequestParameters.fromJson(
    Map<String, Object?> json,
  ) {
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
        'Representative generation parameters changed.',
      );
    }
    return const ClassicsRepresentativeRequestParameters();
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

class ClassicsRepresentativePromptVariant {
  const ClassicsRepresentativePromptVariant({
    required this.variant,
    required this.systemPrompt,
    required this.userPrompt,
    required this.projection,
    required this.metadata,
    required this.requestHash,
  });

  final String variant;
  final String systemPrompt;
  final String userPrompt;
  final Map<String, Object?> projection;
  final Map<String, Object?> metadata;
  final String requestHash;

  factory ClassicsRepresentativePromptVariant.fromJson(
    String variant,
    Map<String, Object?> json,
  ) {
    requireExactKeys(
      json,
      <String>{
        'systemPrompt',
        'userPrompt',
        'projection',
        'metadata',
        'requestHash',
      },
    );
    final Map<String, Object?> metadata = requireObject(json, 'metadata');
    requireExactKeys(
      metadata,
      <String>{
        'analysisSchemaVersion',
        'projectionSchemaVersion',
        'ruleSetId',
        'ruleSetVersion',
        'sourceCatalogVersion',
        'promptPolicyVersion',
        'systemTemplateId',
        'analysisTemplateId',
      },
    );
    for (final String key in metadata.keys) {
      requireString(metadata, key);
    }
    final ClassicsRepresentativePromptVariant result =
        ClassicsRepresentativePromptVariant(
      variant: variant,
      systemPrompt: requireString(json, 'systemPrompt'),
      userPrompt: requireString(json, 'userPrompt'),
      projection: Map<String, Object?>.unmodifiable(
        requireObject(json, 'projection'),
      ),
      metadata: Map<String, Object?>.unmodifiable(metadata),
      requestHash: requireRepresentativeSha256(json, 'requestHash'),
    );
    if (result.requestHash != result.calculateHash()) {
      throw const FormatException('Representative request hash mismatch.');
    }
    return result;
  }

  String calculateHash() => sha256Json(<String, Object?>{
        'variant': variant,
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'projection': projection,
        'metadata': metadata,
      });

  Map<String, Object?> toJson() => <String, Object?>{
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'projection': projection,
        'metadata': metadata,
        'requestHash': requestHash,
      };
}

class ClassicsRepresentativeAdapterCase {
  const ClassicsRepresentativeAdapterCase({
    required this.caseId,
    required this.generationInputHash,
    required this.baseline,
    required this.candidate,
  });

  final String caseId;
  final String generationInputHash;
  final ClassicsRepresentativePromptVariant baseline;
  final ClassicsRepresentativePromptVariant candidate;

  factory ClassicsRepresentativeAdapterCase.fromJson(
    Map<String, Object?> json,
  ) {
    requireExactKeys(
      json,
      <String>{
        'caseId',
        'generationInputHash',
        'baseline',
        'candidate',
      },
    );
    final ClassicsRepresentativeAdapterCase result =
        ClassicsRepresentativeAdapterCase(
      caseId: requireString(json, 'caseId'),
      generationInputHash:
          requireRepresentativeSha256(json, 'generationInputHash'),
      baseline: ClassicsRepresentativePromptVariant.fromJson(
        classicsRepresentativeBaselineVariant,
        requireObject(json, 'baseline'),
      ),
      candidate: ClassicsRepresentativePromptVariant.fromJson(
        classicsRepresentativeCandidateVariant,
        requireObject(json, 'candidate'),
      ),
    );
    result._validateVersionBoundary();
    return result;
  }

  void _validateVersionBoundary() {
    String value(ClassicsRepresentativePromptVariant item, String key) =>
        item.metadata[key]! as String;
    if (value(baseline, 'analysisSchemaVersion') != '1' ||
        value(baseline, 'projectionSchemaVersion') != '1' ||
        value(baseline, 'ruleSetId') != canonicalRuleSetId ||
        value(baseline, 'ruleSetVersion') != 'v2' ||
        value(baseline, 'sourceCatalogVersion') != 'liuyao-evidence/1.0.0' ||
        value(baseline, 'promptPolicyVersion') != 'liuyao-ai-policy/1.0.0' ||
        value(candidate, 'analysisSchemaVersion') != '2' ||
        value(candidate, 'projectionSchemaVersion') != '2' ||
        value(candidate, 'ruleSetId') != canonicalRuleSetId ||
        value(candidate, 'ruleSetVersion') != 'v3' ||
        value(candidate, 'sourceCatalogVersion') != 'liuyao-evidence/1.1.0' ||
        value(candidate, 'promptPolicyVersion') !=
            candidatePromptPolicyVersion) {
      throw const FormatException(
        'Representative production version boundary changed.',
      );
    }
    if (baseline.projection['projectionSchemaVersion'] != 1 ||
        baseline.projection['analysisSchemaVersion'] != 1 ||
        baseline.projection['ruleSetVersion'] != 'v2' ||
        candidate.projection['projectionSchemaVersion'] != 2 ||
        candidate.projection['analysisSchemaVersion'] != 2 ||
        candidate.projection['ruleSetVersion'] != 'v3') {
      throw const FormatException(
        'Representative projection version boundary changed.',
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'caseId': caseId,
        'generationInputHash': generationInputHash,
        'baseline': baseline.toJson(),
        'candidate': candidate.toJson(),
      };
}

class ClassicsRepresentativeAdapter {
  const ClassicsRepresentativeAdapter({
    required this.generationFixtureHash,
    required this.baselineSourceCommit,
    required this.requestParameters,
    required this.cases,
    required this.hash,
  });

  final String generationFixtureHash;
  final String baselineSourceCommit;
  final ClassicsRepresentativeRequestParameters requestParameters;
  final List<ClassicsRepresentativeAdapterCase> cases;
  final String hash;

  factory ClassicsRepresentativeAdapter.fromJson(
    Map<String, Object?> json, {
    required ClassicsRepresentativeGenerationFixture fixture,
  }) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'generationFixtureHash',
        'baselineSourceCommit',
        'requestParameters',
        'cases',
      },
    );
    if (requireString(json, 'schemaVersion') !=
            classicsRepresentativeAdapterSchemaVersion ||
        requireRepresentativeSha256(json, 'generationFixtureHash') !=
            fixture.hash ||
        requireString(json, 'baselineSourceCommit') !=
            classicsRepresentativeBaselineSourceCommit) {
      throw const FormatException('Representative adapter identity changed.');
    }
    final List<ClassicsRepresentativeAdapterCase> cases = requireList(
      json,
      'cases',
    ).map((value) {
      return ClassicsRepresentativeAdapterCase.fromJson(
        (value as Map).cast<String, Object?>(),
      );
    }).toList(growable: false);
    _requireFrozenCaseOrder(cases.map((item) => item.caseId).toList());
    for (final ClassicsRepresentativeGenerationCase generationCase
        in fixture.cases) {
      final ClassicsRepresentativeAdapterCase adapterCase = cases.singleWhere(
        (item) => item.caseId == generationCase.caseId,
      );
      if (adapterCase.generationInputHash !=
          sha256Json(generationCase.generationInput())) {
        throw const FormatException(
          'Representative generation input hash changed.',
        );
      }
    }
    return ClassicsRepresentativeAdapter(
      generationFixtureHash: fixture.hash,
      baselineSourceCommit: requireString(json, 'baselineSourceCommit'),
      requestParameters: ClassicsRepresentativeRequestParameters.fromJson(
        requireObject(json, 'requestParameters'),
      ),
      cases: List<ClassicsRepresentativeAdapterCase>.unmodifiable(cases),
      hash: sha256Json(json),
    );
  }

  ClassicsRepresentativeAdapterCase caseById(String caseId) =>
      cases.singleWhere((item) => item.caseId == caseId);

  String get baselineRequestSetHash => sha256Json(<String, Object?>{
        for (final item in cases) item.caseId: item.baseline.requestHash,
      });

  String get candidateRequestSetHash => sha256Json(<String, Object?>{
        for (final item in cases) item.caseId: item.candidate.requestHash,
      });

  String get baselineProjectionSetHash => sha256Json(<String, Object?>{
        for (final item in cases)
          item.caseId: sha256Json(item.baseline.projection),
      });

  String get candidateProjectionSetHash => sha256Json(<String, Object?>{
        for (final item in cases)
          item.caseId: sha256Json(item.candidate.projection),
      });

  String get generationInputSetHash => sha256Json(<String, Object?>{
        for (final item in cases) item.caseId: item.generationInputHash,
      });
}

class ClassicsRepresentativeJudgeReferenceManifest {
  const ClassicsRepresentativeJudgeReferenceManifest({
    required this.caseIds,
    required this.referenceAssetSha256,
  });

  final List<String> caseIds;
  final String referenceAssetSha256;

  factory ClassicsRepresentativeJudgeReferenceManifest.fromJson(
    Map<String, Object?> json,
  ) {
    requireExactKeys(
      json,
      <String>{'schemaVersion', 'caseIds', 'referenceAssetSha256'},
    );
    if (requireString(json, 'schemaVersion') !=
        classicsRepresentativeReferenceManifestSchemaVersion) {
      throw const FormatException(
        'Unsupported representative judge-reference manifest.',
      );
    }
    final List<String> caseIds = requireStringList(json, 'caseIds');
    _requireFrozenCaseOrder(caseIds);
    return ClassicsRepresentativeJudgeReferenceManifest(
      caseIds: List<String>.unmodifiable(caseIds),
      referenceAssetSha256: requireRepresentativeSha256(
        json,
        'referenceAssetSha256',
      ),
    );
  }
}

class ClassicsRepresentativeJudgeReference {
  const ClassicsRepresentativeJudgeReference({
    required this.cases,
    required this.hash,
  });

  final List<EvalCase> cases;
  final String hash;

  factory ClassicsRepresentativeJudgeReference.fromJson(
    Map<String, Object?> json, {
    required ClassicsRepresentativeGenerationFixture generationFixture,
  }) {
    requireExactKeys(
      json,
      <String>{'schemaVersion', 'baselineSourceCommit', 'cases'},
    );
    if (requireString(json, 'schemaVersion') !=
            classicsRepresentativeReferenceSchemaVersion ||
        requireString(json, 'baselineSourceCommit') !=
            classicsRepresentativeBaselineSourceCommit) {
      throw const FormatException(
        'Representative judge-reference identity changed.',
      );
    }
    final List<EvalCase> cases = requireList(json, 'cases').map((value) {
      return EvalCase.fromJson((value as Map).cast<String, Object?>());
    }).toList(growable: false);
    _requireFrozenCaseOrder(cases.map((item) => item.caseId).toList());
    for (final EvalCase evalCase in cases) {
      final ClassicsRepresentativeGenerationCase generationCase =
          generationFixture.caseById(evalCase.caseId);
      if (evalCase.evaluationSplit != 'calibration' ||
          evalCase.caseKind != generationCase.caseKind ||
          evalCase.requestInput['question'] != generationCase.question) {
        throw const FormatException(
          'Representative judge-reference case changed.',
        );
      }
    }
    return ClassicsRepresentativeJudgeReference(
      cases: List<EvalCase>.unmodifiable(cases),
      hash: sha256Json(json),
    );
  }

  EvalCase caseById(String caseId) =>
      cases.singleWhere((item) => item.caseId == caseId);
}

class ClassicsRepresentativeFrozenBaselineCase {
  const ClassicsRepresentativeFrozenBaselineCase({
    required this.caseId,
    required this.question,
    required this.prompt,
  });

  final String caseId;
  final String question;
  final ClassicsRepresentativePromptVariant prompt;

  factory ClassicsRepresentativeFrozenBaselineCase.fromJson(
    Map<String, Object?> json,
  ) {
    requireExactKeys(
      json,
      <String>{
        'caseId',
        'question',
        'systemPrompt',
        'userPrompt',
        'projection',
        'metadata',
        'requestHash',
      },
    );
    final Map<String, Object?> promptJson = Map<String, Object?>.from(json)
      ..remove('caseId')
      ..remove('question');
    return ClassicsRepresentativeFrozenBaselineCase(
      caseId: requireString(json, 'caseId'),
      question: requireString(json, 'question'),
      prompt: ClassicsRepresentativePromptVariant.fromJson(
        classicsRepresentativeBaselineVariant,
        promptJson,
      ),
    );
  }
}

class ClassicsRepresentativeFrozenBaseline {
  const ClassicsRepresentativeFrozenBaseline({
    required this.generationFixtureHash,
    required this.cases,
  });

  final String generationFixtureHash;
  final List<ClassicsRepresentativeFrozenBaselineCase> cases;

  factory ClassicsRepresentativeFrozenBaseline.fromJson(
    Map<String, Object?> json, {
    required ClassicsRepresentativeGenerationFixture fixture,
  }) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'sourceTag',
        'sourceCommit',
        'generationFixtureHash',
        'cases',
      },
    );
    if (requireString(json, 'schemaVersion') !=
            classicsRepresentativeBaselineSchemaVersion ||
        requireString(json, 'sourceTag') !=
            classicsRepresentativeBaselineSourceTag ||
        requireString(json, 'sourceCommit') !=
            classicsRepresentativeBaselineSourceCommit ||
        requireRepresentativeSha256(json, 'generationFixtureHash') !=
            fixture.hash) {
      throw const FormatException(
        'Representative frozen baseline identity changed.',
      );
    }
    final List<ClassicsRepresentativeFrozenBaselineCase> cases = requireList(
      json,
      'cases',
    ).map((value) {
      return ClassicsRepresentativeFrozenBaselineCase.fromJson(
        (value as Map).cast<String, Object?>(),
      );
    }).toList(growable: false);
    _requireFrozenCaseOrder(cases.map((item) => item.caseId).toList());
    for (final ClassicsRepresentativeFrozenBaselineCase baselineCase in cases) {
      final generationCase = fixture.caseById(baselineCase.caseId);
      if (baselineCase.question != generationCase.question) {
        throw const FormatException(
          'Representative baseline question changed.',
        );
      }
      if (baselineCase.prompt.metadata['analysisSchemaVersion'] != '1' ||
          baselineCase.prompt.metadata['projectionSchemaVersion'] != '1' ||
          baselineCase.prompt.metadata['ruleSetVersion'] != 'v2' ||
          baselineCase.prompt.metadata['promptPolicyVersion'] !=
              'liuyao-ai-policy/1.0.0') {
        throw const FormatException(
          'Representative frozen baseline version changed.',
        );
      }
    }
    return ClassicsRepresentativeFrozenBaseline(
      generationFixtureHash: fixture.hash,
      cases: List<ClassicsRepresentativeFrozenBaselineCase>.unmodifiable(
        cases,
      ),
    );
  }

  ClassicsRepresentativeFrozenBaselineCase caseById(String caseId) =>
      cases.singleWhere((item) => item.caseId == caseId);
}

class ClassicsRepresentativeAssetLoader {
  ClassicsRepresentativeAssetLoader(this.repositoryRoot);

  final String repositoryRoot;

  Map<String, Object?> _read(String relativePath) => SafeArtifactReader(
        root: Directory(repositoryRoot),
      ).readJson(relativePath);

  ClassicsRepresentativeGenerationFixture loadGenerationFixture() =>
      ClassicsRepresentativeGenerationFixture.fromJson(
        _read(classicsRepresentativeGenerationRelativePath),
      );

  ClassicsRepresentativeAdapter loadAdapter(
    ClassicsRepresentativeGenerationFixture fixture,
  ) =>
      ClassicsRepresentativeAdapter.fromJson(
        _read(classicsRepresentativeAdapterRelativePath),
        fixture: fixture,
      );

  ClassicsRepresentativeJudgeReferenceManifest loadJudgeReferenceManifest() =>
      ClassicsRepresentativeJudgeReferenceManifest.fromJson(
        _read(classicsRepresentativeReferenceManifestRelativePath),
      );

  ClassicsRepresentativeFrozenBaseline loadFrozenBaseline(
    ClassicsRepresentativeGenerationFixture fixture,
  ) =>
      ClassicsRepresentativeFrozenBaseline.fromJson(
        _read(classicsRepresentativeBaselineRelativePath),
        fixture: fixture,
      );

  ClassicsRepresentativeJudgeReference loadJudgeReference({
    required ClassicsRepresentativeGenerationFixture generationFixture,
    required ClassicsRepresentativeJudgeReferenceManifest manifest,
  }) {
    final String source =
        SafeArtifactReader(root: Directory(repositoryRoot)).readText(
      classicsRepresentativeReferenceRelativePath,
    );
    if (sha256Text(source) != manifest.referenceAssetSha256) {
      throw const EvalFailure('representativeReferenceAssetDrift');
    }
    return ClassicsRepresentativeJudgeReference.fromJson(
      decodeObject(source),
      generationFixture: generationFixture,
    );
  }
}

void _requireFrozenCaseOrder(List<String> caseIds) {
  if (caseIds.length != classicsRepresentativeCaseIds.length) {
    throw const FormatException('Representative case count changed.');
  }
  for (int index = 0; index < classicsRepresentativeCaseIds.length; index++) {
    if (caseIds[index] != classicsRepresentativeCaseIds[index]) {
      throw const FormatException('Representative case IDs changed.');
    }
  }
}

String requireRepresentativeSha256(
  Map<String, Object?> json,
  String key,
) {
  final String value = requireString(json, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw const FormatException('Invalid representative SHA-256 value.');
  }
  return value;
}
