import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Creates deterministic runtime identities from canonical semantic tuples.
class LiuYaoTraceIdFactory {
  final Map<String, String> _tuplesById = <String, String>{};

  String occurrence({
    required String stageId,
    required String ruleId,
    required String subjectRef,
    String? fromActorId,
    String? toActorId,
    int? pathStep,
  }) {
    return _id('lyo', <Object?>[
      stageId,
      ruleId,
      subjectRef,
      fromActorId,
      toActorId,
      pathStep,
    ]);
  }

  String factor({
    required String factorRuleId,
    required Iterable<String> occurrenceIds,
    required int arbitrationTier,
  }) {
    final sorted = occurrenceIds.toSet().toList()..sort();
    return _id('lyf', <Object?>[
      factorRuleId,
      sorted,
      arbitrationTier,
    ]);
  }

  String condition({
    required String conditionRuleId,
    required String focusActorId,
    required Iterable<String> upstreamOccurrenceIds,
  }) {
    final sorted = upstreamOccurrenceIds.toSet().toList()..sort();
    return _id('lyc', <Object?>[
      conditionRuleId,
      focusActorId,
      sorted,
    ]);
  }

  String timing({
    required String timingRuleId,
    required String scale,
    required String triggerKind,
    required String triggerValue,
    required String targetActorId,
    required Iterable<String> upstreamConditionIds,
  }) {
    final sorted = upstreamConditionIds.toSet().toList()..sort();
    return _id('lyt', <Object?>[
      timingRuleId,
      scale,
      triggerKind,
      triggerValue,
      targetActorId,
      sorted,
    ]);
  }

  String _id(String prefix, List<Object?> tuple) {
    final canonicalTuple = jsonEncode(tuple);
    final digest = sha256.convert(utf8.encode(canonicalTuple)).toString();
    final id = '$prefix-${digest.substring(0, 24)}';
    final previous = _tuplesById[id];
    if (previous != null && previous != canonicalTuple) {
      throw StateError('Liuyao trace ID collision for $id');
    }
    _tuplesById[id] = canonicalTuple;
    return id;
  }
}
