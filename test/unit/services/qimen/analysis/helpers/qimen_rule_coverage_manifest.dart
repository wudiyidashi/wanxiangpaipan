import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';

class QimenRuleCoverageEntry {
  QimenRuleCoverageEntry({
    required this.ruleId,
    required List<String> sourceIds,
    required List<String> positiveTestRefs,
    required List<String> negativeTestRefs,
    required List<String> decisionOrConflictRuleIds,
    required List<String> goldenCoverageTags,
    this.decisionUsageExemption,
    this.goldenCoverageExemption,
  })  : sourceIds = List<String>.unmodifiable(sourceIds),
        positiveTestRefs = List<String>.unmodifiable(positiveTestRefs),
        negativeTestRefs = List<String>.unmodifiable(negativeTestRefs),
        decisionOrConflictRuleIds =
            List<String>.unmodifiable(decisionOrConflictRuleIds),
        goldenCoverageTags = List<String>.unmodifiable(goldenCoverageTags);

  final String ruleId;
  final List<String> sourceIds;
  final List<String> positiveTestRefs;
  final List<String> negativeTestRefs;
  final List<String> decisionOrConflictRuleIds;
  final String? decisionUsageExemption;
  final List<String> goldenCoverageTags;
  final String? goldenCoverageExemption;
}

class QimenRuleCoverageManifest {
  QimenRuleCoverageManifest._();

  static const String _catalogMatrix =
      'test/unit/services/qimen/analysis/qimen_catalog_test.dart#'
      'the stem-response table covers all 81 QiYi pairs once';
  static const String _focusMatrix =
      'test/unit/services/qimen/analysis/qimen_focus_resolver_test.dart#'
      'keeps primary roles and exact category roles';
  static const String _stateMatrix =
      'test/unit/services/qimen/analysis/qimen_fact_evaluators_test.dart#'
      'covers the independent 25-relation star and door matrices';
  static const String _constraintMatrix =
      'test/unit/services/qimen/analysis/qimen_rule_coverage_test.dart#'
      'remaining constraint rules have independent positive and negative cases';
  static const String _punishmentMatrix =
      'test/unit/services/qimen/analysis/qimen_fact_evaluators_test.dart#'
      'evaluates all six punishments only at persisted duty palace';
  static const String _tombMatrix =
      'test/unit/services/qimen/analysis/qimen_fact_evaluators_test.dart#'
      'uses the adopted complete QiYi tomb palace table';
  static const String _structureMatrix =
      'test/unit/services/qimen/analysis/qimen_rule_coverage_test.dart#'
      'structure rules have independent positive and negative cases';
  static const String _stemResponseMatrix =
      'test/unit/services/qimen/analysis/qimen_fact_evaluators_test.dart#'
      'all 81 typed pairs have independent positive and negative cases';
  static const String _formationMatrix =
      'test/unit/services/qimen/analysis/qimen_rule_coverage_test.dart#'
      'every executable formation rule has independent positive and negative cases';
  static const String _skyNetExclusion =
      'test/unit/services/qimen/analysis/qimen_fact_evaluators_test.dart#'
      'does not equate a generic Gui-plus-Gui pair with sky net';
  static const String _relationMatrix =
      'test/unit/services/qimen/analysis/qimen_rule_coverage_test.dart#'
      'relation rules have positive, negative, and incomplete-focus cases';
  static const String _explicitConflict =
      'test/unit/services/qimen/analysis/qimen_conflict_verdict_test.dart#'
      'combined Fu-Yin explicitly subsumes equal-tier component facts';
  static const String _focusConflict =
      'test/unit/services/qimen/analysis/qimen_conflict_verdict_test.dart#'
      'applies focus specificity before tier precedence';
  static const String _tierConflict =
      'test/unit/services/qimen/analysis/qimen_conflict_verdict_test.dart#'
      'applies tier precedence when focus specificity is equal';
  static const String _unresolvedConflict =
      'test/unit/services/qimen/analysis/qimen_conflict_verdict_test.dart#'
      'retains same-tier opposition as an unresolved conflict';
  static const String _verdictMatrix =
      'test/unit/services/qimen/analysis/qimen_conflict_verdict_test.dart#'
      'covers every decision row with a unique first match';
  static const String _yingQiMatrix =
      'test/unit/services/qimen/analysis/qimen_ying_qi_service_test.dart#'
      'deduplicates evidence and orders explicit day/month scales';
  static const String _yingQiNegative =
      'test/unit/services/qimen/analysis/qimen_ying_qi_service_test.dart#'
      'emits no candidate from facts lacking admitted trigger links';
  static const String _secondaryHorseNegative =
      'test/unit/services/qimen/analysis/qimen_ying_qi_service_test.dart#'
      'secondary horse does not create a focus activation candidate';
  static const String _validAnalyzer =
      'test/unit/services/qimen/analysis/qimen_analyzer_test.dart#'
      'analyzes the fixed full pan deterministically without persistence';
  static const String _invalidAnalyzer =
      'test/unit/services/qimen/analysis/qimen_analyzer_test.dart#'
      'history adapter reanalyzes v1 and diagnoses future schemas';

  static final List<QimenRuleCoverageEntry> all =
      List<QimenRuleCoverageEntry>.unmodifiable(_build());

  static final Map<String, QimenRuleCoverageEntry> byRuleId =
      Map<String, QimenRuleCoverageEntry>.unmodifiable(
    <String, QimenRuleCoverageEntry>{
      for (final entry in all) entry.ruleId: entry,
    },
  );

  static List<QimenRuleCoverageEntry> _build() {
    final result = <QimenRuleCoverageEntry>[];

    void add(
      String ruleId, {
      required List<String> positive,
      required List<String> negative,
      List<String> decisionOrConflict = const <String>[],
      String? decisionExemption,
      List<String> goldenTags = const <String>[],
      String? goldenExemption,
    }) {
      result.add(QimenRuleCoverageEntry(
        ruleId: ruleId,
        sourceIds: QimenRuleCatalog.rule(ruleId).sourceIds,
        positiveTestRefs: positive,
        negativeTestRefs: negative,
        decisionOrConflictRuleIds: decisionOrConflict,
        decisionUsageExemption: decisionExemption,
        goldenCoverageTags: goldenTags,
        goldenCoverageExemption: goldenExemption,
      ));
    }

    add(
      QimenRuleCatalog.inputIntegrity,
      positive: const <String>[_invalidAnalyzer],
      negative: const <String>[_validAnalyzer],
      decisionOrConflict: const <String>[QimenRuleCatalog.decision00],
      goldenExemption: 'Invalid inputs are frozen by diagnostic unit cases.',
    );

    for (final ruleId in const <String>[
      QimenRuleCatalog.focusSelf,
      QimenRuleCatalog.focusMatter,
    ]) {
      add(
        ruleId,
        positive: const <String>[_focusMatrix],
        negative: const <String>[_invalidAnalyzer],
        decisionOrConflict: const <String>[QimenRuleCatalog.decision00],
        goldenTags: const <String>['population:sourceBacked'],
      );
    }

    const focusGoldenTags = <String, String>{
      QimenRuleCatalog.focusGeneral: 'category:general',
      QimenRuleCatalog.focusCareer: 'category:career',
      QimenRuleCatalog.focusWealth: 'category:wealth',
      QimenRuleCatalog.focusRelationship: 'category:relationship',
      QimenRuleCatalog.focusHealth: 'category:health',
      QimenRuleCatalog.focusStudy: 'category:study',
      QimenRuleCatalog.focusTravel: 'category:travel',
      QimenRuleCatalog.focusLitigation: 'category:litigation',
    };
    for (final entry in focusGoldenTags.entries) {
      add(
        entry.key,
        positive: const <String>[_focusMatrix],
        negative: const <String>[_focusMatrix],
        decisionExemption: 'Category focus only locates persisted indicators.',
        goldenTags: <String>[entry.value],
      );
    }

    for (final ruleId in const <String>[
      QimenRuleCatalog.starStateWang,
      QimenRuleCatalog.starStateXiang,
      QimenRuleCatalog.starStateXiu,
      QimenRuleCatalog.starStateQiu,
      QimenRuleCatalog.starStateFei,
      QimenRuleCatalog.doorSeasonWang,
      QimenRuleCatalog.doorSeasonXiang,
      QimenRuleCatalog.doorSeasonXiu,
      QimenRuleCatalog.doorSeasonQiu,
      QimenRuleCatalog.doorSeasonFei,
      QimenRuleCatalog.doorStateSame,
      QimenRuleCatalog.doorGeneratesPalace,
      QimenRuleCatalog.palaceGeneratesDoor,
      QimenRuleCatalog.doorControlsPalace,
      QimenRuleCatalog.palaceControlsDoor,
    ]) {
      add(
        ruleId,
        positive: const <String>[_stateMatrix],
        negative: const <String>[_stateMatrix],
        decisionExemption: 'State facts are contextual and never decide alone.',
        goldenExemption: 'The independent 25-cell state tables are exhaustive.',
      );
    }

    for (final ruleId in const <String>[
      QimenRuleCatalog.doorPressure,
      QimenRuleCatalog.voidState,
    ]) {
      add(
        ruleId,
        positive: const <String>[_constraintMatrix],
        negative: const <String>[_constraintMatrix],
        decisionOrConflict: const <String>[QimenRuleCatalog.decision20],
        goldenExemption:
            'Constraint branches are locked by focused table tests.',
      );
    }
    add(
      QimenRuleCatalog.instrumentPunishment,
      positive: const <String>[_punishmentMatrix],
      negative: const <String>[_punishmentMatrix],
      decisionOrConflict: const <String>[QimenRuleCatalog.decision20],
      goldenExemption: 'All six duty-palace punishment rows are exhaustive.',
    );
    add(
      QimenRuleCatalog.qiYiTomb,
      positive: const <String>[_tombMatrix],
      negative: const <String>[_tombMatrix],
      decisionOrConflict: const <String>[QimenRuleCatalog.decision20],
      goldenTags: const <String>['constraint:qiYiTomb'],
    );
    add(
      QimenRuleCatalog.horseActivation,
      positive: const <String>[_constraintMatrix],
      negative: const <String>[_constraintMatrix],
      decisionExemption:
          'Horse activation is corroborating only and never suppresses a fact.',
      goldenExemption: 'Primary and secondary horse paths have focused tests.',
    );

    for (final ruleId in const <String>[
      QimenRuleCatalog.starFuYin,
      QimenRuleCatalog.doorFuYin,
      QimenRuleCatalog.combinedFuYin,
      QimenRuleCatalog.starFanYin,
      QimenRuleCatalog.doorFanYin,
      QimenRuleCatalog.combinedFanYin,
    ]) {
      add(
        ruleId,
        positive: const <String>[_structureMatrix],
        negative: const <String>[_structureMatrix],
        decisionOrConflict: ruleId == QimenRuleCatalog.combinedFuYin ||
                ruleId == QimenRuleCatalog.combinedFanYin
            ? const <String>[QimenRuleCatalog.conflictExplicitPair]
            : const <String>[],
        decisionExemption: ruleId == QimenRuleCatalog.combinedFuYin ||
                ruleId == QimenRuleCatalog.combinedFanYin
            ? null
            : 'Component structure facts are subsumed by their combined fact.',
        goldenTags: ruleId == QimenRuleCatalog.starFuYin ||
                ruleId == QimenRuleCatalog.doorFuYin ||
                ruleId == QimenRuleCatalog.combinedFuYin
            ? const <String>['structure:fuYin']
            : const <String>[],
        goldenExemption: ruleId == QimenRuleCatalog.starFuYin ||
                ruleId == QimenRuleCatalog.doorFuYin ||
                ruleId == QimenRuleCatalog.combinedFuYin
            ? null
            : 'Fan-Yin is covered by independent full-table mutations.',
      );
    }
    add(
      QimenRuleCatalog.fiveNotMeeting,
      positive: const <String>[_structureMatrix],
      negative: const <String>[_structureMatrix],
      decisionOrConflict: const <String>[QimenRuleCatalog.decision10],
      goldenExemption: 'All admitted day/hour behavior is table-tested.',
    );

    for (final spec in QimenRuleCatalog.stemResponseSpecs) {
      final hasGolden = spec.ruleId == 'QMV1-F-STEM-XIN-REN';
      add(
        spec.ruleId,
        positive: const <String>[_stemResponseMatrix, _catalogMatrix],
        negative: const <String>[_stemResponseMatrix],
        decisionExemption: 'Stem responses are contextual in v1.',
        goldenTags: hasGolden
            ? const <String>['stemResponse:XIN-REN']
            : const <String>[],
        goldenExemption: hasGolden
            ? null
            : 'All 81 typed pairs are exhaustively table-tested.',
      );
    }

    const formationGoldenTags = <String, String>{
      QimenRuleCatalog.punishmentPattern: 'formation:punishmentPattern',
      QimenRuleCatalog.fireEntersMetal: 'formation:fireEntersMetal',
      QimenRuleCatalog.metalEntersFire: 'formation:metalEntersFire',
      QimenRuleCatalog.hiddenPalacePattern: 'formation:hiddenPalace',
      QimenRuleCatalog.flyingPalacePattern: 'formation:flyingPalace',
    };
    for (final ruleId in <String>{
      ...QimenRuleCatalog.formationSpecs.map((value) => value.ruleId),
      QimenRuleCatalog.threeWonderDuty,
    }) {
      final goldenTag = formationGoldenTags[ruleId];
      add(
        ruleId,
        positive: const <String>[_formationMatrix],
        negative: const <String>[_formationMatrix],
        decisionExemption: 'Formation facts are corroborating in v1.',
        goldenTags: goldenTag == null ? const <String>[] : <String>[goldenTag],
        goldenExemption: goldenTag == null
            ? 'The executable formation catalog is exhaustively mutated.'
            : null,
      );
    }
    add(
      QimenRuleCatalog.skyNet,
      positive: const <String>[_skyNetExclusion],
      negative: const <String>[_skyNetExclusion],
      decisionExemption: 'Sky Net is an explicit v1 exclusion.',
      goldenExemption:
          'The disputed generic formula is locked as notApplicable.',
    );

    add(
      QimenRuleCatalog.favorableConvergence,
      positive: const <String>[_relationMatrix],
      negative: const <String>[_relationMatrix],
      decisionOrConflict: const <String>[QimenRuleCatalog.decision40],
      goldenTags: const <String>['decision:QMV1-D40'],
    );
    add(
      QimenRuleCatalog.adverseConvergence,
      positive: const <String>[_relationMatrix],
      negative: const <String>[_relationMatrix],
      decisionOrConflict: const <String>[QimenRuleCatalog.decision30],
      goldenTags: const <String>['decision:QMV1-D30'],
    );

    const conflictTests = <String, String>{
      QimenRuleCatalog.conflictExplicitPair: _explicitConflict,
      QimenRuleCatalog.conflictFocusSpecificity: _focusConflict,
      QimenRuleCatalog.conflictTierPrecedence: _tierConflict,
      QimenRuleCatalog.conflictUnresolved: _unresolvedConflict,
    };
    for (final entry in conflictTests.entries) {
      add(
        entry.key,
        positive: <String>[entry.value],
        negative: const <String>[_validAnalyzer],
        decisionOrConflict: <String>[entry.key],
        goldenTags: entry.key == QimenRuleCatalog.conflictExplicitPair
            ? const <String>['structure:fuYin']
            : entry.key == QimenRuleCatalog.conflictUnresolved
                ? const <String>['decision:QMV1-D50']
                : const <String>[],
        goldenExemption: entry.key ==
                    QimenRuleCatalog.conflictFocusSpecificity ||
                entry.key == QimenRuleCatalog.conflictTierPrecedence
            ? 'The exact precedence branch is clearer in isolated unit facts.'
            : null,
      );
    }

    for (final ruleId in const <String>[
      QimenRuleCatalog.decision00,
      QimenRuleCatalog.decision10,
      QimenRuleCatalog.decision20,
      QimenRuleCatalog.decision30,
      QimenRuleCatalog.decision40,
      QimenRuleCatalog.decision50,
      QimenRuleCatalog.decision60,
    ]) {
      add(
        ruleId,
        positive: const <String>[_verdictMatrix],
        negative: const <String>[_verdictMatrix],
        decisionOrConflict: <String>[ruleId],
        goldenTags: <String>['decision:$ruleId'],
      );
    }

    for (final ruleId in const <String>[
      QimenRuleCatalog.yingQiConditionRelease,
      QimenRuleCatalog.yingQiSolarTerm,
    ]) {
      add(
        ruleId,
        positive: const <String>[_yingQiMatrix],
        negative: const <String>[_yingQiNegative],
        decisionExemption: 'YingQi is downstream of the verdict.',
        goldenExemption:
            'Candidate linkage and scale are frozen in unit tests.',
      );
    }
    add(
      QimenRuleCatalog.yingQiHorse,
      positive: const <String>[_yingQiMatrix],
      negative: const <String>[_secondaryHorseNegative],
      decisionExemption: 'YingQi is downstream of the verdict.',
      goldenExemption: 'Primary and secondary horse paths are isolated.',
    );
    for (final ruleId in const <String>[
      QimenRuleCatalog.yingQiFuYin,
      QimenRuleCatalog.yingQiFanYin,
      QimenRuleCatalog.yingQiStem,
    ]) {
      add(
        ruleId,
        positive: const <String>[_yingQiNegative],
        negative: const <String>[_yingQiNegative],
        decisionExemption: 'This v1 generator is explicitly notApplicable.',
        goldenExemption: 'The exclusion trace is the frozen v1 contract.',
      );
    }

    return result;
  }
}
