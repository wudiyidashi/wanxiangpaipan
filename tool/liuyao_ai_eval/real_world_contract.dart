import 'dart:io';

import 'canonical_contract.dart';
import 'canonical_json.dart';
import 'constants.dart';
import 'security.dart';

const String realWorldRentalCaseId = 'liuyao.real.rental.2026-02-28';
const String realWorldBaselineVariant = 'baseline-v1.6.0';
const String realWorldCandidateVariant =
    'candidate-v3-policy-$candidatePromptPolicyRevision';
const List<String> realWorldScenarioIds = <String>[
  'unselected',
  'selected-main-1',
];
const List<String> realWorldLifecycleDimensionIds = <String>[
  'formation',
  'quality',
  'continuity',
  'persistence',
];
const List<String> realWorldRiskCategoryIds = <String>[
  'contractAuthority',
  'fees',
  'possession',
  'continuity',
];
const List<String> realWorldScoreDimensionIds = <String>[
  'stageCompleteness',
  'riskRelevance',
  'evidenceHierarchy',
  'questionFit',
  'uncertainty',
  'actionableVerification',
];

class RealWorldScenario {
  const RealWorldScenario({
    required this.scenarioId,
    required this.selectedPosition,
    required this.selectedHidden,
  });

  final String scenarioId;
  final int? selectedPosition;
  final bool selectedHidden;

  factory RealWorldScenario.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{'scenarioId', 'selectedPosition', 'selectedHidden'},
    );
    final Object? position = json['selectedPosition'];
    if (position != null &&
        (position is! int || position < 1 || position > 6)) {
      throw const FormatException('Invalid real-world selected position.');
    }
    return RealWorldScenario(
      scenarioId: requireString(json, 'scenarioId'),
      selectedPosition: position as int?,
      selectedHidden: requireBool(json, 'selectedHidden'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'scenarioId': scenarioId,
        'selectedPosition': selectedPosition,
        'selectedHidden': selectedHidden,
      };
}

class RealWorldGenerationFixture {
  const RealWorldGenerationFixture({
    required this.caseId,
    required this.question,
    required this.castTime,
    required this.numbers,
    required this.expectedCalendar,
    required this.scenarios,
    required this.hash,
  });

  final String caseId;
  final String question;
  final DateTime castTime;
  final List<int> numbers;
  final Map<String, Object?> expectedCalendar;
  final List<RealWorldScenario> scenarios;
  final String hash;

  factory RealWorldGenerationFixture.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'caseId',
        'question',
        'castTime',
        'numbers',
        'expectedCalendar',
        'scenarios',
      },
    );
    if (requireString(json, 'schemaVersion') !=
        'liuyao-real-world-generation/1.0.0') {
      throw const FormatException('Unsupported real-world generation fixture.');
    }
    final DateTime? castTime =
        DateTime.tryParse(requireString(json, 'castTime'));
    if (castTime == null || castTime.isUtc) {
      throw const FormatException(
          'Real-world cast time must be local civil time.');
    }
    final List<int> numbers = requireList(json, 'numbers').map((value) {
      if (value is! int || value < 6 || value > 9) {
        throw const FormatException('Invalid real-world yao number.');
      }
      return value;
    }).toList(growable: false);
    if (numbers.length != 6) {
      throw const FormatException('Real-world fixture requires six lines.');
    }
    final Map<String, Object?> calendar = requireObject(
      json,
      'expectedCalendar',
    );
    requireExactKeys(
      calendar,
      <String>{
        'yearGanZhi',
        'monthGanZhi',
        'dayGanZhi',
        'monthBranch',
        'kongWang',
      },
    );
    for (final String key in <String>[
      'yearGanZhi',
      'monthGanZhi',
      'dayGanZhi',
      'monthBranch',
    ]) {
      requireString(calendar, key);
    }
    requireStringList(calendar, 'kongWang');
    final String caseId = requireString(json, 'caseId');
    if (caseId != realWorldRentalCaseId) {
      throw const FormatException('Real-world case identity changed.');
    }
    final List<RealWorldScenario> scenarios = requireList(json, 'scenarios')
        .map(
          (value) => RealWorldScenario.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    final Set<String> ids = scenarios.map((item) => item.scenarioId).toSet();
    if (scenarios.length != 2 ||
        ids.length != 2 ||
        !ids.containsAll(realWorldScenarioIds)) {
      throw const FormatException('Real-world scenarios are not frozen.');
    }
    final RealWorldScenario unselected =
        scenarios.singleWhere((item) => item.scenarioId == 'unselected');
    final RealWorldScenario selected =
        scenarios.singleWhere((item) => item.scenarioId == 'selected-main-1');
    if (unselected.selectedPosition != null ||
        unselected.selectedHidden ||
        selected.selectedPosition != 1 ||
        selected.selectedHidden) {
      throw const FormatException('Real-world use-spirit scenarios changed.');
    }
    return RealWorldGenerationFixture(
      caseId: caseId,
      question: requireString(json, 'question'),
      castTime: castTime,
      numbers: List<int>.unmodifiable(numbers),
      expectedCalendar: Map<String, Object?>.unmodifiable(calendar),
      scenarios: List<RealWorldScenario>.unmodifiable(scenarios),
      hash: sha256Json(json),
    );
  }

  RealWorldScenario scenario(String id) =>
      scenarios.singleWhere((item) => item.scenarioId == id);

  Map<String, Object?> generationInput(RealWorldScenario scenario) =>
      <String, Object?>{
        'caseId': caseId,
        'scenarioId': scenario.scenarioId,
        'question': question,
        'castTime': castTime.toIso8601String(),
        'numbers': numbers,
        'selectedPosition': scenario.selectedPosition,
        'selectedHidden': scenario.selectedHidden,
      };
}

class RealWorldJudgeReference {
  const RealWorldJudgeReference({
    required this.caseId,
    required this.document,
    required this.hash,
  });

  final String caseId;
  final Map<String, Object?> document;
  final String hash;

  factory RealWorldJudgeReference.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'caseId',
        'actualOutcome',
        'retrospectiveMappings',
        'expectedLifecycleByScenario',
        'requiredRiskCategories',
        'forbiddenPreciseClaims',
        'scoreDimensions',
      },
    );
    if (requireString(json, 'schemaVersion') !=
        'liuyao-real-world-judge-reference/1.0.0') {
      throw const FormatException('Unsupported real-world judge reference.');
    }
    final String caseId = requireString(json, 'caseId');
    if (caseId != realWorldRentalCaseId) {
      throw const FormatException('Real-world judge case identity changed.');
    }
    final Map<String, Object?> actualOutcome =
        requireObject(json, 'actualOutcome');
    requireExactKeys(
      actualOutcome,
      <String>{'formation', 'contractAuthority', 'fees', 'continuity', 'loss'},
    );
    for (final key in actualOutcome.keys) {
      requireString(actualOutcome, key);
    }
    _requireUniqueStringList(json, 'retrospectiveMappings');
    final Map<String, Object?> lifecycleByScenario =
        requireObject(json, 'expectedLifecycleByScenario');
    requireExactKeys(lifecycleByScenario, realWorldScenarioIds.toSet());
    if (lifecycleByScenario['unselected'] != null) {
      throw const FormatException(
        'Unselected real-world judge lifecycle must remain withheld.',
      );
    }
    final Object? selectedLifecycleRaw = lifecycleByScenario['selected-main-1'];
    if (selectedLifecycleRaw is! Map) {
      throw const FormatException('Selected real-world lifecycle is absent.');
    }
    final Map<String, Object?> selectedLifecycle =
        selectedLifecycleRaw.cast<String, Object?>();
    requireExactKeys(
      selectedLifecycle,
      realWorldLifecycleDimensionIds.toSet(),
    );
    const expectedLifecycle = <String, String>{
      'formation': 'willForm',
      'quality': 'adverse',
      'continuity': 'unstable',
      'persistence': 'entangled',
    };
    for (final entry in expectedLifecycle.entries) {
      if (requireString(selectedLifecycle, entry.key) != entry.value) {
        throw const FormatException('Real-world lifecycle identity changed.');
      }
    }
    _requireExactStringList(
      json,
      'requiredRiskCategories',
      realWorldRiskCategoryIds,
    );
    _requireUniqueStringList(json, 'forbiddenPreciseClaims');
    _requireExactStringList(
      json,
      'scoreDimensions',
      realWorldScoreDimensionIds,
    );
    return RealWorldJudgeReference(
      caseId: caseId,
      document: Map<String, Object?>.unmodifiable(json),
      hash: sha256Json(json),
    );
  }
}

class RealWorldJudgeReferenceManifest {
  const RealWorldJudgeReferenceManifest({
    required this.caseId,
    required this.referenceAssetSha256,
  });

  final String caseId;
  final String referenceAssetSha256;

  factory RealWorldJudgeReferenceManifest.fromJson(
    Map<String, Object?> json,
  ) {
    requireExactKeys(
      json,
      <String>{'schemaVersion', 'caseId', 'referenceAssetSha256'},
    );
    if (requireString(json, 'schemaVersion') !=
        realWorldJudgeReferenceManifestSchemaVersion) {
      throw const FormatException(
        'Unsupported real-world judge reference manifest.',
      );
    }
    final String caseId = requireString(json, 'caseId');
    if (caseId != realWorldRentalCaseId) {
      throw const FormatException(
        'Real-world judge reference manifest identity changed.',
      );
    }
    return RealWorldJudgeReferenceManifest(
      caseId: caseId,
      referenceAssetSha256: requireSha256(json, 'referenceAssetSha256'),
    );
  }
}

class RealWorldPromptVariant {
  const RealWorldPromptVariant({
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

  factory RealWorldPromptVariant.fromJson(
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
      },
    );
    final Map<String, Object?> projection = requireObject(json, 'projection');
    final RealWorldPromptVariant result = RealWorldPromptVariant(
      variant: variant,
      systemPrompt: requireString(json, 'systemPrompt'),
      userPrompt: requireString(json, 'userPrompt'),
      projection: Map<String, Object?>.unmodifiable(projection),
      metadata: Map<String, Object?>.unmodifiable(metadata),
      requestHash: requireSha256(json, 'requestHash'),
    );
    if (result.requestHash != result.calculateHash()) {
      throw const FormatException('Real-world request hash mismatch.');
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

class RealWorldAdapterCase {
  const RealWorldAdapterCase({
    required this.scenarioId,
    required this.generationInputHash,
    required this.baseline,
    required this.candidate,
  });

  final String scenarioId;
  final String generationInputHash;
  final RealWorldPromptVariant baseline;
  final RealWorldPromptVariant candidate;

  factory RealWorldAdapterCase.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'scenarioId',
        'generationInputHash',
        'baseline',
        'candidate',
      },
    );
    final RealWorldAdapterCase result = RealWorldAdapterCase(
      scenarioId: requireString(json, 'scenarioId'),
      generationInputHash: requireSha256(json, 'generationInputHash'),
      baseline: RealWorldPromptVariant.fromJson(
        realWorldBaselineVariant,
        requireObject(json, 'baseline'),
      ),
      candidate: RealWorldPromptVariant.fromJson(
        realWorldCandidateVariant,
        requireObject(json, 'candidate'),
      ),
    );
    result._validateApprovedContractDifferences();
    return result;
  }

  void _validateApprovedContractDifferences() {
    String value(RealWorldPromptVariant item, String key) =>
        item.metadata[key] as String;
    if (value(baseline, 'analysisSchemaVersion') != '1' ||
        value(baseline, 'projectionSchemaVersion') != '1' ||
        value(baseline, 'ruleSetVersion') != 'v2' ||
        value(baseline, 'sourceCatalogVersion') != 'liuyao-evidence/1.0.0' ||
        value(baseline, 'promptPolicyVersion') != 'liuyao-ai-policy/1.0.0' ||
        value(candidate, 'analysisSchemaVersion') != '2' ||
        value(candidate, 'projectionSchemaVersion') != '2' ||
        value(baseline, 'ruleSetId') != canonicalRuleSetId ||
        value(candidate, 'ruleSetId') != canonicalRuleSetId ||
        value(candidate, 'ruleSetVersion') != 'v3' ||
        value(candidate, 'sourceCatalogVersion') != 'liuyao-evidence/1.1.0' ||
        value(candidate, 'promptPolicyVersion') !=
            candidatePromptPolicyVersion) {
      throw const FormatException(
        'Real-world baseline/candidate contract difference is not approved.',
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'scenarioId': scenarioId,
        'generationInputHash': generationInputHash,
        'baseline': baseline.toJson(),
        'candidate': candidate.toJson(),
      };
}

class RealWorldEvalAdapter {
  const RealWorldEvalAdapter({
    required this.generationFixtureHash,
    required this.baselineSourceCommit,
    required this.requestParameters,
    required this.cases,
    required this.hash,
  });

  final String generationFixtureHash;
  final String baselineSourceCommit;
  final GenerationRequestParameters requestParameters;
  final List<RealWorldAdapterCase> cases;
  final String hash;

  factory RealWorldEvalAdapter.fromJson(
    Map<String, Object?> json, {
    required RealWorldGenerationFixture fixture,
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
    if (requireString(json, 'schemaVersion') != realWorldAdapterSchemaVersion ||
        requireSha256(json, 'generationFixtureHash') != fixture.hash ||
        requireString(json, 'baselineSourceCommit') !=
            'e97d94b54b7ac02edcca00b6ab08b8835fad8090') {
      throw const FormatException('Real-world adapter identity mismatch.');
    }
    final List<RealWorldAdapterCase> cases = requireList(json, 'cases')
        .map(
          (value) => RealWorldAdapterCase.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    if (cases.length != fixture.scenarios.length ||
        cases.map((item) => item.scenarioId).toSet().length != cases.length) {
      throw const FormatException('Real-world adapter scenarios mismatch.');
    }
    for (final RealWorldScenario scenario in fixture.scenarios) {
      final RealWorldAdapterCase adapterCase =
          cases.singleWhere((item) => item.scenarioId == scenario.scenarioId);
      if (adapterCase.generationInputHash !=
          sha256Json(fixture.generationInput(scenario))) {
        throw const FormatException('Real-world generation input mismatch.');
      }
    }
    return RealWorldEvalAdapter(
      generationFixtureHash: fixture.hash,
      baselineSourceCommit: requireString(json, 'baselineSourceCommit'),
      requestParameters: GenerationRequestParameters.fromJson(
        requireObject(json, 'requestParameters'),
      ),
      cases: List<RealWorldAdapterCase>.unmodifiable(cases),
      hash: sha256Json(json),
    );
  }

  RealWorldAdapterCase scenario(String id) =>
      cases.singleWhere((item) => item.scenarioId == id);
}

class RealWorldAssetLoader {
  RealWorldAssetLoader(this.repositoryRoot);

  final String repositoryRoot;

  Map<String, Object?> _read(String relativePath) =>
      SafeArtifactReader(root: Directory(repositoryRoot))
          .readJson(relativePath);

  RealWorldGenerationFixture loadGenerationFixture() =>
      RealWorldGenerationFixture.fromJson(
        _read(realWorldGenerationFixtureRelativePath),
      );

  RealWorldJudgeReferenceManifest loadJudgeReferenceManifest() =>
      RealWorldJudgeReferenceManifest.fromJson(
        _read(realWorldJudgeReferenceManifestRelativePath),
      );

  RealWorldJudgeReference loadJudgeReference({
    required RealWorldJudgeReferenceManifest manifest,
  }) {
    final String source =
        SafeArtifactReader(root: Directory(repositoryRoot)).readText(
      realWorldJudgeReferenceRelativePath,
    );
    if (sha256Text(source) != manifest.referenceAssetSha256) {
      throw const EvalFailure('realWorldReferenceAssetDrift');
    }
    final RealWorldJudgeReference reference =
        RealWorldJudgeReference.fromJson(decodeObject(source));
    if (reference.caseId != manifest.caseId) {
      throw const EvalFailure('realWorldReferenceIdentityMismatch');
    }
    return reference;
  }

  RealWorldEvalAdapter loadAdapter(RealWorldGenerationFixture fixture) =>
      RealWorldEvalAdapter.fromJson(
        _read(realWorldAdapterRelativePath),
        fixture: fixture,
      );
}

void _requireUniqueStringList(Map<String, Object?> json, String key) {
  final values = requireStringList(json, key);
  if (values.toSet().length != values.length) {
    throw const FormatException('Real-world judge list contains duplicates.');
  }
}

void _requireExactStringList(
  Map<String, Object?> json,
  String key,
  List<String> expected,
) {
  final actual = requireStringList(json, key);
  if (actual.length != expected.length) {
    throw const FormatException('Real-world judge dimensions changed.');
  }
  for (var index = 0; index < expected.length; index += 1) {
    if (actual[index] != expected[index]) {
      throw const FormatException('Real-world judge dimensions changed.');
    }
  }
}
