import '../models/liuyao_rule_models.dart';

typedef LiuYaoTagRuleSpec = ({
  String ruleId,
  LiuYaoRuleFamily family,
  LiuYaoRuleStage stage,
});

class LiuYaoRuleIds {
  LiuYaoRuleIds._();

  static const String projectSource = 'liuyao.source.project.analysis-contract';
  static const String zengShanSource =
      'liuyao.source.zengshan.zhongguonaner-pdf';
  static const String buShiSource =
      'liuyao.source.bushi-zhengzong.distiller-2004-pdf';

  // Stable execution identities. Display terms in [tagRuleSpecs] may change,
  // but runtime policy must continue to compare these IDs.
  static const String ruleMonthCommand = 'liuyao.rule.wangshuai.month-command';
  static const String ruleMonthBreak = 'liuyao.rule.wangshuai.month-break';
  static const String ruleMonthGenerates =
      'liuyao.rule.wangshuai.month-generates';
  static const String ruleMonthOvercomes =
      'liuyao.rule.wangshuai.month-overcomes';
  static const String ruleProsperous = 'liuyao.rule.wangshuai.prosperous';
  static const String ruleSupported = 'liuyao.rule.wangshuai.supported';
  static const String ruleResting = 'liuyao.rule.wangshuai.resting';
  static const String ruleConfined = 'liuyao.rule.wangshuai.confined';
  static const String ruleDead = 'liuyao.rule.wangshuai.dead';
  static const String ruleDayCommand = 'liuyao.rule.wangshuai.day-command';
  static const String ruleDaySupports = 'liuyao.rule.wangshuai.day-supports';
  static const String ruleDayGenerates = 'liuyao.rule.wangshuai.day-generates';
  static const String ruleDayOvercomes = 'liuyao.rule.wangshuai.day-overcomes';
  static const String ruleVoid = 'liuyao.rule.kongwang.void';
  static const String ruleApparentVoid = 'liuyao.rule.kongwang.apparent-void';
  static const String ruleTrueVoid = 'liuyao.rule.kongwang.true-void';
  static const String ruleVoidClashed = 'liuyao.rule.kongwang.void-clashed';
  static const String ruleDayTomb = 'liuyao.rule.mujue.day-tomb';
  static const String ruleMonthTomb = 'liuyao.rule.mujue.month-tomb';
  static const String ruleMovingTomb = 'liuyao.rule.mujue.moving-tomb';
  static const String ruleTombOpened = 'liuyao.rule.mujue.tomb-opened';
  static const String ruleTerminal = 'liuyao.rule.mujue.terminal';
  static const String ruleMovingBound = 'liuyao.rule.hechong.moving-bound';
  static const String ruleMutualBinding = 'liuyao.rule.hechong.mutual-binding';
  static const String ruleBindingOpened = 'liuyao.rule.hechong.binding-opened';
  static const String ruleHiddenMoving = 'liuyao.rule.dongbian.hidden-moving';
  static const String ruleDayBreak = 'liuyao.rule.dongbian.day-break';
  static const String ruleScattered = 'liuyao.rule.dongbian.scattered';
  static const String ruleDayClashUrges =
      'liuyao.rule.dongbian.day-clash-urges';
  static const String ruleProgress = 'liuyao.rule.dongbian.progress';
  static const String ruleRetreat = 'liuyao.rule.dongbian.retreat';
  static const String ruleReturnGenerates =
      'liuyao.rule.dongbian.return-generates';
  static const String ruleReturnOvercomes =
      'liuyao.rule.dongbian.return-overcomes';
  static const String ruleTransformsDrain =
      'liuyao.rule.dongbian.transforms-drain';
  static const String ruleOvercomesOutward =
      'liuyao.rule.dongbian.overcomes-outward';
  static const String ruleChangedVoid = 'liuyao.rule.dongbian.changed-void';
  static const String ruleChangedBreak = 'liuyao.rule.dongbian.changed-break';
  static const String ruleChangedTomb = 'liuyao.rule.dongbian.changed-tomb';
  static const String ruleChangedTerminal =
      'liuyao.rule.dongbian.changed-terminal';
  static const String ruleChangedJoin = 'liuyao.rule.dongbian.changed-join';
  static const String ruleChangedClash = 'liuyao.rule.dongbian.changed-clash';
  static const String ruleMovingGenerates =
      'liuyao.rule.shengke.moving-generates';
  static const String ruleMovingOvercomes =
      'liuyao.rule.shengke.moving-overcomes';
  static const String ruleMovingSupports =
      'liuyao.rule.shengke.moving-supports';
  static const String ruleGenerationSuppressesOvercoming =
      'liuyao.rule.shengke.generation-suppresses-overcoming';
  static const String ruleBindingSuppressesGeneration =
      'liuyao.rule.shengke.binding-suppresses-generation';
  static const String ruleBindingSuppressesOvercoming =
      'liuyao.rule.shengke.binding-suppresses-overcoming';
  static const String ruleContinuousGeneration =
      'liuyao.rule.shengke.continuous-generation';
  static const String ruleContinuousOvercoming =
      'liuyao.rule.shengke.continuous-overcoming';
  static const String ruleSelectedUseSpirit =
      'liuyao.rule.liuqin.selected-use-spirit';
  static const String ruleSelectedHiddenUseSpirit =
      'liuyao.rule.liuqin.selected-hidden-use-spirit';
  static const String ruleDuplicateUseSpirit =
      'liuyao.rule.liuqin.duplicate-use-spirit';
  static const String ruleSourceSpirit = 'liuyao.rule.liuqin.source-spirit';
  static const String ruleAdverseSpirit = 'liuyao.rule.liuqin.adverse-spirit';
  static const String ruleEnemySpirit = 'liuyao.rule.liuqin.enemy-spirit';
  static const String ruleIdleSpirit = 'liuyao.rule.liuqin.idle-spirit';
  static const String ruleFlightGeneratesHidden =
      'liuyao.rule.fushen.flight-generates-hidden';
  static const String ruleFlightOvercomesHidden =
      'liuyao.rule.fushen.flight-overcomes-hidden';
  static const String ruleHiddenGeneratesFlight =
      'liuyao.rule.fushen.hidden-generates-flight';
  static const String ruleHiddenOvercomesFlight =
      'liuyao.rule.fushen.hidden-overcomes-flight';
  static const String ruleHiddenReleased = 'liuyao.rule.fushen.hidden-released';
  static const String ruleHiddenSuppressed =
      'liuyao.rule.fushen.hidden-suppressed';
  static const String ruleDayJoins = 'liuyao.rule.special.day-joins';
  static const String ruleMonthJoins = 'liuyao.rule.special.month-joins';

  static const String actorReturnOvercome =
      'liuyao.project.availability.return-overcome-blocks';
  static const String actorRetreat =
      'liuyao.project.availability.retreat-blocks';
  static const String actorScattered =
      'liuyao.project.availability.scattered-blocks';
  static const String actorTrueVoid =
      'liuyao.project.availability.true-void-unavailable';
  static const String actorHiddenSuppressed =
      'liuyao.project.availability.hidden-suppressed';
  static const String actorVoid = 'liuyao.project.availability.void-suspends';
  static const String actorMonthBreak =
      'liuyao.project.availability.month-break-suspends';
  static const String actorBinding =
      'liuyao.project.availability.binding-suspends';
  static const String actorBindingOpened =
      'liuyao.project.availability.opened-binding-restores';

  static const String hiddenMovingGenerates =
      'liuyao.rule.shengke.hidden-moving-generates';
  static const String hiddenMovingOvercomes =
      'liuyao.rule.shengke.hidden-moving-overcomes';
  static const String attackerSuppressed =
      'liuyao.project.shengke.actor-suppressed';
  static const String yearCommand = 'liuyao.rule.special.year-command';

  static const String strengthClassification =
      'liuyao.project.verdict.strength-classification';
  static const String arbitrationOrder =
      'liuyao.project.verdict.arbitration-order';
  static const String firstMatch = 'liuyao.project.verdict.first-match';
  static const String overcomeMeetsGeneration =
      'liuyao.rule.verdict.overcome-meets-generation';

  static const String decisionReturnOvercomeWithoutL1Support =
      'liuyao.decision.return-overcome-without-l1-support';
  static const String decisionReturnGenerateUnblocked =
      'liuyao.decision.return-generate-unblocked';
  static const String decisionWeakUnrescuable =
      'liuyao.decision.weak-unrescuable';
  static const String decisionWeakAdverseActive =
      'liuyao.decision.weak-adverse-active';
  static const String decisionWeakUnsupported =
      'liuyao.decision.weak-unsupported';
  static const String decisionStrongClear = 'liuyao.decision.strong-clear';
  static const String decisionStrongWithConditions =
      'liuyao.decision.strong-with-conditions';
  static const String decisionStrongAdverseActive =
      'liuyao.decision.strong-adverse-active';
  static const String decisionMixedSourceContinuity =
      'liuyao.decision.mixed-source-continuity';
  static const String decisionMixedAdverseActive =
      'liuyao.decision.mixed-adverse-active';
  static const String decisionMixedRescuableConditions =
      'liuyao.decision.mixed-rescuable-conditions';
  static const String decisionMixedL1Support =
      'liuyao.decision.mixed-l1-support';
  static const String decisionMixedUnresolved =
      'liuyao.decision.mixed-unresolved';

  static const String conditionTrueVoid =
      'liuyao.condition.true-void.no-release';
  static const String conditionVoid = 'liuyao.condition.void.fill-or-clash';
  static const String conditionMonthBreak =
      'liuyao.condition.month-break.exit-fill-or-join';
  static const String conditionTomb = 'liuyao.condition.tomb.clash-open';
  static const String conditionChangedTomb =
      'liuyao.condition.changed-tomb.clash-open';
  static const String conditionBinding = 'liuyao.condition.binding.clash-open';
  static const String conditionChangedVoid =
      'liuyao.condition.changed-void.fill-or-clash';
  static const String conditionChangedBreak =
      'liuyao.condition.changed-break.exit-fill-or-join';
  static const String conditionTerminal =
      'liuyao.condition.terminal.changsheng-support';
  static const String conditionHiddenRelease =
      'liuyao.condition.hidden.release';
  static const String conditionHiddenSuppressed =
      'liuyao.condition.hidden.no-release-while-suppressed';

  static const String timingVoidFill = 'liuyao.timing.void.branch-fills';
  static const String timingVoidClash = 'liuyao.timing.void.branch-clash';
  static const String timingMonthBreakExit =
      'liuyao.timing.month-break.next-month';
  static const String timingMonthBreakFill =
      'liuyao.timing.month-break.branch-fills';
  static const String timingMonthBreakJoin =
      'liuyao.timing.month-break.branch-joins';
  static const String timingTombOpen = 'liuyao.timing.tomb.clash-opens';
  static const String timingBindingTargetClash =
      'liuyao.timing.binding.target-clash';
  static const String timingBindingPartnerClash =
      'liuyao.timing.binding.partner-clash';
  static const String timingChangedVoidFill =
      'liuyao.timing.changed-void.branch-fills';
  static const String timingChangedVoidClash =
      'liuyao.timing.changed-void.branch-clash';
  static const String timingChangedBreakExit =
      'liuyao.timing.changed-break.next-month';
  static const String timingChangedBreakFill =
      'liuyao.timing.changed-break.branch-fills';
  static const String timingChangedBreakJoin =
      'liuyao.timing.changed-break.branch-joins';
  static const String timingTerminalChangSheng =
      'liuyao.timing.terminal.changsheng-arrives';
  static const String timingHiddenFill = 'liuyao.timing.hidden.branch-fills';
  static const String timingHiddenFlightClash =
      'liuyao.timing.hidden.flight-clash';
}

class LiuYaoRuleCatalog {
  LiuYaoRuleCatalog._();

  static const int analysisSchemaVersion = 1;
  static const String ruleSetId = 'liuyao-zengshan-primary';
  static const String v1Compat = 'v1-compat';
  static const String v2 = 'v2';
  static const String current = v2;
  static const String sourceCatalogVersion = 'liuyao-evidence/1.0.0';

  static const List<LiuYaoSourceRecord> sources = <LiuYaoSourceRecord>[
    LiuYaoSourceRecord(
      sourceId: LiuYaoRuleIds.zengShanSource,
      kind: LiuYaoSourceKind.classicalWitness,
      title: '增删卜易（校对：中国男儿）',
      edition: 'fixed PDF witness',
      revisionOrFingerprint:
          'DE5C6C0CB5A73C47960A4D6C5EB87337CD677A59B768E15E42CFCB24C932FD68',
      publicLocator: 'public fixed-document locator recorded by the project',
      pageSystem: 'PDF page / printed page',
      adoptionStatus: LiuYaoAdoptionStatus.adopted,
      scope: 'Primary Liuyao classical predicates; quotes require page review.',
      adjudication: 'Adopted witness for the liuyao-zengshan-primary rule set.',
      reviewedOn: '2026-08-01',
    ),
    LiuYaoSourceRecord(
      sourceId: LiuYaoRuleIds.buShiSource,
      kind: LiuYaoSourceKind.classicalWitness,
      title: '卜筮正宗',
      edition: 'Distiller 2004 candidate PDF',
      revisionOrFingerprint:
          '1DB6308DED165DD19ECDAC5D50D0F1F6479BF4F2896A983C01D3EE5F31A08655',
      publicLocator: 'candidate fixed-document locator recorded by the project',
      pageSystem: 'candidate PDF page; rendering not reliable',
      adoptionStatus: LiuYaoAdoptionStatus.locatorOnly,
      scope: 'Sanxing and liuhai locators only.',
      adjudication:
          'Non-decision-capable until a page-level witness is reviewed.',
      reviewedOn: '2026-08-01',
      limitations:
          'Embedded font/rendering prevents reliable quotation review.',
    ),
    LiuYaoSourceRecord(
      sourceId: LiuYaoRuleIds.projectSource,
      kind: LiuYaoSourceKind.projectContract,
      title: 'Liuyao analysis contract',
      edition: sourceCatalogVersion,
      revisionOrFingerprint: 'rule-set:$ruleSetId@$v2',
      publicLocator: '.trellis/spec/domain/liuyao-analysis-engine.md',
      pageSystem: 'stable section locator',
      adoptionStatus: LiuYaoAdoptionStatus.adopted,
      scope: 'Software convergence, ordering, identity, and decision policy.',
      adjudication:
          'Executable project convention; never presented as a quote.',
      reviewedOn: '2026-08-01',
    ),
  ];

  static const Map<String, LiuYaoTagRuleSpec> tagRuleSpecs =
      <String, LiuYaoTagRuleSpec>{
    '临月建': (
      ruleId: LiuYaoRuleIds.ruleMonthCommand,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '月破': (
      ruleId: LiuYaoRuleIds.ruleMonthBreak,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '月生': (
      ruleId: LiuYaoRuleIds.ruleMonthGenerates,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '月克': (
      ruleId: LiuYaoRuleIds.ruleMonthOvercomes,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '旺': (
      ruleId: LiuYaoRuleIds.ruleProsperous,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '相': (
      ruleId: LiuYaoRuleIds.ruleSupported,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '休': (
      ruleId: LiuYaoRuleIds.ruleResting,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '囚': (
      ruleId: LiuYaoRuleIds.ruleConfined,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '死': (
      ruleId: LiuYaoRuleIds.ruleDead,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '临日建': (
      ruleId: LiuYaoRuleIds.ruleDayCommand,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '日扶': (
      ruleId: LiuYaoRuleIds.ruleDaySupports,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '日生': (
      ruleId: LiuYaoRuleIds.ruleDayGenerates,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '日克': (
      ruleId: LiuYaoRuleIds.ruleDayOvercomes,
      family: LiuYaoRuleFamily.wangShuai,
      stage: LiuYaoRuleStage.state
    ),
    '旬空': (
      ruleId: LiuYaoRuleIds.ruleVoid,
      family: LiuYaoRuleFamily.kongWang,
      stage: LiuYaoRuleStage.state
    ),
    '假空': (
      ruleId: LiuYaoRuleIds.ruleApparentVoid,
      family: LiuYaoRuleFamily.kongWang,
      stage: LiuYaoRuleStage.state
    ),
    '真空': (
      ruleId: LiuYaoRuleIds.ruleTrueVoid,
      family: LiuYaoRuleFamily.kongWang,
      stage: LiuYaoRuleStage.state
    ),
    '冲空': (
      ruleId: LiuYaoRuleIds.ruleVoidClashed,
      family: LiuYaoRuleFamily.kongWang,
      stage: LiuYaoRuleStage.state
    ),
    '入日墓': (
      ruleId: LiuYaoRuleIds.ruleDayTomb,
      family: LiuYaoRuleFamily.muJue,
      stage: LiuYaoRuleStage.state
    ),
    '入月墓': (
      ruleId: LiuYaoRuleIds.ruleMonthTomb,
      family: LiuYaoRuleFamily.muJue,
      stage: LiuYaoRuleStage.state
    ),
    '入动墓': (
      ruleId: LiuYaoRuleIds.ruleMovingTomb,
      family: LiuYaoRuleFamily.muJue,
      stage: LiuYaoRuleStage.state
    ),
    '出墓': (
      ruleId: LiuYaoRuleIds.ruleTombOpened,
      family: LiuYaoRuleFamily.muJue,
      stage: LiuYaoRuleStage.state
    ),
    '临绝': (
      ruleId: LiuYaoRuleIds.ruleTerminal,
      family: LiuYaoRuleFamily.muJue,
      stage: LiuYaoRuleStage.state
    ),
    '合住': (
      ruleId: LiuYaoRuleIds.ruleMovingBound,
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.availability
    ),
    '合起': (
      ruleId: 'liuyao.rule.hechong.still-activated-by-join',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.effects
    ),
    '合绊': (
      ruleId: LiuYaoRuleIds.ruleMutualBinding,
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.availability
    ),
    '冲开': (
      ruleId: LiuYaoRuleIds.ruleBindingOpened,
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.availability
    ),
    '相冲': (
      ruleId: 'liuyao.rule.hechong.mutual-clash',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.effects
    ),
    '三合局': (
      ruleId: 'liuyao.rule.hechong.three-harmony',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '三合成局': (
      ruleId: 'liuyao.rule.hechong.borrowed-three-harmony',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '半合': (
      ruleId: 'liuyao.rule.hechong.half-harmony',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '三刑': (
      ruleId: 'liuyao.rule.hechong.three-punishment',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '相刑': (
      ruleId: 'liuyao.rule.hechong.mutual-punishment',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '相害': (
      ruleId: 'liuyao.rule.hechong.mutual-harm',
      family: LiuYaoRuleFamily.heChong,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '独发': (
      ruleId: 'liuyao.rule.dongbian.single-moving',
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.facts
    ),
    '独静': (
      ruleId: 'liuyao.rule.dongbian.single-still',
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.facts
    ),
    '暗动': (
      ruleId: LiuYaoRuleIds.ruleHiddenMoving,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '日破': (
      ruleId: LiuYaoRuleIds.ruleDayBreak,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.availability
    ),
    '冲散': (
      ruleId: LiuYaoRuleIds.ruleScattered,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.availability
    ),
    '日冲': (
      ruleId: LiuYaoRuleIds.ruleDayClashUrges,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '化进神': (
      ruleId: LiuYaoRuleIds.ruleProgress,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '化退神': (
      ruleId: LiuYaoRuleIds.ruleRetreat,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.availability
    ),
    '回头生': (
      ruleId: LiuYaoRuleIds.ruleReturnGenerates,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '回头克': (
      ruleId: LiuYaoRuleIds.ruleReturnOvercomes,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.availability
    ),
    '化泄': (
      ruleId: LiuYaoRuleIds.ruleTransformsDrain,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '克出': (
      ruleId: LiuYaoRuleIds.ruleOvercomesOutward,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '化空': (
      ruleId: LiuYaoRuleIds.ruleChangedVoid,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.state
    ),
    '化破': (
      ruleId: LiuYaoRuleIds.ruleChangedBreak,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.state
    ),
    '化墓': (
      ruleId: LiuYaoRuleIds.ruleChangedTomb,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.state
    ),
    '化绝': (
      ruleId: LiuYaoRuleIds.ruleChangedTerminal,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.state
    ),
    '化合': (
      ruleId: LiuYaoRuleIds.ruleChangedJoin,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '化冲': (
      ruleId: LiuYaoRuleIds.ruleChangedClash,
      family: LiuYaoRuleFamily.dongBian,
      stage: LiuYaoRuleStage.effects
    ),
    '动爻生': (
      ruleId: LiuYaoRuleIds.ruleMovingGenerates,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.effects
    ),
    '动爻克': (
      ruleId: LiuYaoRuleIds.ruleMovingOvercomes,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.effects
    ),
    '动爻扶': (
      ruleId: LiuYaoRuleIds.ruleMovingSupports,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.effects
    ),
    '贪生忘克': (
      ruleId: LiuYaoRuleIds.ruleGenerationSuppressesOvercoming,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.conflict
    ),
    '贪合忘生': (
      ruleId: LiuYaoRuleIds.ruleBindingSuppressesGeneration,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.conflict
    ),
    '贪合忘克': (
      ruleId: LiuYaoRuleIds.ruleBindingSuppressesOvercoming,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.conflict
    ),
    '连续相生': (
      ruleId: LiuYaoRuleIds.ruleContinuousGeneration,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.effects
    ),
    '连续相克': (
      ruleId: LiuYaoRuleIds.ruleContinuousOvercoming,
      family: LiuYaoRuleFamily.shengKe,
      stage: LiuYaoRuleStage.effects
    ),
    '用神': (
      ruleId: LiuYaoRuleIds.ruleSelectedUseSpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '用神(伏)': (
      ruleId: LiuYaoRuleIds.ruleSelectedHiddenUseSpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '用神两现': (
      ruleId: LiuYaoRuleIds.ruleDuplicateUseSpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '元神': (
      ruleId: LiuYaoRuleIds.ruleSourceSpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '忌神': (
      ruleId: LiuYaoRuleIds.ruleAdverseSpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '仇神': (
      ruleId: LiuYaoRuleIds.ruleEnemySpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '闲神': (
      ruleId: LiuYaoRuleIds.ruleIdleSpirit,
      family: LiuYaoRuleFamily.liuQin,
      stage: LiuYaoRuleStage.roles
    ),
    '飞生伏': (
      ruleId: LiuYaoRuleIds.ruleFlightGeneratesHidden,
      family: LiuYaoRuleFamily.fuShen,
      stage: LiuYaoRuleStage.effects
    ),
    '飞克伏': (
      ruleId: LiuYaoRuleIds.ruleFlightOvercomesHidden,
      family: LiuYaoRuleFamily.fuShen,
      stage: LiuYaoRuleStage.effects
    ),
    '伏生飞': (
      ruleId: LiuYaoRuleIds.ruleHiddenGeneratesFlight,
      family: LiuYaoRuleFamily.fuShen,
      stage: LiuYaoRuleStage.effects
    ),
    '伏克飞': (
      ruleId: LiuYaoRuleIds.ruleHiddenOvercomesFlight,
      family: LiuYaoRuleFamily.fuShen,
      stage: LiuYaoRuleStage.effects
    ),
    '伏神得出': (
      ruleId: LiuYaoRuleIds.ruleHiddenReleased,
      family: LiuYaoRuleFamily.fuShen,
      stage: LiuYaoRuleStage.availability
    ),
    '伏神受制': (
      ruleId: LiuYaoRuleIds.ruleHiddenSuppressed,
      family: LiuYaoRuleFamily.fuShen,
      stage: LiuYaoRuleStage.availability
    ),
    '日合': (
      ruleId: LiuYaoRuleIds.ruleDayJoins,
      family: LiuYaoRuleFamily.special,
      stage: LiuYaoRuleStage.availability
    ),
    '月合': (
      ruleId: LiuYaoRuleIds.ruleMonthJoins,
      family: LiuYaoRuleFamily.special,
      stage: LiuYaoRuleStage.availability
    ),
    '太岁入爻': (
      ruleId: LiuYaoRuleIds.yearCommand,
      family: LiuYaoRuleFamily.special,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '六冲卦': (
      ruleId: 'liuyao.rule.guachange.six-clash',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '六合卦': (
      ruleId: 'liuyao.rule.guachange.six-harmony',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '游魂卦': (
      ruleId: 'liuyao.rule.guachange.wandering-soul',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '归魂卦': (
      ruleId: 'liuyao.rule.guachange.returning-soul',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '卦变六合': (
      ruleId: 'liuyao.rule.guachange.changes-to-six-harmony',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '卦变六冲': (
      ruleId: 'liuyao.rule.guachange.changes-to-six-clash',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '伏吟': (
      ruleId: 'liuyao.rule.guachange.repetition',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
    '反吟': (
      ruleId: 'liuyao.rule.guachange.reversal',
      family: LiuYaoRuleFamily.guaChange,
      stage: LiuYaoRuleStage.auxiliary
    ),
  };

  static final List<LiuYaoRuleRecord> rules = <LiuYaoRuleRecord>[
    for (final entry in tagRuleSpecs.entries) _tagRule(entry.key, entry.value),
    ..._projectRules,
  ];

  static final Map<String, LiuYaoSourceRecord> sourceById =
      <String, LiuYaoSourceRecord>{
    for (final source in sources) source.sourceId: source
  };
  static final Map<String, LiuYaoRuleRecord> ruleById =
      <String, LiuYaoRuleRecord>{for (final rule in rules) rule.ruleId: rule};
  static final Map<String, String> legacyTermToRuleId =
      Map<String, String>.unmodifiable(<String, String>{
    for (final rule in rules)
      if (rule.primaryTerm.isNotEmpty) rule.primaryTerm: rule.ruleId,
    for (final rule in rules)
      for (final alias in rule.aliases) alias: rule.ruleId,
  });

  static LiuYaoRuleSet resolve(String requestedVersion) {
    final version = requestedVersion == 'current' ? current : requestedVersion;
    if (version != v1Compat && version != v2) {
      throw ArgumentError.value(
        requestedVersion,
        'ruleSetVersion',
        'Unknown Liuyao rule-set version',
      );
    }
    return LiuYaoRuleSet(
      ruleSetId: ruleSetId,
      version: version,
      sourceCatalogVersion: sourceCatalogVersion,
    );
  }

  static LiuYaoRuleRecord? ruleForTerm(String term) {
    final ruleId = legacyTermToRuleId[term];
    return ruleId == null ? null : ruleById[ruleId];
  }

  static void validateOrThrow() {
    final errors = validate();
    if (errors.isNotEmpty) {
      throw StateError('Invalid Liuyao catalog:\n${errors.join('\n')}');
    }
  }

  static List<String> validate() {
    final errors = <String>[];
    if (sourceById.length != sources.length) {
      errors.add('Duplicate sourceId');
    }
    if (ruleById.length != rules.length) {
      errors.add('Duplicate ruleId');
    }
    final claimedTerms = <String>{};
    for (final rule in rules) {
      if (!rule.ruleId.startsWith('liuyao.')) {
        errors.add('Invalid rule namespace: ${rule.ruleId}');
      }
      for (final term in <String>[rule.primaryTerm, ...rule.aliases]) {
        if (term.isNotEmpty && !claimedTerms.add(term)) {
          errors.add('Term/alias resolves more than once: $term');
        }
      }
      if (rule.positiveFixtureIds.isEmpty &&
          rule.negativeFixtureIds.isEmpty &&
          (rule.coverageExemption == null ||
              rule.coverageExemption!.trim().isEmpty)) {
        errors.add('Rule lacks coverage contract: ${rule.ruleId}');
      }
      for (final reference in rule.evidenceRefs) {
        if (!sourceById.containsKey(reference.sourceId)) {
          errors.add('Dangling source ${reference.sourceId}: ${rule.ruleId}');
        }
        if (reference.referenceKind == LiuYaoReferenceKind.exactQuote) {
          if (reference.evidenceLevel != LiuYaoEvidenceLevel.a ||
              reference.quote == null ||
              reference.quote!.trim().isEmpty ||
              reference.reviewer == null ||
              reference.reviewer!.trim().isEmpty) {
            errors.add('Invalid exact quote evidence: ${rule.ruleId}');
          }
        } else if (reference.quote != null) {
          errors.add('Non-quote evidence carries quote text: ${rule.ruleId}');
        }
        if (reference.referenceKind == LiuYaoReferenceKind.locatorOnly &&
            rule.decisionCapable) {
          errors.add('Locator-only rule is decision-capable: ${rule.ruleId}');
        }
      }
    }
    for (final term in tagRuleSpecs.keys) {
      if (ruleForTerm(term) == null) {
        errors.add('Production term does not resolve: $term');
      }
    }
    return errors;
  }

  static LiuYaoRuleRecord _tagRule(String term, LiuYaoTagRuleSpec spec) {
    final locatorOnly = term == '三刑' || term == '相刑' || term == '相害';
    final auxiliary = spec.stage == LiuYaoRuleStage.auxiliary;
    return LiuYaoRuleRecord(
      ruleId: spec.ruleId,
      ruleSetVersions: const <String>[v1Compat, v2],
      family: spec.family,
      stage: spec.stage,
      primaryTerm: term,
      aliases: term == '用神(伏)' ? const <String>['用神（伏）'] : const <String>[],
      evidenceRefs: <LiuYaoEvidenceRef>[
        if (locatorOnly)
          LiuYaoEvidenceRef(
            sourceId: LiuYaoRuleIds.buShiSource,
            locator: 'candidate locator: $term',
            evidenceLevel: LiuYaoEvidenceLevel.c,
            referenceKind: LiuYaoReferenceKind.locatorOnly,
            adoptionNote: 'Kept as low-priority descriptive evidence only.',
          )
        else
          _zengShanEvidence(term),
      ],
      executable: true,
      decisionCapable: !locatorOnly && !auxiliary,
      adjudication: locatorOnly
          ? 'May be displayed but cannot determine the verdict.'
          : auxiliary
              ? 'Auxiliary evidence; never flips the use-spirit verdict.'
              : 'Adopted predicate with execution boundaries fixed by the rule set.',
      applicability: 'Produced only when its typed service predicate matches.',
      suppressionBoundary:
          'Actor availability and directed-effect status determine decision eligibility.',
      coverageExemption:
          'Producer and boundary coverage is maintained in the dedicated service tests.',
    );
  }

  static LiuYaoEvidenceRef _zengShanEvidence(String term) {
    return switch (term) {
      '回头生' => const LiuYaoEvidenceRef(
          sourceId: LiuYaoRuleIds.zengShanSource,
          locator: 'PDF 25 / printed 24, 五行相生章，复之震例',
          evidenceLevel: LiuYaoEvidenceLevel.a,
          referenceKind: LiuYaoReferenceKind.exactQuote,
          adoptionNote: 'Page-render and text reviewed.',
          quote: '化父母生兄爻，相生为吉',
          reviewer: 'Trellis source verification 2026-08-01',
        ),
      '暗动' => const LiuYaoEvidenceRef(
          sourceId: LiuYaoRuleIds.zengShanSource,
          locator: 'PDF 31 / printed 30, 日辰章',
          evidenceLevel: LiuYaoEvidenceLevel.a,
          referenceKind: LiuYaoReferenceKind.exactQuote,
          adoptionNote: 'Page-render and text reviewed.',
          quote: '冲旺相之静爻，即为暗动；冲衰弱之静爻，则为日破',
          reviewer: 'Trellis source verification 2026-08-01',
        ),
      '旬空' || '假空' || '真空' => const LiuYaoEvidenceRef(
          sourceId: LiuYaoRuleIds.zengShanSource,
          locator: 'PDF 46 / printed 45, 旬空章',
          evidenceLevel: LiuYaoEvidenceLevel.a,
          referenceKind: LiuYaoReferenceKind.exactQuote,
          adoptionNote:
              'Page-render and text reviewed; broader boundary is paraphrased.',
          quote: '旺不为空，动不为空',
          reviewer: 'Trellis source verification 2026-08-01',
        ),
      _ => LiuYaoEvidenceRef(
          sourceId: LiuYaoRuleIds.zengShanSource,
          locator: 'chapter locator for $term',
          evidenceLevel: LiuYaoEvidenceLevel.b,
          referenceKind: LiuYaoReferenceKind.paraphrase,
          adoptionNote:
              'Adopted as a reviewed paraphrase; no verbatim quote allowed.',
        ),
    };
  }

  static final List<LiuYaoRuleRecord> _projectRules = <LiuYaoRuleRecord>[
    for (final spec in <(String, String, LiuYaoRuleFamily, LiuYaoRuleStage)>[
      (
        LiuYaoRuleIds.actorReturnOvercome,
        '回头克阻断作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorRetreat,
        '化退阻断作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorScattered,
        '冲散阻断作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorTrueVoid,
        '真空不可用',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorHiddenSuppressed,
        '伏神受制阻断作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorVoid,
        '旬空悬置作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorMonthBreak,
        '月破悬置作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorBinding,
        '合绊悬置作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.actorBindingOpened,
        '冲开恢复作用者',
        LiuYaoRuleFamily.availability,
        LiuYaoRuleStage.availability
      ),
      (
        LiuYaoRuleIds.hiddenMovingGenerates,
        '暗动生',
        LiuYaoRuleFamily.shengKe,
        LiuYaoRuleStage.effects
      ),
      (
        LiuYaoRuleIds.hiddenMovingOvercomes,
        '暗动克',
        LiuYaoRuleFamily.shengKe,
        LiuYaoRuleStage.effects
      ),
      (
        LiuYaoRuleIds.attackerSuppressed,
        '作用者受制',
        LiuYaoRuleFamily.shengKe,
        LiuYaoRuleStage.conflict
      ),
      (
        LiuYaoRuleIds.strengthClassification,
        '强弱三分类',
        LiuYaoRuleFamily.strength,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.arbitrationOrder,
        '裁决层级顺序',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.firstMatch,
        '决策表首行命中',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionReturnOvercomeWithoutL1Support,
        '用神回头受克',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionReturnGenerateUnblocked,
        '用神回头得生',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionWeakUnrescuable,
        '衰而无救',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionWeakAdverseActive,
        '忌神乘衰攻用',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionWeakUnsupported,
        '休囚无生扶',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionStrongClear,
        '日月生扶而无阻',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionStrongWithConditions,
        '旺而有待',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionStrongAdverseActive,
        '旺而忌动',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionMixedSourceContinuity,
        '元神动而生用',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionMixedAdverseActive,
        '忌神动而克用',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionMixedRescuableConditions,
        '悬而未决',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionMixedL1Support,
        '克处逢生',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.decisionMixedUnresolved,
        '扶抑并见',
        LiuYaoRuleFamily.decision,
        LiuYaoRuleStage.verdict
      ),
      (
        LiuYaoRuleIds.conditionTrueVoid,
        '真空到底无用',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionVoid,
        '待出空',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionMonthBreak,
        '待出月',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionTomb,
        '待冲开墓库',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionChangedTomb,
        '待冲开化墓',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionBinding,
        '待冲开',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionChangedVoid,
        '待变爻填实',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionChangedBreak,
        '待变爻出月填实',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionTerminal,
        '待长生扶起',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionHiddenRelease,
        '待出伏',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.conditionHiddenSuppressed,
        '伏神受制无解',
        LiuYaoRuleFamily.condition,
        LiuYaoRuleStage.condition
      ),
      (
        LiuYaoRuleIds.timingVoidFill,
        '值日填实旬空',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingVoidClash,
        '冲空则起',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingMonthBreakExit,
        '出月解除月破',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingMonthBreakFill,
        '值日填实月破',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingMonthBreakJoin,
        '逢合解破',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingTombOpen,
        '冲开墓库',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingBindingTargetClash,
        '冲用神解合',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingBindingPartnerClash,
        '冲合神解合',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingChangedVoidFill,
        '变爻值日填实化空',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingChangedVoidClash,
        '冲起化空',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingChangedBreakExit,
        '出月解除化破',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingChangedBreakFill,
        '变爻值日填实化破',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingChangedBreakJoin,
        '变爻逢合解破',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingTerminalChangSheng,
        '绝处逢生',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingHiddenFill,
        '伏神值日引出',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
      (
        LiuYaoRuleIds.timingHiddenFlightClash,
        '冲飞引伏',
        LiuYaoRuleFamily.timing,
        LiuYaoRuleStage.timing
      ),
    ])
      _projectRule(spec.$1, spec.$2, spec.$3, spec.$4),
    LiuYaoRuleRecord(
      ruleId: LiuYaoRuleIds.overcomeMeetsGeneration,
      ruleSetVersions: const <String>[v1Compat, v2],
      family: LiuYaoRuleFamily.decision,
      stage: LiuYaoRuleStage.verdict,
      primaryTerm: '克处逢生（古籍谓词）',
      evidenceRefs: const <LiuYaoEvidenceRef>[
        LiuYaoEvidenceRef(
          sourceId: LiuYaoRuleIds.zengShanSource,
          locator: 'PDF 26 / printed 25, 五行相克章，否之讼例',
          evidenceLevel: LiuYaoEvidenceLevel.a,
          referenceKind: LiuYaoReferenceKind.exactQuote,
          adoptionNote: 'Page-render and text reviewed.',
          quote: '克处逢生',
          reviewer: 'Trellis source verification 2026-08-01',
        ),
      ],
      executable: true,
      decisionCapable: true,
      adjudication: 'Classical predicate precedes the project decision row.',
      positiveFixtureIds: const <String>['liuyao.case.golden.014'],
      negativeFixtureIds: const <String>['liuyao.case.golden.013'],
    ),
  ];

  static LiuYaoRuleRecord _projectRule(
    String ruleId,
    String term,
    LiuYaoRuleFamily family,
    LiuYaoRuleStage stage,
  ) {
    return LiuYaoRuleRecord(
      ruleId: ruleId,
      ruleSetVersions: const <String>[v1Compat, v2],
      family: family,
      stage: stage,
      primaryTerm: term,
      evidenceRefs: const <LiuYaoEvidenceRef>[
        LiuYaoEvidenceRef(
          sourceId: LiuYaoRuleIds.projectSource,
          locator: 'analysis-contract:phase-order-and-policy',
          evidenceLevel: LiuYaoEvidenceLevel.d,
          referenceKind: LiuYaoReferenceKind.projectConvention,
          adoptionNote:
              'Executable software convention, not a classical quotation.',
        ),
      ],
      executable: true,
      decisionCapable: true,
      adjudication: 'Pinned by the versioned project analysis contract.',
      coverageExemption:
          'Covered by catalog, verdict, condition, or timing contract tests.',
    );
  }
}
