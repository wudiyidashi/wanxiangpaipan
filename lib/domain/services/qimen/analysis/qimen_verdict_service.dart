import '../../shared/analysis/models/verdict_models.dart';
import 'facts/qimen_constraint_fact_service.dart';
import 'models/qimen_analysis_models.dart';
import 'models/qimen_rule_models.dart';
import 'rules/qimen_rule_catalog.dart';
import 'rules/qimen_source_catalog.dart';
import 'rules/qimen_verdict_table.dart';

class QimenVerdictEvaluation {
  const QimenVerdictEvaluation({required this.result, required this.trace});

  final QimenVerdictResult result;
  final List<QimenTraceStep> trace;
}

class QimenVerdictService {
  QimenVerdictService._();

  static const Map<String, String> _punishmentReleaseBranches =
      <String, String>{
    '戊': '酉',
    '己': '丑',
    '庚': '申',
    '辛': '子',
    '壬': '戌',
    '癸': '亥',
  };

  static QimenVerdictEvaluation judge({
    required QimenAnalysisStatus status,
    required List<QimenAnalysisDiagnostic> diagnostics,
    required List<QimenFocus> focuses,
    required bool hasUniquePrimaryFocus,
    required List<QimenFact> activeFacts,
    required List<QimenConflictResolution> conflicts,
  }) {
    final conditions = _buildConditions(activeFacts);
    final adverse = activeFacts
        .where((fact) => fact.ruleId == QimenRuleCatalog.adverseConvergence)
        .toList(growable: false);
    final favorable = activeFacts
        .where((fact) => fact.ruleId == QimenRuleCatalog.favorableConvergence)
        .toList(growable: false);
    final unresolvedHigh = conflicts.where((resolution) {
      if (!resolution.isUnresolved) return false;
      final contenders = activeFacts.where(
        (fact) => resolution.contenderOccurrenceIds.contains(
          fact.occurrenceId,
        ),
      );
      return contenders.any((fact) =>
          fact.conflictTier == QimenConflictTier.decisive ||
          fact.conflictTier == QimenConflictTier.conditional);
    }).toList(growable: false);
    final unresolvedFactIds = unresolvedHigh
        .expand((resolution) => resolution.contenderOccurrenceIds)
        .toSet();
    final decisiveBlockers = activeFacts
        .where((fact) =>
            fact.affectsPrimaryFocus &&
            fact.role == QimenFactRole.inhibit &&
            fact.conflictTier == QimenConflictTier.decisive &&
            fact.ruleId != QimenRuleCatalog.adverseConvergence &&
            !unresolvedFactIds.contains(fact.occurrenceId))
        .toList(growable: false);

    bool matches(QimenVerdictPredicate predicate) => switch (predicate) {
          QimenVerdictPredicate.invalidInputOrFocus =>
            status != QimenAnalysisStatus.complete || !hasUniquePrimaryFocus,
          QimenVerdictPredicate.decisiveBlocker => decisiveBlockers.isNotEmpty,
          QimenVerdictPredicate.releasableCondition => conditions.isNotEmpty,
          QimenVerdictPredicate.adverseConvergence =>
            adverse.isNotEmpty && unresolvedHigh.isEmpty,
          QimenVerdictPredicate.favorableConvergence =>
            favorable.isNotEmpty && unresolvedHigh.isEmpty,
          QimenVerdictPredicate.unresolvedDecisiveConflict =>
            unresolvedHigh.isNotEmpty,
          QimenVerdictPredicate.conservativeFallback => true,
        };

    QimenVerdictRow? matchedRow;
    final trace = <QimenTraceStep>[];
    for (final row in QimenVerdictTable.rows) {
      final rowMatches = matchedRow == null && matches(row.predicate);
      if (rowMatches) matchedRow = row;
      trace.add(QimenTraceStep(
        stepId: 'verdict:${row.rowId}',
        sequence: -1,
        stage: QimenTraceStage.verdict,
        ruleId: row.rowId,
        status: rowMatches
            ? QimenEvaluationStatus.matched
            : matchedRow == null
                ? QimenEvaluationStatus.notMatched
                : QimenEvaluationStatus.notApplicable,
        inputRefs: const <QimenInputRef>[],
        outputOccurrenceIds:
            rowMatches ? <String>[row.rowId] : const <String>[],
        sourceIds: QimenRuleCatalog.rule(row.rowId).sourceIds,
        explanation: rowMatches
            ? '决策表首行命中${row.rowId}：${row.summary}'
            : matchedRow == null
                ? '${row.rowId}谓词未命中。'
                : '已有更早决策行${matchedRow.rowId}命中，本行不再参与。',
      ));
    }
    final row = matchedRow!;

    final participatingFacts = switch (row.predicate) {
      QimenVerdictPredicate.decisiveBlocker => decisiveBlockers,
      QimenVerdictPredicate.releasableCondition => activeFacts
          .where((fact) => conditions
              .any((condition) => condition.sourceFactId == fact.occurrenceId))
          .toList(growable: false),
      QimenVerdictPredicate.adverseConvergence => adverse,
      QimenVerdictPredicate.favorableConvergence => favorable,
      QimenVerdictPredicate.unresolvedDecisiveConflict => activeFacts
          .where((fact) => unresolvedHigh.any((resolution) =>
              resolution.contenderOccurrenceIds.contains(fact.occurrenceId)))
          .toList(growable: false),
      _ => const <QimenFact>[],
    };
    final participatingConflictIds = conflicts
        .where((resolution) => participatingFacts.any((fact) =>
            resolution.contenderOccurrenceIds.contains(fact.occurrenceId)))
        .map((resolution) => resolution.resolutionId)
        .toSet()
        .toList(growable: false)
      ..sort();
    final sourceIds = <String>{
      ...QimenRuleCatalog.rule(row.rowId).sourceIds,
      ...participatingFacts.expand((fact) => fact.sourceIds),
      ...conditions.expand((condition) => condition.sourceIds),
    }.toList(growable: false)
      ..sort();
    final factors = <VerdictFactor>[
      for (final focus in focuses.where(
        (focus) => focus.roleId == 'self' || focus.roleId == 'matter',
      ))
        VerdictFactor(
          rule: '焦点·${focus.roleId}',
          effect: VerdictEffect.neutral,
          reason: focus.reason,
          source: focus.sourceIds.join(','),
        ),
      for (final fact in participatingFacts)
        VerdictFactor(
          rule: fact.ruleId,
          effect: _effect(fact.role),
          reason: fact.reason,
          source: fact.sourceIds.join(','),
        ),
      for (final conflict in conflicts.where(
        (resolution) => participatingConflictIds.contains(
          resolution.resolutionId,
        ),
      ))
        VerdictFactor(
          rule: conflict.policyId,
          effect: VerdictEffect.neutral,
          reason: conflict.reason,
          source: QimenRuleCatalog.rule(conflict.policyId).sourceIds.join(','),
        ),
      for (final condition in conditions)
        VerdictFactor(
          rule: condition.conditionId,
          effect: VerdictEffect.suspend,
          reason: condition.condition.reason,
          source: condition.sourceIds.join(','),
        ),
      VerdictFactor(
        rule: row.rowId,
        effect: VerdictEffect.neutral,
        reason: '固定顺序决策表首行命中：${row.summary}',
        source: QimenRuleCatalog.rule(row.rowId).sourceIds.join(','),
      ),
    ];
    final diagnosticText = diagnostics.isEmpty
        ? ''
        : ' 诊断：${diagnostics.map((value) => value.code).join('、')}。';
    final conditionText = conditions.isEmpty
        ? ''
        : ' 未决条件：${conditions.map((value) => value.condition.label).join('、')}。';
    final judgment = VerdictJudgment(
      trend: row.trend,
      conditions:
          conditions.map((value) => value.condition).toList(growable: false),
      factors: factors,
      summary:
          '${_trendLabel(row.trend)}：${row.summary}$conditionText$diagnosticText',
    );
    return QimenVerdictEvaluation(
      result: QimenVerdictResult(
        judgment: judgment,
        matchedDecisionRowId: row.rowId,
        participatingFactIds: participatingFacts
            .map((fact) => fact.occurrenceId)
            .toSet()
            .toList(growable: false)
          ..sort(),
        conflictResolutionIds: participatingConflictIds,
        sourceIds: sourceIds,
        conditionLinks: conditions,
      ),
      trace: List<QimenTraceStep>.unmodifiable(trace),
    );
  }

  static List<QimenVerdictCondition> _buildConditions(
    List<QimenFact> activeFacts,
  ) {
    final result = <QimenVerdictCondition>[];
    final eligible = activeFacts
        .where((fact) =>
            fact.role == QimenFactRole.suspend && fact.affectsPrimaryFocus)
        .toList(growable: false)
      ..sort((left, right) => left.occurrenceId.compareTo(right.occurrenceId));
    for (final fact in eligible) {
      final QimenVerdictCondition? condition;
      switch (fact.ruleId) {
        case QimenRuleCatalog.voidState:
          final branches = _refValue(fact, 'voidBranches')
              ?.split(',')
              .where((value) => value.isNotEmpty)
              .toList(growable: false);
          final branch = branches == null || branches.isEmpty
              ? null
              : (branches..sort()).first;
          condition = branch == null
              ? null
              : _condition(
                  fact: fact,
                  label: '待$branch填实空亡',
                  branch: branch,
                  reason: '${fact.reason} 观察$branch到临填实，但不保证事情发生。',
                  triggerKind: 'branch',
                  triggerValue: branch,
                  releaseScale: YingQiScale.ri,
                );
        case QimenRuleCatalog.qiYiTomb:
          final palace = fact.relatedPalaceNumbers.firstOrNull;
          final tombBranch = palace == null
              ? null
              : QimenConstraintFactService.tombBranches[palace];
          final release = QimenConstraintFactService.clashBranches[tombBranch];
          condition = release == null
              ? null
              : _condition(
                  fact: fact,
                  label: '待$release冲开$tombBranch墓',
                  branch: release,
                  reason: '${fact.reason} 观察$release冲墓窗口，但不据此改判成败。',
                  triggerKind: 'branch',
                  triggerValue: release,
                  releaseScale: YingQiScale.ri,
                );
        case QimenRuleCatalog.instrumentPunishment:
          final stem =
              fact.inputRefs.isEmpty ? null : fact.inputRefs.first.value;
          final release = _punishmentReleaseBranches[stem];
          condition = release == null
              ? null
              : _condition(
                  fact: fact,
                  label: '待$release冲刑缓解',
                  branch: release,
                  reason: '${fact.reason} 观察$release冲动刑位的窗口。',
                  triggerKind: 'branch',
                  triggerValue: release,
                  releaseScale: YingQiScale.ri,
                );
        case QimenRuleCatalog.doorPressure:
          final palace = fact.relatedPalaceNumbers.firstOrNull;
          condition = palace == null
              ? null
              : _condition(
                  fact: fact,
                  label: '待$palace宫门迫缓解',
                  reason: '${fact.reason} 只在门迫状态解除后复核。',
                  triggerKind: 'conditionRelease',
                  triggerValue: 'doorPressure:p$palace',
                  releaseScale: YingQiScale.ri,
                );
        default:
          condition = null;
      }
      if (condition != null) result.add(condition);
    }
    return List<QimenVerdictCondition>.unmodifiable(result);
  }

  static QimenVerdictCondition _condition({
    required QimenFact fact,
    required String label,
    required String reason,
    required String triggerKind,
    required String triggerValue,
    required YingQiScale releaseScale,
    String? branch,
  }) {
    final sources = <String>{
      ...fact.sourceIds,
      QimenSourceCatalog.projectV1,
    }.toList(growable: false)
      ..sort();
    return QimenVerdictCondition(
      conditionId: 'QMV1-COND@${fact.occurrenceId}',
      sourceFactId: fact.occurrenceId,
      ruleId: fact.ruleId,
      condition: VerdictCondition(
        label: label,
        branch: branch,
        reason: reason,
      ),
      releaseTriggerKind: triggerKind,
      releaseTriggerValue: triggerValue,
      releaseScale: releaseScale,
      sourceIds: sources,
    );
  }

  static String? _refValue(QimenFact fact, String suffix) {
    for (final ref in fact.inputRefs) {
      if (ref.path == suffix || ref.path.endsWith(suffix)) return ref.value;
    }
    return null;
  }

  static VerdictEffect _effect(QimenFactRole role) => switch (role) {
        QimenFactRole.support => VerdictEffect.fu,
        QimenFactRole.inhibit => VerdictEffect.yi,
        QimenFactRole.suspend => VerdictEffect.suspend,
        QimenFactRole.neutral => VerdictEffect.neutral,
      };

  static String _trendLabel(VerdictTrend trend) => switch (trend) {
        VerdictTrend.keCheng => '可成',
        VerdictTrend.nanCheng => '难成',
        VerdictTrend.daiTiaoJian => '待条件',
        VerdictTrend.buMing => '趋势不明',
      };
}
