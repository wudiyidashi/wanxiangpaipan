import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_trace.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/liuyao_analysis_projection.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';

import 'helpers/analysis_fixtures.dart';

LiuYaoResult _buildSelectedResult() {
  final mainGua = buildGua(const <int>[7, 7, 7, 7, 7, 7]);
  return LiuYaoResult(
    id: 'projection-closure-fixture',
    castTime: DateTime(2026, 7, 1, 1, 30),
    castMethod: CastMethod.manual,
    mainGua: mainGua,
    changingGua: buildChangingGua(mainGua),
    lunarInfo: buildLunar(yueJian: '午', riGanZhi: '甲子'),
    liuShen: const <String>['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
    yongShenPosition: 6,
  );
}

void main() {
  test('projection rejects analysis schema mismatched with its rule set', () {
    final result = _buildSelectedResult();
    final currentReport = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: result.yongShenPosition,
    );
    final compatibilityReport = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: result.yongShenPosition,
      ruleSetVersion: LiuYaoRuleCatalog.v2,
    );

    expect(currentReport.analysisSchemaVersion, 2);
    expect(compatibilityReport.analysisSchemaVersion, 1);
    for (final corrupted in [
      currentReport.copyWith(analysisSchemaVersion: 1),
      compatibilityReport.copyWith(analysisSchemaVersion: 2),
    ]) {
      expect(
        () => LiuYaoAnalysisProjection.fromReport(
          result: result,
          report: corrupted,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('version mismatch'),
          ),
        ),
      );
    }
  });

  test('projection rejects a factor with an orphan upstream occurrence', () {
    final result = _buildSelectedResult();
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: result.yongShenPosition,
    );
    final judgment = report.judgment!;
    final factor = judgment.factors.first;
    final corrupted = report.copyWith(
      judgment: judgment.copyWith(
        factors: [
          factor.copyWith(
            upstreamOccurrenceIds: const <String>['lyo-missing'],
          ),
          ...judgment.factors.skip(1),
        ],
      ),
    );

    expect(
      () => LiuYaoAnalysisProjection.fromReport(
        result: result,
        report: corrupted,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('factor'),
        ),
      ),
    );
  });

  test('projection rejects trace IDs outside the report provenance', () {
    final result = _buildSelectedResult();
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: result.yongShenPosition,
    );
    final firstStep = report.trace.first;

    LiuYaoAnalysisTraceStep corruptedStep({
      List<String>? ruleIds,
      List<String>? occurrenceIds,
    }) =>
        LiuYaoAnalysisTraceStep(
          stageId: firstStep.stageId,
          ruleIds: ruleIds ?? firstStep.ruleIds,
          occurrenceIds: occurrenceIds ?? firstStep.occurrenceIds,
          notes: firstStep.notes,
        );

    expect(
      () => LiuYaoAnalysisProjection.fromReport(
        result: result,
        report: report.copyWith(
          trace: <LiuYaoAnalysisTraceStep>[
            corruptedStep(
              occurrenceIds: const <String>['lyo-missing'],
            ),
            ...report.trace.skip(1),
          ],
        ),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => LiuYaoAnalysisProjection.fromReport(
        result: result,
        report: report.copyWith(
          trace: <LiuYaoAnalysisTraceStep>[
            corruptedStep(
              ruleIds: const <String>['liuyao.rule.missing'],
            ),
            ...report.trace.skip(1),
          ],
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
