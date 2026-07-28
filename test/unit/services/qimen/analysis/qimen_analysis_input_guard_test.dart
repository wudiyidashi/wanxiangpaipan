import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analysis_input_guard.dart';

import 'helpers/qimen_analysis_fixtures.dart';

void main() {
  group('QimenAnalysisInputGuard palace metadata', () {
    for (final element in const <String>['火', 'invalid-element']) {
      test('rejects palace 1 element $element deterministically', () {
        final result = mutatedQimenAnalysisResult((json) {
          qimenAnalysisPalaceJson(json, 1)['element'] = element;
        });

        final guard = QimenAnalysisInputGuard.validate(result);
        final diagnostic = guard.diagnostics.singleWhere(
          (value) => value.code == 'QMV1-E-PALACE-ELEMENT',
        );

        expect(guard.status, QimenAnalysisStatus.invalidPanFacts);
        expect(diagnostic.path, r'$.palaces[number=1].element');
        expect(diagnostic.message, contains('frozen palace element 水'));
      });
    }
  });
}
