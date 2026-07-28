import 'qimen_analysis_models.dart';
import 'qimen_rule_models.dart';
import 'qimen_ying_qi_models.dart';

class QimenAnalysisProjection {
  QimenAnalysisProjection({
    required this.projectionSchemaVersion,
    required this.ruleSetId,
    required this.ruleSetVersion,
    required this.inputPanSchemaVersion,
    required this.inputResultId,
    required this.status,
    required List<QimenAnalysisDiagnostic> diagnostics,
    required this.calculationOwner,
    required this.mayRecalculatePan,
    required this.mayRecalculateAnalysis,
    required this.mayOverrideVerdict,
    required List<QimenInputRef> panFieldReferences,
    required List<QimenSourceRef> sources,
    required List<QimenFocus> focuses,
    required List<QimenFact> facts,
    required List<QimenConflictResolution> conflicts,
    required this.verdict,
    required List<QimenYingQiCandidate> yingQiCandidates,
    required List<QimenTraceStep> trace,
  })  : diagnostics = List<QimenAnalysisDiagnostic>.unmodifiable(diagnostics),
        panFieldReferences =
            List<QimenInputRef>.unmodifiable(panFieldReferences),
        sources = List<QimenSourceRef>.unmodifiable(sources),
        focuses = List<QimenFocus>.unmodifiable(focuses),
        facts = List<QimenFact>.unmodifiable(facts),
        conflicts = List<QimenConflictResolution>.unmodifiable(conflicts),
        yingQiCandidates =
            List<QimenYingQiCandidate>.unmodifiable(yingQiCandidates),
        trace = List<QimenTraceStep>.unmodifiable(trace);

  static const int currentSchemaVersion = 1;
  static const Set<String> topLevelKeys = <String>{
    'projectionSchemaVersion',
    'ruleSetId',
    'ruleSetVersion',
    'inputPanSchemaVersion',
    'inputResultId',
    'status',
    'diagnostics',
    'policy',
    'panFieldReferences',
    'sources',
    'focuses',
    'facts',
    'conflicts',
    'verdict',
    'yingQiCandidates',
    'trace',
  };
  static const Set<String> policyKeys = <String>{
    'calculationOwner',
    'mayRecalculatePan',
    'mayRecalculateAnalysis',
    'mayOverrideVerdict',
  };

  final int projectionSchemaVersion;
  final String ruleSetId;
  final String ruleSetVersion;
  final int inputPanSchemaVersion;
  final String inputResultId;
  final QimenAnalysisStatus status;
  final List<QimenAnalysisDiagnostic> diagnostics;
  final String calculationOwner;
  final bool mayRecalculatePan;
  final bool mayRecalculateAnalysis;
  final bool mayOverrideVerdict;
  final List<QimenInputRef> panFieldReferences;
  final List<QimenSourceRef> sources;
  final List<QimenFocus> focuses;
  final List<QimenFact> facts;
  final List<QimenConflictResolution> conflicts;
  final QimenVerdictResult verdict;
  final List<QimenYingQiCandidate> yingQiCandidates;
  final List<QimenTraceStep> trace;

  factory QimenAnalysisProjection.fromReport(QimenAnalysisReport report) {
    final projection = QimenAnalysisProjection(
      projectionSchemaVersion: currentSchemaVersion,
      ruleSetId: report.ruleSetId,
      ruleSetVersion: report.ruleSetVersion,
      inputPanSchemaVersion: report.inputPanSchemaVersion,
      inputResultId: report.inputResultId,
      status: report.status,
      diagnostics: report.diagnostics,
      calculationOwner: 'program',
      mayRecalculatePan: false,
      mayRecalculateAnalysis: false,
      mayOverrideVerdict: false,
      panFieldReferences: canonicalQimenPanFieldReferences(
        facts: report.facts,
        trace: report.trace,
      ),
      sources: report.sources,
      focuses: report.focuses,
      facts: report.facts,
      conflicts: report.conflicts,
      verdict: report.verdict,
      yingQiCandidates: report.yingQiCandidates,
      trace: report.trace,
    );
    return projection;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'projectionSchemaVersion': projectionSchemaVersion,
        'ruleSetId': ruleSetId,
        'ruleSetVersion': ruleSetVersion,
        'inputPanSchemaVersion': inputPanSchemaVersion,
        'inputResultId': inputResultId,
        'status': status.id,
        'diagnostics': diagnostics.map((value) => value.toJson()).toList(),
        'policy': <String, dynamic>{
          'calculationOwner': calculationOwner,
          'mayRecalculatePan': mayRecalculatePan,
          'mayRecalculateAnalysis': mayRecalculateAnalysis,
          'mayOverrideVerdict': mayOverrideVerdict,
        },
        'panFieldReferences':
            panFieldReferences.map((value) => value.toJson()).toList(),
        'sources': sources.map((value) => value.toJson()).toList(),
        'focuses': focuses.map((value) => value.toJson()).toList(),
        'facts': facts.map((value) => value.toJson()).toList(),
        'conflicts': conflicts.map((value) => value.toJson()).toList(),
        'verdict': verdict.toJson(),
        'yingQiCandidates':
            yingQiCandidates.map((value) => value.toJson()).toList(),
        'trace': trace.map((value) => value.toJson()).toList(),
      };

  factory QimenAnalysisProjection.fromJson(Map<String, dynamic> json) {
    if (json['projectionSchemaVersion'] != currentSchemaVersion) {
      throw const QimenAnalysisCompatibilityException(
        'unsupported Qimen analysis projection schema',
      );
    }
    if (json.keys.toSet().difference(topLevelKeys).isNotEmpty ||
        topLevelKeys.difference(json.keys.toSet()).isNotEmpty) {
      throw const FormatException(
        'Qimen analysis projection fields do not match schema v1',
      );
    }
    final policy = Map<String, dynamic>.from(json['policy'] as Map);
    if (policy.keys.toSet().difference(policyKeys).isNotEmpty ||
        policyKeys.difference(policy.keys.toSet()).isNotEmpty ||
        policy['calculationOwner'] != 'program' ||
        policy['mayRecalculatePan'] != false ||
        policy['mayRecalculateAnalysis'] != false ||
        policy['mayOverrideVerdict'] != false) {
      throw const FormatException(
        'Qimen analysis projection policy is not the immutable v1 policy',
      );
    }
    final projection = QimenAnalysisProjection(
      projectionSchemaVersion: json['projectionSchemaVersion'] as int,
      ruleSetId: json['ruleSetId'] as String,
      ruleSetVersion: json['ruleSetVersion'] as String,
      inputPanSchemaVersion: json['inputPanSchemaVersion'] as int,
      inputResultId: json['inputResultId'] as String,
      status: QimenAnalysisStatus.fromId(json['status'] as String),
      diagnostics: _decodeList(
        json,
        'diagnostics',
        QimenAnalysisDiagnostic.fromJson,
      ),
      calculationOwner: policy['calculationOwner'] as String,
      mayRecalculatePan: policy['mayRecalculatePan'] as bool,
      mayRecalculateAnalysis: policy['mayRecalculateAnalysis'] as bool,
      mayOverrideVerdict: policy['mayOverrideVerdict'] as bool,
      panFieldReferences: _decodeList(
        json,
        'panFieldReferences',
        QimenInputRef.fromJson,
      ),
      sources: _decodeList(json, 'sources', QimenSourceRef.fromJson),
      focuses: _decodeList(json, 'focuses', QimenFocus.fromJson),
      facts: _decodeList(json, 'facts', QimenFact.fromJson),
      conflicts: _decodeList(
        json,
        'conflicts',
        QimenConflictResolution.fromJson,
      ),
      verdict: QimenVerdictResult.fromJson(
        Map<String, dynamic>.from(json['verdict'] as Map),
      ),
      yingQiCandidates: _decodeList(
        json,
        'yingQiCandidates',
        QimenYingQiCandidate.fromJson,
      ),
      trace: _decodeList(json, 'trace', QimenTraceStep.fromJson),
    );
    validateQimenAnalysisGraph(
      ruleSetId: projection.ruleSetId,
      ruleSetVersion: projection.ruleSetVersion,
      sources: projection.sources,
      focuses: projection.focuses,
      facts: projection.facts,
      conflicts: projection.conflicts,
      verdict: projection.verdict,
      yingQiCandidates: projection.yingQiCandidates,
      trace: projection.trace,
      panFieldReferences: projection.panFieldReferences,
    );
    return projection;
  }
}

List<T> _decodeList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) =>
    (json[key] as List)
        .map((value) => decode(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
