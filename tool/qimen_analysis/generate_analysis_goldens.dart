import 'dart:convert';
import 'dart:io';

import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_source_catalog.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_time_service.dart';

const _outputPath =
    'test/unit/services/qimen/analysis/fixtures/qimen_analysis_goldens.json';
const _panCommit = '7d226a690fa411ca1fe74f021c0fa54dca875f2c';
const _accessedOn = '2026-07-28';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--search')) {
    await _searchSyntheticDecisionCases();
    return;
  }

  final generated = <Map<String, dynamic>>[];
  for (final seed in _seeds) {
    final entry = await _generate(seed);
    generated.add(entry);
    _printInspection(entry);
  }

  if (!arguments.contains('--write')) return;
  final file = File(_outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(generated)}\n',
  );
  stdout.writeln('Wrote ${generated.length} cases to ${file.path}');
}

Future<Map<String, dynamic>> _generate(_GoldenSeed seed) async {
  final params = QimenPanParams(
    timeBasis: QimenTimeBasis.beijing,
    sourceUtcOffsetMinutes: 480,
    questionCategory: seed.category,
  );
  final calendar = QimenTimeService.resolve(seed.castTime, params);
  final input = <String, dynamic>{
    'yearGanZhi': calendar.yearGanZhi,
    'monthGanZhi': calendar.monthGanZhi,
    'dayGanZhi': seed.dayGanZhi,
    'hourGanZhi': seed.hourGanZhi,
    'solarTerm': seed.solarTerm,
    'dun': seed.dun.id,
    'juNumber': seed.juNumber,
    'yuan': seed.yuan.id,
    'params': <String, dynamic>{
      'timeBasis': params.timeBasis.id,
      'sourceUtcOffsetMinutes': params.sourceUtcOffsetMinutes,
      'longitude': null,
      'dayBoundary': params.dayBoundary.id,
      'hostingMode': params.hostingMode.id,
      'hiddenStemMode': params.hiddenStemMode.id,
      'questionCategory': params.questionCategory.id,
    },
  };
  final cast = await QimenSystem().cast(
    method: CastMethod.manual,
    input: input,
    castTime: seed.castTime,
  ) as QimenResult;
  final panJson = Map<String, dynamic>.from(cast.toJson())
    ..['id'] = seed.caseId;
  final pan = QimenResult.fromJson(panJson);
  final report = QimenAnalyzer.analyze(pan, ruleSetVersion: 'v1');
  final factRuleIds = report.facts.map((fact) => fact.ruleId).toSet().toList()
    ..sort();
  final factOccurrenceIds =
      report.facts.map((fact) => fact.occurrenceId).toSet().toList()..sort();
  final conflictPolicyIds = report.conflicts
      .map((conflict) => conflict.policyId)
      .toSet()
      .toList()
    ..sort();
  final yingQiRuleIds = report.yingQiCandidates
      .map((candidate) => candidate.ruleId)
      .toSet()
      .toList()
    ..sort();
  final excludedYingQiRuleIds = report.trace
      .where(
        (step) =>
            step.stage == QimenTraceStage.yingQi &&
            step.status == QimenEvaluationStatus.notApplicable,
      )
      .map((step) => step.ruleId)
      .toSet()
      .toList()
    ..sort();

  _validateSeedAssertions(
    seed: seed,
    panJson: panJson,
    factRuleIds: factRuleIds,
    conflictPolicyIds: conflictPolicyIds,
    decisionRowId: report.verdict.matchedDecisionRowId,
  );

  final matchedRuleIds = <String>{
    ...report.focuses.map((focus) => focus.ruleId),
    ...factRuleIds,
    ...conflictPolicyIds,
    report.verdict.matchedDecisionRowId,
    ...yingQiRuleIds,
  };
  final coverageTags = <String>{
    'population:${seed.population}',
    'source:${seed.sourceId}',
    'dun:${seed.dun.id}',
    'category:${seed.category.id}',
    'decision:${report.verdict.matchedDecisionRowId}',
    'trend:${report.verdict.judgment.trend.name}',
    if (report.verdict.conditionLinks.isNotEmpty) 'path:condition',
    if (report.conflicts.isNotEmpty) 'path:conflict',
    if (seed.sourcePanAssertions.isNotEmpty) 'path:source-pan-assertion',
    for (final ruleId in matchedRuleIds)
      'family:${QimenRuleCatalog.rule(ruleId).family.id}',
    for (final policyId in conflictPolicyIds) 'conflict:$policyId',
    for (final ruleId in yingQiRuleIds) 'yingQi:$ruleId',
    for (final ruleId in excludedYingQiRuleIds) 'yingQiExcluded:$ruleId',
    ...seed.coverageTags,
  }.toList(growable: false)
    ..sort();
  final source = QimenSourceCatalog.byId[seed.sourceId]!;
  final reportJson = report.toJson();

  return <String, dynamic>{
    'caseId': seed.caseId,
    'title': seed.title,
    'population': seed.population,
    'sourceNature': seed.sourceNature,
    'sourceId': seed.sourceId,
    'sourceCitation': source.toJson(),
    'sourceSection': seed.sourceSection,
    'accessedOn': source.accessedOn ?? _accessedOn,
    'sourceAssertion': seed.sourceAssertion,
    'manualAdjudication': seed.manualAdjudication,
    'syntheticPurpose': seed.syntheticPurpose,
    'representativePillars': <String, dynamic>{
      'used': seed.population == _Population.sourceBacked,
      'reason': seed.inputQualification,
      'yearGanZhi': calendar.yearGanZhi,
      'monthGanZhi': calendar.monthGanZhi,
      'dayGanZhi': seed.dayGanZhi,
      'hourGanZhi': seed.hourGanZhi,
    },
    'panFixtureId': seed.caseId,
    'panEngineCommit': _panCommit,
    'panSchemaVersion': QimenResult.currentSchemaVersion,
    'analysisSchemaVersion': QimenAnalysisReport.currentSchemaVersion,
    'ruleSetId': QimenRuleCatalog.ruleSetId,
    'ruleSetVersion': QimenRuleCatalog.v1,
    'questionCategory': seed.category.id,
    'ruleAssertions': <String, dynamic>{
      'requiredMatchedRuleIds': [...seed.requiredRuleIds]..sort(),
      'requiredNotMatchedRuleIds': [...seed.excludedRuleIds]..sort(),
      'requiredConflictPolicyIds': [...seed.requiredConflictPolicyIds]..sort(),
      'requiredDecisionRowId': seed.requiredDecisionRowId,
    },
    'sourcePanAssertions':
        seed.sourcePanAssertions.map((value) => value.toJson()).toList(),
    'expected': <String, dynamic>{
      'status': report.status.id,
      'focusRoleIds': report.focuses.map((focus) => focus.roleId).toList(),
      'focuses': report.focuses.map((value) => value.toJson()).toList(),
      'factRuleIds': factRuleIds,
      'factOccurrenceIds': factOccurrenceIds,
      'facts': report.facts.map((value) => value.toJson()).toList(),
      'conflictPolicyIds': conflictPolicyIds,
      'conflicts': report.conflicts.map((value) => value.toJson()).toList(),
      'decisionRowId': report.verdict.matchedDecisionRowId,
      'trend': report.verdict.judgment.trend.name,
      'verdict': report.verdict.toJson(),
      'conditions':
          report.verdict.conditionLinks.map((value) => value.toJson()).toList(),
      'yingQiRuleIds': yingQiRuleIds,
      'excludedYingQiRuleIds': excludedYingQiRuleIds,
      'yingQiCandidates':
          report.yingQiCandidates.map((value) => value.toJson()).toList(),
      'coverageTags': coverageTags,
      'reportSnapshotGzipBase64': base64Encode(
        gzip.encode(utf8.encode(jsonEncode(reportJson))),
      ),
    },
    'pan': panJson,
  };
}

void _validateSeedAssertions({
  required _GoldenSeed seed,
  required Map<String, dynamic> panJson,
  required List<String> factRuleIds,
  required List<String> conflictPolicyIds,
  required String decisionRowId,
}) {
  final missingRules = seed.requiredRuleIds
      .where((ruleId) => !factRuleIds.contains(ruleId))
      .toList(growable: false);
  final unexpectedRules =
      seed.excludedRuleIds.where(factRuleIds.contains).toList(growable: false);
  final missingPolicies = seed.requiredConflictPolicyIds
      .where((policyId) => !conflictPolicyIds.contains(policyId))
      .toList(growable: false);
  if (missingRules.isNotEmpty ||
      unexpectedRules.isNotEmpty ||
      missingPolicies.isNotEmpty ||
      (seed.requiredDecisionRowId != null &&
          seed.requiredDecisionRowId != decisionRowId)) {
    throw StateError(
      '${seed.caseId} assertion mismatch: missingRules=$missingRules, '
      'unexpectedRules=$unexpectedRules, missingPolicies=$missingPolicies, '
      'decision=$decisionRowId expected=${seed.requiredDecisionRowId}',
    );
  }

  final palaces = (panJson['palaces'] as List)
      .cast<Map<String, dynamic>>()
      .toList(growable: false);
  for (final assertion in seed.sourcePanAssertions) {
    final palace = palaces.singleWhere(
      (value) => value['number'] == assertion.palaceNumber,
    );
    for (final entry in assertion.expectedFields.entries) {
      if (palace[entry.key] != entry.value) {
        throw StateError(
          '${seed.caseId} source pan assertion failed at '
          'palace ${assertion.palaceNumber}.${entry.key}: '
          '${palace[entry.key]} != ${entry.value}',
        );
      }
    }
  }
}

void _printInspection(Map<String, dynamic> entry) {
  final expected = entry['expected'] as Map<String, dynamic>;
  stdout.writeln(
    '${entry['caseId']} population=${entry['population']} '
    'decision=${expected['decisionRowId']} trend=${expected['trend']} '
    'conflicts=${expected['conflictPolicyIds']} '
    'yingQi=${expected['yingQiRuleIds']}',
  );
}

abstract final class _Population {
  static const String sourceBacked = 'sourceBacked';
  static const String synthetic = 'synthetic';
}

class _SourcePanAssertion {
  const _SourcePanAssertion({
    required this.claim,
    required this.palaceNumber,
    required this.expectedFields,
  });

  final String claim;
  final int palaceNumber;
  final Map<String, Object?> expectedFields;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'claim': claim,
        'palaceNumber': palaceNumber,
        'expectedFields': expectedFields,
      };
}

class _GoldenSeed {
  const _GoldenSeed({
    required this.caseId,
    required this.title,
    required this.population,
    required this.sourceNature,
    required this.sourceId,
    required this.sourceSection,
    required this.sourceAssertion,
    required this.manualAdjudication,
    required this.inputQualification,
    required this.castTime,
    required this.solarTerm,
    required this.dun,
    required this.juNumber,
    required this.yuan,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.category,
    this.syntheticPurpose,
    this.requiredRuleIds = const <String>[],
    this.excludedRuleIds = const <String>[],
    this.requiredConflictPolicyIds = const <String>[],
    this.requiredDecisionRowId,
    this.sourcePanAssertions = const <_SourcePanAssertion>[],
    this.coverageTags = const <String>[],
  });

  final String caseId;
  final String title;
  final String population;
  final String sourceNature;
  final String sourceId;
  final String sourceSection;
  final String sourceAssertion;
  final String manualAdjudication;
  final String inputQualification;
  final String? syntheticPurpose;
  final DateTime castTime;
  final String solarTerm;
  final QimenDun dun;
  final int juNumber;
  final QimenYuan yuan;
  final String dayGanZhi;
  final String hourGanZhi;
  final QimenQuestionCategory category;
  final List<String> requiredRuleIds;
  final List<String> excludedRuleIds;
  final List<String> requiredConflictPolicyIds;
  final String? requiredDecisionRowId;
  final List<_SourcePanAssertion> sourcePanAssertions;
  final List<String> coverageTags;
}

final List<_GoldenSeed> _seeds = <_GoldenSeed>[
  _GoldenSeed(
    caseId: 'QM-G01',
    title: '《遁甲演义》阳遁一局甲子时',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・阳遁一局甲子时例',
    sourceAssertion: '九星、八门伏吟，以迟滞背景审慎观察。',
    manualAdjudication: '原例锁定甲子时、阳遁一局与星门伏吟。',
    inputQualification: '原例未载完整四柱；采用己丑日保持甲子时五鼠遁关系，'
        '年、月柱只补全 schema 1，不冒充历史事实。',
    castTime: DateTime.utc(2026, 12, 25, 4),
    solarTerm: '冬至',
    dun: QimenDun.yang,
    juNumber: 1,
    yuan: QimenYuan.upper,
    dayGanZhi: '己丑',
    hourGanZhi: '甲子',
    category: QimenQuestionCategory.general,
    requiredRuleIds: <String>[
      QimenRuleCatalog.starFuYin,
      QimenRuleCatalog.doorFuYin,
      QimenRuleCatalog.combinedFuYin,
    ],
    coverageTags: <String>['structure:fuYin'],
  ),
  _GoldenSeed(
    caseId: 'QM-G02',
    title: '《遁甲演义》大寒上元阳遁三局丙寅时',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・大寒上元阳遁三局丙寅时例',
    sourceAssertion: '庚加己，刑格。',
    manualAdjudication: '原例锁定甲己日丙寅时与庚加己刑格。',
    inputQualification: '甲己日取己丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 1, 25, 4),
    solarTerm: '大寒',
    dun: QimenDun.yang,
    juNumber: 3,
    yuan: QimenYuan.upper,
    dayGanZhi: '己丑',
    hourGanZhi: '丙寅',
    category: QimenQuestionCategory.litigation,
    requiredRuleIds: <String>[QimenRuleCatalog.punishmentPattern],
    coverageTags: <String>['formation:punishmentPattern'],
  ),
  _GoldenSeed(
    caseId: 'QM-G03',
    title: '《遁甲演义》小满上元阳遁五局戊戌时',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・小满上元阳遁五局戊戌时例',
    sourceAssertion: '丙加庚，荧入太白。',
    manualAdjudication: '原例锁定丙辛日戊戌时与丙加庚荧入太白。',
    inputQualification: '丙辛日取丙子日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 5, 25, 4),
    solarTerm: '小满',
    dun: QimenDun.yang,
    juNumber: 5,
    yuan: QimenYuan.upper,
    dayGanZhi: '丙子',
    hourGanZhi: '戊戌',
    category: QimenQuestionCategory.travel,
    requiredRuleIds: <String>[QimenRuleCatalog.fireEntersMetal],
    coverageTags: <String>['formation:fireEntersMetal'],
  ),
  _GoldenSeed(
    caseId: 'QM-G04',
    title: '《遁甲演义》清明上元阳遁四局壬申时',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・清明上元阳遁四局壬申时例',
    sourceAssertion: '庚加丙，太白入荧。',
    manualAdjudication: '原例锁定甲己日壬申时与庚加丙太白入荧。',
    inputQualification: '甲己日取己丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 4, 10, 4),
    solarTerm: '清明',
    dun: QimenDun.yang,
    juNumber: 4,
    yuan: QimenYuan.upper,
    dayGanZhi: '己丑',
    hourGanZhi: '壬申',
    category: QimenQuestionCategory.health,
    requiredRuleIds: <String>[QimenRuleCatalog.metalEntersFire],
    coverageTags: <String>['formation:metalEntersFire'],
  ),
  _GoldenSeed(
    caseId: 'QM-G05',
    title: '《遁甲演义》甲申日伏干的 schema-v1 边界',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExampleBoundary',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・小满上元阳遁五局甲申日壬申时例',
    sourceAssertion: '原文记庚临日干为伏干格。',
    manualAdjudication: 'schema 1 没有日旬遁仪，甲日不能从时旬首借位；'
        '本例因此锁定为伏干规则不命中的来源边界。',
    inputQualification: '原例完整给出甲申日壬申时；仅年、月柱为 schema 1 代表值。',
    castTime: DateTime.utc(2026, 5, 25, 4),
    solarTerm: '小满',
    dun: QimenDun.yang,
    juNumber: 5,
    yuan: QimenYuan.upper,
    dayGanZhi: '甲申',
    hourGanZhi: '壬申',
    category: QimenQuestionCategory.general,
    excludedRuleIds: <String>[QimenRuleCatalog.hiddenStemPattern],
    coverageTags: <String>['boundary:dayJia', 'nonMatch:hiddenStem'],
  ),
  _GoldenSeed(
    caseId: 'QM-G06',
    title: '《遁甲演义》甲日飞干的 schema-v1 边界',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExampleBoundary',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・小满上元阳遁五局庚午时例',
    sourceAssertion: '原文在甲己日庚午时例记日干临庚为飞干格。',
    manualAdjudication: '本 fixture 明确取甲日侧验证 schema-v1 边界：'
        '甲日无可定位日旬遁仪，不能借时旬首发出飞干事实。',
    inputQualification: '甲己日明确取甲子日作为边界输入；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 5, 25, 4),
    solarTerm: '小满',
    dun: QimenDun.yang,
    juNumber: 5,
    yuan: QimenYuan.upper,
    dayGanZhi: '甲子',
    hourGanZhi: '庚午',
    category: QimenQuestionCategory.relationship,
    excludedRuleIds: <String>[QimenRuleCatalog.flyingStemPattern],
    coverageTags: <String>['boundary:dayJia', 'nonMatch:flyingStem'],
  ),
  _GoldenSeed(
    caseId: 'QM-G07',
    title: '《遁甲演义》立春下元阳遁二局伏宫',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・立春下元阳遁二局壬申时例',
    sourceAssertion: '庚临值符，天乙伏宫格。',
    manualAdjudication: '原例锁定甲己日壬申时与庚临值符伏宫格。',
    inputQualification: '甲己日取己丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 2, 10, 4),
    solarTerm: '立春',
    dun: QimenDun.yang,
    juNumber: 2,
    yuan: QimenYuan.lower,
    dayGanZhi: '己丑',
    hourGanZhi: '壬申',
    category: QimenQuestionCategory.career,
    requiredRuleIds: <String>[QimenRuleCatalog.hiddenPalacePattern],
    coverageTags: <String>['formation:hiddenPalace'],
  ),
  _GoldenSeed(
    caseId: 'QM-G08',
    title: '《遁甲演义》春分中元阳遁九局飞宫',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・春分中元阳遁九局庚午时例',
    sourceAssertion: '值符临庚，天乙飞宫格。',
    manualAdjudication: '原例锁定甲己日庚午时与值符临庚飞宫格。',
    inputQualification: '甲己日取己丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 3, 25, 4),
    solarTerm: '春分',
    dun: QimenDun.yang,
    juNumber: 9,
    yuan: QimenYuan.middle,
    dayGanZhi: '己丑',
    hourGanZhi: '庚午',
    category: QimenQuestionCategory.study,
    requiredRuleIds: <String>[QimenRuleCatalog.flyingPalacePattern],
    coverageTags: <String>['formation:flyingPalace'],
  ),
  _GoldenSeed(
    caseId: 'QM-G09',
    title: '《遁甲演义》阴遁四局丙奇入墓',
    population: _Population.sourceBacked,
    sourceNature: 'classicalWorkedExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷二・阴遁四局庚寅时例',
    sourceAssertion: '丙奇临乾六，三奇入墓。',
    manualAdjudication: '原例锁定丙辛日庚寅时、阴遁四局与丙奇临乾入墓。',
    inputQualification: '原例未载节气与三元；采用夏至上元作代表坐标，'
        '丙子日补全日柱，不宣称历史日期。',
    castTime: DateTime.utc(2026, 6, 25, 4),
    solarTerm: '夏至',
    dun: QimenDun.yin,
    juNumber: 4,
    yuan: QimenYuan.upper,
    dayGanZhi: '丙子',
    hourGanZhi: '庚寅',
    category: QimenQuestionCategory.general,
    requiredRuleIds: <String>[QimenRuleCatalog.qiYiTomb],
    coverageTags: <String>['constraint:qiYiTomb'],
  ),
  _GoldenSeed(
    caseId: 'QM-G10',
    title: '《奇门遁甲元灵经》惊蛰中元占财',
    population: _Population.sourceBacked,
    sourceNature: 'publishedWorkedExample',
    sourceId: QimenSourceCatalog.yuanLingJing,
    sourceSection: '奇门遁甲元灵经・占财例（惊蛰中元阳遁七局）',
    sourceAssertion: '生门体克天蓬用，门囚且辛加壬，不作单一吉断。',
    manualAdjudication: '只锁定原例明载的生门、天蓬与辛加壬同宫事实，'
        '不把古例断语直接提升为程序综合结论。',
    inputQualification: '丁壬日取丁丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 3, 10, 4),
    solarTerm: '惊蛰',
    dun: QimenDun.yang,
    juNumber: 7,
    yuan: QimenYuan.middle,
    dayGanZhi: '丁丑',
    hourGanZhi: '壬寅',
    category: QimenQuestionCategory.wealth,
    requiredRuleIds: <String>['QMV1-F-STEM-XIN-REN'],
    sourcePanAssertions: <_SourcePanAssertion>[
      _SourcePanAssertion(
        claim: '坤二宫同见辛加壬、天蓬与生门。',
        palaceNumber: 2,
        expectedFields: <String, Object?>{
          'trigram': '坤',
          'heavenStem': '辛',
          'earthStem': '壬',
          'star': '天蓬',
          'door': '生门',
        },
      ),
    ],
    coverageTags: <String>['case:wealth', 'stemResponse:XIN-REN'],
  ),
  _GoldenSeed(
    caseId: 'QM-G11',
    title: '《奇门遁甲元灵经》立秋上元占财',
    population: _Population.sourceBacked,
    sourceNature: 'publishedWorkedExample',
    sourceId: QimenSourceCatalog.yuanLingJing,
    sourceSection: '奇门遁甲元灵经・占财例（立秋上元阴遁二局）',
    sourceAssertion: '时干、甲子戊与生门同兑内盘，原文记“得财必速”。',
    manualAdjudication: '核验兑七宫同宫事实，不把“得财必速”当作无条件保证。',
    inputQualification: '甲己日取己丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 8, 10, 4),
    solarTerm: '立秋',
    dun: QimenDun.yin,
    juNumber: 2,
    yuan: QimenYuan.upper,
    dayGanZhi: '己丑',
    hourGanZhi: '壬申',
    category: QimenQuestionCategory.wealth,
    sourcePanAssertions: <_SourcePanAssertion>[
      _SourcePanAssertion(
        claim: '兑七宫同见时干壬、甲子戊与生门。',
        palaceNumber: 7,
        expectedFields: <String, Object?>{
          'trigram': '兑',
          'earthStem': '壬',
          'heavenStem': '戊',
          'door': '生门',
        },
      ),
    ],
    coverageTags: <String>['case:wealthFastGain', 'palace:duiSeven'],
  ),
  _GoldenSeed(
    caseId: 'QM-G12',
    title: '《奇门遁甲元灵经》大寒中元占走失人口',
    population: _Population.sourceBacked,
    sourceNature: 'publishedWorkedExample',
    sourceId: QimenSourceCatalog.yuanLingJing,
    sourceSection: '奇门遁甲元灵经・占走失人口例（大寒中元阳遁九局）',
    sourceAssertion: '时干与六合都在内盘，坎宫潜藏，原文断不失。',
    manualAdjudication: '只核验坎一宫时干与六合同宫，不把“不失”转成评分或保证。',
    inputQualification: '乙庚日取乙丑日作为代表日柱；年、月柱只补全 schema 1。',
    castTime: DateTime.utc(2026, 1, 25, 4),
    solarTerm: '大寒',
    dun: QimenDun.yang,
    juNumber: 9,
    yuan: QimenYuan.middle,
    dayGanZhi: '乙丑',
    hourGanZhi: '庚辰',
    category: QimenQuestionCategory.travel,
    sourcePanAssertions: <_SourcePanAssertion>[
      _SourcePanAssertion(
        claim: '坎一宫同见时干壬与六合。',
        palaceNumber: 1,
        expectedFields: <String, Object?>{
          'trigram': '坎',
          'heavenStem': '壬',
          'deity': '六合',
        },
      ),
    ],
    coverageTags: <String>['case:missingPerson', 'palace:kanOne'],
  ),
  _GoldenSeed(
    caseId: 'QM-G16',
    title: '《奇门遁甲元灵经》大寒上元占升迁',
    population: _Population.sourceBacked,
    sourceNature: 'publishedWorkedExample',
    sourceId: QimenSourceCatalog.yuanLingJing,
    sourceSection: '奇门遁甲元灵经・占升迁例（大寒上元阳遁三局）',
    sourceAssertion: '开门在兑得相、奇合，太岁天辅来生，原文断“主升无疑”。',
    manualAdjudication: '锁定兑七宫开门与焦点有利收敛；但 matter 时干乙落巽四宫，'
        '命中持久化辰巳空亡，冻结首行优先命中 QMV1-D20。原文“主升无疑”'
        '不覆盖程序条件，也不改写为保证。',
    inputQualification: '原例给出六己年、丙申日乙未时；取2030年大寒前的己酉年'
        '作为六己年代表坐标，月柱只用于补全 schema 1。',
    castTime: DateTime.utc(2030, 1, 25, 4),
    solarTerm: '大寒',
    dun: QimenDun.yang,
    juNumber: 3,
    yuan: QimenYuan.upper,
    dayGanZhi: '丙申',
    hourGanZhi: '乙未',
    category: QimenQuestionCategory.career,
    requiredRuleIds: <String>[QimenRuleCatalog.favorableConvergence],
    requiredDecisionRowId: QimenRuleCatalog.decision20,
    sourcePanAssertions: <_SourcePanAssertion>[
      _SourcePanAssertion(
        claim: '兑七宫见开门。',
        palaceNumber: 7,
        expectedFields: <String, Object?>{
          'trigram': '兑',
          'door': '开门',
        },
      ),
    ],
    coverageTags: <String>['case:careerPromotion', 'palace:duiSeven'],
  ),
  _GoldenSeed(
    caseId: 'QM-G17',
    title: '《遁甲演义》青龙返首与三奇得使公式见证',
    population: _Population.sourceBacked,
    sourceNature: 'classicalRuleExample',
    sourceId: QimenSourceCatalog.dunJiaYanYi,
    sourceSection: '奇门遁甲演义卷一・青龙返首与三奇得使格',
    sourceAssertion: '戊加丙为青龙返首；乙加己、辛等固定仪对为三奇得使。',
    manualAdjudication: '来源锁定格局公式；完整盘与综合可成趋势分别由手工盘面复核和'
        'QMV1-D40 项目裁决锁定，不冒充古籍历史占例。',
    inputQualification: '来源段落只给格局公式，未给完整四柱；采用大寒上元阳遁三局、'
        '癸酉日辛酉时构造可复算 schema-1 公式见证。',
    castTime: DateTime.utc(2026, 1, 25, 4),
    solarTerm: '大寒',
    dun: QimenDun.yang,
    juNumber: 3,
    yuan: QimenYuan.upper,
    dayGanZhi: '癸酉',
    hourGanZhi: '辛酉',
    category: QimenQuestionCategory.general,
    requiredRuleIds: <String>[
      QimenRuleCatalog.dragonReturns,
      QimenRuleCatalog.threeWonderDuty,
      QimenRuleCatalog.favorableConvergence,
    ],
    requiredDecisionRowId: QimenRuleCatalog.decision40,
    sourcePanAssertions: <_SourcePanAssertion>[
      _SourcePanAssertion(
        claim: '坎一宫见天盘戊加地盘丙，命中青龙返首。',
        palaceNumber: 1,
        expectedFields: <String, Object?>{
          'trigram': '坎',
          'heavenStem': '戊',
          'earthStem': '丙',
        },
      ),
      _SourcePanAssertion(
        claim: '巽四宫见天盘乙加地盘己，命中三奇得使。',
        palaceNumber: 4,
        expectedFields: <String, Object?>{
          'trigram': '巽',
          'heavenStem': '乙',
          'earthStem': '己',
        },
      ),
    ],
    coverageTags: <String>['formation:dragonReturns', 'sourceTrend:keCheng'],
  ),
  _GoldenSeed(
    caseId: 'QM-S-D10',
    title: '章法合成例：五不遇时决定性阻断',
    population: _Population.synthetic,
    sourceNature: 'projectSyntheticCoverage',
    sourceId: QimenSourceCatalog.projectV1,
    sourceSection: '奇门分析 v1・QMV1-D10 决策行',
    sourceAssertion: '合成盘只用于固定决定性阻断首行命中。',
    manualAdjudication: '由离线搜索固定首个稳定 D10 见证，不宣称为古籍占例。',
    inputQualification: '全部四柱与局参数均为明确的合成测试输入。',
    syntheticPurpose: '覆盖 QMV1-D10 与难成趋势。',
    castTime: DateTime.utc(2026, 4, 10, 4),
    solarTerm: '清明',
    dun: QimenDun.yang,
    juNumber: 1,
    yuan: QimenYuan.upper,
    dayGanZhi: '丁卯',
    hourGanZhi: '癸卯',
    category: QimenQuestionCategory.general,
    requiredRuleIds: <String>[QimenRuleCatalog.fiveNotMeeting],
    requiredDecisionRowId: QimenRuleCatalog.decision10,
    coverageTags: <String>['synthetic:decisionD10'],
  ),
  _GoldenSeed(
    caseId: 'QM-S-X-FOCUS',
    title: '章法合成例：焦点特异性冲突优先',
    population: _Population.synthetic,
    sourceNature: 'projectSyntheticCoverage',
    sourceId: QimenSourceCatalog.projectV1,
    sourceSection: '奇门分析 v1・QMV1-X-FOCUS-SPECIFICITY 冲突路径',
    sourceAssertion: '合成盘只用于固定焦点事实优先于同宫背景事实的冲突路径。',
    manualAdjudication: '由离线搜索固定首个稳定焦点特异性见证，不宣称为古籍占例。',
    inputQualification: '全部四柱与局参数均为明确的合成测试输入。',
    syntheticPurpose: '覆盖 QMV1-X-FOCUS-SPECIFICITY 冲突路径。',
    castTime: DateTime.utc(2026, 4, 10, 4),
    solarTerm: '清明',
    dun: QimenDun.yang,
    juNumber: 1,
    yuan: QimenYuan.upper,
    dayGanZhi: '乙丑',
    hourGanZhi: '己卯',
    category: QimenQuestionCategory.health,
    requiredConflictPolicyIds: <String>[
      QimenRuleCatalog.conflictFocusSpecificity,
    ],
    coverageTags: <String>['synthetic:conflictFocusSpecificity'],
  ),
  _GoldenSeed(
    caseId: 'QM-S-D30',
    title: '章法合成例：健康问事不利收敛',
    population: _Population.synthetic,
    sourceNature: 'projectSyntheticCoverage',
    sourceId: QimenSourceCatalog.projectV1,
    sourceSection: '奇门分析 v1・QMV1-D30 决策行',
    sourceAssertion: '合成盘只用于固定类别不利收敛首行命中。',
    manualAdjudication: '由离线搜索固定首个稳定 D30 见证，不宣称为古籍占例。',
    inputQualification: '全部四柱与局参数均为明确的合成测试输入。',
    syntheticPurpose: '覆盖 QMV1-D30、健康类别与难成趋势。',
    castTime: DateTime.utc(2026, 4, 10, 4),
    solarTerm: '清明',
    dun: QimenDun.yang,
    juNumber: 1,
    yuan: QimenYuan.upper,
    dayGanZhi: '己巳',
    hourGanZhi: '己巳',
    category: QimenQuestionCategory.health,
    requiredRuleIds: <String>[QimenRuleCatalog.adverseConvergence],
    requiredDecisionRowId: QimenRuleCatalog.decision30,
    coverageTags: <String>['synthetic:decisionD30'],
  ),
  _GoldenSeed(
    caseId: 'QM-S-D40',
    title: '章法合成例：感情问事有利收敛',
    population: _Population.synthetic,
    sourceNature: 'projectSyntheticCoverage',
    sourceId: QimenSourceCatalog.projectV1,
    sourceSection: '奇门分析 v1・QMV1-D40 决策行',
    sourceAssertion: '合成盘只用于固定类别有利收敛首行命中。',
    manualAdjudication: '由离线搜索固定首个稳定 D40 见证，不宣称为古籍占例。',
    inputQualification: '全部四柱与局参数均为明确的合成测试输入。',
    syntheticPurpose: '覆盖 QMV1-D40、感情类别与可成趋势。',
    castTime: DateTime.utc(2026, 4, 10, 4),
    solarTerm: '清明',
    dun: QimenDun.yang,
    juNumber: 3,
    yuan: QimenYuan.upper,
    dayGanZhi: '己巳',
    hourGanZhi: '己巳',
    category: QimenQuestionCategory.relationship,
    requiredRuleIds: <String>[QimenRuleCatalog.favorableConvergence],
    requiredDecisionRowId: QimenRuleCatalog.decision40,
    coverageTags: <String>['synthetic:decisionD40'],
  ),
  _GoldenSeed(
    caseId: 'QM-S-D50',
    title: '章法合成例：决定性扶抑冲突未决',
    population: _Population.synthetic,
    sourceNature: 'projectSyntheticCoverage',
    sourceId: QimenSourceCatalog.projectV1,
    sourceSection: '奇门分析 v1・QMV1-D50 决策行',
    sourceAssertion: '合成盘只用于固定同层决定性冲突的保守裁决。',
    manualAdjudication: '由离线搜索固定首个稳定 D50 见证，不宣称为古籍占例。',
    inputQualification: '全部四柱与局参数均为明确的合成测试输入。',
    syntheticPurpose: '覆盖 QMV1-D50、未决冲突与趋势不明。',
    castTime: DateTime.utc(2026, 8, 10, 4),
    solarTerm: '立秋',
    dun: QimenDun.yin,
    juNumber: 4,
    yuan: QimenYuan.upper,
    dayGanZhi: '丁卯',
    hourGanZhi: '癸卯',
    category: QimenQuestionCategory.general,
    requiredRuleIds: <String>[
      QimenRuleCatalog.fiveNotMeeting,
      QimenRuleCatalog.favorableConvergence,
    ],
    requiredConflictPolicyIds: <String>[
      QimenRuleCatalog.conflictUnresolved,
    ],
    requiredDecisionRowId: QimenRuleCatalog.decision50,
    coverageTags: <String>['synthetic:decisionD50'],
  ),
];

Future<void> _searchSyntheticDecisionCases() async {
  const targets = <String>{
    QimenRuleCatalog.decision10,
    QimenRuleCatalog.decision30,
    QimenRuleCatalog.decision40,
    QimenRuleCatalog.decision50,
  };
  final found = <String>{};
  const conflictTargets = <String>{
    QimenRuleCatalog.conflictFocusSpecificity,
  };
  final foundConflicts = <String>{};
  const dayHours = <(String, String)>[
    ('乙丑', '己卯'),
    ('丙寅', '辛卯'),
    ('丁卯', '癸卯'),
    ('戊辰', '丙辰'),
    ('己巳', '己巳'),
    ('庚午', '壬午'),
    ('辛未', '乙未'),
    ('壬申', '戊申'),
    ('癸酉', '辛酉'),
  ];
  for (final dun in QimenDun.values) {
    for (var ju = 1; ju <= 9; ju++) {
      for (final yuan in QimenYuan.values) {
        for (final pair in dayHours) {
          for (final category in QimenQuestionCategory.values) {
            final seed = _GoldenSeed(
              caseId: 'SEARCH',
              title: 'search',
              population: _Population.synthetic,
              sourceNature: 'search',
              sourceId: QimenSourceCatalog.projectV1,
              sourceSection: 'search',
              sourceAssertion: 'search',
              manualAdjudication: 'search',
              inputQualification: 'search',
              syntheticPurpose: 'search',
              castTime: dun == QimenDun.yang
                  ? DateTime.utc(2026, 4, 10, 4)
                  : DateTime.utc(2026, 8, 10, 4),
              solarTerm: dun == QimenDun.yang ? '清明' : '立秋',
              dun: dun,
              juNumber: ju,
              yuan: yuan,
              dayGanZhi: pair.$1,
              hourGanZhi: pair.$2,
              category: category,
            );
            final generated = await _generate(seed);
            final expected = generated['expected'] as Map<String, dynamic>;
            final row = expected['decisionRowId'] as String;
            if (targets.contains(row) && found.add(row)) {
              stdout.writeln(
                'FOUND $row dun=${dun.id} ju=$ju yuan=${yuan.id} '
                'day=${pair.$1} hour=${pair.$2} category=${category.id} '
                'trend=${expected['trend']} facts=${expected['factRuleIds']}',
              );
            }
            final conflictPolicyIds =
                (expected['conflictPolicyIds'] as List).cast<String>();
            for (final policyId in conflictPolicyIds) {
              if (conflictTargets.contains(policyId) &&
                  foundConflicts.add(policyId)) {
                stdout.writeln(
                  'FOUND CONFLICT $policyId dun=${dun.id} ju=$ju '
                  'yuan=${yuan.id} day=${pair.$1} hour=${pair.$2} '
                  'category=${category.id} decision=$row',
                );
              }
            }
            if (found.containsAll(targets) &&
                foundConflicts.containsAll(conflictTargets)) {
              return;
            }
          }
        }
      }
    }
  }
  stdout.writeln('Missing synthetic rows: ${targets.difference(found)}');
  stdout.writeln(
    'Missing synthetic conflicts: '
    '${conflictTargets.difference(foundConflicts)}',
  );
}
