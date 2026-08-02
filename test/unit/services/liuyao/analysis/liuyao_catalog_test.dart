import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/liuyao_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rule_identity_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';

void main() {
  test('catalog 自校验通过且版本解析受控', () {
    expect(LiuYaoRuleCatalog.validate(), isEmpty);
    expect(LiuYaoRuleCatalog.resolve('current').version, LiuYaoRuleCatalog.v2);
    expect(
      LiuYaoRuleCatalog.resolve(LiuYaoRuleCatalog.v1Compat).version,
      LiuYaoRuleCatalog.v1Compat,
    );
    expect(
      () => LiuYaoRuleCatalog.resolve('future'),
      throwsArgumentError,
    );
  });

  test('生产 term 与 alias 唯一解析到主规则', () {
    for (final entry in LiuYaoRuleCatalog.tagRuleSpecs.entries) {
      expect(
        LiuYaoRuleCatalog.ruleForTerm(entry.key)?.ruleId,
        entry.value.ruleId,
        reason: entry.key,
      );
    }

    final hidden = LiuYaoRuleCatalog.ruleForTerm('用神(伏)');
    expect(hidden, isNotNull);
    expect(
      LiuYaoRuleCatalog.ruleForTerm('用神（伏）')?.ruleId,
      hidden!.ruleId,
    );
  });

  test('已绑定 ruleId 优先于改名后的展示 term', () {
    const tag = YaoAnalysisTag(
      term: '已改名的展示词',
      category: TagCategory.dongBian,
      polarity: Polarity.neutral,
      priority: 1,
      reason: 'identity regression',
      ruleId: LiuYaoRuleIds.ruleReturnOvercomes,
    );

    expect(
      RuleIdentityService.resolveRuleId(tag),
      LiuYaoRuleIds.ruleReturnOvercomes,
    );
  });

  test('决策行、条件与应期规则集合完整', () {
    const decisionRows = <String>{
      LiuYaoRuleIds.decisionReturnOvercomeWithoutL1Support,
      LiuYaoRuleIds.decisionReturnGenerateUnblocked,
      LiuYaoRuleIds.decisionWeakUnrescuable,
      LiuYaoRuleIds.decisionWeakAdverseActive,
      LiuYaoRuleIds.decisionWeakUnsupported,
      LiuYaoRuleIds.decisionStrongClear,
      LiuYaoRuleIds.decisionStrongWithConditions,
      LiuYaoRuleIds.decisionStrongAdverseActive,
      LiuYaoRuleIds.decisionMixedSourceContinuity,
      LiuYaoRuleIds.decisionMixedAdverseActive,
      LiuYaoRuleIds.decisionMixedRescuableConditions,
      LiuYaoRuleIds.decisionMixedL1Support,
      LiuYaoRuleIds.decisionMixedUnresolved,
    };
    const conditions = <String>{
      LiuYaoRuleIds.conditionTrueVoid,
      LiuYaoRuleIds.conditionVoid,
      LiuYaoRuleIds.conditionMonthBreak,
      LiuYaoRuleIds.conditionTomb,
      LiuYaoRuleIds.conditionChangedTomb,
      LiuYaoRuleIds.conditionBinding,
      LiuYaoRuleIds.conditionChangedVoid,
      LiuYaoRuleIds.conditionChangedBreak,
      LiuYaoRuleIds.conditionTerminal,
      LiuYaoRuleIds.conditionHiddenRelease,
      LiuYaoRuleIds.conditionHiddenSuppressed,
    };
    const timing = <String>{
      LiuYaoRuleIds.timingVoidFill,
      LiuYaoRuleIds.timingVoidClash,
      LiuYaoRuleIds.timingMonthBreakExit,
      LiuYaoRuleIds.timingMonthBreakFill,
      LiuYaoRuleIds.timingMonthBreakJoin,
      LiuYaoRuleIds.timingTombOpen,
      LiuYaoRuleIds.timingBindingTargetClash,
      LiuYaoRuleIds.timingBindingPartnerClash,
      LiuYaoRuleIds.timingChangedVoidFill,
      LiuYaoRuleIds.timingChangedVoidClash,
      LiuYaoRuleIds.timingChangedBreakExit,
      LiuYaoRuleIds.timingChangedBreakFill,
      LiuYaoRuleIds.timingChangedBreakJoin,
      LiuYaoRuleIds.timingTerminalChangSheng,
      LiuYaoRuleIds.timingHiddenFill,
      LiuYaoRuleIds.timingHiddenFlightClash,
    };

    expect(
      LiuYaoRuleCatalog.rules
          .where((rule) => rule.ruleId.startsWith('liuyao.decision.'))
          .map((rule) => rule.ruleId)
          .toSet(),
      decisionRows,
    );
    expect(
      LiuYaoRuleCatalog.rules
          .where((rule) => rule.family == LiuYaoRuleFamily.condition)
          .map((rule) => rule.ruleId)
          .toSet(),
      conditions,
    );
    expect(
      LiuYaoRuleCatalog.rules
          .where((rule) => rule.family == LiuYaoRuleFamily.timing)
          .map((rule) => rule.ruleId)
          .toSet(),
      timing,
    );
  });

  test('项目裁定不冒充古籍且 locator-only 不可决定裁决', () {
    for (final rule in LiuYaoRuleCatalog.rules) {
      expect(rule.evidenceRefs, isNotEmpty, reason: rule.ruleId);
      for (final reference in rule.evidenceRefs) {
        expect(
          LiuYaoRuleCatalog.sourceById,
          contains(reference.sourceId),
          reason: rule.ruleId,
        );
        if (reference.sourceId == LiuYaoRuleIds.projectSource) {
          expect(
            reference.referenceKind,
            LiuYaoReferenceKind.projectConvention,
            reason: rule.ruleId,
          );
          expect(reference.evidenceLevel, LiuYaoEvidenceLevel.d);
          expect(reference.quote, isNull);
        }
        if (reference.referenceKind == LiuYaoReferenceKind.locatorOnly) {
          expect(rule.decisionCapable, isFalse, reason: rule.ruleId);
        }
      }
    }
  });
}
