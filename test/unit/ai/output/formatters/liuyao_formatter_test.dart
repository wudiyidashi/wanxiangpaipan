import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/liuyao_analysis_projection.dart';

import '../../../services/liuyao/analysis/helpers/analysis_fixtures.dart';

const _liuShen = <String>['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'];

LiuYaoResult _buildResult(
  List<int> numbers, {
  int? yongShenPosition,
  bool yongShenIsFuShen = false,
  LiuYaoCalendarInputMode calendarInputMode =
      LiuYaoCalendarInputMode.legacyUnknown,
}) {
  final mainGua = buildGua(numbers);
  return LiuYaoResult(
    id: 'formatter-fixture',
    castTime: DateTime(2026, 7, 1, 1, 30),
    castMethod: CastMethod.manual,
    mainGua: mainGua,
    changingGua: buildChangingGua(mainGua),
    lunarInfo: buildLunar(yueJian: '午', riGanZhi: '甲子').copyWith(
      hourGanZhi: '乙丑',
    ),
    liuShen: _liuShen,
    calendarInputMode: calendarInputMode,
    yongShenPosition: yongShenPosition,
    yongShenIsFuShen: yongShenIsFuShen,
  );
}

Map<String, dynamic> _projectionOf(StructuredDivinationOutput output) {
  final section = output.sections.singleWhere((item) => item.key == 'analysis');
  return Map<String, dynamic>.from(
    section.metadata!['projection'] as Map,
  );
}

Map<String, dynamic> _aiProjectionOf(StructuredDivinationOutput output) {
  final section = output.sections.singleWhere((item) => item.key == 'analysis');
  return Map<String, dynamic>.from(
    section.metadata!['aiProjection'] as Map,
  );
}

void main() {
  test('动爻输出应读取变卦对应爻的完整纳甲', () async {
    final result = await LiuYaoSystem().cast(
      method: CastMethod.time,
      input: const <String, dynamic>{},
      castTime: DateTime(2026, 4, 24, 5, 30),
    ) as LiuYaoResult;
    final formatter = LiuYaoStructuredFormatter();

    final rendered = formatter.render(formatter.format(result));

    expect(
      rendered,
      contains('四爻动: 子孙丁亥(水) → 兄弟戊申(金)'),
    );
    expect(rendered, isNot(contains('子孙丁亥(水) → 亥')));
  });

  test('显用神投影完整输出裁决、条件、应期、来源与固定版本', () {
    final formatter = LiuYaoStructuredFormatter();
    final output = formatter.format(
      _buildResult(
        const <int>[7, 7, 7, 7, 7, 7],
        yongShenPosition: 6,
      ),
      question: '所求能否落实？',
    );
    final projection = _projectionOf(output);
    final aiProjection = _aiProjectionOf(output);
    final analysis = output.sections.singleWhere(
      (section) => section.key == 'analysis',
    );
    final readable =
        analysis.content.split('[LIUYAO_CANONICAL_PROJECTION]').first;

    expect(output.temporal.hourGanZhi, '乙丑');
    expect(output.coreData['hasChangingGua'], isFalse);
    expect(
        output.analysisContract?.analysisSchemaVersion, isNot('legacyUnknown'));
    expect(output.analysisContract?.projectionSchemaVersion, '2');
    expect(output.analysisContract?.ruleSetId, 'liuyao-zengshan-primary');
    expect(output.analysisContract?.ruleSetVersion, 'v3');
    expect(
      projection.keys,
      orderedEquals(LiuYaoAnalysisProjection.schema2TopLevelKeys),
    );
    expect(projection['analysisStages'], isNotEmpty);
    expect(projection['policy'], containsPair('calculationOwner', 'program'));
    expect(projection['policy'], containsPair('mayOverrideVerdict', false));
    expect(projection['useSpirit'], containsPair('mode', 'selectedVisible'));
    expect(projection['selectedUseSpiritFacts'], isNotEmpty);
    expect(projection['roles'], isNotEmpty);
    expect(projection['factors'], isNotEmpty);
    expect(projection['conditions'], isNotEmpty);
    expect(projection['timingCandidates'], isNotEmpty);
    expect(projection['sources'], isNotEmpty);
    final fullVerdict = Map<String, dynamic>.from(projection['verdict'] as Map);
    final compactVerdict =
        Map<String, dynamic>.from(aiProjection['verdict'] as Map);
    final timingSummary = fullVerdict['summary'] as String;
    expect(compactVerdict['summary'], timingSummary);
    expect(timingSummary, contains('应期候选'));
    expect(timingSummary, contains('触发窗口'));
    expect(timingSummary, contains('优先观察'));
    expect(analysis.content.split(timingSummary), hasLength(2));
    expect(aiProjection['aiProjectionSchemaVersion'], 1);
    expect(aiProjection['projectionSchemaVersion'], 2);
    expect(aiProjection['projectionView'], 'aiCompact');
    expect(aiProjection, isNot(contains('actorAvailability')));
    expect(
      aiProjection['selectedUseSpiritFacts'],
      contains('selectedFactOccurrenceIds'),
    );
    expect(aiProjection, isNot(contains('analysisStages')));
    expect(aiProjection, isNot(contains('trace')));
    expect(
      aiProjection['actorFacts'],
      hasLength((projection['actorFacts'] as List<dynamic>).length),
    );
    final compactActorTag = (((aiProjection['actorFacts'] as List<dynamic>)
            .first as Map<String, dynamic>)['tags'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .first;
    expect(compactActorTag, contains('priority'));
    expect(compactActorTag, contains('relatedYao'));
    final compactUseSpirit =
        (aiProjection['useSpiritOccurrences'] as List<dynamic>).first as Map;
    expect(compactUseSpirit, contains('tagOccurrenceIds'));
    expect(compactUseSpirit, contains('phaseContributionOccurrenceIds'));
    expect(compactUseSpirit, isNot(contains('tags')));
    expect(compactUseSpirit, isNot(contains('phaseContributions')));
    final compactSource = (aiProjection['sources'] as List<dynamic>).first
        as Map<String, dynamic>;
    expect(compactSource, contains('adjudication'));
    final compactReference = (compactSource['references'] as List<dynamic>)
        .first as Map<String, dynamic>;
    expect(compactReference, contains('adoptionNote'));

    expect(readable, contains('投影统计:'));
    expect(readable, contains('canonical JSON'));
    final compactJson = jsonEncode(aiProjection);
    for (final factor in projection['factors'] as List<dynamic>) {
      expect(
          compactJson, contains((factor as Map<String, dynamic>)['factorId']));
    }
    for (final condition in projection['conditions'] as List<dynamic>) {
      expect(
        compactJson,
        contains((condition as Map<String, dynamic>)['conditionId']),
      );
    }
    for (final timing in projection['timingCandidates'] as List<dynamic>) {
      final item = timing as Map<String, dynamic>;
      expect(compactJson, contains(item['timingId']));
      expect(item['upstreamConditionIds'], isNotEmpty);
    }
    for (final source in projection['sources'] as List<dynamic>) {
      final item = source as Map<String, dynamic>;
      expect(readable, contains(item['sourceId']));
      expect(
          item['publicLocator'], isNot(matches(r'^(?:[A-Za-z]:[\\/]|/|\\\\)')));
      for (final reference in item['references'] as List<dynamic>) {
        final ref = reference as Map<String, dynamic>;
        if (ref['referenceKind'] != 'exactQuote') {
          expect(ref, isNot(contains('quote')));
        }
      }
    }

    final canonicalMatch = RegExp(
      r'\[LIUYAO_CANONICAL_PROJECTION\]\n(.*)\n\[/LIUYAO_CANONICAL_PROJECTION\]',
      dotAll: true,
    ).firstMatch(analysis.content);
    expect(canonicalMatch, isNotNull);
    expect(jsonDecode(canonicalMatch!.group(1)!), aiProjection);
  });

  test('伏神取用保留 hidden actor 与伏神自身事实', () {
    final formatter = LiuYaoStructuredFormatter();
    final output = formatter.format(
      _buildResult(
        const <int>[8, 8, 7, 7, 7, 7],
        yongShenPosition: 2,
        yongShenIsFuShen: true,
      ),
    );
    final projection = _projectionOf(output);
    final aiProjection = _aiProjectionOf(output);
    final useSpirit = Map<String, dynamic>.from(projection['useSpirit'] as Map);
    final roles = projection['roles'] as List<dynamic>;

    expect(useSpirit['mode'], 'selectedHidden');
    expect(useSpirit['selectedActorId'], 'hidden:host-yao:2');
    expect(
      roles.any((value) {
        final role = Map<String, dynamic>.from(value as Map);
        final actor = Map<String, dynamic>.from(role['actor'] as Map);
        return role['selected'] == true &&
            actor['actorId'] == 'hidden:host-yao:2';
      }),
      isTrue,
    );
    expect(projection['selectedUseSpiritFacts'], isNotEmpty);
    final compactSelectedFacts = Map<String, dynamic>.from(
      aiProjection['selectedUseSpiritFacts'] as Map,
    );
    final supplementalFacts =
        (compactSelectedFacts['factsNotPresentElsewhere'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    expect(
      supplementalFacts.map((fact) => fact['ruleId']),
      contains('liuyao.rule.liuqin.selected-hidden-use-spirit'),
    );
    _expectCompactOccurrenceClosure(aiProjection);
    expect(
      output.sections.singleWhere((item) => item.key == 'analysis').content,
      contains('伏神取用'),
    );
  });

  test('AI 紧凑投影与完整 metadata 隔离、输出确定且不含事后参考', () async {
    final result = await LiuYaoSystem().castByManualYaoNumbers(
      const <int>[8, 8, 6, 7, 8, 6],
      castTime: DateTime(2026, 2, 28, 8),
    );
    final selected = result.copyWith(yongShenPosition: 1);
    final formatter = LiuYaoStructuredFormatter();
    final first = formatter.format(selected, question: '租房是否顺利');
    final second = formatter.format(selected, question: '租房是否顺利');
    final fullProjection = _projectionOf(first);
    final compactProjection = _aiProjectionOf(first);

    expect(
      fullProjection.keys,
      orderedEquals(LiuYaoAnalysisProjection.schema2TopLevelKeys),
    );
    expect(
      jsonEncode(compactProjection),
      jsonEncode(_aiProjectionOf(second)),
    );
    expect(compactProjection['policy'], fullProjection['policy']);
    final fullVerdict =
        Map<String, dynamic>.from(fullProjection['verdict'] as Map);
    final compactVerdict =
        Map<String, dynamic>.from(compactProjection['verdict'] as Map);
    final fullSummary = fullVerdict.remove('summary') as String;
    expect(fullSummary, contains('应期候选'));
    expect(fullSummary, contains('触发窗口'));
    expect(compactVerdict, fullVerdict);
    expect(compactVerdict, isNot(contains('summary')));
    expect(
      compactProjection['lifecycleVerdict'],
      fullProjection['lifecycleVerdict'],
    );
    expect(
      jsonEncode(compactProjection).length,
      lessThan(jsonEncode(fullProjection).length),
    );
    final compactSelectedFacts = Map<String, dynamic>.from(
      compactProjection['selectedUseSpiritFacts'] as Map,
    );
    expect(compactSelectedFacts['selectedFactOccurrenceIds'], isNotEmpty);
    final supplementalFacts =
        (compactSelectedFacts['factsNotPresentElsewhere'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    expect(
      supplementalFacts.map((fact) => fact['ruleId']),
      orderedEquals(<String>[
        'liuyao.rule.fushen.flight-overcomes-hidden',
      ]),
    );
    final compactEffect =
        (compactProjection['directedEffects'] as List<dynamic>).first
            as Map<String, dynamic>;
    expect(compactEffect, contains('pathStep'));
    final compactWithoutSources = Map<String, dynamic>.from(compactProjection)
      ..remove('sources');
    final compactBodyJson = jsonEncode(compactWithoutSources);
    final fullReferenceCount = (fullProjection['sources'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .fold<int>(
          0,
          (sum, source) => sum + (source['references'] as List<dynamic>).length,
        );
    final compactReferences = (compactProjection['sources'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .expand((source) => source['references'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
    final compactReferenceRuleIds =
        compactReferences.map((reference) => reference['ruleId']).toSet();
    expect(compactReferences.length, lessThan(fullReferenceCount));
    for (final reference in compactReferences) {
      expect(compactBodyJson, contains(reference['ruleId']));
      expect(reference, contains('adoptionNote'));
    }
    expect(compactBodyJson, contains('liuyao.rule.special.year-command'));
    expect(
      compactReferenceRuleIds,
      isNot(contains('liuyao.rule.special.year-command')),
    );
    expect(
      compactReferenceRuleIds,
      contains('liuyao.rule.mujue.moving-tomb'),
    );
    _expectCompactOccurrenceClosure(compactProjection);

    final compactJson = jsonEncode(compactProjection);
    for (final forbidden in const <String>[
      '二房东',
      '黑中介',
      '六个月',
      '三个月',
      '甲午月',
      '跑路',
      '被赶出',
      '三千',
      'actualOutcome',
      'retrospectiveMappings',
    ]) {
      expect(compactJson, isNot(contains(forbidden)));
    }
    final analysis = first.sections.singleWhere(
      (section) => section.key == 'analysis',
    );
    for (final timingSummaryTerm in const <String>[
      '应期候选',
      '触发窗口',
      '优先观察',
    ]) {
      expect(analysis.content, isNot(contains(timingSummaryTerm)));
    }

    final compactPolicy = compactProjection['policy'] as Map<String, dynamic>;
    compactPolicy['verdictMode'] = 'tampered';
    expect(
      (fullProjection['policy'] as Map<String, dynamic>)['verdictMode'],
      'explainLifecycle',
    );
  });

  test('未取用时保留完整盘面但不产生程序裁决、条件或应期', () {
    final formatter = LiuYaoStructuredFormatter();
    final output = formatter.format(
      _buildResult(const <int>[7, 7, 7, 9, 7, 7]),
    );
    final projection = _projectionOf(output);
    final aiProjection = _aiProjectionOf(output);
    final pan = Map<String, dynamic>.from(projection['pan'] as Map);

    expect(output.coreData['hasChangingGua'], isTrue);
    expect(pan['hasChangingGua'], isTrue);
    expect(pan['changingGua'], isNotNull);
    expect(projection['useSpirit'], containsPair('mode', 'unselected'));
    expect(projection['verdict'], isNull);
    expect(projection['factors'], isEmpty);
    expect(projection['conditions'], isEmpty);
    expect(projection['timingCandidates'], isEmpty);
    expect(aiProjection['policy'], containsPair('verdictMode', 'abstain'));
    expect(aiProjection['verdict'], isNull);
    expect(aiProjection['lifecycleVerdict'], isNull);
    expect(aiProjection['conditions'], isEmpty);
    expect(aiProjection['timingCandidates'], isEmpty);
    expect(
      output.sections.singleWhere((item) => item.key == 'analysis').content,
      contains('程序裁决、条件和应期均为空'),
    );
  });

  test('日历来源决定 castTime 在提示词中的权威语义', () async {
    final formatter = LiuYaoStructuredFormatter();
    final solarResult = await LiuYaoSystem().castByGuaName(
      benGuaId: '001000',
      bianGuaId: '101001',
      yueJian: '庚寅',
      riGanZhi: '癸酉',
      yearGanZhi: '丙午',
      hourGanZhi: '丙辰',
      castTime: DateTime(2026, 2, 28, 8),
      calendarInputMode: LiuYaoCalendarInputMode.providedSolar,
    );
    final solarOutput = formatter.format(solarResult);
    final solarProjection = _projectionOf(solarOutput);
    final solarCalendar = Map<String, dynamic>.from(
      (solarProjection['pan'] as Map)['calendar'] as Map,
    );

    expect(formatter.render(solarOutput), contains('起卦阳历时间'));
    expect(solarCalendar['inputMode'], 'providedSolar');
    expect(solarCalendar['solarConsistency'], isTrue);
    expect(solarCalendar['analysisCalendarAuthority'], 'castTime');

    final directResult = solarResult.copyWith(
      castTime: DateTime(2026, 7, 31, 8),
      calendarInputMode: LiuYaoCalendarInputMode.providedGanZhi,
    );
    final directOutput = formatter.format(directResult);
    final directProjection = _projectionOf(directOutput);
    final directCalendar = Map<String, dynamic>.from(
      (directProjection['pan'] as Map)['calendar'] as Map,
    );

    expect(
      formatter.render(directOutput),
      contains('记录时间（不作为四柱换算依据）'),
    );
    expect(directCalendar['inputMode'], 'providedGanZhi');
    expect(directCalendar['solarConsistency'], isNull);
    expect(directCalendar['analysisCalendarAuthority'], 'storedGanZhi');
  });

  test('投影拒绝绕过起卦系统的 providedSolar 错配结果', () async {
    final result = await LiuYaoSystem().castByGuaName(
      benGuaId: '001000',
      yueJian: '庚寅',
      riGanZhi: '癸酉',
      yearGanZhi: '丙午',
      hourGanZhi: '丙辰',
      castTime: DateTime(2026, 2, 28, 8),
      calendarInputMode: LiuYaoCalendarInputMode.providedSolar,
    );
    final corrupted = result.copyWith(castTime: DateTime(2026, 7, 31, 8));

    expect(
      () => LiuYaoStructuredFormatter().format(corrupted),
      throwsA(isA<FormatException>()),
    );
  });

  test('投影拒绝 derivedFromCastTime 的权威时间与四柱错配', () async {
    final result = await LiuYaoSystem().castByManualYaoNumbers(
      const <int>[8, 8, 6, 7, 8, 6],
      castTime: DateTime(2026, 2, 28, 8),
    );
    final corrupted = result.copyWith(castTime: DateTime(2026, 7, 31, 8));

    expect(
        result.calendarInputMode, LiuYaoCalendarInputMode.derivedFromCastTime);
    expect(
      () => LiuYaoStructuredFormatter().format(corrupted),
      throwsA(isA<FormatException>()),
    );
  });
}

void _expectCompactOccurrenceClosure(Map<String, dynamic> projection) {
  final occurrenceIds = <String>{};
  final referencedIds = <String>{};

  void visit(Object? value) {
    if (value is List) {
      for (final item in value) {
        visit(item);
      }
      return;
    }
    if (value is! Map) return;
    for (final entry in value.entries) {
      final key = entry.key;
      final item = entry.value;
      if (key == 'occurrenceId' && item is String) {
        occurrenceIds.add(item);
      } else if (key is String &&
          key.endsWith('OccurrenceIds') &&
          item is List) {
        referencedIds.addAll(item.whereType<String>());
      }
      visit(item);
    }
  }

  visit(projection);
  final unresolved = referencedIds.difference(occurrenceIds).toList()..sort();
  expect(unresolved, isEmpty, reason: 'orphan compact occurrence references');
}
