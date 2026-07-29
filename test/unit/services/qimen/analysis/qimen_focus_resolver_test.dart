import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_focus_resolver.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_input_ref_resolver.dart';

import 'helpers/qimen_analysis_fixtures.dart';

void main() {
  group('QimenFocusResolver', () {
    const expectedByCategory = <QimenQuestionCategory, Set<String>>{
      QimenQuestionCategory.general: <String>{
        'self',
        'matter',
        'generalDutyStar',
        'generalDutyDoor',
      },
      QimenQuestionCategory.career: <String>{
        'self',
        'matter',
        'careerOpenDoor',
        'careerDutyStar',
      },
      QimenQuestionCategory.wealth: <String>{
        'self',
        'matter',
        'wealthLifeDoor',
        'wealthWu',
      },
      QimenQuestionCategory.relationship: <String>{
        'self',
        'matter',
        'relationshipYi',
        'relationshipGeng',
        'relationshipHarmony',
      },
      QimenQuestionCategory.health: <String>{
        'self',
        'matter',
        'healthDisease',
        'healthTreatment',
        'healthYi',
      },
      QimenQuestionCategory.study: <String>{
        'self',
        'matter',
        'studyAssistant',
        'studySceneryDoor',
        'studyDing',
      },
      QimenQuestionCategory.travel: <String>{
        'self',
        'matter',
        'travelOpenDoor',
        'travelHorse',
      },
      QimenQuestionCategory.litigation: <String>{
        'self',
        'matter',
        'litigationAlarmDoor',
        'litigationGeng',
        'litigationDutyDoor',
      },
    };

    for (final entry in expectedByCategory.entries) {
      test('${entry.key.id} keeps primary roles and exact category roles', () {
        final result = fixedQimenAnalysisResult(category: entry.key);
        final resolution = QimenFocusResolver.resolve(result);

        expect(resolution.hasUniquePrimaryFocus, true);
        expect(
          resolution.focuses.map((focus) => focus.roleId).toSet(),
          entry.value,
        );
        expect(
          resolution.focuses
              .where((focus) => focus.priority == QimenFocusPriority.primary)
              .map((focus) => focus.roleId)
              .toSet(),
          <String>{'self', 'matter'},
        );
        for (final ref in resolution.trace
            .where((step) => step.status == QimenEvaluationStatus.matched)
            .expand((step) => step.inputRefs)) {
          expect(
            QimenInputRefResolver.matches(result, ref),
            true,
            reason: '${entry.key.id}: ${ref.path}=${ref.value}',
          );
        }
      });
    }

    test('uses persisted xun hidden stem for an hour stem Jia', () {
      final result = mutatedQimenAnalysisResult((json) {
        final context = Map<String, dynamic>.from(
          json['temporalContext'] as Map,
        )..['hourGanZhi'] = '甲子';
        json['temporalContext'] = context;
      });
      final resolution = QimenFocusResolver.resolve(
        result,
        ruleSetVersion: 'v1',
      );
      final matter = resolution.focuses.singleWhere(
        (focus) => focus.roleId == 'matter',
      );

      expect(matter.indicatorValue, result.xunHiddenStem);
      expect(matter.palaceNumber, 2);
      expect(
        resolution.trace
            .singleWhere((step) => step.stepId.endsWith(':matter'))
            .inputRefs,
        contains(
          isA<QimenInputRef>()
              .having((ref) => ref.path, 'path', r'$.xunHiddenStem')
              .having((ref) => ref.value, 'value', '癸'),
        ),
      );
    });

    test('keeps a day stem Jia unresolved under pan schema v1', () {
      final result = mutatedQimenAnalysisResult((json) {
        final context = Map<String, dynamic>.from(
          json['temporalContext'] as Map,
        )..['dayGanZhi'] = '甲子';
        json['temporalContext'] = context;
      });
      final resolution = QimenFocusResolver.resolve(
        result,
        ruleSetVersion: 'v1',
      );

      expect(
        resolution.focuses.where((focus) => focus.roleId == 'self'),
        isEmpty,
      );
      expect(resolution.hasUniquePrimaryFocus, false);
      expect(
        resolution.diagnostics.map((value) => value.code),
        contains('QMV1-E-DAY-JIA-FOCUS-UNRESOLVED'),
      );
    });

    const jiaXunCases =
        <({String dayGanZhi, String hiddenStem, int palaceNumber})>[
      (dayGanZhi: '甲子', hiddenStem: '戊', palaceNumber: 4),
      (dayGanZhi: '甲戌', hiddenStem: '己', palaceNumber: 7),
      (dayGanZhi: '甲申', hiddenStem: '庚', palaceNumber: 3),
      (dayGanZhi: '甲午', hiddenStem: '辛', palaceNumber: 6),
      (dayGanZhi: '甲辰', hiddenStem: '壬', palaceNumber: 9),
      (dayGanZhi: '甲寅', hiddenStem: '癸', palaceNumber: 2),
    ];

    for (final testCase in jiaXunCases) {
      test('v2 resolves ${testCase.dayGanZhi} self from the day xun', () {
        final result = mutatedQimenAnalysisResult((json) {
          final context = Map<String, dynamic>.from(
            json['temporalContext'] as Map,
          )..['dayGanZhi'] = testCase.dayGanZhi;
          json['temporalContext'] = context;
        });
        final resolution = QimenFocusResolver.resolve(
          result,
          ruleSetVersion: 'v2',
        );
        final self = resolution.focuses.singleWhere(
          (focus) => focus.roleId == 'self',
        );
        final selfTrace = resolution.trace.singleWhere(
          (step) => step.stepId.endsWith(':self'),
        );

        expect(resolution.hasUniquePrimaryFocus, true);
        expect(resolution.diagnostics, isEmpty);
        expect(
          resolution.focuses
              .where((focus) => focus.priority == QimenFocusPriority.secondary)
              .map((focus) => focus.reason),
          everyElement(contains('奇门分析 v2')),
        );
        expect(self.indicatorValue, testCase.hiddenStem);
        expect(self.palaceNumber, testCase.palaceNumber);
        expect(
          selfTrace.inputRefs,
          contains(
            isA<QimenInputRef>()
                .having(
                  (ref) => ref.path,
                  'path',
                  r'$.temporalContext.dayGanZhi',
                )
                .having(
                  (ref) => ref.value,
                  'value',
                  testCase.dayGanZhi,
                ),
          ),
        );
        expect(
          selfTrace.inputRefs.map((ref) => ref.path),
          isNot(contains(r'$.xunHiddenStem')),
        );
        for (final ref in selfTrace.inputRefs) {
          expect(QimenInputRefResolver.matches(result, ref), true);
        }
      });
    }

    test('v2 Jia self preserves center origin and explicit hosted action', () {
      final result = mutatedQimenAnalysisResult((json) {
        final context = Map<String, dynamic>.from(
          json['temporalContext'] as Map,
        )..['dayGanZhi'] = '甲子';
        json['temporalContext'] = context;
        final palace4 = qimenAnalysisPalaceJson(json, 4);
        final palace5 = qimenAnalysisPalaceJson(json, 5);
        palace4
          ..['heavenStem'] = '丁'
          ..['hostedHeavenStem'] = '戊';
        palace5['heavenStem'] = '戊';
      });
      final resolution = QimenFocusResolver.resolve(
        result,
        ruleSetVersion: 'v2',
      );
      final self = resolution.focuses.singleWhere(
        (focus) => focus.roleId == 'self',
      );
      final refs = resolution.trace
          .singleWhere((step) => step.stepId.endsWith(':self'))
          .inputRefs;

      expect(self.originPalaceNumber, 5);
      expect(self.palaceNumber, 4);
      expect(self.isHosted, true);
      expect(
        refs.map((ref) => ref.path),
        containsAll(<String>[
          r'$.palaces[number=5].heavenStem',
          r'$.palaces[number=4].hostedHeavenStem',
          r'$.temporalContext.dayGanZhi',
        ]),
      );
    });

    test('preserves center origin when a focus acts through hosted heaven stem',
        () {
      final result = fixedQimenAnalysisResult(
        category: QimenQuestionCategory.study,
      );
      final focus = QimenFocusResolver.resolve(result).focuses.singleWhere(
            (value) => value.roleId == 'studyDing',
          );

      expect(focus.originPalaceNumber, 5);
      expect(focus.palaceNumber, 4);
      expect(focus.isHosted, true);
    });
  });
}
