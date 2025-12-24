/// 提示词模板数据模型
///
/// 定义用户可配置的提示词模板结构。
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/divination_system.dart';

part 'prompt_template.freezed.dart';
part 'prompt_template.g.dart';

/// 模板类型枚举
enum PromptTemplateType {
  system('系统提示词', 'system'),
  analysis('分析提示词', 'analysis'),
  question('问题引导', 'question'),
  summary('摘要模板', 'summary');

  const PromptTemplateType(this.displayName, this.id);
  final String displayName;
  final String id;

  static PromptTemplateType fromId(String id) {
    return PromptTemplateType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => PromptTemplateType.analysis,
    );
  }
}

/// 模板变量类型
enum TemplateVariableType {
  text('文本', 'text'),
  number('数字', 'number'),
  boolean('布尔', 'boolean'),
  select('选择', 'select'),
  divinationData('排盘数据', 'divination');

  const TemplateVariableType(this.displayName, this.id);
  final String displayName;
  final String id;

  static TemplateVariableType fromId(String id) {
    return TemplateVariableType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => TemplateVariableType.text,
    );
  }
}

/// 提示词模板
@freezed
class PromptTemplate with _$PromptTemplate {
  const factory PromptTemplate({
    /// 模板唯一 ID
    required String id,

    /// 模板名称
    required String name,

    /// 模板描述
    @Default('') String description,

    /// 适用的术数系统类型
    required String systemType,

    /// 模板类型
    required String templateType,

    /// 模板内容
    required String content,

    /// 变量定义 JSON
    @Default('{}') String variablesJson,

    /// 是否为内置模板
    @Default(false) bool isBuiltIn,

    /// 是否激活
    @Default(true) bool isActive,

    /// 创建时间
    DateTime? createdAt,

    /// 更新时间
    DateTime? updatedAt,
  }) = _PromptTemplate;

  factory PromptTemplate.fromJson(Map<String, dynamic> json) =>
      _$PromptTemplateFromJson(json);

  const PromptTemplate._();

  /// 获取术数系统类型枚举
  DivinationType get divinationType => DivinationType.fromId(systemType);

  /// 获取模板类型枚举
  PromptTemplateType get type => PromptTemplateType.fromId(templateType);
}

/// 模板变量定义
@freezed
class TemplateVariable with _$TemplateVariable {
  const factory TemplateVariable({
    /// 变量名
    required String name,

    /// 变量描述
    required String description,

    /// 变量类型
    required String type,

    /// 默认值
    String? defaultValue,

    /// 是否必填
    @Default(false) bool required,

    /// 选项列表（用于 select 类型）
    List<String>? options,
  }) = _TemplateVariable;

  factory TemplateVariable.fromJson(Map<String, dynamic> json) =>
      _$TemplateVariableFromJson(json);

  const TemplateVariable._();

  /// 获取变量类型枚举
  TemplateVariableType get variableType => TemplateVariableType.fromId(type);
}

/// 模板验证结果
@freezed
class TemplateValidationResult with _$TemplateValidationResult {
  const factory TemplateValidationResult({
    /// 是否验证通过
    required bool isValid,

    /// 错误列表
    required List<String> errors,

    /// 警告列表
    @Default([]) List<String> warnings,

    /// 提取的变量列表
    required Set<String> variables,
  }) = _TemplateValidationResult;

  factory TemplateValidationResult.fromJson(Map<String, dynamic> json) =>
      _$TemplateValidationResultFromJson(json);
}
