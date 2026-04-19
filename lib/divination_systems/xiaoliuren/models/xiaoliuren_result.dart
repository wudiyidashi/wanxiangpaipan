import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';

/// 小六壬占卜结果
///
/// 第一版严格围绕“月 -> 日 -> 时”三段顺推链建模，
/// 不引入额外神煞、宫盘或多流派兼容规则。
class XiaoLiuRenResult implements DivinationResult {
  @override
  final String id;

  @override
  final DateTime castTime;

  @override
  final CastMethod castMethod;

  @override
  final LunarInfo lunarInfo;

  final XiaoLiuRenPalaceMode palaceMode;
  final XiaoLiuRenSource source;
  final XiaoLiuRenPosition monthPosition;
  final XiaoLiuRenPosition dayPosition;
  final XiaoLiuRenPosition hourPosition;
  final XiaoLiuRenPosition finalPosition;
  final String judgement;
  final String detail;
  final String questionId;
  final String detailId;
  final String interpretationId;

  XiaoLiuRenResult({
    required this.id,
    required this.castTime,
    required this.castMethod,
    required this.lunarInfo,
    required this.palaceMode,
    required this.source,
    required this.monthPosition,
    required this.dayPosition,
    required this.hourPosition,
    required this.finalPosition,
    required this.judgement,
    required this.detail,
    this.questionId = '',
    this.detailId = '',
    this.interpretationId = '',
  });

  @override
  DivinationType get systemType => DivinationType.xiaoLiuRen;

  @override
  String getSummary() => '${finalPosition.name} · ${finalPosition.keyword}';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systemType': systemType.id,
      'castTime': castTime.toIso8601String(),
      'castMethod': castMethod.id,
      'lunarInfo': lunarInfo.toJson(),
      'palaceMode': palaceMode.id,
      'source': source.toJson(),
      'monthPosition': monthPosition.toJson(),
      'dayPosition': dayPosition.toJson(),
      'hourPosition': hourPosition.toJson(),
      'finalPosition': finalPosition.toJson(),
      'judgement': judgement,
      'detail': detail,
      'questionId': questionId,
      'detailId': detailId,
      'interpretationId': interpretationId,
    };
  }

  factory XiaoLiuRenResult.fromJson(Map<String, dynamic> json) {
    final systemType = DivinationType.fromId(json['systemType'] as String);
    if (systemType != DivinationType.xiaoLiuRen) {
      throw ArgumentError('小六壬结果的 systemType 无效: ${json['systemType']}');
    }

    return XiaoLiuRenResult(
      id: json['id'] as String,
      castTime: DateTime.parse(json['castTime'] as String),
      castMethod: CastMethod.fromId(json['castMethod'] as String),
      lunarInfo: LunarInfo.fromJson(json['lunarInfo'] as Map<String, dynamic>),
      palaceMode: XiaoLiuRenPalaceMode.fromId(json['palaceMode'] as String),
      source: XiaoLiuRenSource.fromJson(json['source'] as Map<String, dynamic>),
      monthPosition: XiaoLiuRenPosition.fromJson(
        json['monthPosition'] as Map<String, dynamic>,
      ),
      dayPosition: XiaoLiuRenPosition.fromJson(
        json['dayPosition'] as Map<String, dynamic>,
      ),
      hourPosition: XiaoLiuRenPosition.fromJson(
        json['hourPosition'] as Map<String, dynamic>,
      ),
      finalPosition: XiaoLiuRenPosition.fromJson(
        json['finalPosition'] as Map<String, dynamic>,
      ),
      judgement: json['judgement'] as String,
      detail: json['detail'] as String,
      questionId: json['questionId'] as String? ?? '',
      detailId: json['detailId'] as String? ?? '',
      interpretationId: json['interpretationId'] as String? ?? '',
    );
  }
}

enum XiaoLiuRenPalaceMode {
  sixPalaces('六宫', 'sixPalaces'),
  ninePalaces('九宫', 'ninePalaces');

  const XiaoLiuRenPalaceMode(this.displayName, this.id);

  final String displayName;
  final String id;

  static XiaoLiuRenPalaceMode fromId(String id) {
    return XiaoLiuRenPalaceMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw ArgumentError('未知的小六壬盘式: $id'),
    );
  }
}

/// 起课输入源与推算痕迹
class XiaoLiuRenSource {
  final String methodLabel;
  final int firstNumber;
  final int secondNumber;
  final int thirdNumber;
  final String firstLabel;
  final String secondLabel;
  final String thirdLabel;
  final String? hourZhi;
  final bool usesLunarDate;
  final String rule;
  final String? note;

  const XiaoLiuRenSource({
    required this.methodLabel,
    required this.firstNumber,
    required this.secondNumber,
    required this.thirdNumber,
    required this.firstLabel,
    required this.secondLabel,
    required this.thirdLabel,
    this.hourZhi,
    required this.usesLunarDate,
    required this.rule,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'methodLabel': methodLabel,
      'firstNumber': firstNumber,
      'secondNumber': secondNumber,
      'thirdNumber': thirdNumber,
      'firstLabel': firstLabel,
      'secondLabel': secondLabel,
      'thirdLabel': thirdLabel,
      'hourZhi': hourZhi,
      'usesLunarDate': usesLunarDate,
      'rule': rule,
      'note': note,
    };
  }

  factory XiaoLiuRenSource.fromJson(Map<String, dynamic> json) {
    return XiaoLiuRenSource(
      methodLabel: json['methodLabel'] as String,
      firstNumber: json['firstNumber'] as int,
      secondNumber: json['secondNumber'] as int,
      thirdNumber: json['thirdNumber'] as int,
      firstLabel: json['firstLabel'] as String,
      secondLabel: json['secondLabel'] as String,
      thirdLabel: json['thirdLabel'] as String,
      hourZhi: json['hourZhi'] as String?,
      usesLunarDate: json['usesLunarDate'] as bool,
      rule: json['rule'] as String,
      note: json['note'] as String?,
    );
  }
}

/// 六宫定义
class XiaoLiuRenPosition {
  final int index;
  final String name;
  final String fortune;
  final String keyword;
  final String description;
  final String wuXing;
  final String direction;

  const XiaoLiuRenPosition({
    required this.index,
    required this.name,
    required this.fortune,
    required this.keyword,
    required this.description,
    required this.wuXing,
    required this.direction,
  });

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'fortune': fortune,
      'keyword': keyword,
      'description': description,
      'wuXing': wuXing,
      'direction': direction,
    };
  }

  factory XiaoLiuRenPosition.fromJson(Map<String, dynamic> json) {
    return XiaoLiuRenPosition(
      index: json['index'] as int,
      name: json['name'] as String,
      fortune: json['fortune'] as String,
      keyword: json['keyword'] as String,
      description: json['description'] as String,
      wuXing: json['wuXing'] as String,
      direction: json['direction'] as String,
    );
  }
}
