import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_tag.dart';
import 'models/analysis_trace.dart';
import 'rule_identity_service.dart';
import 'rules/liuyao_catalog.dart';
import 'rules/liuyao_trace_id_factory.dart';
import 'tables/dizhi_relations.dart';

class ShengKeAnalysisResult {
  const ShengKeAnalysisResult({
    required this.tags,
    required this.effects,
  });

  final Map<int, List<YaoAnalysisTag>> tags;
  final List<DirectedEffectOccurrence> effects;
}

/// 爻间生克与贪生贪合分析。
///
/// 覆盖：动爻生、动爻克、动爻扶（拱）、贪生忘克、贪合忘生、贪合忘克、
/// 连续相生、连续相克。
/// 规则依据《增删卜易》：静不生克，动方能作用；动爻遇可生之动爻则
/// 贪生忘克；动爻被合住则忘生忘克；泄、耗、制、化等表述见术语词典。
class ShengKeService {
  ShengKeService._();

  /// v2 directed force graph. Suppressed attempts remain in [effects], while
  /// continuous tags are attached only to the terminal actor of the path.
  static ShengKeAnalysisResult analyzeDirected({
    required Gua gua,
    required LunarInfo lunarInfo,
    required Map<int, List<YaoAnalysisTag>> baseTags,
    required List<ActorAvailability> actorAvailability,
    required LiuYaoTraceIdFactory traceIdFactory,
  }) {
    final tags = <int, List<YaoAnalysisTag>>{};
    final effects = <DirectedEffectOccurrence>[];
    final availabilityByActorId = <String, ActorAvailability>{
      for (final availability in actorAvailability)
        availability.actor.actorId: availability,
    };
    final actorByPosition = <int, LiuYaoActorRef>{
      for (final availability in actorAvailability)
        if (availability.actor.kind == LiuYaoActorKind.mainYao &&
            availability.actor.position != null)
          availability.actor.position!: availability.actor,
    };
    final baseEffectByKey = <String, DirectedEffectOccurrence>{};
    final forceActors = gua.yaos.where((yao) {
      if (yao.isMoving) return true;
      return (baseTags[yao.position] ?? const <YaoAnalysisTag>[]).any((tag) =>
          RuleIdentityService.resolveRuleId(tag) ==
          LiuYaoRuleIds.ruleHiddenMoving);
    }).toList();

    void addTag(int position, YaoAnalysisTag tag) {
      tags.putIfAbsent(position, () => <YaoAnalysisTag>[]).add(tag);
    }

    for (final sourceYao in forceActors) {
      final sourceActor = actorByPosition[sourceYao.position]!;
      final availability = availabilityByActorId[sourceActor.actorId]!;
      final isHiddenMoving = !sourceYao.isMoving;
      final greedyTargets = sourceYao.isMoving
          ? gua.movingYaos
              .where((candidate) =>
                  candidate.position != sourceYao.position &&
                  WuXingService.isSheng(
                    sourceYao.wuXing,
                    candidate.wuXing,
                  ))
              .toList()
          : const <Yao>[];

      for (final targetYao in gua.yaos) {
        if (targetYao.position == sourceYao.position) continue;
        final targetActor = actorByPosition[targetYao.position]!;
        final DirectedEffectKind? effect;
        final String? ruleId;
        final String? displayTerm;
        final Polarity polarity;
        if (WuXingService.isSheng(sourceYao.wuXing, targetYao.wuXing)) {
          effect = DirectedEffectKind.sheng;
          ruleId = isHiddenMoving
              ? LiuYaoRuleIds.hiddenMovingGenerates
              : LiuYaoRuleIds.ruleMovingGenerates;
          displayTerm = '动爻生';
          polarity = Polarity.ji;
        } else if (WuXingService.isKe(
          sourceYao.wuXing,
          targetYao.wuXing,
        )) {
          effect = DirectedEffectKind.ke;
          ruleId = isHiddenMoving
              ? LiuYaoRuleIds.hiddenMovingOvercomes
              : LiuYaoRuleIds.ruleMovingOvercomes;
          displayTerm = '动爻克';
          polarity = Polarity.xiong;
        } else if (sourceYao.wuXing == targetYao.wuXing && !isHiddenMoving) {
          effect = DirectedEffectKind.fu;
          ruleId = LiuYaoRuleIds.ruleMovingSupports;
          displayTerm = '动爻扶';
          polarity = Polarity.ji;
        } else {
          continue;
        }

        final suppressedByRuleIds = <String>{
          if (!availability.canTransmit) ...availability.reasonRuleIds,
        };
        final suppressedByOccurrenceIds = <String>{
          if (!availability.canTransmit)
            ...availability.suppressedByOccurrenceIds,
        };
        if (effect == DirectedEffectKind.ke && greedyTargets.isNotEmpty) {
          suppressedByRuleIds.add(
            LiuYaoRuleIds.ruleGenerationSuppressesOvercoming,
          );
        }
        final active = suppressedByRuleIds.isEmpty;
        final occurrenceId = traceIdFactory.occurrence(
          stageId: LiuYaoAnalysisStages.calculateEffects,
          ruleId: ruleId,
          subjectRef: targetActor.actorId,
          fromActorId: sourceActor.actorId,
          toActorId: targetActor.actorId,
          pathStep: 0,
        );
        final sourceIds = LiuYaoRuleCatalog.ruleById[ruleId]!.sourceIds;
        final occurrence = DirectedEffectOccurrence(
          occurrenceId: occurrenceId,
          ruleId: ruleId,
          fromActor: sourceActor,
          toActor: targetActor,
          effect: effect,
          status: active
              ? DirectedEffectStatus.active
              : DirectedEffectStatus.suppressed,
          pathActorIds: <String>[
            sourceActor.actorId,
            targetActor.actorId,
          ],
          pathStep: 0,
          suppressedByRuleIds: suppressedByRuleIds.toList()..sort(),
          suppressedByOccurrenceIds: suppressedByOccurrenceIds.toList()..sort(),
          sourceIds: sourceIds,
          inputRefs: <String>[
            'mainGua.yaos[${sourceYao.position}]',
            'mainGua.yaos[${targetYao.position}]',
          ],
        );
        effects.add(occurrence);
        baseEffectByKey[
                '${sourceYao.position}>${targetYao.position}>${effect.name}'] =
            occurrence;

        var term = displayTerm;
        var tagRuleId = ruleId;
        var reason = '${sourceYao.position}爻${sourceYao.branch}'
            '${active ? '动来' : '受制，不能'}'
            '${effect == DirectedEffectKind.ke ? '克' : effect == DirectedEffectKind.fu ? '拱扶' : '生'}本爻';
        var relatedYao = <int>[sourceYao.position];
        if (!active &&
            effect == DirectedEffectKind.ke &&
            greedyTargets.isNotEmpty) {
          term = '贪生忘克';
          tagRuleId = LiuYaoRuleIds.ruleGenerationSuppressesOvercoming;
          relatedYao = <int>[
            sourceYao.position,
            greedyTargets.first.position,
          ];
          reason = '${sourceYao.position}爻${sourceYao.branch}贪生'
              '${greedyTargets.first.position}爻${greedyTargets.first.branch}，忘克本爻';
        } else if (!active &&
            availability.reasonRuleIds.contains(
              LiuYaoRuleIds.actorBinding,
            )) {
          term = effect == DirectedEffectKind.ke ? '贪合忘克' : '贪合忘生';
          tagRuleId = effect == DirectedEffectKind.ke
              ? LiuYaoRuleIds.ruleBindingSuppressesOvercoming
              : LiuYaoRuleIds.ruleBindingSuppressesGeneration;
          reason = '${sourceYao.position}爻${sourceYao.branch}被合绊，不能作用本爻';
        }
        final tagOccurrenceId = term == displayTerm
            ? occurrenceId
            : traceIdFactory.occurrence(
                stageId: LiuYaoAnalysisStages.arbitrateConflicts,
                ruleId: tagRuleId,
                subjectRef: targetActor.actorId,
                fromActorId: sourceActor.actorId,
                toActorId: targetActor.actorId,
              );
        addTag(
          targetYao.position,
          YaoAnalysisTag(
            term: term,
            category: TagCategory.shengKe,
            polarity: term.startsWith('贪') ? Polarity.ji : polarity,
            priority: term == '动爻克'
                ? 37
                : term == '动爻生'
                    ? 38
                    : term == '动爻扶'
                        ? 39
                        : 21,
            reason: reason,
            relatedYao: relatedYao,
            ruleId: tagRuleId,
            occurrenceId: tagOccurrenceId,
            sourceIds: LiuYaoRuleCatalog.ruleById[tagRuleId]!.sourceIds,
            active: active,
            suppressedByRuleIds: suppressedByRuleIds.toList()..sort(),
          ),
        );
      }
    }

    final seenPaths = <String>{};
    for (final first in gua.movingYaos) {
      for (final middle in gua.movingYaos) {
        for (final last in gua.movingYaos) {
          if ({first.position, middle.position, last.position}.length != 3) {
            continue;
          }
          final DirectedEffectKind? effect =
              WuXingService.isSheng(first.wuXing, middle.wuXing) &&
                      WuXingService.isSheng(middle.wuXing, last.wuXing)
                  ? DirectedEffectKind.sheng
                  : WuXingService.isKe(first.wuXing, middle.wuXing) &&
                          WuXingService.isKe(middle.wuXing, last.wuXing)
                      ? DirectedEffectKind.ke
                      : null;
          if (effect == null) continue;
          final pathKey =
              '${effect.name}:${first.position}>${middle.position}>${last.position}';
          if (!seenPaths.add(pathKey)) continue;
          final firstEdge = baseEffectByKey[
              '${first.position}>${middle.position}>${effect.name}'];
          final secondEdge = baseEffectByKey[
              '${middle.position}>${last.position}>${effect.name}'];
          if (firstEdge == null || secondEdge == null) continue;
          final ruleId = effect == DirectedEffectKind.sheng
              ? LiuYaoRuleIds.ruleContinuousGeneration
              : LiuYaoRuleIds.ruleContinuousOvercoming;
          final active = firstEdge.isActive && secondEdge.isActive;
          final suppressedByRuleIds = <String>{
            ...firstEdge.suppressedByRuleIds,
            ...secondEdge.suppressedByRuleIds,
          }.toList()
            ..sort();
          final suppressedByOccurrenceIds = <String>{
            ...firstEdge.suppressedByOccurrenceIds,
            ...secondEdge.suppressedByOccurrenceIds,
            if (!firstEdge.isActive) firstEdge.occurrenceId,
            if (!secondEdge.isActive) secondEdge.occurrenceId,
          }.toList()
            ..sort();
          final pathActors = <String>[
            firstEdge.fromActor.actorId,
            firstEdge.toActor.actorId,
            secondEdge.toActor.actorId,
          ];
          final occurrenceId = traceIdFactory.occurrence(
            stageId: LiuYaoAnalysisStages.calculateEffects,
            ruleId: ruleId,
            subjectRef:
                '${secondEdge.toActor.actorId}|path:${pathActors.join('>')}',
            fromActorId: firstEdge.fromActor.actorId,
            toActorId: secondEdge.toActor.actorId,
            pathStep: 2,
          );
          final sourceIds = LiuYaoRuleCatalog.ruleById[ruleId]!.sourceIds;
          effects.add(DirectedEffectOccurrence(
            occurrenceId: occurrenceId,
            ruleId: ruleId,
            fromActor: firstEdge.fromActor,
            toActor: secondEdge.toActor,
            effect: effect,
            status: active
                ? DirectedEffectStatus.active
                : DirectedEffectStatus.suppressed,
            pathActorIds: pathActors,
            pathStep: 2,
            suppressedByRuleIds: suppressedByRuleIds,
            suppressedByOccurrenceIds: suppressedByOccurrenceIds,
            sourceIds: sourceIds,
            inputRefs: <String>[
              'mainGua.yaos[${first.position}]',
              'mainGua.yaos[${middle.position}]',
              'mainGua.yaos[${last.position}]',
            ],
          ));
          addTag(
            last.position,
            YaoAnalysisTag(
              term: effect == DirectedEffectKind.sheng ? '连续相生' : '连续相克',
              category: TagCategory.shengKe,
              polarity: effect == DirectedEffectKind.sheng
                  ? Polarity.ji
                  : Polarity.xiong,
              priority: 13,
              reason: '${first.position}爻→${middle.position}爻→${last.position}爻'
                  '${effect == DirectedEffectKind.sheng ? '递相生' : '递相克'}',
              relatedYao: <int>[first.position, middle.position],
              ruleId: ruleId,
              occurrenceId: occurrenceId,
              sourceIds: sourceIds,
              active: active,
              suppressedByRuleIds: suppressedByRuleIds,
              suppressedByOccurrenceIds: suppressedByOccurrenceIds,
            ),
          );
        }
      }
    }

    return ShengKeAnalysisResult(tags: tags, effects: effects);
  }

  static Map<int, List<YaoAnalysisTag>> analyzeGua(
      Gua gua, LunarInfo lunarInfo) {
    final result = <int, List<YaoAnalysisTag>>{};
    final moving = gua.movingYaos;
    if (moving.isEmpty) return result;

    void add(int position, YaoAnalysisTag tag) {
      result.putIfAbsent(position, () => []).add(tag);
    }

    for (final m in moving) {
      final hePartner = _hePartnerOf(m, gua, lunarInfo);
      // 贪生对象：另一动爻为本动爻所生
      final tanSheng = moving
          .where((s) =>
              s.position != m.position &&
              WuXingService.isSheng(m.wuXing, s.wuXing))
          .toList();

      for (final t in gua.yaos) {
        if (t.position == m.position) continue;
        if (WuXingService.isSheng(m.wuXing, t.wuXing)) {
          if (hePartner != null) {
            add(
                t.position,
                YaoAnalysisTag(
                  term: '贪合忘生',
                  category: TagCategory.shengKe,
                  polarity: Polarity.neutral,
                  priority: 34,
                  reason: '${m.position}爻${m.branch}被$hePartner合住，忘生本爻',
                  relatedYao: [m.position],
                ));
          } else {
            add(
                t.position,
                YaoAnalysisTag(
                  term: '动爻生',
                  category: TagCategory.shengKe,
                  polarity: Polarity.ji,
                  priority: 38,
                  reason: '${m.position}爻${m.branch}动来生本爻',
                  relatedYao: [m.position],
                ));
          }
        } else if (WuXingService.isKe(m.wuXing, t.wuXing)) {
          if (hePartner != null) {
            add(
                t.position,
                YaoAnalysisTag(
                  term: '贪合忘克',
                  category: TagCategory.shengKe,
                  polarity: Polarity.ji,
                  priority: 34,
                  reason: '${m.position}爻${m.branch}被$hePartner合住，忘克本爻',
                  relatedYao: [m.position],
                ));
          } else if (tanSheng.isNotEmpty) {
            add(
                t.position,
                YaoAnalysisTag(
                  term: '贪生忘克',
                  category: TagCategory.shengKe,
                  polarity: Polarity.ji,
                  priority: 21,
                  reason:
                      '${m.position}爻${m.branch}贪生${tanSheng.first.position}爻'
                      '${tanSheng.first.branch}，忘克本爻',
                  relatedYao: [m.position, tanSheng.first.position],
                ));
          } else {
            add(
                t.position,
                YaoAnalysisTag(
                  term: '动爻克',
                  category: TagCategory.shengKe,
                  polarity: Polarity.xiong,
                  priority: 37,
                  reason: '${m.position}爻${m.branch}动来克本爻',
                  relatedYao: [m.position],
                ));
          }
        } else if (m.wuXing == t.wuXing && hePartner == null) {
          add(
              t.position,
              YaoAnalysisTag(
                term: '动爻扶',
                category: TagCategory.shengKe,
                polarity: Polarity.ji,
                priority: 39,
                reason: '${m.position}爻${m.branch}动来拱扶本爻',
                relatedYao: [m.position],
              ));
        }
      }
    }

    _analyzeChains(moving, add);
    return result;
  }

  /// 动爻的合住来源：他爻六合或日辰相合；无则返回 null
  static String? _hePartnerOf(Yao m, Gua gua, LunarInfo lunarInfo) {
    for (final o in gua.yaos) {
      if (o.position != m.position &&
          DiZhiRelations.isLiuHe(m.branch, o.branch)) {
        final isOpened = DiZhiRelations.isLiuChong(
              lunarInfo.riZhi,
              m.branch,
            ) ||
            DiZhiRelations.isLiuChong(lunarInfo.riZhi, o.branch);
        if (isOpened) continue;
        return '${o.position}爻${o.branch}';
      }
    }
    if (DiZhiRelations.isLiuHe(lunarInfo.riZhi, m.branch)) {
      return '日辰${lunarInfo.riZhi}';
    }
    return null;
  }

  /// 三个及以上动爻递相生/克成链
  static void _analyzeChains(
      List<Yao> moving, void Function(int, YaoAnalysisTag) add) {
    if (moving.length < 3) return;

    final shengMembers = <int, List<int>>{};
    final keMembers = <int, List<int>>{};

    for (final a in moving) {
      for (final b in moving) {
        for (final c in moving) {
          if (a.position == b.position ||
              b.position == c.position ||
              a.position == c.position) {
            continue;
          }
          final positions = [a.position, b.position, c.position];
          if (WuXingService.isSheng(a.wuXing, b.wuXing) &&
              WuXingService.isSheng(b.wuXing, c.wuXing)) {
            for (final p in positions) {
              shengMembers
                  .putIfAbsent(p, () => [])
                  .addAll(positions.where((x) => x != p));
            }
          }
          if (WuXingService.isKe(a.wuXing, b.wuXing) &&
              WuXingService.isKe(b.wuXing, c.wuXing)) {
            for (final p in positions) {
              keMembers
                  .putIfAbsent(p, () => [])
                  .addAll(positions.where((x) => x != p));
            }
          }
        }
      }
    }

    shengMembers.forEach((position, related) {
      add(
          position,
          YaoAnalysisTag(
            term: '连续相生',
            category: TagCategory.shengKe,
            polarity: Polarity.ji,
            priority: 13,
            reason: '动爻递相生，气脉相连',
            relatedYao: related.toSet().toList()..sort(),
          ));
    });
    keMembers.forEach((position, related) {
      add(
          position,
          YaoAnalysisTag(
            term: '连续相克',
            category: TagCategory.shengKe,
            polarity: Polarity.xiong,
            priority: 13,
            reason: '动爻递相克，祸患相连',
            relatedYao: related.toSet().toList()..sort(),
          ));
    });
  }
}
