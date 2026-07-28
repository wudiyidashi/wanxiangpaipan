import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';

const _fixturePath = 'test/unit/services/qimen/analysis/fixtures/'
    'qimen_analysis_goldens.json';
const _panEngineCommit = '7d226a690fa411ca1fe74f021c0fa54dca875f2c';

void main() {
  final cases = _loadCases();

  group('Qimen whole-pan analysis goldens', () {
    test('freeze the A9 source, verdict, and coverage matrix', () {
      final sourceCases = cases
          .where((testCase) => testCase['population'] == 'sourceBacked')
          .toList(growable: false);
      final syntheticCases = cases
          .where((testCase) => testCase['population'] == 'synthetic')
          .toList(growable: false);
      final allTags = cases
          .expand((testCase) => _strings(_expected(testCase)['coverageTags']))
          .toSet();

      expect(sourceCases.length, greaterThanOrEqualTo(12));
      expect(syntheticCases, isNotEmpty);
      expect(
        cases.map((testCase) => testCase['caseId']).toSet().length,
        cases.length,
      );
      expect(
        sourceCases.map((testCase) => testCase['sourceId']).toSet(),
        containsAll(<String>{
          'QMS-CLASSIC-YANYI',
          'QMS-CLASSIC-YUANLING',
        }),
      );
      expect(
        sourceCases
            .map((testCase) => _pan(testCase)['juInfo'])
            .map((value) => _map(value)['dun'])
            .toSet(),
        <String>{'yang', 'yin'},
      );
      expect(
        cases.map((testCase) => testCase['questionCategory']).toSet(),
        QimenQuestionCategory.values.map((value) => value.id).toSet(),
      );
      expect(
        cases.map((testCase) => _expected(testCase)['trend']).toSet(),
        <String>{'可成', '难成', '待条件', '趋势不明'},
      );
      expect(
        cases.map((testCase) => _expected(testCase)['decisionRowId']).toSet(),
        <String>{
          QimenRuleCatalog.decision00,
          QimenRuleCatalog.decision10,
          QimenRuleCatalog.decision20,
          QimenRuleCatalog.decision30,
          QimenRuleCatalog.decision40,
          QimenRuleCatalog.decision50,
          QimenRuleCatalog.decision60,
        },
      );
      expect(
        cases
            .expand(
              (testCase) => _strings(_expected(testCase)['conflictPolicyIds']),
            )
            .toSet(),
        containsAll(<String>{
          QimenRuleCatalog.conflictExplicitPair,
          QimenRuleCatalog.conflictFocusSpecificity,
          QimenRuleCatalog.conflictTierPrecedence,
          QimenRuleCatalog.conflictUnresolved,
        }),
      );
      expect(
        allTags,
        containsAll(<String>{
          'family:focus',
          'family:state',
          'family:constraint',
          'family:structure',
          'family:stemResponse',
          'family:formation',
          'family:relation',
          'family:conflict',
          'family:verdict',
          'family:yingQi',
          'yingQi:${QimenRuleCatalog.yingQiConditionRelease}',
          'yingQi:${QimenRuleCatalog.yingQiHorse}',
          'yingQi:${QimenRuleCatalog.yingQiSolarTerm}',
          'yingQiExcluded:${QimenRuleCatalog.yingQiFuYin}',
          'yingQiExcluded:${QimenRuleCatalog.yingQiFanYin}',
          'yingQiExcluded:${QimenRuleCatalog.yingQiStem}',
        }),
      );

      for (final testCase in cases) {
        _expectCompleteMetadata(testCase);
      }
    });

    test('label synthetic verdict and conflict witnesses explicitly', () {
      final syntheticById = <String, Map<String, dynamic>>{
        for (final testCase
            in cases.where((value) => value['population'] == 'synthetic'))
          testCase['caseId'] as String: testCase,
      };
      expect(
        syntheticById.keys,
        containsAll(<String>{
          'QM-S-D10',
          'QM-S-D30',
          'QM-S-D40',
          'QM-S-D50',
          'QM-S-X-FOCUS',
        }),
      );
      for (final testCase in syntheticById.values) {
        expect(testCase['sourceNature'], 'projectSyntheticCoverage');
        expect(testCase['sourceId'], 'QMS-PROJECT-V1');
        expect((testCase['syntheticPurpose'] as String).trim(), isNotEmpty);
        expect(
          _strings(_expected(testCase)['coverageTags']),
          contains('population:synthetic'),
        );
      }
    });

    test('keep G05 and G06 as explicit day-Jia non-match boundaries', () {
      final byId = <String, Map<String, dynamic>>{
        for (final testCase in cases) testCase['caseId'] as String: testCase,
      };
      final expectedExclusions = <String, String>{
        'QM-G05': QimenRuleCatalog.hiddenStemPattern,
        'QM-G06': QimenRuleCatalog.flyingStemPattern,
      };
      for (final entry in expectedExclusions.entries) {
        final testCase = byId[entry.key]!;
        final pillars = _map(testCase['representativePillars']);
        final assertions = _map(testCase['ruleAssertions']);
        expect((pillars['dayGanZhi'] as String).startsWith('甲'), isTrue);
        expect(
          _strings(assertions['requiredNotMatchedRuleIds']),
          <String>[entry.value],
        );
        expect(
          _strings(_expected(testCase)['factRuleIds']),
          isNot(contains(entry.value)),
        );
        expect(
          _strings(_expected(testCase)['coverageTags']),
          contains('boundary:dayJia'),
        );
      }
    });

    test('lock source palace assertions for G10 through G12', () {
      final byId = <String, Map<String, dynamic>>{
        for (final testCase in cases) testCase['caseId'] as String: testCase,
      };
      for (final caseId in <String>['QM-G10', 'QM-G11', 'QM-G12']) {
        final testCase = byId[caseId]!;
        final assertions = _maps(testCase['sourcePanAssertions']);
        expect(assertions, isNotEmpty, reason: caseId);
        _expectSourcePanAssertions(_pan(testCase), assertions, caseId);
      }
    });

    for (final testCase in cases) {
      final caseId = testCase['caseId'] as String;
      test('$caseId restores schema v1 and matches the report snapshot', () {
        final persistedPan = _map(jsonDecode(jsonEncode(_pan(testCase))));
        expect(persistedPan['schemaVersion'], QimenResult.currentSchemaVersion);

        final pan = QimenResult.fromJson(persistedPan);
        expect(pan.toJson(), persistedPan);
        final report = QimenAnalyzer.analyze(pan, ruleSetVersion: 'v1');
        final expected = _expected(testCase);
        final factRuleIds = report.facts
            .map((fact) => fact.ruleId)
            .toSet()
            .toList(growable: false)
          ..sort();
        final factOccurrenceIds = report.facts
            .map((fact) => fact.occurrenceId)
            .toSet()
            .toList(growable: false)
          ..sort();
        final conflictPolicyIds = report.conflicts
            .map((conflict) => conflict.policyId)
            .toSet()
            .toList(growable: false)
          ..sort();
        final yingQiRuleIds = report.yingQiCandidates
            .map((candidate) => candidate.ruleId)
            .toSet()
            .toList(growable: false)
          ..sort();

        expect(report.status.id, expected['status']);
        expect(
          report.focuses.map((value) => value.toJson()).toList(),
          expected['focuses'],
        );
        expect(
          report.focuses.map((value) => value.roleId).toList(),
          expected['focusRoleIds'],
        );
        expect(factRuleIds, expected['factRuleIds']);
        expect(factOccurrenceIds, expected['factOccurrenceIds']);
        expect(
          report.facts.map((value) => value.toJson()).toList(),
          expected['facts'],
        );
        expect(conflictPolicyIds, expected['conflictPolicyIds']);
        expect(
          report.conflicts.map((value) => value.toJson()).toList(),
          expected['conflicts'],
        );
        expect(
          report.verdict.matchedDecisionRowId,
          expected['decisionRowId'],
        );
        expect(report.verdict.judgment.trend.name, expected['trend']);
        expect(report.verdict.toJson(), expected['verdict']);
        expect(
          report.verdict.conditionLinks.map((value) => value.toJson()).toList(),
          expected['conditions'],
        );
        expect(yingQiRuleIds, expected['yingQiRuleIds']);
        expect(
          report.yingQiCandidates.map((value) => value.toJson()).toList(),
          expected['yingQiCandidates'],
        );
        expect(report.toJson(), _decodeReportSnapshot(expected));

        _expectRuleAssertions(testCase, factRuleIds, conflictPolicyIds, report);
        _expectSourcePanAssertions(
          persistedPan,
          _maps(testCase['sourcePanAssertions']),
          caseId,
        );
      });

      test('$caseId is deterministic across restored reruns', () {
        final firstPan = QimenResult.fromJson(_map(_pan(testCase)));
        final secondPan = QimenResult.fromJson(
          _map(jsonDecode(jsonEncode(_pan(testCase)))),
        );
        final first = QimenAnalyzer.analyze(firstPan, ruleSetVersion: 'v1');
        final second = QimenAnalyzer.analyze(secondPan, ruleSetVersion: 'v1');

        expect(second.toCanonicalJson(), first.toCanonicalJson());
      });
    }
  });
}

void _expectCompleteMetadata(Map<String, dynamic> testCase) {
  final caseId = testCase['caseId'] as String;
  final source = _map(testCase['sourceCitation']);
  final pillars = _map(testCase['representativePillars']);
  final assertions = _map(testCase['ruleAssertions']);
  final pan = _pan(testCase);
  final expected = _expected(testCase);
  final tags = _strings(expected['coverageTags']);
  final sortedTags = [...tags]..sort();

  for (final field in <String>[
    'title',
    'population',
    'sourceNature',
    'sourceId',
    'sourceSection',
    'accessedOn',
    'sourceAssertion',
    'manualAdjudication',
    'panFixtureId',
    'panEngineCommit',
    'ruleSetId',
    'ruleSetVersion',
    'questionCategory',
  ]) {
    expect((testCase[field] as String).trim(), isNotEmpty,
        reason: '$caseId.$field');
  }
  for (final field in <String>[
    'sourceId',
    'kind',
    'title',
    'editionOrRevision',
    'locator',
    'claimSummary',
    'adjudicationNote',
  ]) {
    expect((source[field] as String).trim(), isNotEmpty,
        reason: '$caseId.sourceCitation.$field');
  }
  expect(source['sourceId'], testCase['sourceId'], reason: caseId);
  expect((pillars['reason'] as String).trim(), isNotEmpty, reason: caseId);
  expect((pillars['yearGanZhi'] as String).length, 2, reason: caseId);
  expect((pillars['monthGanZhi'] as String).length, 2, reason: caseId);
  expect((pillars['dayGanZhi'] as String).length, 2, reason: caseId);
  expect((pillars['hourGanZhi'] as String).length, 2, reason: caseId);
  expect(testCase['panEngineCommit'], _panEngineCommit, reason: caseId);
  expect(testCase['panSchemaVersion'], 1, reason: caseId);
  expect(testCase['analysisSchemaVersion'], 1, reason: caseId);
  expect(testCase['ruleSetVersion'], 'v1', reason: caseId);
  expect(testCase['panFixtureId'], caseId, reason: caseId);
  expect(pan['id'], caseId, reason: caseId);
  expect(pan['schemaVersion'], 1, reason: caseId);
  expect(
      _map(pan['panParams'])['questionCategory'], testCase['questionCategory'],
      reason: caseId);
  expect(assertions['requiredMatchedRuleIds'], isA<List<dynamic>>(),
      reason: caseId);
  expect(assertions['requiredNotMatchedRuleIds'], isA<List<dynamic>>(),
      reason: caseId);
  expect(assertions['requiredConflictPolicyIds'], isA<List<dynamic>>(),
      reason: caseId);
  expect(expected['focuses'], isA<List<dynamic>>(), reason: caseId);
  expect(expected['facts'], isA<List<dynamic>>(), reason: caseId);
  expect(expected['conflicts'], isA<List<dynamic>>(), reason: caseId);
  expect(expected['verdict'], isA<Map<String, dynamic>>(), reason: caseId);
  expect(expected['conditions'], isA<List<dynamic>>(), reason: caseId);
  expect(expected['yingQiCandidates'], isA<List<dynamic>>(), reason: caseId);
  expect(
    (expected['reportSnapshotGzipBase64'] as String).trim(),
    isNotEmpty,
    reason: caseId,
  );
  expect(tags, sortedTags, reason: '$caseId coverage tags must be sorted');
  expect(tags.toSet().length, tags.length, reason: caseId);
  expect(
    tags,
    containsAll(<String>{
      'population:${testCase['population']}',
      'source:${testCase['sourceId']}',
      'category:${testCase['questionCategory']}',
      'decision:${expected['decisionRowId']}',
      'trend:${expected['trend']}',
    }),
    reason: caseId,
  );

  if (testCase['population'] == 'sourceBacked') {
    expect(source['locator'], contains('oldid='), reason: caseId);
    expect(source['accessedOn'], testCase['accessedOn'], reason: caseId);
    expect(testCase['syntheticPurpose'], isNull, reason: caseId);
    final hasRuleAssertion =
        _strings(assertions['requiredMatchedRuleIds']).isNotEmpty ||
            _strings(assertions['requiredNotMatchedRuleIds']).isNotEmpty;
    expect(
      hasRuleAssertion || _maps(testCase['sourcePanAssertions']).isNotEmpty,
      isTrue,
      reason: '$caseId must lock a source rule or persisted pan claim',
    );
  } else {
    expect((testCase['syntheticPurpose'] as String).trim(), isNotEmpty,
        reason: caseId);
  }
}

void _expectRuleAssertions(
  Map<String, dynamic> testCase,
  List<String> factRuleIds,
  List<String> conflictPolicyIds,
  QimenAnalysisReport report,
) {
  final assertions = _map(testCase['ruleAssertions']);
  expect(
    factRuleIds,
    containsAll(_strings(assertions['requiredMatchedRuleIds'])),
  );
  for (final ruleId in _strings(assertions['requiredNotMatchedRuleIds'])) {
    expect(factRuleIds, isNot(contains(ruleId)));
  }
  expect(
    conflictPolicyIds,
    containsAll(_strings(assertions['requiredConflictPolicyIds'])),
  );
  final requiredRow = assertions['requiredDecisionRowId'];
  if (requiredRow != null) {
    expect(report.verdict.matchedDecisionRowId, requiredRow);
  }
}

void _expectSourcePanAssertions(
  Map<String, dynamic> pan,
  List<Map<String, dynamic>> assertions,
  String caseId,
) {
  final palaces = _maps(pan['palaces']);
  for (final assertion in assertions) {
    expect((assertion['claim'] as String).trim(), isNotEmpty, reason: caseId);
    final palaceNumber = assertion['palaceNumber'] as int;
    final palace = palaces.singleWhere(
      (value) => value['number'] == palaceNumber,
    );
    final expectedFields = _map(assertion['expectedFields']);
    expect(expectedFields, isNotEmpty, reason: caseId);
    for (final field in expectedFields.entries) {
      expect(
        palace[field.key],
        field.value,
        reason: '$caseId palace $palaceNumber.${field.key}',
      );
    }
  }
}

List<Map<String, dynamic>> _loadCases() {
  final decoded = jsonDecode(File(_fixturePath).readAsStringSync()) as List;
  return decoded.map(_map).toList(growable: false);
}

Map<String, dynamic> _decodeReportSnapshot(Map<String, dynamic> expected) {
  final compressed = base64Decode(
    expected['reportSnapshotGzipBase64'] as String,
  );
  return _map(jsonDecode(utf8.decode(gzip.decode(compressed))));
}

Map<String, dynamic> _pan(Map<String, dynamic> testCase) =>
    _map(testCase['pan']);

Map<String, dynamic> _expected(Map<String, dynamic> testCase) =>
    _map(testCase['expected']);

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value! as Map);

List<Map<String, dynamic>> _maps(Object? value) =>
    (value! as List).map(_map).toList(growable: false);

List<String> _strings(Object? value) => List<String>.from(value! as List);
