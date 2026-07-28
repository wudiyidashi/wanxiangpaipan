enum QimenSourceKind {
  classicalText('classicalText'),
  modernReference('modernReference'),
  publishedCase('publishedCase'),
  externalCrossCheck('externalCrossCheck'),
  projectConvention('projectConvention');

  const QimenSourceKind(this.id);
  final String id;

  static QimenSourceKind fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen source kind: $id'),
      );
}

enum QimenRuleFamily {
  input('input'),
  focus('focus'),
  state('state'),
  constraint('constraint'),
  structure('structure'),
  stemResponse('stemResponse'),
  formation('formation'),
  relation('relation'),
  conflict('conflict'),
  verdict('verdict'),
  yingQi('yingQi');

  const QimenRuleFamily(this.id);
  final String id;

  static QimenRuleFamily fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen rule family: $id'),
      );
}

enum QimenFactRole {
  support('support'),
  inhibit('inhibit'),
  suspend('suspend'),
  neutral('neutral');

  const QimenFactRole(this.id);
  final String id;

  static QimenFactRole fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen fact role: $id'),
      );
}

enum QimenConflictTier {
  decisive('decisive', 0),
  conditional('conditional', 1),
  corroborating('corroborating', 2),
  contextual('contextual', 3);

  const QimenConflictTier(this.id, this.order);
  final String id;
  final int order;

  static QimenConflictTier fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen conflict tier: $id'),
      );
}

enum QimenFactScope {
  global('global'),
  palace('palace'),
  focusRelation('focusRelation');

  const QimenFactScope(this.id);
  final String id;

  static QimenFactScope fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('Unknown Qimen fact scope: $id'),
      );
}

class QimenSourceRef {
  const QimenSourceRef({
    required this.sourceId,
    required this.kind,
    required this.title,
    required this.editionOrRevision,
    required this.locator,
    required this.claimSummary,
    required this.adjudicationNote,
    this.accessedOn,
  });

  final String sourceId;
  final QimenSourceKind kind;
  final String title;
  final String editionOrRevision;
  final String locator;
  final String claimSummary;
  final String adjudicationNote;
  final String? accessedOn;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sourceId': sourceId,
        'kind': kind.id,
        'title': title,
        'editionOrRevision': editionOrRevision,
        'locator': locator,
        'claimSummary': claimSummary,
        'adjudicationNote': adjudicationNote,
        'accessedOn': accessedOn,
      };

  factory QimenSourceRef.fromJson(Map<String, dynamic> json) => QimenSourceRef(
        sourceId: json['sourceId'] as String,
        kind: QimenSourceKind.fromId(json['kind'] as String),
        title: json['title'] as String,
        editionOrRevision: json['editionOrRevision'] as String,
        locator: json['locator'] as String,
        claimSummary: json['claimSummary'] as String,
        adjudicationNote: json['adjudicationNote'] as String,
        accessedOn: json['accessedOn'] as String?,
      );
}

class QimenRuleDefinition {
  QimenRuleDefinition({
    required this.ruleId,
    required this.family,
    required this.introducedIn,
    required this.displayTerm,
    required this.factRole,
    required this.conflictTier,
    required List<QimenFactScope> supportedScopes,
    required List<String> sourceIds,
    required this.evaluatorId,
    this.decisionCapable = false,
    List<String> resolvesRuleIds = const <String>[],
    List<String> suppressedByRuleIds = const <String>[],
  })  : supportedScopes = List<QimenFactScope>.unmodifiable(supportedScopes),
        sourceIds = List<String>.unmodifiable(sourceIds),
        resolvesRuleIds = List<String>.unmodifiable(resolvesRuleIds),
        suppressedByRuleIds = List<String>.unmodifiable(suppressedByRuleIds);

  final String ruleId;
  final QimenRuleFamily family;
  final String introducedIn;
  final String displayTerm;
  final QimenFactRole factRole;
  final QimenConflictTier conflictTier;
  final List<QimenFactScope> supportedScopes;
  final List<String> sourceIds;
  final String evaluatorId;
  final bool decisionCapable;
  final List<String> resolvesRuleIds;
  final List<String> suppressedByRuleIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ruleId': ruleId,
        'family': family.id,
        'introducedIn': introducedIn,
        'displayTerm': displayTerm,
        'factRole': factRole.id,
        'conflictTier': conflictTier.id,
        'supportedScopes': supportedScopes.map((value) => value.id).toList(),
        'sourceIds': sourceIds,
        'evaluatorId': evaluatorId,
        'decisionCapable': decisionCapable,
        'resolvesRuleIds': resolvesRuleIds,
        'suppressedByRuleIds': suppressedByRuleIds,
      };

  factory QimenRuleDefinition.fromJson(Map<String, dynamic> json) =>
      QimenRuleDefinition(
        ruleId: json['ruleId'] as String,
        family: QimenRuleFamily.fromId(json['family'] as String),
        introducedIn: json['introducedIn'] as String,
        displayTerm: json['displayTerm'] as String,
        factRole: QimenFactRole.fromId(json['factRole'] as String),
        conflictTier: QimenConflictTier.fromId(json['conflictTier'] as String),
        supportedScopes: (json['supportedScopes'] as List)
            .map((value) => QimenFactScope.fromId(value as String))
            .toList(growable: false),
        sourceIds: List<String>.from(json['sourceIds'] as List),
        evaluatorId: json['evaluatorId'] as String,
        decisionCapable: json['decisionCapable'] as bool? ?? false,
        resolvesRuleIds: List<String>.from(
          json['resolvesRuleIds'] as List? ?? const <String>[],
        ),
        suppressedByRuleIds: List<String>.from(
          json['suppressedByRuleIds'] as List? ?? const <String>[],
        ),
      );
}

class QimenInputRef {
  const QimenInputRef({required this.path, required this.value});

  final String path;
  final String value;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'value': value,
      };

  factory QimenInputRef.fromJson(Map<String, dynamic> json) => QimenInputRef(
        path: json['path'] as String,
        value: json['value'] as String,
      );
}

class QimenAnalysisDiagnostic {
  const QimenAnalysisDiagnostic({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'path': path,
        'message': message,
      };

  factory QimenAnalysisDiagnostic.fromJson(Map<String, dynamic> json) =>
      QimenAnalysisDiagnostic(
        code: json['code'] as String,
        path: json['path'] as String,
        message: json['message'] as String,
      );
}
