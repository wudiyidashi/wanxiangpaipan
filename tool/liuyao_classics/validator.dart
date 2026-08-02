import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:wanxiang_paipan/domain/services/fushen_service.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_report.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_trace.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

import 'fixture_models.dart';

enum LiuYaoClassicsValidationMode { full, evaluationDraft }

class LiuYaoClassicsValidationResult {
  const LiuYaoClassicsValidationResult({
    required this.errors,
    required this.caseCount,
    required this.originalBookCount,
    required this.ruleValidationCount,
    required this.holdoutCount,
    required this.cohortHash,
  });

  final List<String> errors;
  final int caseCount;
  final int originalBookCount;
  final int ruleValidationCount;
  final int holdoutCount;
  final String cohortHash;

  bool get isValid => errors.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'status': isValid ? 'valid' : 'invalid',
        'caseCount': caseCount,
        'originalBookCount': originalBookCount,
        'ruleValidationCount': ruleValidationCount,
        'holdoutCount': holdoutCount,
        'cohortHash': cohortHash,
        'errors': errors,
      };
}

class LiuYaoClassicsValidator {
  const LiuYaoClassicsValidator();

  static const String holdoutSalt = 'liuyao-holdout-v1-2026-08-01';

  LiuYaoClassicsValidationResult validate(
    LiuYaoClassicsFixture fixture, {
    LiuYaoClassicsValidationMode mode = LiuYaoClassicsValidationMode.full,
  }) {
    final errors = <String>[...LiuYaoRuleCatalog.validate()];
    if (fixture.fixtureVersion != 'liuyao-classics/1.0.0') {
      errors.add('Unexpected fixtureVersion: ${fixture.fixtureVersion}');
    }
    if (fixture.sourceCatalogVersion !=
        LiuYaoRuleCatalog.sourceCatalogVersion) {
      errors.add('Fixture source catalog version mismatch.');
    }
    if (fixture.ruleSetId != LiuYaoRuleCatalog.ruleSetId ||
        fixture.ruleSetVersion != LiuYaoRuleCatalog.v2) {
      errors.add('Fixture rule-set identity mismatch.');
    }
    if (fixture.holdoutSalt != holdoutSalt) {
      errors.add('Holdout salt does not match the frozen literal.');
    }

    final originals = fixture.cases
        .where((testCase) => testCase.caseKind == 'originalBook')
        .toList();
    final validations = fixture.cases
        .where((testCase) => testCase.caseKind == 'ruleValidation')
        .toList();
    final holdouts = fixture.cases
        .where((testCase) => testCase.evaluationSplit == 'holdout')
        .toList();
    if (fixture.cases.length != 40) {
      errors.add('Fixture must contain 40 cases.');
    }
    if (originals.length != 26) {
      errors.add('Fixture must contain 26 original-book cases.');
    }
    if (validations.length != 14) {
      errors.add('Fixture must contain 14 rule-validation cases.');
    }
    if (fixture.holdoutSize != 6 || holdouts.length != 6) {
      errors.add('Fixture must contain exactly six holdout cases.');
    }
    if (validations
        .any((testCase) => testCase.evaluationSplit != 'calibration')) {
      errors.add('Every rule-validation case must be calibration.');
    }
    if (holdouts.any((testCase) => testCase.caseKind != 'originalBook')) {
      errors.add('Every holdout case must be an original-book case.');
    }

    final ranked = <({LiuYaoClassicsCase testCase, String hash})>[
      for (final testCase in originals)
        (
          testCase: testCase,
          hash: sha256
              .convert(utf8.encode(
                '${fixture.holdoutSalt}\n${testCase.caseId}',
              ))
              .toString(),
        ),
    ]..sort((left, right) {
        final byHash = left.hash.compareTo(right.hash);
        return byHash != 0
            ? byHash
            : left.testCase.caseId.compareTo(right.testCase.caseId);
      });
    final expectedHoldout = ranked.take(fixture.holdoutSize).toList();
    final expectedHoldoutIds =
        expectedHoldout.map((member) => member.testCase.caseId).toSet();
    final actualHoldoutIds =
        holdouts.map((testCase) => testCase.caseId).toSet();
    if (expectedHoldoutIds.length != actualHoldoutIds.length ||
        !expectedHoldoutIds.containsAll(actualHoldoutIds)) {
      errors.add('Holdout split does not match deterministic hash ranking.');
    }
    final cohortMembers = <Object?>[
      for (final member in expectedHoldout)
        <String, Object?>{
          'caseId': member.testCase.caseId,
          'selectionHash': member.hash,
        },
    ];
    if (fixture.holdoutMembers.length != cohortMembers.length) {
      errors.add('Holdout member count mismatch.');
    } else {
      for (var index = 0; index < cohortMembers.length; index++) {
        final expected = expectedHoldout[index];
        final declared = fixture.holdoutMembers[index];
        if (declared.caseId != expected.testCase.caseId ||
            declared.selectionHash != expected.hash) {
          errors.add('Holdout member mismatch at index $index.');
        }
      }
    }
    final cohortHash =
        sha256.convert(utf8.encode(jsonEncode(cohortMembers))).toString();
    if (fixture.holdoutCohortHash != cohortHash) {
      errors.add('Holdout cohort hash mismatch.');
    }

    final caseIds = <String>{};
    for (final testCase in fixture.cases) {
      final prefix = testCase.caseId;
      void error(String message) => errors.add('$prefix: $message');
      final bool withheld = testCase.evaluationReferenceWithheld;
      if (!caseIds.add(testCase.caseId)) error('duplicate caseId');
      if (!RegExp(r'^liuyao\.case\.golden\.\d{3}$').hasMatch(testCase.caseId)) {
        error('invalid caseId namespace');
      }
      if (!const <String>{'originalBook', 'ruleValidation'}
          .contains(testCase.caseKind)) {
        error('invalid caseKind');
      }
      if (!const <String>{'calibration', 'holdout'}
          .contains(testCase.evaluationSplit)) {
        error('invalid evaluationSplit');
      }
      if (mode == LiuYaoClassicsValidationMode.evaluationDraft) {
        if (testCase.evaluationSplit == 'holdout' && !withheld) {
          error('draft holdout evaluation reference was not withheld');
        }
        if (testCase.evaluationSplit != 'holdout' && withheld) {
          error('draft withheld a calibration evaluation reference');
        }
      } else if (withheld) {
        error('full validation cannot use a withheld evaluation reference');
      }
      if (testCase.reviewStatus != 'reviewed') {
        error('case is not reviewed');
      }
      if (testCase.unknowns.any((value) => value.trim().isEmpty)) {
        error('unknowns contains an empty entry');
      }
      if (testCase.coverage.isEmpty) error('coverage is empty');
      if (_containsAbsolutePath(testCase.reference.chapter) ||
          _containsAbsolutePath(testCase.reference.printedPages)) {
        error('reference leaks an absolute path');
      }

      for (final sourceRef in testCase.sourceRefs) {
        if (!LiuYaoRuleCatalog.sourceById.containsKey(sourceRef.sourceId)) {
          error('unknown sourceId ${sourceRef.sourceId}');
        }
        if (_containsAbsolutePath(sourceRef.locator)) {
          error('source locator leaks an absolute path');
        }
        final allowedKind = switch (sourceRef.evidenceLevel) {
          'a' => const <String>{'exactQuote', 'paraphrase'},
          'b' => const <String>{'paraphrase'},
          'c' => const <String>{'locatorOnly'},
          'd' => const <String>{'projectConvention'},
          _ => const <String>{},
        };
        if (!allowedKind.contains(sourceRef.referenceKind)) {
          error('illegal evidence/reference pair for ${sourceRef.sourceId}');
        }
      }
      for (final ruleId in <String>{
        ...testCase.ruleIds,
        if (!withheld) ...testCase.expected.conditionRuleIds,
        if (!withheld) ...testCase.expected.absentConditionRuleIds,
        if (!withheld) ...testCase.expected.factorRuleIds,
        if (!withheld && testCase.expected.decisionRowId.isNotEmpty)
          testCase.expected.decisionRowId,
      }) {
        if (!LiuYaoRuleCatalog.ruleById.containsKey(ruleId)) {
          error('unknown ruleId $ruleId');
        }
      }

      final gua = _guard(prefix, error,
          () => GuaCalculator.calculateGua(testCase.pan.numbers));
      if (gua == null) continue;
      if (gua.name != testCase.pan.declaredMainGuaName) {
        error(
            'main gua mismatch: ${testCase.pan.declaredMainGuaName} != ${gua.name}');
      }
      final movingPositions =
          gua.movingYaos.map((yao) => yao.position).toList();
      if (!_sameList(movingPositions, testCase.pan.declaredMovingPositions)) {
        error('moving positions mismatch');
      }
      final changing = GuaCalculator.generateChangingGua(gua);
      if (changing?.name != testCase.pan.declaredChangingGuaName) {
        error('changing gua mismatch');
      }
      if (testCase.useSpirit.position < 1 || testCase.useSpirit.position > 6) {
        error('use-spirit position is out of range');
        continue;
      }
      final hidden = testCase.useSpirit.mode == 'selectedHidden';
      if (!hidden && testCase.useSpirit.mode != 'selectedVisible') {
        error('invalid use-spirit mode');
        continue;
      }
      final selected = hidden
          ? FuShenService.calculateFuShen(gua)[testCase.useSpirit.position]?.yao
          : gua.yaos[testCase.useSpirit.position - 1];
      if (selected == null) {
        error('declared hidden use spirit does not exist');
        continue;
      }
      final actorId = hidden
          ? 'hidden:host-yao:${testCase.useSpirit.position}'
          : 'main:yao:${testCase.useSpirit.position}';
      if (testCase.useSpirit.declaredActorId != actorId ||
          testCase.useSpirit.declaredLiuQin != selected.liuQin.name ||
          testCase.useSpirit.declaredBranch != selected.branch ||
          testCase.useSpirit.declaredWuXing != selected.wuXing.name) {
        error('selected actor metadata mismatch');
      }

      final lunar = _lunar(
        testCase.pan.monthBranch,
        testCase.pan.dayGanZhi,
        excludedYearBranches: <String>{
          ...gua.yaos.map((yao) => yao.branch),
          selected.branch,
        },
      );
      final report = _guard(
        prefix,
        error,
        () => LiuYaoAnalyzer.analyze(
          gua,
          changing,
          lunar,
          yongShenPosition: testCase.useSpirit.position,
          yongShenIsFuShen: hidden,
          ruleSetVersion: fixture.ruleSetVersion,
        ),
      );
      if (report == null) continue;
      if (report.status != LiuYaoAnalysisStatus.success) {
        error('runtime analysis is not successful');
        continue;
      }
      if (<YaoAnalysisTag>[
        ...report.yaoTags.values.expand((tags) => tags),
        ...report.guaTags,
        ...report.yongShenTags,
      ].any((tag) => tag.ruleId == LiuYaoRuleIds.yearCommand)) {
        error('unknown source year introduced synthetic year evidence');
      }
      final judgment = report.judgment;
      if (judgment == null) {
        error('runtime judgment is missing');
        continue;
      }
      final conditionRuleIds = judgment.conditions
          .map((condition) => condition.conditionRuleId)
          .toSet();
      final factorRuleIds =
          judgment.factors.map((factor) => factor.ruleId).toSet();
      if (!withheld) {
        if (judgment.trend.code != testCase.expected.trend) {
          error(
              'trend mismatch: ${testCase.expected.trend} != ${judgment.trend.code}');
        }
        if (judgment.nuance != testCase.expected.nuance) {
          error(
              'nuance mismatch: ${testCase.expected.nuance} != ${judgment.nuance}');
        }
        if (!_sameSet(
          conditionRuleIds,
          testCase.expected.conditionRuleIds.toSet(),
        )) {
          error('condition rule IDs do not match exactly');
        }
        if (conditionRuleIds
            .intersection(testCase.expected.absentConditionRuleIds.toSet())
            .isNotEmpty) {
          error('an absent condition rule is present');
        }
        if (!_sameSet(factorRuleIds, testCase.expected.factorRuleIds.toSet())) {
          error('factor rule IDs do not match exactly');
        }
        final timingBranches = (report.yingQi ?? const [])
            .map((candidate) => candidate.branch)
            .toSet();
        if (!_sameSet(
          timingBranches,
          testCase.expected.timingBranches.toSet(),
        )) {
          error('timing branches do not match exactly');
        }
        if (judgment.conditions.any((condition) => !condition.hasRescue) !=
            testCase.expected.hasUnrescuedCondition) {
          error('unrescued-condition expectation mismatch');
        }
        if (testCase.expected.decisionRowId.isEmpty ||
            judgment.matchedDecisionRowId != testCase.expected.decisionRowId) {
          error('decision row identity mismatch');
        }
        _expectExactIds(
          prefix,
          'factor',
          testCase.expected.factorIds,
          judgment.factors.map((factor) => factor.factorId),
          error,
        );
        _expectExactIds(
          prefix,
          'condition',
          testCase.expected.conditionIds,
          judgment.conditions.map((condition) => condition.conditionId),
          error,
        );
        _expectExactIds(
          prefix,
          'timing',
          testCase.expected.timingIds,
          (report.yingQi ?? const []).map((candidate) => candidate.timingId),
          error,
        );
      }
      if (!_sameList(report.analysisStages, LiuYaoAnalysisStages.ordered) ||
          !_sameList(
            report.trace.map((step) => step.stageId).toList(),
            LiuYaoAnalysisStages.ordered,
          )) {
        error('analysis stage order/trace coverage mismatch');
      }
      final conditionIds =
          judgment.conditions.map((condition) => condition.conditionId).toSet();
      for (final candidate in report.yingQi ?? const <YingQiCandidate>[]) {
        if (!conditionIds.containsAll(candidate.upstreamConditionIds)) {
          error('timing candidate has orphan upstream condition IDs');
        }
      }
      for (final condition in judgment.conditions.where(
        (condition) => !condition.hasRescue,
      )) {
        if ((report.yingQi ?? const <YingQiCandidate>[]).any((candidate) =>
            candidate.upstreamConditionIds.contains(condition.conditionId))) {
          error('non-rescuable condition generated timing');
        }
      }
      if (!withheld) {
        final runtimeRuleIds = <String>{
          ...factorRuleIds,
          ...conditionRuleIds,
          ...testCase.expected.absentConditionRuleIds,
          for (final candidate in report.yingQi ?? const <YingQiCandidate>[])
            ...<String>[
              candidate.timingRuleId,
              ...candidate.upstreamRuleIds,
            ].where((ruleId) => ruleId.isNotEmpty),
        };
        if (!_sameSet(runtimeRuleIds, testCase.ruleIds.toSet())) {
          error('case ruleIds do not match the runtime evidence closure');
        }
      }
      final declaredSourceIds =
          testCase.sourceRefs.map((sourceRef) => sourceRef.sourceId).toSet();
      if (!declaredSourceIds.containsAll(report.usedSourceIds)) {
        error('case sourceRefs do not cover the runtime source closure');
      }
    }

    return LiuYaoClassicsValidationResult(
      errors: errors,
      caseCount: fixture.cases.length,
      originalBookCount: originals.length,
      ruleValidationCount: validations.length,
      holdoutCount: holdouts.length,
      cohortHash: cohortHash,
    );
  }

  static T? _guard<T>(
    String caseId,
    void Function(String message) error,
    T Function() action,
  ) {
    try {
      return action();
    } catch (exception) {
      error('validation threw ${exception.runtimeType}');
      return null;
    }
  }

  static LunarInfo _lunar(
    String monthBranch,
    String dayGanZhi, {
    required Set<String> excludedYearBranches,
  }) {
    final split = TianGanDiZhiService.splitGanZhi(dayGanZhi)!;
    const ganZhiByBranch = <String, String>{
      '子': '甲子',
      '丑': '乙丑',
      '寅': '丙寅',
      '卯': '丁卯',
      '辰': '戊辰',
      '巳': '己巳',
      '午': '庚午',
      '未': '辛未',
      '申': '壬申',
      '酉': '癸酉',
      '戌': '甲戌',
      '亥': '乙亥',
    };
    final String yearGanZhi = ganZhiByBranch.entries
        .firstWhere((entry) => !excludedYearBranches.contains(entry.key))
        .value;
    return LunarInfo(
      yueJian: monthBranch,
      riGan: split.first,
      riZhi: split.last,
      riGanZhi: dayGanZhi,
      kongWang: TianGanDiZhiService.getKongWang(dayGanZhi),
      yearGanZhi: yearGanZhi,
      monthGanZhi: ganZhiByBranch[monthBranch]!,
    );
  }

  static void _expectExactIds(
    String caseId,
    String kind,
    List<String> expected,
    Iterable<String> actual,
    void Function(String message) error,
  ) {
    final expectedSorted = expected.toSet().toList()..sort();
    final actualSorted = actual.toSet().toList()..sort();
    if (!_sameList(expectedSorted, actualSorted)) {
      error('$kind runtime IDs are missing or stale');
    }
    final prefix = switch (kind) {
      'factor' => 'lyf-',
      'condition' => 'lyc-',
      _ => 'lyt-',
    };
    if (actualSorted.any((id) => !id.startsWith(prefix))) {
      error('$kind runtime ID has an invalid namespace');
    }
  }

  static bool _sameList<T>(List<T> left, List<T> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool _sameSet<T>(Set<T> left, Set<T> right) =>
      left.length == right.length && left.containsAll(right);

  static bool _containsAbsolutePath(String value) =>
      RegExp(r'(^|\s)[A-Za-z]:[\\/]').hasMatch(value) ||
      value.startsWith('/Users/') ||
      value.startsWith('/home/');
}
