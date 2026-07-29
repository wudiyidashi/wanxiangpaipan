import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';
import '../daliuren_constants.dart';
import 'si_ke.dart';
import 'san_chuan.dart';
import 'tianpan.dart';
import 'tianpan_map_contract.dart';
import 'shen_jiang_config.dart';
import 'shen_sha.dart';
import 'pan_params.dart';
import 'dlr_cast_time.dart';
import 'dlr_rule_contract.dart';

part 'daliuren_result.freezed.dart';
part 'daliuren_result.g.dart';

/// 大六壬占卜结果
///
/// 大六壬是中国古代三式之一，以天干地支、十二神将为基础，
/// 通过四课三传进行占断。
///
/// 核心数据结构：
/// - [tianPan]: 天盘（月将加临时支）
/// - [siKe]: 四课（日干支推演的四课）
/// - [sanChuan]: 三传（初传、中传、末传）
/// - [shenJiangConfig]: 十二神将配置
/// - [shenShaList]: 神煞列表
@Freezed(fromJson: false, toJson: true, copyWith: false)
class DaLiuRenResult with _$DaLiuRenResult implements DivinationResult {
  @JsonSerializable(explicitToJson: true)
  const factory DaLiuRenResult._validated({
    /// 唯一标识
    required String id,

    /// 跨系统既有记录时间；新盘历法事实以 [civilTime] 为准。
    ///
    /// 此字段保持 legacy wire 角色，不在本模型中静默迁移为 UTC。
    required DateTime castTime,

    /// 起卦方式
    required CastMethod castMethod,

    /// 农历信息
    required LunarInfo lunarInfo,

    /// 天盘
    required TianPan tianPan,

    /// 四课
    required SiKe siKe,

    /// 三传
    required SanChuan sanChuan,

    /// 十二神将配置
    required ShenJiangConfig shenJiangConfig,

    /// 神煞列表
    required ShenShaList shenShaList,

    /// 排盘参数
    required DaLiuRenPanParams panParams,

    /// 生成本盘的排盘规则集版本；旧 JSON 明确保持未知。
    @Default(DlrRuleSetVersions.legacyUnknown) String panRuleSetVersion,

    /// 本盘引用的古籍证据目录版本；旧 JSON 明确保持未知。
    @Default(DlrRuleSetVersions.legacyUnknown) String evidenceCatalogVersion,

    /// 原始起课输入的规范化快照；旧盘或不可恢复记录为 null。
    DlrCastInputSnapshot? castInputSnapshot,

    /// 新盘的权威绝对时刻与来源民用 offset；旧 JSON 保持 null。
    DlrCivilTime? civilTime,

    /// 持久化月将解析事实与来源；旧 JSON 保持 null，不现场补算。
    DlrMonthGeneralResolution? monthGeneralResolution,

    /// 显式重排来源盘 ID；C15 再实现关联保存流程。
    String? recastFromId,

    /// 占问ID（加密存储引用）
    @Default('') String questionId,

    /// 详情ID（加密存储引用）
    @Default('') String detailId,

    /// 解读ID（加密存储引用）
    @Default('') String interpretationId,
  }) = _DaLiuRenResult;

  factory DaLiuRenResult({
    required String id,
    required DateTime castTime,
    required CastMethod castMethod,
    required LunarInfo lunarInfo,
    required TianPan tianPan,
    required SiKe siKe,
    required SanChuan sanChuan,
    required ShenJiangConfig shenJiangConfig,
    required ShenShaList shenShaList,
    required DaLiuRenPanParams panParams,
    String? panRuleSetVersion,
    String? evidenceCatalogVersion,
    DlrCastInputSnapshot? castInputSnapshot,
    DlrCivilTime? civilTime,
    DlrMonthGeneralResolution? monthGeneralResolution,
    String? recastFromId,
    String questionId = '',
    String detailId = '',
    String interpretationId = '',
  }) {
    final resolvedPanRuleSetVersion =
        panRuleSetVersion ?? shenJiangConfig.executionRuleRef.ruleSetVersion;
    final resolvedEvidenceCatalogVersion = evidenceCatalogVersion ??
        (resolvedPanRuleSetVersion == DlrRuleSetVersions.panCurrent
            ? DlrRuleSetVersions.evidenceCatalog
            : DlrRuleSetVersions.legacyUnknown);
    final result = DaLiuRenResult._validated(
      id: id,
      castTime: castTime,
      castMethod: castMethod,
      lunarInfo: lunarInfo,
      tianPan: tianPan,
      siKe: siKe,
      sanChuan: sanChuan,
      shenJiangConfig: shenJiangConfig,
      shenShaList: shenShaList,
      panParams: panParams,
      panRuleSetVersion: resolvedPanRuleSetVersion,
      evidenceCatalogVersion: resolvedEvidenceCatalogVersion,
      castInputSnapshot: castInputSnapshot,
      civilTime: civilTime,
      monthGeneralResolution: monthGeneralResolution,
      recastFromId: recastFromId,
      questionId: questionId,
      detailId: detailId,
      interpretationId: interpretationId,
    );
    result.validateShenJiangContract();
    return result;
  }

  factory DaLiuRenResult.fromJson(Map<String, dynamic> json) {
    final sourcePanRuleSetVersion = _sourcePanRuleSetVersion(json);
    final rawTianPan = json['tianPan'];
    if (rawTianPan is! Map) {
      throw ArgumentError.value(rawTianPan, 'tianPan', '天盘必须是对象');
    }
    final tianPan = TianPan.fromJson(
      _stringKeyedJsonMap(rawTianPan, 'tianPan'),
    );

    final rawConfig = json['shenJiangConfig'];
    if (rawConfig is! Map) {
      throw ArgumentError.value(
        rawConfig,
        'shenJiangConfig',
        '十二天将配置必须是对象',
      );
    }
    final configJson = _stringKeyedJsonMap(rawConfig, 'shenJiangConfig');
    final config = _decodeShenJiangConfig(
      configJson,
      sourcePanRuleSetVersion: sourcePanRuleSetVersion,
      persistedTianPanMap: tianPan.tianPanMap,
    );
    config.validateAgainstTianPan(tianPan.tianPanMap);
    config.validateForPanRuleSetVersion(sourcePanRuleSetVersion);

    final normalizedJson = Map<String, dynamic>.from(json)
      ..['shenJiangConfig'] = config.toJson();
    final result = _$$DaLiuRenResultImplFromJson(normalizedJson);
    result.validateShenJiangContract();
    return result;
  }

  const DaLiuRenResult._();

  DaLiuRenResult copyWith({
    String? id,
    DateTime? castTime,
    CastMethod? castMethod,
    LunarInfo? lunarInfo,
    TianPan? tianPan,
    SiKe? siKe,
    SanChuan? sanChuan,
    ShenJiangConfig? shenJiangConfig,
    ShenShaList? shenShaList,
    DaLiuRenPanParams? panParams,
    String? panRuleSetVersion,
    String? evidenceCatalogVersion,
    Object? castInputSnapshot = _copyWithUnset,
    Object? civilTime = _copyWithUnset,
    Object? monthGeneralResolution = _copyWithUnset,
    Object? recastFromId = _copyWithUnset,
    String? questionId,
    String? detailId,
    String? interpretationId,
  }) =>
      DaLiuRenResult(
        id: id ?? this.id,
        castTime: castTime ?? this.castTime,
        castMethod: castMethod ?? this.castMethod,
        lunarInfo: lunarInfo ?? this.lunarInfo,
        tianPan: tianPan ?? this.tianPan,
        siKe: siKe ?? this.siKe,
        sanChuan: sanChuan ?? this.sanChuan,
        shenJiangConfig: shenJiangConfig ?? this.shenJiangConfig,
        shenShaList: shenShaList ?? this.shenShaList,
        panParams: panParams ?? this.panParams,
        panRuleSetVersion: panRuleSetVersion ?? this.panRuleSetVersion,
        evidenceCatalogVersion:
            evidenceCatalogVersion ?? this.evidenceCatalogVersion,
        castInputSnapshot: _copyNullableValue<DlrCastInputSnapshot>(
          castInputSnapshot,
          this.castInputSnapshot,
          'castInputSnapshot',
        ),
        civilTime: _copyNullableValue<DlrCivilTime>(
          civilTime,
          this.civilTime,
          'civilTime',
        ),
        monthGeneralResolution: _copyNullableValue<DlrMonthGeneralResolution>(
          monthGeneralResolution,
          this.monthGeneralResolution,
          'monthGeneralResolution',
        ),
        recastFromId: _copyNullableValue<String>(
          recastFromId,
          this.recastFromId,
          'recastFromId',
        ),
        questionId: questionId ?? this.questionId,
        detailId: detailId ?? this.detailId,
        interpretationId: interpretationId ?? this.interpretationId,
      );

  void validateShenJiangContract() {
    shenJiangConfig.validateAgainstTianPan(tianPan.tianPanMap);
    shenJiangConfig.validateForPanRuleSetVersion(panRuleSetVersion);

    if (panRuleSetVersion == DlrRuleSetVersions.panCurrent) {
      if (evidenceCatalogVersion != DlrRuleSetVersions.evidenceCatalog) {
        throw ArgumentError.value(
          evidenceCatalogVersion,
          'evidenceCatalogVersion',
          '当前盘必须绑定当前证据目录版本',
        );
      }
      if (panParams.guiRenVerse == DaLiuRenGuiRenVerse.jiaDayAlt) {
        throw ArgumentError.value(
          panParams.guiRenVerse,
          'panParams.guiRenVerse',
          'jiaDayAlt 只允许历史盘解码，不得用于当前盘',
        );
      }
    }

    final monthGeneralRuleVersion =
        monthGeneralResolution?.executionRuleRef.ruleSetVersion;
    if (_requiresExactNestedPanVersion(panRuleSetVersion) &&
        monthGeneralRuleVersion != null &&
        monthGeneralRuleVersion != panRuleSetVersion) {
      throw ArgumentError.value(
        monthGeneralResolution!.executionRuleRef,
        'monthGeneralResolution.executionRuleRef',
        '月将执行规则版本必须与顶层盘版本一致',
      );
    }

    for (final lesson in siKe.allKe) {
      final expected = shenJiangConfig.generalForHeavenBranch(lesson.shangShen);
      if (expected != lesson.chengShen) {
        throw ArgumentError.value(
          lesson.chengShen,
          'siKe.ke${lesson.index}.chengShen',
          '四课乘将必须与神将天盘支映射一致',
        );
      }
    }
    for (final transmission in sanChuan.allChuan) {
      final expected =
          shenJiangConfig.generalForHeavenBranch(transmission.diZhi);
      if (expected != transmission.chengShen) {
        throw ArgumentError.value(
          transmission.chengShen,
          'sanChuan.${transmission.position.name}.chengShen',
          '三传乘将必须与神将天盘支映射一致',
        );
      }
    }
  }

  /// 系统类型（实现 DivinationResult 接口）
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  /// 获取结果摘要（实现 DivinationResult 接口）
  @override
  String getSummary() {
    final keTypeName = sanChuan.keTypeName;
    final chuChuan = sanChuan.chuChuanDiZhi;
    final zhongChuan = sanChuan.zhongChuanDiZhi;
    final moChuan = sanChuan.moChuanDiZhi;
    return '$keTypeName课 · 初传$chuChuan 中传$zhongChuan 末传$moChuan';
  }

  /// 获取日干
  String get riGan => siKe.riGan;

  /// 获取日支
  String get riZhi => siKe.riZhi;

  /// 获取月将
  String get yueJiang => tianPan.yueJiang;

  /// 获取时支
  String get shiZhi => tianPan.shiZhi;

  /// 获取课体类型
  String get keTypeName => sanChuan.keTypeName;

  /// 是否为伏吟课
  bool get isFuYin => sanChuan.isFuYin;

  /// 是否为反吟课
  bool get isFanYin => sanChuan.isFanYin;

  /// 初传地支
  String get chuChuan => sanChuan.chuChuanDiZhi;

  /// 中传地支
  String get zhongChuan => sanChuan.zhongChuanDiZhi;

  /// 末传地支
  String get moChuan => sanChuan.moChuanDiZhi;

  /// 吉神数量
  int get jiShenCount => shenShaList.jiCount;

  /// 凶神数量
  int get xiongShenCount => shenShaList.xiongCount;
}

const Object _copyWithUnset = Object();

T? _copyNullableValue<T>(Object? value, T? currentValue, String field) {
  if (identical(value, _copyWithUnset)) return currentValue;
  if (value == null) return null;
  if (value is T) return value as T;
  throw ArgumentError.value(value, field, '类型不正确');
}

bool _requiresExactNestedPanVersion(String panRuleSetVersion) =>
    panRuleSetVersion == panRuleSetVersion.trim() &&
    panRuleSetVersion.startsWith('daliuren-pan/');

const Set<String> _legacyShenJiangConfigKeys = <String>{
  'guiRenPosition',
  'isYangGui',
  'isYangRi',
  'positions',
  'diZhiToShenJiang',
};

const Set<String> _legacyOnlyShenJiangConfigKeys = <String>{
  'guiRenPosition',
  'isYangRi',
  'diZhiToShenJiang',
};

const Set<String> _currentOnlyShenJiangConfigKeys = <String>{
  'selectedGuiRenTianBranch',
  'guiRenEarthPalace',
  'actualDirection',
  'tianBranchToGeneral',
  'earthPalaceToGeneral',
  'executionRuleRef',
  'classicAttributionRuleIds',
};

String _sourcePanRuleSetVersion(Map<String, dynamic> json) {
  final rawVersion = json['panRuleSetVersion'];
  if (rawVersion == null) return DlrRuleSetVersions.legacyUnknown;
  if (rawVersion is! String) {
    throw ArgumentError.value(
      rawVersion,
      'panRuleSetVersion',
      '排盘规则集版本必须是字符串',
    );
  }
  return rawVersion;
}

ShenJiangConfig _decodeShenJiangConfig(
  Map<String, dynamic> json, {
  required String sourcePanRuleSetVersion,
  required Map<String, String> persistedTianPanMap,
}) {
  final hasLegacyFields =
      json.keys.any(_legacyOnlyShenJiangConfigKeys.contains);
  final hasCurrentFields =
      json.keys.any(_currentOnlyShenJiangConfigKeys.contains);
  if (hasLegacyFields && hasCurrentFields) {
    throw ArgumentError.value(
      json,
      'shenJiangConfig',
      '不得混用旧坐标字段与当前坐标字段',
    );
  }
  if (!hasLegacyFields) return ShenJiangConfig.fromJson(json);

  final canMigrateLegacyShape = sourcePanRuleSetVersion.isEmpty ||
      sourcePanRuleSetVersion == DlrRuleSetVersions.legacyUnknown ||
      sourcePanRuleSetVersion == DlrRuleSetVersions.panV1 ||
      sourcePanRuleSetVersion == DlrRuleSetVersions.panV2 ||
      sourcePanRuleSetVersion == DlrRuleSetVersions.panV3;
  if (!canMigrateLegacyShape) {
    throw ArgumentError.value(
      sourcePanRuleSetVersion,
      'panRuleSetVersion',
      '当前或未来排盘版本不得使用旧神将坐标结构',
    );
  }

  return _migrateLegacyShenJiangConfig(
    json,
    sourcePanRuleSetVersion: sourcePanRuleSetVersion,
    persistedTianPanMap: persistedTianPanMap,
  );
}

ShenJiangConfig _migrateLegacyShenJiangConfig(
  Map<String, dynamic> json, {
  required String sourcePanRuleSetVersion,
  required Map<String, String> persistedTianPanMap,
}) {
  final actualKeys = json.keys.toSet();
  if (actualKeys.length != _legacyShenJiangConfigKeys.length ||
      !actualKeys.containsAll(_legacyShenJiangConfigKeys)) {
    throw ArgumentError.value(
      actualKeys,
      'shenJiangConfig',
      '旧神将配置必须包含完整的五个历史字段',
    );
  }

  final selectedGuiRenTianBranch =
      _legacyRequiredString(json['guiRenPosition'], 'guiRenPosition');
  TianPanMapContract.validateBranch(
    selectedGuiRenTianBranch,
    'guiRenPosition',
  );
  final isYangGui = _legacyRequiredBool(json['isYangGui'], 'isYangGui');
  _legacyRequiredBool(json['isYangRi'], 'isYangRi');

  final rawPositions = json['positions'];
  if (rawPositions is! List || rawPositions.length != ShenJiang.values.length) {
    throw ArgumentError.value(
      rawPositions,
      'positions',
      '旧神将位置必须恰有十二项',
    );
  }

  final recoveredTianPan = <String, String>{};
  final positionByGeneral = <ShenJiang, _LegacyShenJiangPosition>{};
  for (final rawPosition in rawPositions) {
    if (rawPosition is! Map) {
      throw ArgumentError.value(rawPosition, 'positions', '旧位置必须是对象');
    }
    final position = _LegacyShenJiangPosition.fromJson(
      _stringKeyedJsonMap(rawPosition, 'positions'),
    );
    if (positionByGeneral.containsKey(position.shenJiang)) {
      throw ArgumentError.value(
        rawPositions,
        'positions',
        '旧位置中每个神将必须恰好出现一次',
      );
    }
    if (recoveredTianPan.containsKey(position.diZhi)) {
      throw ArgumentError.value(
        rawPositions,
        'positions',
        '旧位置中地支不得重复',
      );
    }
    positionByGeneral[position.shenJiang] = position;
    recoveredTianPan[position.diZhi] = position.tianPanZhi;
  }
  if (positionByGeneral.length != ShenJiang.values.length) {
    throw ArgumentError.value(rawPositions, 'positions', '旧位置未覆盖十二神将');
  }

  final validatedRecoveredTianPan = TianPanMapContract.validate(
    recoveredTianPan,
    parameterName: 'legacyPositions',
  );
  final validatedPersistedTianPan = TianPanMapContract.validate(
    persistedTianPanMap,
    parameterName: 'persistedTianPanMap',
  );
  for (final branch in DaLiuRenConstants.diZhi) {
    if (validatedRecoveredTianPan[branch] !=
        validatedPersistedTianPan[branch]) {
      throw ArgumentError.value(
        recoveredTianPan,
        'legacyPositions',
        '旧神将位置恢复的天盘与结果天盘矛盾',
      );
    }
  }

  final tianBranchToGeneral = _parseLegacyGeneralMap(
    json['diZhiToShenJiang'],
    'diZhiToShenJiang',
  );
  for (final position in positionByGeneral.values) {
    if (tianBranchToGeneral[position.diZhi] != position.shenJiang) {
      throw ArgumentError.value(
        json['diZhiToShenJiang'],
        'diZhiToShenJiang',
        '旧神将映射与旧位置记录不一致',
      );
    }
  }
  if (tianBranchToGeneral[selectedGuiRenTianBranch] != ShenJiang.guiRen) {
    throw ArgumentError.value(
      selectedGuiRenTianBranch,
      'guiRenPosition',
      '旧贵人位置必须对应贵人',
    );
  }

  final heavenToEarth = <String, String>{};
  for (final entry in validatedPersistedTianPan.entries) {
    heavenToEarth[entry.value] = entry.key;
  }
  final guiRenEarthPalace = heavenToEarth[selectedGuiRenTianBranch]!;
  final actualDirection = _legacyDirection(tianBranchToGeneral);

  final positions = <ShenJiangPosition>[];
  final earthPalaceToGeneral = <String, ShenJiang>{};
  for (final general in ShenJiang.values) {
    final heavenBranch = tianBranchToGeneral.entries
        .singleWhere((entry) => entry.value == general)
        .key;
    final earthPalace = heavenToEarth[heavenBranch]!;
    positions.add(
      ShenJiangPosition(
        shenJiang: general,
        heavenBranch: heavenBranch,
        earthPalace: earthPalace,
      ),
    );
    earthPalaceToGeneral[earthPalace] = general;
  }

  final importedRuleSetVersion = sourcePanRuleSetVersion.isEmpty
      ? DlrRuleSetVersions.legacyUnknown
      : sourcePanRuleSetVersion;
  return ShenJiangConfig(
    selectedGuiRenTianBranch: selectedGuiRenTianBranch,
    guiRenEarthPalace: guiRenEarthPalace,
    isYangGui: isYangGui,
    actualDirection: actualDirection,
    positions: positions,
    tianBranchToGeneral: tianBranchToGeneral,
    earthPalaceToGeneral: earthPalaceToGeneral,
    executionRuleRef: DlrRuleRef.projectPan(
      DlrProjectPanRuleIds.shenJiangLegacyLayoutImport,
      ruleSetVersion: importedRuleSetVersion,
    ),
    classicAttributionRuleIds: const <String>[],
  );
}

ShenJiangDirection _legacyDirection(
  Map<String, ShenJiang> tianBranchToGeneral,
) {
  final branches = DaLiuRenConstants.diZhi;
  final guiRenBranch = tianBranchToGeneral.entries
      .singleWhere((entry) => entry.value == ShenJiang.guiRen)
      .key;
  final tengSheBranch = tianBranchToGeneral.entries
      .singleWhere((entry) => entry.value == ShenJiang.tengShe)
      .key;
  final guiRenIndex = branches.indexOf(guiRenBranch);
  if (tengSheBranch == branches[(guiRenIndex + 1) % branches.length]) {
    return ShenJiangDirection.shun;
  }
  if (tengSheBranch == branches[(guiRenIndex - 1) % branches.length]) {
    return ShenJiangDirection.ni;
  }
  throw ArgumentError.value(
    tianBranchToGeneral,
    'diZhiToShenJiang',
    '旧布局中贵人与腾蛇不相邻，无法恢复顺逆',
  );
}

Map<String, ShenJiang> _parseLegacyGeneralMap(Object? raw, String field) {
  if (raw is! Map || raw.length != ShenJiang.values.length) {
    throw ArgumentError.value(raw, field, '旧神将映射必须恰有十二项');
  }
  final result = <String, ShenJiang>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw ArgumentError.value(entry.key, field, '映射键必须是字符串');
    }
    TianPanMapContract.validateBranch(entry.key as String, field);
    result[entry.key as String] =
        _legacyParseEnum(ShenJiang.values, entry.value, field);
  }
  final expectedBranches = DaLiuRenConstants.diZhi.toSet();
  final generals = result.values.toSet();
  if (!result.keys.toSet().containsAll(expectedBranches) ||
      generals.length != ShenJiang.values.length ||
      !generals.containsAll(ShenJiang.values)) {
    throw ArgumentError.value(raw, field, '旧映射必须是十二地支到十二神将的双射');
  }
  return result;
}

class _LegacyShenJiangPosition {
  const _LegacyShenJiangPosition({
    required this.shenJiang,
    required this.diZhi,
    required this.tianPanZhi,
  });

  factory _LegacyShenJiangPosition.fromJson(Map<String, dynamic> json) {
    const expectedKeys = <String>{'shenJiang', 'diZhi', 'tianPanZhi'};
    final actualKeys = json.keys.toSet();
    if (actualKeys.length != expectedKeys.length ||
        !actualKeys.containsAll(expectedKeys)) {
      throw ArgumentError.value(
        actualKeys,
        'positions',
        '旧位置字段不完整',
      );
    }
    final diZhi = _legacyRequiredString(json['diZhi'], 'diZhi');
    final tianPanZhi = _legacyRequiredString(json['tianPanZhi'], 'tianPanZhi');
    TianPanMapContract.validateBranch(diZhi, 'diZhi');
    TianPanMapContract.validateBranch(tianPanZhi, 'tianPanZhi');
    return _LegacyShenJiangPosition(
      shenJiang: _legacyParseEnum(
        ShenJiang.values,
        json['shenJiang'],
        'shenJiang',
      ),
      diZhi: diZhi,
      tianPanZhi: tianPanZhi,
    );
  }

  final ShenJiang shenJiang;
  final String diZhi;
  final String tianPanZhi;
}

Map<String, dynamic> _stringKeyedJsonMap(
  Map<dynamic, dynamic> raw,
  String field,
) {
  final result = <String, dynamic>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw ArgumentError.value(entry.key, field, '对象键必须是字符串');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _legacyRequiredString(Object? raw, String field) {
  if (raw is! String) {
    throw ArgumentError.value(raw, field, '必须是字符串');
  }
  return raw;
}

bool _legacyRequiredBool(Object? raw, String field) {
  if (raw is! bool) {
    throw ArgumentError.value(raw, field, '必须是布尔值');
  }
  return raw;
}

T _legacyParseEnum<T extends Enum>(
  List<T> values,
  Object? raw,
  String field,
) {
  if (raw is String) {
    for (final value in values) {
      if (value.toString().split('.').last == raw) return value;
    }
  }
  throw ArgumentError.value(raw, field, '不是已知枚举值');
}
