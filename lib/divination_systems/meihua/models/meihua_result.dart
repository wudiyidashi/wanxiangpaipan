import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';

/// 梅花易数占卜结果
///
/// 梅花易数是宋代邵雍创立的占卜方法，以数字起卦，
/// 通过体卦、用卦、变卦进行占断。
///
/// 核心概念：
/// - 起卦方式：时间起卦、数字起卦、物象起卦
/// - 体卦：代表自己
/// - 用卦：代表他人或事物
/// - 变卦：变化的卦
/// - 五行生克：体用关系
class MeiHuaResult implements DivinationResult {
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

  MeiHuaResult({
    required this.id,
    required this.castTime,
    required this.castMethod,
    required this.lunarInfo,
    this.placeholderData = const {},
  }) : systemType = DivinationType.meiHua;

  @override
  String getSummary() {
    return '梅花易数占卜（未实现）';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systemType': systemType.name,
      'castTime': castTime.toIso8601String(),
      'castMethod': castMethod.name,
      'lunarInfo': lunarInfo.toJson(),
      'placeholderData': placeholderData,
    };
  }

  factory MeiHuaResult.fromJson(Map<String, dynamic> json) {
    return MeiHuaResult(
      id: json['id'] as String,
      castTime: DateTime.parse(json['castTime'] as String),
      castMethod: CastMethod.values.firstWhere(
        (m) => m.name == json['castMethod'],
      ),
      lunarInfo: LunarInfo.fromJson(json['lunarInfo'] as Map<String, dynamic>),
      placeholderData: (json['placeholderData'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {},
    );
  }

  // TODO: 未来实现时添加以下字段
  // - 本卦（上卦、下卦）
  // - 体卦
  // - 用卦
  // - 变卦
  // - 互卦
  // - 五行关系（体用生克）
  // - 占断结果
}
