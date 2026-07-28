import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_constraint_fact_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_formation_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_star_door_state_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_stem_response_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';

import 'helpers/qimen_analysis_fixtures.dart';
import 'helpers/qimen_stem_response_expectations.dart';

void main() {
  group('Qimen seasonal state facts', () {
    const elements = <String>['木', '火', '土', '金', '水'];
    const starByElement = <String, String>{
      '木': '天冲',
      '火': '天英',
      '土': '天任',
      '金': '天心',
      '水': '天蓬',
    };
    const doorByElement = <String, String>{
      '木': '伤门',
      '火': '景门',
      '土': '生门',
      '金': '开门',
      '水': '休门',
    };
    const monthPillarByElement = <String, String>{
      '木': '甲寅',
      '火': '丁巳',
      '土': '丙辰',
      '金': '庚申',
      '水': '甲子',
    };
    const expectedStarStates = <String, List<String>>{
      '木': <String>['相', '旺', '休', '囚', '废'],
      '火': <String>['废', '相', '旺', '休', '囚'],
      '土': <String>['囚', '废', '相', '旺', '休'],
      '金': <String>['休', '囚', '废', '相', '旺'],
      '水': <String>['旺', '休', '囚', '废', '相'],
    };
    const expectedDoorStates = <String, List<String>>{
      '木': <String>['旺', '废', '囚', '休', '相'],
      '火': <String>['相', '旺', '废', '囚', '休'],
      '土': <String>['休', '相', '旺', '废', '囚'],
      '金': <String>['囚', '休', '相', '旺', '废'],
      '水': <String>['废', '囚', '休', '相', '旺'],
    };

    test('stamps the explicitly supplied resolved rule-set version', () {
      const resolvedVersion = 'resolved-version-under-test';
      final batch = QimenStarDoorStateService.evaluate(
        fixedQimenAnalysisResult(),
        const <QimenFocus>[],
        ruleSetVersion: resolvedVersion,
      );

      expect(batch.facts, isNotEmpty);
      expect(
        batch.facts.every(
          (fact) => fact.ruleSetVersion == resolvedVersion,
        ),
        true,
      );
    });

    test('covers the independent 25-relation star and door matrices', () {
      for (final entityElement in elements) {
        for (var monthIndex = 0; monthIndex < elements.length; monthIndex++) {
          final monthElement = elements[monthIndex];
          final result = mutatedQimenAnalysisResult((json) {
            _setMonthPillar(json, monthPillarByElement[monthElement]!);
            final palace = qimenAnalysisPalaceJson(json, 1);
            palace['star'] = starByElement[entityElement];
            palace['door'] = doorByElement[entityElement];
          });
          final batch = QimenStarDoorStateService.evaluate(
            result,
            const <QimenFocus>[],
            ruleSetVersion: QimenRuleCatalog.v1,
          );
          final starState = expectedStarStates[entityElement]![monthIndex];
          final doorState = expectedDoorStates[entityElement]![monthIndex];
          expect(
            _hasRuleAt(batch.facts, _starRuleId(starState), 1),
            true,
            reason: 'star $entityElement in $monthElement month',
          );
          expect(
            _hasRuleAt(batch.facts, _doorSeasonRuleId(doorState), 1),
            true,
            reason: 'door $entityElement in $monthElement month',
          );
        }
      }
    });

    test('maps all twelve persisted month branches independently', () {
      const pillars = <String, String>{
        '寅': '甲寅',
        '卯': '乙卯',
        '辰': '丙辰',
        '巳': '丁巳',
        '午': '戊午',
        '未': '己未',
        '申': '庚申',
        '酉': '辛酉',
        '戌': '壬戌',
        '亥': '癸亥',
        '子': '甲子',
        '丑': '乙丑',
      };
      const branchElements = <String, String>{
        '寅': '木',
        '卯': '木',
        '巳': '火',
        '午': '火',
        '申': '金',
        '酉': '金',
        '亥': '水',
        '子': '水',
        '辰': '土',
        '未': '土',
        '戌': '土',
        '丑': '土',
      };
      for (final entry in pillars.entries) {
        final result = mutatedQimenAnalysisResult((json) {
          _setMonthPillar(json, entry.value);
          final palace = qimenAnalysisPalaceJson(json, 1);
          palace['star'] = '天冲';
          palace['door'] = '伤门';
        });
        final batch = QimenStarDoorStateService.evaluate(
          result,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        final monthElement = branchElements[entry.key]!;
        final monthIndex = elements.indexOf(monthElement);
        expect(
          _hasRuleAt(
            batch.facts,
            _starRuleId(expectedStarStates['木']![monthIndex]),
            1,
          ),
          true,
          reason: 'month branch ${entry.key}',
        );
      }
    });

    test('use month-pillar branch and distinct star and door formulas', () {
      final batch = QimenStarDoorStateService.evaluate(
        fixedQimenAnalysisResult(),
        const <QimenFocus>[],
        ruleSetVersion: QimenRuleCatalog.v1,
      );

      const expectedStars = <int, String>{
        1: QimenRuleCatalog.starStateXiu,
        2: QimenRuleCatalog.starStateFei,
        3: QimenRuleCatalog.starStateWang,
        4: QimenRuleCatalog.starStateXiang,
        7: QimenRuleCatalog.starStateQiu,
      };
      const expectedDoors = <int, String>{
        2: QimenRuleCatalog.doorSeasonXiang,
        6: QimenRuleCatalog.doorSeasonWang,
        7: QimenRuleCatalog.doorSeasonXiu,
        1: QimenRuleCatalog.doorSeasonQiu,
        3: QimenRuleCatalog.doorSeasonFei,
      };
      for (final entry in expectedStars.entries) {
        expect(
          _hasRuleAt(batch.facts, entry.value, entry.key),
          true,
          reason: 'nine-star state at palace ${entry.key}',
        );
      }
      for (final entry in expectedDoors.entries) {
        expect(
          _hasRuleAt(batch.facts, entry.value, entry.key),
          true,
          reason: 'eight-door state at palace ${entry.key}',
        );
      }
      for (final fact in batch.facts.where(
        (fact) =>
            fact.category == QimenFactCategory.starState ||
            fact.ruleId.startsWith('QMV1-F-DOOR-SEASON-'),
      )) {
        expect(
          fact.inputRefs,
          contains(
            isA<QimenInputRef>()
                .having(
                  (ref) => ref.path,
                  'path',
                  r'$.temporalContext.monthGanZhi',
                )
                .having((ref) => ref.value, 'value', '壬戌'),
          ),
        );
      }
    });

    test('keeps door-palace relation and door pressure as separate facts', () {
      final result = fixedQimenAnalysisResult();
      final state = QimenStarDoorStateService.evaluate(
        result,
        const <QimenFocus>[],
        ruleSetVersion: QimenRuleCatalog.v1,
      );
      final constraints = QimenConstraintFactService.evaluate(
        result,
        const <QimenFocus>[],
        ruleSetVersion: QimenRuleCatalog.v1,
      );

      expect(
        _hasRuleAt(
          state.facts,
          QimenRuleCatalog.doorControlsPalace,
          8,
        ),
        true,
      );
      expect(
        _hasRuleAt(
          constraints.facts,
          QimenRuleCatalog.doorPressure,
          8,
        ),
        true,
      );
    });
  });

  group('Qimen constraint facts', () {
    test('uses the adopted complete QiYi tomb palace table', () {
      const tombs = <String, int>{
        '乙': 2,
        '癸': 2,
        '丙': 6,
        '戊': 6,
        '丁': 8,
        '己': 8,
        '庚': 8,
        '辛': 4,
        '壬': 4,
      };

      for (final entry in tombs.entries) {
        final result = mutatedQimenAnalysisResult((json) {
          qimenAnalysisPalaceJson(json, entry.value)['heavenStem'] = entry.key;
        });
        final batch = QimenConstraintFactService.evaluate(
          result,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          _hasRuleAt(
            batch.facts,
            QimenRuleCatalog.qiYiTomb,
            entry.value,
          ),
          true,
          reason: '${entry.key} enters tomb at palace ${entry.value}',
        );

        final wrongPalace = entry.value == 1 ? 2 : 1;
        final negative = mutatedQimenAnalysisResult((json) {
          qimenAnalysisPalaceJson(json, wrongPalace)['heavenStem'] = entry.key;
        });
        final negativeBatch = QimenConstraintFactService.evaluate(
          negative,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          _hasRuleAt(
            negativeBatch.facts,
            QimenRuleCatalog.qiYiTomb,
            wrongPalace,
          ),
          false,
          reason: '${entry.key} does not enter tomb at palace $wrongPalace',
        );
      }
    });

    test('evaluates all six punishments only at persisted duty palace', () {
      const punishmentPalaces = <String, int>{
        '戊': 3,
        '己': 2,
        '庚': 8,
        '辛': 9,
        '壬': 4,
        '癸': 4,
      };
      for (final entry in punishmentPalaces.entries) {
        final positive = mutatedQimenAnalysisResult((json) {
          json['xunHiddenStem'] = entry.key;
          json['zhiFuPalace'] = entry.value;
          qimenAnalysisPalaceJson(json, entry.value)['heavenStem'] = entry.key;
        });
        final positiveBatch = QimenConstraintFactService.evaluate(
          positive,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        final punishment = positiveBatch.facts.singleWhere(
          (fact) => fact.ruleId == QimenRuleCatalog.instrumentPunishment,
        );
        expect(punishment.relatedPalaceNumbers, <int>[entry.value]);
        expect(
          punishment.inputRefs.any(
            (ref) => ref.path == r'$.xunHiddenStem' && ref.value == entry.key,
          ),
          true,
        );
        expect(
          punishment.inputRefs.any(
            (ref) =>
                ref.path == r'$.zhiFuPalace' && ref.value == '${entry.value}',
          ),
          true,
        );

        final wrongPalace = entry.value == 1 ? 2 : 1;
        final negative = mutatedQimenAnalysisResult((json) {
          json['xunHiddenStem'] = entry.key;
          json['zhiFuPalace'] = entry.value;
          qimenAnalysisPalaceJson(json, entry.value)['heavenStem'] = '乙';
          qimenAnalysisPalaceJson(json, wrongPalace)['heavenStem'] = entry.key;
        });
        final negativeBatch = QimenConstraintFactService.evaluate(
          negative,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          negativeBatch.facts.where(
            (fact) => fact.ruleId == QimenRuleCatalog.instrumentPunishment,
          ),
          isEmpty,
          reason: '${entry.key} outside duty palace ${entry.value}',
        );
      }
    });

    test('preserves a hosted xun-hidden punishment occurrence separately', () {
      final result = mutatedQimenAnalysisResult((json) {
        json['zhiFuPalace'] = 4;
        qimenAnalysisPalaceJson(json, 4)['hostedHeavenStem'] = '癸';
      });
      final batch = QimenConstraintFactService.evaluate(
        result,
        const <QimenFocus>[],
        ruleSetVersion: QimenRuleCatalog.v1,
      );

      expect(
        batch.facts
            .where(
              (fact) => fact.ruleId == QimenRuleCatalog.instrumentPunishment,
            )
            .single
            .occurrenceId,
        contains(':hosted:癸'),
      );
    });
  });

  group('Qimen formation facts', () {
    test('distinguishes day-stem and xun-hidden flying/hidden formulas', () {
      final cases = <({
        String heaven,
        String earth,
        String ruleId,
      })>[
        (
          heaven: '戊',
          earth: '庚',
          ruleId: QimenRuleCatalog.flyingStemPattern,
        ),
        (
          heaven: '庚',
          earth: '戊',
          ruleId: QimenRuleCatalog.hiddenStemPattern,
        ),
        (
          heaven: '癸',
          earth: '庚',
          ruleId: QimenRuleCatalog.flyingPalacePattern,
        ),
        (
          heaven: '庚',
          earth: '癸',
          ruleId: QimenRuleCatalog.hiddenPalacePattern,
        ),
      ];

      for (final testCase in cases) {
        final result = mutatedQimenAnalysisResult((json) {
          final palace = qimenAnalysisPalaceJson(json, 1);
          palace['heavenStem'] = testCase.heaven;
          palace['earthStem'] = testCase.earth;
        });
        final batch = QimenFormationService.evaluate(
          result,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        final fact = batch.facts.singleWhere(
          (candidate) =>
              candidate.ruleId == testCase.ruleId &&
              candidate.relatedPalaceNumbers.contains(1),
        );
        if (testCase.ruleId == QimenRuleCatalog.flyingPalacePattern ||
            testCase.ruleId == QimenRuleCatalog.hiddenPalacePattern) {
          expect(
            fact.inputRefs,
            contains(
              isA<QimenInputRef>()
                  .having((ref) => ref.path, 'path', r'$.xunHiddenStem')
                  .having((ref) => ref.value, 'value', '癸'),
            ),
          );
        } else {
          expect(
            fact.inputRefs,
            contains(
              isA<QimenInputRef>()
                  .having(
                    (ref) => ref.path,
                    'path',
                    r'$.temporalContext.dayGanZhi',
                  )
                  .having((ref) => ref.value, 'value', '戊申'),
            ),
          );
        }

        final negative = mutatedQimenAnalysisResult((json) {
          final palace = qimenAnalysisPalaceJson(json, 1);
          palace['heavenStem'] = testCase.earth;
          palace['earthStem'] = testCase.heaven;
        });
        final negativeBatch = QimenFormationService.evaluate(
          negative,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          _hasRuleAt(negativeBatch.facts, testCase.ruleId, 1),
          false,
          reason: 'negative direction for ${testCase.ruleId}',
        );
      }
    });

    test('does not equate a generic Gui-plus-Gui pair with sky net', () {
      final result = mutatedQimenAnalysisResult((json) {
        final palace = qimenAnalysisPalaceJson(json, 1);
        palace['heavenStem'] = '癸';
        palace['earthStem'] = '癸';
      });
      final batch = QimenFormationService.evaluate(
        result,
        const <QimenFocus>[],
        ruleSetVersion: QimenRuleCatalog.v1,
      );

      expect(
        batch.facts.where((fact) => fact.ruleId == QimenRuleCatalog.skyNet),
        isEmpty,
      );
      expect(
        batch.trace
            .singleWhere(
              (step) => step.ruleId == QimenRuleCatalog.skyNet,
            )
            .status,
        QimenEvaluationStatus.notApplicable,
      );
    });
  });

  group('Qimen stem-response facts', () {
    test('all 81 typed pairs have independent positive and negative cases', () {
      for (final heaven in expectedStemResponseOrder) {
        for (var earthIndex = 0;
            earthIndex < expectedStemResponseOrder.length;
            earthIndex++) {
          final earth = expectedStemResponseOrder[earthIndex];
          final ruleId = expectedStemResponseRuleId(heaven, earth);
          final positive = mutatedQimenAnalysisResult((json) {
            final palace = qimenAnalysisPalaceJson(json, 1);
            palace['heavenStem'] = heaven;
            palace['earthStem'] = earth;
          });
          final positiveFacts = QimenStemResponseService.evaluate(
            positive,
            const <QimenFocus>[],
            ruleSetVersion: QimenRuleCatalog.v1,
          ).facts;
          expect(
            _hasRuleAt(positiveFacts, ruleId, 1),
            true,
            reason: 'positive $heaven+$earth',
          );

          final otherEarth = expectedStemResponseOrder[
              (earthIndex + 1) % expectedStemResponseOrder.length];
          final negative = mutatedQimenAnalysisResult((json) {
            final palace = qimenAnalysisPalaceJson(json, 1);
            palace['heavenStem'] = heaven;
            palace['earthStem'] = otherEarth;
          });
          final negativeFacts = QimenStemResponseService.evaluate(
            negative,
            const <QimenFocus>[],
            ruleSetVersion: QimenRuleCatalog.v1,
          ).facts;
          expect(
            _hasRuleAt(negativeFacts, ruleId, 1),
            false,
            reason: 'negative $heaven+$earth',
          );
        }
      }
    });
  });
}

bool _hasRuleAt(List<QimenFact> facts, String ruleId, int palaceNumber) =>
    facts.any(
      (fact) =>
          fact.ruleId == ruleId &&
          fact.relatedPalaceNumbers.contains(palaceNumber),
    );

void _setMonthPillar(Map<String, dynamic> json, String pillar) {
  final temporal = Map<String, dynamic>.from(json['temporalContext'] as Map)
    ..['monthGanZhi'] = pillar;
  final lunar = Map<String, dynamic>.from(json['lunarInfo'] as Map)
    ..['monthGanZhi'] = pillar;
  json['temporalContext'] = temporal;
  json['lunarInfo'] = lunar;
}

String _starRuleId(String state) => switch (state) {
      '旺' => QimenRuleCatalog.starStateWang,
      '相' => QimenRuleCatalog.starStateXiang,
      '休' => QimenRuleCatalog.starStateXiu,
      '囚' => QimenRuleCatalog.starStateQiu,
      '废' => QimenRuleCatalog.starStateFei,
      _ => throw StateError('unknown expected star state $state'),
    };

String _doorSeasonRuleId(String state) => switch (state) {
      '旺' => QimenRuleCatalog.doorSeasonWang,
      '相' => QimenRuleCatalog.doorSeasonXiang,
      '休' => QimenRuleCatalog.doorSeasonXiu,
      '囚' => QimenRuleCatalog.doorSeasonQiu,
      '废' => QimenRuleCatalog.doorSeasonFei,
      _ => throw StateError('unknown expected door state $state'),
    };
