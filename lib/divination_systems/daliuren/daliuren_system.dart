import 'dart:math';

import '../../domain/divination_system.dart';
import '../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../domain/services/daliuren/dlr_cast_time_service.dart';
import '../../domain/services/daliuren/tianpan_service.dart';
import '../../domain/services/daliuren/si_ke_service.dart';
import '../../domain/services/daliuren/san_chuan_service.dart';
import '../../domain/services/daliuren/shen_jiang_service.dart';
import '../../domain/services/daliuren/shen_sha_service.dart';
import '../../domain/services/daliuren/yue_jiang_service.dart';
import '../../models/lunar_info.dart';
import 'models/daliuren_result.dart';
import 'models/dlr_cast_time.dart';
import 'models/dlr_rule_contract.dart';
import 'models/pan_params.dart';

/// 大六壬排盘系统
///
/// 大六壬是中国古代三式之一（太乙、奇门、六壬），以天干地支、
/// 十二神将为基础，通过四课三传进行占断。
///
/// 核心算法流程：
/// 1. 获取农历信息（日干支、月建、时支）
/// 2. 计算月将，排列天盘
/// 3. 排列四课
/// 4. 推导三传（根据课体类型）
/// 5. 配置十二神将
/// 6. 计算神煞
class DaLiuRenSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.daLiuRen;

  @override
  String get name => '大六壬';

  @override
  String get description => '大六壬：中国古代三式之一，以天干地支、十二神将为基础，通过四课三传进行占断';

  @override
  bool get isEnabled => true; // 已启用

  @override
  List<CastMethod> get supportedMethods => [
        CastMethod.time, // 时间起课
        CastMethod.reportNumber, // 报数起课
        CastMethod.manual, // 手动输入
        CastMethod.computer, // 随机起课
      ];

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    final time = castTime ?? DateTime.now();

    // Manual parsing owns its validation so calendar mismatches can name the
    // offending pillars instead of being collapsed into a generic error.
    if (method == CastMethod.manual) {
      return _castByManual(time, input);
    }
    if (!validateInput(method, input)) {
      throw ArgumentError('输入参数无效');
    }

    switch (method) {
      case CastMethod.time:
        return _castByTime(time, input);
      case CastMethod.reportNumber:
        return _castByReportNumber(time, input);
      case CastMethod.computer:
        return _castByComputer(time, input);
      default:
        throw UnsupportedError('大六壬不支持的起卦方式: ${method.displayName}');
    }
  }

  /// 地支列表，用于报数和随机起课映射
  static const _diZhiList = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥'
  ];

  /// 时间起课
  ///
  /// [shiZhiOverride] 可选的时支覆盖值，用于报数起课和随机起课
  /// [castMethodOverride] 可选的起课方式覆盖，用于标记实际使用的方式
  Future<DaLiuRenResult> _castByTime(
    DateTime castTime,
    Map<String, dynamic> input, {
    String? shiZhiOverride,
    CastMethod? castMethodOverride,
  }) async {
    final panParams = _parsePanParams(input);
    final civilTime = _civilTimeFromCast(castTime, input);
    final calendarContext = DlrCastTimeService.resolve(civilTime);
    final shiZhi = shiZhiOverride ?? calendarContext.pillars.hourZhi;
    final hourGanZhi = shiZhiOverride == null
        ? calendarContext.pillars.hourGanZhi
        : _buildHourGanZhi(
            dayGan: calendarContext.pillars.dayGan,
            shiZhi: shiZhi,
          );
    final lunarInfo = calendarContext.lunarInfo.copyWith(
      hourGanZhi: hourGanZhi,
      kongWang: _resolveKongWang(
        dayGanZhi: calendarContext.pillars.dayGanZhi,
        hourGanZhi: hourGanZhi,
        xunShouMode: panParams.xunShouMode,
      ),
    );
    final monthGeneralResolution = _resolveMonthGeneral(
      params: panParams,
      automatic: calendarContext.monthGeneralResolution,
    );
    final effectiveCastMethod = castMethodOverride ?? CastMethod.time;
    final castInputSnapshot = _captureTimeDerivedInput(
      castMethod: effectiveCastMethod,
      civilTime: civilTime,
      input: input,
      panParams: panParams,
      resolvedShiZhi: shiZhi,
      resolvedHourGanZhi: hourGanZhi,
    );

    return _assembleResult(
      castTime: castTime,
      castMethod: effectiveCastMethod,
      lunarInfo: lunarInfo,
      shiZhi: shiZhi,
      panParams: panParams,
      civilTime: civilTime,
      monthGeneralResolution: monthGeneralResolution,
      castInputSnapshot: castInputSnapshot,
    );
  }

  /// 报数起课
  ///
  /// 用户提供一个数字，映射到地支作为时支，然后按时间起课流程计算
  Future<DaLiuRenResult> _castByReportNumber(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    final number = input['number'] as int;
    final index = (number.abs() - 1) % 12;
    final shiZhi = _diZhiList[index];

    return _castByTime(
      castTime,
      input,
      shiZhiOverride: shiZhi,
      castMethodOverride: CastMethod.reportNumber,
    );
  }

  /// 随机起课
  ///
  /// 系统随机选择一个地支作为时支，然后按时间起课流程计算
  Future<DaLiuRenResult> _castByComputer(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    final random = Random();
    final index = random.nextInt(12);
    final shiZhi = _diZhiList[index];

    return _castByTime(
      castTime,
      input,
      shiZhiOverride: shiZhi,
      castMethodOverride: CastMethod.computer,
    );
  }

  /// 手动起课
  Future<DaLiuRenResult> _castByManual(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    final command = _parseManualCommand(input);
    return switch (command.mode) {
      DlrManualInputMode.rawPillars => _castRawPillars(
          castTime: castTime,
          input: input,
          command: command,
        ),
      DlrManualInputMode.calendarBacked => _castCalendarBackedManual(
          castTime: castTime,
          input: input,
          command: command,
        ),
    };
  }

  DaLiuRenResult _castRawPillars({
    required DateTime castTime,
    required Map<String, dynamic> input,
    required _ManualCommand command,
  }) {
    final pillars = command.pillars;
    final panParams = command.panParams;
    final sourceUtcOffsetMinutes = _sourceUtcOffsetMinutes(
      input: input,
      castTime: castTime,
    );
    final lunarInfo = LunarInfo(
      yueJian: pillars.monthZhi,
      riGan: pillars.dayGan,
      riZhi: pillars.dayZhi,
      riGanZhi: pillars.dayGanZhi,
      hourGanZhi: pillars.hourGanZhi,
      kongWang: _resolveKongWang(
        dayGanZhi: pillars.dayGanZhi,
        hourGanZhi: pillars.hourGanZhi,
        xunShouMode: panParams.xunShouMode,
      ),
      yearGanZhi: pillars.yearGanZhi,
      monthGanZhi: pillars.monthGanZhi,
    );
    final monthGeneralResolution = YueJiangService.manualOverride(
      panParams.manualMonthGeneral!,
    );
    final snapshot = DlrCastInputSnapshot.capture(
      castMethod: CastMethod.manual,
      castTime: castTime,
      utcOffsetMinutes: sourceUtcOffsetMinutes,
      normalizedInput: <String, dynamic>{
        'manualInputMode': DlrManualInputMode.rawPillars.id,
        ...pillars.toJson(),
        'manualMonthGeneral': monthGeneralResolution.yueJiang,
        'calendarValidated': false,
        'params': panParams.toJson(),
      },
      replayStatus: DlrReplayStatus.complete,
    );

    return _assembleResult(
      castTime: castTime,
      castMethod: CastMethod.manual,
      lunarInfo: lunarInfo,
      shiZhi: pillars.hourZhi,
      panParams: panParams,
      monthGeneralResolution: monthGeneralResolution,
      castInputSnapshot: snapshot,
    );
  }

  DaLiuRenResult _castCalendarBackedManual({
    required DateTime castTime,
    required Map<String, dynamic> input,
    required _ManualCommand command,
  }) {
    final civilTime = command.civilTime!;
    final calendarContext = command.resolvedCastTime!;
    final lunarInfo = calendarContext.lunarInfo.copyWith(
      kongWang: _resolveKongWang(
        dayGanZhi: calendarContext.pillars.dayGanZhi,
        hourGanZhi: calendarContext.pillars.hourGanZhi,
        xunShouMode: command.panParams.xunShouMode,
      ),
    );
    final snapshot = DlrCastInputSnapshot.capture(
      castMethod: CastMethod.manual,
      castTime: civilTime.instantUtc,
      utcOffsetMinutes: civilTime.sourceUtcOffsetMinutes,
      normalizedInput: <String, dynamic>{
        'manualInputMode': DlrManualInputMode.calendarBacked.id,
        'manualCivilDateTime': civilTime.instantUtc.toIso8601String(),
        'sourceUtcOffsetMinutes': civilTime.sourceUtcOffsetMinutes,
        ...calendarContext.pillars.toJson(),
        'calendarValidated': true,
        'params': command.panParams.toJson(),
      },
      replayStatus: DlrReplayStatus.complete,
    );

    return _assembleResult(
      castTime: castTime,
      castMethod: CastMethod.manual,
      lunarInfo: lunarInfo,
      shiZhi: calendarContext.pillars.hourZhi,
      panParams: command.panParams,
      civilTime: civilTime,
      monthGeneralResolution: calendarContext.monthGeneralResolution,
      castInputSnapshot: snapshot,
    );
  }

  DaLiuRenResult _assembleResult({
    required DateTime castTime,
    required CastMethod castMethod,
    required LunarInfo lunarInfo,
    required String shiZhi,
    required DaLiuRenPanParams panParams,
    DlrCivilTime? civilTime,
    required DlrMonthGeneralResolution monthGeneralResolution,
    required DlrCastInputSnapshot castInputSnapshot,
  }) {
    final tianPan = TianPanService.createTianPan(
      yueJiang: monthGeneralResolution.yueJiang,
      shiZhi: shiZhi,
    );
    final shenJiangConfig = ShenJiangService.configureShenJiang(
      riGan: lunarInfo.riGan,
      shiZhi: shiZhi,
      tianPanMap: tianPan.tianPanMap,
      dayNightMode: panParams.dayNightMode,
      guiRenVerse: panParams.guiRenVerse,
    );
    final siKe = SiKeService.arrangeSiKe(
      riGan: lunarInfo.riGan,
      riZhi: lunarInfo.riZhi,
      tianPanMap: tianPan.tianPanMap,
      resolveChengShen: shenJiangConfig.generalForHeavenBranch,
    );
    final sanChuan = SanChuanService.deriveSanChuan(
      siKe: siKe,
      tianPanMap: tianPan.tianPanMap,
      shenJiangConfig: shenJiangConfig,
      kongWang: lunarInfo.kongWang,
    );
    final shenShaList = ShenShaService.calculateShenSha(
      riGan: lunarInfo.riGan,
      riZhi: lunarInfo.riZhi,
      yueJian: lunarInfo.yueJian,
      shiZhi: shiZhi,
    );

    final result = DaLiuRenResult(
      id: _generateId(),
      castTime: castTime,
      castMethod: castMethod,
      lunarInfo: lunarInfo,
      tianPan: tianPan,
      siKe: siKe,
      sanChuan: sanChuan,
      shenJiangConfig: shenJiangConfig,
      shenShaList: shenShaList,
      panParams: panParams,
      panRuleSetVersion: DlrRuleSetVersions.panCurrent,
      evidenceCatalogVersion: DlrRuleSetVersions.evidenceCatalog,
      castInputSnapshot: castInputSnapshot,
      civilTime: civilTime,
      monthGeneralResolution: monthGeneralResolution,
    );
    result.validateShenJiangContract();
    return result;
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return DaLiuRenResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    final paramsValid = _tryParsePanParams(input) != null;
    if (!paramsValid || !_hasValidSourceUtcOffset(input)) {
      return false;
    }

    switch (method) {
      case CastMethod.time:
        return true;
      case CastMethod.reportNumber:
        return input.containsKey('number') && input['number'] is int;
      case CastMethod.computer:
        return true;
      case CastMethod.manual:
        return _tryParseManualCommand(input) != null;
      default:
        return false;
    }
  }

  /// 生成唯一 ID
  String _generateId() {
    return 'dlr_${DateTime.now().millisecondsSinceEpoch}';
  }

  DaLiuRenPanParams _parsePanParams(Map<String, dynamic> input) {
    final parsed = _tryParsePanParams(input);
    if (parsed == null) {
      throw ArgumentError('大六壬参数不合法');
    }
    return parsed;
  }

  DaLiuRenPanParams? _tryParsePanParams(Map<String, dynamic> input) {
    final raw = input['params'];
    if (raw == null) {
      return const DaLiuRenPanParams();
    }
    if (raw is! Map) {
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(raw);
      final monthGeneralMode = map['monthGeneralMode'] is String
          ? DaLiuRenMonthGeneralMode.fromId(
              map['monthGeneralMode'] as String,
            )
          : DaLiuRenMonthGeneralMode.auto;
      final manualMonthGeneral = map['manualMonthGeneral'] as String?;
      if (monthGeneralMode == DaLiuRenMonthGeneralMode.manual &&
          !TianGanDiZhiService.isValidDiZhi(manualMonthGeneral ?? '')) {
        return null;
      }

      final dayNightMode = map['dayNightMode'] is String
          ? DaLiuRenDayNightMode.fromId(map['dayNightMode'] as String)
          : DaLiuRenDayNightMode.auto;
      final guiRenVerse = map['guiRenVerse'] is String
          ? DaLiuRenGuiRenVerse.fromId(map['guiRenVerse'] as String)
          : DaLiuRenGuiRenVerse.classic;
      if (guiRenVerse == DaLiuRenGuiRenVerse.jiaDayAlt) {
        return null;
      }
      final xunShouMode = map['xunShouMode'] is String
          ? DaLiuRenXunShouMode.fromId(map['xunShouMode'] as String)
          : DaLiuRenXunShouMode.day;
      final showSanChuanOnTop = map['showSanChuanOnTop'];
      final birthYear = map['birthYear'];

      return DaLiuRenPanParams(
        birthYear: birthYear is int ? birthYear : null,
        monthGeneralMode: monthGeneralMode,
        manualMonthGeneral: manualMonthGeneral,
        dayNightMode: dayNightMode,
        guiRenVerse: guiRenVerse,
        xunShouMode: xunShouMode,
        showSanChuanOnTop: showSanChuanOnTop is bool ? showSanChuanOnTop : true,
      );
    } catch (_) {
      return null;
    }
  }

  _ManualCommand _parseManualCommand(Map<String, dynamic> input) {
    final rawMode = input['manualInputMode'];
    if (rawMode is! String) {
      throw ArgumentError.value(
        rawMode,
        'manualInputMode',
        '手工起课必须显式选择 rawPillars 或 calendarBacked',
      );
    }
    final mode = DlrManualInputMode.fromId(rawMode);
    final panParams = _parsePanParams(input);
    final pillars = _parsePillars(input);

    switch (mode) {
      case DlrManualInputMode.rawPillars:
        if (input['manualCivilDateTime'] != null) {
          throw ArgumentError('rawPillars 不得同时提供 manualCivilDateTime');
        }
        if (panParams.monthGeneralMode != DaLiuRenMonthGeneralMode.manual ||
            panParams.manualMonthGeneral == null) {
          throw ArgumentError('rawPillars 必须显式提供手动月将');
        }
        pillars.validateRawStemLinks();
        return _ManualCommand(
          mode: mode,
          panParams: panParams,
          pillars: pillars,
        );
      case DlrManualInputMode.calendarBacked:
        if (panParams.monthGeneralMode != DaLiuRenMonthGeneralMode.auto) {
          throw ArgumentError('calendarBacked 必须使用自动月将');
        }
        final civilTime = _parseManualCivilTime(input);
        final resolved = DlrCastTimeService.resolve(civilTime);
        _verifyCalendarPillars(supplied: pillars, resolved: resolved.pillars);
        return _ManualCommand(
          mode: mode,
          panParams: panParams,
          pillars: pillars,
          civilTime: civilTime,
          resolvedCastTime: resolved,
        );
    }
  }

  _ManualCommand? _tryParseManualCommand(Map<String, dynamic> input) {
    try {
      return _parseManualCommand(input);
    } catch (_) {
      return null;
    }
  }

  DlrPillars _parsePillars(Map<String, dynamic> input) {
    final values = <String, String>{};
    for (final field in const <String>[
      'yearGanZhi',
      'monthGanZhi',
      'dayGanZhi',
      'hourGanZhi',
    ]) {
      final value = input[field];
      if (value is! String) {
        throw ArgumentError.value(value, field, '指定干支需要完整输入年柱、月柱、日柱、时柱');
      }
      values[field] = value;
    }
    return DlrPillars(
      yearGanZhi: values['yearGanZhi']!,
      monthGanZhi: values['monthGanZhi']!,
      dayGanZhi: values['dayGanZhi']!,
      hourGanZhi: values['hourGanZhi']!,
    );
  }

  DlrCivilTime _parseManualCivilTime(Map<String, dynamic> input) {
    if (!input.containsKey('sourceUtcOffsetMinutes')) {
      throw ArgumentError('calendarBacked 必须显式提供 sourceUtcOffsetMinutes');
    }
    final rawInstant = input['manualCivilDateTime'];
    final DateTime instant;
    if (rawInstant is DateTime) {
      instant = rawInstant;
    } else if (rawInstant is String && _hasExplicitZone(rawInstant)) {
      try {
        instant = DateTime.parse(rawInstant);
      } on FormatException {
        throw ArgumentError.value(
          rawInstant,
          'manualCivilDateTime',
          '民用时刻格式不合法',
        );
      }
    } else {
      throw ArgumentError.value(
        rawInstant,
        'manualCivilDateTime',
        '必须是 DateTime 或带明确 zone 的 ISO-8601 字符串',
      );
    }
    return DlrCivilTime(
      instant: instant,
      sourceUtcOffsetMinutes: _sourceUtcOffsetMinutes(
        input: input,
        castTime: instant,
        requireExplicit: true,
      ),
    );
  }

  void _verifyCalendarPillars({
    required DlrPillars supplied,
    required DlrPillars resolved,
  }) {
    final mismatches = <String>[
      if (supplied.yearGanZhi != resolved.yearGanZhi)
        'yearGanZhi(${supplied.yearGanZhi} != ${resolved.yearGanZhi})',
      if (supplied.monthGanZhi != resolved.monthGanZhi)
        'monthGanZhi(${supplied.monthGanZhi} != ${resolved.monthGanZhi})',
      if (supplied.dayGanZhi != resolved.dayGanZhi)
        'dayGanZhi(${supplied.dayGanZhi} != ${resolved.dayGanZhi})',
      if (supplied.hourGanZhi != resolved.hourGanZhi)
        'hourGanZhi(${supplied.hourGanZhi} != ${resolved.hourGanZhi})',
    ];
    if (mismatches.isNotEmpty) {
      throw ArgumentError('手工四柱与民用时刻不一致: ${mismatches.join(', ')}');
    }
  }

  DlrCivilTime _civilTimeFromCast(
    DateTime castTime,
    Map<String, dynamic> input,
  ) =>
      DlrCivilTime(
        instant: castTime,
        sourceUtcOffsetMinutes: _sourceUtcOffsetMinutes(
          input: input,
          castTime: castTime,
        ),
      );

  int _sourceUtcOffsetMinutes({
    required Map<String, dynamic> input,
    required DateTime castTime,
    bool requireExplicit = false,
  }) {
    final rawOffset = input['sourceUtcOffsetMinutes'];
    if (rawOffset == null) {
      if (requireExplicit) {
        throw ArgumentError('必须显式提供 sourceUtcOffsetMinutes');
      }
      return castTime.timeZoneOffset.inMinutes;
    }
    if (rawOffset is! int || rawOffset < -840 || rawOffset > 840) {
      throw ArgumentError.value(
        rawOffset,
        'sourceUtcOffsetMinutes',
        'UTC offset 必须是 [-840, 840] 内的整数分钟',
      );
    }
    return rawOffset;
  }

  bool _hasValidSourceUtcOffset(Map<String, dynamic> input) {
    final value = input['sourceUtcOffsetMinutes'];
    return value == null || (value is int && value >= -840 && value <= 840);
  }

  DlrMonthGeneralResolution _resolveMonthGeneral({
    required DaLiuRenPanParams params,
    required DlrMonthGeneralResolution automatic,
  }) =>
      params.monthGeneralMode == DaLiuRenMonthGeneralMode.manual
          ? YueJiangService.manualOverride(params.manualMonthGeneral!)
          : automatic;

  List<String> _resolveKongWang({
    required String dayGanZhi,
    required String hourGanZhi,
    required DaLiuRenXunShouMode xunShouMode,
  }) {
    final target =
        xunShouMode == DaLiuRenXunShouMode.hour ? hourGanZhi : dayGanZhi;
    return TianGanDiZhiService.getKongWang(target);
  }

  String _buildHourGanZhi({
    required String dayGan,
    required String shiZhi,
  }) {
    final hourGan = DlrPillars.expectedHourGanFor(
      dayGan: dayGan,
      hourZhi: shiZhi,
    );
    return '$hourGan$shiZhi';
  }

  DlrCastInputSnapshot _captureTimeDerivedInput({
    required CastMethod castMethod,
    required DlrCivilTime civilTime,
    required Map<String, dynamic> input,
    required DaLiuRenPanParams panParams,
    required String resolvedShiZhi,
    required String resolvedHourGanZhi,
  }) {
    final normalizedInput = <String, dynamic>{
      'civilTime': civilTime.toJson(),
      'params': panParams.toJson(),
    };
    var replayStatus = DlrReplayStatus.complete;
    var missingFields = const <String>[];

    if (castMethod == CastMethod.reportNumber) {
      normalizedInput.addAll(<String, dynamic>{
        'number': input['number'] as int,
        'resolvedShiZhi': resolvedShiZhi,
        'resolvedHourGanZhi': resolvedHourGanZhi,
      });
    } else if (castMethod == CastMethod.computer) {
      normalizedInput.addAll(<String, dynamic>{
        'resolvedShiZhi': resolvedShiZhi,
        'resolvedHourGanZhi': resolvedHourGanZhi,
      });
      replayStatus = DlrReplayStatus.incomplete;
      missingFields = const <String>['randomSeed'];
    } else if (castMethod != CastMethod.time) {
      throw StateError('不支持为 ${castMethod.id} 构造时间派生快照');
    }

    return DlrCastInputSnapshot.capture(
      castMethod: castMethod,
      castTime: civilTime.instantUtc,
      utcOffsetMinutes: civilTime.sourceUtcOffsetMinutes,
      normalizedInput: normalizedInput,
      replayStatus: replayStatus,
      missingFields: missingFields,
    );
  }

  bool _hasExplicitZone(String value) =>
      RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(value);
}

class _ManualCommand {
  const _ManualCommand({
    required this.mode,
    required this.panParams,
    required this.pillars,
    this.civilTime,
    this.resolvedCastTime,
  });

  final DlrManualInputMode mode;
  final DaLiuRenPanParams panParams;
  final DlrPillars pillars;
  final DlrCivilTime? civilTime;
  final DlrResolvedCastTime? resolvedCastTime;
}
