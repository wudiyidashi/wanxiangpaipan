import 'package:flutter/material.dart';

import '../../../domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import '../../../domain/services/qimen/analysis/models/qimen_analysis_projection.dart';
import '../../../domain/services/qimen/analysis/qimen_analyzer.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../models/qimen_result.dart';
import 'qimen_result_sections.dart';

class QimenResultScreen extends StatefulWidget {
  const QimenResultScreen({
    super.key,
    required this.result,
  });

  final QimenResult result;

  @override
  State<QimenResultScreen> createState() => _QimenResultScreenState();
}

class _QimenResultScreenState extends State<QimenResultScreen> {
  late QimenAnalysisReport _report;
  late QimenAnalysisProjection _projection;

  @override
  void initState() {
    super.initState();
    _deriveAnalysis(widget.result);
  }

  @override
  void didUpdateWidget(covariant QimenResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _deriveAnalysis(widget.result);
    }
  }

  void _deriveAnalysis(QimenResult result) {
    _report = QimenAnalyzer.analyze(result);
    _projection = QimenAnalysisProjection.fromReport(_report);
  }

  String? get _aiUnavailableReason {
    if (_projection.status == QimenAnalysisStatus.complete) {
      return null;
    }
    final diagnosticCodes =
        _projection.diagnostics.map((diagnostic) => diagnostic.code).join('、');
    final detail =
        diagnosticCodes.isEmpty ? _projection.status.id : diagnosticCodes;
    return '当前奇门分析未通过兼容校验（$detail）。为避免基于不完整盘面事实'
        '生成解释，AI 分析已暂停；本地盘面、裁决和兼容诊断仍可查看。';
  }

  @override
  Widget build(BuildContext context) => DivinationResultPage(
        result: widget.result,
        title: '奇门遁甲排盘结果',
        fallbackQuestion:
            widget.result.questionId.isEmpty ? null : widget.result.questionId,
        aiAnalysisUnavailableReason: _aiUnavailableReason,
        buildSections: (context, question) => <Widget>[
          QimenBasisSection(result: widget.result, question: question),
          QimenDutySection(result: widget.result),
          QimenPalaceSection(result: widget.result, report: _report),
          QimenMarkersSection(result: widget.result),
          QimenVerdictSection(projection: _projection),
          QimenFactsSection(projection: _projection),
          QimenTimingSection(candidates: _projection.yingQiCandidates),
        ],
      );
}
