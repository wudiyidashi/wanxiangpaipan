import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/qimen_formatter.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

import '../../../services/qimen/analysis/helpers/qimen_analysis_fixtures.dart';

void main() {
  group('QimenStructuredFormatter', () {
    test('输出冻结九宫顺序、程序分析投影与不可重算策略', () {
      final formatter = QimenStructuredFormatter();
      final output = formatter.format(
        fixedQimenAnalysisResult(),
        question: '项目是否适合推进？',
      );

      expect(output.systemType, 'qimen');
      expect(output.userQuestion, '项目是否适合推进？');
      expect(
        (output.coreData['palaces'] as List)
            .map((value) => (value as Map)['number']),
        QimenStructuredFormatter.palaceOrder,
      );

      final basis = output.coreData['calculationBasis'] as Map;
      expect(basis['panSchemaVersion'], 1);
      expect(basis['analysisProjectionSchemaVersion'], 1);
      expect(basis['analysisRuleSetVersion'], 'v1');
      expect(basis['timeBasis'], 'beijing');
      expect(basis['hostingMode'], 'kunTwo');
      expect(basis['hiddenStemMode'], 'dutyDoorHourStem');

      final focusAndFacts = output.coreData['focusAndFacts'] as Map;
      expect(focusAndFacts['status'], 'complete');
      expect(focusAndFacts['focuses'], isNotEmpty);
      expect(focusAndFacts['facts'], isNotEmpty);
      expect(focusAndFacts['trace'], isNotEmpty);

      expect(
        output.coreData['policy'],
        <String, dynamic>{
          'calculationOwner': 'program',
          'mayRecalculatePan': false,
          'mayRecalculateAnalysis': false,
          'mayOverrideVerdict': false,
        },
      );
      expect(output.coreData['sources'], isNotEmpty);
    });

    test('渲染包含裁决、压制链、来源和应期免责，不产生评分', () {
      final formatter = QimenStructuredFormatter();
      final rendered = formatter.render(
        formatter.format(fixedQimenAnalysisResult()),
      );

      expect(rendered, contains('洛书九宫完整事实'));
      expect(rendered, contains('程序裁决与冲突'));
      expect(rendered, contains('裁决行：'));
      expect(rendered, contains('calculationOwner=program'));
      expect(rendered, contains('mayRecalculateAnalysis=false'));
      expect(rendered, contains('mayOverrideVerdict=false'));
      expect(rendered, contains('不保证事件发生或结论自动转吉'));
      expect(rendered, isNot(contains('百分比')));
      expect(rendered, isNot(contains('加权')));
      expect(rendered, isNot(contains('星级')));
    });

    test('兼容诊断在 formatter 边界阻止任何 AI prompt 组装', () {
      final invalidPan = fixedQimenAnalysisPanMap()..['id'] = '';
      final invalidResult = QimenResult.fromJson(invalidPan);

      expect(
        () => QimenStructuredFormatter().format(invalidResult),
        throwsA(
          isA<QimenAnalysisCompatibilityException>()
              .having(
                (error) => error.message,
                'message',
                contains('status=invalidPanFacts'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('QMV1-E-EMPTY-RESULT-ID'),
              ),
        ),
      );
    });

    test('拒绝非奇门结果类型', () {
      final dynamic formatter = QimenStructuredFormatter();

      expect(
        () => formatter.format(_NonQimenResult()),
        throwsA(isA<TypeError>()),
      );
    });
  });
}

class _NonQimenResult implements DivinationResult {
  @override
  String get id => 'not-qimen';

  @override
  DateTime get castTime => DateTime.utc(2026);

  @override
  CastMethod get castMethod => CastMethod.time;

  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  LunarInfo get lunarInfo => throw UnsupportedError('not used');

  @override
  String getSummary() => 'not qimen';

  @override
  Map<String, dynamic> toJson() => const <String, dynamic>{};
}
