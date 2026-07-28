import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_constraint_fact_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_formation_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_relation_fact_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/facts/qimen_structure_fact_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_source_catalog.dart';

import 'helpers/qimen_analysis_fixtures.dart';
import 'helpers/qimen_rule_coverage_manifest.dart';

const _goldenPath =
    'test/unit/services/qimen/analysis/fixtures/qimen_analysis_goldens.json';

void main() {
  group('Qimen rule coverage manifest', () {
    test('coverage manifest maps every released rule to auditable evidence',
        () {
      final releasedRuleIds =
          QimenRuleCatalog.all.map((rule) => rule.ruleId).toSet();
      expect(
        QimenRuleCoverageManifest.byRuleId,
        hasLength(QimenRuleCoverageManifest.all.length),
      );
      expect(QimenRuleCoverageManifest.byRuleId.keys.toSet(), releasedRuleIds);

      final goldenFile = File(_goldenPath);
      expect(goldenFile.existsSync(), true, reason: _goldenPath);
      final goldenCases = jsonDecode(goldenFile.readAsStringSync()) as List;
      final availableGoldenTags = goldenCases
          .expand((value) =>
              ((value as Map)['expected'] as Map)['coverageTags'] as List)
          .cast<String>()
          .toSet();

      for (final entry in QimenRuleCoverageManifest.all) {
        final rule = QimenRuleCatalog.rule(entry.ruleId);
        expect(entry.sourceIds, rule.sourceIds, reason: entry.ruleId);
        expect(entry.sourceIds, isNotEmpty, reason: entry.ruleId);
        expect(
          entry.sourceIds.every(QimenSourceCatalog.byId.containsKey),
          true,
          reason: entry.ruleId,
        );
        expect(entry.positiveTestRefs, isNotEmpty, reason: entry.ruleId);
        expect(entry.negativeTestRefs, isNotEmpty, reason: entry.ruleId);
        for (final testRef in <String>{
          ...entry.positiveTestRefs,
          ...entry.negativeTestRefs,
        }) {
          _expectTestReferenceExists(testRef, entry.ruleId);
        }

        final decisionExemption = entry.decisionUsageExemption?.trim() ?? '';
        expect(
          entry.decisionOrConflictRuleIds.isNotEmpty ||
              decisionExemption.isNotEmpty,
          true,
          reason: '${entry.ruleId} lacks decision/conflict usage or exemption',
        );
        for (final linkedRuleId in entry.decisionOrConflictRuleIds) {
          final linkedRule = QimenRuleCatalog.rule(linkedRuleId);
          expect(
            <QimenRuleFamily>{
              QimenRuleFamily.conflict,
              QimenRuleFamily.verdict,
            },
            contains(linkedRule.family),
            reason: '${entry.ruleId} -> $linkedRuleId',
          );
        }

        final goldenExemption = entry.goldenCoverageExemption?.trim() ?? '';
        expect(
          entry.goldenCoverageTags.isNotEmpty || goldenExemption.isNotEmpty,
          true,
          reason: '${entry.ruleId} lacks golden coverage or exemption',
        );
        expect(
          availableGoldenTags,
          containsAll(entry.goldenCoverageTags),
          reason: entry.ruleId,
        );
      }
    });

    test(
      'remaining constraint rules have independent positive and negative cases',
      () {
        final positive = QimenConstraintFactService.evaluate(
          fixedQimenAnalysisResult(),
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          positive.facts.map((fact) => fact.ruleId).toSet(),
          containsAll(<String>{
            QimenRuleCatalog.doorPressure,
            QimenRuleCatalog.voidState,
            QimenRuleCatalog.horseActivation,
          }),
        );

        final negativeResult = mutatedQimenAnalysisResult((json) {
          const sameElementDoor = <String, String>{
            '水': '休门',
            '木': '伤门',
            '火': '景门',
            '土': '生门',
            '金': '开门',
          };
          for (final palace in (json['palaces'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
            palace['voidBranches'] = <String>[];
            palace['isHorse'] = false;
            if (palace['door'] != null) {
              palace['door'] = sameElementDoor[palace['element']];
            }
          }
        });
        final negative = QimenConstraintFactService.evaluate(
          negativeResult,
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        for (final ruleId in const <String>[
          QimenRuleCatalog.doorPressure,
          QimenRuleCatalog.voidState,
          QimenRuleCatalog.horseActivation,
        ]) {
          expect(
            negative.facts.where((fact) => fact.ruleId == ruleId),
            isEmpty,
            reason: ruleId,
          );
          expect(
            negative.trace.singleWhere((step) => step.ruleId == ruleId).status,
            QimenEvaluationStatus.notMatched,
            reason: ruleId,
          );
        }
      },
    );

    test('structure rules have independent positive and negative cases', () {
      for (final ruleId in const <String>[
        QimenRuleCatalog.starFuYin,
        QimenRuleCatalog.doorFuYin,
        QimenRuleCatalog.combinedFuYin,
        QimenRuleCatalog.starFanYin,
        QimenRuleCatalog.doorFanYin,
        QimenRuleCatalog.combinedFanYin,
        QimenRuleCatalog.fiveNotMeeting,
      ]) {
        final positive = QimenStructureFactService.evaluate(
          _structureResult(ruleId, matches: true),
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        final negative = QimenStructureFactService.evaluate(
          _structureResult(ruleId, matches: false),
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );

        expect(
          positive.facts.any((fact) => fact.ruleId == ruleId),
          true,
          reason: 'positive $ruleId',
        );
        expect(
          negative.facts.any((fact) => fact.ruleId == ruleId),
          false,
          reason: 'negative $ruleId',
        );
        expect(
          negative.trace.singleWhere((step) => step.ruleId == ruleId).status,
          QimenEvaluationStatus.notMatched,
          reason: ruleId,
        );
      }
    });

    test(
      'every executable formation rule has independent positive and negative cases',
      () {
        for (final spec in QimenRuleCatalog.formationSpecs) {
          final positive = QimenFormationService.evaluate(
            _formationResult(spec, matches: true),
            const <QimenFocus>[],
            ruleSetVersion: QimenRuleCatalog.v1,
          );
          final negative = QimenFormationService.evaluate(
            _formationResult(spec, matches: false),
            const <QimenFocus>[],
            ruleSetVersion: QimenRuleCatalog.v1,
          );
          expect(
            positive.facts.any(
              (fact) =>
                  fact.ruleId == spec.ruleId &&
                  fact.relatedPalaceNumbers.contains(
                    spec.palaceNumber ?? 1,
                  ),
            ),
            true,
            reason: 'positive ${spec.ruleId}',
          );
          expect(
            negative.facts.any(
              (fact) =>
                  fact.ruleId == spec.ruleId &&
                  fact.relatedPalaceNumbers.contains(
                    spec.palaceNumber ?? 1,
                  ),
            ),
            false,
            reason: 'negative ${spec.ruleId}',
          );
        }

        final dutyPositive = QimenFormationService.evaluate(
          _threeWonderDutyResult(matches: true),
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        final dutyNegative = QimenFormationService.evaluate(
          _threeWonderDutyResult(matches: false),
          const <QimenFocus>[],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          dutyPositive.facts.any(
            (fact) => fact.ruleId == QimenRuleCatalog.threeWonderDuty,
          ),
          true,
        );
        expect(
          dutyNegative.facts.any(
            (fact) => fact.ruleId == QimenRuleCatalog.threeWonderDuty,
          ),
          false,
        );
      },
    );

    test(
      'relation rules have positive, negative, and incomplete-focus cases',
      () {
        final result = fixedQimenAnalysisResult();
        final favorable = QimenRelationFactService.evaluate(
          result,
          <QimenFocus>[
            _primaryFocus('self', 2),
            _primaryFocus('matter', 2),
          ],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          favorable.facts.map((fact) => fact.ruleId),
          <String>[QimenRuleCatalog.favorableConvergence],
        );

        final adverse = QimenRelationFactService.evaluate(
          result,
          <QimenFocus>[
            _primaryFocus('self', 1),
            _primaryFocus('matter', 2),
          ],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(
          adverse.facts.map((fact) => fact.ruleId),
          <String>[QimenRuleCatalog.adverseConvergence],
        );

        final incomplete = QimenRelationFactService.evaluate(
          result,
          <QimenFocus>[_primaryFocus('self', 1)],
          ruleSetVersion: QimenRuleCatalog.v1,
        );
        expect(incomplete.facts, isEmpty);
        expect(
          incomplete.trace.map((step) => step.status).toSet(),
          <QimenEvaluationStatus>{QimenEvaluationStatus.notApplicable},
        );

        for (final category in QimenQuestionCategory.values) {
          final categoryResult = mutatedQimenAnalysisResult((json) {
            final params = Map<String, dynamic>.from(json['panParams'] as Map)
              ..['questionCategory'] = category.id;
            json['panParams'] = params;
          });
          final roles = QimenRuleCatalog.convergenceFocusRoles[category]!;
          final categoryBatch = QimenRelationFactService.evaluate(
            categoryResult,
            <QimenFocus>[
              _primaryFocus(roles.$1, 2),
              _primaryFocus(roles.$2, 2),
            ],
            ruleSetVersion: QimenRuleCatalog.v1,
          );
          final categoryFact = categoryBatch.facts.singleWhere(
            (fact) => fact.ruleId == QimenRuleCatalog.favorableConvergence,
          );
          expect(
            categoryFact.inputRefs,
            contains(
              isA<QimenInputRef>()
                  .having(
                    (ref) => ref.path,
                    'path',
                    r'$.panParams.questionCategory',
                  )
                  .having((ref) => ref.value, 'value', category.id),
            ),
            reason: category.id,
          );
        }
      },
    );
  });
}

void _expectTestReferenceExists(String testRef, String ruleId) {
  final separator = testRef.indexOf('#');
  expect(separator, greaterThan(0), reason: '$ruleId -> $testRef');
  final path = testRef.substring(0, separator);
  final marker = testRef.substring(separator + 1);
  final file = File(path);
  expect(file.existsSync(), true, reason: '$ruleId -> $path');
  expect(file.readAsStringSync(), contains(marker),
      reason: '$ruleId -> $testRef');
}

QimenResult _structureResult(String ruleId, {required bool matches}) {
  return mutatedQimenAnalysisResult((json) {
    const starOrigins = <int, String>{
      1: '天蓬',
      2: '天芮',
      3: '天冲',
      4: '天辅',
      5: '天禽',
      6: '天心',
      7: '天柱',
      8: '天任',
      9: '天英',
    };
    const doorOrigins = <int, String>{
      1: '休门',
      2: '死门',
      3: '伤门',
      4: '杜门',
      6: '开门',
      7: '惊门',
      8: '生门',
      9: '景门',
    };
    const opposite = <int, int>{
      1: 9,
      2: 8,
      3: 7,
      4: 6,
      5: 5,
      6: 4,
      7: 3,
      8: 2,
      9: 1,
    };
    final isFuYin = <String>{
      QimenRuleCatalog.starFuYin,
      QimenRuleCatalog.doorFuYin,
      QimenRuleCatalog.combinedFuYin,
    }.contains(ruleId);
    final isFanYin = <String>{
      QimenRuleCatalog.starFanYin,
      QimenRuleCatalog.doorFanYin,
      QimenRuleCatalog.combinedFanYin,
    }.contains(ruleId);

    if (isFuYin || isFanYin) {
      for (final palace
          in (json['palaces'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final number = palace['number'] as int;
        final sourceNumber = isFanYin ? opposite[number]! : number;
        palace['star'] = starOrigins[sourceNumber];
        if (number != 5) palace['door'] = doorOrigins[sourceNumber];
      }
      if (!matches) {
        final first = qimenAnalysisPalaceJson(json, 1);
        final breaksStar = ruleId == QimenRuleCatalog.starFuYin ||
            ruleId == QimenRuleCatalog.combinedFuYin ||
            ruleId == QimenRuleCatalog.starFanYin ||
            ruleId == QimenRuleCatalog.combinedFanYin;
        if (breaksStar) {
          first['star'] = isFuYin ? '天英' : '天蓬';
        } else {
          first['door'] = isFuYin ? '开门' : '休门';
        }
      }
      return;
    }

    final temporal = Map<String, dynamic>.from(json['temporalContext'] as Map)
      ..['dayGanZhi'] = '戊申'
      ..['hourGanZhi'] = matches ? '甲寅' : '乙卯';
    json['temporalContext'] = temporal;
  });
}

QimenResult _formationResult(
  QimenFormationSpec spec, {
  required bool matches,
}) {
  return mutatedQimenAnalysisResult((json) {
    final palaceNumber = spec.palaceNumber ?? 1;
    final palace = qimenAnalysisPalaceJson(json, palaceNumber)
      ..['hostedHeavenStem'] = null
      ..['hostedEarthStem'] = null;
    final heaven = spec.heavenStem ??
        (spec.heavenMatchesDayStem
            ? '戊'
            : spec.heavenMatchesXunHiddenStem
                ? '癸'
                : palace['heavenStem'] as String);
    final earth = spec.earthStem ??
        (spec.earthMatchesDayStem
            ? '戊'
            : spec.earthMatchesXunHiddenStem
                ? '癸'
                : palace['earthStem'] as String);
    palace['heavenStem'] = matches ? heaven : _differentStem(heaven);
    palace['earthStem'] = earth;
    if (spec.door != null) palace['door'] = spec.door;
    if (spec.allowedDoors.isNotEmpty) palace['door'] = spec.allowedDoors.first;
    if (spec.deity != null) palace['deity'] = spec.deity;
  });
}

QimenResult _threeWonderDutyResult({required bool matches}) {
  return mutatedQimenAnalysisResult((json) {
    json['zhiShiPalace'] = 1;
    final palace = qimenAnalysisPalaceJson(json, 1)
      ..['heavenStem'] = matches ? '乙' : '戊'
      ..['hostedHeavenStem'] = null;
    if (!matches) palace['hostedEarthStem'] = null;
  });
}

String _differentStem(String stem) => stem == '乙' ? '丙' : '乙';

QimenFocus _primaryFocus(String roleId, int palaceNumber) => QimenFocus(
      roleId: roleId,
      indicatorKind: QimenIndicatorKind.stem,
      indicatorValue: roleId == 'self' ? '戊' : '癸',
      palaceNumber: palaceNumber,
      originPalaceNumber: palaceNumber,
      priority: QimenFocusPriority.primary,
      isHosted: false,
      reason: 'coverage fixture',
      ruleId: roleId == 'self'
          ? QimenRuleCatalog.focusSelf
          : QimenRuleCatalog.focusMatter,
      sourceIds: QimenRuleCatalog.rule(
        roleId == 'self'
            ? QimenRuleCatalog.focusSelf
            : QimenRuleCatalog.focusMatter,
      ).sourceIds,
    );
