import '../../../domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import '../../../domain/services/qimen/analysis/models/qimen_rule_models.dart';
import '../../../domain/services/qimen/analysis/models/qimen_ying_qi_models.dart';
import '../../../domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import '../../../domain/services/qimen/analysis/rules/qimen_source_catalog.dart';
import '../../../domain/services/shared/analysis/models/polarity.dart';
import '../../../domain/services/shared/analysis/models/verdict_models.dart';

/// Converts stable analysis identifiers into user-facing Chinese labels.
///
/// Stable IDs remain unchanged in reports, projections, and AI payloads. UI
/// code must use this class instead of displaying those IDs directly.
class QimenAnalysisPresentation {
  QimenAnalysisPresentation._();

  static const Map<String, String> _roleLabels = <String, String>{
    'self': '求测者',
    'matter': '所问之事',
    'generalDutyStar': '综合值符星',
    'generalDutyDoor': '综合值使门',
    'careerOpenDoor': '事业开门',
    'careerDutyStar': '事业值符星',
    'wealthLifeDoor': '财运生门',
    'wealthWu': '财运戊仪',
    'relationshipYi': '关系乙奇',
    'relationshipGeng': '关系庚仪',
    'relationshipHarmony': '关系六合',
    'healthDisease': '疾病状态',
    'healthTreatment': '治疗与处置',
    'healthYi': '健康乙奇',
    'studyAssistant': '学业天辅',
    'studySceneryDoor': '学业景门',
    'studyDing': '学业丁奇',
    'travelOpenDoor': '出行开门',
    'travelHorse': '出行驿马',
    'litigationAlarmDoor': '诉讼惊门',
    'litigationGeng': '诉讼庚仪',
    'litigationDutyDoor': '诉讼值使门',
  };

  static String roleLabel(String? roleId) =>
      roleId == null ? '全局' : _roleLabels[roleId] ?? '未识别焦点';

  static String ruleLabel(String ruleId) =>
      QimenRuleCatalog.byId[ruleId]?.displayTerm ?? '未识别规则';

  static String sourceLabel(String sourceId) =>
      QimenSourceCatalog.byId[sourceId]?.title ?? '未识别来源';

  static String sourceLabels(Iterable<String> sourceIds) =>
      sourceIds.map(sourceLabel).toSet().join('、');

  static String occurrenceLabel(
    String? occurrenceId,
    Iterable<QimenFact> facts,
  ) {
    if (occurrenceId == null) return '未决';
    for (final fact in facts) {
      if (fact.occurrenceId == occurrenceId) return ruleLabel(fact.ruleId);
    }
    return '未识别事实';
  }

  static String occurrenceLabels(
    Iterable<String> occurrenceIds,
    Iterable<QimenFact> facts,
  ) {
    if (occurrenceIds.isEmpty) return '无';
    return occurrenceIds
        .map((id) => occurrenceLabel(id, facts))
        .toSet()
        .join('、');
  }

  static String ruleSetLabel(String version) => switch (version) {
        QimenRuleCatalog.v1 => '时家转盘奇门 v1',
        QimenRuleCatalog.v2 => '时家转盘奇门 v2',
        _ => '时家转盘奇门（未知版本）',
      };

  static String analysisStatusLabel(QimenAnalysisStatus status) =>
      switch (status) {
        QimenAnalysisStatus.complete => '分析完整',
        QimenAnalysisStatus.unsupportedPanSchema => '排盘版本暂不支持',
        QimenAnalysisStatus.invalidPanFacts => '排盘事实不完整',
      };

  static String focusPriorityLabel(QimenFocusPriority priority) =>
      switch (priority) {
        QimenFocusPriority.primary => '主焦点',
        QimenFocusPriority.secondary => '辅助焦点',
      };

  static String traceStageLabel(QimenTraceStage stage) => switch (stage) {
        QimenTraceStage.input => '输入校验',
        QimenTraceStage.focus => '焦点定位',
        QimenTraceStage.fact => '事实评估',
        QimenTraceStage.conflict => '冲突处理',
        QimenTraceStage.verdict => '综合裁决',
        QimenTraceStage.yingQi => '应期观察',
      };

  static String evaluationStatusLabel(QimenEvaluationStatus status) =>
      switch (status) {
        QimenEvaluationStatus.matched => '已命中',
        QimenEvaluationStatus.notMatched => '未命中',
        QimenEvaluationStatus.notApplicable => '不适用',
        QimenEvaluationStatus.suppressed => '已压制',
      };

  static String polarityLabel(Polarity polarity) => switch (polarity) {
        Polarity.ji => '有利',
        Polarity.xiong => '不利',
        Polarity.neutral => '中性',
      };

  static String triggerKindLabel(QimenYingQiTriggerKind kind) => switch (kind) {
        QimenYingQiTriggerKind.stem => '天干到临',
        QimenYingQiTriggerKind.branch => '地支到临',
        QimenYingQiTriggerKind.solarTerm => '节气到临',
        QimenYingQiTriggerKind.conditionRelease => '条件解除',
      };

  static String releaseTriggerLabel(String triggerKind) =>
      switch (triggerKind) {
        'stem' => '天干到临',
        'branch' => '地支到临',
        'solarTerm' => '节气到临',
        'conditionRelease' => '条件解除',
        _ => '解除条件',
      };

  static String verdictFactorRuleLabel(String value) {
    if (value.startsWith('焦点·')) {
      return '焦点·${roleLabel(value.substring(3))}';
    }
    if (QimenRuleCatalog.byId.containsKey(value)) return ruleLabel(value);
    if (value.startsWith('condition:')) return '未决条件';
    return '裁决因素';
  }

  static String verdictSourceLabel(String value) => value
      .split(',')
      .where((id) => id.isNotEmpty)
      .map(sourceLabel)
      .toSet()
      .join('、');

  static String narrativeLabel(
    String value, {
    Iterable<QimenFact> facts = const <QimenFact>[],
  }) {
    var localized = value;
    final occurrences = facts.toList(growable: false)
      ..sort(
        (left, right) =>
            right.occurrenceId.length.compareTo(left.occurrenceId.length),
      );
    for (final fact in occurrences) {
      localized = localized.replaceAll(
        fact.occurrenceId,
        ruleLabel(fact.ruleId),
      );
    }
    final rules = QimenRuleCatalog.all.toList(growable: false)
      ..sort(
          (left, right) => right.ruleId.length.compareTo(left.ruleId.length));
    for (final rule in rules) {
      localized = localized.replaceAll(rule.ruleId, rule.displayTerm);
    }
    for (final source in QimenSourceCatalog.all) {
      localized = localized.replaceAll(source.sourceId, source.title);
    }
    final roles = _roleLabels.entries.toList(growable: false)
      ..sort((left, right) => right.key.length.compareTo(left.key.length));
    for (final role in roles) {
      localized = localized.replaceAll(role.key, role.value);
    }
    const technicalLabels = <String, String>{
      'hostedHeaven': '寄宫天盘',
      'hostedEarth': '寄宫地盘',
      'hostedBoth': '天地盘同寄',
      'primary': '主盘',
      'hosted': '寄宫',
      'decisive': '决定层',
      'conditional': '条件层',
      'corroborating': '佐证层',
      'contextual': '背景层',
    };
    for (final entry in technicalLabels.entries) {
      localized = localized.replaceAll(entry.key, entry.value);
    }
    return localized
        .replaceAll(RegExp(r'QMV1-[A-Z0-9-]+(?:@[^\s，。；：]+)?'), '内部审计项')
        .replaceAll(RegExp(r'QMS[A-Z0-9-]+'), '规则来源');
  }

  static String diagnosticSummary(QimenAnalysisDiagnostic diagnostic) =>
      switch (diagnostic.code) {
        'QMV1-E-UNSUPPORTED-PAN-SCHEMA' => '该历史排盘版本暂不支持当前分析。',
        'QMV1-E-PAN-DESERIALIZATION' => '排盘记录无法完整读取。',
        'QMV1-E-DAY-JIA-FOCUS-UNRESOLVED' => '日干焦点无法定位。',
        'QMV1-E-FOCUS-UNRESOLVED' => '主要分析焦点无法唯一定位。',
        'QMV1-E-EMPTY-RESULT-ID' => '排盘记录缺少有效标识。',
        'QMV1-E-INVALID-DAY-PILLAR' => '日柱事实无效。',
        'QMV1-E-INVALID-HOUR-PILLAR' => '时柱事实无效。',
        'QMV1-E-INVALID-MONTH-PILLAR' => '月柱事实无效。',
        'QMV1-E-INCOMPLETE-PALACES' => '九宫事实不完整。',
        _ => '排盘事实未通过完整性校验。',
      };

  static String diagnosticFieldLabel(String path) {
    if (path.contains('dayGanZhi')) return '日柱';
    if (path.contains('hourGanZhi')) return '时柱';
    if (path.contains('monthGanZhi')) return '月柱';
    if (path.contains('palaces')) return '九宫事实';
    if (path.contains('schemaVersion')) return '排盘版本';
    if (path == r'$.id') return '排盘标识';
    return '排盘数据';
  }

  static String yingQiScaleLabel(YingQiScale scale) => scale.name;
}
