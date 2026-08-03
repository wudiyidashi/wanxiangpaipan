import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../fushen_service.dart';
import '../../gua_calculator.dart';
import 'actor_availability_service.dart';
import 'dong_bian_service.dart';
import 'fu_shen_relation_service.dart';
import 'gua_change_service.dart';
import 'he_chong_service.dart';
import 'kong_wang_service.dart';
import 'liu_qin_deduce_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'models/analysis_trace.dart';
import 'models/liuyao_rule_models.dart';
import 'mu_jue_service.dart';
import 'rule_identity_service.dart';
import 'rules/liuyao_catalog.dart';
import 'rules/liuyao_trace_id_factory.dart';
import 'sheng_ke_service.dart';
import 'special_service.dart';
import 'verdict_service.dart';
import 'wang_shuai_service.dart';
import 'ying_qi_service.dart';

/// The single analysis orchestration boundary for Liuyao.
class LiuYaoAnalyzer {
  LiuYaoAnalyzer._();

  static AnalysisReport analyze(
    Gua mainGua,
    Gua? changingGua,
    LunarInfo lunarInfo, {
    int? yongShenPosition,
    bool yongShenIsFuShen = false,
    String ruleSetVersion = LiuYaoRuleCatalog.current,
  }) {
    final ruleSet = LiuYaoRuleCatalog.resolve(ruleSetVersion);
    LiuYaoRuleCatalog.validateOrThrow();
    final inputDiagnostic = _validateInput(
      mainGua,
      changingGua,
      yongShenPosition,
      yongShenIsFuShen,
    );
    if (inputDiagnostic != null) {
      return AnalysisReport(
        analysisSchemaVersion: ruleSet.version == LiuYaoRuleCatalog.v3 ? 2 : 1,
        ruleSetId: ruleSet.ruleSetId,
        ruleSetVersion: ruleSet.version,
        sourceCatalogVersion: ruleSet.sourceCatalogVersion,
        status: LiuYaoAnalysisStatus.invalid,
        diagnostics: <String>[inputDiagnostic],
        yaoTags: const <int, List<YaoAnalysisTag>>{},
        trace: const <LiuYaoAnalysisTraceStep>[
          LiuYaoAnalysisTraceStep(
            stageId: LiuYaoAnalysisStages.validateInput,
            notes: <String>['invalid'],
          ),
        ],
      );
    }

    final traceIds = LiuYaoTraceIdFactory();
    final yaoTags = <int, List<YaoAnalysisTag>>{
      for (final yao in mainGua.yaos) yao.position: <YaoAnalysisTag>[],
    };

    for (final yao in mainGua.yaos) {
      yaoTags[yao.position]!
        ..addAll(WangShuaiService.analyzeYao(yao, lunarInfo))
        ..addAll(KongWangService.analyzeYao(yao, mainGua, lunarInfo))
        ..addAll(MuJueService.analyzeYao(yao, mainGua, lunarInfo))
        ..addAll(SpecialService.analyzeYao(yao, lunarInfo));
    }
    _merge(yaoTags, HeChongService.analyzeGua(mainGua, lunarInfo));
    _merge(
      yaoTags,
      DongBianService.analyzeGua(mainGua, changingGua, lunarInfo),
    );
    _merge(
      yaoTags,
      FuShenRelationService.analyzeGua(mainGua, lunarInfo),
    );

    YongShenChain? chain;
    List<LiuYaoRoleOccurrence> roles = const <LiuYaoRoleOccurrence>[];
    if (yongShenPosition != null) {
      chain = LiuQinDeduceService.deduce(
        mainGua,
        yongShenPosition,
        isFuShen: yongShenIsFuShen,
      );
      roles = LiuQinDeduceService.deduceRoleOccurrences(
        mainGua,
        yongShenPosition,
        isFuShen: yongShenIsFuShen,
      );
      _addChainTags(yaoTags, chain);
    }

    _bindPositionTags(yaoTags, traceIds);
    final actorTags = ruleSet.version == LiuYaoRuleCatalog.v3
        ? _buildV3ActorTags(
            mainGua: mainGua,
            changingGua: changingGua,
            lunarInfo: lunarInfo,
            yaoTags: yaoTags,
            traceIdFactory: traceIds,
          )
        : const <String, List<YaoAnalysisTag>>{};
    var actorAvailability = ruleSet.version == LiuYaoRuleCatalog.v3
        ? _evaluateV3ActorAvailability(
            mainGua: mainGua,
            changingGua: changingGua,
            lunarInfo: lunarInfo,
            actorTags: actorTags,
          )
        : ActorAvailabilityService.evaluateGua(
            mainGua: mainGua,
            changingGua: changingGua,
            lunarInfo: lunarInfo,
            yaoTags: yaoTags,
            ruleSetVersion: ruleSet.version,
          );

    final directedEffects = <DirectedEffectOccurrence>[];
    if (ruleSet.version == LiuYaoRuleCatalog.v1Compat) {
      final legacyShengKe = ShengKeService.analyzeGua(mainGua, lunarInfo);
      _bindPositionTags(legacyShengKe, traceIds);
      _merge(yaoTags, legacyShengKe);
    } else {
      final shengKe = ShengKeService.analyzeDirected(
        gua: mainGua,
        lunarInfo: lunarInfo,
        baseTags: yaoTags,
        actorAvailability: actorAvailability,
        traceIdFactory: traceIds,
        ruleSetVersion: ruleSet.version,
      );
      _merge(yaoTags, shengKe.tags);
      directedEffects.addAll(shengKe.effects);
      directedEffects.addAll(_buildTransformationEffects(
        mainGua: mainGua,
        changingGua: changingGua,
        yaoTags: yaoTags,
        traceIdFactory: traceIds,
        ruleSetVersion: ruleSet.version,
      ));
      actorAvailability = _linkAvailabilitySuppressors(
        actorAvailability,
        directedEffects,
        yaoTags,
      );
    }

    final guaTags = GuaChangeService.analyzeGua(
      mainGua,
      changingGua,
      ruleSetVersion: ruleSet.version,
    )
        .map((tag) => RuleIdentityService.bindTag(
              tag: tag,
              stageId: _stageIdFor(tag),
              subjectRef: 'main:gua',
              traceIdFactory: traceIds,
            ))
        .toList();

    List<YaoAnalysisTag> selectedYongShenTags = const <YaoAnalysisTag>[];
    List<YingQiCandidate>? yingQi;
    VerdictJudgment? judgment;
    if (yongShenPosition != null) {
      final yongShenYao = yongShenIsFuShen
          ? FuShenService.calculateFuShen(mainGua)[yongShenPosition]!.yao
          : mainGua.yaos[yongShenPosition - 1];
      final targetActor = yongShenIsFuShen
          ? ActorAvailabilityService.hiddenActor(yongShenYao)
          : ActorAvailabilityService.mainActor(yongShenYao);
      selectedYongShenTags = yongShenIsFuShen
          ? _analyzeFuShenYongShen(
              yongShenYao,
              mainGua,
              lunarInfo,
              yaoTags[yongShenPosition]!,
              traceIds,
            )
          : List<YaoAnalysisTag>.from(yaoTags[yongShenPosition]!);
      selectedYongShenTags.sort(_compareTags);
      if (yongShenIsFuShen) {
        actorAvailability = <ActorAvailability>[
          ...actorAvailability.where(
            (availability) => availability.actor.actorId != targetActor.actorId,
          ),
          ActorAvailabilityService.evaluateActor(
            actor: targetActor,
            tags: selectedYongShenTags,
            lunarInfo: lunarInfo,
            ruleSetVersion: ruleSet.version,
          ),
        ];
      }
      final changedYao = yongShenYao.isMoving && changingGua != null
          ? changingGua.yaos[yongShenPosition - 1]
          : null;

      if (ruleSet.version == LiuYaoRuleCatalog.v1Compat) {
        yingQi = YingQiService.calculate(
          yongShen: yongShenYao,
          changedYao: changedYao,
          yongShenTags: selectedYongShenTags,
          lunarInfo: lunarInfo,
          ruleSetVersion: ruleSet.version,
        );
        judgment = VerdictService.judge(
          yongShen: yongShenYao,
          isFuShen: yongShenIsFuShen,
          yongShenTags: selectedYongShenTags,
          yaoTags: yaoTags,
          mainGua: mainGua,
          changedYao: changedYao,
          lunarInfo: lunarInfo,
          yingQi: yingQi,
          ruleSetVersion: ruleSet.version,
          traceIdFactory: traceIds,
          targetActorId: targetActor.actorId,
        );
      } else {
        judgment = VerdictService.judge(
          yongShen: yongShenYao,
          isFuShen: yongShenIsFuShen,
          yongShenTags: selectedYongShenTags,
          yaoTags: yaoTags,
          mainGua: mainGua,
          changedYao: changedYao,
          lunarInfo: lunarInfo,
          ruleSetVersion: ruleSet.version,
          directedEffects: directedEffects,
          roles: roles,
          traceIdFactory: traceIds,
          targetActorId: targetActor.actorId,
        );
        yingQi = YingQiService.calculate(
          yongShen: yongShenYao,
          changedYao: changedYao,
          conditions: judgment.conditions,
          selectedActor: targetActor,
          hiddenFlightBranch: yongShenIsFuShen
              ? mainGua.yaos[yongShenPosition - 1].branch
              : null,
          lunarInfo: lunarInfo,
          ruleSetVersion: ruleSet.version,
          traceIdFactory: traceIds,
        );
        judgment = VerdictService.attachTimingSummary(judgment, yingQi);
      }
    }

    for (final tags in yaoTags.values) {
      tags.sort(_compareTags);
      for (final tag in tags) {
        if (tag.ruleId.isEmpty || tag.occurrenceId.isEmpty) {
          throw StateError('Unbound Liuyao production tag: ${tag.term}');
        }
      }
    }
    yaoTags.removeWhere((_, tags) => tags.isEmpty);

    _validateProvenanceClosure(
      ruleSetVersion: ruleSet.version,
      yaoTags: yaoTags,
      actorTags: actorTags,
      guaTags: guaTags,
      yongShenTags: selectedYongShenTags,
      actorAvailability: actorAvailability,
      directedEffects: directedEffects,
      judgment: judgment,
      yingQi: yingQi,
    );

    final trace = _buildTrace(
      yaoTags: yaoTags,
      actorTags: actorTags,
      guaTags: guaTags,
      yongShenTags: selectedYongShenTags,
      directedEffects: directedEffects,
      judgment: judgment,
      yingQi: yingQi,
    );
    final usedSourceIds = <String>{
      ...yaoTags.values.expand((tags) => tags).expand((tag) => tag.sourceIds),
      ...actorTags.values.expand((tags) => tags).expand((tag) => tag.sourceIds),
      ...guaTags.expand((tag) => tag.sourceIds),
      ...directedEffects.expand((effect) => effect.sourceIds),
      ...?judgment?.factors.expand((factor) => factor.sourceIds),
      ...?judgment?.conditions.expand((condition) => condition.sourceIds),
      ...?yingQi?.expand((candidate) => candidate.sourceIds),
    }.toList()
      ..sort();

    return AnalysisReport(
      analysisSchemaVersion: ruleSet.version == LiuYaoRuleCatalog.v3 ? 2 : 1,
      ruleSetId: ruleSet.ruleSetId,
      ruleSetVersion: ruleSet.version,
      sourceCatalogVersion: ruleSet.sourceCatalogVersion,
      yaoTags: yaoTags,
      guaTags: guaTags,
      yongShen: chain,
      yongShenTags: selectedYongShenTags,
      yingQi: yingQi,
      verdictSummary: judgment?.summary,
      judgment: judgment,
      roles: roles,
      actorTags: actorTags,
      actorAvailability: actorAvailability,
      directedEffects: directedEffects,
      trace: trace,
      usedSourceIds: usedSourceIds,
    );
  }

  static String? _validateInput(
    Gua mainGua,
    Gua? changingGua,
    int? yongShenPosition,
    bool yongShenIsFuShen,
  ) {
    if (mainGua.yaos.length != 6 ||
        List.generate(6, (index) => index + 1).any(
            (position) => mainGua.yaos[position - 1].position != position)) {
      return 'invalidMainGuaYaoOrder';
    }
    final expectedChangingGua = GuaCalculator.generateChangingGua(mainGua);
    if (expectedChangingGua != null && changingGua == null) {
      return 'missingChangingGua';
    }
    if (expectedChangingGua == null && changingGua != null) {
      return 'unexpectedChangingGua';
    }
    if (changingGua != null && changingGua.yaos.length != 6) {
      return 'invalidChangingGuaYaoCount';
    }
    if (changingGua != null &&
        List.generate(6, (index) => index + 1).any((position) =>
            changingGua.yaos[position - 1].position != position)) {
      return 'invalidChangingGuaYaoOrder';
    }
    if (changingGua != null && changingGua != expectedChangingGua) {
      return 'changingGuaDoesNotCorrespond';
    }
    if (yongShenPosition != null &&
        (yongShenPosition < 1 || yongShenPosition > 6)) {
      return 'invalidYongShenPosition';
    }
    if (yongShenIsFuShen && yongShenPosition == null) {
      return 'hiddenYongShenRequiresPosition';
    }
    if (yongShenIsFuShen &&
        !FuShenService.calculateFuShen(mainGua).containsKey(yongShenPosition)) {
      return 'selectedHiddenYongShenDoesNotExist';
    }
    return null;
  }

  static List<YaoAnalysisTag> _analyzeFuShenYongShen(
    Yao fuShen,
    Gua mainGua,
    LunarInfo lunarInfo,
    List<YaoAnalysisTag> positionTags,
    LiuYaoTraceIdFactory traceIdFactory,
  ) {
    final rawTags = <YaoAnalysisTag>[
      ...WangShuaiService.analyzeYao(fuShen, lunarInfo),
      ...KongWangService.analyzeYao(fuShen, mainGua, lunarInfo),
      ...MuJueService.analyzeYao(fuShen, mainGua, lunarInfo),
      ...SpecialService.analyzeYao(fuShen, lunarInfo),
      ...positionTags
          .where(
            (tag) =>
                tag.category == TagCategory.fuShen ||
                (tag.category == TagCategory.liuQin &&
                    tag.relatedYao.isEmpty &&
                    RuleIdentityService.resolveRuleId(tag) ==
                        LiuYaoRuleIds.ruleSelectedHiddenUseSpirit),
          )
          .map((tag) => tag.copyWith(occurrenceId: '')),
    ];
    return rawTags
        .map((tag) => RuleIdentityService.bindTag(
              tag: tag,
              stageId: _stageIdFor(tag),
              subjectRef: 'hidden:host-yao:${fuShen.position}',
              traceIdFactory: traceIdFactory,
            ))
        .toList();
  }

  static Map<String, List<YaoAnalysisTag>> _buildV3ActorTags({
    required Gua mainGua,
    required Gua? changingGua,
    required LunarInfo lunarInfo,
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required LiuYaoTraceIdFactory traceIdFactory,
  }) {
    List<YaoAnalysisTag> bindActorTags(
      Iterable<YaoAnalysisTag> rawTags,
      String actorId,
    ) {
      final tags = rawTags
          .map((tag) => RuleIdentityService.bindTag(
                tag: tag.copyWith(occurrenceId: ''),
                stageId: _stageIdFor(tag),
                subjectRef: actorId,
                traceIdFactory: traceIdFactory,
              ))
          .toList()
        ..sort(_compareTags);
      return List<YaoAnalysisTag>.unmodifiable(tags);
    }

    List<YaoAnalysisTag> intrinsicTags(Yao yao) => <YaoAnalysisTag>[
          ...WangShuaiService.analyzeYao(yao, lunarInfo),
          ...KongWangService.analyzeYao(yao, mainGua, lunarInfo),
          ...MuJueService.analyzeYao(yao, mainGua, lunarInfo),
          ...SpecialService.analyzeYao(yao, lunarInfo),
        ];

    final result = <String, List<YaoAnalysisTag>>{};
    for (final yao in mainGua.yaos) {
      final actor = ActorAvailabilityService.mainActor(yao);
      result[actor.actorId] = List<YaoAnalysisTag>.unmodifiable(
        (yaoTags[yao.position] ?? const <YaoAnalysisTag>[])
            .where((tag) => tag.category != TagCategory.fuShen),
      );
    }

    if (changingGua != null) {
      for (final original in mainGua.movingYaos) {
        final changed = changingGua.yaos[original.position - 1];
        final actor = ActorAvailabilityService.changedActor(changed);
        // A changed branch is produced by a moving line. Preserve that motion
        // for void and day/month binding classification without changing its
        // branch, stem, relation, or polarity in the projected actor.
        final changedStateYao = changed.copyWith(number: original.number);
        result[actor.actorId] = bindActorTags(
          <YaoAnalysisTag>[
            ...intrinsicTags(changedStateYao),
            ...(yaoTags[original.position] ?? const <YaoAnalysisTag>[])
                .where((tag) => tag.category == TagCategory.dongBian),
          ],
          actor.actorId,
        );
      }
    }

    final hidden = FuShenService.calculateFuShen(mainGua).entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in hidden) {
      final hiddenYao = entry.value.yao;
      final actor = ActorAvailabilityService.hiddenActor(hiddenYao);
      result[actor.actorId] = bindActorTags(
        <YaoAnalysisTag>[
          ...intrinsicTags(hiddenYao),
          ...(yaoTags[entry.key] ?? const <YaoAnalysisTag>[])
              .where((tag) => tag.category == TagCategory.fuShen),
        ],
        actor.actorId,
      );
    }
    return Map<String, List<YaoAnalysisTag>>.unmodifiable(result);
  }

  static List<ActorAvailability> _evaluateV3ActorAvailability({
    required Gua mainGua,
    required Gua? changingGua,
    required LunarInfo lunarInfo,
    required Map<String, List<YaoAnalysisTag>> actorTags,
  }) {
    ActorAvailability evaluate(LiuYaoActorRef actor) =>
        ActorAvailabilityService.evaluateActor(
          actor: actor,
          tags: actorTags[actor.actorId] ?? const <YaoAnalysisTag>[],
          lunarInfo: lunarInfo,
          ruleSetVersion: LiuYaoRuleCatalog.v3,
        );

    final result = <ActorAvailability>[
      for (final yao in mainGua.yaos)
        evaluate(ActorAvailabilityService.mainActor(yao)),
    ];
    if (changingGua != null) {
      for (final original in mainGua.movingYaos) {
        result.add(evaluate(ActorAvailabilityService.changedActor(
          changingGua.yaos[original.position - 1],
        )));
      }
    }
    final hidden = FuShenService.calculateFuShen(mainGua).entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in hidden) {
      result
          .add(evaluate(ActorAvailabilityService.hiddenActor(entry.value.yao)));
    }
    result
      ..add(ActorAvailability(
        actor: ActorAvailabilityService.calendarActor(
          kind: LiuYaoActorKind.calendarDay,
          branch: lunarInfo.riZhi,
        ),
        state: ActorAvailabilityState.active,
        reasonRuleIds: const <String>[],
      ))
      ..add(ActorAvailability(
        actor: ActorAvailabilityService.calendarActor(
          kind: LiuYaoActorKind.calendarMonth,
          branch: lunarInfo.yueJian,
        ),
        state: ActorAvailabilityState.active,
        reasonRuleIds: const <String>[],
      ));
    return List<ActorAvailability>.unmodifiable(result);
  }

  static List<DirectedEffectOccurrence> _buildTransformationEffects({
    required Gua mainGua,
    required Gua? changingGua,
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required LiuYaoTraceIdFactory traceIdFactory,
    required String ruleSetVersion,
  }) {
    if (changingGua == null) return const <DirectedEffectOccurrence>[];
    final effects = <DirectedEffectOccurrence>[];
    for (final original in mainGua.movingYaos) {
      final changed = changingGua.yaos[original.position - 1];
      final mainActor = ActorAvailabilityService.mainActor(original);
      final changedActor = ActorAvailabilityService.changedActor(changed);
      for (final tag
          in yaoTags[original.position] ?? const <YaoAnalysisTag>[]) {
        final ruleId = RuleIdentityService.resolveRuleId(tag);
        final DirectedEffectKind? effect = switch (ruleId) {
          LiuYaoRuleIds.ruleReturnGenerates => DirectedEffectKind.sheng,
          LiuYaoRuleIds.ruleReturnOvercomes => DirectedEffectKind.ke,
          LiuYaoRuleIds.ruleTransformsDrain => DirectedEffectKind.xie,
          LiuYaoRuleIds.ruleOvercomesOutward => DirectedEffectKind.hao,
          LiuYaoRuleIds.ruleChangedJoin => DirectedEffectKind.he,
          LiuYaoRuleIds.ruleChangedClash => DirectedEffectKind.chong,
          LiuYaoRuleIds.ruleRetreat ||
          LiuYaoRuleIds.ruleChangedVoid ||
          LiuYaoRuleIds.ruleChangedBreak ||
          LiuYaoRuleIds.ruleChangedTomb ||
          LiuYaoRuleIds.ruleChangedTerminal
              when ruleSetVersion == LiuYaoRuleCatalog.v3 =>
            DirectedEffectKind.restrict,
          _ => null,
        };
        if (effect == null) continue;
        final returns = ruleId == LiuYaoRuleIds.ruleReturnGenerates ||
            ruleId == LiuYaoRuleIds.ruleReturnOvercomes ||
            ruleId == LiuYaoRuleIds.ruleChangedJoin ||
            ruleId == LiuYaoRuleIds.ruleChangedClash ||
            effect == DirectedEffectKind.restrict;
        final fromActor = returns ? changedActor : mainActor;
        final toActor = returns ? mainActor : changedActor;
        effects.add(DirectedEffectOccurrence(
          occurrenceId: traceIdFactory.occurrence(
            stageId: LiuYaoAnalysisStages.calculateEffects,
            ruleId: tag.ruleId,
            subjectRef: toActor.actorId,
            fromActorId: fromActor.actorId,
            toActorId: toActor.actorId,
            pathStep: 0,
          ),
          ruleId: tag.ruleId,
          fromActor: fromActor,
          toActor: toActor,
          effect: effect,
          status: DirectedEffectStatus.active,
          pathActorIds: <String>[fromActor.actorId, toActor.actorId],
          pathStep: 0,
          sourceIds: tag.sourceIds,
          phase: ruleSetVersion == LiuYaoRuleCatalog.v3
              ? ruleId == LiuYaoRuleIds.ruleChangedTerminal
                  ? DirectedEffectPhase.finalState
                  : DirectedEffectPhase.laterProcess
              : DirectedEffectPhase.formation,
          horizon: ruleSetVersion == LiuYaoRuleCatalog.v3
              ? ruleId == LiuYaoRuleIds.ruleChangedTerminal
                  ? DirectedEffectHorizon.terminal
                  : DirectedEffectHorizon.subsequent
              : DirectedEffectHorizon.immediate,
          inputRefs: <String>[
            'mainGua.yaos[${original.position}]',
            'changingGua.yaos[${changed.position}]',
          ],
        ));
      }
    }
    return effects;
  }

  static List<ActorAvailability> _linkAvailabilitySuppressors(
    List<ActorAvailability> availability,
    List<DirectedEffectOccurrence> effects,
    Map<int, List<YaoAnalysisTag>> yaoTags,
  ) {
    return <ActorAvailability>[
      for (final entry in availability)
        if (entry.canTransmit)
          entry
        else
          ActorAvailability(
            actor: entry.actor,
            state: entry.state,
            reasonRuleIds: entry.reasonRuleIds,
            releaseConditionRuleIds: entry.releaseConditionRuleIds,
            suppressedByOccurrenceIds: <String>{
              ...entry.suppressedByOccurrenceIds,
              ...effects
                  .where(
                      (effect) => effect.toActor.actorId == entry.actor.actorId)
                  .where(
                      (effect) => entry.reasonRuleIds.contains(effect.ruleId))
                  .map((effect) => effect.occurrenceId),
              if (entry.actor.position case final int position)
                ...(yaoTags[position] ?? const <YaoAnalysisTag>[])
                    .where((tag) => entry.reasonRuleIds.contains(tag.ruleId))
                    .map((tag) => tag.occurrenceId),
            }.where((id) => id.isNotEmpty).toList()
              ..sort(),
          ),
    ];
  }

  static void _bindPositionTags(
    Map<int, List<YaoAnalysisTag>> tagsByPosition,
    LiuYaoTraceIdFactory traceIdFactory,
  ) {
    for (final entry in tagsByPosition.entries) {
      final subjectRef = 'main:yao:${entry.key}';
      for (var index = 0; index < entry.value.length; index++) {
        final tag = entry.value[index];
        entry.value[index] = RuleIdentityService.bindTag(
          tag: tag,
          stageId: _stageIdFor(tag),
          subjectRef: subjectRef,
          traceIdFactory: traceIdFactory,
        );
      }
    }
  }

  static String _stageIdFor(YaoAnalysisTag tag) {
    final ruleId = RuleIdentityService.resolveRuleId(tag);
    final stage =
        ruleId == null ? null : LiuYaoRuleCatalog.ruleById[ruleId]?.stage;
    return switch (stage) {
      LiuYaoRuleStage.input => LiuYaoAnalysisStages.validateInput,
      LiuYaoRuleStage.facts => LiuYaoAnalysisStages.freezeFacts,
      LiuYaoRuleStage.roles => LiuYaoAnalysisStages.buildRoles,
      LiuYaoRuleStage.state => LiuYaoAnalysisStages.calculateState,
      LiuYaoRuleStage.availability =>
        LiuYaoAnalysisStages.calculateAvailability,
      LiuYaoRuleStage.effects => LiuYaoAnalysisStages.calculateEffects,
      LiuYaoRuleStage.auxiliary => LiuYaoAnalysisStages.auxiliaryEvidence,
      LiuYaoRuleStage.conflict => LiuYaoAnalysisStages.arbitrateConflicts,
      LiuYaoRuleStage.verdict => LiuYaoAnalysisStages.judgeVerdict,
      LiuYaoRuleStage.condition => LiuYaoAnalysisStages.judgeVerdict,
      LiuYaoRuleStage.timing => LiuYaoAnalysisStages.calculateTiming,
      null => throw StateError('Unknown tag stage: ${tag.term}'),
    };
  }

  static List<LiuYaoAnalysisTraceStep> _buildTrace({
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required Map<String, List<YaoAnalysisTag>> actorTags,
    required List<YaoAnalysisTag> guaTags,
    required List<YaoAnalysisTag> yongShenTags,
    required List<DirectedEffectOccurrence> directedEffects,
    required VerdictJudgment? judgment,
    required List<YingQiCandidate>? yingQi,
  }) {
    final occurrencesByStage = <String, Set<String>>{
      for (final stage in LiuYaoAnalysisStages.ordered) stage: <String>{},
    };
    final rulesByStage = <String, Set<String>>{
      for (final stage in LiuYaoAnalysisStages.ordered) stage: <String>{},
    };
    for (final tag in <YaoAnalysisTag>[
      ...yaoTags.values.expand((tags) => tags),
      ...actorTags.values.expand((tags) => tags),
      ...guaTags,
      ...yongShenTags,
    ]) {
      final stage = _stageIdFor(tag);
      occurrencesByStage[stage]!.add(tag.occurrenceId);
      rulesByStage[stage]!.add(tag.ruleId);
    }
    for (final effect in directedEffects) {
      occurrencesByStage[LiuYaoAnalysisStages.calculateEffects]!
          .add(effect.occurrenceId);
      rulesByStage[LiuYaoAnalysisStages.calculateEffects]!.add(effect.ruleId);
    }
    if (judgment != null) {
      occurrencesByStage[LiuYaoAnalysisStages.judgeVerdict]!.addAll(
        judgment.factors.map((factor) => factor.factorId),
      );
      occurrencesByStage[LiuYaoAnalysisStages.judgeVerdict]!.addAll(
        judgment.conditions.map((condition) => condition.conditionId),
      );
      rulesByStage[LiuYaoAnalysisStages.judgeVerdict]!.addAll(
        judgment.factors.map((factor) => factor.ruleId),
      );
      rulesByStage[LiuYaoAnalysisStages.judgeVerdict]!.addAll(
        judgment.conditions.map((condition) => condition.conditionRuleId),
      );
    }
    if (yingQi != null) {
      occurrencesByStage[LiuYaoAnalysisStages.calculateTiming]!.addAll(
        yingQi
            .map((candidate) => candidate.timingId)
            .where((timingId) => timingId.isNotEmpty),
      );
      rulesByStage[LiuYaoAnalysisStages.calculateTiming]!.addAll(
        yingQi
            .map((candidate) => candidate.timingRuleId)
            .where((timingRuleId) => timingRuleId.isNotEmpty),
      );
    }
    return <LiuYaoAnalysisTraceStep>[
      for (final stage in LiuYaoAnalysisStages.ordered)
        LiuYaoAnalysisTraceStep(
          stageId: stage,
          ruleIds: rulesByStage[stage]!.toList()..sort(),
          occurrenceIds: occurrencesByStage[stage]!.toList()..sort(),
        ),
    ];
  }

  static void _validateProvenanceClosure({
    required String ruleSetVersion,
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required Map<String, List<YaoAnalysisTag>> actorTags,
    required List<YaoAnalysisTag> guaTags,
    required List<YaoAnalysisTag> yongShenTags,
    required List<ActorAvailability> actorAvailability,
    required List<DirectedEffectOccurrence> directedEffects,
    required VerdictJudgment? judgment,
    required List<YingQiCandidate>? yingQi,
  }) {
    final tags = <YaoAnalysisTag>[
      ...yaoTags.values.expand((value) => value),
      ...actorTags.values.expand((value) => value),
      ...guaTags,
      ...yongShenTags,
    ];
    final occurrenceIds = <String>{
      ...tags.map((tag) => tag.occurrenceId),
      ...directedEffects.map((effect) => effect.occurrenceId),
    }..remove('');

    void requireOccurrenceLinks(String owner, Iterable<String> links) {
      final orphans = links
          .where((occurrenceId) => !occurrenceIds.contains(occurrenceId))
          .toSet()
          .toList()
        ..sort();
      if (orphans.isNotEmpty) {
        throw StateError('$owner has orphan occurrence IDs: $orphans');
      }
    }

    for (final tag in tags) {
      requireOccurrenceLinks(
        'Tag ${tag.occurrenceId}',
        tag.suppressedByOccurrenceIds,
      );
    }
    for (final availability in actorAvailability) {
      requireOccurrenceLinks(
        'Availability ${availability.actor.actorId}',
        availability.suppressedByOccurrenceIds,
      );
    }
    for (final effect in directedEffects) {
      requireOccurrenceLinks(
        'Effect ${effect.occurrenceId}',
        effect.suppressedByOccurrenceIds,
      );
    }
    if (judgment != null) {
      for (final factor in judgment.factors) {
        requireOccurrenceLinks(
          'Factor ${factor.factorId}',
          factor.upstreamOccurrenceIds,
        );
      }
      for (final condition in judgment.conditions) {
        requireOccurrenceLinks(
          'Condition ${condition.conditionId}',
          condition.upstreamOccurrenceIds,
        );
        if (ruleSetVersion != LiuYaoRuleCatalog.v1Compat &&
            condition.upstreamOccurrenceIds.isEmpty) {
          throw StateError(
            'Condition ${condition.conditionId} has no upstream occurrence.',
          );
        }
      }
    }

    final conditionIds = <String>{
      ...?judgment?.conditions.map((condition) => condition.conditionId),
    }..remove('');
    for (final candidate in yingQi ?? const <YingQiCandidate>[]) {
      final orphanConditions = candidate.upstreamConditionIds
          .where((conditionId) => !conditionIds.contains(conditionId))
          .toSet()
          .toList()
        ..sort();
      if (orphanConditions.isNotEmpty) {
        throw StateError(
          'Timing ${candidate.timingId} has orphan condition IDs: '
          '$orphanConditions',
        );
      }
      if (ruleSetVersion != LiuYaoRuleCatalog.v1Compat &&
          (candidate.timingId.isEmpty ||
              candidate.timingRuleId.isEmpty ||
              candidate.upstreamConditionIds.isEmpty)) {
        throw StateError('Incomplete v2 timing provenance.');
      }
    }
  }

  static void _merge(
    Map<int, List<YaoAnalysisTag>> into,
    Map<int, List<YaoAnalysisTag>> from,
  ) {
    from.forEach((position, tags) => into[position]!.addAll(tags));
  }

  static void _addChainTags(
    Map<int, List<YaoAnalysisTag>> yaoTags,
    YongShenChain chain,
  ) {
    void addRole(
      int? position,
      String term,
      Polarity polarity,
      int priority,
      String reason,
    ) {
      if (position == null) return;
      yaoTags[position]!.add(YaoAnalysisTag(
        term: term,
        category: TagCategory.liuQin,
        polarity: polarity,
        priority: priority,
        reason: reason,
      ));
    }

    addRole(
      chain.position,
      chain.isFuShen ? '用神(伏)' : '用神',
      Polarity.neutral,
      0,
      chain.isFuShen ? '用神不现，伏神取用' : '所占之事以此爻为用',
    );
    addRole(chain.yuanShenPosition, '元神', Polarity.ji, 1, '生用神者为元神');
    addRole(chain.jiShenPosition, '忌神', Polarity.xiong, 1, '克用神者为忌神');
    addRole(chain.chouShenPosition, '仇神', Polarity.xiong, 8, '克元神生忌神者为仇神');
    for (final position in chain.duplicatePositions) {
      addRole(position, '用神两现', Polarity.neutral, 8, '与用神同六亲，舍此取彼');
    }
  }

  static int _compareTags(YaoAnalysisTag left, YaoAnalysisTag right) {
    final priority = left.priority.compareTo(right.priority);
    return priority != 0
        ? priority
        : left.occurrenceId.compareTo(right.occurrenceId);
  }
}
