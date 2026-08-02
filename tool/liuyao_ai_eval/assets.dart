import 'dart:io';

import 'canonical_json.dart';
import 'constants.dart';
import 'security.dart';

const Set<String> _caseKinds = <String>{'originalBook', 'ruleValidation'};
const Set<String> _evaluationSplits = <String>{'calibration', 'holdout'};
const Set<String> _declaredCohorts = <String>{
  'overall',
  'originalBook',
  'ruleValidation',
  'holdout',
};
const Set<String> _coreDimensions = <String>{
  'evidenceCoverage',
  'conflictExplanation',
  'sourceFidelity',
  'conditionTimingExplanation',
  'questionRelevance',
};

class AllowedSource {
  const AllowedSource({
    required this.sourceId,
    required this.locators,
    required this.exactQuotes,
  });

  final String sourceId;
  final Set<String> locators;
  final Set<String> exactQuotes;

  factory AllowedSource.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{'sourceId', 'locators', 'exactQuotes'},
    );
    return AllowedSource(
      sourceId: requireString(json, 'sourceId'),
      locators: requireStringList(json, 'locators').toSet(),
      exactQuotes: requireStringList(json, 'exactQuotes').toSet(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'locators': locators.toList()..sort(),
        'exactQuotes': exactQuotes.toList()..sort(),
      };
}

class ScoringReference {
  const ScoringReference({
    required this.expectedVerdictTrend,
    required this.requiredConditionIds,
    required this.allowedPanFactIds,
    required this.expectedYongShenActorId,
    required this.allowedTimingIds,
    required this.allowedSources,
  });

  final String? expectedVerdictTrend;
  final Set<String> requiredConditionIds;
  final Set<String> allowedPanFactIds;
  final String? expectedYongShenActorId;
  final Set<String> allowedTimingIds;
  final Map<String, AllowedSource> allowedSources;

  factory ScoringReference.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'expectedVerdictTrend',
        'requiredConditionIds',
        'allowedPanFactIds',
        'expectedYongShenActorId',
        'allowedTimingIds',
        'allowedSources',
      },
    );
    final Object? verdict = json['expectedVerdictTrend'];
    final Object? yongShen = json['expectedYongShenActorId'];
    if (verdict != null && verdict is! String) {
      throw const FormatException('Invalid expected verdict trend.');
    }
    if (yongShen != null && yongShen is! String) {
      throw const FormatException('Invalid expected use-spirit actor.');
    }
    final List<AllowedSource> sources = requireList(json, 'allowedSources')
        .map(
          (Object? value) => AllowedSource.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    final Map<String, AllowedSource> byId = <String, AllowedSource>{};
    for (final AllowedSource source in sources) {
      if (byId.containsKey(source.sourceId)) {
        throw const FormatException(
            'Duplicate source ID in scoring reference.');
      }
      byId[source.sourceId] = source;
    }
    return ScoringReference(
      expectedVerdictTrend: verdict as String?,
      requiredConditionIds:
          requireStringList(json, 'requiredConditionIds').toSet(),
      allowedPanFactIds: requireStringList(json, 'allowedPanFactIds').toSet(),
      expectedYongShenActorId: yongShen as String?,
      allowedTimingIds: requireStringList(json, 'allowedTimingIds').toSet(),
      allowedSources: Map<String, AllowedSource>.unmodifiable(byId),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'expectedVerdictTrend': expectedVerdictTrend,
        'requiredConditionIds': requiredConditionIds.toList()..sort(),
        'allowedPanFactIds': allowedPanFactIds.toList()..sort(),
        'expectedYongShenActorId': expectedYongShenActorId,
        'allowedTimingIds': allowedTimingIds.toList()..sort(),
        'allowedSources': <Object?>[
          for (final String sourceId in (allowedSources.keys.toList()..sort()))
            allowedSources[sourceId]!.toJson(),
        ],
      };
}

class EvalCase {
  const EvalCase({
    required this.caseId,
    required this.caseKind,
    required this.evaluationSplit,
    required this.cohortIds,
    required this.requestInput,
    required this.scoringReference,
  });

  final String caseId;
  final String caseKind;
  final String evaluationSplit;
  final Set<String> cohortIds;
  final Map<String, Object?> requestInput;
  final ScoringReference scoringReference;

  factory EvalCase.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'caseId',
        'caseKind',
        'evaluationSplit',
        'cohortIds',
        'requestInput',
        'scoringReference',
      },
    );
    final String caseId = requireString(json, 'caseId');
    final String caseKind = requireString(json, 'caseKind');
    final String evaluationSplit = requireString(json, 'evaluationSplit');
    if (!_caseKinds.contains(caseKind) ||
        !_evaluationSplits.contains(evaluationSplit)) {
      throw const FormatException('Invalid case kind or evaluation split.');
    }
    if (caseKind == 'ruleValidation' && evaluationSplit != 'calibration') {
      throw const FormatException('Rule-validation cases must be calibration.');
    }
    if (evaluationSplit == 'holdout' && caseKind != 'originalBook') {
      throw const FormatException('Holdout cases must be original-book cases.');
    }
    final Set<String> cohortIds = requireStringList(json, 'cohortIds').toSet();
    final Set<String> expectedCohorts = <String>{
      'overall',
      caseKind,
      evaluationSplit,
    };
    if (!_setEquals(cohortIds, expectedCohorts)) {
      throw const FormatException('Case cohorts do not match case metadata.');
    }
    final Map<String, Object?> requestInput =
        requireObject(json, 'requestInput');
    requireExactKeys(requestInput, <String>{'question', 'projection'});
    requireString(requestInput, 'question');
    _rejectScoringFields(requestInput);
    final ScoringReference scoringReference = ScoringReference.fromJson(
      requireObject(json, 'scoringReference'),
    );
    _validateProjection(
      requireObject(requestInput, 'projection'),
      scoringReference,
    );
    return EvalCase(
      caseId: caseId,
      caseKind: caseKind,
      evaluationSplit: evaluationSplit,
      cohortIds: Set<String>.unmodifiable(cohortIds),
      requestInput: Map<String, Object?>.unmodifiable(requestInput),
      scoringReference: scoringReference,
    );
  }

  bool belongsTo(String cohort) => switch (cohort) {
        'overall' => true,
        'originalBook' || 'ruleValidation' => caseKind == cohort,
        'holdout' => evaluationSplit == 'holdout',
        _ => false,
      };
}

class EvalFixture {
  const EvalFixture({
    required this.fixtureVersion,
    required this.rubricVersion,
    required this.projectionSchemaVersion,
    required this.requestSchemaVersion,
    required this.cases,
    required this.hash,
    this.sourceFixtureVersion,
    this.sourceFixtureHash,
  });

  final String fixtureVersion;
  final String rubricVersion;
  final String projectionSchemaVersion;
  final String requestSchemaVersion;
  final List<EvalCase> cases;
  final String hash;
  final String? sourceFixtureVersion;
  final String? sourceFixtureHash;

  EvalCase caseById(String caseId) => cases.singleWhere(
        (EvalCase value) => value.caseId == caseId,
        orElse: () => throw const FormatException('Unknown evaluation case.'),
      );

  factory EvalFixture.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'fixtureVersion',
        'rubricVersion',
        'projectionSchemaVersion',
        'requestSchemaVersion',
        'cases',
      },
      optional: <String>{'sourceFixtureVersion', 'sourceFixtureHash'},
    );
    final bool hasSourceVersion = json.containsKey('sourceFixtureVersion');
    final bool hasSourceHash = json.containsKey('sourceFixtureHash');
    if (hasSourceVersion != hasSourceHash) {
      throw const FormatException(
        'Evaluation source fixture identity must be complete.',
      );
    }
    final String? sourceFixtureHash =
        hasSourceHash ? requireString(json, 'sourceFixtureHash') : null;
    if (sourceFixtureHash != null &&
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(sourceFixtureHash)) {
      throw const FormatException('Invalid evaluation source fixture hash.');
    }
    if (requireString(json, 'schemaVersion') != evalFixtureVersion ||
        requireString(json, 'fixtureVersion') != evalFixtureVersion ||
        requireString(json, 'rubricVersion') != evalRubricVersion ||
        requireString(json, 'requestSchemaVersion') !=
            evalRequestSchemaVersion) {
      throw const FormatException('Unsupported fixture contract version.');
    }
    final List<EvalCase> cases = requireList(json, 'cases')
        .map(
          (Object? value) =>
              EvalCase.fromJson((value as Map).cast<String, Object?>()),
        )
        .toList(growable: false);
    if (cases.isEmpty ||
        cases.map((EvalCase c) => c.caseId).toSet().length != cases.length) {
      throw const FormatException('Evaluation case IDs must be unique.');
    }
    final List<String> caseIds = cases.map((EvalCase c) => c.caseId).toList();
    final List<String> sortedIds = List<String>.from(caseIds)..sort();
    if (!_listEquals(caseIds, sortedIds)) {
      throw const FormatException('Evaluation cases must use stable ID order.');
    }
    return EvalFixture(
      fixtureVersion: requireString(json, 'fixtureVersion'),
      rubricVersion: requireString(json, 'rubricVersion'),
      projectionSchemaVersion: requireString(json, 'projectionSchemaVersion'),
      requestSchemaVersion: requireString(json, 'requestSchemaVersion'),
      cases: List<EvalCase>.unmodifiable(cases),
      hash: sha256Json(json),
      sourceFixtureVersion:
          hasSourceVersion ? requireString(json, 'sourceFixtureVersion') : null,
      sourceFixtureHash: sourceFixtureHash,
    );
  }
}

class RubricDimension {
  const RubricDimension({
    required this.dimensionId,
    required this.core,
    required this.description,
    required this.anchors,
  });

  final String dimensionId;
  final bool core;
  final String description;
  final Map<int, String> anchors;

  factory RubricDimension.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{'dimensionId', 'core', 'description', 'anchors'},
    );
    final Map<String, Object?> anchors = requireObject(json, 'anchors');
    requireExactKeys(anchors, <String>{'0', '1', '2'});
    return RubricDimension(
      dimensionId: requireString(json, 'dimensionId'),
      core: requireBool(json, 'core'),
      description: requireString(json, 'description'),
      anchors: <int, String>{
        0: requireString(anchors, '0'),
        1: requireString(anchors, '1'),
        2: requireString(anchors, '2'),
      },
    );
  }
}

class EvalRubric {
  const EvalRubric({
    required this.dimensions,
    required this.hardGateIds,
    required this.cohorts,
    required this.hash,
  });

  final List<RubricDimension> dimensions;
  final Set<String> hardGateIds;
  final List<String> cohorts;
  final String hash;

  factory EvalRubric.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'schemaVersion',
        'rubricVersion',
        'scoreMinimum',
        'scoreMaximum',
        'hardGateIds',
        'dimensions',
        'cohorts',
        'dimensionCohortMatrix',
        'judgeContract',
        'holdoutContract',
        'improvementRule',
      },
    );
    if (requireString(json, 'schemaVersion') != evalRubricVersion ||
        requireString(json, 'rubricVersion') != evalRubricVersion ||
        requireInt(json, 'scoreMinimum') != 0 ||
        requireInt(json, 'scoreMaximum') != 2) {
      throw const FormatException('Unsupported rubric contract.');
    }
    final List<RubricDimension> dimensions = requireList(json, 'dimensions')
        .map(
          (Object? value) => RubricDimension.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    final Set<String> dimensionIds =
        dimensions.map((RubricDimension d) => d.dimensionId).toSet();
    if (dimensions.length != 7 || dimensionIds.length != dimensions.length) {
      throw const FormatException('The rubric must contain seven dimensions.');
    }
    final Set<String> actualCore = dimensions
        .where((RubricDimension d) => d.core)
        .map((RubricDimension d) => d.dimensionId)
        .toSet();
    if (!_setEquals(actualCore, _coreDimensions)) {
      throw const FormatException('Core rubric dimensions changed.');
    }
    final List<String> cohorts = requireStringList(json, 'cohorts');
    if (!_setEquals(cohorts.toSet(), _declaredCohorts) ||
        cohorts.length != _declaredCohorts.length) {
      throw const FormatException('Declared rubric cohorts changed.');
    }
    final Set<String> expectedMatrix = <String>{
      for (final String dimension in dimensionIds)
        for (final String cohort in cohorts) '$dimension:$cohort',
    };
    final List<String> matrix =
        requireStringList(json, 'dimensionCohortMatrix');
    if (matrix.length != expectedMatrix.length ||
        !_setEquals(matrix.toSet(), expectedMatrix)) {
      throw const FormatException('Dimension by cohort matrix is incomplete.');
    }
    _validateJudgeContract(requireObject(json, 'judgeContract'));
    _validateHoldoutContract(requireObject(json, 'holdoutContract'));
    _validateImprovementRule(requireObject(json, 'improvementRule'));
    return EvalRubric(
      dimensions: List<RubricDimension>.unmodifiable(dimensions),
      hardGateIds: Set<String>.unmodifiable(
        requireStringList(json, 'hardGateIds').toSet(),
      ),
      cohorts: List<String>.unmodifiable(cohorts),
      hash: sha256Json(json),
    );
  }
}

class EvalAssets {
  EvalAssets(this.repositoryRoot);

  final String repositoryRoot;

  EvalFixture loadFixture() => EvalFixture.fromJson(
        _readObject('tool/liuyao_ai_eval/fixtures/offline_fixture.json'),
      );

  EvalFixture loadCanonicalFixture() {
    final File file = File('$repositoryRoot/$evalCanonicalFixtureRelativePath');
    if (!file.existsSync()) {
      throw const EvalFailure('canonicalV2FixtureMissing');
    }
    final EvalFixture fixture =
        EvalFixture.fromJson(decodeObject(file.readAsStringSync()));
    if (fixture.hash != canonicalV2FixtureHash) {
      throw const EvalFailure('canonicalV2FixtureHashMismatch');
    }
    final Map<String, Object?> source =
        _readObject(evalClassicsFixtureRelativePath);
    if (fixture.sourceFixtureVersion !=
            requireString(source, 'fixtureVersion') ||
        fixture.sourceFixtureHash != sha256Json(source)) {
      throw const EvalFailure('canonicalV2SourceFixtureMismatch');
    }
    return fixture;
  }

  EvalRubric loadRubric() => EvalRubric.fromJson(
        _readObject('tool/liuyao_ai_eval/fixtures/rubric.json'),
      );

  Map<String, Object?> loadOfflineOutputs() =>
      _readObject('tool/liuyao_ai_eval/fixtures/offline_outputs.json');

  FrozenValidation validateFrozenAssets() {
    final Map<String, Object?> templates =
        _readObject('tool/liuyao_ai_eval/frozen/legacy_templates.json');
    final Map<String, Object?> requests =
        _readObject('tool/liuyao_ai_eval/frozen/legacy_e2e_requests.json');
    requireExactKeys(
      templates,
      <String>{'schemaVersion', 'sourceCommit', 'templates'},
    );
    requireExactKeys(
      requests,
      <String>{'schemaVersion', 'sourceCommit', 'capturePath', 'requests'},
    );
    if (requireString(templates, 'schemaVersion') !=
            'liuyao-legacy-templates/1.0.0' ||
        requireString(requests, 'schemaVersion') !=
            'liuyao-legacy-e2e-diagnostic/1.0.0' ||
        requireString(templates, 'sourceCommit') !=
            requireString(requests, 'sourceCommit') ||
        !RegExp(r'^[0-9a-f]{40}$')
            .hasMatch(requireString(templates, 'sourceCommit'))) {
      throw const FormatException('Frozen legacy asset identity changed.');
    }
    final Set<String> templateIds = <String>{};
    final Map<String, String> templateHashes = <String, String>{};
    final Map<String, String> templateContents = <String, String>{};
    for (final Object? raw in requireList(templates, 'templates')) {
      final Map<String, Object?> template =
          (raw as Map).cast<String, Object?>();
      requireExactKeys(
        template,
        <String>{'templateId', 'templateType', 'content', 'sha256'},
      );
      final String id = requireString(template, 'templateId');
      final String content = requireString(template, 'content');
      final String expectedHash = requireString(template, 'sha256');
      if (!templateIds.add(id) || sha256Text(content) != expectedHash) {
        throw const FormatException('Frozen template hash mismatch.');
      }
      templateHashes[id] = expectedHash;
      templateContents[id] = content;
    }
    if (!_setEquals(
      templateIds,
      <String>{
        'builtin_liuyao_system',
        'builtin_liuyao_analysis',
        'builtin_liuyao_brief',
      },
    )) {
      throw const FormatException('Frozen template set changed.');
    }
    final List<String> capturePath = requireStringList(requests, 'capturePath');
    if (!_listEquals(
      capturePath,
      <String>[
        'LiuYaoResult',
        'LiuYaoStructuredFormatter',
        'PromptAssembler',
      ],
    )) {
      throw const FormatException('Legacy capture path changed.');
    }
    final List<Map<String, Object?>> requestList = <Map<String, Object?>>[];
    final Set<String> requestIds = <String>{};
    for (final Object? raw in requireList(requests, 'requests')) {
      final Map<String, Object?> request = (raw as Map).cast<String, Object?>();
      _validateFrozenRequest(request, templateIds);
      if (!requestIds.add(requireString(request, 'requestId'))) {
        throw const FormatException('Duplicate frozen request ID.');
      }
      requestList.add(request);
    }
    if (requestList.length != 2) {
      throw const FormatException('Legacy diagnostic request count changed.');
    }
    return FrozenValidation(
      sourceCommit: requireString(templates, 'sourceCommit'),
      templateHashes: Map<String, String>.unmodifiable(templateHashes),
      templateContents: Map<String, String>.unmodifiable(templateContents),
      requests: List<Map<String, Object?>>.unmodifiable(requestList),
      templatesHash: sha256Json(templates),
      requestsHash: sha256Json(requests),
    );
  }

  Map<String, Object?> _readObject(String relativePath) {
    final File file = File('$repositoryRoot/$relativePath');
    if (!file.existsSync()) {
      throw const FormatException('Required evaluator asset is missing.');
    }
    return decodeObject(file.readAsStringSync());
  }
}

class FrozenValidation {
  const FrozenValidation({
    required this.sourceCommit,
    required this.templateHashes,
    required this.templateContents,
    required this.requests,
    required this.templatesHash,
    required this.requestsHash,
  });

  final String sourceCommit;
  final Map<String, String> templateHashes;
  final Map<String, String> templateContents;
  final List<Map<String, Object?>> requests;
  final String templatesHash;
  final String requestsHash;
}

void _validateProjection(
  Map<String, Object?> projection,
  ScoringReference reference,
) {
  if (projection.containsKey('projectionSchemaVersion')) {
    final ScoringReference canonical =
        scoringReferenceFromCanonicalProjection(projection);
    if (sha256Json(canonical.toJson()) != sha256Json(reference.toJson())) {
      throw const FormatException(
        'Canonical projection and scoring reference diverged.',
      );
    }
    return;
  }
  requireExactKeys(
    projection,
    <String>{
      'panFactIds',
      'yongShenActorId',
      'verdictTrend',
      'conditions',
      'timingCandidates',
      'sources',
    },
  );
  final Object? yongShen = projection['yongShenActorId'];
  final Object? verdict = projection['verdictTrend'];
  if ((yongShen != null && yongShen is! String) ||
      (verdict != null && verdict is! String)) {
    throw const FormatException('Projection nullable string is invalid.');
  }
  final Set<String> panFacts =
      requireStringList(projection, 'panFactIds').toSet();
  final Set<String> conditionIds = <String>{};
  for (final Object? raw in requireList(projection, 'conditions')) {
    final Map<String, Object?> condition = (raw as Map).cast<String, Object?>();
    requireExactKeys(condition, <String>{'conditionId', 'hasRescue'});
    conditionIds.add(requireString(condition, 'conditionId'));
    requireBool(condition, 'hasRescue');
  }
  final Set<String> timingIds = <String>{};
  for (final Object? raw in requireList(projection, 'timingCandidates')) {
    final Map<String, Object?> timing = (raw as Map).cast<String, Object?>();
    requireExactKeys(timing, <String>{'timingId', 'triggerValue'});
    timingIds.add(requireString(timing, 'timingId'));
    requireString(timing, 'triggerValue');
  }
  final Map<String, AllowedSource> projectionSources =
      <String, AllowedSource>{};
  for (final Object? raw in requireList(projection, 'sources')) {
    final AllowedSource source =
        AllowedSource.fromJson((raw as Map).cast<String, Object?>());
    projectionSources[source.sourceId] = source;
  }
  if (verdict != reference.expectedVerdictTrend ||
      yongShen != reference.expectedYongShenActorId ||
      !_setEquals(panFacts, reference.allowedPanFactIds) ||
      !_setEquals(conditionIds, reference.requiredConditionIds) ||
      !_setEquals(timingIds, reference.allowedTimingIds) ||
      sha256Json(
            projectionSources.map(
              (String key, AllowedSource value) =>
                  MapEntry<String, Object?>(key, value.toJson()),
            ),
          ) !=
          sha256Json(
            reference.allowedSources.map(
              (String key, AllowedSource value) =>
                  MapEntry<String, Object?>(key, value.toJson()),
            ),
          )) {
    throw const FormatException('Projection and scoring reference diverged.');
  }
}

ScoringReference scoringReferenceFromCanonicalProjection(
  Map<String, Object?> projection,
) {
  requireExactKeys(
    projection,
    <String>{
      'projectionSchemaVersion',
      'analysisSchemaVersion',
      'ruleSetId',
      'ruleSetVersion',
      'sourceCatalogVersion',
      'status',
      'diagnostics',
      'analysisStages',
      'policy',
      'pan',
      'useSpirit',
      'roles',
      'selectedUseSpiritFacts',
      'actorAvailability',
      'directedEffects',
      'auxiliaryEvidence',
      'conflicts',
      'factors',
      'verdict',
      'conditions',
      'timingCandidates',
      'sources',
      'trace',
    },
  );
  if (requireInt(projection, 'projectionSchemaVersion') != 1 ||
      requireInt(projection, 'analysisSchemaVersion') != 1 ||
      requireString(projection, 'ruleSetId') != canonicalRuleSetId ||
      requireString(projection, 'ruleSetVersion') != canonicalRuleSetVersion) {
    throw const FormatException('Canonical projection identity mismatch.');
  }
  requireString(projection, 'sourceCatalogVersion');
  requireString(projection, 'status');
  requireStringList(projection, 'diagnostics');
  requireStringList(projection, 'analysisStages');

  final Map<String, Object?> policy = requireObject(projection, 'policy');
  requireExactKeys(
    policy,
    <String>{
      'calculationOwner',
      'mayRecalculatePan',
      'mayRecalculateAnalysis',
      'mayReselectYongShen',
      'mayOverrideVerdict',
      'mayInventSources',
      'mayInventTiming',
      'timingIsGuarantee',
      'maySuggestYongShen',
    },
  );
  if (requireString(policy, 'calculationOwner') != 'program' ||
      requireBool(policy, 'mayRecalculatePan') ||
      requireBool(policy, 'mayRecalculateAnalysis') ||
      requireBool(policy, 'mayReselectYongShen') ||
      requireBool(policy, 'mayOverrideVerdict') ||
      requireBool(policy, 'mayInventSources') ||
      requireBool(policy, 'mayInventTiming') ||
      requireBool(policy, 'timingIsGuarantee')) {
    throw const FormatException('Canonical projection policy mismatch.');
  }
  requireBool(policy, 'maySuggestYongShen');

  final Map<String, Object?> useSpirit = requireObject(projection, 'useSpirit');
  requireExactKeys(
    useSpirit,
    <String>{
      'mode',
      'userOverride',
      'maySuggestCandidates',
      'position',
      'selectedActorId',
    },
  );
  final String mode = requireString(useSpirit, 'mode');
  if (!<String>{'selectedVisible', 'selectedHidden', 'unselected'}
      .contains(mode)) {
    throw const FormatException('Canonical use-spirit mode is invalid.');
  }
  requireBool(useSpirit, 'userOverride');
  requireBool(useSpirit, 'maySuggestCandidates');
  final Object? position = useSpirit['position'];
  final Object? selectedActorId = useSpirit['selectedActorId'];
  if ((position != null && position is! int) ||
      (selectedActorId != null && selectedActorId is! String)) {
    throw const FormatException('Canonical use-spirit value is invalid.');
  }

  String? expectedVerdictTrend;
  final Object? verdictRaw = projection['verdict'];
  if (verdictRaw != null) {
    if (verdictRaw is! Map) {
      throw const FormatException('Canonical verdict is invalid.');
    }
    final Map<String, Object?> verdict = verdictRaw.cast<String, Object?>();
    requireExactKeys(
      verdict,
      <String>{'trend', 'nuance', 'summary', 'matchedDecisionRowId'},
    );
    expectedVerdictTrend = requireString(verdict, 'trend');
    _requireNullableString(verdict, 'nuance');
    requireString(verdict, 'summary');
    requireString(verdict, 'matchedDecisionRowId');
  }

  final Set<String> conditionIds = <String>{};
  for (final Object? raw in requireList(projection, 'conditions')) {
    final Map<String, Object?> condition = (raw as Map).cast<String, Object?>();
    requireExactKeys(
      condition,
      <String>{
        'conditionId',
        'conditionRuleId',
        'label',
        'branch',
        'reason',
        'hasRescue',
        'status',
        'sourceIds',
        'upstreamOccurrenceIds',
      },
    );
    conditionIds.add(requireString(condition, 'conditionId'));
    requireString(condition, 'conditionRuleId');
    requireString(condition, 'label');
    requireString(condition, 'branch');
    requireString(condition, 'reason');
    requireBool(condition, 'hasRescue');
    requireString(condition, 'status');
    requireStringList(condition, 'sourceIds');
    requireStringList(condition, 'upstreamOccurrenceIds');
  }
  final Set<String> timingIds = <String>{};
  for (final Object? raw in requireList(projection, 'timingCandidates')) {
    final Map<String, Object?> timing = (raw as Map).cast<String, Object?>();
    requireExactKeys(
      timing,
      <String>{
        'timingId',
        'timingRuleId',
        'label',
        'branch',
        'scale',
        'triggerKind',
        'triggerValue',
        'targetActorId',
        'reason',
        'priority',
        'upstreamConditionIds',
        'upstreamRuleIds',
        'sourceIds',
      },
    );
    timingIds.add(requireString(timing, 'timingId'));
    requireString(timing, 'timingRuleId');
    requireString(timing, 'label');
    requireString(timing, 'branch');
    requireString(timing, 'scale');
    requireString(timing, 'triggerKind');
    requireString(timing, 'triggerValue');
    requireString(timing, 'targetActorId');
    requireString(timing, 'reason');
    requireInt(timing, 'priority');
    requireStringList(timing, 'upstreamConditionIds');
    requireStringList(timing, 'upstreamRuleIds');
    requireStringList(timing, 'sourceIds');
  }

  final Map<String, AllowedSource> sources = <String, AllowedSource>{};
  for (final Object? raw in requireList(projection, 'sources')) {
    final Map<String, Object?> source = (raw as Map).cast<String, Object?>();
    requireExactKeys(
      source,
      <String>{
        'sourceId',
        'kind',
        'title',
        'edition',
        'revisionOrFingerprint',
        'publicLocator',
        'pageSystem',
        'adoptionStatus',
        'scope',
        'adjudication',
        'reviewedOn',
        'references',
      },
      optional: <String>{'limitations'},
    );
    final String sourceId = requireString(source, 'sourceId');
    for (final String key in <String>{
      'kind',
      'title',
      'edition',
      'revisionOrFingerprint',
      'publicLocator',
      'pageSystem',
      'adoptionStatus',
      'scope',
      'adjudication',
      'reviewedOn',
    }) {
      requireString(source, key);
    }
    if (source.containsKey('limitations')) {
      requireString(source, 'limitations');
    }
    final Set<String> locators = <String>{};
    final Set<String> exactQuotes = <String>{};
    for (final Object? referenceRaw in requireList(source, 'references')) {
      final Map<String, Object?> reference =
          (referenceRaw as Map).cast<String, Object?>();
      requireExactKeys(
        reference,
        <String>{
          'ruleId',
          'primaryTerm',
          'locator',
          'evidenceLevel',
          'referenceKind',
          'adoptionNote',
        },
        optional: <String>{'quote', 'reviewer'},
      );
      requireString(reference, 'ruleId');
      requireString(reference, 'primaryTerm');
      locators.add(requireString(reference, 'locator'));
      requireString(reference, 'evidenceLevel');
      final String referenceKind = requireString(reference, 'referenceKind');
      requireString(reference, 'adoptionNote');
      if (reference.containsKey('reviewer')) {
        requireString(reference, 'reviewer');
      }
      if (reference.containsKey('quote')) {
        final String quote = requireString(reference, 'quote');
        if (referenceKind != 'exactQuote') {
          throw const FormatException(
            'Only exact-quote references may carry quote text.',
          );
        }
        exactQuotes.add(quote);
      }
    }
    if (sources.containsKey(sourceId)) {
      throw const FormatException('Duplicate canonical projection source.');
    }
    sources[sourceId] = AllowedSource(
      sourceId: sourceId,
      locators: Set<String>.unmodifiable(locators),
      exactQuotes: Set<String>.unmodifiable(exactQuotes),
    );
  }

  for (final String listKey in <String>{
    'roles',
    'selectedUseSpiritFacts',
    'actorAvailability',
    'directedEffects',
    'auxiliaryEvidence',
    'conflicts',
    'factors',
    'trace',
  }) {
    requireList(projection, listKey);
  }
  if (mode == 'unselected' &&
      (expectedVerdictTrend != null ||
          conditionIds.isNotEmpty ||
          timingIds.isNotEmpty ||
          selectedActorId != null)) {
    throw const FormatException(
      'Unselected canonical projection contains program conclusions.',
    );
  }
  if (mode != 'unselected' &&
      (expectedVerdictTrend == null || selectedActorId == null)) {
    throw const FormatException(
      'Selected canonical projection is missing program conclusions.',
    );
  }
  return ScoringReference(
    expectedVerdictTrend: expectedVerdictTrend,
    requiredConditionIds: Set<String>.unmodifiable(conditionIds),
    allowedPanFactIds: Set<String>.unmodifiable(
      _canonicalPanFactIds(requireObject(projection, 'pan')),
    ),
    expectedYongShenActorId: selectedActorId as String?,
    allowedTimingIds: Set<String>.unmodifiable(timingIds),
    allowedSources: Map<String, AllowedSource>.unmodifiable(sources),
  );
}

Set<String> _canonicalPanFactIds(Map<String, Object?> pan) {
  requireExactKeys(
    pan,
    <String>{
      'castMethod',
      'mainGua',
      'changingGua',
      'hasChangingGua',
      'calendar',
      'liuShen',
    },
  );
  final Set<String> facts = <String>{
    'pan.castMethod=${requireString(pan, 'castMethod')}',
  };
  void addGua(String label, Map<String, Object?> gua) {
    requireExactKeys(
      gua,
      <String>{
        'id',
        'name',
        'palace',
        'specialType',
        'shiPosition',
        'yingPosition',
        'yaos',
      },
    );
    facts
      ..add('pan.$label.id=${requireString(gua, 'id')}')
      ..add('pan.$label.name=${requireString(gua, 'name')}')
      ..add('pan.$label.palace=${requireString(gua, 'palace')}')
      ..add(
        'pan.$label.specialType=${requireString(gua, 'specialType')}',
      )
      ..add(
        'pan.$label.shiPosition=${requireInt(gua, 'shiPosition')}',
      )
      ..add(
        'pan.$label.yingPosition=${requireInt(gua, 'yingPosition')}',
      );
    for (final Object? raw in requireList(gua, 'yaos')) {
      final Map<String, Object?> yao = (raw as Map).cast<String, Object?>();
      requireExactKeys(
        yao,
        <String>{
          'position',
          'number',
          'stem',
          'branch',
          'wuXing',
          'liuQin',
          'isYang',
          'isMoving',
          'isShi',
          'isYing',
        },
      );
      final int yaoPosition = requireInt(yao, 'position');
      facts
        ..add(
          'pan.$label.yao.$yaoPosition.number=${requireInt(yao, 'number')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.stem=${requireString(yao, 'stem')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.branch=${requireString(yao, 'branch')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.wuXing=${requireString(yao, 'wuXing')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.liuQin=${requireString(yao, 'liuQin')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.isYang=${requireBool(yao, 'isYang')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.isMoving=${requireBool(yao, 'isMoving')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.isShi=${requireBool(yao, 'isShi')}',
        )
        ..add(
          'pan.$label.yao.$yaoPosition.isYing=${requireBool(yao, 'isYing')}',
        );
    }
  }

  addGua('mainGua', requireObject(pan, 'mainGua'));
  final bool hasChangingGua = requireBool(pan, 'hasChangingGua');
  facts.add('pan.hasChangingGua=$hasChangingGua');
  final Object? changingRaw = pan['changingGua'];
  if (changingRaw == null) {
    if (hasChangingGua) {
      throw const FormatException('Changing-gua presence flag diverged.');
    }
  } else {
    if (!hasChangingGua || changingRaw is! Map) {
      throw const FormatException('Changing-gua presence flag diverged.');
    }
    addGua('changingGua', changingRaw.cast<String, Object?>());
  }

  final Map<String, Object?> calendar = requireObject(pan, 'calendar');
  requireExactKeys(
    calendar,
    <String>{
      'yearGanZhi',
      'monthGanZhi',
      'dayGanZhi',
      'hourGanZhi',
      'yueJian',
      'kongWang',
    },
  );
  for (final String key in <String>{
    'yearGanZhi',
    'monthGanZhi',
    'dayGanZhi',
    'yueJian',
  }) {
    facts.add('pan.calendar.$key=${requireString(calendar, key)}');
  }
  final String? hourGanZhi = _requireNullableString(calendar, 'hourGanZhi');
  facts.add('pan.calendar.hourGanZhi=${hourGanZhi ?? 'null'}');
  for (final String branch in requireStringList(calendar, 'kongWang')) {
    facts.add('pan.calendar.kongWang=$branch');
  }
  final List<String> liuShen = requireStringList(pan, 'liuShen');
  for (int index = 0; index < liuShen.length; index += 1) {
    facts.add('pan.liuShen.${index + 1}=${liuShen[index]}');
  }
  return facts;
}

String? _requireNullableString(Map<String, Object?> value, String key) {
  final Object? raw = value[key];
  if (raw != null && raw is! String) {
    throw const FormatException('Expected a nullable string.');
  }
  return raw as String?;
}

void _rejectScoringFields(Object? value) {
  const Set<String> forbidden = <String>{
    'expectedTrend',
    'expectedFactors',
    'expectedConditions',
    'recordedOutcome',
    'scoringReference',
  };
  if (value is Map) {
    for (final Object? key in value.keys) {
      if (key is! String || forbidden.contains(key)) {
        throw const FormatException('Scoring data leaked into model input.');
      }
    }
    for (final Object? item in value.values) {
      _rejectScoringFields(item);
    }
  } else if (value is List) {
    for (final Object? item in value) {
      _rejectScoringFields(item);
    }
  }
}

void _validateJudgeContract(Map<String, Object?> json) {
  requireExactKeys(
    json,
    <String>{
      'reuseGenerationEndpoint',
      'reuseExactGenerationModel',
      'temperature',
      'maxCompletionTokens',
      'responseFormat',
      'seed',
      'blindOrderSalt',
    },
  );
  if (!requireBool(json, 'reuseGenerationEndpoint') ||
      !requireBool(json, 'reuseExactGenerationModel') ||
      requireInt(json, 'temperature') != 0 ||
      requireInt(json, 'maxCompletionTokens') != 2048 ||
      requireString(json, 'responseFormat') != 'json' ||
      requireInt(json, 'seed') != judgeSeed ||
      requireString(json, 'blindOrderSalt') != judgeOrderSalt) {
    throw const FormatException('Judge contract changed.');
  }
}

void _validateHoldoutContract(Map<String, Object?> json) {
  requireExactKeys(
    json,
    <String>{
      'selectionSalt',
      'cardinality',
      'revealMarkerIsImmutable',
      'reuseAfterReveal',
    },
  );
  if (requireString(json, 'selectionSalt') != holdoutSelectionSalt ||
      requireInt(json, 'cardinality') != 6 ||
      !requireBool(json, 'revealMarkerIsImmutable') ||
      requireString(json, 'reuseAfterReveal') != 'regressionOnly') {
    throw const FormatException('Holdout contract changed.');
  }
}

void _validateImprovementRule(Map<String, Object?> json) {
  requireExactKeys(
    json,
    <String>{
      'minimumMeanDelta',
      'minimumNonTieWinRate',
      'minimumConsistentRepetitions',
      'requiredRepetitions',
      'requiredCohorts',
    },
  );
  if (json['minimumMeanDelta'] != 0.2 ||
      json['minimumNonTieWinRate'] != 0.6 ||
      requireInt(json, 'minimumConsistentRepetitions') != 2 ||
      requireInt(json, 'requiredRepetitions') != 3 ||
      !_setEquals(
        requireStringList(json, 'requiredCohorts').toSet(),
        <String>{'overall', 'holdout'},
      )) {
    throw const FormatException('Improvement rule changed.');
  }
}

void _validateFrozenRequest(
  Map<String, Object?> request,
  Set<String> templateIds,
) {
  requireExactKeys(
    request,
    <String>{
      'requestId',
      'analysisType',
      'systemTemplateId',
      'analysisTemplateId',
      'systemPrompt',
      'userPrompt',
      'structuredOutput',
      'systemPromptSha256',
      'userPromptSha256',
      'structuredOutputSha256',
      'requestSha256',
      'requestParameters',
    },
  );
  final String systemTemplateId = requireString(request, 'systemTemplateId');
  final String analysisTemplateId =
      requireString(request, 'analysisTemplateId');
  if (!templateIds.contains(systemTemplateId) ||
      !templateIds.contains(analysisTemplateId)) {
    throw const FormatException('Frozen request references unknown template.');
  }
  final String systemPrompt = requireString(request, 'systemPrompt');
  final String userPrompt = requireString(request, 'userPrompt');
  final Map<String, Object?> structuredOutput =
      requireObject(request, 'structuredOutput');
  final Map<String, Object?> parameters =
      requireObject(request, 'requestParameters');
  requireExactKeys(
    parameters,
    <String>{
      'stream',
      'temperature',
      'maxTokens',
      'responseFormat',
      'stop',
    },
  );
  if (requireBool(parameters, 'stream') ||
      requireInt(parameters, 'temperature') != 0 ||
      requireInt(parameters, 'maxTokens') != 2048 ||
      requireString(parameters, 'responseFormat') != 'text' ||
      requireList(parameters, 'stop').isNotEmpty) {
    throw const FormatException('Frozen request parameters changed.');
  }
  if (sha256Text(systemPrompt) !=
      requireString(request, 'systemPromptSha256')) {
    throw const FormatException('Frozen system prompt hash mismatch.');
  }
  if (sha256Text(userPrompt) != requireString(request, 'userPromptSha256')) {
    throw const FormatException('Frozen user prompt hash mismatch.');
  }
  final String actualStructuredOutputHash = sha256Json(structuredOutput);
  final String expectedStructuredOutputHash =
      requireString(request, 'structuredOutputSha256');
  if (actualStructuredOutputHash != expectedStructuredOutputHash) {
    throw FormatException(
      'Frozen structured output hash mismatch: '
      '$expectedStructuredOutputHash != $actualStructuredOutputHash.',
    );
  }
  final Map<String, Object?> envelope = <String, Object?>{
    'messages': <Object?>[
      <String, Object?>{'role': 'system', 'content': systemPrompt},
      <String, Object?>{'role': 'user', 'content': userPrompt},
    ],
    'stream': parameters['stream'],
    'temperature': parameters['temperature'],
    'maxTokens': parameters['maxTokens'],
    'responseFormat': parameters['responseFormat'],
    'stop': parameters['stop'],
  };
  if (sha256Json(envelope) != requireString(request, 'requestSha256')) {
    throw const FormatException('Frozen request envelope hash mismatch.');
  }
}

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

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
