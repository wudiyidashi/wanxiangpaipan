import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

import '../../../services/liuyao/analysis/helpers/analysis_fixtures.dart';

const _liuShen = <String>['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'];

LiuYaoResult _buildResult(
  List<int> numbers, {
  int? yongShenPosition,
  bool yongShenIsFuShen = false,
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
    final analysis = output.sections.singleWhere(
      (section) => section.key == 'analysis',
    );
    final readable =
        analysis.content.split('[LIUYAO_CANONICAL_PROJECTION]').first;

    expect(output.temporal.hourGanZhi, '乙丑');
    expect(output.coreData['hasChangingGua'], isFalse);
    expect(
        output.analysisContract?.analysisSchemaVersion, isNot('legacyUnknown'));
    expect(output.analysisContract?.projectionSchemaVersion, '1');
    expect(output.analysisContract?.ruleSetId, 'liuyao-zengshan-primary');
    expect(output.analysisContract?.ruleSetVersion, 'v2');
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

    for (final factor in projection['factors'] as List<dynamic>) {
      expect(readable, contains((factor as Map<String, dynamic>)['factorId']));
    }
    for (final condition in projection['conditions'] as List<dynamic>) {
      expect(
        readable,
        contains((condition as Map<String, dynamic>)['conditionId']),
      );
    }
    for (final timing in projection['timingCandidates'] as List<dynamic>) {
      final item = timing as Map<String, dynamic>;
      expect(readable, contains(item['timingId']));
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
    expect(jsonDecode(canonicalMatch!.group(1)!), projection);
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
    expect(
      output.sections.singleWhere((item) => item.key == 'analysis').content,
      contains('伏神取用'),
    );
  });

  test('未取用时保留完整盘面但不产生程序裁决、条件或应期', () {
    final formatter = LiuYaoStructuredFormatter();
    final output = formatter.format(
      _buildResult(const <int>[7, 7, 7, 9, 7, 7]),
    );
    final projection = _projectionOf(output);
    final pan = Map<String, dynamic>.from(projection['pan'] as Map);

    expect(output.coreData['hasChangingGua'], isTrue);
    expect(pan['hasChangingGua'], isTrue);
    expect(pan['changingGua'], isNotNull);
    expect(projection['useSpirit'], containsPair('mode', 'unselected'));
    expect(projection['verdict'], isNull);
    expect(projection['factors'], isEmpty);
    expect(projection['conditions'], isEmpty);
    expect(projection['timingCandidates'], isEmpty);
    expect(
      output.sections.singleWhere((item) => item.key == 'analysis').content,
      contains('程序裁决、条件和应期均为空'),
    );
  });
}
