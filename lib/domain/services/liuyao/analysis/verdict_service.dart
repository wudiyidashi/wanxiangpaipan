import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import 'actor_availability_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'models/analysis_trace.dart';
import 'rule_identity_service.dart';
import 'rules/liuyao_catalog.dart';
import 'rules/liuyao_trace_id_factory.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';

enum _Strength { strong, weak, mixed }

/// First-match four-value verdict, with typed identities and provenance.
class VerdictService {
  VerdictService._();

  static const Set<String> _l1FuRuleIds = <String>{
    LiuYaoRuleIds.ruleMonthCommand,
    LiuYaoRuleIds.ruleDayCommand,
    LiuYaoRuleIds.ruleDaySupports,
    LiuYaoRuleIds.ruleMonthGenerates,
    LiuYaoRuleIds.ruleDayGenerates,
    LiuYaoRuleIds.ruleProsperous,
    LiuYaoRuleIds.ruleSupported,
  };
  static const Set<String> _l1YiRuleIds = <String>{
    LiuYaoRuleIds.ruleMonthOvercomes,
    LiuYaoRuleIds.ruleDayOvercomes,
    LiuYaoRuleIds.ruleConfined,
    LiuYaoRuleIds.ruleDead,
    LiuYaoRuleIds.ruleDayBreak,
    LiuYaoRuleIds.ruleScattered,
  };
  static const Set<String> _l2FuRuleIds = <String>{
    LiuYaoRuleIds.ruleMovingGenerates,
    LiuYaoRuleIds.ruleMovingSupports,
    LiuYaoRuleIds.ruleContinuousGeneration,
  };
  static const Set<String> _l2YiRuleIds = <String>{
    LiuYaoRuleIds.ruleMovingOvercomes,
    LiuYaoRuleIds.ruleContinuousOvercoming,
  };
  static const Set<String> _l4FuRuleIds = <String>{
    LiuYaoRuleIds.ruleReturnGenerates,
    LiuYaoRuleIds.ruleProgress,
    LiuYaoRuleIds.ruleChangedJoin,
  };
  static const Set<String> _l4YiHeavyRuleIds = <String>{
    LiuYaoRuleIds.ruleReturnOvercomes,
    LiuYaoRuleIds.ruleRetreat,
  };
  static const Set<String> _l4YiLightRuleIds = <String>{
    LiuYaoRuleIds.ruleTransformsDrain,
    LiuYaoRuleIds.ruleChangedClash,
  };
  static const Set<String> _fuShenFuRuleIds = <String>{
    LiuYaoRuleIds.ruleFlightGeneratesHidden,
    LiuYaoRuleIds.ruleHiddenOvercomesFlight,
    LiuYaoRuleIds.ruleHiddenReleased,
  };
  static const Set<String> _fuShenYiRuleIds = <String>{
    LiuYaoRuleIds.ruleFlightOvercomesHidden,
    LiuYaoRuleIds.ruleHiddenGeneratesFlight,
    LiuYaoRuleIds.ruleHiddenSuppressed,
  };
  static const Set<String> _neutralRuleIds = <String>{
    LiuYaoRuleIds.ruleResting,
    LiuYaoRuleIds.ruleBindingSuppressesGeneration,
    LiuYaoRuleIds.ruleBindingSuppressesOvercoming,
    LiuYaoRuleIds.ruleGenerationSuppressesOvercoming,
    LiuYaoRuleIds.ruleOvercomesOutward,
    LiuYaoRuleIds.ruleDayClashUrges,
    LiuYaoRuleIds.ruleHiddenMoving,
  };
  static const Set<String> _suspendRuleIds = <String>{
    LiuYaoRuleIds.ruleVoid,
    LiuYaoRuleIds.ruleTrueVoid,
    LiuYaoRuleIds.ruleApparentVoid,
    LiuYaoRuleIds.ruleMonthBreak,
    LiuYaoRuleIds.ruleDayTomb,
    LiuYaoRuleIds.ruleMonthTomb,
    LiuYaoRuleIds.ruleMovingTomb,
    LiuYaoRuleIds.ruleChangedTomb,
    LiuYaoRuleIds.ruleMovingBound,
    LiuYaoRuleIds.ruleMutualBinding,
    LiuYaoRuleIds.ruleChangedVoid,
    LiuYaoRuleIds.ruleChangedBreak,
    LiuYaoRuleIds.ruleTerminal,
    LiuYaoRuleIds.ruleChangedTerminal,
  };
  static final Set<String> _directEffectRuleIds = <String>{
    ..._l2FuRuleIds,
    ..._l2YiRuleIds,
    LiuYaoRuleIds.hiddenMovingGenerates,
    LiuYaoRuleIds.hiddenMovingOvercomes,
  };

  static VerdictJudgment judge({
    required Yao yongShen,
    required bool isFuShen,
    required List<YaoAnalysisTag> yongShenTags,
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required Gua mainGua,
    Yao? changedYao,
    required LunarInfo lunarInfo,
    List<YingQiCandidate> yingQi = const <YingQiCandidate>[],
    String ruleSetVersion = LiuYaoRuleCatalog.current,
    List<DirectedEffectOccurrence> directedEffects =
        const <DirectedEffectOccurrence>[],
    List<LiuYaoRoleOccurrence> roles = const <LiuYaoRoleOccurrence>[],
    LiuYaoTraceIdFactory? traceIdFactory,
    String? targetActorId,
  }) {
    final resolvedVersion = LiuYaoRuleCatalog.resolve(ruleSetVersion).version;
    final ids = traceIdFactory ?? LiuYaoTraceIdFactory();
    final focusActorId = targetActorId ??
        (isFuShen
            ? 'hidden:host-yao:${yongShen.position}'
            : 'main:yao:${yongShen.position}');
    final tagRuleIds = <String>{
      for (final tag in yongShenTags)
        if (RuleIdentityService.resolveRuleId(tag) case final String ruleId)
          ruleId,
    };
    final factors = <VerdictFactor>[];
    var factorOrder = 0;

    void addFactor({
      required String displayRule,
      required String ruleId,
      required VerdictEffect effect,
      required String reason,
      required Iterable<String> occurrenceIds,
      required bool active,
      int? tier,
      String decisionRowId = '',
    }) {
      final upstream =
          occurrenceIds.where((id) => id.isNotEmpty).toSet().toList()..sort();
      final arbitrationTier = tier ?? _tierOf(ruleId);
      final record = LiuYaoRuleCatalog.ruleById[ruleId];
      factors.add(VerdictFactor(
        rule: displayRule,
        effect: effect,
        reason: reason,
        source: _sourceLabel(ruleId),
        factorId: ids.factor(
          factorRuleId: ruleId,
          occurrenceIds: upstream,
          arbitrationTier: arbitrationTier,
        ),
        ruleId: ruleId,
        decisionRowId: decisionRowId,
        sourceIds: record?.sourceIds ?? const <String>[],
        upstreamOccurrenceIds: upstream,
        active: active,
        arbitrationTier: arbitrationTier,
        arbitrationOrder: factorOrder++,
      ));
    }

    for (final tag in yongShenTags) {
      final ruleId = RuleIdentityService.resolveRuleId(tag);
      if (ruleId == null) continue;
      if (resolvedVersion == LiuYaoRuleCatalog.v2 &&
          directedEffects.isNotEmpty &&
          _directEffectRuleIds.contains(ruleId)) {
        continue;
      }
      final effect = _effectOfRule(ruleId, yongShen);
      if (effect == null) continue;
      addFactor(
        displayRule: tag.term,
        ruleId: ruleId,
        effect: effect,
        reason: tag.reason,
        occurrenceIds: <String>[tag.occurrenceId],
        active: tag.active,
      );
    }

    if (resolvedVersion == LiuYaoRuleCatalog.v2) {
      final relevantEffects = directedEffects
          .where((effect) =>
              effect.toActor.actorId == focusActorId &&
              _directEffectRuleIds.contains(effect.ruleId))
          .toList()
        ..sort((left, right) {
          final tier = _tierOf(left.ruleId).compareTo(_tierOf(right.ruleId));
          return tier != 0
              ? tier
              : left.occurrenceId.compareTo(right.occurrenceId);
        });
      for (final occurrence in relevantEffects) {
        final displayRule =
            LiuYaoRuleCatalog.ruleById[occurrence.ruleId]?.primaryTerm ??
                occurrence.ruleId;
        addFactor(
          displayRule: displayRule,
          ruleId: occurrence.ruleId,
          effect: switch (occurrence.effect) {
            DirectedEffectKind.sheng ||
            DirectedEffectKind.fu =>
              VerdictEffect.fu,
            DirectedEffectKind.ke => VerdictEffect.yi,
            _ => VerdictEffect.neutral,
          },
          reason: occurrence.isActive
              ? '${occurrence.fromActor.actorId}作用于${occurrence.toActor.actorId}'
              : '${occurrence.fromActor.actorId}受制，未向${occurrence.toActor.actorId}传力',
          occurrenceIds: <String>[occurrence.occurrenceId],
          active: occurrence.isActive,
          tier: occurrence.ruleId == LiuYaoRuleIds.hiddenMovingGenerates ||
                  occurrence.ruleId == LiuYaoRuleIds.hiddenMovingOvercomes
              ? 3
              : 2,
        );
      }
    }

    final activeFactors = factors.where((factor) => factor.active).toList();
    final hasFu =
        activeFactors.any((factor) => factor.effect == VerdictEffect.fu);
    final l1Fu = tagRuleIds.intersection(_l1FuRuleIds).isNotEmpty;
    final heavyYi = tagRuleIds.intersection(<String>{
      ..._l1YiRuleIds,
      ..._l4YiHeavyRuleIds,
      LiuYaoRuleIds.ruleFlightOvercomesHidden,
      LiuYaoRuleIds.ruleHiddenSuppressed,
    });
    final _Strength strength;
    if (l1Fu && heavyYi.isEmpty) {
      strength = _Strength.strong;
    } else if (heavyYi.isNotEmpty && !hasFu) {
      strength = _Strength.weak;
    } else {
      strength = _Strength.mixed;
    }

    var yuanActive = false;
    var jiActive = false;
    if (resolvedVersion == LiuYaoRuleCatalog.v2 && directedEffects.isNotEmpty) {
      final roleByActor = <String, LiuYaoRole>{
        for (final role in roles) role.actor.actorId: role.role,
      };
      final hasRoleInventory = roleByActor.isNotEmpty;
      for (final effect in directedEffects.where(
        (effect) => effect.isActive && effect.toActor.actorId == focusActorId,
      )) {
        // For a -> b -> focus paths, b is the actor that actually transmits
        // the terminal force. Changed-line return effects are intentionally not
        // inferred as yuan/ji actors when a complete role inventory exists.
        final transmitterActorId = effect.pathActorIds.length >= 2
            ? effect.pathActorIds[effect.pathActorIds.length - 2]
            : effect.fromActor.actorId;
        final role = roleByActor[transmitterActorId];
        final acceptsUnclassifiedActor = !hasRoleInventory && role == null;
        if ((effect.effect == DirectedEffectKind.sheng ||
                effect.effect == DirectedEffectKind.fu) &&
            (role == LiuYaoRole.yuanShen || acceptsUnclassifiedActor)) {
          yuanActive = true;
        }
        if (effect.effect == DirectedEffectKind.ke &&
            (role == LiuYaoRole.jiShen || acceptsUnclassifiedActor)) {
          jiActive = true;
        }
      }
    } else {
      yuanActive = tagRuleIds.intersection(_l2FuRuleIds).isNotEmpty;
      jiActive = tagRuleIds.intersection(_l2YiRuleIds).isNotEmpty;
      if (jiActive &&
          tagRuleIds.contains(
            LiuYaoRuleIds.ruleMovingOvercomes,
          )) {
        final attackers = yongShenTags
            .where((tag) =>
                RuleIdentityService.resolveRuleId(tag) ==
                LiuYaoRuleIds.ruleMovingOvercomes)
            .expand((tag) => tag.relatedYao)
            .toSet();
        final allRestrained = attackers.isNotEmpty &&
            attackers.every((position) {
              final attackerRuleIds =
                  (yaoTags[position] ?? const <YaoAnalysisTag>[])
                      .map(RuleIdentityService.resolveRuleId)
                      .whereType<String>()
                      .toSet();
              return attackerRuleIds.contains(
                    LiuYaoRuleIds.ruleReturnOvercomes,
                  ) ||
                  attackerRuleIds.contains(
                    LiuYaoRuleIds.ruleRetreat,
                  ) ||
                  attackerRuleIds.contains(
                    LiuYaoRuleIds.ruleScattered,
                  );
            });
        if (allRestrained &&
            !tagRuleIds.contains(
              LiuYaoRuleIds.ruleContinuousOvercoming,
            )) {
          jiActive = false;
          addFactor(
            displayRule: '忌神受制',
            ruleId: LiuYaoRuleIds.attackerSuppressed,
            effect: VerdictEffect.neutral,
            reason: '克用神之作用者自身受制，不能施克',
            occurrenceIds: const <String>[],
            active: true,
            tier: 5,
          );
        }
      }
    }

    final conditions = _buildConditions(
      yongShen: yongShen,
      isFuShen: isFuShen,
      tags: yongShenTags,
      tagRuleIds: tagRuleIds,
      strength: strength,
      hasFu: hasFu,
      yuanActive: yuanActive,
      changedYao: changedYao,
      ruleSetVersion: resolvedVersion,
      focusActorId: focusActorId,
      traceIdFactory: ids,
      lunarInfo: lunarInfo,
    );

    final hasNoRescue = conditions.any((condition) => !condition.hasRescue);
    final allRescuable = conditions.isNotEmpty && !hasNoRescue;
    final hasOnlyJoinCondition = conditions.isNotEmpty &&
        conditions.every((condition) =>
            condition.conditionRuleId == LiuYaoRuleIds.conditionBinding);
    final hasActiveContinuousGeneration = activeFactors.any(
        (factor) => factor.ruleId == LiuYaoRuleIds.ruleContinuousGeneration);
    final yuanTakesPriority = yuanActive &&
        (!jiActive ||
            hasActiveContinuousGeneration ||
            tagRuleIds.contains(
              LiuYaoRuleIds.ruleGenerationSuppressesOvercoming,
            ));

    final VerdictTrend trend;
    final String? nuance;
    final String decisionRowId;
    final String decisionTerm;
    if (tagRuleIds.contains(
          LiuYaoRuleIds.ruleReturnOvercomes,
        ) &&
        !l1Fu) {
      trend = VerdictTrend.nanCheng;
      nuance = '克处无生';
      decisionRowId = LiuYaoRuleIds.decisionReturnOvercomeWithoutL1Support;
      decisionTerm = '用神回头受克';
    } else if (tagRuleIds.contains(
          LiuYaoRuleIds.ruleReturnGenerates,
        ) &&
        !jiActive &&
        (conditions.isEmpty || hasOnlyJoinCondition)) {
      trend = VerdictTrend.keCheng;
      nuance = '先难后成';
      decisionRowId = LiuYaoRuleIds.decisionReturnGenerateUnblocked;
      decisionTerm = '用神回头得生';
    } else {
      switch (strength) {
        case _Strength.weak:
          if (hasNoRescue) {
            trend = VerdictTrend.nanCheng;
            nuance = '空破墓绝，到底无救';
            decisionRowId = LiuYaoRuleIds.decisionWeakUnrescuable;
            decisionTerm = '衰而无救';
          } else if (jiActive) {
            trend = VerdictTrend.nanCheng;
            nuance = '克处无生';
            decisionRowId = LiuYaoRuleIds.decisionWeakAdverseActive;
            decisionTerm = '忌神乘衰攻用';
          } else {
            trend = VerdictTrend.nanCheng;
            nuance = '衰而无助';
            decisionRowId = LiuYaoRuleIds.decisionWeakUnsupported;
            decisionTerm = '休囚无生扶';
          }
        case _Strength.strong:
          if (conditions.isEmpty && !jiActive) {
            trend = VerdictTrend.keCheng;
            nuance = null;
            decisionRowId = LiuYaoRuleIds.decisionStrongClear;
            decisionTerm = '日月生扶而无阻';
          } else if (conditions.isNotEmpty) {
            trend = VerdictTrend.daiTiaoJian;
            nuance = '成而有待';
            decisionRowId = LiuYaoRuleIds.decisionStrongWithConditions;
            decisionTerm = '旺而有待';
          } else {
            trend = VerdictTrend.daiTiaoJian;
            nuance = '吉中有阻';
            decisionRowId = LiuYaoRuleIds.decisionStrongAdverseActive;
            decisionTerm = '旺而忌动';
          }
        case _Strength.mixed:
          if (yuanTakesPriority) {
            trend = VerdictTrend.daiTiaoJian;
            nuance = '先难后成';
            decisionRowId = LiuYaoRuleIds.decisionMixedSourceContinuity;
            decisionTerm = '元神动而生用';
          } else if (jiActive) {
            trend = VerdictTrend.nanCheng;
            nuance = '抑重于扶';
            decisionRowId = LiuYaoRuleIds.decisionMixedAdverseActive;
            decisionTerm = '忌神动而克用';
          } else if (allRescuable) {
            trend = VerdictTrend.daiTiaoJian;
            nuance = '待解除后再断';
            decisionRowId = LiuYaoRuleIds.decisionMixedRescuableConditions;
            decisionTerm = '悬而未决';
          } else if (l1Fu) {
            trend = VerdictTrend.daiTiaoJian;
            nuance = '先难后成';
            decisionRowId = LiuYaoRuleIds.decisionMixedL1Support;
            decisionTerm = '克处逢生';
          } else {
            trend = VerdictTrend.buMing;
            nuance = '扶抑并见，须参断者裁';
            decisionRowId = LiuYaoRuleIds.decisionMixedUnresolved;
            decisionTerm = '扶抑并见';
          }
      }
    }

    factors.sort((left, right) {
      final tier = left.arbitrationTier.compareTo(right.arbitrationTier);
      if (tier != 0) return tier;
      final order = left.arbitrationOrder.compareTo(right.arbitrationOrder);
      return order != 0 ? order : left.factorId.compareTo(right.factorId);
    });
    addFactor(
      displayRule: '裁决·$decisionTerm',
      ruleId: decisionRowId,
      effect: VerdictEffect.neutral,
      reason: '决策表命中：${trend.name}${nuance == null ? '' : '（$nuance）'}',
      occurrenceIds: factors.expand(
        (factor) => factor.upstreamOccurrenceIds,
      ),
      active: true,
      tier: 9,
      decisionRowId: decisionRowId,
    );

    return VerdictJudgment(
      trend: trend,
      nuance: nuance,
      conditions: conditions,
      factors: factors,
      matchedDecisionRowId: decisionRowId,
      summary: _buildSummary(
        yongShen: yongShen,
        isFuShen: isFuShen,
        trend: trend,
        nuance: nuance,
        conditions: conditions,
        yingQi: yingQi,
      ),
    );
  }

  static VerdictJudgment attachTimingSummary(
    VerdictJudgment judgment,
    List<YingQiCandidate> yingQi,
  ) {
    if (yingQi.isEmpty) return judgment;
    final hint = yingQi.take(2).map((candidate) => candidate.label).join('，');
    return judgment.copyWith(summary: '${judgment.summary}；优先观察：$hint');
  }

  static List<VerdictCondition> _buildConditions({
    required Yao yongShen,
    required bool isFuShen,
    required List<YaoAnalysisTag> tags,
    required Set<String> tagRuleIds,
    required _Strength strength,
    required bool hasFu,
    required bool yuanActive,
    required String ruleSetVersion,
    required String focusActorId,
    required LiuYaoTraceIdFactory traceIdFactory,
    required LunarInfo lunarInfo,
    Yao? changedYao,
  }) {
    final conditions = <VerdictCondition>[];
    final zhi = yongShen.branch;
    final chongZhi = DiZhiRelations.getLiuChong(zhi)!;
    final muBranch = ChangShengTable.getMuBranch(yongShen.wuXing);
    final notWeak = strength != _Strength.weak;

    bool has(String ruleId) => tagRuleIds.contains(ruleId);

    List<YaoAnalysisTag> triggering(Iterable<String> ruleIds) {
      final wanted = ruleIds.toSet();
      return tags
          .where(
              (tag) => wanted.contains(RuleIdentityService.resolveRuleId(tag)))
          .toList();
    }

    void add({
      required String conditionRuleId,
      required String label,
      required String reason,
      required Iterable<String> triggeringRuleIds,
      String? branch,
      bool hasRescue = true,
    }) {
      final upstreamTags = triggering(triggeringRuleIds);
      final upstreamOccurrenceIds = upstreamTags
          .map((tag) => tag.occurrenceId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final sourceIds = <String>{
        ...LiuYaoRuleCatalog.ruleById[conditionRuleId]!.sourceIds,
        ...upstreamTags.expand((tag) => tag.sourceIds),
      }.toList()
        ..sort();
      conditions.add(VerdictCondition(
        label: label,
        branch: branch,
        reason: reason,
        hasRescue: hasRescue,
        conditionId: traceIdFactory.condition(
          conditionRuleId: conditionRuleId,
          focusActorId: focusActorId,
          upstreamOccurrenceIds: upstreamOccurrenceIds,
        ),
        conditionRuleId: conditionRuleId,
        sourceIds: sourceIds,
        upstreamOccurrenceIds: upstreamOccurrenceIds,
      ));
    }

    if (has(LiuYaoRuleIds.ruleTrueVoid)) {
      if (ruleSetVersion == LiuYaoRuleCatalog.v1Compat) {
        add(
          conditionRuleId: LiuYaoRuleIds.conditionVoid,
          label: '待出空',
          branch: zhi,
          reason: '旬空待出空填实',
          hasRescue: notWeak,
          triggeringRuleIds: const <String>[
            LiuYaoRuleIds.ruleTrueVoid,
            LiuYaoRuleIds.ruleVoid,
          ],
        );
      } else {
        add(
          conditionRuleId: LiuYaoRuleIds.conditionTrueVoid,
          label: '真空到底无用',
          branch: zhi,
          reason: '休囚安静逢空为真空，到底无用',
          hasRescue: false,
          triggeringRuleIds: const <String>[
            LiuYaoRuleIds.ruleTrueVoid,
            LiuYaoRuleIds.ruleVoid,
          ],
        );
      }
    } else if (has(LiuYaoRuleIds.ruleVoid)) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionVoid,
        label: '待出空',
        branch: zhi,
        reason:
            has(LiuYaoRuleIds.ruleVoidClashed) ? '旬空已逢冲空，仍待出空填实' : '旬空待出空填实',
        triggeringRuleIds: const <String>[
          LiuYaoRuleIds.ruleVoid,
          LiuYaoRuleIds.ruleVoidClashed,
        ],
      );
    }
    if (has(LiuYaoRuleIds.ruleMonthBreak)) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionMonthBreak,
        label: '待出月',
        branch: zhi,
        reason: '月破待出月、填实或逢合解破',
        hasRescue: notWeak,
        triggeringRuleIds: const <String>[LiuYaoRuleIds.ruleMonthBreak],
      );
    }
    final inMu = has(LiuYaoRuleIds.ruleDayTomb) ||
        has(LiuYaoRuleIds.ruleMonthTomb) ||
        has(LiuYaoRuleIds.ruleMovingTomb);
    if (inMu && !has(LiuYaoRuleIds.ruleTombOpened)) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionTomb,
        label: '待冲开墓库',
        branch: DiZhiRelations.getLiuChong(muBranch),
        reason: '入墓待冲开墓库$muBranch之日',
        triggeringRuleIds: const <String>[
          LiuYaoRuleIds.ruleDayTomb,
          LiuYaoRuleIds.ruleMonthTomb,
          LiuYaoRuleIds.ruleMovingTomb,
        ],
      );
    }
    if (has(LiuYaoRuleIds.ruleChangedTomb)) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionChangedTomb,
        label: '待冲开化墓',
        branch: DiZhiRelations.getLiuChong(muBranch),
        reason: '动而化墓，待冲开墓库$muBranch',
        triggeringRuleIds: const <String>[LiuYaoRuleIds.ruleChangedTomb],
      );
    }
    final held = has(LiuYaoRuleIds.ruleMovingBound) ||
        has(LiuYaoRuleIds.ruleMutualBinding) ||
        (yongShen.isMoving &&
            (has(LiuYaoRuleIds.ruleDayJoins) ||
                has(LiuYaoRuleIds.ruleMonthJoins)));
    final bindingStillClosed = ruleSetVersion == LiuYaoRuleCatalog.v1Compat
        ? held && !has(LiuYaoRuleIds.ruleBindingOpened)
        : ActorAvailabilityService.isBindingClosed(
            actor: isFuShen
                ? ActorAvailabilityService.hiddenActor(yongShen)
                : ActorAvailabilityService.mainActor(yongShen),
            tags: tags,
            lunarInfo: lunarInfo,
          );
    if (bindingStillClosed) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionBinding,
        label: '待冲开',
        branch: chongZhi,
        reason: '合住则绊，待冲开之日用神方能施为',
        triggeringRuleIds: const <String>[
          LiuYaoRuleIds.ruleMovingBound,
          LiuYaoRuleIds.ruleMutualBinding,
          LiuYaoRuleIds.ruleDayJoins,
          LiuYaoRuleIds.ruleMonthJoins,
        ],
      );
    }
    if (has(LiuYaoRuleIds.ruleChangedVoid) && changedYao != null) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionChangedVoid,
        label: '待变爻填实',
        branch: changedYao.branch,
        reason: '动而化空，变爻${changedYao.branch}出空填实之日应之',
        triggeringRuleIds: const <String>[LiuYaoRuleIds.ruleChangedVoid],
      );
    }
    if (has(LiuYaoRuleIds.ruleChangedBreak) && changedYao != null) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionChangedBreak,
        label: '待变爻出月填实',
        branch: changedYao.branch,
        reason: '动而化破，变爻${changedYao.branch}出月或填实应之',
        triggeringRuleIds: const <String>[LiuYaoRuleIds.ruleChangedBreak],
      );
    }
    if (has(LiuYaoRuleIds.ruleTerminal) ||
        has(LiuYaoRuleIds.ruleChangedTerminal)) {
      add(
        conditionRuleId: LiuYaoRuleIds.conditionTerminal,
        label: '待长生扶起',
        branch: ChangShengTable.getChangShengBranch(yongShen.wuXing),
        reason: '临绝待长生之日，绝处逢生',
        hasRescue: hasFu || yuanActive,
        triggeringRuleIds: const <String>[
          LiuYaoRuleIds.ruleTerminal,
          LiuYaoRuleIds.ruleChangedTerminal,
        ],
      );
    }
    if (isFuShen) {
      final released = has(LiuYaoRuleIds.ruleHiddenReleased);
      final suppressed = (has(LiuYaoRuleIds.ruleFlightOvercomesHidden) ||
              has(LiuYaoRuleIds.ruleHiddenSuppressed)) &&
          !released;
      if (ruleSetVersion == LiuYaoRuleCatalog.v1Compat) {
        add(
          conditionRuleId: LiuYaoRuleIds.conditionHiddenRelease,
          label: '待出伏',
          branch: zhi,
          reason: released ? '伏神已有得出之象，仍待值日引出' : '用神不现，待伏神值日或冲飞之日引出',
          hasRescue: !suppressed,
          triggeringRuleIds: const <String>[
            LiuYaoRuleIds.ruleSelectedHiddenUseSpirit,
            LiuYaoRuleIds.ruleFlightOvercomesHidden,
            LiuYaoRuleIds.ruleHiddenSuppressed,
            LiuYaoRuleIds.ruleHiddenReleased,
          ],
        );
      } else if (!released) {
        add(
          conditionRuleId: suppressed
              ? LiuYaoRuleIds.conditionHiddenSuppressed
              : LiuYaoRuleIds.conditionHiddenRelease,
          label: suppressed ? '伏神受制无解' : '待出伏',
          branch: zhi,
          reason: suppressed ? '伏神受飞神及日月压制，当前无可执行的释放路径' : '用神不现，待伏神值日或冲飞之日引出',
          hasRescue: !suppressed,
          triggeringRuleIds: const <String>[
            LiuYaoRuleIds.ruleSelectedHiddenUseSpirit,
            LiuYaoRuleIds.ruleFlightOvercomesHidden,
            LiuYaoRuleIds.ruleHiddenSuppressed,
          ],
        );
      }
    }
    return conditions;
  }

  static VerdictEffect? _effectOfRule(String ruleId, Yao yongShen) {
    if (_suspendRuleIds.contains(ruleId)) return VerdictEffect.suspend;
    if (_l1FuRuleIds.contains(ruleId) ||
        _l2FuRuleIds.contains(ruleId) ||
        _l4FuRuleIds.contains(ruleId) ||
        _fuShenFuRuleIds.contains(ruleId)) {
      return VerdictEffect.fu;
    }
    if (ruleId == LiuYaoRuleIds.ruleDayJoins ||
        ruleId == LiuYaoRuleIds.ruleMonthJoins) {
      return yongShen.isMoving ? VerdictEffect.suspend : VerdictEffect.fu;
    }
    if (_l1YiRuleIds.contains(ruleId) ||
        _l2YiRuleIds.contains(ruleId) ||
        _l4YiHeavyRuleIds.contains(ruleId) ||
        _l4YiLightRuleIds.contains(ruleId) ||
        _fuShenYiRuleIds.contains(ruleId)) {
      return VerdictEffect.yi;
    }
    if (_neutralRuleIds.contains(ruleId)) return VerdictEffect.neutral;
    return null;
  }

  static int _tierOf(String ruleId) {
    if (_l1FuRuleIds.contains(ruleId) || _l1YiRuleIds.contains(ruleId)) {
      return 1;
    }
    if (_l2FuRuleIds.contains(ruleId) || _l2YiRuleIds.contains(ruleId)) {
      return 2;
    }
    if (ruleId == LiuYaoRuleIds.hiddenMovingGenerates ||
        ruleId == LiuYaoRuleIds.hiddenMovingOvercomes) {
      return 3;
    }
    if (_l4FuRuleIds.contains(ruleId) ||
        _l4YiHeavyRuleIds.contains(ruleId) ||
        _l4YiLightRuleIds.contains(ruleId)) {
      return 4;
    }
    return 5;
  }

  static String _sourceLabel(String ruleId) {
    final sources =
        LiuYaoRuleCatalog.ruleById[ruleId]?.sourceIds ?? const <String>[];
    if (sources.contains(LiuYaoRuleIds.projectSource)) {
      return '项目约定·六爻分析合同';
    }
    if (sources.contains(LiuYaoRuleIds.buShiSource)) {
      return '《卜筮正宗》候选定位';
    }
    return '《增删卜易》';
  }

  static String _buildSummary({
    required Yao yongShen,
    required bool isFuShen,
    required VerdictTrend trend,
    required String? nuance,
    required List<VerdictCondition> conditions,
    required List<YingQiCandidate> yingQi,
  }) {
    final description = '${yongShen.liuQin.name}${yongShen.branch}'
        '${yongShen.wuXing.name}${isFuShen ? '（伏）' : ''}';
    final conditionText =
        conditions.take(2).map((condition) => condition.label).join('、');
    final timingHint = yingQi.isEmpty
        ? ''
        : '；优先观察：${yingQi.take(2).map((candidate) => candidate.label).join('，')}';
    return '用神$description，断曰：${trend.name}${nuance == null ? '' : '（$nuance）'}。'
        '${conditionText.isEmpty ? '' : '未决条件：$conditionText。'}'
        '应期候选仅表示条件触发窗口，不单独决定事情成败$timingHint';
  }
}
