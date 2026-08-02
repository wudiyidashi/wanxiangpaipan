import 'dart:convert';
import 'dart:io';

enum LiuYaoClassicsReadMode { full, evaluationDraft }

class LiuYaoClassicsFixture {
  LiuYaoClassicsFixture({
    required this.fixtureVersion,
    required this.sourceCatalogVersion,
    required this.ruleSetId,
    required this.ruleSetVersion,
    required this.holdoutSalt,
    required this.holdoutSize,
    required this.holdoutCohortHash,
    required List<LiuYaoFixtureHoldoutMember> holdoutMembers,
    required List<LiuYaoClassicsCase> cases,
  })  : holdoutMembers =
            List<LiuYaoFixtureHoldoutMember>.unmodifiable(holdoutMembers),
        cases = List<LiuYaoClassicsCase>.unmodifiable(cases);

  final String fixtureVersion;
  final String sourceCatalogVersion;
  final String ruleSetId;
  final String ruleSetVersion;
  final String holdoutSalt;
  final int holdoutSize;
  final String holdoutCohortHash;
  final List<LiuYaoFixtureHoldoutMember> holdoutMembers;
  final List<LiuYaoClassicsCase> cases;

  factory LiuYaoClassicsFixture.fromFile(
    File file, {
    LiuYaoClassicsReadMode readMode = LiuYaoClassicsReadMode.full,
  }) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Fixture root must be an object.');
    }
    return LiuYaoClassicsFixture.fromJson(decoded, readMode: readMode);
  }

  factory LiuYaoClassicsFixture.fromJson(
    Map<String, Object?> json, {
    LiuYaoClassicsReadMode readMode = LiuYaoClassicsReadMode.full,
  }) {
    final holdout = _object(json, 'holdout');
    return LiuYaoClassicsFixture(
      fixtureVersion: _string(json, 'fixtureVersion'),
      sourceCatalogVersion: _string(json, 'sourceCatalogVersion'),
      ruleSetId: _string(json, 'ruleSetId'),
      ruleSetVersion: _string(json, 'ruleSetVersion'),
      holdoutSalt: _string(holdout, 'salt'),
      holdoutSize: _integer(holdout, 'size'),
      holdoutCohortHash: _string(holdout, 'cohortHash'),
      holdoutMembers: _list(holdout, 'members')
          .map(
            (value) => LiuYaoFixtureHoldoutMember.fromJson(
              _asObject(value),
            ),
          )
          .toList(),
      cases: _list(json, 'cases')
          .map(
            (value) => LiuYaoClassicsCase.fromJson(
              _asObject(value),
              readMode: readMode,
            ),
          )
          .toList(),
    );
  }
}

class LiuYaoFixtureHoldoutMember {
  const LiuYaoFixtureHoldoutMember({
    required this.caseId,
    required this.selectionHash,
  });

  final String caseId;
  final String selectionHash;

  factory LiuYaoFixtureHoldoutMember.fromJson(Map<String, Object?> json) =>
      LiuYaoFixtureHoldoutMember(
        caseId: _string(json, 'caseId'),
        selectionHash: _string(json, 'selectionHash'),
      );
}

class LiuYaoClassicsCase {
  LiuYaoClassicsCase({
    required this.caseId,
    required this.caseKind,
    required this.evaluationSplit,
    required this.question,
    required this.pan,
    required this.useSpirit,
    required this.reference,
    required this.sourceRefs,
    required this.ruleIds,
    required this.unknowns,
    required this.reviewStatus,
    required this.coverage,
    required this.expected,
    this.evaluationReferenceWithheld = false,
  });

  final String caseId;
  final String caseKind;
  final String evaluationSplit;
  final String question;
  final LiuYaoFixturePan pan;
  final LiuYaoFixtureUseSpirit useSpirit;
  final LiuYaoFixtureReference reference;
  final List<LiuYaoFixtureSourceRef> sourceRefs;
  final List<String> ruleIds;
  final List<String> unknowns;
  final String reviewStatus;
  final List<String> coverage;
  final LiuYaoFixtureExpected expected;
  final bool evaluationReferenceWithheld;

  factory LiuYaoClassicsCase.fromJson(
    Map<String, Object?> json, {
    LiuYaoClassicsReadMode readMode = LiuYaoClassicsReadMode.full,
  }) {
    final bool withholdEvaluationReference =
        readMode == LiuYaoClassicsReadMode.evaluationDraft &&
            _string(json, 'evaluationSplit') == 'holdout';
    return LiuYaoClassicsCase(
      caseId: _string(json, 'caseId'),
      caseKind: _string(json, 'caseKind'),
      evaluationSplit: _string(json, 'evaluationSplit'),
      question: _string(json, 'question'),
      pan: LiuYaoFixturePan.fromJson(_object(json, 'pan')),
      useSpirit: LiuYaoFixtureUseSpirit.fromJson(_object(json, 'useSpirit')),
      reference: LiuYaoFixtureReference.fromJson(
        _object(json, 'reference'),
        withholdAdjudication: withholdEvaluationReference,
      ),
      sourceRefs: _list(json, 'sourceRefs')
          .map((value) => LiuYaoFixtureSourceRef.fromJson(_asObject(value)))
          .toList(),
      ruleIds: _stringList(json, 'ruleIds'),
      unknowns: _stringList(json, 'unknowns'),
      reviewStatus: _string(json, 'reviewStatus'),
      coverage: _stringList(json, 'coverage'),
      expected: withholdEvaluationReference
          ? LiuYaoFixtureExpected.withheld()
          : LiuYaoFixtureExpected.fromJson(_object(json, 'expected')),
      evaluationReferenceWithheld: withholdEvaluationReference,
    );
  }
}

class LiuYaoFixturePan {
  LiuYaoFixturePan({
    required this.numbers,
    required this.monthBranch,
    required this.dayGanZhi,
    required this.declaredMainGuaName,
    required this.declaredChangingGuaName,
    required this.declaredMovingPositions,
  });

  final List<int> numbers;
  final String monthBranch;
  final String dayGanZhi;
  final String declaredMainGuaName;
  final String? declaredChangingGuaName;
  final List<int> declaredMovingPositions;

  factory LiuYaoFixturePan.fromJson(Map<String, Object?> json) =>
      LiuYaoFixturePan(
        numbers: _list(json, 'numbers').map((value) => value as int).toList(),
        monthBranch: _string(json, 'monthBranch'),
        dayGanZhi: _string(json, 'dayGanZhi'),
        declaredMainGuaName: _string(json, 'declaredMainGuaName'),
        declaredChangingGuaName:
            _nullableString(json, 'declaredChangingGuaName'),
        declaredMovingPositions: _list(json, 'declaredMovingPositions')
            .map((value) => value as int)
            .toList(),
      );
}

class LiuYaoFixtureUseSpirit {
  LiuYaoFixtureUseSpirit({
    required this.mode,
    required this.position,
    required this.declaredActorId,
    required this.declaredLiuQin,
    required this.declaredBranch,
    required this.declaredWuXing,
  });

  final String mode;
  final int position;
  final String declaredActorId;
  final String declaredLiuQin;
  final String declaredBranch;
  final String declaredWuXing;

  factory LiuYaoFixtureUseSpirit.fromJson(Map<String, Object?> json) =>
      LiuYaoFixtureUseSpirit(
        mode: _string(json, 'mode'),
        position: _integer(json, 'position'),
        declaredActorId: _string(json, 'declaredActorId'),
        declaredLiuQin: _string(json, 'declaredLiuQin'),
        declaredBranch: _string(json, 'declaredBranch'),
        declaredWuXing: _string(json, 'declaredWuXing'),
      );
}

class LiuYaoFixtureReference {
  LiuYaoFixtureReference({
    required this.chapter,
    required this.printedPages,
    required this.referenceKind,
    required this.adjudication,
  });

  final String chapter;
  final String printedPages;
  final String referenceKind;
  final String adjudication;

  factory LiuYaoFixtureReference.fromJson(
    Map<String, Object?> json, {
    bool withholdAdjudication = false,
  }) =>
      LiuYaoFixtureReference(
        chapter: _string(json, 'chapter'),
        printedPages: _string(json, 'printedPages'),
        referenceKind: _string(json, 'referenceKind'),
        adjudication: withholdAdjudication
            ? LiuYaoFixtureExpected.withheldValue
            : _string(json, 'adjudication'),
      );
}

class LiuYaoFixtureSourceRef {
  LiuYaoFixtureSourceRef({
    required this.sourceId,
    required this.locator,
    required this.evidenceLevel,
    required this.referenceKind,
  });

  final String sourceId;
  final String locator;
  final String evidenceLevel;
  final String referenceKind;

  factory LiuYaoFixtureSourceRef.fromJson(Map<String, Object?> json) =>
      LiuYaoFixtureSourceRef(
        sourceId: _string(json, 'sourceId'),
        locator: _string(json, 'locator'),
        evidenceLevel: _string(json, 'evidenceLevel'),
        referenceKind: _string(json, 'referenceKind'),
      );
}

class LiuYaoFixtureExpected {
  static const String withheldValue = '[withheld-until-holdout-reveal]';

  LiuYaoFixtureExpected({
    required this.trend,
    required this.nuance,
    required this.conditionRuleIds,
    required this.absentConditionRuleIds,
    required this.factorRuleIds,
    required this.timingBranches,
    required this.hasUnrescuedCondition,
    required this.decisionRowId,
    required this.factorIds,
    required this.conditionIds,
    required this.timingIds,
  });

  final String trend;
  final String? nuance;
  final List<String> conditionRuleIds;
  final List<String> absentConditionRuleIds;
  final List<String> factorRuleIds;
  final List<String> timingBranches;
  final bool hasUnrescuedCondition;
  final String decisionRowId;
  final List<String> factorIds;
  final List<String> conditionIds;
  final List<String> timingIds;

  factory LiuYaoFixtureExpected.withheld() => LiuYaoFixtureExpected(
        trend: withheldValue,
        nuance: null,
        conditionRuleIds: const <String>[],
        absentConditionRuleIds: const <String>[],
        factorRuleIds: const <String>[],
        timingBranches: const <String>[],
        hasUnrescuedCondition: false,
        decisionRowId: '',
        factorIds: const <String>[],
        conditionIds: const <String>[],
        timingIds: const <String>[],
      );

  factory LiuYaoFixtureExpected.fromJson(Map<String, Object?> json) =>
      LiuYaoFixtureExpected(
        trend: _string(json, 'trend'),
        nuance: _nullableString(json, 'nuance'),
        conditionRuleIds: _stringList(json, 'conditionRuleIds'),
        absentConditionRuleIds: _stringList(json, 'absentConditionRuleIds'),
        factorRuleIds: _stringList(json, 'factorRuleIds'),
        timingBranches: _stringList(json, 'timingBranches'),
        hasUnrescuedCondition: _boolean(json, 'hasUnrescuedCondition'),
        decisionRowId: _stringAllowEmpty(json, 'decisionRowId'),
        factorIds: _stringList(json, 'factorIds'),
        conditionIds: _stringList(json, 'conditionIds'),
        timingIds: _stringList(json, 'timingIds'),
      );
}

Map<String, Object?> _object(Map<String, Object?> json, String key) =>
    _asObject(json[key]);

Map<String, Object?> _asObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw const FormatException('Expected an object.');
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is List<Object?>) return value;
  throw FormatException('$key must be a list.');
}

List<String> _stringList(Map<String, Object?> json, String key) =>
    _list(json, key).map((value) {
      if (value is! String) throw FormatException('$key must contain strings.');
      return value;
    }).toList();

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$key must be a non-empty string.');
}

String _stringAllowEmpty(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is String) return value as String?;
  throw FormatException('$key must be a string or null.');
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('$key must be an integer.');
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}
