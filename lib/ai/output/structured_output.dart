/// 结构化输出数据模型
///
/// 定义排盘系统生成的标准结构化输出格式，
/// 用于传递给 LLM 进行分析。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'structured_output.freezed.dart';
part 'structured_output.g.dart';

/// 结构化占卜输出
///
/// 排盘系统生成的标准格式，包含：
/// - 系统类型
/// - 时间信息
/// - 核心数据
/// - 结构化段落
@freezed
class StructuredDivinationOutput with _$StructuredDivinationOutput {
  const factory StructuredDivinationOutput({
    /// 术数系统类型
    required String systemType,

    /// 时间信息
    required TemporalInfo temporal,

    /// 核心数据（各系统特定的关键数据）
    required Map<String, dynamic> coreData,

    /// 结构化段落列表
    required List<StructuredSection> sections,

    /// 用户问题（可选）
    String? userQuestion,

    /// 摘要信息
    String? summary,
  }) = _StructuredDivinationOutput;

  factory StructuredDivinationOutput.fromJson(Map<String, dynamic> json) =>
      _$StructuredDivinationOutputFromJson(json);

  const StructuredDivinationOutput._();

  /// 获取指定 key 的段落
  StructuredSection? getSection(String key) {
    return sections.where((s) => s.key == key).firstOrNull;
  }

  /// 检查是否包含指定 key 的段落
  bool hasSection(String key) {
    return sections.any((s) => s.key == key);
  }
}

/// 时间信息
///
/// 包含所有术数系统通用的时间和干支信息。
@freezed
class TemporalInfo with _$TemporalInfo {
  const factory TemporalInfo({
    /// 公历时间
    required DateTime solarTime,

    /// 年干支
    required String yearGanZhi,

    /// 月干支
    required String monthGanZhi,

    /// 日干支
    required String dayGanZhi,

    /// 时干支（可选）
    String? hourGanZhi,

    /// 空亡地支
    required List<String> kongWang,

    /// 节气（可选）
    String? solarTerm,

    /// 农历日期描述（可选）
    String? lunarDate,

    /// 月建
    String? yueJian,
  }) = _TemporalInfo;

  factory TemporalInfo.fromJson(Map<String, dynamic> json) =>
      _$TemporalInfoFromJson(json);
}

/// 结构化段落
///
/// 表示排盘结果中的一个逻辑段落，如本卦、变卦、动爻等。
@freezed
class StructuredSection with _$StructuredSection {
  const factory StructuredSection({
    /// 段落唯一标识（如 mainGua, changingGua, movingYaos）
    required String key,

    /// 段落显示标题
    required String title,

    /// 格式化的文本内容
    required String content,

    /// 段落优先级（用于排序，数字越小越靠前）
    @Default(0) int priority,

    /// 额外元数据
    Map<String, dynamic>? metadata,
  }) = _StructuredSection;

  factory StructuredSection.fromJson(Map<String, dynamic> json) =>
      _$StructuredSectionFromJson(json);
}
