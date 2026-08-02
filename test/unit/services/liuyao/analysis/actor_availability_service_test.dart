import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/actor_availability_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_trace.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');

  YaoAnalysisTag tag(String term, String occurrenceId) {
    final rule = LiuYaoRuleCatalog.ruleForTerm(term)!;
    return YaoAnalysisTag(
      term: term,
      category: TagCategory.special,
      polarity: Polarity.neutral,
      priority: 1,
      reason: 'test blocker',
      ruleId: rule.ruleId,
      occurrenceId: occurrenceId,
      sourceIds: rule.sourceIds,
    );
  }

  ActorAvailability evaluate(
    Yao yao,
    List<YaoAnalysisTag> tags, {
    String version = LiuYaoRuleCatalog.v2,
    LunarInfo? calendar,
  }) {
    return ActorAvailabilityService.evaluateActor(
      actor: ActorAvailabilityService.mainActor(yao),
      tags: tags,
      lunarInfo: calendar ?? lunar,
      ruleSetVersion: version,
    );
  }

  test('v1-compat 保持所有作用者可用', () {
    final availability = evaluate(
      makeYao(position: 1, branch: '子', moving: true),
      <YaoAnalysisTag>[tag('回头克', 'lyo-return-overcome')],
      version: LiuYaoRuleCatalog.v1Compat,
    );

    expect(availability.state, ActorAvailabilityState.active);
    expect(availability.reasonRuleIds, isEmpty);
    expect(availability.suppressedByOccurrenceIds, isEmpty);
  });

  test('真空优先判不可用并链接全部实际阻断标签', () {
    final trueVoid = tag('真空', 'lyo-true-void');
    final voidTag = tag('旬空', 'lyo-void');
    final availability = evaluate(
      makeYao(position: 6, branch: '戌'),
      <YaoAnalysisTag>[trueVoid, voidTag],
    );
    final expectedRules = <String>[
      LiuYaoRuleIds.actorTrueVoid,
      trueVoid.ruleId,
      voidTag.ruleId,
    ]..sort();

    expect(availability.state, ActorAvailabilityState.unavailable);
    expect(availability.reasonRuleIds, orderedEquals(expectedRules));
    expect(
      availability.suppressedByOccurrenceIds,
      orderedEquals(<String>['lyo-true-void', 'lyo-void']),
    );
    expect(availability.releaseConditionRuleIds, isEmpty);
  });

  test('伏神受制只记录政策与实际 blocker 的闭包', () {
    final suppressed = tag('伏神受制', 'lyo-hidden-suppressed');
    final flightOvercomes = tag('飞克伏', 'lyo-flight-overcomes');
    final availability = ActorAvailabilityService.evaluateActor(
      actor: ActorAvailabilityService.hiddenActor(
        makeYao(position: 2, branch: '寅'),
      ),
      tags: <YaoAnalysisTag>[suppressed, flightOvercomes],
      lunarInfo: lunar,
      ruleSetVersion: LiuYaoRuleCatalog.v2,
    );
    final expectedRules = <String>[
      LiuYaoRuleIds.actorHiddenSuppressed,
      suppressed.ruleId,
      flightOvercomes.ruleId,
    ]..sort();

    expect(availability.state, ActorAvailabilityState.unavailable);
    expect(availability.reasonRuleIds, orderedEquals(expectedRules));
    expect(
      availability.suppressedByOccurrenceIds,
      orderedEquals(<String>[
        'lyo-flight-overcomes',
        'lyo-hidden-suppressed',
      ]),
    );
    expect(
      availability.reasonRuleIds,
      isNot(contains(LiuYaoRuleIds.conditionHiddenSuppressed)),
    );
  });

  test('回头克对不同角色位置使用同一压制政策', () {
    final blocker = tag('回头克', 'lyo-return-overcome');
    final first = evaluate(
      makeYao(position: 1, branch: '子', moving: true),
      <YaoAnalysisTag>[blocker],
    );
    final fifth = evaluate(
      makeYao(position: 5, branch: '申', moving: true),
      <YaoAnalysisTag>[blocker],
    );

    expect(first.state, ActorAvailabilityState.suppressed);
    expect(fifth.state, ActorAvailabilityState.suppressed);
    expect(first.reasonRuleIds, orderedEquals(fifth.reasonRuleIds));
    expect(first.reasonRuleIds, contains(LiuYaoRuleIds.actorReturnOvercome));
  });

  test('旬空与月破悬置并暴露对应释放条件', () {
    final voidAvailability = evaluate(
      makeYao(position: 1, branch: '子'),
      <YaoAnalysisTag>[tag('旬空', 'lyo-void')],
    );
    final brokenAvailability = evaluate(
      makeYao(position: 2, branch: '寅'),
      <YaoAnalysisTag>[tag('月破', 'lyo-month-break')],
    );

    expect(voidAvailability.state, ActorAvailabilityState.suspended);
    expect(
      voidAvailability.releaseConditionRuleIds,
      orderedEquals(<String>[LiuYaoRuleIds.conditionVoid]),
    );
    expect(brokenAvailability.state, ActorAvailabilityState.suspended);
    expect(
      brokenAvailability.releaseConditionRuleIds,
      orderedEquals(<String>[LiuYaoRuleIds.conditionMonthBreak]),
    );
  });

  test('日合与月合对动爻采用同一悬置政策', () {
    final dayBound = evaluate(
      makeYao(position: 1, branch: '丑', moving: true),
      const <YaoAnalysisTag>[],
    );
    final monthBound = evaluate(
      makeYao(position: 2, branch: '未', moving: true),
      const <YaoAnalysisTag>[],
    );

    for (final availability in <ActorAvailability>[dayBound, monthBound]) {
      expect(availability.state, ActorAvailabilityState.suspended);
      expect(availability.reasonRuleIds, contains(LiuYaoRuleIds.actorBinding));
      expect(
        availability.releaseConditionRuleIds,
        orderedEquals(<String>[LiuYaoRuleIds.conditionBinding]),
      );
    }
  });

  test('合处逢另一日月冲开时恢复作用', () {
    final availability = evaluate(
      makeYao(position: 1, branch: '丑', moving: true),
      const <YaoAnalysisTag>[],
      calendar: buildLunar(yueJian: '未', riGanZhi: '甲子'),
    );

    expect(availability.state, ActorAvailabilityState.active);
    expect(
      availability.reasonRuleIds,
      orderedEquals(<String>[LiuYaoRuleIds.actorBindingOpened]),
    );
  });

  test('月合逢日冲开时同样恢复作用', () {
    final availability = evaluate(
      makeYao(position: 1, branch: '丑', moving: true),
      const <YaoAnalysisTag>[],
      calendar: buildLunar(yueJian: '子', riGanZhi: '丁未'),
    );

    expect(availability.state, ActorAvailabilityState.active);
    expect(
      availability.reasonRuleIds,
      orderedEquals(<String>[LiuYaoRuleIds.actorBindingOpened]),
    );
  });

  test('化退神与冲散直接压制作用并保留 blocker occurrence', () {
    final cases = <(String, String, String)>[
      ('化退神', LiuYaoRuleIds.actorRetreat, 'lyo-retreat'),
      ('冲散', LiuYaoRuleIds.actorScattered, 'lyo-scattered'),
    ];

    for (final item in cases) {
      final availability = evaluate(
        makeYao(position: 3, branch: '辰', moving: true),
        <YaoAnalysisTag>[tag(item.$1, item.$3)],
      );

      expect(availability.state, ActorAvailabilityState.suppressed);
      expect(availability.reasonRuleIds, contains(item.$2));
      expect(
        availability.suppressedByOccurrenceIds,
        orderedEquals(<String>[item.$3]),
      );
    }
  });

  test('展示术语改名不改变 blocker 与合绊判定', () {
    final renamedReturn = tag('回头克', 'lyo-renamed-return').copyWith(
      term: '变爻反制（展示名）',
    );
    final suppressed = evaluate(
      makeYao(position: 3, branch: '辰', moving: true),
      <YaoAnalysisTag>[renamedReturn],
    );

    expect(suppressed.state, ActorAvailabilityState.suppressed);
    expect(
      suppressed.suppressedByOccurrenceIds,
      orderedEquals(<String>['lyo-renamed-return']),
    );

    final renamedBinding = tag('合住', 'lyo-renamed-binding').copyWith(
      term: '受合暂停（展示名）',
    );
    final bound = evaluate(
      makeYao(position: 4, branch: '午', moving: true),
      <YaoAnalysisTag>[renamedBinding],
      calendar: buildLunar(yueJian: '寅', riGanZhi: '甲寅'),
    );

    expect(bound.state, ActorAvailabilityState.suspended);
    expect(
      bound.suppressedByOccurrenceIds,
      orderedEquals(<String>['lyo-renamed-binding']),
    );
  });
}
