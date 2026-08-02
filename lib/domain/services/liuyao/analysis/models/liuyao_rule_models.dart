/// Evidence grade for a single source reference.
enum LiuYaoEvidenceLevel {
  a,
  b,
  c,
  d,
}

/// How a source may be represented to users.
enum LiuYaoReferenceKind {
  exactQuote,
  paraphrase,
  projectConvention,
  locatorOnly,
}

enum LiuYaoSourceKind {
  classicalWitness,
  projectContract,
}

enum LiuYaoAdoptionStatus {
  adopted,
  locatorOnly,
}

enum LiuYaoRuleStage {
  input,
  facts,
  roles,
  state,
  availability,
  effects,
  auxiliary,
  conflict,
  verdict,
  condition,
  timing,
}

enum LiuYaoRuleFamily {
  wangShuai,
  kongWang,
  muJue,
  heChong,
  dongBian,
  shengKe,
  liuQin,
  fuShen,
  special,
  guaChange,
  availability,
  strength,
  decision,
  condition,
  timing,
}

class LiuYaoSourceRecord {
  const LiuYaoSourceRecord({
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
    this.limitations,
  });

  final String sourceId;
  final LiuYaoSourceKind kind;
  final String title;
  final String edition;
  final String revisionOrFingerprint;
  final String publicLocator;
  final String pageSystem;
  final LiuYaoAdoptionStatus adoptionStatus;
  final String scope;
  final String adjudication;
  final String reviewedOn;
  final String? limitations;
}

class LiuYaoEvidenceRef {
  const LiuYaoEvidenceRef({
    required this.sourceId,
    required this.locator,
    required this.evidenceLevel,
    required this.referenceKind,
    required this.adoptionNote,
    this.quote,
    this.reviewer,
  });

  final String sourceId;
  final String locator;
  final LiuYaoEvidenceLevel evidenceLevel;
  final LiuYaoReferenceKind referenceKind;
  final String adoptionNote;
  final String? quote;
  final String? reviewer;
}

class LiuYaoRuleRecord {
  const LiuYaoRuleRecord({
    required this.ruleId,
    required this.ruleSetVersions,
    required this.family,
    required this.stage,
    required this.primaryTerm,
    required this.evidenceRefs,
    required this.executable,
    required this.decisionCapable,
    required this.adjudication,
    this.aliases = const <String>[],
    this.applicability = '',
    this.suppressionBoundary = '',
    this.positiveFixtureIds = const <String>[],
    this.negativeFixtureIds = const <String>[],
    this.coverageExemption,
  });

  final String ruleId;
  final List<String> ruleSetVersions;
  final LiuYaoRuleFamily family;
  final LiuYaoRuleStage stage;
  final String primaryTerm;
  final List<String> aliases;
  final List<LiuYaoEvidenceRef> evidenceRefs;
  final bool executable;
  final bool decisionCapable;
  final String adjudication;
  final String applicability;
  final String suppressionBoundary;
  final List<String> positiveFixtureIds;
  final List<String> negativeFixtureIds;
  final String? coverageExemption;

  List<String> get sourceIds =>
      evidenceRefs.map((reference) => reference.sourceId).toSet().toList()
        ..sort();
}

class LiuYaoRuleSet {
  const LiuYaoRuleSet({
    required this.ruleSetId,
    required this.version,
    required this.sourceCatalogVersion,
  });

  final String ruleSetId;
  final String version;
  final String sourceCatalogVersion;
}
