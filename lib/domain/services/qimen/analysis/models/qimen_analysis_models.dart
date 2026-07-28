import 'dart:convert';

import '../../../shared/analysis/models/polarity.dart';
import '../../../shared/analysis/models/verdict_models.dart';
import 'qimen_rule_models.dart';
import 'qimen_ying_qi_models.dart';
import '../rules/qimen_rule_catalog.dart';
import '../rules/qimen_source_catalog.dart';

enum QimenAnalysisStatus {
  complete('complete'),
  unsupportedPanSchema('unsupportedPanSchema'),
  invalidPanFacts('invalidPanFacts');

  const QimenAnalysisStatus(this.id);
  final String id;

  static QimenAnalysisStatus fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () =>
            throw FormatException('Unknown Qimen analysis status: $id'),
      );
}

enum QimenFactCategory {
  starState('starState'),
  doorState('doorState'),
  constraint('constraint'),
  structure('structure'),
  stemResponse('stemResponse'),
  formation('formation'),
  relation('relation'),
  activation('activation');

  const QimenFactCategory(this.id);
  final String id;

  static QimenFactCategory fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen fact category: $id'),
      );
}

enum QimenIndicatorKind {
  stem('stem'),
  star('star'),
  door('door'),
  deity('deity'),
  marker('marker'),
  dutyStar('dutyStar'),
  dutyDoor('dutyDoor');

  const QimenIndicatorKind(this.id);
  final String id;

  static QimenIndicatorKind fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () =>
            throw FormatException('Unknown Qimen indicator kind: $id'),
      );
}

enum QimenFocusPriority {
  primary('primary'),
  secondary('secondary');

  const QimenFocusPriority(this.id);
  final String id;

  static QimenFocusPriority fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () =>
            throw FormatException('Unknown Qimen focus priority: $id'),
      );
}

enum QimenTraceStage {
  input('input'),
  focus('focus'),
  fact('fact'),
  conflict('conflict'),
  verdict('verdict'),
  yingQi('yingQi');

  const QimenTraceStage(this.id);
  final String id;

  static QimenTraceStage fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen trace stage: $id'),
      );
}

enum QimenEvaluationStatus {
  matched('matched'),
  notMatched('notMatched'),
  notApplicable('notApplicable'),
  suppressed('suppressed');

  const QimenEvaluationStatus(this.id);
  final String id;

  static QimenEvaluationStatus fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () =>
            throw FormatException('Unknown Qimen evaluation status: $id'),
      );
}

class QimenFocus {
  QimenFocus({
    required this.roleId,
    required this.indicatorKind,
    required this.indicatorValue,
    required this.palaceNumber,
    required this.originPalaceNumber,
    required this.priority,
    required this.isHosted,
    required this.reason,
    required this.ruleId,
    required List<String> sourceIds,
  }) : sourceIds = List<String>.unmodifiable(sourceIds);

  final String roleId;
  final QimenIndicatorKind indicatorKind;
  final String indicatorValue;
  final int palaceNumber;
  final int originPalaceNumber;
  final QimenFocusPriority priority;
  final bool isHosted;
  final String reason;
  final String ruleId;
  final List<String> sourceIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roleId': roleId,
        'indicatorKind': indicatorKind.id,
        'indicatorValue': indicatorValue,
        'palaceNumber': palaceNumber,
        'originPalaceNumber': originPalaceNumber,
        'priority': priority.id,
        'isHosted': isHosted,
        'reason': reason,
        'ruleId': ruleId,
        'sourceIds': sourceIds,
      };

  factory QimenFocus.fromJson(Map<String, dynamic> json) => QimenFocus(
        roleId: json['roleId'] as String,
        indicatorKind:
            QimenIndicatorKind.fromId(json['indicatorKind'] as String),
        indicatorValue: json['indicatorValue'] as String,
        palaceNumber: json['palaceNumber'] as int,
        originPalaceNumber: json['originPalaceNumber'] as int,
        priority: QimenFocusPriority.fromId(json['priority'] as String),
        isHosted: json['isHosted'] as bool,
        reason: json['reason'] as String,
        ruleId: json['ruleId'] as String,
        sourceIds: List<String>.from(json['sourceIds'] as List),
      );
}

class QimenFact {
  QimenFact({
    required this.occurrenceId,
    required this.ruleId,
    required this.ruleSetVersion,
    required this.category,
    required this.polarity,
    required this.role,
    required this.scope,
    required List<int> relatedPalaceNumbers,
    required List<String> relatedFocusRoleIds,
    required this.reason,
    required List<QimenInputRef> inputRefs,
    required List<String> sourceIds,
    required this.traceStepId,
    required this.conflictTier,
  })  : relatedPalaceNumbers = List<int>.unmodifiable(relatedPalaceNumbers),
        relatedFocusRoleIds = List<String>.unmodifiable(relatedFocusRoleIds),
        inputRefs = List<QimenInputRef>.unmodifiable(inputRefs),
        sourceIds = List<String>.unmodifiable(sourceIds);

  final String occurrenceId;
  final String ruleId;
  final String ruleSetVersion;
  final QimenFactCategory category;
  final Polarity polarity;
  final QimenFactRole role;
  final QimenFactScope scope;
  final List<int> relatedPalaceNumbers;
  final List<String> relatedFocusRoleIds;
  final String reason;
  final List<QimenInputRef> inputRefs;
  final List<String> sourceIds;
  final String traceStepId;
  final QimenConflictTier conflictTier;

  bool get affectsPrimaryFocus => relatedFocusRoleIds.any(
        (role) => role == 'self' || role == 'matter',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'occurrenceId': occurrenceId,
        'ruleId': ruleId,
        'ruleSetVersion': ruleSetVersion,
        'category': category.id,
        'polarity': qimenPolarityId(polarity),
        'role': role.id,
        'scope': scope.id,
        'relatedPalaceNumbers': relatedPalaceNumbers,
        'relatedFocusRoleIds': relatedFocusRoleIds,
        'reason': reason,
        'inputRefs': inputRefs.map((value) => value.toJson()).toList(),
        'sourceIds': sourceIds,
        'traceStepId': traceStepId,
        'conflictTier': conflictTier.id,
      };

  factory QimenFact.fromJson(Map<String, dynamic> json) => QimenFact(
        occurrenceId: json['occurrenceId'] as String,
        ruleId: json['ruleId'] as String,
        ruleSetVersion: json['ruleSetVersion'] as String,
        category: QimenFactCategory.fromId(json['category'] as String),
        polarity: qimenPolarityFromId(json['polarity'] as String),
        role: QimenFactRole.fromId(json['role'] as String),
        scope: QimenFactScope.fromId(json['scope'] as String),
        relatedPalaceNumbers:
            List<int>.from(json['relatedPalaceNumbers'] as List),
        relatedFocusRoleIds:
            List<String>.from(json['relatedFocusRoleIds'] as List),
        reason: json['reason'] as String,
        inputRefs: (json['inputRefs'] as List)
            .map((value) => QimenInputRef.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        sourceIds: List<String>.from(json['sourceIds'] as List),
        traceStepId: json['traceStepId'] as String,
        conflictTier: QimenConflictTier.fromId(json['conflictTier'] as String),
      );
}

class QimenTraceStep {
  QimenTraceStep({
    required this.stepId,
    required this.sequence,
    required this.stage,
    required this.ruleId,
    required this.status,
    required List<QimenInputRef> inputRefs,
    required List<String> outputOccurrenceIds,
    required List<String> sourceIds,
    required this.explanation,
  })  : inputRefs = List<QimenInputRef>.unmodifiable(inputRefs),
        outputOccurrenceIds = List<String>.unmodifiable(outputOccurrenceIds),
        sourceIds = List<String>.unmodifiable(sourceIds);

  final String stepId;
  final int sequence;
  final QimenTraceStage stage;
  final String ruleId;
  final QimenEvaluationStatus status;
  final List<QimenInputRef> inputRefs;
  final List<String> outputOccurrenceIds;
  final List<String> sourceIds;
  final String explanation;

  QimenTraceStep copyWith({
    String? stepId,
    int? sequence,
    QimenEvaluationStatus? status,
    String? explanation,
  }) =>
      QimenTraceStep(
        stepId: stepId ?? this.stepId,
        sequence: sequence ?? this.sequence,
        stage: stage,
        ruleId: ruleId,
        status: status ?? this.status,
        inputRefs: inputRefs,
        outputOccurrenceIds: outputOccurrenceIds,
        sourceIds: sourceIds,
        explanation: explanation ?? this.explanation,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stepId': stepId,
        'sequence': sequence,
        'stage': stage.id,
        'ruleId': ruleId,
        'status': status.id,
        'inputRefs': inputRefs.map((value) => value.toJson()).toList(),
        'outputOccurrenceIds': outputOccurrenceIds,
        'sourceIds': sourceIds,
        'explanation': explanation,
      };

  factory QimenTraceStep.fromJson(Map<String, dynamic> json) => QimenTraceStep(
        stepId: json['stepId'] as String,
        sequence: json['sequence'] as int,
        stage: QimenTraceStage.fromId(json['stage'] as String),
        ruleId: json['ruleId'] as String,
        status: QimenEvaluationStatus.fromId(json['status'] as String),
        inputRefs: (json['inputRefs'] as List)
            .map((value) => QimenInputRef.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
        outputOccurrenceIds:
            List<String>.from(json['outputOccurrenceIds'] as List),
        sourceIds: List<String>.from(json['sourceIds'] as List),
        explanation: json['explanation'] as String,
      );
}

class QimenConflictResolution {
  QimenConflictResolution({
    required this.resolutionId,
    required this.policyId,
    required List<String> contenderOccurrenceIds,
    required List<String> suppressedOccurrenceIds,
    required this.reason,
    this.winnerOccurrenceId,
  })  : contenderOccurrenceIds =
            List<String>.unmodifiable(contenderOccurrenceIds),
        suppressedOccurrenceIds =
            List<String>.unmodifiable(suppressedOccurrenceIds);

  final String resolutionId;
  final String policyId;
  final List<String> contenderOccurrenceIds;
  final String? winnerOccurrenceId;
  final List<String> suppressedOccurrenceIds;
  final String reason;

  bool get isUnresolved => winnerOccurrenceId == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'resolutionId': resolutionId,
        'policyId': policyId,
        'contenderOccurrenceIds': contenderOccurrenceIds,
        'winnerOccurrenceId': winnerOccurrenceId,
        'suppressedOccurrenceIds': suppressedOccurrenceIds,
        'reason': reason,
      };

  factory QimenConflictResolution.fromJson(Map<String, dynamic> json) =>
      QimenConflictResolution(
        resolutionId: json['resolutionId'] as String,
        policyId: json['policyId'] as String,
        contenderOccurrenceIds:
            List<String>.from(json['contenderOccurrenceIds'] as List),
        winnerOccurrenceId: json['winnerOccurrenceId'] as String?,
        suppressedOccurrenceIds:
            List<String>.from(json['suppressedOccurrenceIds'] as List),
        reason: json['reason'] as String,
      );
}

class QimenVerdictCondition {
  QimenVerdictCondition({
    required this.conditionId,
    required this.sourceFactId,
    required this.ruleId,
    required this.condition,
    required this.releaseTriggerKind,
    required this.releaseTriggerValue,
    required this.releaseScale,
    required List<String> sourceIds,
  }) : sourceIds = List<String>.unmodifiable(sourceIds);

  final String conditionId;
  final String sourceFactId;
  final String ruleId;
  final VerdictCondition condition;
  final String releaseTriggerKind;
  final String releaseTriggerValue;
  final YingQiScale releaseScale;
  final List<String> sourceIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'conditionId': conditionId,
        'sourceFactId': sourceFactId,
        'ruleId': ruleId,
        'condition': qimenConditionToJson(condition),
        'releaseTriggerKind': releaseTriggerKind,
        'releaseTriggerValue': releaseTriggerValue,
        'releaseScale': qimenYingQiScaleId(releaseScale),
        'sourceIds': sourceIds,
      };

  factory QimenVerdictCondition.fromJson(Map<String, dynamic> json) =>
      QimenVerdictCondition(
        conditionId: json['conditionId'] as String,
        sourceFactId: json['sourceFactId'] as String,
        ruleId: json['ruleId'] as String,
        condition: qimenConditionFromJson(
          Map<String, dynamic>.from(json['condition'] as Map),
        ),
        releaseTriggerKind: json['releaseTriggerKind'] as String,
        releaseTriggerValue: json['releaseTriggerValue'] as String,
        releaseScale: qimenYingQiScaleFromId(json['releaseScale'] as String),
        sourceIds: List<String>.from(json['sourceIds'] as List),
      );
}

class QimenVerdictResult {
  QimenVerdictResult({
    required this.judgment,
    required this.matchedDecisionRowId,
    required List<String> participatingFactIds,
    required List<String> conflictResolutionIds,
    required List<String> sourceIds,
    required List<QimenVerdictCondition> conditionLinks,
  })  : participatingFactIds = List<String>.unmodifiable(participatingFactIds),
        conflictResolutionIds =
            List<String>.unmodifiable(conflictResolutionIds),
        sourceIds = List<String>.unmodifiable(sourceIds),
        conditionLinks =
            List<QimenVerdictCondition>.unmodifiable(conditionLinks);

  final VerdictJudgment judgment;
  final String matchedDecisionRowId;
  final List<String> participatingFactIds;
  final List<String> conflictResolutionIds;
  final List<String> sourceIds;
  final List<QimenVerdictCondition> conditionLinks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'judgment': qimenJudgmentToJson(judgment),
        'matchedDecisionRowId': matchedDecisionRowId,
        'participatingFactIds': participatingFactIds,
        'conflictResolutionIds': conflictResolutionIds,
        'sourceIds': sourceIds,
        'conditionLinks':
            conditionLinks.map((value) => value.toJson()).toList(),
      };

  factory QimenVerdictResult.fromJson(Map<String, dynamic> json) =>
      QimenVerdictResult(
        judgment: qimenJudgmentFromJson(
          Map<String, dynamic>.from(json['judgment'] as Map),
        ),
        matchedDecisionRowId: json['matchedDecisionRowId'] as String,
        participatingFactIds:
            List<String>.from(json['participatingFactIds'] as List),
        conflictResolutionIds:
            List<String>.from(json['conflictResolutionIds'] as List),
        sourceIds: List<String>.from(json['sourceIds'] as List),
        conditionLinks: (json['conditionLinks'] as List)
            .map((value) => QimenVerdictCondition.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ))
            .toList(growable: false),
      );
}

class QimenAnalysisCompatibilityException implements Exception {
  const QimenAnalysisCompatibilityException(this.message);

  final String message;

  @override
  String toString() => 'QimenAnalysisCompatibilityException: $message';
}

class QimenAnalysisReport {
  QimenAnalysisReport({
    required this.analysisSchemaVersion,
    required this.ruleSetId,
    required this.ruleSetVersion,
    required this.inputPanSchemaVersion,
    required this.inputResultId,
    required this.status,
    required List<QimenAnalysisDiagnostic> diagnostics,
    required List<QimenSourceRef> sources,
    required List<QimenFocus> focuses,
    required List<QimenFact> facts,
    required List<QimenConflictResolution> conflicts,
    required this.verdict,
    required List<QimenYingQiCandidate> yingQiCandidates,
    required List<QimenTraceStep> trace,
  })  : diagnostics = List<QimenAnalysisDiagnostic>.unmodifiable(diagnostics),
        sources = List<QimenSourceRef>.unmodifiable(sources),
        focuses = List<QimenFocus>.unmodifiable(focuses),
        facts = List<QimenFact>.unmodifiable(facts),
        conflicts = List<QimenConflictResolution>.unmodifiable(conflicts),
        yingQiCandidates =
            List<QimenYingQiCandidate>.unmodifiable(yingQiCandidates),
        trace = List<QimenTraceStep>.unmodifiable(trace);

  static const int currentSchemaVersion = 1;

  final int analysisSchemaVersion;
  final String ruleSetId;
  final String ruleSetVersion;
  final int inputPanSchemaVersion;
  final String inputResultId;
  final QimenAnalysisStatus status;
  final List<QimenAnalysisDiagnostic> diagnostics;
  final List<QimenSourceRef> sources;
  final List<QimenFocus> focuses;
  final List<QimenFact> facts;
  final List<QimenConflictResolution> conflicts;
  final QimenVerdictResult verdict;
  final List<QimenYingQiCandidate> yingQiCandidates;
  final List<QimenTraceStep> trace;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'analysisSchemaVersion': analysisSchemaVersion,
        'ruleSetId': ruleSetId,
        'ruleSetVersion': ruleSetVersion,
        'inputPanSchemaVersion': inputPanSchemaVersion,
        'inputResultId': inputResultId,
        'status': status.id,
        'diagnostics': diagnostics.map((value) => value.toJson()).toList(),
        'sources': sources.map((value) => value.toJson()).toList(),
        'focuses': focuses.map((value) => value.toJson()).toList(),
        'facts': facts.map((value) => value.toJson()).toList(),
        'conflicts': conflicts.map((value) => value.toJson()).toList(),
        'verdict': verdict.toJson(),
        'yingQiCandidates':
            yingQiCandidates.map((value) => value.toJson()).toList(),
        'trace': trace.map((value) => value.toJson()).toList(),
      };

  factory QimenAnalysisReport.fromJson(Map<String, dynamic> json) {
    final schema = json['analysisSchemaVersion'];
    if (schema != currentSchemaVersion) {
      throw QimenAnalysisCompatibilityException(
        'unsupported analysis schema $schema; supported: '
        '$currentSchemaVersion',
      );
    }
    try {
      final report = QimenAnalysisReport(
        analysisSchemaVersion: schema as int,
        ruleSetId: json['ruleSetId'] as String,
        ruleSetVersion: json['ruleSetVersion'] as String,
        inputPanSchemaVersion: json['inputPanSchemaVersion'] as int,
        inputResultId: json['inputResultId'] as String,
        status: QimenAnalysisStatus.fromId(json['status'] as String),
        diagnostics: _decodeList(json, 'diagnostics',
            (value) => QimenAnalysisDiagnostic.fromJson(value)),
        sources: _decodeList(
            json, 'sources', (value) => QimenSourceRef.fromJson(value)),
        focuses:
            _decodeList(json, 'focuses', (value) => QimenFocus.fromJson(value)),
        facts: _decodeList(json, 'facts', (value) => QimenFact.fromJson(value)),
        conflicts: _decodeList(json, 'conflicts',
            (value) => QimenConflictResolution.fromJson(value)),
        verdict: QimenVerdictResult.fromJson(
          Map<String, dynamic>.from(json['verdict'] as Map),
        ),
        yingQiCandidates: _decodeList(json, 'yingQiCandidates',
            (value) => QimenYingQiCandidate.fromJson(value)),
        trace: _decodeList(
            json, 'trace', (value) => QimenTraceStep.fromJson(value)),
      );
      validateQimenAnalysisGraph(
        ruleSetId: report.ruleSetId,
        ruleSetVersion: report.ruleSetVersion,
        sources: report.sources,
        focuses: report.focuses,
        facts: report.facts,
        conflicts: report.conflicts,
        verdict: report.verdict,
        yingQiCandidates: report.yingQiCandidates,
        trace: report.trace,
      );
      return report;
    } on QimenAnalysisCompatibilityException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid Qimen analysis report JSON', error);
    }
  }

  String toCanonicalJson() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is QimenAnalysisReport &&
      toCanonicalJson() == other.toCanonicalJson();

  @override
  int get hashCode => toCanonicalJson().hashCode;
}

void validateQimenAnalysisGraph({
  required String ruleSetId,
  required String ruleSetVersion,
  required List<QimenSourceRef> sources,
  required List<QimenFocus> focuses,
  required List<QimenFact> facts,
  required List<QimenConflictResolution> conflicts,
  required QimenVerdictResult verdict,
  required List<QimenYingQiCandidate> yingQiCandidates,
  required List<QimenTraceStep> trace,
  List<QimenInputRef>? panFieldReferences,
}) {
  if (ruleSetId != QimenRuleCatalog.ruleSetId) {
    throw FormatException('Unknown Qimen analysis rule-set: $ruleSetId');
  }
  final ruleSet = QimenRuleCatalog.released[ruleSetVersion];
  if (ruleSet == null) {
    throw FormatException('Unknown Qimen rule-set version: $ruleSetVersion');
  }
  final releasedRuleIds = ruleSet.rules.map((rule) => rule.ruleId).toSet();

  void knownRule(String ruleId, String owner) {
    if (!releasedRuleIds.contains(ruleId)) {
      throw FormatException('Unknown Qimen rule $ruleId in $owner');
    }
  }

  void knownSources(Iterable<String> sourceIds, String owner) {
    _requireUnique(sourceIds, '$owner source ID');
    for (final sourceId in sourceIds) {
      if (!QimenSourceCatalog.byId.containsKey(sourceId)) {
        throw FormatException('Unknown Qimen source $sourceId in $owner');
      }
    }
  }

  _requireUnique(sources.map((source) => source.sourceId), 'source ID');
  _requireUnique(focuses.map((focus) => focus.roleId), 'focus role ID');
  _requireUnique(facts.map((fact) => fact.occurrenceId), 'fact occurrence ID');
  _requireUnique(
    conflicts.map((conflict) => conflict.resolutionId),
    'conflict resolution ID',
  );
  _requireUnique(
    verdict.conditionLinks.map((condition) => condition.conditionId),
    'verdict condition ID',
  );
  _requireUnique(
    yingQiCandidates.map((candidate) => candidate.candidateId),
    'YingQi candidate ID',
  );
  _requireUnique(trace.map((step) => step.stepId), 'trace step ID');
  _requireUnique(trace.map((step) => step.sequence), 'trace sequence');
  final orderedSequences = trace.map((step) => step.sequence).toList()..sort();
  final expectedSequences = List<int>.generate(
    trace.length,
    (index) => index + 1,
  );
  if (!_sameValues(orderedSequences, expectedSequences)) {
    throw const FormatException('Qimen trace sequences must be contiguous');
  }

  final sourcesById = <String, QimenSourceRef>{
    for (final source in sources) source.sourceId: source,
  };
  for (final source in sources) {
    final catalogSource = QimenSourceCatalog.byId[source.sourceId];
    if (catalogSource == null) {
      throw FormatException('Unknown Qimen source ${source.sourceId}');
    }
    if (jsonEncode(source.toJson()) != jsonEncode(catalogSource.toJson())) {
      throw FormatException(
        'Qimen source metadata differs from catalog: ${source.sourceId}',
      );
    }
  }

  final focusesById = <String, QimenFocus>{
    for (final focus in focuses) focus.roleId: focus,
  };
  final factsById = <String, QimenFact>{
    for (final fact in facts) fact.occurrenceId: fact,
  };
  final conflictsById = <String, QimenConflictResolution>{
    for (final conflict in conflicts) conflict.resolutionId: conflict,
  };
  final conditionsById = <String, QimenVerdictCondition>{
    for (final condition in verdict.conditionLinks)
      condition.conditionId: condition,
  };
  final candidatesById = <String, QimenYingQiCandidate>{
    for (final candidate in yingQiCandidates) candidate.candidateId: candidate,
  };
  final traceById = <String, QimenTraceStep>{
    for (final step in trace) step.stepId: step,
  };
  final referencedSourceIds = <String>{};

  void referenceSources(Iterable<String> sourceIds, String owner) {
    knownSources(sourceIds, owner);
    referencedSourceIds.addAll(sourceIds);
  }

  for (final focus in focuses) {
    knownRule(focus.ruleId, 'focus ${focus.roleId}');
    referenceSources(focus.sourceIds, 'focus ${focus.roleId}');
    if (focus.palaceNumber < 1 ||
        focus.palaceNumber > 9 ||
        focus.originPalaceNumber < 1 ||
        focus.originPalaceNumber > 9 ||
        (focus.isHosted
            ? focus.originPalaceNumber != 5 || focus.palaceNumber == 5
            : focus.originPalaceNumber != focus.palaceNumber)) {
      throw FormatException(
        'Focus ${focus.roleId} has invalid hosted/origin provenance',
      );
    }
  }
  for (final fact in facts) {
    knownRule(fact.ruleId, 'fact ${fact.occurrenceId}');
    referenceSources(fact.sourceIds, 'fact ${fact.occurrenceId}');
    if (fact.ruleSetVersion != ruleSetVersion) {
      throw FormatException(
        'Fact ${fact.occurrenceId} uses rule-set ${fact.ruleSetVersion}',
      );
    }
    final producingStep = traceById[fact.traceStepId];
    if (producingStep == null ||
        producingStep.stage != QimenTraceStage.fact ||
        producingStep.ruleId != fact.ruleId ||
        !producingStep.outputOccurrenceIds.contains(fact.occurrenceId)) {
      throw FormatException(
        'Fact ${fact.occurrenceId} has an invalid producing trace step',
      );
    }
  }
  for (final conflict in conflicts) {
    knownRule(conflict.policyId, 'conflict ${conflict.resolutionId}');
    referenceSources(
      QimenRuleCatalog.rule(conflict.policyId).sourceIds,
      'conflict ${conflict.resolutionId}',
    );
    _requireUnique(
      conflict.contenderOccurrenceIds,
      'conflict ${conflict.resolutionId} contender ID',
    );
    _requireUnique(
      conflict.suppressedOccurrenceIds,
      'conflict ${conflict.resolutionId} suppressed ID',
    );
    if (conflict.contenderOccurrenceIds.length < 2 ||
        conflict.contenderOccurrenceIds.any(
          (factId) => !factsById.containsKey(factId),
        )) {
      throw FormatException(
        'Conflict ${conflict.resolutionId} has dangling contenders',
      );
    }
    final winnerId = conflict.winnerOccurrenceId;
    if (winnerId == null) {
      if (conflict.suppressedOccurrenceIds.isNotEmpty) {
        throw FormatException(
          'Unresolved conflict ${conflict.resolutionId} suppresses facts',
        );
      }
    } else if (!conflict.contenderOccurrenceIds.contains(winnerId) ||
        conflict.suppressedOccurrenceIds.contains(winnerId) ||
        conflict.suppressedOccurrenceIds.isEmpty) {
      throw FormatException(
        'Conflict ${conflict.resolutionId} has an invalid winner',
      );
    }
    if (conflict.suppressedOccurrenceIds.any(
      (factId) => !conflict.contenderOccurrenceIds.contains(factId),
    )) {
      throw FormatException(
        'Conflict ${conflict.resolutionId} suppresses a non-contender',
      );
    }
  }

  knownRule(verdict.matchedDecisionRowId, 'verdict');
  referenceSources(verdict.sourceIds, 'verdict');
  _requireUnique(verdict.participatingFactIds, 'verdict fact ID');
  _requireUnique(verdict.conflictResolutionIds, 'verdict conflict ID');
  if (verdict.participatingFactIds.any(
        (factId) => !factsById.containsKey(factId),
      ) ||
      verdict.conflictResolutionIds.any(
        (conflictId) => !conflictsById.containsKey(conflictId),
      )) {
    throw const FormatException('Qimen verdict has dangling graph references');
  }
  for (final condition in verdict.conditionLinks) {
    knownRule(condition.ruleId, 'condition ${condition.conditionId}');
    referenceSources(condition.sourceIds, 'condition ${condition.conditionId}');
    final sourceFact = factsById[condition.sourceFactId];
    if (sourceFact == null || sourceFact.ruleId != condition.ruleId) {
      throw FormatException(
        'Condition ${condition.conditionId} has a dangling source fact',
      );
    }
  }

  final judgmentConditions = verdict.judgment.conditions
      .map(qimenConditionToJson)
      .toList(growable: false);
  final linkedConditions = verdict.conditionLinks
      .map((condition) => qimenConditionToJson(condition.condition))
      .toList(growable: false);
  if (jsonEncode(judgmentConditions) != jsonEncode(linkedConditions)) {
    throw const FormatException(
      'Qimen verdict judgment conditions differ from condition links',
    );
  }
  for (final factor in verdict.judgment.factors) {
    final expectedSources = <String>{};
    final rule = factor.rule;
    if (rule.startsWith('焦点·')) {
      final roleId = rule.substring('焦点·'.length);
      final focus = focusesById[roleId];
      if (focus == null || focus.priority != QimenFocusPriority.primary) {
        throw FormatException('Unknown Qimen verdict factor rule: $rule');
      }
      expectedSources.addAll(focus.sourceIds);
    } else if (conditionsById.containsKey(rule)) {
      expectedSources.addAll(conditionsById[rule]!.sourceIds);
    } else if (rule == verdict.matchedDecisionRowId) {
      expectedSources.addAll(QimenRuleCatalog.rule(rule).sourceIds);
    } else {
      for (final factId in verdict.participatingFactIds) {
        final fact = factsById[factId]!;
        if (fact.ruleId == rule) expectedSources.addAll(fact.sourceIds);
      }
      for (final conflictId in verdict.conflictResolutionIds) {
        final conflict = conflictsById[conflictId]!;
        if (conflict.policyId == rule) {
          expectedSources.addAll(QimenRuleCatalog.rule(rule).sourceIds);
        }
      }
      if (expectedSources.isEmpty) {
        throw FormatException('Unknown Qimen verdict factor rule: $rule');
      }
    }
    final factorSources = factor.source
        .split(',')
        .map((sourceId) => sourceId.trim())
        .where((sourceId) => sourceId.isNotEmpty)
        .toList(growable: false);
    _requireUnique(factorSources, 'verdict factor source ID');
    if (factorSources.toSet().length != expectedSources.length ||
        !factorSources.toSet().containsAll(expectedSources)) {
      throw FormatException(
        'Qimen verdict factor $rule has inconsistent sources',
      );
    }
    referenceSources(factorSources, 'verdict factor $rule');
  }

  for (final candidate in yingQiCandidates) {
    knownRule(candidate.ruleId, 'YingQi ${candidate.candidateId}');
    referenceSources(candidate.sourceIds, 'YingQi ${candidate.candidateId}');
    _requireUnique(
      candidate.relatedFactIds,
      'YingQi ${candidate.candidateId} fact ID',
    );
    _requireUnique(
      candidate.relatedConditionIds,
      'YingQi ${candidate.candidateId} condition ID',
    );
    if ((candidate.relatedFactIds.isEmpty &&
            candidate.relatedConditionIds.isEmpty) ||
        candidate.relatedFactIds.any(
          (factId) => !factsById.containsKey(factId),
        ) ||
        candidate.relatedConditionIds.any(
          (conditionId) => !conditionsById.containsKey(conditionId),
        ) ||
        (candidate.targetFocusRoleId != null &&
            !focusesById.containsKey(candidate.targetFocusRoleId))) {
      throw FormatException(
        'YingQi ${candidate.candidateId} has dangling graph references',
      );
    }
  }

  for (final step in trace) {
    knownRule(step.ruleId, 'trace ${step.stepId}');
    referenceSources(step.sourceIds, 'trace ${step.stepId}');
    final validOutput = switch (step.stage) {
      QimenTraceStage.input => step.outputOccurrenceIds.isEmpty,
      QimenTraceStage.focus => step.outputOccurrenceIds.every(
          focusesById.containsKey,
        ),
      QimenTraceStage.fact ||
      QimenTraceStage.conflict =>
        step.outputOccurrenceIds.every(factsById.containsKey),
      QimenTraceStage.verdict => step.outputOccurrenceIds.every(
          releasedRuleIds.contains,
        ),
      QimenTraceStage.yingQi => step.outputOccurrenceIds.every(
          candidatesById.containsKey,
        ),
    };
    if (!validOutput) {
      throw FormatException('Trace ${step.stepId} has dangling outputs');
    }
  }

  final suppliedSourceIds = sourcesById.keys.toSet();
  if (suppliedSourceIds.length != referencedSourceIds.length ||
      !suppliedSourceIds.containsAll(referencedSourceIds)) {
    throw const FormatException(
      'Qimen report sources do not exactly cover graph references',
    );
  }

  if (panFieldReferences != null) {
    final expected = canonicalQimenPanFieldReferences(
      facts: facts,
      trace: trace,
    );
    if (panFieldReferences.length != expected.length ||
        !List<bool>.generate(
          expected.length,
          (index) =>
              panFieldReferences[index].path == expected[index].path &&
              panFieldReferences[index].value == expected[index].value,
        ).every((matches) => matches)) {
      throw const FormatException(
        'Qimen projection panFieldReferences do not match report evidence',
      );
    }
  }
}

List<QimenInputRef> canonicalQimenPanFieldReferences({
  required List<QimenFact> facts,
  required List<QimenTraceStep> trace,
}) {
  final references = <String, QimenInputRef>{};
  for (final ref in <QimenInputRef>[
    ...facts.expand((fact) => fact.inputRefs),
    ...trace.expand((step) => step.inputRefs),
  ]) {
    references['${ref.path}\u0000${ref.value}'] = ref;
  }
  final ordered = references.values.toList(growable: false)
    ..sort((left, right) {
      final pathComparison = left.path.compareTo(right.path);
      return pathComparison != 0
          ? pathComparison
          : left.value.compareTo(right.value);
    });
  return List<QimenInputRef>.unmodifiable(ordered);
}

void _requireUnique<T>(Iterable<T> values, String label) {
  final list = values.toList(growable: false);
  if (list.toSet().length != list.length) {
    throw FormatException('Duplicate Qimen $label');
  }
}

bool _sameValues<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

List<T> _decodeList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) =>
    (json[key] as List)
        .map((value) => decode(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);

String qimenPolarityId(Polarity value) => switch (value) {
      Polarity.ji => 'ji',
      Polarity.xiong => 'xiong',
      Polarity.neutral => 'neutral',
    };

Polarity qimenPolarityFromId(String id) => switch (id) {
      'ji' => Polarity.ji,
      'xiong' => Polarity.xiong,
      'neutral' => Polarity.neutral,
      _ => throw FormatException('Unknown polarity: $id'),
    };

String qimenVerdictTrendId(VerdictTrend value) => switch (value) {
      VerdictTrend.keCheng => 'keCheng',
      VerdictTrend.nanCheng => 'nanCheng',
      VerdictTrend.daiTiaoJian => 'daiTiaoJian',
      VerdictTrend.buMing => 'buMing',
    };

VerdictTrend qimenVerdictTrendFromId(String id) => switch (id) {
      'keCheng' => VerdictTrend.keCheng,
      'nanCheng' => VerdictTrend.nanCheng,
      'daiTiaoJian' => VerdictTrend.daiTiaoJian,
      'buMing' => VerdictTrend.buMing,
      _ => throw FormatException('Unknown verdict trend: $id'),
    };

String qimenVerdictEffectId(VerdictEffect value) => switch (value) {
      VerdictEffect.fu => 'fu',
      VerdictEffect.yi => 'yi',
      VerdictEffect.suspend => 'suspend',
      VerdictEffect.neutral => 'neutral',
    };

VerdictEffect qimenVerdictEffectFromId(String id) => switch (id) {
      'fu' => VerdictEffect.fu,
      'yi' => VerdictEffect.yi,
      'suspend' => VerdictEffect.suspend,
      'neutral' => VerdictEffect.neutral,
      _ => throw FormatException('Unknown verdict effect: $id'),
    };

Map<String, dynamic> qimenConditionToJson(VerdictCondition value) =>
    <String, dynamic>{
      'label': value.label,
      'branch': value.branch,
      'reason': value.reason,
      'hasRescue': value.hasRescue,
    };

VerdictCondition qimenConditionFromJson(Map<String, dynamic> json) =>
    VerdictCondition(
      label: json['label'] as String,
      branch: json['branch'] as String?,
      reason: json['reason'] as String,
      hasRescue: json['hasRescue'] as bool,
    );

Map<String, dynamic> qimenJudgmentToJson(VerdictJudgment value) =>
    <String, dynamic>{
      'trend': qimenVerdictTrendId(value.trend),
      'nuance': value.nuance,
      'conditions': value.conditions.map(qimenConditionToJson).toList(),
      'factors': value.factors
          .map((factor) => <String, dynamic>{
                'rule': factor.rule,
                'effect': qimenVerdictEffectId(factor.effect),
                'reason': factor.reason,
                'source': factor.source,
              })
          .toList(),
      'summary': value.summary,
    };

VerdictJudgment qimenJudgmentFromJson(Map<String, dynamic> json) =>
    VerdictJudgment(
      trend: qimenVerdictTrendFromId(json['trend'] as String),
      nuance: json['nuance'] as String?,
      conditions: (json['conditions'] as List)
          .map((value) => qimenConditionFromJson(
                Map<String, dynamic>.from(value as Map),
              ))
          .toList(growable: false),
      factors: (json['factors'] as List).map((value) {
        final map = Map<String, dynamic>.from(value as Map);
        return VerdictFactor(
          rule: map['rule'] as String,
          effect: qimenVerdictEffectFromId(map['effect'] as String),
          reason: map['reason'] as String,
          source: map['source'] as String,
        );
      }).toList(growable: false),
      summary: json['summary'] as String,
    );
