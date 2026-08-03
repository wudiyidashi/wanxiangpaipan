import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_ai_projection_compactor.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';

const _bindingOpenedRuleId = 'liuyao.rule.hechong.binding-opened';
const _mutualBindingRuleId = 'liuyao.rule.hechong.mutual-binding';
const _openedBindingAvailabilityRuleId =
    'liuyao.project.availability.opened-binding-restores';
const _apparentVoidRuleId = 'liuyao.rule.kongwang.apparent-void';
final _unprojectedTimingVocabulary =
    RegExp(r'出空|出月|填实|冲开|解除合绊|合绊已解|等待|等到|等至|待到|待至|择日|时机|届时');

void main() {
  late LiuYaoResult base;

  setUpAll(() async {
    base = await LiuYaoSystem().castByManualYaoNumbers(
      const <int>[8, 8, 6, 7, 8, 6],
      castTime: DateTime(2026, 2, 28, 8),
    );
  });

  test(
      'empty conditions and timing keep resolved binding audit only in full view',
      () {
    final output = LiuYaoStructuredFormatter().format(
      base.copyWith(yongShenPosition: 1),
      question: '租房是否顺利',
    );
    final full = _projectionOf(output, 'projection');
    final compact = _projectionOf(output, 'aiProjection');
    final fullBeforeCompaction = jsonEncode(full);
    final fullBindingTags = _actorTags(full)
        .where((tag) => tag['ruleId'] == _bindingOpenedRuleId)
        .toList(growable: false);
    final bindingOccurrenceIds = fullBindingTags
        .map((tag) => tag['occurrenceId'])
        .whereType<String>()
        .toSet();
    final resolvedBindingOccurrenceIds = _actorTags(full)
        .where((tag) => <String>{
              _bindingOpenedRuleId,
              _mutualBindingRuleId,
            }.contains(tag['ruleId']))
        .map((tag) => tag['occurrenceId'])
        .whereType<String>()
        .toSet();

    expect(full['conditions'], isEmpty);
    expect(full['timingCandidates'], isEmpty);
    expect(
      (full['verdict']! as Map<Object?, Object?>),
      contains('summary'),
    );
    expect(
      (compact['verdict']! as Map<Object?, Object?>),
      isNot(contains('summary')),
    );
    expect(_releaseConditionRuleIds(full), isNotEmpty);
    expect(_releaseConditionRuleIds(compact), isEmpty);
    expect(fullBindingTags, isNotEmpty);
    expect(fullBindingTags.every((tag) => tag['active'] == true), isTrue);
    expect(bindingOccurrenceIds, isNotEmpty);
    expect(
      _actorTags(full).map((tag) => tag['ruleId']),
      contains(_mutualBindingRuleId),
    );
    expect(
      _useSpiritTagOccurrenceIds(full).intersection(bindingOccurrenceIds),
      isNotEmpty,
    );
    expect(_sourceRuleIds(full), contains(_bindingOpenedRuleId));

    expect(
      _actorTags(compact).map((tag) => tag['ruleId']),
      isNot(contains(_bindingOpenedRuleId)),
    );
    expect(
      _actorTags(compact).map((tag) => tag['ruleId']),
      isNot(contains(_mutualBindingRuleId)),
    );
    expect(
      _useSpiritTagOccurrenceIds(compact).intersection(bindingOccurrenceIds),
      isEmpty,
    );
    expect(
      _referencedOccurrenceIds(compact).intersection(bindingOccurrenceIds),
      isEmpty,
    );
    expect(
      _referencedOccurrenceIds(compact)
          .intersection(resolvedBindingOccurrenceIds),
      isEmpty,
    );
    expect(_sourceRuleIds(compact), isNot(contains(_bindingOpenedRuleId)));
    expect(_sourceRuleIds(compact), isNot(contains(_mutualBindingRuleId)));
    expect(
      _sourceRuleIds(compact),
      isNot(contains(_openedBindingAvailabilityRuleId)),
    );
    expect(jsonEncode(compact), isNot(contains(_bindingOpenedRuleId)));
    expect(
      jsonEncode(compact),
      isNot(contains(_openedBindingAvailabilityRuleId)),
    );
    final apparentVoidTags = _actorTags(compact)
        .where((tag) => tag['ruleId'] == _apparentVoidRuleId)
        .toList(growable: false);
    expect(apparentVoidTags, isNotEmpty);
    expect(
      apparentVoidTags.map((tag) => tag['reason']).toSet(),
      <Object?>{'旺或动而不作全空，当前按假空参与分析'},
    );
    expect(_unprojectedTimingVocabulary.hasMatch(jsonEncode(compact)), isFalse);
    _expectOccurrenceClosure(compact);

    expect(LiuYaoAiProjectionCompactor.compact(full), compact);
    expect(jsonEncode(full), fullBeforeCompaction);
    expect(
      _actorTags(full).map((tag) => tag['ruleId']),
      contains(_bindingOpenedRuleId),
    );
  });

  test('nonempty conditions and timing retain active binding-opened', () {
    final output = LiuYaoStructuredFormatter().format(
      base.copyWith(yongShenPosition: 6),
      question: '租房是否顺利',
    );
    final full = _projectionOf(output, 'projection');
    final compact = _projectionOf(output, 'aiProjection');
    final bindingOccurrenceIds = _actorTags(full)
        .where((tag) => tag['ruleId'] == _bindingOpenedRuleId)
        .map((tag) => tag['occurrenceId'])
        .whereType<String>()
        .toSet();

    expect(full['conditions'], isNotEmpty);
    expect(full['timingCandidates'], isNotEmpty);
    expect(_releaseConditionRuleIds(full), isNotEmpty);
    expect(
      _releaseConditionRuleIds(compact),
      _releaseConditionRuleIds(full),
    );
    expect(
      (compact['verdict']! as Map<Object?, Object?>),
      contains('summary'),
    );
    expect(bindingOccurrenceIds, isNotEmpty);
    expect(
      _actorTags(compact).map((tag) => tag['ruleId']),
      contains(_bindingOpenedRuleId),
    );
    expect(
      _useSpiritTagOccurrenceIds(compact).intersection(bindingOccurrenceIds),
      isNotEmpty,
    );
    expect(_sourceRuleIds(compact), contains(_bindingOpenedRuleId));
    expect(_sourceRuleIds(compact), contains(_mutualBindingRuleId));
    _expectOccurrenceClosure(compact);
  });
}

Map<String, Object?> _projectionOf(
  StructuredDivinationOutput output,
  String key,
) {
  final analysis =
      output.sections.singleWhere((section) => section.key == 'analysis');
  return (analysis.metadata![key]! as Map<Object?, Object?>)
      .cast<String, Object?>();
}

Iterable<Map<String, Object?>> _actorTags(Map<String, Object?> projection) =>
    (projection['actorFacts']! as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .expand((fact) => fact['tags']! as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .map((tag) => tag.cast<String, Object?>());

Set<String> _useSpiritTagOccurrenceIds(
  Map<String, Object?> projection,
) {
  final result = <String>{};
  for (final raw in projection['useSpiritOccurrences']! as List<Object?>) {
    final occurrence = (raw! as Map<Object?, Object?>).cast<String, Object?>();
    final tags = occurrence['tags'];
    if (tags is List<Object?>) {
      result.addAll(tags
          .cast<Map<Object?, Object?>>()
          .map(
            (tag) => tag['occurrenceId'],
          )
          .whereType<String>());
    }
    final tagOccurrenceIds = occurrence['tagOccurrenceIds'];
    if (tagOccurrenceIds is List<Object?>) {
      result.addAll(tagOccurrenceIds.whereType<String>());
    }
  }
  return result;
}

Set<String> _sourceRuleIds(Map<String, Object?> projection) =>
    (projection['sources']! as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .expand((source) => source['references']! as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .map((reference) => reference['ruleId'])
        .whereType<String>()
        .toSet();

Set<String> _releaseConditionRuleIds(Map<String, Object?> projection) {
  final result = <String>{};
  for (final branch in const <String>[
    'actorFacts',
    'useSpiritOccurrences',
  ]) {
    for (final raw in projection[branch]! as List<Object?>) {
      final item = raw! as Map<Object?, Object?>;
      final availability = item['availability'];
      if (availability is! Map<Object?, Object?>) continue;
      final ruleIds = availability['releaseConditionRuleIds'];
      if (ruleIds is List<Object?>) {
        result.addAll(ruleIds.whereType<String>());
      }
    }
  }
  return result;
}

Set<String> _referencedOccurrenceIds(Object? value) {
  final result = <String>{};

  void visit(Object? item) {
    if (item is List<Object?>) {
      for (final child in item) {
        visit(child);
      }
      return;
    }
    if (item is! Map<Object?, Object?>) return;
    for (final entry in item.entries) {
      final key = entry.key;
      final child = entry.value;
      if (key is String && key.endsWith('OccurrenceIds')) {
        if (child is List<Object?>) {
          result.addAll(child.whereType<String>());
        } else if (child is Map<Object?, Object?>) {
          for (final ids in child.values.whereType<List<Object?>>()) {
            result.addAll(ids.whereType<String>());
          }
        }
      }
      visit(child);
    }
  }

  visit(value);
  return result;
}

void _expectOccurrenceClosure(Map<String, Object?> projection) {
  final defined = <String>{};

  void visit(Object? value) {
    if (value is List<Object?>) {
      for (final item in value) {
        visit(item);
      }
      return;
    }
    if (value is! Map<Object?, Object?>) return;
    final occurrenceId = value['occurrenceId'];
    if (occurrenceId is String) defined.add(occurrenceId);
    final evidenceId = value['evidenceId'];
    if (evidenceId is String) defined.add(evidenceId);
    for (final item in value.values) {
      visit(item);
    }
  }

  visit(projection);
  final orphaned = _referencedOccurrenceIds(projection).difference(defined);
  expect(orphaned, isEmpty, reason: 'compact occurrence references must close');
}
