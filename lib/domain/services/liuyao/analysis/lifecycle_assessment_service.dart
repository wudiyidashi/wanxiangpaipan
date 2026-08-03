import '../../../../divination_systems/liuyao/liuyao_result.dart';
import '../../shared/liuqin_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'models/analysis_trace.dart';
import 'question_focus_service.dart';
import 'rules/liuyao_catalog.dart';

enum LiuYaoFormation { willForm, unlikely, pending, unclear }

enum LiuYaoQuality { favorable, adverse, mixed, unclear }

enum LiuYaoContinuity { stable, unstable, conditional, unclear }

enum LiuYaoPersistence { smooth, entangled, brief, unclear }

class LiuYaoLifecycleJudgment {
  const LiuYaoLifecycleJudgment({
    required this.formation,
    required this.quality,
    required this.continuity,
    required this.persistence,
    required this.headlineCode,
    required this.headline,
    required this.matchedDecisionRowId,
    required this.evidenceOccurrenceIds,
  });

  final LiuYaoFormation formation;
  final LiuYaoQuality quality;
  final LiuYaoContinuity continuity;
  final LiuYaoPersistence persistence;
  final String headlineCode;
  final String headline;
  final String matchedDecisionRowId;
  final Map<String, List<String>> evidenceOccurrenceIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'formation': formation.name,
        'quality': quality.name,
        'continuity': continuity.name,
        'persistence': persistence.name,
        'headlineCode': headlineCode,
        'headline': headline,
        'matchedDecisionRowId': matchedDecisionRowId,
        'evidenceOccurrenceIds': evidenceOccurrenceIds,
      };
}

class LiuYaoLifecycleAssessmentService {
  LiuYaoLifecycleAssessmentService._();

  static const String formsButAdverseRowId =
      'liuyao.lifecycle.rental.forms-adverse-entangled';
  static const String fallbackRowId =
      'liuyao.lifecycle.rental.dimension-preserving-fallback';
  static const List<String> dimensionIds = <String>[
    'formation',
    'quality',
    'continuity',
    'persistence',
  ];

  static const Set<String> _adverseStateRules = <String>{
    LiuYaoRuleIds.ruleMonthOvercomes,
    LiuYaoRuleIds.ruleDayOvercomes,
    LiuYaoRuleIds.ruleConfined,
    LiuYaoRuleIds.ruleDead,
    LiuYaoRuleIds.ruleDayBreak,
    LiuYaoRuleIds.ruleScattered,
  };

  static const Set<String> _supportStateRules = <String>{
    LiuYaoRuleIds.ruleMonthCommand,
    LiuYaoRuleIds.ruleDayCommand,
    LiuYaoRuleIds.ruleDaySupports,
    LiuYaoRuleIds.ruleMonthGenerates,
    LiuYaoRuleIds.ruleDayGenerates,
    LiuYaoRuleIds.ruleProsperous,
    LiuYaoRuleIds.ruleSupported,
  };

  static const Set<String> _continuityRiskRules = <String>{
    LiuYaoRuleIds.ruleFlightOvercomesHidden,
    LiuYaoRuleIds.ruleHiddenSuppressed,
    LiuYaoRuleIds.ruleMovingTomb,
    LiuYaoRuleIds.ruleChangedTomb,
    LiuYaoRuleIds.ruleChangedTerminal,
    LiuYaoRuleIds.ruleRetreat,
  };

  static LiuYaoLifecycleJudgment? assess({
    required String? question,
    required LiuYaoResult result,
    required AnalysisReport report,
  }) {
    final focus = LiuYaoQuestionFocusService.resolve(question);
    final selected = report.yongShen;
    if (report.ruleSetVersion != LiuYaoRuleCatalog.v3 ||
        selected == null ||
        !focus.applicable) {
      return null;
    }

    final selectedActorId = selected.isFuShen
        ? 'hidden:host-yao:${selected.position}'
        : 'main:yao:${selected.position}';
    final selectedRoles = report.roles
        .where((role) => role.actor.actorId == selectedActorId && role.selected)
        .toList(growable: false);
    if (selectedRoles.length != 1 ||
        selectedRoles.single.actor.liuQin != LiuQin.qiCai) {
      return null;
    }
    final shiYing = LiuYaoQuestionFocusService.shiYingRelation(result);
    final harmonyTags = report.guaTags.where((tag) => <String>{
          LiuYaoRuleIds.ruleGuaSixHarmony,
          LiuYaoRuleIds.ruleChangesToSixHarmony,
        }.contains(tag.ruleId));
    final formationEvidence = <String>{
      ...harmonyTags.map((tag) => tag.occurrenceId),
      if (shiYing.supportsFormation) shiYing.evidenceId,
    }..remove('');
    final formation = formationEvidence.isNotEmpty
        ? LiuYaoFormation.willForm
        : LiuYaoFormation.unclear;

    final adverseTags = report.yongShenTags
        .where((tag) => tag.active && _adverseStateRules.contains(tag.ruleId));
    final supportiveTags = report.yongShenTags
        .where((tag) => tag.active && _supportStateRules.contains(tag.ruleId));
    final adverseEffects = report.directedEffects.where((effect) =>
        effect.isActive &&
        effect.toActor.actorId == selectedActorId &&
        effect.effect == DirectedEffectKind.ke &&
        (effect.phase == DirectedEffectPhase.formation ||
            effect.phase == DirectedEffectPhase.earlyProcess));
    final supportiveEffects = report.directedEffects.where((effect) =>
        effect.isActive &&
        effect.toActor.actorId == selectedActorId &&
        (effect.effect == DirectedEffectKind.sheng ||
            effect.effect == DirectedEffectKind.fu) &&
        (effect.phase == DirectedEffectPhase.formation ||
            effect.phase == DirectedEffectPhase.earlyProcess));
    final qualityEvidence = <String>{
      ...adverseTags.map((tag) => tag.occurrenceId),
      ...supportiveTags.map((tag) => tag.occurrenceId),
      ...adverseEffects.map((effect) => effect.occurrenceId),
      ...supportiveEffects.map((effect) => effect.occurrenceId),
    }..remove('');
    final hasAdverse = adverseTags.isNotEmpty || adverseEffects.isNotEmpty;
    final hasSupport =
        supportiveTags.isNotEmpty || supportiveEffects.isNotEmpty;
    final quality = adverseTags.isNotEmpty && adverseEffects.isNotEmpty
        ? LiuYaoQuality.adverse
        : hasAdverse && hasSupport
            ? LiuYaoQuality.mixed
            : hasAdverse
                ? LiuYaoQuality.adverse
                : hasSupport
                    ? LiuYaoQuality.favorable
                    : LiuYaoQuality.unclear;

    final duplicatePositions = selected.duplicatePositions.toSet();
    final continuityPositions = <int>{
      selected.position,
      ...duplicatePositions,
      result.mainGua.yingYaoPosition,
    };
    final continuityTags = _projectableContinuityTags(
      report,
      continuityPositions,
    );
    final finalRestrictions = report.directedEffects.where((effect) =>
        effect.isActive &&
        effect.effect == DirectedEffectKind.restrict &&
        (effect.toActor.actorId == selectedActorId ||
            duplicatePositions.contains(effect.toActor.position)));
    final scopedNoRescue = report.judgment?.conditions.where((condition) =>
            !condition.hasRescue && condition.dimension != 'formation') ??
        const <VerdictCondition>[];
    final continuityEvidence = <String>{
      ...continuityTags.map((tag) => tag.occurrenceId),
      ...finalRestrictions.map((effect) => effect.occurrenceId),
      ...scopedNoRescue.expand(
        (condition) => condition.upstreamOccurrenceIds,
      ),
    }..remove('');
    final continuity = continuityEvidence.isNotEmpty
        ? LiuYaoContinuity.unstable
        : quality == LiuYaoQuality.favorable
            ? LiuYaoContinuity.stable
            : LiuYaoContinuity.unclear;

    final persistenceEvidence = <String>{
      ...harmonyTags.map((tag) => tag.occurrenceId),
      ...continuityEvidence,
    }..remove('');
    final persistence = harmonyTags.isNotEmpty &&
            (quality == LiuYaoQuality.adverse ||
                quality == LiuYaoQuality.mixed ||
                continuity == LiuYaoContinuity.unstable)
        ? LiuYaoPersistence.entangled
        : harmonyTags.isNotEmpty &&
                quality == LiuYaoQuality.favorable &&
                continuity == LiuYaoContinuity.stable
            ? LiuYaoPersistence.smooth
            : continuity == LiuYaoContinuity.unstable
                ? LiuYaoPersistence.brief
                : LiuYaoPersistence.unclear;

    final isFormsButAdverse = formation == LiuYaoFormation.willForm &&
        quality == LiuYaoQuality.adverse &&
        continuity == LiuYaoContinuity.unstable &&
        persistence == LiuYaoPersistence.entangled;
    final rowId = isFormsButAdverse ? formsButAdverseRowId : fallbackRowId;
    return LiuYaoLifecycleJudgment(
      formation: formation,
      quality: quality,
      continuity: continuity,
      persistence: persistence,
      headlineCode: isFormsButAdverse
          ? 'formsButAdverse'
          : 'dimensionPreservingAssessment',
      headline: isFormsButAdverse ? '事必成，成而受困；合非吉兆，是套' : '形成、质量、持续与牵绊须分维度解释',
      matchedDecisionRowId: rowId,
      evidenceOccurrenceIds: <String, List<String>>{
        'formation': formationEvidence.toList()..sort(),
        'quality': qualityEvidence.toList()..sort(),
        'continuity': continuityEvidence.toList()..sort(),
        'persistence': persistenceEvidence.toList()..sort(),
      },
    );
  }

  static Iterable<YaoAnalysisTag> _projectableContinuityTags(
    AnalysisReport report,
    Set<int> positions,
  ) sync* {
    final actorScopedTags = <YaoAnalysisTag>[
      for (final position in positions)
        for (final actorId in <String>[
          'main:yao:$position',
          'changed:yao:$position',
          'hidden:host-yao:$position',
        ])
          ...?report.actorTags[actorId],
    ];
    final projectedOccurrenceIds = <String>{
      ...actorScopedTags.map((tag) => tag.occurrenceId),
      ...report.yongShenTags.map((tag) => tag.occurrenceId),
    };
    final originalTags = <YaoAnalysisTag>[
      for (final position in positions) ...?report.yaoTags[position],
      ...report.yongShenTags,
    ].where((tag) => tag.active && _continuityRiskRules.contains(tag.ruleId));

    for (final tag in originalTags) {
      if (projectedOccurrenceIds.contains(tag.occurrenceId)) {
        yield tag;
        continue;
      }
      final matches = actorScopedTags
          .where((candidate) => _sameEvidenceMeaning(candidate, tag))
          .toList(growable: false);
      if (matches.length != 1) {
        throw StateError(
          'Lifecycle evidence cannot map to one projected actor fact: '
          '${tag.ruleId}',
        );
      }
      yield matches.single;
    }
  }

  static bool _sameEvidenceMeaning(
    YaoAnalysisTag left,
    YaoAnalysisTag right,
  ) =>
      left.ruleId == right.ruleId &&
      left.term == right.term &&
      left.category == right.category &&
      left.polarity == right.polarity &&
      left.priority == right.priority &&
      left.reason == right.reason &&
      left.active == right.active &&
      left.relatedYao.length == right.relatedYao.length &&
      left.relatedYao
          .asMap()
          .entries
          .every((entry) => right.relatedYao[entry.key] == entry.value);
}
