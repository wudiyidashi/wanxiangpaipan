import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/divination_system.dart';

part 'dlr_rule_contract.freezed.dart';

enum DlrRuleKind { classic, project, display }

enum DlrEvidenceLevel { a, b, c, d }

enum DlrReplayStatus { complete, incomplete, legacyUnknown }

enum DlrAnalysisCompatibility { current, legacyUnknown, versionMismatch }

/// Published rule-set identifiers. A behavior change requires a new value.
class DlrRuleSetVersions {
  DlrRuleSetVersions._();

  static const String legacyUnknown = 'legacyUnknown';
  static const String evidenceCatalog = 'daliuren-classics/1.0.0';
  static const String panCurrent = 'daliuren-pan/1.0.0';
  static const String analysisCurrent = 'daliuren-analysis-project-v1/1.0.0';
  static const String castInputSchema = '1.0.0';

  static DlrAnalysisCompatibility resolveAnalysisCompatibility({
    required String sourcePanRuleSetVersion,
    required DlrCastInputSnapshot? castInputSnapshot,
  }) {
    if (sourcePanRuleSetVersion.trim().isEmpty ||
        sourcePanRuleSetVersion == legacyUnknown) {
      return DlrAnalysisCompatibility.legacyUnknown;
    }
    if (sourcePanRuleSetVersion != panCurrent) {
      return DlrAnalysisCompatibility.versionMismatch;
    }
    if (castInputSnapshot == null ||
        castInputSnapshot.replayStatus == DlrReplayStatus.legacyUnknown) {
      return DlrAnalysisCompatibility.legacyUnknown;
    }
    return DlrAnalysisCompatibility.current;
  }
}

/// C00 classic rules approved for deterministic execution in the current
/// evidence catalog.
///
/// `adopted` and A/B evidence do not imply executable approval. Updating this
/// set requires a matching evidence-catalog version change.
class DlrClassicExecutableRuleIds {
  DlrClassicExecutableRuleIds._();

  static const String heavenPlateRotation =
      'dlr.rule.pan.003.heaven-plate-rotation';
  static const String firstLesson = 'dlr.rule.pan.005.first-lesson';
  static const String secondLesson = 'dlr.rule.pan.006.second-lesson';
  static const String thirdLesson = 'dlr.rule.pan.007.third-lesson';
  static const String fourthLesson = 'dlr.rule.pan.008.fourth-lesson';

  static const Set<String> all = <String>{
    heavenPlateRotation,
    firstLesson,
    secondLesson,
    thirdLesson,
    fourthLesson,
  };
}

/// Stable identities for the current project-v1 analysis heuristics.
///
/// These IDs deliberately do not use the `dlr.rule.*` classic namespace.
class DlrProjectRuleIds {
  DlrProjectRuleIds._();

  static const String keGeChongShen = 'dlr.project.analysis.kege.chong-shen';
  static const String keGeYuanShou = 'dlr.project.analysis.kege.yuan-shou';
  static const String keGeZhiYi = 'dlr.project.analysis.kege.zhi-yi';
  static const String keGeSheHai = 'dlr.project.analysis.kege.she-hai';
  static const String keGeHaoShi = 'dlr.project.analysis.kege.hao-shi';
  static const String keGeTanShe = 'dlr.project.analysis.kege.tan-she';
  static const String keGeHuShi = 'dlr.project.analysis.kege.hu-shi';
  static const String keGeDongSheYanMu =
      'dlr.project.analysis.kege.dong-she-yan-mu';
  static const String keGeBieZe = 'dlr.project.analysis.kege.bie-ze';
  static const String keGeBaZhuan = 'dlr.project.analysis.kege.ba-zhuan';
  static const String keGeBuYu = 'dlr.project.analysis.kege.bu-yu';
  static const String keGeZiRen = 'dlr.project.analysis.kege.zi-ren';
  static const String keGeZiXin = 'dlr.project.analysis.kege.zi-xin';
  static const String keGeJingLanShe = 'dlr.project.analysis.kege.jing-lan-she';
  static const String keGeFanYin = 'dlr.project.analysis.kege.fan-yin';

  static const String ganAboveGeneratesSelf =
      'dlr.project.analysis.host-guest.gan-above-generates-self';
  static const String ganAboveControlsSelf =
      'dlr.project.analysis.host-guest.gan-above-controls-self';
  static const String selfControlsGanAbove =
      'dlr.project.analysis.host-guest.self-controls-gan-above';
  static const String selfGeneratesGanAbove =
      'dlr.project.analysis.host-guest.self-generates-gan-above';
  static const String ganAbovePeerSupport =
      'dlr.project.analysis.host-guest.gan-above-peer-support';
  static const String affairReceivesSupport =
      'dlr.project.analysis.host-guest.affair-receives-support';
  static const String affairIsControlled =
      'dlr.project.analysis.host-guest.affair-is-controlled';
  static const String affairControlsAbove =
      'dlr.project.analysis.host-guest.affair-controls-above';
  static const String affairGeneratesAbove =
      'dlr.project.analysis.host-guest.affair-generates-above';
  static const String branchAbovePeerSupport =
      'dlr.project.analysis.host-guest.branch-above-peer-support';
  static const String ganAboveVoid =
      'dlr.project.analysis.host-guest.gan-above-void';
  static const String branchAboveVoid =
      'dlr.project.analysis.host-guest.branch-above-void';

  static const String initialTransmissionVoid =
      'dlr.project.analysis.transmission.initial-void';
  static const String middleTransmissionVoid =
      'dlr.project.analysis.transmission.middle-void';
  static const String finalTransmissionVoid =
      'dlr.project.analysis.transmission.final-void';
  static const String transmissionGeneralPolarity =
      'dlr.project.analysis.transmission.general-polarity';
  static const String initialTransmissionControlsSelf =
      'dlr.project.analysis.transmission.initial-controls-self';
  static const String initialTransmissionGeneratesSelf =
      'dlr.project.analysis.transmission.initial-generates-self';
  static const String progressiveGeneration =
      'dlr.project.analysis.transmission.progressive-generation';
  static const String progressiveControl =
      'dlr.project.analysis.transmission.progressive-control';
  static const String transmissionReturnsToGenerateSelf =
      'dlr.project.analysis.transmission.returns-to-generate-self';
  static const String transmissionReturnsToControlSelf =
      'dlr.project.analysis.transmission.returns-to-control-self';
  static const String threeHarmonyFormation =
      'dlr.project.analysis.transmission.three-harmony-formation';

  static const String shenShaOnTransmission =
      'dlr.project.analysis.shensha.on-transmission';
  static const String travellingHorseInitial =
      'dlr.project.analysis.shensha.travelling-horse-initial';
}

/// A validated, immutable rule identity.
class DlrRuleRef {
  factory DlrRuleRef({
    required String ruleId,
    required String ruleSetVersion,
    required DlrRuleKind kind,
    required DlrEvidenceLevel evidenceLevel,
    List<String> sourceIds = const <String>[],
    bool executableApproved = false,
  }) {
    _validateRuleRef(
      ruleId: ruleId,
      ruleSetVersion: ruleSetVersion,
      kind: kind,
      evidenceLevel: evidenceLevel,
      sourceIds: sourceIds,
      executableApproved: executableApproved,
    );
    return DlrRuleRef._(
      ruleId: ruleId,
      ruleSetVersion: ruleSetVersion,
      kind: kind,
      evidenceLevel: evidenceLevel,
      sourceIds: List<String>.unmodifiable(sourceIds),
      executableApproved: executableApproved,
    );
  }

  factory DlrRuleRef.project(
    String ruleId, {
    String ruleSetVersion = DlrRuleSetVersions.analysisCurrent,
  }) =>
      DlrRuleRef(
        ruleId: ruleId,
        ruleSetVersion: ruleSetVersion,
        kind: DlrRuleKind.project,
        evidenceLevel: DlrEvidenceLevel.d,
      );

  factory DlrRuleRef.fromJson(Map<String, dynamic> json) {
    final rawSourceIds = json['sourceIds'];
    if (rawSourceIds != null && rawSourceIds is! List) {
      throw ArgumentError.value(rawSourceIds, 'sourceIds', '来源 ID 必须是字符串数组');
    }
    final sourceIds = <String>[];
    for (final value in rawSourceIds as List? ?? const <dynamic>[]) {
      if (value is! String) {
        throw ArgumentError.value(value, 'sourceIds', '来源 ID 必须是字符串');
      }
      sourceIds.add(value);
    }
    final rawExecutableApproved = json['executableApproved'];
    if (rawExecutableApproved != null && rawExecutableApproved is! bool) {
      throw ArgumentError.value(
        rawExecutableApproved,
        'executableApproved',
        '古籍执行批准状态必须是布尔值',
      );
    }

    return DlrRuleRef(
      ruleId: _requiredString(json['ruleId'], 'ruleId'),
      ruleSetVersion: _requiredString(
        json['ruleSetVersion'],
        'ruleSetVersion',
      ),
      kind: _enumByName(DlrRuleKind.values, json['kind'], 'kind'),
      evidenceLevel: _enumByName(
        DlrEvidenceLevel.values,
        json['evidenceLevel'],
        'evidenceLevel',
      ),
      sourceIds: sourceIds,
      executableApproved: rawExecutableApproved as bool? ?? false,
    );
  }

  const DlrRuleRef._({
    required this.ruleId,
    required this.ruleSetVersion,
    required this.kind,
    required this.evidenceLevel,
    required this.sourceIds,
    required this.executableApproved,
  });

  final String ruleId;
  final String ruleSetVersion;
  final DlrRuleKind kind;
  final DlrEvidenceLevel evidenceLevel;
  final List<String> sourceIds;

  /// Mirrors C00's approval bit for classic rules only.
  ///
  /// Project rules are executable heuristics by kind and rule-set version;
  /// display rules are never executable.
  final bool executableApproved;

  bool get isExecutable => switch (kind) {
        DlrRuleKind.classic => executableApproved,
        DlrRuleKind.project => true,
        DlrRuleKind.display => false,
      };

  DlrRuleRef copyWith({
    String? ruleId,
    String? ruleSetVersion,
    DlrRuleKind? kind,
    DlrEvidenceLevel? evidenceLevel,
    List<String>? sourceIds,
    bool? executableApproved,
  }) =>
      DlrRuleRef(
        ruleId: ruleId ?? this.ruleId,
        ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
        kind: kind ?? this.kind,
        evidenceLevel: evidenceLevel ?? this.evidenceLevel,
        sourceIds: sourceIds ?? this.sourceIds,
        executableApproved: executableApproved ?? this.executableApproved,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ruleId': ruleId,
        'ruleSetVersion': ruleSetVersion,
        'kind': kind.name,
        'evidenceLevel': evidenceLevel.name,
        'sourceIds': sourceIds.toList(growable: false),
        'executableApproved': executableApproved,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DlrRuleRef &&
          other.ruleId == ruleId &&
          other.ruleSetVersion == ruleSetVersion &&
          other.kind == kind &&
          other.evidenceLevel == evidenceLevel &&
          _stringListsEqual(other.sourceIds, sourceIds) &&
          other.executableApproved == executableApproved;

  @override
  int get hashCode => Object.hash(
        ruleId,
        ruleSetVersion,
        kind,
        evidenceLevel,
        Object.hashAll(sourceIds),
        executableApproved,
      );

  @override
  String toString() => 'DlrRuleRef($ruleId@$ruleSetVersion)';
}

@Freezed(copyWith: false)
class DlrCastInputSnapshot with _$DlrCastInputSnapshot {
  const factory DlrCastInputSnapshot._validated({
    @Default(DlrRuleSetVersions.castInputSchema) String schemaVersion,
    required CastMethod castMethod,
    required DateTime castTime,
    required int utcOffsetMinutes,
    required Map<String, dynamic> normalizedInput,
    required DlrReplayStatus replayStatus,
    @Default(<String>[]) List<String> missingFields,
  }) = _DlrCastInputSnapshot;

  const DlrCastInputSnapshot._();

  factory DlrCastInputSnapshot({
    String schemaVersion = DlrRuleSetVersions.castInputSchema,
    required CastMethod castMethod,
    required DateTime castTime,
    required int utcOffsetMinutes,
    required Map<String, dynamic> normalizedInput,
    required DlrReplayStatus replayStatus,
    List<String> missingFields = const <String>[],
  }) =>
      DlrCastInputSnapshot.capture(
        schemaVersion: schemaVersion,
        castMethod: castMethod,
        castTime: castTime,
        utcOffsetMinutes: utcOffsetMinutes,
        normalizedInput: normalizedInput,
        replayStatus: replayStatus,
        missingFields: missingFields,
      );

  factory DlrCastInputSnapshot.fromJson(Map<String, dynamic> json) {
    final rawSchemaVersion = json['schemaVersion'];
    if (rawSchemaVersion != null && rawSchemaVersion is! String) {
      throw ArgumentError.value(
        rawSchemaVersion,
        'schemaVersion',
        '快照 schema 版本必须是字符串',
      );
    }
    final rawCastTime = json['castTime'];
    if (rawCastTime is! String) {
      throw ArgumentError.value(rawCastTime, 'castTime', '起课时间必须是字符串');
    }
    final DateTime castTime;
    try {
      castTime = DateTime.parse(rawCastTime);
    } on FormatException {
      throw ArgumentError.value(rawCastTime, 'castTime', '起课时间格式不合法');
    }
    final rawUtcOffsetMinutes = json['utcOffsetMinutes'];
    if (rawUtcOffsetMinutes is! num ||
        !rawUtcOffsetMinutes.isFinite ||
        rawUtcOffsetMinutes != rawUtcOffsetMinutes.roundToDouble()) {
      throw ArgumentError.value(
        rawUtcOffsetMinutes,
        'utcOffsetMinutes',
        'UTC offset 必须是有限整数',
      );
    }
    final rawNormalizedInput = json['normalizedInput'];
    if (rawNormalizedInput is! Map) {
      throw ArgumentError.value(
        rawNormalizedInput,
        'normalizedInput',
        '规范化输入必须是 JSON 对象',
      );
    }
    final normalizedInput = <String, dynamic>{};
    for (final entry in rawNormalizedInput.entries) {
      if (entry.key is! String) {
        throw ArgumentError.value(
          entry.key,
          'normalizedInput',
          'JSON 对象键必须是字符串',
        );
      }
      normalizedInput[entry.key as String] = entry.value;
    }
    final rawMissingFields = json['missingFields'];
    if (rawMissingFields != null && rawMissingFields is! List) {
      throw ArgumentError.value(
        rawMissingFields,
        'missingFields',
        '缺失字段必须是字符串数组',
      );
    }
    final missingFields = <String>[];
    for (final value in rawMissingFields as List? ?? const <dynamic>[]) {
      if (value is! String) {
        throw ArgumentError.value(value, 'missingFields', '缺失字段必须是字符串');
      }
      missingFields.add(value);
    }

    return DlrCastInputSnapshot.capture(
      schemaVersion:
          rawSchemaVersion as String? ?? DlrRuleSetVersions.castInputSchema,
      castMethod: _enumByName(
        CastMethod.values,
        json['castMethod'],
        'castMethod',
      ),
      castTime: castTime,
      utcOffsetMinutes: rawUtcOffsetMinutes.toInt(),
      normalizedInput: normalizedInput,
      replayStatus: _enumByName(
        DlrReplayStatus.values,
        json['replayStatus'],
        'replayStatus',
      ),
      missingFields: missingFields,
    );
  }

  factory DlrCastInputSnapshot.capture({
    String schemaVersion = DlrRuleSetVersions.castInputSchema,
    required CastMethod castMethod,
    required DateTime castTime,
    required int utcOffsetMinutes,
    required Map<String, dynamic> normalizedInput,
    required DlrReplayStatus replayStatus,
    List<String> missingFields = const <String>[],
  }) {
    if (!_isDlrCastMethod(castMethod)) {
      throw ArgumentError.value(
        castMethod,
        'castMethod',
        '不是大六壬支持的起课方式',
      );
    }
    if (schemaVersion.trim().isEmpty) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        '快照 schema 版本不能为空',
      );
    }
    if (replayStatus == DlrReplayStatus.complete && missingFields.isNotEmpty) {
      throw ArgumentError.value(
        missingFields,
        'missingFields',
        '可完整重放的快照不能声明缺失字段',
      );
    }
    if (replayStatus == DlrReplayStatus.incomplete && missingFields.isEmpty) {
      throw ArgumentError.value(
        missingFields,
        'missingFields',
        '不可完整重放的快照必须声明缺失字段',
      );
    }

    return DlrCastInputSnapshot._validated(
      schemaVersion: schemaVersion,
      castMethod: castMethod,
      castTime: castTime,
      utcOffsetMinutes: utcOffsetMinutes,
      normalizedInput: _copyJsonMap(normalizedInput),
      replayStatus: replayStatus,
      missingFields: List<String>.unmodifiable(missingFields),
    );
  }

  DlrCastInputSnapshot copyWith({
    String? schemaVersion,
    CastMethod? castMethod,
    DateTime? castTime,
    int? utcOffsetMinutes,
    Map<String, dynamic>? normalizedInput,
    DlrReplayStatus? replayStatus,
    List<String>? missingFields,
  }) =>
      DlrCastInputSnapshot.capture(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        castMethod: castMethod ?? this.castMethod,
        castTime: castTime ?? this.castTime,
        utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
        normalizedInput: normalizedInput ?? this.normalizedInput,
        replayStatus: replayStatus ?? this.replayStatus,
        missingFields: missingFields ?? this.missingFields,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'castMethod': castMethod.name,
        'castTime': castTime.toIso8601String(),
        'utcOffsetMinutes': utcOffsetMinutes,
        'normalizedInput': _copyJsonMap(normalizedInput),
        'replayStatus': replayStatus.name,
        'missingFields': List<String>.unmodifiable(missingFields),
      };
}

bool _isDlrCastMethod(CastMethod method) => switch (method) {
      CastMethod.time ||
      CastMethod.reportNumber ||
      CastMethod.computer ||
      CastMethod.manual =>
        true,
      _ => false,
    };

final RegExp _classicRuleIdPattern = RegExp(
  r'^dlr\.rule(?:\.[a-z0-9]+(?:-[a-z0-9]+)*)+$',
);
final RegExp _projectRuleIdPattern = RegExp(
  r'^dlr\.project\.(?:analysis|pan)(?:\.[a-z0-9]+(?:-[a-z0-9]+)*)+$',
);
final RegExp _displayRuleIdPattern = RegExp(
  r'^dlr\.display(?:\.[a-z0-9]+(?:-[a-z0-9]+)*)+$',
);
final RegExp _sourceIdPattern = RegExp(
  r'^dlr\.source(?:\.[a-z0-9]+(?:-[a-z0-9]+)*)+$',
);

void _validateRuleRef({
  required String ruleId,
  required String ruleSetVersion,
  required DlrRuleKind kind,
  required DlrEvidenceLevel evidenceLevel,
  required List<String> sourceIds,
  required bool executableApproved,
}) {
  final idPattern = switch (kind) {
    DlrRuleKind.classic => _classicRuleIdPattern,
    DlrRuleKind.project => _projectRuleIdPattern,
    DlrRuleKind.display => _displayRuleIdPattern,
  };
  if (!idPattern.hasMatch(ruleId)) {
    throw ArgumentError.value(
      ruleId,
      'ruleId',
      '规则 ID 与 ${kind.name} 命名域不匹配',
    );
  }
  if (ruleSetVersion.trim().isEmpty) {
    throw ArgumentError.value(
      ruleSetVersion,
      'ruleSetVersion',
      '规则集版本不能为空',
    );
  }
  if (ruleSetVersion != ruleSetVersion.trim()) {
    throw ArgumentError.value(
      ruleSetVersion,
      'ruleSetVersion',
      '规则集版本不能包含首尾空白',
    );
  }
  for (final sourceId in sourceIds) {
    if (!_sourceIdPattern.hasMatch(sourceId)) {
      throw ArgumentError.value(sourceId, 'sourceIds', '来源 ID 不合法');
    }
  }

  if (kind == DlrRuleKind.classic &&
      (evidenceLevel == DlrEvidenceLevel.a ||
          evidenceLevel == DlrEvidenceLevel.b) &&
      sourceIds.isEmpty) {
    throw ArgumentError.value(
      sourceIds,
      'sourceIds',
      '古籍 A/B 级规则必须提供 C00 来源 ID',
    );
  }
  if (kind != DlrRuleKind.classic && evidenceLevel != DlrEvidenceLevel.d) {
    throw ArgumentError.value(
      evidenceLevel,
      'evidenceLevel',
      '项目或展示规则不得冒充古籍 A/B/C 级证据',
    );
  }
  if (kind != DlrRuleKind.classic && sourceIds.isNotEmpty) {
    throw ArgumentError.value(
      sourceIds,
      'sourceIds',
      '项目或展示规则不得挂接古籍来源',
    );
  }
  if (kind != DlrRuleKind.classic && executableApproved) {
    throw ArgumentError.value(
      executableApproved,
      'executableApproved',
      '古籍执行批准状态只适用于 classic 规则',
    );
  }
  if (kind == DlrRuleKind.classic && executableApproved) {
    if (evidenceLevel != DlrEvidenceLevel.a &&
        evidenceLevel != DlrEvidenceLevel.b) {
      throw ArgumentError.value(
        evidenceLevel,
        'evidenceLevel',
        '只有 A/B 级古籍规则可以获得执行批准',
      );
    }
    if (!DlrClassicExecutableRuleIds.all.contains(ruleId)) {
      throw ArgumentError.value(
        ruleId,
        'ruleId',
        '当前 C00 证据目录未批准该古籍规则执行',
      );
    }
  }
}

String _requiredString(Object? raw, String field) {
  if (raw is String) {
    return raw;
  }
  throw ArgumentError.value(raw, field, '字段必须是字符串');
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, String field) {
  if (raw is String) {
    for (final value in values) {
      if (value.name.toLowerCase() == raw.toLowerCase()) {
        return value;
      }
    }
  }
  throw ArgumentError.value(raw, field, '未知枚举值');
}

bool _stringListsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

Map<String, dynamic> _copyJsonMap(Map<String, dynamic> source) {
  final copy = <String, dynamic>{};
  for (final entry in source.entries) {
    copy[entry.key] = _copyJsonValue(entry.value, entry.key);
  }
  return Map<String, dynamic>.unmodifiable(copy);
}

Object? _copyJsonValue(Object? value, String path) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, path, 'JSON 数值必须为有限值');
    }
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(
      <Object?>[
        for (var index = 0; index < value.length; index++)
          _copyJsonValue(value[index], '$path[$index]'),
      ],
    );
  }
  if (value is Map) {
    final copy = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError.value(entry.key, path, 'JSON 对象键必须是字符串');
      }
      final key = entry.key as String;
      copy[key] = _copyJsonValue(entry.value, '$path.$key');
    }
    return Map<String, dynamic>.unmodifiable(copy);
  }
  throw ArgumentError.value(value, path, '值不是 JSON-safe 类型');
}
