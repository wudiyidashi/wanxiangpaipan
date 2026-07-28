import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
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

    for (final testCase in <({
      String field,
      Object value,
      String code,
    })>[
      (field: 'name', value: '错宫', code: 'QMV1-E-PALACE-NAME'),
      (field: 'trigram', value: '错卦', code: 'QMV1-E-PALACE-TRIGRAM'),
      (
        field: 'direction',
        value: '错向',
        code: 'QMV1-E-PALACE-DIRECTION',
      ),
      (
        field: 'branches',
        value: <String>['子', '亥'],
        code: 'QMV1-E-PALACE-BRANCHES',
      ),
    ]) {
      test('rejects corrupted palace ${testCase.field} metadata', () {
        final result = mutatedQimenAnalysisResult((json) {
          qimenAnalysisPalaceJson(json, 1)[testCase.field] = testCase.value;
        });

        final guard = QimenAnalysisInputGuard.validate(result);
        final diagnostic = guard.diagnostics.singleWhere(
          (value) => value.code == testCase.code,
        );

        expect(guard.status, QimenAnalysisStatus.invalidPanFacts);
        expect(
          diagnostic.path,
          '\$.palaces[number=1].${testCase.field}',
        );
      });
    }

    test('rejects a hosted heaven stem moved off its rotated source', () {
      final result = mutatedQimenAnalysisResult((json) {
        final palaces =
            (json['palaces'] as List<dynamic>).cast<Map<String, dynamic>>();
        final original = palaces.singleWhere(
          (palace) => palace['hostedHeavenStem'] != null,
        );
        final hostedStem = original['hostedHeavenStem'];
        original['hostedHeavenStem'] = null;
        palaces.firstWhere(
          (palace) => palace['number'] != original['number'],
        )['hostedHeavenStem'] = hostedStem;
      });

      final guard = QimenAnalysisInputGuard.validate(result);
      expect(
        guard.diagnostics.map((value) => value.code),
        contains('QMV1-E-HOSTED-HEAVEN'),
      );
    });

    test('rejects Tian Qin hosted away from the Tian Rui occurrence', () {
      final result = mutatedQimenAnalysisResult((json) {
        final palaces =
            (json['palaces'] as List<dynamic>).cast<Map<String, dynamic>>();
        final original = palaces.singleWhere(
          (palace) => palace['hostedStar'] != null,
        );
        original['hostedStar'] = null;
        palaces.firstWhere(
          (palace) => palace['star'] != '天芮',
        )['hostedStar'] = '天禽';
      });

      final guard = QimenAnalysisInputGuard.validate(result);
      expect(
        guard.diagnostics.map((value) => value.code),
        contains('QMV1-E-HOSTED-STAR'),
      );
    });

    test('rejects a duplicated hidden-stem permutation', () {
      final result = mutatedQimenAnalysisResult((json) {
        final palaces = (json['palaces'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .where((palace) => palace['hiddenStem'] != null)
            .toList(growable: false);
        palaces[1]['hiddenStem'] = palaces.first['hiddenStem'];
      });

      final guard = QimenAnalysisInputGuard.validate(result);
      expect(
        guard.diagnostics.map((value) => value.code),
        contains('QMV1-E-HIDDEN-STEMS'),
      );
    });

    test('rejects unknown current and effective solar terms', () {
      final current = mutatedQimenAnalysisResult((json) {
        final context =
            Map<String, dynamic>.from(json['temporalContext'] as Map)
              ..['currentSolarTerm'] = '不存在节气';
        json['temporalContext'] = context;
      });
      final effective = mutatedQimenAnalysisResult((json) {
        final juInfo = Map<String, dynamic>.from(json['juInfo'] as Map)
          ..['effectiveSolarTerm'] = '不存在节气';
        json['juInfo'] = juInfo;
      });

      for (final result in <QimenResult>[current, effective]) {
        final guard = QimenAnalysisInputGuard.validate(result);
        expect(
          guard.diagnostics.map((value) => value.code),
          contains('QMV1-E-SOLAR-TERM'),
        );
      }
    });
  });
}
