import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_trace.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/liuyao_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rule_identity_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';

void main() {
  test('catalog 自校验通过且版本解析受控', () {
    expect(LiuYaoRuleCatalog.validate(), isEmpty);
    expect(LiuYaoRuleCatalog.resolve('current').version, LiuYaoRuleCatalog.v3);
    expect(
      LiuYaoRuleCatalog.resolve(LiuYaoRuleCatalog.v2).sourceCatalogVersion,
      LiuYaoRuleCatalog.v2SourceCatalogVersion,
    );
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
      LiuYaoRuleIds.decisionMixedUnrescuable,
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

    expect(
      LiuYaoRuleCatalog
          .ruleById[LiuYaoRuleIds.decisionMixedUnrescuable]!.ruleSetVersions,
      <String>[LiuYaoRuleCatalog.v3],
    );
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

  test('v3 transformation tags expose later or final lifecycle authority', () {
    const expected =
        <String, ({DirectedEffectPhase phase, DirectedEffectHorizon horizon})>{
      LiuYaoRuleIds.ruleReturnOvercomes: (
        phase: DirectedEffectPhase.laterProcess,
        horizon: DirectedEffectHorizon.subsequent,
      ),
      LiuYaoRuleIds.ruleRetreat: (
        phase: DirectedEffectPhase.laterProcess,
        horizon: DirectedEffectHorizon.subsequent,
      ),
      LiuYaoRuleIds.ruleChangedTerminal: (
        phase: DirectedEffectPhase.finalState,
        horizon: DirectedEffectHorizon.terminal,
      ),
    };

    for (final entry in expected.entries) {
      final rule = LiuYaoRuleCatalog.ruleById[entry.key]!;
      expect(rule.phase, entry.value.phase, reason: entry.key);
      expect(rule.horizon, entry.value.horizon, reason: entry.key);
      expect(
        rule.decisionScopes,
        const <LiuYaoDecisionScope>[
          LiuYaoDecisionScope.continuity,
          LiuYaoDecisionScope.persistence,
        ],
        reason: entry.key,
      );
      expect(
        rule.decisionScopes,
        isNot(contains(LiuYaoDecisionScope.quality)),
        reason: entry.key,
      );
    }
  });
}
