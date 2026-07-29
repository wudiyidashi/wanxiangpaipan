import '../../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../../divination_systems/qimen/models/qimen_result.dart';
import '../../shared/tiangan_dizhi_service.dart';
import '../qimen_constants.dart';
import 'models/qimen_analysis_models.dart';
import 'models/qimen_rule_models.dart';
import 'qimen_input_ref_resolver.dart';
import 'rules/qimen_focus_catalog.dart';
import 'rules/qimen_rule_catalog.dart';

class QimenFocusResolution {
  const QimenFocusResolution({
    required this.focuses,
    required this.diagnostics,
    required this.trace,
  });

  final List<QimenFocus> focuses;
  final List<QimenAnalysisDiagnostic> diagnostics;
  final List<QimenTraceStep> trace;

  bool get hasUniquePrimaryFocus {
    final self = focuses.where((focus) => focus.roleId == 'self');
    final matter = focuses.where((focus) => focus.roleId == 'matter');
    return self.length == 1 && matter.length == 1;
  }
}

class QimenFocusResolver {
  QimenFocusResolver._();

  static QimenFocusResolution resolve(
    QimenResult result, {
    String ruleSetVersion = 'current',
  }) {
    final resolvedVersion = QimenRuleCatalog.resolve(ruleSetVersion).version;
    final focuses = <QimenFocus>[];
    final diagnostics = <QimenAnalysisDiagnostic>[];
    final trace = <QimenTraceStep>[];
    final dayStem = result.temporalContext.dayGanZhi.substring(0, 1);
    final rawHourStem = result.temporalContext.hourGanZhi.substring(0, 1);

    if (dayStem == '甲' && resolvedVersion == QimenRuleCatalog.v1) {
      diagnostics.add(const QimenAnalysisDiagnostic(
        code: 'QMV1-E-DAY-JIA-FOCUS-UNRESOLVED',
        path: r'$.temporalContext.dayGanZhi',
        message: 'day stem Jia has no explicit day-specific hidden instrument '
            'in pan schema v1',
      ));
      trace.add(_trace(
        ruleId: QimenRuleCatalog.focusSelf,
        roleId: 'self',
        status: QimenEvaluationStatus.notApplicable,
        refs: <QimenInputRef>[
          QimenInputRef(
            path: r'$.temporalContext.dayGanZhi',
            value: result.temporalContext.dayGanZhi,
          ),
        ],
        explanation: '日干为甲，但 schema v1 只保存时旬遁仪；不借用时旬首猜测日干落宫。',
      ));
    } else {
      final requestedStem = dayStem == '甲'
          ? _dayXunHiddenStem(result.temporalContext.dayGanZhi)
          : dayStem;
      _addStemFocus(
        result: result,
        requestedStem: requestedStem,
        roleId: 'self',
        priority: QimenFocusPriority.primary,
        ruleId: QimenRuleCatalog.focusSelf,
        reason: dayStem == '甲'
            ? '日干甲按日柱${result.temporalContext.dayGanZhi}所在旬的遁仪$requestedStem'
                '定位求测者；只读取已排定天盘干及显式寄宫字段。'
            : '日干$dayStem代表求测者，只读取已排定天盘干及显式寄宫字段。',
        focuses: focuses,
        diagnostics: diagnostics,
        trace: trace,
        extraRefs: <QimenInputRef>[
          QimenInputRef(
            path: r'$.temporalContext.dayGanZhi',
            value: result.temporalContext.dayGanZhi,
          ),
        ],
      );
    }

    final effectiveHourStem =
        rawHourStem == '甲' ? result.xunHiddenStem : rawHourStem;
    _addStemFocus(
      result: result,
      requestedStem: effectiveHourStem,
      roleId: 'matter',
      priority: QimenFocusPriority.primary,
      ruleId: QimenRuleCatalog.focusMatter,
      reason: rawHourStem == '甲'
          ? '时干甲按结果已保存的时旬遁仪${result.xunHiddenStem}定位所问之事。'
          : '时干$rawHourStem代表所问之事，只读取已排定天盘干及显式寄宫字段。',
      focuses: focuses,
      diagnostics: diagnostics,
      trace: trace,
      extraRefs: <QimenInputRef>[
        QimenInputRef(
          path: r'$.temporalContext.hourGanZhi',
          value: result.temporalContext.hourGanZhi,
        ),
        if (rawHourStem == '甲')
          QimenInputRef(
            path: r'$.xunHiddenStem',
            value: result.xunHiddenStem,
          ),
      ],
    );

    final categoryRule =
        QimenFocusCatalog.byCategory[result.panParams.questionCategory]!;
    for (final indicator in categoryRule.indicators) {
      _addSecondaryFocus(
        result: result,
        ruleSetVersion: resolvedVersion,
        ruleId: categoryRule.ruleId,
        indicator: indicator,
        focuses: focuses,
        diagnostics: diagnostics,
        trace: trace,
      );
    }

    return QimenFocusResolution(
      focuses: List<QimenFocus>.unmodifiable(focuses),
      diagnostics: List<QimenAnalysisDiagnostic>.unmodifiable(diagnostics),
      trace: List<QimenTraceStep>.unmodifiable(trace),
    );
  }

  static String _dayXunHiddenStem(String dayGanZhi) {
    final dayIndex = TianGanDiZhiService.getGanZhiIndex(dayGanZhi);
    if (dayIndex < 0) {
      throw StateError('无法由日柱推导日旬：$dayGanZhi');
    }
    final xunShou = TianGanDiZhiService.getGanZhi(dayIndex - dayIndex % 10);
    final hiddenStem = QimenConstants.xunHiddenStem[xunShou];
    if (hiddenStem == null) {
      throw StateError('无法由旬首推导遁仪：$xunShou');
    }
    return hiddenStem;
  }

  static void _addStemFocus({
    required QimenResult result,
    required String requestedStem,
    required String roleId,
    required QimenFocusPriority priority,
    required String ruleId,
    required String reason,
    required List<QimenFocus> focuses,
    required List<QimenAnalysisDiagnostic> diagnostics,
    required List<QimenTraceStep> trace,
    List<QimenInputRef> extraRefs = const <QimenInputRef>[],
  }) {
    final primary = result.palaces
        .where((palace) => palace.heavenStem == requestedStem)
        .toList(growable: false);
    if (primary.length != 1) {
      _unresolved(
        roleId: roleId,
        ruleId: ruleId,
        path: r'$.palaces[*].heavenStem',
        value: requestedStem,
        reason: '天盘主干无法唯一定位',
        diagnostics: diagnostics,
        trace: trace,
      );
      return;
    }
    final origin = primary.single;
    final hosted = result.palaces
        .where((palace) => palace.hostedHeavenStem == requestedStem)
        .toList(growable: false);
    final useHosted = origin.number == 5 && hosted.length == 1;
    final effective = useHosted ? hosted.single : origin;
    final refs = <QimenInputRef>[
      QimenInputRef(
        path: QimenInputPath.palace(origin.number, 'heavenStem'),
        value: requestedStem,
      ),
      if (useHosted)
        QimenInputRef(
          path: QimenInputPath.palace(
            effective.number,
            'hostedHeavenStem',
          ),
          value: requestedStem,
        ),
      ...extraRefs,
    ];
    final sourceIds = QimenRuleCatalog.rule(ruleId).sourceIds;
    final focus = QimenFocus(
      roleId: roleId,
      indicatorKind: QimenIndicatorKind.stem,
      indicatorValue: requestedStem,
      palaceNumber: effective.number,
      originPalaceNumber: origin.number,
      priority: priority,
      isHosted: useHosted,
      reason: useHosted ? '$reason 中五主事实保留于5宫，作用宫取显式寄宫。' : reason,
      ruleId: ruleId,
      sourceIds: sourceIds,
    );
    focuses.add(focus);
    trace.add(_trace(
      ruleId: ruleId,
      roleId: roleId,
      status: QimenEvaluationStatus.matched,
      refs: refs,
      sourceIds: sourceIds,
      explanation: focus.reason,
    ));
  }

  static void _addSecondaryFocus({
    required QimenResult result,
    required String ruleSetVersion,
    required String ruleId,
    required QimenFocusIndicatorSpec indicator,
    required List<QimenFocus> focuses,
    required List<QimenAnalysisDiagnostic> diagnostics,
    required List<QimenTraceStep> trace,
  }) {
    if (indicator.kind == QimenIndicatorKind.stem) {
      _addStemFocus(
        result: result,
        requestedStem: indicator.value!,
        roleId: indicator.roleId,
        priority: QimenFocusPriority.secondary,
        ruleId: ruleId,
        reason: '${indicator.reason} 本项目约定（奇门分析 $ruleSetVersion）。',
        focuses: focuses,
        diagnostics: diagnostics,
        trace: trace,
      );
      return;
    }

    final QimenPalace? palace;
    final bool isHosted;
    final String value;
    final String unresolvedPath;
    final int originPalaceNumber;
    final List<QimenInputRef> refs;
    switch (indicator.lookup) {
      case QimenFocusLookup.dutyStar:
        palace = _palace(result, result.zhiFuPalace);
        value = result.zhiFuStar;
        isHosted = palace?.hostedStar == value;
        final origins = result.palaces
            .where((candidate) => candidate.star == value)
            .toList(growable: false);
        originPalaceNumber = isHosted && origins.length == 1
            ? origins.single.number
            : result.zhiFuPalace;
        unresolvedPath = r'$.zhiFuPalace';
        refs = <QimenInputRef>[
          QimenInputRef(path: r'$.zhiFuStar', value: result.zhiFuStar),
          QimenInputRef(
            path: r'$.zhiFuPalace',
            value: result.zhiFuPalace.toString(),
          ),
          if (palace != null)
            QimenInputRef(
              path: QimenInputPath.palace(
                palace.number,
                isHosted ? 'hostedStar' : 'star',
              ),
              value: value,
            ),
        ];
      case QimenFocusLookup.dutyDoor:
        palace = _palace(result, result.zhiShiPalace);
        value = result.zhiShiDoor;
        isHosted = false;
        originPalaceNumber = result.zhiShiPalace;
        unresolvedPath = r'$.zhiShiPalace';
        refs = <QimenInputRef>[
          QimenInputRef(path: r'$.zhiShiDoor', value: result.zhiShiDoor),
          QimenInputRef(
            path: r'$.zhiShiPalace',
            value: result.zhiShiPalace.toString(),
          ),
        ];
      case QimenFocusLookup.horse:
        palace = _palace(result, result.horsePalace);
        value = result.horseBranch;
        isHosted = false;
        originPalaceNumber = result.horsePalace;
        unresolvedPath = r'$.horsePalace';
        refs = <QimenInputRef>[
          QimenInputRef(path: r'$.horseBranch', value: result.horseBranch),
          QimenInputRef(
            path: r'$.horsePalace',
            value: result.horsePalace.toString(),
          ),
          if (palace != null)
            QimenInputRef(
              path: QimenInputPath.palace(palace.number, 'isHorse'),
              value: palace.isHorse.toString(),
            ),
        ];
      case QimenFocusLookup.value:
        final matches = _findByValue(result, indicator.kind, indicator.value!);
        palace = matches.length == 1 ? matches.single : null;
        value = indicator.value!;
        isHosted = false;
        originPalaceNumber = palace?.number ?? -1;
        unresolvedPath = r'$.palaces[*].' + indicator.kind.id;
        refs = palace == null
            ? const <QimenInputRef>[]
            : <QimenInputRef>[
                QimenInputRef(
                  path: QimenInputPath.palace(
                    palace.number,
                    indicator.kind.id,
                  ),
                  value: value,
                ),
              ];
    }

    if (palace == null) {
      _unresolved(
        roleId: indicator.roleId,
        ruleId: ruleId,
        path: unresolvedPath,
        value: value,
        reason: '类别指标无法唯一定位',
        diagnostics: diagnostics,
        trace: trace,
      );
      return;
    }

    final sourceIds = QimenRuleCatalog.rule(ruleId).sourceIds;
    final focus = QimenFocus(
      roleId: indicator.roleId,
      indicatorKind: indicator.kind,
      indicatorValue: value,
      palaceNumber: palace.number,
      originPalaceNumber: originPalaceNumber,
      priority: QimenFocusPriority.secondary,
      isHosted: isHosted,
      reason: '${indicator.reason} 本项目约定（奇门分析 $ruleSetVersion）。',
      ruleId: ruleId,
      sourceIds: sourceIds,
    );
    focuses.add(focus);
    trace.add(_trace(
      ruleId: ruleId,
      roleId: indicator.roleId,
      status: QimenEvaluationStatus.matched,
      refs: refs,
      sourceIds: sourceIds,
      explanation: focus.reason,
    ));
  }

  static List<QimenPalace> _findByValue(
    QimenResult result,
    QimenIndicatorKind kind,
    String value,
  ) =>
      result.palaces.where((palace) {
        return switch (kind) {
          QimenIndicatorKind.star => palace.star == value,
          QimenIndicatorKind.door => palace.door == value,
          QimenIndicatorKind.deity => palace.deity == value,
          _ => false,
        };
      }).toList(growable: false);

  static QimenPalace? _palace(QimenResult result, int number) {
    for (final palace in result.palaces) {
      if (palace.number == number) return palace;
    }
    return null;
  }

  static void _unresolved({
    required String roleId,
    required String ruleId,
    required String path,
    required String value,
    required String reason,
    required List<QimenAnalysisDiagnostic> diagnostics,
    required List<QimenTraceStep> trace,
  }) {
    diagnostics.add(QimenAnalysisDiagnostic(
      code: 'QMV1-E-FOCUS-UNRESOLVED',
      path: path,
      message: '$reason: $roleId=$value',
    ));
    trace.add(_trace(
      ruleId: ruleId,
      roleId: roleId,
      status: QimenEvaluationStatus.notApplicable,
      refs: <QimenInputRef>[QimenInputRef(path: path, value: value)],
      explanation: '$reason；不按列表首项猜测。',
    ));
  }

  static QimenTraceStep _trace({
    required String ruleId,
    required String roleId,
    required QimenEvaluationStatus status,
    required List<QimenInputRef> refs,
    required String explanation,
    List<String> sourceIds = const <String>[],
  }) =>
      QimenTraceStep(
        stepId: 'focus:$ruleId:$roleId',
        sequence: -1,
        stage: QimenTraceStage.focus,
        ruleId: ruleId,
        status: status,
        inputRefs: refs,
        outputOccurrenceIds: status == QimenEvaluationStatus.matched
            ? <String>[roleId]
            : const [],
        sourceIds: sourceIds,
        explanation: explanation,
      );
}
