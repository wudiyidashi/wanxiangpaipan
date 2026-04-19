import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';

/// 梅花易数占卜结果
///
/// 第一版严格围绕“起卦依据 -> 本卦 -> 动爻 -> 变卦 -> 互卦 -> 体用 -> 五行 -> 结论”
/// 这条主链建模，不混入纳甲六亲、六神、世应等六爻概念。
class MeiHuaResult implements DivinationResult {
  @override
  final String id;

  @override
  final DateTime castTime;

  @override
  final CastMethod castMethod;

  @override
  final LunarInfo lunarInfo;

  final MeiHuaSource source;
  final MeiHuaHexagram benGua;
  final MeiHuaHexagram bianGua;
  final MeiHuaHexagram huGua;
  final int movingLine;
  final MeiHuaTrigram tiGua;
  final MeiHuaTrigram yongGua;
  final String bodyUseRule;
  final String wuXingRelation;
  final String questionId;
  final String detailId;
  final String interpretationId;

  MeiHuaResult({
    required this.id,
    required this.castTime,
    required this.castMethod,
    required this.lunarInfo,
    required this.source,
    required this.benGua,
    required this.bianGua,
    required this.huGua,
    required this.movingLine,
    required this.tiGua,
    required this.yongGua,
    required this.bodyUseRule,
    required this.wuXingRelation,
    this.questionId = '',
    this.detailId = '',
    this.interpretationId = '',
  }) : assert(movingLine >= 1 && movingLine <= 6, '动爻必须在 1..6');

  @override
  DivinationType get systemType => DivinationType.meiHua;

  String get movingLineLabel {
    switch (movingLine) {
      case 1:
        return '初爻';
      case 2:
        return '二爻';
      case 3:
        return '三爻';
      case 4:
        return '四爻';
      case 5:
        return '五爻';
      case 6:
        return '上爻';
      default:
        throw StateError('非法动爻: $movingLine');
    }
  }

  @override
  String getSummary() => '${benGua.name} → ${bianGua.name} · $wuXingRelation';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systemType': systemType.id,
      'castTime': castTime.toIso8601String(),
      'castMethod': castMethod.id,
      'lunarInfo': lunarInfo.toJson(),
      'source': source.toJson(),
      'benGua': benGua.toJson(),
      'bianGua': bianGua.toJson(),
      'huGua': huGua.toJson(),
      'movingLine': movingLine,
      'tiGua': tiGua.toJson(),
      'yongGua': yongGua.toJson(),
      'bodyUseRule': bodyUseRule,
      'wuXingRelation': wuXingRelation,
      'questionId': questionId,
      'detailId': detailId,
      'interpretationId': interpretationId,
    };
  }

  factory MeiHuaResult.fromJson(Map<String, dynamic> json) {
    final systemType = DivinationType.fromId(json['systemType'] as String);
    if (systemType != DivinationType.meiHua) {
      throw ArgumentError('梅花易数结果的 systemType 无效: ${json['systemType']}');
    }

    return MeiHuaResult(
      id: json['id'] as String,
      castTime: DateTime.parse(json['castTime'] as String),
      castMethod: CastMethod.fromId(json['castMethod'] as String),
      lunarInfo: LunarInfo.fromJson(json['lunarInfo'] as Map<String, dynamic>),
      source: MeiHuaSource.fromJson(json['source'] as Map<String, dynamic>),
      benGua: MeiHuaHexagram.fromJson(json['benGua'] as Map<String, dynamic>),
      bianGua: MeiHuaHexagram.fromJson(json['bianGua'] as Map<String, dynamic>),
      huGua: MeiHuaHexagram.fromJson(json['huGua'] as Map<String, dynamic>),
      movingLine: json['movingLine'] as int,
      tiGua: MeiHuaTrigram.fromJson(json['tiGua'] as Map<String, dynamic>),
      yongGua: MeiHuaTrigram.fromJson(json['yongGua'] as Map<String, dynamic>),
      bodyUseRule: json['bodyUseRule'] as String,
      wuXingRelation: json['wuXingRelation'] as String,
      questionId: json['questionId'] as String? ?? '',
      detailId: json['detailId'] as String? ?? '',
      interpretationId: json['interpretationId'] as String? ?? '',
    );
  }
}

/// 起卦依据与取数痕迹
class MeiHuaSource {
  final String methodLabel;
  final int upperNumber;
  final int lowerNumber;
  final int movingLineNumber;
  final int? upperRawValue;
  final int? lowerRawValue;
  final int? movingRawValue;
  final int? upperInputNumber;
  final int? lowerInputNumber;
  final String? yearBranch;
  final int? yearNumber;
  final int? monthNumber;
  final int? dayNumber;
  final String? hourBranch;
  final int? hourNumber;
  final String? manualUpperTrigram;
  final String? manualLowerTrigram;
  final String? note;

  const MeiHuaSource({
    required this.methodLabel,
    required this.upperNumber,
    required this.lowerNumber,
    required this.movingLineNumber,
    this.upperRawValue,
    this.lowerRawValue,
    this.movingRawValue,
    this.upperInputNumber,
    this.lowerInputNumber,
    this.yearBranch,
    this.yearNumber,
    this.monthNumber,
    this.dayNumber,
    this.hourBranch,
    this.hourNumber,
    this.manualUpperTrigram,
    this.manualLowerTrigram,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'methodLabel': methodLabel,
      'upperNumber': upperNumber,
      'lowerNumber': lowerNumber,
      'movingLineNumber': movingLineNumber,
      'upperRawValue': upperRawValue,
      'lowerRawValue': lowerRawValue,
      'movingRawValue': movingRawValue,
      'upperInputNumber': upperInputNumber,
      'lowerInputNumber': lowerInputNumber,
      'yearBranch': yearBranch,
      'yearNumber': yearNumber,
      'monthNumber': monthNumber,
      'dayNumber': dayNumber,
      'hourBranch': hourBranch,
      'hourNumber': hourNumber,
      'manualUpperTrigram': manualUpperTrigram,
      'manualLowerTrigram': manualLowerTrigram,
      'note': note,
    };
  }

  factory MeiHuaSource.fromJson(Map<String, dynamic> json) {
    return MeiHuaSource(
      methodLabel: json['methodLabel'] as String,
      upperNumber: json['upperNumber'] as int,
      lowerNumber: json['lowerNumber'] as int,
      movingLineNumber: json['movingLineNumber'] as int,
      upperRawValue: json['upperRawValue'] as int?,
      lowerRawValue: json['lowerRawValue'] as int?,
      movingRawValue: json['movingRawValue'] as int?,
      upperInputNumber: json['upperInputNumber'] as int?,
      lowerInputNumber: json['lowerInputNumber'] as int?,
      yearBranch: json['yearBranch'] as String?,
      yearNumber: json['yearNumber'] as int?,
      monthNumber: json['monthNumber'] as int?,
      dayNumber: json['dayNumber'] as int?,
      hourBranch: json['hourBranch'] as String?,
      hourNumber: json['hourNumber'] as int?,
      manualUpperTrigram: json['manualUpperTrigram'] as String?,
      manualLowerTrigram: json['manualLowerTrigram'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// 八卦模型
class MeiHuaTrigram {
  final String key;
  final String name;
  final String symbol;
  final String wuXing;
  final int number;
  final List<int> lines;

  MeiHuaTrigram({
    required this.key,
    required this.name,
    required this.symbol,
    required this.wuXing,
    required this.number,
    required List<int> lines,
  }) : lines = List.unmodifiable(lines);

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'symbol': symbol,
      'wuXing': wuXing,
      'number': number,
      'lines': lines,
    };
  }

  factory MeiHuaTrigram.fromJson(Map<String, dynamic> json) {
    return MeiHuaTrigram(
      key: json['key'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      wuXing: json['wuXing'] as String,
      number: json['number'] as int,
      lines: List<int>.from(json['lines'] as List),
    );
  }
}

/// 六爻卦模型
class MeiHuaHexagram {
  final String code;
  final String name;
  final MeiHuaTrigram upperTrigram;
  final MeiHuaTrigram lowerTrigram;
  final List<int> lines;

  MeiHuaHexagram({
    required this.code,
    required this.name,
    required this.upperTrigram,
    required this.lowerTrigram,
    required List<int> lines,
  }) : lines = List.unmodifiable(lines);

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'upperTrigram': upperTrigram.toJson(),
      'lowerTrigram': lowerTrigram.toJson(),
      'lines': lines,
    };
  }

  factory MeiHuaHexagram.fromJson(Map<String, dynamic> json) {
    return MeiHuaHexagram(
      code: json['code'] as String,
      name: json['name'] as String,
      upperTrigram:
          MeiHuaTrigram.fromJson(json['upperTrigram'] as Map<String, dynamic>),
      lowerTrigram:
          MeiHuaTrigram.fromJson(json['lowerTrigram'] as Map<String, dynamic>),
      lines: List<int>.from(json['lines'] as List),
    );
  }
}
