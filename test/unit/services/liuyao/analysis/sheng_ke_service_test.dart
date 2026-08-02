import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/actor_availability_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_trace_id_factory.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/sheng_ke_service.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲寅');

  List<String> termsAt(Map<int, List<YaoAnalysisTag>> result, int pos) =>
      (result[pos] ?? []).map((t) => t.term).toList();

  ShengKeAnalysisResult analyzeDirected(List<int> numbers) {
    final gua = buildGua(numbers);
    const baseTags = <int, List<YaoAnalysisTag>>{};
    final availability = ActorAvailabilityService.evaluateGua(
      mainGua: gua,
      changingGua: null,
      lunarInfo: lunar,
      yaoTags: baseTags,
      ruleSetVersion: LiuYaoRuleCatalog.v2,
    );
    return ShengKeService.analyzeDirected(
      gua: gua,
      lunarInfo: lunar,
      baseTags: baseTags,
      actorAvailability: availability,
      traceIdFactory: LiuYaoTraceIdFactory(),
    );
  }

  group('ShengKeService 动爻生克扶', () {
    test('乾卦初爻子水动：生二爻寅木、克四爻午火', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      expect(termsAt(result, 2), contains('动爻生'));
      expect(termsAt(result, 4), contains('动爻克'));
      final tag = result[2]!.firstWhere((t) => t.term == '动爻生');
      expect(tag.relatedYao, contains(1));
    });

    test('同五行动爻扶：三爻辰土动扶上爻戌土', () {
      final qian = buildGua([7, 7, 9, 7, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      expect(termsAt(result, 6), contains('动爻扶'));
    });

    test('静爻不施生克', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      expect(result, isEmpty);
    });
  });

  group('ShengKeService 贪生忘克', () {
    test('动爻克我但贪生他动爻：克解除', () {
      // 乾：初爻子水动克四爻午火；二爻寅木亦动，子贪生寅忘克午
      final qian = buildGua([9, 9, 7, 7, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      final terms4 = termsAt(result, 4);
      expect(terms4, contains('贪生忘克'));
      expect(terms4, isNot(contains('动爻克')));
      final tag = result[4]!.firstWhere((t) => t.term == '贪生忘克');
      expect(tag.polarity, Polarity.ji);
      expect(tag.relatedYao, containsAll([1, 2]));
    });

    test('无可贪生对象时正常克', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      expect(termsAt(result, 4), contains('动爻克'));
      expect(termsAt(result, 4), isNot(contains('贪生忘克')));
    });
  });

  group('ShengKeService 贪合忘生克', () {
    test('动爻被合住则忘克：泰卦子动合丑，子不克他爻', () {
      // 泰：初爻子水动，四爻丑土静（子丑合）——子贪合忘克午？泰无午。
      // 用乾变体不便构造合；改用地天泰初爻动：子合丑后不生二爻寅
      final tai = buildGua([9, 7, 7, 8, 8, 8]);
      final result = ShengKeService.analyzeGua(tai, lunar);
      final terms2 = termsAt(result, 2);
      expect(terms2, contains('贪合忘生'));
      expect(terms2, isNot(contains('动爻生')));
    });

    test('合处已逢日冲则恢复动爻生克', () {
      final tai = buildGua([9, 7, 7, 8, 8, 8]);
      final wuDay = buildLunar(yueJian: '寅', riGanZhi: '甲午');

      final result = ShengKeService.analyzeGua(tai, wuDay);

      expect(termsAt(result, 2), contains('动爻生'));
      expect(termsAt(result, 2), isNot(contains('贪合忘生')));
    });
  });

  group('ShengKeService 连续相生克', () {
    test('三动爻连续相生：子生寅、寅生午', () {
      // 乾：初子(1)、二寅(2)、四午(4)皆动 → 水生木生火
      final qian = buildGua([9, 9, 7, 9, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      for (final pos in [1, 2, 4]) {
        expect(termsAt(result, pos), contains('连续相生'),
            reason: '$pos 爻应在连续相生链中');
      }
    });

    test('三动爻连续相克：子克午、午克申', () {
      final qian = buildGua([9, 7, 7, 9, 9, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      for (final pos in [1, 4, 5]) {
        expect(termsAt(result, pos), contains('连续相克'),
            reason: '$pos 爻应在连续相克链中');
      }
    });

    test('仅两动爻不成连续链', () {
      final qian = buildGua([9, 9, 7, 7, 7, 7]);
      final result = ShengKeService.analyzeGua(qian, lunar);
      expect(termsAt(result, 1), isNot(contains('连续相生')));
    });
  });

  group('ShengKeService v2 有向连续作用', () {
    test('连续相生记录头中尾路径且只标注终点', () {
      final result = analyzeDirected([9, 9, 7, 9, 7, 7]);
      final chainRuleId = LiuYaoRuleCatalog.tagRuleSpecs['连续相生']!.ruleId;
      final chain = result.effects.singleWhere(
        (effect) => effect.ruleId == chainRuleId,
      );

      expect(chain.fromActor.position, 1);
      expect(chain.toActor.position, 4);
      expect(
        chain.pathActorIds,
        orderedEquals(<String>['main:yao:1', 'main:yao:2', 'main:yao:4']),
      );
      expect(chain.pathStep, 2);
      expect(chain.isActive, isTrue);
      expect(termsAt(result.tags, 1), isNot(contains('连续相生')));
      expect(termsAt(result.tags, 2), isNot(contains('连续相生')));
      expect(termsAt(result.tags, 4), contains('连续相生'));
      final terminalTag = result.tags[4]!.singleWhere(
        (tag) => tag.term == '连续相生',
      );
      expect(terminalTag.relatedYao, orderedEquals(<int>[1, 2]));
      expect(terminalTag.occurrenceId, chain.occurrenceId);
    });

    test('连续相克记录头中尾路径且只标注终点', () {
      final result = analyzeDirected([9, 7, 7, 9, 9, 7]);
      final chainRuleId = LiuYaoRuleCatalog.tagRuleSpecs['连续相克']!.ruleId;
      final chain = result.effects.singleWhere(
        (effect) => effect.ruleId == chainRuleId,
      );

      expect(chain.fromActor.position, 1);
      expect(chain.toActor.position, 5);
      expect(
        chain.pathActorIds,
        orderedEquals(<String>['main:yao:1', 'main:yao:4', 'main:yao:5']),
      );
      expect(chain.pathStep, 2);
      expect(chain.isActive, isTrue);
      expect(termsAt(result.tags, 1), isNot(contains('连续相克')));
      expect(termsAt(result.tags, 4), isNot(contains('连续相克')));
      expect(termsAt(result.tags, 5), contains('连续相克'));
      final terminalTag = result.tags[5]!.singleWhere(
        (tag) => tag.term == '连续相克',
      );
      expect(terminalTag.relatedYao, orderedEquals(<int>[1, 4]));
      expect(terminalTag.occurrenceId, chain.occurrenceId);
    });

    test('中继作用者化退时终点路径受制并闭包 blocker occurrence', () {
      final gua = buildGua([9, 9, 7, 9, 7, 7]);
      final blockerRule = LiuYaoRuleCatalog.ruleForTerm('化退神')!;
      final baseTags = <int, List<YaoAnalysisTag>>{
        2: <YaoAnalysisTag>[
          YaoAnalysisTag(
            term: '化退神',
            category: TagCategory.dongBian,
            polarity: Polarity.xiong,
            priority: 1,
            reason: 'test blocker',
            ruleId: blockerRule.ruleId,
            occurrenceId: 'lyo-retreat-blocker',
            sourceIds: blockerRule.sourceIds,
          ),
        ],
      };
      final availability = ActorAvailabilityService.evaluateGua(
        mainGua: gua,
        changingGua: null,
        lunarInfo: lunar,
        yaoTags: baseTags,
        ruleSetVersion: LiuYaoRuleCatalog.v2,
      );
      final result = ShengKeService.analyzeDirected(
        gua: gua,
        lunarInfo: lunar,
        baseTags: baseTags,
        actorAvailability: availability,
        traceIdFactory: LiuYaoTraceIdFactory(),
      );
      final movingGeneratesRule = LiuYaoRuleCatalog.tagRuleSpecs['动爻生']!.ruleId;
      final terminalEdge = result.effects.singleWhere(
        (effect) =>
            effect.ruleId == movingGeneratesRule &&
            effect.fromActor.position == 2 &&
            effect.toActor.position == 4,
      );
      final chainRuleId = LiuYaoRuleCatalog.tagRuleSpecs['连续相生']!.ruleId;
      final chain = result.effects.singleWhere(
        (effect) => effect.ruleId == chainRuleId,
      );

      expect(terminalEdge.isActive, isFalse);
      expect(
        terminalEdge.suppressedByOccurrenceIds,
        contains('lyo-retreat-blocker'),
      );
      expect(chain.isActive, isFalse);
      expect(
        chain.suppressedByOccurrenceIds,
        containsAll(<String>[
          'lyo-retreat-blocker',
          terminalEdge.occurrenceId,
        ]),
      );
      final terminalTag = result.tags[4]!.singleWhere(
        (tag) => tag.term == '连续相生',
      );
      expect(
        terminalTag.suppressedByOccurrenceIds,
        orderedEquals(chain.suppressedByOccurrenceIds),
      );
    });

    test('暗动展示术语改名后仍按稳定 ID 产生作用', () {
      final gua = buildGua([7, 7, 7, 7, 7, 7]);
      final hiddenMovingRule =
          LiuYaoRuleCatalog.ruleById[LiuYaoRuleIds.ruleHiddenMoving]!;
      final baseTags = <int, List<YaoAnalysisTag>>{
        1: <YaoAnalysisTag>[
          YaoAnalysisTag(
            term: '日冲发动（展示名）',
            category: TagCategory.dongBian,
            polarity: Polarity.neutral,
            priority: 1,
            reason: 'renamed hidden-moving display term',
            ruleId: hiddenMovingRule.ruleId,
            occurrenceId: 'lyo-renamed-hidden-moving',
            sourceIds: hiddenMovingRule.sourceIds,
          ),
        ],
      };
      final availability = ActorAvailabilityService.evaluateGua(
        mainGua: gua,
        changingGua: null,
        lunarInfo: lunar,
        yaoTags: baseTags,
        ruleSetVersion: LiuYaoRuleCatalog.v2,
      );

      final result = ShengKeService.analyzeDirected(
        gua: gua,
        lunarInfo: lunar,
        baseTags: baseTags,
        actorAvailability: availability,
        traceIdFactory: LiuYaoTraceIdFactory(),
      );

      expect(
        result.effects.where(
          (effect) =>
              effect.fromActor.position == 1 &&
              effect.ruleId == LiuYaoRuleIds.hiddenMovingGenerates,
        ),
        isNotEmpty,
      );
      expect(
        result.effects.where(
          (effect) =>
              effect.fromActor.position == 1 &&
              effect.ruleId == LiuYaoRuleIds.hiddenMovingOvercomes,
        ),
        isNotEmpty,
      );
    });
  });
}
