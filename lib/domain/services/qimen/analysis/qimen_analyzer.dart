import '../../../../divination_systems/qimen/models/qimen_result.dart';
import 'facts/qimen_constraint_fact_service.dart';
import 'facts/qimen_fact_support.dart';
import 'facts/qimen_formation_service.dart';
import 'facts/qimen_relation_fact_service.dart';
import 'facts/qimen_star_door_state_service.dart';
import 'facts/qimen_stem_response_service.dart';
import 'facts/qimen_structure_fact_service.dart';
import 'models/qimen_analysis_models.dart';
import 'models/qimen_rule_models.dart';
import 'qimen_analysis_input_guard.dart';
import 'qimen_conflict_resolver.dart';
import 'qimen_focus_resolver.dart';
import 'qimen_verdict_service.dart';
import 'qimen_ying_qi_service.dart';
import 'rules/qimen_rule_catalog.dart';
import 'rules/qimen_source_catalog.dart';

class QimenAnalyzer {
  QimenAnalyzer._();

  static QimenAnalysisReport analyze(
    QimenResult result, {
    String ruleSetVersion = 'current',
  }) {
    final ruleSet = QimenRuleCatalog.resolve(ruleSetVersion);
    QimenRuleCatalog.validate();
    final guard = QimenAnalysisInputGuard.validate(result);
    if (!guard.isValid) {
      return _diagnosticReport(
        ruleSetVersion: ruleSet.version,
        inputPanSchemaVersion: QimenResult.currentSchemaVersion,
        inputResultId: result.id,
        guard: guard,
      );
    }

    final focus = QimenFocusResolver.resolve(result);
    final batches = <QimenFactBatch>[
      QimenStarDoorStateService.evaluate(
        result,
        focus.focuses,
        ruleSetVersion: ruleSet.version,
      ),
      QimenConstraintFactService.evaluate(
        result,
        focus.focuses,
        ruleSetVersion: ruleSet.version,
      ),
      QimenStructureFactService.evaluate(
        result,
        focus.focuses,
        ruleSetVersion: ruleSet.version,
      ),
      QimenStemResponseService.evaluate(
        result,
        focus.focuses,
        ruleSetVersion: ruleSet.version,
      ),
      QimenFormationService.evaluate(
        result,
        focus.focuses,
        ruleSetVersion: ruleSet.version,
      ),
      QimenRelationFactService.evaluate(
        result,
        focus.focuses,
        ruleSetVersion: ruleSet.version,
      ),
    ];
    final facts = batches.expand((batch) => batch.facts).toList(growable: false)
      ..sort(_compareFacts);
    final conflicts = QimenConflictResolver.resolve(facts);
    final diagnostics = <QimenAnalysisDiagnostic>[
      ...guard.diagnostics,
      ...focus.diagnostics,
    ];
    final verdict = QimenVerdictService.judge(
      status: guard.status,
      diagnostics: diagnostics,
      focuses: focus.focuses,
      hasUniquePrimaryFocus: focus.hasUniquePrimaryFocus,
      activeFacts: conflicts.activeFacts,
      conflicts: conflicts.resolutions,
    );
    final yingQi = QimenYingQiService.calculate(
      activeFacts: conflicts.activeFacts,
      verdict: verdict.result,
    );
    final trace = _renumber(<QimenTraceStep>[
      _inputTrace(
        resultId: result.id,
        status: QimenEvaluationStatus.matched,
        explanation: '排盘 schema 1 与九宫完整性门禁通过；分析只读消费冻结结果。',
      ),
      ...focus.trace,
      ...batches.expand((batch) => batch.trace),
      ...conflicts.trace,
      ...verdict.trace,
      ...yingQi.trace,
    ]);
    final sources = _referencedSources(
      focuses: focus.focuses,
      facts: facts,
      conflicts: conflicts.resolutions,
      verdict: verdict.result,
      trace: trace,
    );
    return QimenAnalysisReport(
      analysisSchemaVersion: QimenAnalysisReport.currentSchemaVersion,
      ruleSetId: ruleSet.ruleSetId,
      ruleSetVersion: ruleSet.version,
      inputPanSchemaVersion: QimenResult.currentSchemaVersion,
      inputResultId: result.id,
      status: guard.status,
      diagnostics: List<QimenAnalysisDiagnostic>.unmodifiable(diagnostics),
      sources: sources,
      focuses: focus.focuses,
      facts: List<QimenFact>.unmodifiable(facts),
      conflicts: conflicts.resolutions,
      verdict: verdict.result,
      yingQiCandidates: yingQi.candidates,
      trace: trace,
    );
  }

  static QimenAnalysisReport analyzePersisted(
    Map<String, dynamic> persistedPan, {
    String ruleSetVersion = 'current',
  }) {
    final ruleSet = QimenRuleCatalog.resolve(ruleSetVersion);
    final schema = persistedPan['schemaVersion'];
    if (schema != QimenResult.currentSchemaVersion) {
      return _diagnosticReport(
        ruleSetVersion: ruleSet.version,
        inputPanSchemaVersion: schema is int ? schema : -1,
        inputResultId:
            persistedPan['id'] is String ? persistedPan['id'] as String : '',
        hasInputResultId: persistedPan['id'] is String,
        guard: QimenAnalysisInputGuard.unsupportedSchema(
          schemaVersion: schema,
        ),
      );
    }
    late final QimenResult result;
    try {
      result = QimenResult.fromJson(persistedPan);
    } catch (error) {
      return _diagnosticReport(
        ruleSetVersion: ruleSet.version,
        inputPanSchemaVersion: schema as int,
        inputResultId:
            persistedPan['id'] is String ? persistedPan['id'] as String : '',
        hasInputResultId: persistedPan['id'] is String,
        guard: QimenInputGuardResult(
          status: QimenAnalysisStatus.invalidPanFacts,
          diagnostics: <QimenAnalysisDiagnostic>[
            _deserializationDiagnostic(persistedPan, error),
          ],
        ),
      );
    }
    return analyze(result, ruleSetVersion: ruleSet.version);
  }

  static QimenAnalysisReport _diagnosticReport({
    required String ruleSetVersion,
    required int inputPanSchemaVersion,
    required String inputResultId,
    required QimenInputGuardResult guard,
    bool hasInputResultId = true,
  }) {
    final verdict = QimenVerdictService.judge(
      status: guard.status,
      diagnostics: guard.diagnostics,
      focuses: const <QimenFocus>[],
      hasUniquePrimaryFocus: false,
      activeFacts: const <QimenFact>[],
      conflicts: const <QimenConflictResolution>[],
    );
    final trace = _renumber(<QimenTraceStep>[
      _inputTrace(
        resultId: inputResultId,
        includeResultIdRef: hasInputResultId,
        status: QimenEvaluationStatus.notApplicable,
        explanation: guard.diagnostics.map((value) => value.message).join('; '),
      ),
      ...verdict.trace,
    ]);
    return QimenAnalysisReport(
      analysisSchemaVersion: QimenAnalysisReport.currentSchemaVersion,
      ruleSetId: QimenRuleCatalog.ruleSetId,
      ruleSetVersion: ruleSetVersion,
      inputPanSchemaVersion: inputPanSchemaVersion,
      inputResultId: inputResultId,
      status: guard.status,
      diagnostics: guard.diagnostics,
      sources: _referencedSources(
        focuses: const <QimenFocus>[],
        facts: const <QimenFact>[],
        conflicts: const <QimenConflictResolution>[],
        verdict: verdict.result,
        trace: trace,
      ),
      focuses: const <QimenFocus>[],
      facts: const <QimenFact>[],
      conflicts: const <QimenConflictResolution>[],
      verdict: verdict.result,
      yingQiCandidates: const [],
      trace: trace,
    );
  }

  static QimenTraceStep _inputTrace({
    required String resultId,
    required QimenEvaluationStatus status,
    required String explanation,
    bool includeResultIdRef = true,
  }) =>
      QimenTraceStep(
        stepId: 'input:${QimenRuleCatalog.inputIntegrity}',
        sequence: -1,
        stage: QimenTraceStage.input,
        ruleId: QimenRuleCatalog.inputIntegrity,
        status: status,
        inputRefs: includeResultIdRef
            ? <QimenInputRef>[
                QimenInputRef(path: r'$.id', value: resultId),
              ]
            : const <QimenInputRef>[],
        outputOccurrenceIds: const <String>[],
        sourceIds:
            QimenRuleCatalog.rule(QimenRuleCatalog.inputIntegrity).sourceIds,
        explanation: explanation,
      );

  static QimenAnalysisDiagnostic _deserializationDiagnostic(
    Map<String, dynamic> persistedPan,
    Object error,
  ) {
    const requiredFields = <String>[
      'systemType',
      'id',
      'castTime',
      'castMethod',
      'lunarInfo',
      'panParams',
      'temporalContext',
      'juInfo',
      'palaces',
      'xunShou',
      'xunHiddenStem',
      'zhiFuStar',
      'zhiFuPalace',
      'zhiShiDoor',
      'zhiShiPalace',
      'kongWangBranches',
      'horseBranch',
      'horsePalace',
      'derivationSteps',
    ];
    var path = r'$';
    for (final field in requiredFields) {
      if (!persistedPan.containsKey(field)) {
        path = '\$.$field';
        break;
      }
    }
    final message = error.toString();
    if (path == r'$') {
      if (message.contains('systemType')) {
        path = r'$.systemType';
      } else if (message.contains('castMethod')) {
        path = r'$.castMethod';
      } else if (message.contains('九宫') || persistedPan['palaces'] is! List) {
        path = r'$.palaces';
      } else if (message.contains('局数')) {
        path = r'$.juInfo.juNumber';
      }
    }
    return QimenAnalysisDiagnostic(
      code: 'QMV1-E-PAN-DESERIALIZATION',
      path: path,
      message: 'schema-v1 pan could not be deserialized at $path: $message',
    );
  }

  static List<QimenTraceStep> _renumber(List<QimenTraceStep> trace) =>
      List<QimenTraceStep>.unmodifiable(<QimenTraceStep>[
        for (var index = 0; index < trace.length; index++)
          trace[index].copyWith(sequence: index + 1),
      ]);

  static int _compareFacts(QimenFact left, QimenFact right) {
    var comparison =
        left.conflictTier.order.compareTo(right.conflictTier.order);
    if (comparison != 0) return comparison;
    comparison = left.category.id.compareTo(right.category.id);
    if (comparison != 0) return comparison;
    comparison = left.ruleId.compareTo(right.ruleId);
    if (comparison != 0) return comparison;
    return left.occurrenceId.compareTo(right.occurrenceId);
  }

  static List<QimenSourceRef> _referencedSources({
    required List<QimenFocus> focuses,
    required List<QimenFact> facts,
    required List<QimenConflictResolution> conflicts,
    required QimenVerdictResult verdict,
    required List<QimenTraceStep> trace,
  }) {
    final ids = <String>{
      ...focuses.expand((focus) => focus.sourceIds),
      ...facts.expand((fact) => fact.sourceIds),
      ...conflicts.expand(
        (conflict) => QimenRuleCatalog.rule(conflict.policyId).sourceIds,
      ),
      ...verdict.sourceIds,
      ...trace.expand((step) => step.sourceIds),
    }.toList(growable: false)
      ..sort();
    return List<QimenSourceRef>.unmodifiable(
      ids.map((id) => QimenSourceCatalog.byId[id]!).toList(growable: false),
    );
  }
}
