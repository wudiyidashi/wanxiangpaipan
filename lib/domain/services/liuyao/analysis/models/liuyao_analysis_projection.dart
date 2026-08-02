import 'dart:convert';

import '../../../../../divination_systems/liuyao/liuyao_result.dart';
import '../../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../services/shared/liuqin_service.dart';
import '../../../../services/shared/wuxing_service.dart';
import 'analysis_report.dart';
import 'analysis_tag.dart';
import 'analysis_trace.dart';
import 'liuyao_rule_models.dart';
import '../rules/liuyao_catalog.dart';

enum LiuYaoUseSpiritMode {
  selectedVisible,
  selectedHidden,
  unselected,
}

class LiuYaoProjectionPolicy {
  const LiuYaoProjectionPolicy({required this.maySuggestYongShen});

  final bool maySuggestYongShen;

  Map<String, Object?> toJson() => <String, Object?>{
        'calculationOwner': 'program',
        'mayRecalculatePan': false,
        'mayRecalculateAnalysis': false,
        'mayReselectYongShen': false,
        'mayOverrideVerdict': false,
        'mayInventSources': false,
        'mayInventTiming': false,
        'timingIsGuarantee': false,
        'maySuggestYongShen': maySuggestYongShen,
      };
}

class LiuYaoUseSpiritProjection {
  const LiuYaoUseSpiritProjection({
    required this.mode,
    required this.userOverride,
    required this.maySuggestCandidates,
    this.position,
    this.selectedActorId,
  });

  final LiuYaoUseSpiritMode mode;
  final bool userOverride;
  final bool maySuggestCandidates;
  final int? position;
  final String? selectedActorId;

  Map<String, Object?> toJson() => <String, Object?>{
        'mode': _useSpiritModeId(mode),
        'userOverride': userOverride,
        'maySuggestCandidates': maySuggestCandidates,
        'position': position,
        'selectedActorId': selectedActorId,
      };
}

class LiuYaoYaoProjection {
  const LiuYaoYaoProjection({
    required this.position,
    required this.number,
    required this.stem,
    required this.branch,
    required this.wuXing,
    required this.liuQin,
    required this.isYang,
    required this.isMoving,
    required this.isShi,
    required this.isYing,
  });

  factory LiuYaoYaoProjection.fromYao(Yao yao) => LiuYaoYaoProjection(
        position: yao.position,
        number: yao.number.value,
        stem: yao.stem,
        branch: yao.branch,
        wuXing: _wuXingId(yao.wuXing),
        liuQin: _liuQinId(yao.liuQin),
        isYang: yao.isYang,
        isMoving: yao.isMoving,
        isShi: yao.isSeYao,
        isYing: yao.isYingYao,
      );

  final int position;
  final int number;
  final String stem;
  final String branch;
  final String wuXing;
  final String liuQin;
  final bool isYang;
  final bool isMoving;
  final bool isShi;
  final bool isYing;

  Map<String, Object?> toJson() => <String, Object?>{
        'position': position,
        'number': number,
        'stem': stem,
        'branch': branch,
        'wuXing': wuXing,
        'liuQin': liuQin,
        'isYang': isYang,
        'isMoving': isMoving,
        'isShi': isShi,
        'isYing': isYing,
      };
}

class LiuYaoGuaProjection {
  const LiuYaoGuaProjection({
    required this.id,
    required this.name,
    required this.palace,
    required this.specialType,
    required this.shiPosition,
    required this.yingPosition,
    required this.yaos,
  });

  factory LiuYaoGuaProjection.fromGua(Gua gua) => LiuYaoGuaProjection(
        id: gua.id,
        name: gua.name,
        palace: _baGongId(gua.baGong),
        specialType: _guaSpecialTypeId(gua.specialType),
        shiPosition: gua.seYaoPosition,
        yingPosition: gua.yingYaoPosition,
        yaos: gua.yaos.map(LiuYaoYaoProjection.fromYao).toList(),
      );

  final String id;
  final String name;
  final String palace;
  final String specialType;
  final int shiPosition;
  final int yingPosition;
  final List<LiuYaoYaoProjection> yaos;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'palace': palace,
        'specialType': specialType,
        'shiPosition': shiPosition,
        'yingPosition': yingPosition,
        'yaos': yaos.map((yao) => yao.toJson()).toList(),
      };
}

class LiuYaoPanProjection {
  const LiuYaoPanProjection({
    required this.castMethod,
    required this.mainGua,
    required this.changingGua,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.yueJian,
    required this.kongWang,
    required this.liuShen,
  });

  factory LiuYaoPanProjection.fromResult(LiuYaoResult result) =>
      LiuYaoPanProjection(
        castMethod: result.castMethod.id,
        mainGua: LiuYaoGuaProjection.fromGua(result.mainGua),
        changingGua: result.changingGua == null
            ? null
            : LiuYaoGuaProjection.fromGua(result.changingGua!),
        yearGanZhi: result.lunarInfo.yearGanZhi,
        monthGanZhi: result.lunarInfo.monthGanZhi,
        dayGanZhi: result.lunarInfo.riGanZhi,
        hourGanZhi: result.lunarInfo.hourGanZhi,
        yueJian: result.lunarInfo.yueJian,
        kongWang: List<String>.unmodifiable(result.lunarInfo.kongWang),
        liuShen: List<String>.unmodifiable(result.liuShen),
      );

  final String castMethod;
  final LiuYaoGuaProjection mainGua;
  final LiuYaoGuaProjection? changingGua;
  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String? hourGanZhi;
  final String yueJian;
  final List<String> kongWang;
  final List<String> liuShen;

  bool get hasChangingGua => changingGua != null;

  Map<String, Object?> toJson() => <String, Object?>{
        'castMethod': castMethod,
        'mainGua': mainGua.toJson(),
        'changingGua': changingGua?.toJson(),
        'hasChangingGua': hasChangingGua,
        'calendar': <String, Object?>{
          'yearGanZhi': yearGanZhi,
          'monthGanZhi': monthGanZhi,
          'dayGanZhi': dayGanZhi,
          'hourGanZhi': hourGanZhi,
          'yueJian': yueJian,
          'kongWang': kongWang,
        },
        'liuShen': liuShen,
      };
}

class LiuYaoProjectionReference {
  const LiuYaoProjectionReference({
    required this.ruleId,
    required this.primaryTerm,
    required this.locator,
    required this.evidenceLevel,
    required this.referenceKind,
    required this.adoptionNote,
    this.quote,
    this.reviewer,
  });

  final String ruleId;
  final String primaryTerm;
  final String locator;
  final String evidenceLevel;
  final String referenceKind;
  final String adoptionNote;
  final String? quote;
  final String? reviewer;

  Map<String, Object?> toJson() => <String, Object?>{
        'ruleId': ruleId,
        'primaryTerm': primaryTerm,
        'locator': locator,
        'evidenceLevel': evidenceLevel,
        'referenceKind': referenceKind,
        'adoptionNote': adoptionNote,
        if (quote != null) 'quote': quote,
        if (reviewer != null) 'reviewer': reviewer,
      };
}

class LiuYaoProjectionSource {
  const LiuYaoProjectionSource({
    required this.sourceId,
    required this.kind,
    required this.title,
    required this.edition,
    required this.revisionOrFingerprint,
    required this.publicLocator,
    required this.pageSystem,
    required this.adoptionStatus,
    required this.scope,
    required this.adjudication,
    required this.reviewedOn,
    required this.references,
    this.limitations,
  });

  final String sourceId;
  final String kind;
  final String title;
  final String edition;
  final String revisionOrFingerprint;
  final String publicLocator;
  final String pageSystem;
  final String adoptionStatus;
  final String scope;
  final String adjudication;
  final String reviewedOn;
  final String? limitations;
  final List<LiuYaoProjectionReference> references;

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'kind': kind,
        'title': title,
        'edition': edition,
        'revisionOrFingerprint': revisionOrFingerprint,
        'publicLocator': publicLocator,
        'pageSystem': pageSystem,
        'adoptionStatus': adoptionStatus,
        'scope': scope,
        'adjudication': adjudication,
        'reviewedOn': reviewedOn,
        if (limitations != null) 'limitations': limitations,
        'references':
            references.map((reference) => reference.toJson()).toList(),
      };
}

/// Canonical, versioned Liuyao analysis input used by every AI prompt variant.
class LiuYaoAnalysisProjection {
  LiuYaoAnalysisProjection._({
    required this.projectionSchemaVersion,
    required this.analysisSchemaVersion,
    required this.ruleSetId,
    required this.ruleSetVersion,
    required this.sourceCatalogVersion,
    required this.status,
    required this.diagnostics,
    required this.analysisStages,
    required this.policy,
    required this.pan,
    required this.useSpirit,
    required this.roles,
    required this.selectedUseSpiritFacts,
    required this.actorAvailability,
    required this.directedEffects,
    required this.auxiliaryEvidence,
    required this.conflicts,
    required this.factors,
    required this.verdict,
    required this.conditions,
    required this.timingCandidates,
    required this.sources,
    required this.trace,
    required Set<String> upstreamOccurrenceIds,
    required Set<String> traceOccurrenceIds,
    required Set<String> knownRuleIds,
  })  : _upstreamOccurrenceIds = Set<String>.unmodifiable(
          upstreamOccurrenceIds,
        ),
        _traceOccurrenceIds = Set<String>.unmodifiable(traceOccurrenceIds),
        _knownRuleIds = Set<String>.unmodifiable(knownRuleIds);

  static const int currentProjectionSchemaVersion = 1;

  static const List<String> topLevelKeys = <String>[
    'projectionSchemaVersion',
    'analysisSchemaVersion',
    'ruleSetId',
    'ruleSetVersion',
    'sourceCatalogVersion',
    'status',
    'diagnostics',
    'analysisStages',
    'policy',
    'pan',
    'useSpirit',
    'roles',
    'selectedUseSpiritFacts',
    'actorAvailability',
    'directedEffects',
    'auxiliaryEvidence',
    'conflicts',
    'factors',
    'verdict',
    'conditions',
    'timingCandidates',
    'sources',
    'trace',
  ];

  factory LiuYaoAnalysisProjection.fromReport({
    required LiuYaoResult result,
    required AnalysisReport report,
  }) {
    LiuYaoRuleCatalog.resolve(report.ruleSetVersion);

    final useSpirit = _projectUseSpirit(report);
    final allTags = <YaoAnalysisTag>[
      ...report.guaTags,
      ...report.yaoTags.values.expand((tags) => tags),
      ...report.yongShenTags,
    ];
    final conditions =
        report.judgment?.conditions ?? const <VerdictCondition>[];
    final timing = report.yingQi ?? const <YingQiCandidate>[];
    final ruleIds = _collectRuleIds(
      report: report,
      tags: allTags,
      conditions: conditions,
      timing: timing,
    );
    final explicitSourceIds = _collectExplicitSourceIds(
      report: report,
      tags: allTags,
      conditions: conditions,
      timing: timing,
    );
    final sources = _projectSources(ruleIds, explicitSourceIds);
    final factors = report.judgment?.factors ?? const <VerdictFactor>[];
    final upstreamOccurrenceIds = <String>{
      ...allTags.map((tag) => tag.occurrenceId),
      ...report.directedEffects.map((effect) => effect.occurrenceId),
    }..remove('');
    final traceOccurrenceIds = <String>{
      ...upstreamOccurrenceIds,
      ...factors.map((factor) => factor.factorId),
      ...conditions.map((condition) => condition.conditionId),
      ...timing.map((candidate) => candidate.timingId),
    }..remove('');
    final conflicts = <Map<String, Object?>>[
      ...allTags.where((tag) => !tag.active).map((tag) => _tagToJson(tag)),
      ...report.directedEffects
          .where((effect) => !effect.isActive)
          .map((effect) => _effectToJson(effect)),
    ];

    final projection = LiuYaoAnalysisProjection._(
      projectionSchemaVersion: currentProjectionSchemaVersion,
      analysisSchemaVersion: report.analysisSchemaVersion,
      ruleSetId: report.ruleSetId,
      ruleSetVersion: report.ruleSetVersion,
      sourceCatalogVersion: report.sourceCatalogVersion,
      status: _analysisStatusId(report.status),
      diagnostics: List<String>.unmodifiable(report.diagnostics),
      analysisStages: List<String>.unmodifiable(report.analysisStages),
      policy: LiuYaoProjectionPolicy(
        maySuggestYongShen: useSpirit.mode == LiuYaoUseSpiritMode.unselected,
      ),
      pan: LiuYaoPanProjection.fromResult(result),
      useSpirit: useSpirit,
      roles: List<LiuYaoRoleOccurrence>.unmodifiable(report.roles),
      selectedUseSpiritFacts:
          List<YaoAnalysisTag>.unmodifiable(report.yongShenTags),
      actorAvailability:
          List<ActorAvailability>.unmodifiable(report.actorAvailability),
      directedEffects:
          List<DirectedEffectOccurrence>.unmodifiable(report.directedEffects),
      auxiliaryEvidence: List<YaoAnalysisTag>.unmodifiable(report.guaTags),
      conflicts: List<Map<String, Object?>>.unmodifiable(conflicts),
      factors: List<VerdictFactor>.unmodifiable(
        factors,
      ),
      verdict: report.judgment,
      conditions: List<VerdictCondition>.unmodifiable(conditions),
      timingCandidates: List<YingQiCandidate>.unmodifiable(timing),
      sources: List<LiuYaoProjectionSource>.unmodifiable(sources),
      trace: List<LiuYaoAnalysisTraceStep>.unmodifiable(report.trace),
      upstreamOccurrenceIds: upstreamOccurrenceIds,
      traceOccurrenceIds: traceOccurrenceIds,
      knownRuleIds: ruleIds,
    );
    projection.validate();
    return projection;
  }

  final int projectionSchemaVersion;
  final int analysisSchemaVersion;
  final String ruleSetId;
  final String ruleSetVersion;
  final String sourceCatalogVersion;
  final String status;
  final List<String> diagnostics;
  final List<String> analysisStages;
  final LiuYaoProjectionPolicy policy;
  final LiuYaoPanProjection pan;
  final LiuYaoUseSpiritProjection useSpirit;
  final List<LiuYaoRoleOccurrence> roles;
  final List<YaoAnalysisTag> selectedUseSpiritFacts;
  final List<ActorAvailability> actorAvailability;
  final List<DirectedEffectOccurrence> directedEffects;
  final List<YaoAnalysisTag> auxiliaryEvidence;
  final List<Map<String, Object?>> conflicts;
  final List<VerdictFactor> factors;
  final VerdictJudgment? verdict;
  final List<VerdictCondition> conditions;
  final List<YingQiCandidate> timingCandidates;
  final List<LiuYaoProjectionSource> sources;
  final List<LiuYaoAnalysisTraceStep> trace;
  final Set<String> _upstreamOccurrenceIds;
  final Set<String> _traceOccurrenceIds;
  final Set<String> _knownRuleIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'projectionSchemaVersion': projectionSchemaVersion,
        'analysisSchemaVersion': analysisSchemaVersion,
        'ruleSetId': ruleSetId,
        'ruleSetVersion': ruleSetVersion,
        'sourceCatalogVersion': sourceCatalogVersion,
        'status': status,
        'diagnostics': diagnostics,
        'analysisStages': analysisStages,
        'policy': policy.toJson(),
        'pan': pan.toJson(),
        'useSpirit': useSpirit.toJson(),
        'roles': roles.map(_roleToJson).toList(),
        'selectedUseSpiritFacts':
            selectedUseSpiritFacts.map(_tagToJson).toList(),
        'actorAvailability':
            actorAvailability.map(_availabilityToJson).toList(),
        'directedEffects': directedEffects.map(_effectToJson).toList(),
        'auxiliaryEvidence': auxiliaryEvidence.map(_tagToJson).toList(),
        'conflicts': conflicts,
        'factors': factors.map(_factorToJson).toList(),
        'verdict': verdict == null ? null : _verdictToJson(verdict!),
        'conditions': conditions.map(_conditionToJson).toList(),
        'timingCandidates': timingCandidates.map(_timingToJson).toList(),
        'sources': sources.map((source) => source.toJson()).toList(),
        'trace': trace.map(_traceToJson).toList(),
      };

  String toCanonicalJson() => jsonEncode(toJson());

  void validate() {
    if (projectionSchemaVersion != currentProjectionSchemaVersion) {
      throw const FormatException('Unsupported Liuyao projection schema');
    }
    if (ruleSetId != LiuYaoRuleCatalog.ruleSetId ||
        sourceCatalogVersion != LiuYaoRuleCatalog.sourceCatalogVersion) {
      throw const FormatException('Liuyao projection version mismatch');
    }
    if (!_sameStrings(analysisStages, LiuYaoAnalysisStages.ordered)) {
      throw const FormatException('Liuyao analysis stage order mismatch');
    }
    final json = toJson();
    if (!_sameStrings(json.keys.toList(), topLevelKeys)) {
      throw const FormatException('Liuyao projection top-level shape drift');
    }
    final policyJson = policy.toJson();
    if (policyJson['calculationOwner'] != 'program' ||
        policyJson['mayRecalculatePan'] != false ||
        policyJson['mayRecalculateAnalysis'] != false ||
        policyJson['mayReselectYongShen'] != false ||
        policyJson['mayOverrideVerdict'] != false ||
        policyJson['mayInventSources'] != false ||
        policyJson['mayInventTiming'] != false ||
        policyJson['timingIsGuarantee'] != false) {
      throw const FormatException('Liuyao immutable policy was modified');
    }
    if (useSpirit.mode == LiuYaoUseSpiritMode.unselected) {
      if (verdict != null ||
          conditions.isNotEmpty ||
          timingCandidates.isNotEmpty) {
        throw const FormatException(
          'Unselected Liuyao projection cannot contain verdict or timing',
        );
      }
    } else if (verdict == null) {
      throw const FormatException(
        'Selected Liuyao projection requires the program verdict',
      );
    }
    for (final tags in <YaoAnalysisTag>[
      ...selectedUseSpiritFacts,
      ...auxiliaryEvidence,
    ]) {
      _requireKnownRule(tags.ruleId);
      _requireOccurrenceLinks(
        owner: 'Liuyao tag ${tags.occurrenceId}',
        links: tags.suppressedByOccurrenceIds,
        knownIds: _upstreamOccurrenceIds,
      );
    }
    for (final availability in actorAvailability) {
      _requireOccurrenceLinks(
        owner: 'Liuyao availability ${availability.actor.actorId}',
        links: availability.suppressedByOccurrenceIds,
        knownIds: _upstreamOccurrenceIds,
      );
    }
    for (final effect in directedEffects) {
      _requireKnownRule(effect.ruleId);
      _requireOccurrenceLinks(
        owner: 'Liuyao effect ${effect.occurrenceId}',
        links: effect.suppressedByOccurrenceIds,
        knownIds: _upstreamOccurrenceIds,
      );
    }
    for (final factor in factors) {
      _requireKnownRule(factor.ruleId);
      if (factor.decisionRowId.isNotEmpty) {
        _requireKnownRule(factor.decisionRowId);
      }
      if (factor.factorId.isEmpty) {
        throw const FormatException('Liuyao factor ID is empty');
      }
      _requireOccurrenceLinks(
        owner: 'Liuyao factor ${factor.factorId}',
        links: factor.upstreamOccurrenceIds,
        knownIds: _upstreamOccurrenceIds,
      );
    }
    final conditionIds = <String>{};
    for (final condition in conditions) {
      _requireKnownRule(condition.conditionRuleId);
      if (condition.conditionId.isEmpty) {
        throw const FormatException('Liuyao condition ID is empty');
      }
      conditionIds.add(condition.conditionId);
      _requireOccurrenceLinks(
        owner: 'Liuyao condition ${condition.conditionId}',
        links: condition.upstreamOccurrenceIds,
        knownIds: _upstreamOccurrenceIds,
      );
    }
    for (final timing in timingCandidates) {
      _requireKnownRule(timing.timingRuleId);
      if (timing.timingId.isEmpty ||
          !conditionIds.containsAll(timing.upstreamConditionIds)) {
        throw FormatException(
          'Liuyao timing has an empty ID or orphan conditions: '
          '${timing.timingId}',
        );
      }
      if (timing.upstreamConditionIds.isEmpty) {
        throw FormatException(
          'Liuyao timing is not linked to a verdict condition: '
          '${timing.timingId}',
        );
      }
    }
    final expectedTraceStages = status == 'invalid'
        ? const <String>[LiuYaoAnalysisStages.validateInput]
        : LiuYaoAnalysisStages.ordered;
    if (!_sameStrings(
      trace.map((step) => step.stageId).toList(),
      expectedTraceStages,
    )) {
      throw const FormatException('Liuyao trace stage order mismatch');
    }
    for (final step in trace) {
      final unknownRules = step.ruleIds
          .where((ruleId) => !_knownRuleIds.contains(ruleId))
          .toSet();
      if (unknownRules.isNotEmpty) {
        throw FormatException(
          'Liuyao trace has unknown rule IDs at ${step.stageId}: '
          '${unknownRules.toList()..sort()}',
        );
      }
      _requireOccurrenceLinks(
        owner: 'Liuyao trace ${step.stageId}',
        links: step.occurrenceIds,
        knownIds: _traceOccurrenceIds,
      );
    }
    for (final source in sources) {
      if (_looksLikeAbsolutePath(source.publicLocator)) {
        throw FormatException(
          'Liuyao source exposes an absolute path: ${source.sourceId}',
        );
      }
      for (final reference in source.references) {
        if (reference.referenceKind != 'exactQuote' &&
            reference.quote != null) {
          throw FormatException(
            'Non-quote Liuyao reference contains quote text: '
            '${reference.ruleId}',
          );
        }
      }
    }
  }
}

LiuYaoUseSpiritProjection _projectUseSpirit(AnalysisReport report) {
  final chain = report.yongShen;
  if (chain == null) {
    return const LiuYaoUseSpiritProjection(
      mode: LiuYaoUseSpiritMode.unselected,
      userOverride: false,
      maySuggestCandidates: true,
    );
  }
  return LiuYaoUseSpiritProjection(
    mode: chain.isFuShen
        ? LiuYaoUseSpiritMode.selectedHidden
        : LiuYaoUseSpiritMode.selectedVisible,
    userOverride: true,
    maySuggestCandidates: false,
    position: chain.position,
    selectedActorId: chain.isFuShen
        ? 'hidden:host-yao:${chain.position}'
        : 'main:yao:${chain.position}',
  );
}

Set<String> _collectRuleIds({
  required AnalysisReport report,
  required List<YaoAnalysisTag> tags,
  required List<VerdictCondition> conditions,
  required List<YingQiCandidate> timing,
}) {
  final result = <String>{
    ...tags.map((tag) => tag.ruleId),
    ...tags.expand((tag) => tag.suppressedByRuleIds),
    ...report.roles.map((role) => role.roleRuleId),
    ...report.actorAvailability.expand((item) => item.reasonRuleIds),
    ...report.actorAvailability.expand((item) => item.releaseConditionRuleIds),
    ...report.directedEffects.map((effect) => effect.ruleId),
    ...report.directedEffects.expand((effect) => effect.suppressedByRuleIds),
    ...?report.judgment?.factors.map((factor) => factor.ruleId),
    ...?report.judgment?.factors.map((factor) => factor.decisionRowId),
    if ((report.judgment?.matchedDecisionRowId ?? '').isNotEmpty)
      report.judgment!.matchedDecisionRowId,
    ...conditions.map((condition) => condition.conditionRuleId),
    ...timing.map((candidate) => candidate.timingRuleId),
    ...timing.expand((candidate) => candidate.upstreamRuleIds),
  }..remove('');
  for (final ruleId in result) {
    _requireKnownRule(ruleId);
  }
  return result;
}

Set<String> _collectExplicitSourceIds({
  required AnalysisReport report,
  required List<YaoAnalysisTag> tags,
  required List<VerdictCondition> conditions,
  required List<YingQiCandidate> timing,
}) =>
    <String>{
      ...report.usedSourceIds,
      ...tags.expand((tag) => tag.sourceIds),
      ...report.directedEffects.expand((effect) => effect.sourceIds),
      ...?report.judgment?.factors.expand((factor) => factor.sourceIds),
      ...conditions.expand((condition) => condition.sourceIds),
      ...timing.expand((candidate) => candidate.sourceIds),
    }..remove('');

List<LiuYaoProjectionSource> _projectSources(
  Set<String> ruleIds,
  Set<String> explicitSourceIds,
) {
  final refsBySource = <String, List<LiuYaoProjectionReference>>{};
  for (final ruleId in ruleIds.toList()..sort()) {
    final rule = LiuYaoRuleCatalog.ruleById[ruleId]!;
    for (final evidence in rule.evidenceRefs) {
      refsBySource.putIfAbsent(evidence.sourceId, () => []).add(
            LiuYaoProjectionReference(
              ruleId: rule.ruleId,
              primaryTerm: rule.primaryTerm,
              locator: evidence.locator,
              evidenceLevel: _evidenceLevelId(evidence.evidenceLevel),
              referenceKind: _referenceKindId(evidence.referenceKind),
              adoptionNote: evidence.adoptionNote,
              quote: evidence.referenceKind == LiuYaoReferenceKind.exactQuote
                  ? evidence.quote
                  : null,
              reviewer: evidence.reviewer,
            ),
          );
      explicitSourceIds.add(evidence.sourceId);
    }
  }
  final sourceIds = explicitSourceIds.toList()..sort();
  return sourceIds.map((sourceId) {
    final source = LiuYaoRuleCatalog.sourceById[sourceId];
    if (source == null) {
      throw FormatException('Unknown Liuyao source ID: $sourceId');
    }
    final references = refsBySource[sourceId] ?? <LiuYaoProjectionReference>[];
    references.sort((a, b) {
      final byRule = a.ruleId.compareTo(b.ruleId);
      return byRule != 0 ? byRule : a.locator.compareTo(b.locator);
    });
    return LiuYaoProjectionSource(
      sourceId: source.sourceId,
      kind: _sourceKindId(source.kind),
      title: source.title,
      edition: source.edition,
      revisionOrFingerprint: source.revisionOrFingerprint,
      publicLocator: source.publicLocator,
      pageSystem: source.pageSystem,
      adoptionStatus: _adoptionStatusId(source.adoptionStatus),
      scope: source.scope,
      adjudication: source.adjudication,
      reviewedOn: source.reviewedOn,
      limitations: source.limitations,
      references: List<LiuYaoProjectionReference>.unmodifiable(references),
    );
  }).toList();
}

Map<String, Object?> _actorToJson(LiuYaoActorRef actor) => <String, Object?>{
      'actorId': actor.actorId,
      'kind': _actorKindId(actor.kind),
      'position': actor.position,
      'branch': actor.branch,
      'wuXing': _wuXingId(actor.wuXing),
      'liuQin': actor.liuQin == null ? null : _liuQinId(actor.liuQin!),
      'isMoving': actor.isMoving,
    };

Map<String, Object?> _roleToJson(LiuYaoRoleOccurrence role) =>
    <String, Object?>{
      'actor': _actorToJson(role.actor),
      'role': _roleId(role.role),
      'roleRuleId': role.roleRuleId,
      'reason': role.reason,
      'selected': role.selected,
      'representative': role.representative,
    };

Map<String, Object?> _availabilityToJson(ActorAvailability availability) =>
    <String, Object?>{
      'actor': _actorToJson(availability.actor),
      'state': _availabilityStateId(availability.state),
      'reasonRuleIds': availability.reasonRuleIds,
      'releaseConditionRuleIds': availability.releaseConditionRuleIds,
      'suppressedByOccurrenceIds': availability.suppressedByOccurrenceIds,
    };

Map<String, Object?> _effectToJson(DirectedEffectOccurrence effect) =>
    <String, Object?>{
      'occurrenceId': effect.occurrenceId,
      'ruleId': effect.ruleId,
      'fromActor': _actorToJson(effect.fromActor),
      'toActor': _actorToJson(effect.toActor),
      'effect': _effectKindId(effect.effect),
      'status': _effectStatusId(effect.status),
      'pathActorIds': effect.pathActorIds,
      'pathStep': effect.pathStep,
      'suppressedByRuleIds': effect.suppressedByRuleIds,
      'suppressedByOccurrenceIds': effect.suppressedByOccurrenceIds,
      'sourceIds': effect.sourceIds,
      'inputRefs': effect.inputRefs,
    };

Map<String, Object?> _tagToJson(YaoAnalysisTag tag) => <String, Object?>{
      'occurrenceId': tag.occurrenceId,
      'ruleId': tag.ruleId,
      'term': tag.term,
      'category': _tagCategoryId(tag.category),
      'polarity': _polarityId(tag.polarity),
      'priority': tag.priority,
      'reason': tag.reason,
      'relatedYao': tag.relatedYao,
      'sourceIds': tag.sourceIds,
      'active': tag.active,
      'suppressedByRuleIds': tag.suppressedByRuleIds,
      'suppressedByOccurrenceIds': tag.suppressedByOccurrenceIds,
    };

Map<String, Object?> _factorToJson(VerdictFactor factor) => <String, Object?>{
      'factorId': factor.factorId,
      'ruleId': factor.ruleId,
      'decisionRowId': factor.decisionRowId,
      'rule': factor.rule,
      'effect': _verdictEffectId(factor.effect),
      'reason': factor.reason,
      'source': factor.source,
      'sourceIds': factor.sourceIds,
      'upstreamOccurrenceIds': factor.upstreamOccurrenceIds,
      'active': factor.active,
      'arbitrationTier': factor.arbitrationTier,
      'arbitrationOrder': factor.arbitrationOrder,
    };

Map<String, Object?> _conditionToJson(VerdictCondition condition) =>
    <String, Object?>{
      'conditionId': condition.conditionId,
      'conditionRuleId': condition.conditionRuleId,
      'label': condition.label,
      'branch': condition.branch,
      'reason': condition.reason,
      'hasRescue': condition.hasRescue,
      'status': condition.status,
      'sourceIds': condition.sourceIds,
      'upstreamOccurrenceIds': condition.upstreamOccurrenceIds,
    };

Map<String, Object?> _verdictToJson(VerdictJudgment verdict) =>
    <String, Object?>{
      'trend': _verdictTrendId(verdict.trend),
      'nuance': verdict.nuance,
      'summary': verdict.summary,
      'matchedDecisionRowId': verdict.matchedDecisionRowId,
    };

Map<String, Object?> _timingToJson(YingQiCandidate timing) => <String, Object?>{
      'timingId': timing.timingId,
      'timingRuleId': timing.timingRuleId,
      'label': timing.label,
      'branch': timing.branch,
      'scale': _yingQiScaleId(timing.scale),
      'triggerKind': timing.triggerKind,
      'triggerValue': timing.triggerValue,
      'targetActorId': timing.targetActorId,
      'reason': timing.reason,
      'priority': timing.priority,
      'upstreamConditionIds': timing.upstreamConditionIds,
      'upstreamRuleIds': timing.upstreamRuleIds,
      'sourceIds': timing.sourceIds,
    };

Map<String, Object?> _traceToJson(LiuYaoAnalysisTraceStep step) =>
    <String, Object?>{
      'stageId': step.stageId,
      'ruleIds': step.ruleIds,
      'occurrenceIds': step.occurrenceIds,
      'notes': step.notes,
    };

void _requireKnownRule(String ruleId) {
  if (ruleId.isEmpty || !LiuYaoRuleCatalog.ruleById.containsKey(ruleId)) {
    throw FormatException('Unknown Liuyao rule ID: $ruleId');
  }
}

void _requireOccurrenceLinks({
  required String owner,
  required Iterable<String> links,
  required Set<String> knownIds,
}) {
  final orphanIds = links.where((id) => !knownIds.contains(id)).toSet().toList()
    ..sort();
  if (orphanIds.isNotEmpty) {
    throw FormatException('$owner has orphan occurrence IDs: $orphanIds');
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _looksLikeAbsolutePath(String value) =>
    RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value) ||
    value.startsWith('/') ||
    value.startsWith(r'\\');

String _analysisStatusId(LiuYaoAnalysisStatus value) => switch (value) {
      LiuYaoAnalysisStatus.success => 'success',
      LiuYaoAnalysisStatus.invalid => 'invalid',
    };

String _useSpiritModeId(LiuYaoUseSpiritMode value) => switch (value) {
      LiuYaoUseSpiritMode.selectedVisible => 'selectedVisible',
      LiuYaoUseSpiritMode.selectedHidden => 'selectedHidden',
      LiuYaoUseSpiritMode.unselected => 'unselected',
    };

String _actorKindId(LiuYaoActorKind value) => switch (value) {
      LiuYaoActorKind.mainYao => 'mainYao',
      LiuYaoActorKind.changedYao => 'changedYao',
      LiuYaoActorKind.hiddenYao => 'hiddenYao',
      LiuYaoActorKind.calendarDay => 'calendarDay',
      LiuYaoActorKind.calendarMonth => 'calendarMonth',
    };

String _roleId(LiuYaoRole value) => switch (value) {
      LiuYaoRole.yongShen => 'yongShen',
      LiuYaoRole.duplicateYongShen => 'duplicateYongShen',
      LiuYaoRole.yuanShen => 'yuanShen',
      LiuYaoRole.jiShen => 'jiShen',
      LiuYaoRole.chouShen => 'chouShen',
      LiuYaoRole.xianShen => 'xianShen',
    };

String _availabilityStateId(ActorAvailabilityState value) => switch (value) {
      ActorAvailabilityState.active => 'active',
      ActorAvailabilityState.suspended => 'suspended',
      ActorAvailabilityState.suppressed => 'suppressed',
      ActorAvailabilityState.unavailable => 'unavailable',
    };

String _effectKindId(DirectedEffectKind value) => switch (value) {
      DirectedEffectKind.sheng => 'sheng',
      DirectedEffectKind.ke => 'ke',
      DirectedEffectKind.fu => 'fu',
      DirectedEffectKind.xie => 'xie',
      DirectedEffectKind.hao => 'hao',
      DirectedEffectKind.he => 'he',
      DirectedEffectKind.chong => 'chong',
    };

String _effectStatusId(DirectedEffectStatus value) => switch (value) {
      DirectedEffectStatus.active => 'active',
      DirectedEffectStatus.suppressed => 'suppressed',
    };

String _tagCategoryId(TagCategory value) => switch (value) {
      TagCategory.wangShuai => 'wangShuai',
      TagCategory.kongWang => 'kongWang',
      TagCategory.muJue => 'muJue',
      TagCategory.heChong => 'heChong',
      TagCategory.dongBian => 'dongBian',
      TagCategory.shengKe => 'shengKe',
      TagCategory.liuQin => 'liuQin',
      TagCategory.fuShen => 'fuShen',
      TagCategory.special => 'special',
      TagCategory.guaChange => 'guaChange',
    };

String _polarityId(Polarity value) => switch (value) {
      Polarity.ji => 'ji',
      Polarity.xiong => 'xiong',
      Polarity.neutral => 'neutral',
    };

String _verdictEffectId(VerdictEffect value) => switch (value) {
      VerdictEffect.fu => 'fu',
      VerdictEffect.yi => 'yi',
      VerdictEffect.suspend => 'suspend',
      VerdictEffect.neutral => 'neutral',
    };

String _verdictTrendId(VerdictTrend value) => switch (value) {
      VerdictTrend.keCheng => 'keCheng',
      VerdictTrend.nanCheng => 'nanCheng',
      VerdictTrend.daiTiaoJian => 'daiTiaoJian',
      VerdictTrend.buMing => 'buMing',
    };

String _yingQiScaleId(YingQiScale value) => switch (value) {
      YingQiScale.ri => 'ri',
      YingQiScale.yue => 'yue',
      YingQiScale.nian => 'nian',
    };

String _evidenceLevelId(LiuYaoEvidenceLevel value) => switch (value) {
      LiuYaoEvidenceLevel.a => 'A',
      LiuYaoEvidenceLevel.b => 'B',
      LiuYaoEvidenceLevel.c => 'C',
      LiuYaoEvidenceLevel.d => 'D',
    };

String _referenceKindId(LiuYaoReferenceKind value) => switch (value) {
      LiuYaoReferenceKind.exactQuote => 'exactQuote',
      LiuYaoReferenceKind.paraphrase => 'paraphrase',
      LiuYaoReferenceKind.projectConvention => 'projectConvention',
      LiuYaoReferenceKind.locatorOnly => 'locatorOnly',
    };

String _sourceKindId(LiuYaoSourceKind value) => switch (value) {
      LiuYaoSourceKind.classicalWitness => 'classicalWitness',
      LiuYaoSourceKind.projectContract => 'projectContract',
    };

String _adoptionStatusId(LiuYaoAdoptionStatus value) => switch (value) {
      LiuYaoAdoptionStatus.adopted => 'adopted',
      LiuYaoAdoptionStatus.locatorOnly => 'locatorOnly',
    };

String _wuXingId(WuXing value) => switch (value) {
      WuXing.jin => 'jin',
      WuXing.mu => 'mu',
      WuXing.shui => 'shui',
      WuXing.huo => 'huo',
      WuXing.tu => 'tu',
    };

String _liuQinId(LiuQin value) => switch (value) {
      LiuQin.fuMu => 'fuMu',
      LiuQin.xiongDi => 'xiongDi',
      LiuQin.ziSun => 'ziSun',
      LiuQin.qiCai => 'qiCai',
      LiuQin.guanGui => 'guanGui',
    };

String _baGongId(BaGong value) => switch (value) {
      BaGong.qian => 'qian',
      BaGong.kun => 'kun',
      BaGong.zhen => 'zhen',
      BaGong.xun => 'xun',
      BaGong.kan => 'kan',
      BaGong.li => 'li',
      BaGong.gen => 'gen',
      BaGong.dui => 'dui',
    };

String _guaSpecialTypeId(GuaSpecialType value) => switch (value) {
      GuaSpecialType.liuChong => 'liuChong',
      GuaSpecialType.liuHe => 'liuHe',
      GuaSpecialType.youHun => 'youHun',
      GuaSpecialType.guiHun => 'guiHun',
      GuaSpecialType.none => 'none',
    };
