import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';

/// 小六壬占卜结果
///
/// 小六壬是一种简化的占卜方法，使用大安、留连、速喜、赤口、小吉、空亡
/// 六个位置进行推算。
///
/// 核心概念：
/// - 六神：大安、留连、速喜、赤口、小吉、空亡
/// - 起卦方式：月、日、时三次推算
/// - 落宫：最终落在哪个六神位置
class XiaoLiuRenResult implements DivinationResult {
  @override
  final String id;

  @override
  final DivinationType systemType;

  @override
  final DateTime castTime;

  @override
  final CastMethod castMethod;

  @override
  final LunarInfo lunarInfo;

  /// 占位数据（未来实现时替换）
  final Map<String, dynamic> placeholderData;

  XiaoLiuRenResult({
    required this.id,
    required this.castTime,
    required this.castMethod,
    required this.lunarInfo,
    this.placeholderData = const {},
  }) : systemType = DivinationType.xiaoLiuRen;

  @override
  String getSummary() {
    return '小六壬占卜（未实现）';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systemType': systemType.id,
      'castTime': castTime.toIso8601String(),
      'castMethod': castMethod.id,
      'lunarInfo': lunarInfo.toJson(),
      'placeholderData': placeholderData,
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
      placeholderData: (json['placeholderData'] as Map<dynamic, dynamic>?)
              ?.cast<String, dynamic>() ??
          {},
    );
  }

  // TODO: 未来实现时添加以下字段
  // - 六神名称（大安、留连、速喜、赤口、小吉、空亡）
  // - 月推算结果
  // - 日推算结果
  // - 时推算结果
  // - 最终落宫
  // - 占断结果
}
