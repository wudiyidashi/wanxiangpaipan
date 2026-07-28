import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../../models/lunar_info.dart';
import 'dlr_rule_contract.dart';

enum DlrManualInputMode {
  rawPillars('rawPillars'),
  calendarBacked('calendarBacked');

  const DlrManualInputMode(this.id);

  final String id;

  static DlrManualInputMode fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError.value(id, 'id', '未知的手工输入模式'),
      );
}

enum DlrMonthGeneralResolutionMode {
  zhongQi('zhongQi'),
  manualOverride('manualOverride');

  const DlrMonthGeneralResolutionMode(this.id);

  final String id;

  static DlrMonthGeneralResolutionMode fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError.value(id, 'id', '未知的月将解析模式'),
      );
}

/// One absolute instant plus the fixed civil offset captured at cast time.
class DlrCivilTime {
  factory DlrCivilTime({
    required DateTime instant,
    required int sourceUtcOffsetMinutes,
  }) {
    if (sourceUtcOffsetMinutes < -840 || sourceUtcOffsetMinutes > 840) {
      throw ArgumentError.value(
        sourceUtcOffsetMinutes,
        'sourceUtcOffsetMinutes',
        'UTC offset 必须在 [-840, 840] 分钟内',
      );
    }
    return DlrCivilTime._(
      instantUtc: instant.toUtc(),
      sourceUtcOffsetMinutes: sourceUtcOffsetMinutes,
    );
  }

  factory DlrCivilTime.fromJson(Map<String, dynamic> json) {
    final rawInstant = json['instantUtc'];
    if (rawInstant is! String || !_hasExplicitZone(rawInstant)) {
      throw ArgumentError.value(
        rawInstant,
        'instantUtc',
        '权威时刻必须是带 Z 或 offset 的 ISO-8601 字符串',
      );
    }
    final DateTime instant;
    try {
      instant = DateTime.parse(rawInstant);
    } on FormatException {
      throw ArgumentError.value(rawInstant, 'instantUtc', '时刻格式不合法');
    }
    final rawOffset = json['sourceUtcOffsetMinutes'];
    if (rawOffset is! num ||
        !rawOffset.isFinite ||
        rawOffset != rawOffset.roundToDouble()) {
      throw ArgumentError.value(
        rawOffset,
        'sourceUtcOffsetMinutes',
        'UTC offset 必须是有限整数',
      );
    }
    return DlrCivilTime(
      instant: instant,
      sourceUtcOffsetMinutes: rawOffset.toInt(),
    );
  }

  const DlrCivilTime._({
    required this.instantUtc,
    required this.sourceUtcOffsetMinutes,
  });

  final DateTime instantUtc;
  final int sourceUtcOffsetMinutes;

  DateTime get sourceWallTime => wallTimeAtOffset(
        instantUtc,
        sourceUtcOffsetMinutes,
      );

  static DateTime wallTimeAtOffset(DateTime instant, int offsetMinutes) {
    final shifted = instant.toUtc().add(Duration(minutes: offsetMinutes));
    return DateTime.utc(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'instantUtc': instantUtc.toUtc().toIso8601String(),
        'sourceUtcOffsetMinutes': sourceUtcOffsetMinutes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DlrCivilTime &&
          other.instantUtc == instantUtc &&
          other.sourceUtcOffsetMinutes == sourceUtcOffsetMinutes;

  @override
  int get hashCode => Object.hash(instantUtc, sourceUtcOffsetMinutes);
}

class DlrPillars {
  factory DlrPillars({
    required String yearGanZhi,
    required String monthGanZhi,
    required String dayGanZhi,
    required String hourGanZhi,
  }) {
    final values = <String, String>{
      'yearGanZhi': yearGanZhi,
      'monthGanZhi': monthGanZhi,
      'dayGanZhi': dayGanZhi,
      'hourGanZhi': hourGanZhi,
    };
    for (final entry in values.entries) {
      if (!TianGanDiZhiService.isValidGanZhi(entry.value)) {
        throw ArgumentError.value(entry.value, entry.key, '必须属于六十甲子');
      }
    }
    return DlrPillars._(
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      dayGanZhi: dayGanZhi,
      hourGanZhi: hourGanZhi,
    );
  }

  factory DlrPillars.fromJson(Map<String, dynamic> json) => DlrPillars(
        yearGanZhi: _requiredString(json['yearGanZhi'], 'yearGanZhi'),
        monthGanZhi: _requiredString(json['monthGanZhi'], 'monthGanZhi'),
        dayGanZhi: _requiredString(json['dayGanZhi'], 'dayGanZhi'),
        hourGanZhi: _requiredString(json['hourGanZhi'], 'hourGanZhi'),
      );

  const DlrPillars._({
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
  });

  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String hourGanZhi;

  String get yearGan => yearGanZhi.substring(0, 1);
  String get monthGan => monthGanZhi.substring(0, 1);
  String get monthZhi => monthGanZhi.substring(1);
  String get dayGan => dayGanZhi.substring(0, 1);
  String get dayZhi => dayGanZhi.substring(1);
  String get hourGan => hourGanZhi.substring(0, 1);
  String get hourZhi => hourGanZhi.substring(1);

  void validateRawStemLinks() {
    final expectedMonthGan = expectedMonthGanFor(
      yearGan: yearGan,
      monthZhi: monthZhi,
    );
    if (monthGan != expectedMonthGan) {
      throw ArgumentError.value(
        monthGanZhi,
        'monthGanZhi',
        '$yearGan年$monthZhi月的月干应为$expectedMonthGan',
      );
    }
    final expectedHourGan = expectedHourGanFor(
      dayGan: dayGan,
      hourZhi: hourZhi,
    );
    if (hourGan != expectedHourGan) {
      throw ArgumentError.value(
        hourGanZhi,
        'hourGanZhi',
        '$dayGan日$hourZhi时的时干应为$expectedHourGan',
      );
    }
  }

  static String expectedMonthGanFor({
    required String yearGan,
    required String monthZhi,
  }) {
    final yearIndex = TianGanDiZhiService.getTianGanIndex(yearGan);
    final monthIndex = TianGanDiZhiService.getDiZhiIndex(monthZhi);
    if (yearIndex < 0 || monthIndex < 0) {
      throw ArgumentError('无法根据年干$yearGan和月支$monthZhi计算月干');
    }
    final yinMonthStart = ((yearIndex % 5) * 2 + 2) % 10;
    final monthOffset = (monthIndex - 2 + 12) % 12;
    return TianGanDiZhiService.getTianGanByIndex(
      yinMonthStart + monthOffset,
    );
  }

  static String expectedHourGanFor({
    required String dayGan,
    required String hourZhi,
  }) {
    final dayIndex = TianGanDiZhiService.getTianGanIndex(dayGan);
    final hourIndex = TianGanDiZhiService.getDiZhiIndex(hourZhi);
    if (dayIndex < 0 || hourIndex < 0) {
      throw ArgumentError('无法根据日干$dayGan和时支$hourZhi计算时干');
    }
    return TianGanDiZhiService.getTianGanByIndex(
      (dayIndex % 5) * 2 + hourIndex,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'yearGanZhi': yearGanZhi,
        'monthGanZhi': monthGanZhi,
        'dayGanZhi': dayGanZhi,
        'hourGanZhi': hourGanZhi,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DlrPillars &&
          other.yearGanZhi == yearGanZhi &&
          other.monthGanZhi == monthGanZhi &&
          other.dayGanZhi == dayGanZhi &&
          other.hourGanZhi == hourGanZhi;

  @override
  int get hashCode =>
      Object.hash(yearGanZhi, monthGanZhi, dayGanZhi, hourGanZhi);
}

class DlrMonthGeneralResolution {
  factory DlrMonthGeneralResolution({
    required String yueJiang,
    required DlrMonthGeneralResolutionMode mode,
    String? effectiveZhongQi,
    DateTime? effectiveZhongQiInstantUtc,
    required String calendarEngine,
    required String calendarEngineVersion,
    required String algorithmVersion,
    required DlrRuleRef executionRuleRef,
    List<String> classicAttributionRuleIds = const <String>[],
  }) {
    if (!TianGanDiZhiService.isValidDiZhi(yueJiang)) {
      throw ArgumentError.value(yueJiang, 'yueJiang', '月将必须是合法地支');
    }
    if (calendarEngine.trim().isEmpty ||
        calendarEngineVersion.trim().isEmpty ||
        algorithmVersion.trim().isEmpty) {
      throw ArgumentError('历法引擎和算法版本不能为空');
    }
    if (executionRuleRef.kind != DlrRuleKind.project ||
        !executionRuleRef.ruleId.startsWith('dlr.project.pan.')) {
      throw ArgumentError.value(
        executionRuleRef,
        'executionRuleRef',
        '月将执行规则必须是 project-pan 规则',
      );
    }
    if (!executionRuleRef.ruleSetVersion.startsWith('daliuren-pan/')) {
      throw ArgumentError.value(
        executionRuleRef,
        'executionRuleRef',
        '月将执行规则必须使用 daliuren-pan 规则集版本',
      );
    }
    for (final ruleId in classicAttributionRuleIds) {
      if (!ruleId.startsWith('dlr.rule.')) {
        throw ArgumentError.value(
          ruleId,
          'classicAttributionRuleIds',
          '古籍 attribution 必须使用 dlr.rule.* ID',
        );
      }
    }
    if (mode == DlrMonthGeneralResolutionMode.zhongQi &&
        ((effectiveZhongQi?.trim().isEmpty ?? true) ||
            effectiveZhongQiInstantUtc == null)) {
      throw ArgumentError('中气解析必须保存中气名称与绝对时刻');
    }
    if (mode == DlrMonthGeneralResolutionMode.manualOverride &&
        (effectiveZhongQi != null || effectiveZhongQiInstantUtc != null)) {
      throw ArgumentError('手动月将不能伪造中气来源');
    }
    if (mode == DlrMonthGeneralResolutionMode.manualOverride &&
        classicAttributionRuleIds.isNotEmpty) {
      throw ArgumentError('手动月将不能挂接古籍 attribution');
    }
    return DlrMonthGeneralResolution._(
      yueJiang: yueJiang,
      mode: mode,
      effectiveZhongQi: effectiveZhongQi,
      effectiveZhongQiInstantUtc: effectiveZhongQiInstantUtc?.toUtc(),
      calendarEngine: calendarEngine,
      calendarEngineVersion: calendarEngineVersion,
      algorithmVersion: algorithmVersion,
      executionRuleRef: executionRuleRef,
      classicAttributionRuleIds:
          List<String>.unmodifiable(classicAttributionRuleIds),
    );
  }

  factory DlrMonthGeneralResolution.fromJson(Map<String, dynamic> json) {
    final rawAttributions = json['classicAttributionRuleIds'];
    if (rawAttributions != null && rawAttributions is! List) {
      throw ArgumentError.value(
        rawAttributions,
        'classicAttributionRuleIds',
        '古籍 attribution 必须是字符串数组',
      );
    }
    final attributions = <String>[];
    for (final value in rawAttributions as List? ?? const <dynamic>[]) {
      if (value is! String || !value.startsWith('dlr.rule.')) {
        throw ArgumentError.value(value, 'classicAttributionRuleIds');
      }
      attributions.add(value);
    }
    final rawTermInstant = json['effectiveZhongQiInstantUtc'];
    DateTime? termInstant;
    if (rawTermInstant != null) {
      if (rawTermInstant is! String || !_hasExplicitZone(rawTermInstant)) {
        throw ArgumentError.value(
          rawTermInstant,
          'effectiveZhongQiInstantUtc',
          '中气时刻必须带明确 zone',
        );
      }
      try {
        termInstant = DateTime.parse(rawTermInstant);
      } on FormatException {
        throw ArgumentError.value(
          rawTermInstant,
          'effectiveZhongQiInstantUtc',
          '中气时刻格式不合法',
        );
      }
    }
    final rawRuleRef = json['executionRuleRef'];
    if (rawRuleRef is! Map) {
      throw ArgumentError.value(rawRuleRef, 'executionRuleRef');
    }
    return DlrMonthGeneralResolution(
      yueJiang: _requiredString(json['yueJiang'], 'yueJiang'),
      mode: DlrMonthGeneralResolutionMode.fromId(
        _requiredString(json['mode'], 'mode'),
      ),
      effectiveZhongQi: json['effectiveZhongQi'] as String?,
      effectiveZhongQiInstantUtc: termInstant,
      calendarEngine: _requiredString(
        json['calendarEngine'],
        'calendarEngine',
      ),
      calendarEngineVersion: _requiredString(
        json['calendarEngineVersion'],
        'calendarEngineVersion',
      ),
      algorithmVersion: _requiredString(
        json['algorithmVersion'],
        'algorithmVersion',
      ),
      executionRuleRef: DlrRuleRef.fromJson(
        Map<String, dynamic>.from(rawRuleRef),
      ),
      classicAttributionRuleIds: attributions,
    );
  }

  const DlrMonthGeneralResolution._({
    required this.yueJiang,
    required this.mode,
    required this.effectiveZhongQi,
    required this.effectiveZhongQiInstantUtc,
    required this.calendarEngine,
    required this.calendarEngineVersion,
    required this.algorithmVersion,
    required this.executionRuleRef,
    required this.classicAttributionRuleIds,
  });

  final String yueJiang;
  final DlrMonthGeneralResolutionMode mode;
  final String? effectiveZhongQi;
  final DateTime? effectiveZhongQiInstantUtc;
  final String calendarEngine;
  final String calendarEngineVersion;
  final String algorithmVersion;
  final DlrRuleRef executionRuleRef;
  final List<String> classicAttributionRuleIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'yueJiang': yueJiang,
        'mode': mode.id,
        'effectiveZhongQi': effectiveZhongQi,
        'effectiveZhongQiInstantUtc':
            effectiveZhongQiInstantUtc?.toUtc().toIso8601String(),
        'calendarEngine': calendarEngine,
        'calendarEngineVersion': calendarEngineVersion,
        'algorithmVersion': algorithmVersion,
        'executionRuleRef': executionRuleRef.toJson(),
        'classicAttributionRuleIds': classicAttributionRuleIds,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DlrMonthGeneralResolution &&
          other.yueJiang == yueJiang &&
          other.mode == mode &&
          other.effectiveZhongQi == effectiveZhongQi &&
          other.effectiveZhongQiInstantUtc == effectiveZhongQiInstantUtc &&
          other.calendarEngine == calendarEngine &&
          other.calendarEngineVersion == calendarEngineVersion &&
          other.algorithmVersion == algorithmVersion &&
          other.executionRuleRef == executionRuleRef &&
          _listEquals(
            other.classicAttributionRuleIds,
            classicAttributionRuleIds,
          );

  @override
  int get hashCode => Object.hash(
        yueJiang,
        mode,
        effectiveZhongQi,
        effectiveZhongQiInstantUtc,
        calendarEngine,
        calendarEngineVersion,
        algorithmVersion,
        executionRuleRef,
        Object.hashAll(classicAttributionRuleIds),
      );
}

class DlrResolvedCastTime {
  const DlrResolvedCastTime({
    required this.civilTime,
    required this.pillars,
    required this.lunarInfo,
    required this.monthGeneralResolution,
  });

  final DlrCivilTime civilTime;
  final DlrPillars pillars;
  final LunarInfo lunarInfo;
  final DlrMonthGeneralResolution monthGeneralResolution;
}

String _requiredString(Object? value, String fieldName) {
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, '必须是非空字符串');
  }
  return value;
}

bool _hasExplicitZone(String value) =>
    RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(value);

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
