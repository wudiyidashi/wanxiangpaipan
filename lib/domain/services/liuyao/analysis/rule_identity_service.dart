import 'models/analysis_tag.dart';
import 'rules/liuyao_catalog.dart';
import 'rules/liuyao_trace_id_factory.dart';

/// Resolves legacy display terms once, then carries stable identities downstream.
class RuleIdentityService {
  RuleIdentityService._();

  static String? resolveRuleId(YaoAnalysisTag tag) {
    if (tag.ruleId.isNotEmpty) {
      return LiuYaoRuleCatalog.ruleById.containsKey(tag.ruleId)
          ? tag.ruleId
          : null;
    }
    return LiuYaoRuleCatalog.legacyTermToRuleId[tag.term];
  }

  static YaoAnalysisTag bindTag({
    required YaoAnalysisTag tag,
    required String stageId,
    required String subjectRef,
    required LiuYaoTraceIdFactory traceIdFactory,
    String? fromActorId,
    String? toActorId,
    int? pathStep,
  }) {
    final ruleId = resolveRuleId(tag);
    if (ruleId == null) {
      throw StateError('Unknown Liuyao production rule for term: ${tag.term}');
    }
    final rule = LiuYaoRuleCatalog.ruleById[ruleId]!;
    final occurrenceId = tag.occurrenceId.isNotEmpty
        ? tag.occurrenceId
        : traceIdFactory.occurrence(
            stageId: stageId,
            ruleId: ruleId,
            subjectRef: subjectRef,
            fromActorId: fromActorId,
            toActorId: toActorId,
            pathStep: pathStep,
          );
    return tag.copyWith(
      ruleId: ruleId,
      occurrenceId: occurrenceId,
      sourceIds: tag.sourceIds.isEmpty ? rule.sourceIds : tag.sourceIds,
    );
  }
}
