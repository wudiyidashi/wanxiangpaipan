import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../daliuren_constants.dart';
import 'dlr_rule_contract.dart';
import 'tianpan_map_contract.dart';

part 'shen_jiang_config.freezed.dart';

enum ShenJiangDirection { shun, ni }

/// A general's two independent coordinates on a Da Liu Ren plate.
@Freezed(copyWith: false)
class ShenJiangPosition with _$ShenJiangPosition {
  const factory ShenJiangPosition._validated({
    required ShenJiang shenJiang,
    required String heavenBranch,
    required String earthPalace,
  }) = _ShenJiangPosition;

  factory ShenJiangPosition({
    required ShenJiang shenJiang,
    required String heavenBranch,
    required String earthPalace,
  }) {
    TianPanMapContract.validateBranch(heavenBranch, 'heavenBranch');
    TianPanMapContract.validateBranch(earthPalace, 'earthPalace');
    return ShenJiangPosition._validated(
      shenJiang: shenJiang,
      heavenBranch: heavenBranch,
      earthPalace: earthPalace,
    );
  }

  factory ShenJiangPosition.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(
      json,
      const <String>{'shenJiang', 'heavenBranch', 'earthPalace'},
      'ShenJiangPosition',
    );
    return ShenJiangPosition(
      shenJiang: _parseEnum(ShenJiang.values, json['shenJiang'], 'shenJiang'),
      heavenBranch: _requiredString(json['heavenBranch'], 'heavenBranch'),
      earthPalace: _requiredString(json['earthPalace'], 'earthPalace'),
    );
  }

  const ShenJiangPosition._();

  ShenJiangPosition copyWith({
    ShenJiang? shenJiang,
    String? heavenBranch,
    String? earthPalace,
  }) =>
      ShenJiangPosition(
        shenJiang: shenJiang ?? this.shenJiang,
        heavenBranch: heavenBranch ?? this.heavenBranch,
        earthPalace: earthPalace ?? this.earthPalace,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'shenJiang': _enumWireName(shenJiang),
        'heavenBranch': heavenBranch,
        'earthPalace': earthPalace,
      };

  String get name => shenJiang.name;

  String get description => shenJiang.description;

  String get displayText => '${shenJiang.name}乘$heavenBranch、临$earthPalace';
}

/// Complete and coordinate-explicit placement of the twelve generals.
@Freezed(copyWith: false)
class ShenJiangConfig with _$ShenJiangConfig {
  static const Set<String> shunEarthPalaces = <String>{
    '亥',
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
  };

  const factory ShenJiangConfig._validated({
    required String selectedGuiRenTianBranch,
    required String guiRenEarthPalace,
    required bool isYangGui,
    required ShenJiangDirection actualDirection,
    required List<ShenJiangPosition> positions,
    required Map<String, ShenJiang> tianBranchToGeneral,
    required Map<String, ShenJiang> earthPalaceToGeneral,
    required DlrRuleRef executionRuleRef,
    required List<String> classicAttributionRuleIds,
  }) = _ShenJiangConfig;

  factory ShenJiangConfig({
    required String selectedGuiRenTianBranch,
    required String guiRenEarthPalace,
    required bool isYangGui,
    required ShenJiangDirection actualDirection,
    required List<ShenJiangPosition> positions,
    required Map<String, ShenJiang> tianBranchToGeneral,
    required Map<String, ShenJiang> earthPalaceToGeneral,
    required DlrRuleRef executionRuleRef,
    required List<String> classicAttributionRuleIds,
  }) {
    final positionsSnapshot = List<ShenJiangPosition>.unmodifiable(positions);
    final tianMapSnapshot = UnmodifiableMapView<String, ShenJiang>(
      Map<String, ShenJiang>.from(tianBranchToGeneral),
    );
    final earthMapSnapshot = UnmodifiableMapView<String, ShenJiang>(
      Map<String, ShenJiang>.from(earthPalaceToGeneral),
    );
    final attributionSnapshot =
        List<String>.unmodifiable(classicAttributionRuleIds);

    _validateConfig(
      selectedGuiRenTianBranch: selectedGuiRenTianBranch,
      guiRenEarthPalace: guiRenEarthPalace,
      actualDirection: actualDirection,
      positions: positionsSnapshot,
      tianBranchToGeneral: tianMapSnapshot,
      earthPalaceToGeneral: earthMapSnapshot,
      executionRuleRef: executionRuleRef,
      classicAttributionRuleIds: attributionSnapshot,
    );

    return ShenJiangConfig._validated(
      selectedGuiRenTianBranch: selectedGuiRenTianBranch,
      guiRenEarthPalace: guiRenEarthPalace,
      isYangGui: isYangGui,
      actualDirection: actualDirection,
      positions: positionsSnapshot,
      tianBranchToGeneral: tianMapSnapshot,
      earthPalaceToGeneral: earthMapSnapshot,
      executionRuleRef: executionRuleRef,
      classicAttributionRuleIds: attributionSnapshot,
    );
  }

  factory ShenJiangConfig.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(
      json,
      const <String>{
        'selectedGuiRenTianBranch',
        'guiRenEarthPalace',
        'isYangGui',
        'actualDirection',
        'positions',
        'tianBranchToGeneral',
        'earthPalaceToGeneral',
        'executionRuleRef',
        'classicAttributionRuleIds',
      },
      'ShenJiangConfig',
    );

    final rawPositions = json['positions'];
    if (rawPositions is! List) {
      throw ArgumentError.value(rawPositions, 'positions', '必须是数组');
    }
    final positions = <ShenJiangPosition>[];
    for (final rawPosition in rawPositions) {
      if (rawPosition is! Map) {
        throw ArgumentError.value(rawPosition, 'positions', '位置必须是对象');
      }
      positions.add(
        ShenJiangPosition.fromJson(_stringKeyedMap(rawPosition, 'positions')),
      );
    }

    final rawRuleRef = json['executionRuleRef'];
    if (rawRuleRef is! Map) {
      throw ArgumentError.value(
        rawRuleRef,
        'executionRuleRef',
        '执行规则引用必须是对象',
      );
    }

    return ShenJiangConfig(
      selectedGuiRenTianBranch: _requiredString(
        json['selectedGuiRenTianBranch'],
        'selectedGuiRenTianBranch',
      ),
      guiRenEarthPalace: _requiredString(
        json['guiRenEarthPalace'],
        'guiRenEarthPalace',
      ),
      isYangGui: _requiredBool(json['isYangGui'], 'isYangGui'),
      actualDirection: _parseEnum(
        ShenJiangDirection.values,
        json['actualDirection'],
        'actualDirection',
      ),
      positions: positions,
      tianBranchToGeneral: _parseGeneralMap(
        json['tianBranchToGeneral'],
        'tianBranchToGeneral',
      ),
      earthPalaceToGeneral: _parseGeneralMap(
        json['earthPalaceToGeneral'],
        'earthPalaceToGeneral',
      ),
      executionRuleRef: DlrRuleRef.fromJson(
        _stringKeyedMap(rawRuleRef, 'executionRuleRef'),
      ),
      classicAttributionRuleIds: _parseStringList(
        json['classicAttributionRuleIds'],
        'classicAttributionRuleIds',
      ),
    );
  }

  const ShenJiangConfig._();

  ShenJiangConfig copyWith({
    String? selectedGuiRenTianBranch,
    String? guiRenEarthPalace,
    bool? isYangGui,
    ShenJiangDirection? actualDirection,
    List<ShenJiangPosition>? positions,
    Map<String, ShenJiang>? tianBranchToGeneral,
    Map<String, ShenJiang>? earthPalaceToGeneral,
    DlrRuleRef? executionRuleRef,
    List<String>? classicAttributionRuleIds,
  }) =>
      ShenJiangConfig(
        selectedGuiRenTianBranch:
            selectedGuiRenTianBranch ?? this.selectedGuiRenTianBranch,
        guiRenEarthPalace: guiRenEarthPalace ?? this.guiRenEarthPalace,
        isYangGui: isYangGui ?? this.isYangGui,
        actualDirection: actualDirection ?? this.actualDirection,
        positions: positions ?? this.positions,
        tianBranchToGeneral: tianBranchToGeneral ?? this.tianBranchToGeneral,
        earthPalaceToGeneral: earthPalaceToGeneral ?? this.earthPalaceToGeneral,
        executionRuleRef: executionRuleRef ?? this.executionRuleRef,
        classicAttributionRuleIds:
            classicAttributionRuleIds ?? this.classicAttributionRuleIds,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'selectedGuiRenTianBranch': selectedGuiRenTianBranch,
        'guiRenEarthPalace': guiRenEarthPalace,
        'isYangGui': isYangGui,
        'actualDirection': actualDirection.name,
        'positions': positions.map((position) => position.toJson()).toList(
              growable: false,
            ),
        'tianBranchToGeneral': tianBranchToGeneral.map(
          (branch, general) =>
              MapEntry<String, String>(branch, _enumWireName(general)),
        ),
        'earthPalaceToGeneral': earthPalaceToGeneral.map(
          (branch, general) =>
              MapEntry<String, String>(branch, _enumWireName(general)),
        ),
        'executionRuleRef': executionRuleRef.toJson(),
        'classicAttributionRuleIds':
            classicAttributionRuleIds.toList(growable: false),
      };

  ShenJiang? generalForHeavenBranch(String heavenBranch) =>
      tianBranchToGeneral[heavenBranch];

  ShenJiang? generalForEarthPalace(String earthPalace) =>
      earthPalaceToGeneral[earthPalace];

  ShenJiangPosition? positionOf(ShenJiang general) {
    for (final position in positions) {
      if (position.shenJiang == general) return position;
    }
    return null;
  }

  void validateAgainstTianPan(Map<String, String> earthToHeaven) {
    final validatedMap = TianPanMapContract.validate(
      earthToHeaven,
      parameterName: 'earthToHeaven',
    );
    for (final position in positions) {
      if (validatedMap[position.earthPalace] != position.heavenBranch) {
        throw ArgumentError.value(
          earthToHeaven,
          'earthToHeaven',
          '神将${position.shenJiang.name}的天盘支与地盘落宫不匹配',
        );
      }
    }
  }

  /// Validates the nested execution identity against the persisted plate
  /// version without reinterpreting unknown future versions as current.
  void validateForPanRuleSetVersion(String panRuleSetVersion) {
    final normalizedVersion = panRuleSetVersion.isEmpty
        ? DlrRuleSetVersions.legacyUnknown
        : panRuleSetVersion;
    final isKnownLegacyVersion =
        normalizedVersion == DlrRuleSetVersions.legacyUnknown ||
            normalizedVersion == DlrRuleSetVersions.panV1 ||
            normalizedVersion == DlrRuleSetVersions.panV2 ||
            normalizedVersion == DlrRuleSetVersions.panV3;

    if (normalizedVersion == DlrRuleSetVersions.panCurrent) {
      if (executionRuleRef.ruleId !=
              DlrProjectPanRuleIds.shenJiangLandingPalaceLayout ||
          executionRuleRef.ruleSetVersion != normalizedVersion) {
        throw ArgumentError.value(
          executionRuleRef,
          'executionRuleRef',
          '当前盘版本必须使用同版本的当前排将规则',
        );
      }
      return;
    }

    if (isKnownLegacyVersion) {
      if (executionRuleRef.ruleId !=
              DlrProjectPanRuleIds.shenJiangLegacyLayoutImport ||
          executionRuleRef.ruleSetVersion != normalizedVersion) {
        throw ArgumentError.value(
          executionRuleRef,
          'executionRuleRef',
          '历史盘版本必须使用同版本的旧布局导入规则',
        );
      }
      return;
    }

    // A syntactically normal future pan version remains readable, but its
    // nested rule identity must still name the same version. Deliberately
    // malformed/case-varied version strings stay readable as mismatch data.
    if (panRuleSetVersion == panRuleSetVersion.trim() &&
        panRuleSetVersion.startsWith('daliuren-pan/') &&
        executionRuleRef.ruleSetVersion != panRuleSetVersion) {
      throw ArgumentError.value(
        executionRuleRef,
        'executionRuleRef',
        '排将执行规则版本必须与顶层盘版本一致',
      );
    }
  }

  ShenJiangPosition? get guiRen => positionOf(ShenJiang.guiRen);

  ShenJiangPosition? get qingLong => positionOf(ShenJiang.qingLong);

  ShenJiangPosition? get baiHu => positionOf(ShenJiang.baiHu);

  ShenJiangPosition? get xuanWu => positionOf(ShenJiang.xuanWu);

  String get guiRenTypeDescription => isYangGui ? '阳贵（昼贵）' : '阴贵（夜贵）';

  String get directionDescription =>
      actualDirection == ShenJiangDirection.shun ? '顺布' : '逆布';
}

void _validateConfig({
  required String selectedGuiRenTianBranch,
  required String guiRenEarthPalace,
  required ShenJiangDirection actualDirection,
  required List<ShenJiangPosition> positions,
  required Map<String, ShenJiang> tianBranchToGeneral,
  required Map<String, ShenJiang> earthPalaceToGeneral,
  required DlrRuleRef executionRuleRef,
  required List<String> classicAttributionRuleIds,
}) {
  TianPanMapContract.validateBranch(
    selectedGuiRenTianBranch,
    'selectedGuiRenTianBranch',
  );
  TianPanMapContract.validateBranch(guiRenEarthPalace, 'guiRenEarthPalace');
  _validateGeneralMap(tianBranchToGeneral, 'tianBranchToGeneral');
  _validateGeneralMap(earthPalaceToGeneral, 'earthPalaceToGeneral');

  if (positions.length != ShenJiang.values.length) {
    throw ArgumentError.value(positions, 'positions', '必须恰有十二个神将位置');
  }
  final byGeneral = <ShenJiang, ShenJiangPosition>{};
  final heavenBranches = <String>{};
  final earthPalaces = <String>{};
  for (final position in positions) {
    if (byGeneral.containsKey(position.shenJiang)) {
      throw ArgumentError.value(positions, 'positions', '每个神将必须恰好出现一次');
    }
    byGeneral[position.shenJiang] = position;
    if (!heavenBranches.add(position.heavenBranch)) {
      throw ArgumentError.value(positions, 'positions', '天盘支不得重复');
    }
    if (!earthPalaces.add(position.earthPalace)) {
      throw ArgumentError.value(positions, 'positions', '地盘落宫不得重复');
    }
    if (tianBranchToGeneral[position.heavenBranch] != position.shenJiang ||
        earthPalaceToGeneral[position.earthPalace] != position.shenJiang) {
      throw ArgumentError.value(positions, 'positions', '位置事实必须与两张神将映射一致');
    }
  }
  if (byGeneral.length != ShenJiang.values.length) {
    throw ArgumentError.value(positions, 'positions', '位置必须覆盖十二神将');
  }

  if (tianBranchToGeneral[selectedGuiRenTianBranch] != ShenJiang.guiRen ||
      earthPalaceToGeneral[guiRenEarthPalace] != ShenJiang.guiRen) {
    throw ArgumentError(
      '所选贵人天盘支和地盘落宫都必须锚定贵人',
    );
  }

  final step = actualDirection == ShenJiangDirection.shun ? 1 : -1;
  _validateGeneralSequence(
    byGeneral,
    (position) => position.heavenBranch,
    selectedGuiRenTianBranch,
    step,
    'tianBranchToGeneral',
  );
  _validateGeneralSequence(
    byGeneral,
    (position) => position.earthPalace,
    guiRenEarthPalace,
    step,
    'earthPalaceToGeneral',
  );

  if (executionRuleRef.kind != DlrRuleKind.project ||
      (executionRuleRef.ruleId !=
              DlrProjectPanRuleIds.shenJiangLandingPalaceLayout &&
          executionRuleRef.ruleId !=
              DlrProjectPanRuleIds.shenJiangLegacyLayoutImport)) {
    throw ArgumentError.value(
      executionRuleRef,
      'executionRuleRef',
      '神将配置必须引用稳定的项目排将规则',
    );
  }
  if (executionRuleRef.ruleSetVersion != DlrRuleSetVersions.legacyUnknown &&
      !executionRuleRef.ruleSetVersion.startsWith('daliuren-pan/')) {
    throw ArgumentError.value(
      executionRuleRef,
      'executionRuleRef',
      '神将执行规则必须使用 daliuren-pan 规则集版本',
    );
  }

  final isLegacyImport = executionRuleRef.ruleId ==
      DlrProjectPanRuleIds.shenJiangLegacyLayoutImport;
  if (isLegacyImport && classicAttributionRuleIds.isNotEmpty) {
    throw ArgumentError.value(
      classicAttributionRuleIds,
      'classicAttributionRuleIds',
      '历史布局导入不得冒充当前古籍引用',
    );
  }
  if (!isLegacyImport &&
      !_sameStrings(
        classicAttributionRuleIds,
        DlrShenJiangClassicRuleIds.currentAttributions,
      )) {
    throw ArgumentError.value(
      classicAttributionRuleIds,
      'classicAttributionRuleIds',
      '当前排将布局必须引用已核定的四条神将古籍事实',
    );
  }

  if (!isLegacyImport) {
    final expectedDirection =
        ShenJiangConfig.shunEarthPalaces.contains(guiRenEarthPalace)
            ? ShenJiangDirection.shun
            : ShenJiangDirection.ni;
    if (actualDirection != expectedDirection) {
      throw ArgumentError.value(
        actualDirection,
        'actualDirection',
        '当前排将方向必须由贵人所临地盘六区决定',
      );
    }
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _validateGeneralMap(
  Map<String, ShenJiang> map,
  String parameterName,
) {
  final expectedBranches = DaLiuRenConstants.diZhi.toSet();
  if (map.length != expectedBranches.length ||
      map.keys.toSet().length != expectedBranches.length ||
      !map.keys.toSet().containsAll(expectedBranches)) {
    throw ArgumentError.value(map, parameterName, '键必须恰为十二地支全集');
  }
  final generals = map.values.toSet();
  if (generals.length != ShenJiang.values.length ||
      !generals.containsAll(ShenJiang.values)) {
    throw ArgumentError.value(map, parameterName, '十二神将必须各出现一次');
  }
}

void _validateGeneralSequence(
  Map<ShenJiang, ShenJiangPosition> byGeneral,
  String Function(ShenJiangPosition position) coordinateOf,
  String guiRenCoordinate,
  int step,
  String parameterName,
) {
  final branches = DaLiuRenConstants.diZhi;
  final guiRenIndex = branches.indexOf(guiRenCoordinate);
  for (var index = 0; index < ShenJiang.values.length; index++) {
    final expectedIndex = (guiRenIndex + step * index) % branches.length;
    final actual = coordinateOf(byGeneral[ShenJiang.values[index]]!);
    if (actual != branches[expectedIndex]) {
      throw ArgumentError.value(
        actual,
        parameterName,
        '十二将相邻次序与实际顺逆不一致',
      );
    }
  }
}

Map<String, ShenJiang> _parseGeneralMap(Object? raw, String field) {
  if (raw is! Map) {
    throw ArgumentError.value(raw, field, '必须是对象');
  }
  final result = <String, ShenJiang>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw ArgumentError.value(entry.key, field, '键必须是字符串');
    }
    result[entry.key as String] =
        _parseEnum(ShenJiang.values, entry.value, field);
  }
  return result;
}

List<String> _parseStringList(Object? raw, String field) {
  if (raw is! List) {
    throw ArgumentError.value(raw, field, '必须是字符串数组');
  }
  final result = <String>[];
  for (final value in raw) {
    result.add(_requiredString(value, field));
  }
  return result;
}

Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> raw, String field) {
  final result = <String, dynamic>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw ArgumentError.value(entry.key, field, '对象键必须是字符串');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _requireExactKeys(
  Map<String, dynamic> json,
  Set<String> expected,
  String typeName,
) {
  final actual = json.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw ArgumentError.value(
      actual,
      typeName,
      '字段必须与当前 wire 契约完全一致',
    );
  }
}

String _requiredString(Object? raw, String field) {
  if (raw is! String) {
    throw ArgumentError.value(raw, field, '必须是字符串');
  }
  return raw;
}

bool _requiredBool(Object? raw, String field) {
  if (raw is! bool) {
    throw ArgumentError.value(raw, field, '必须是布尔值');
  }
  return raw;
}

T _parseEnum<T extends Enum>(List<T> values, Object? raw, String field) {
  if (raw is String) {
    for (final value in values) {
      if (_enumWireName(value) == raw) return value;
    }
  }
  throw ArgumentError.value(raw, field, '不是已知枚举值');
}

String _enumWireName(Enum value) => value.toString().split('.').last;
