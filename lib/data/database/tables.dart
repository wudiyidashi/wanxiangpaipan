import 'package:drift/drift.dart';

/// 占卜记录表（新架构）
///
/// 支持多术数系统的通用占卜记录表。
/// 使用 systemType 字段区分不同的术数系统（六爻、大六壬、小六壬、梅花易数等）。
class DivinationRecords extends Table {
  /// 主键ID（UUID）
  TextColumn get id => text()();

  /// 术数系统类型（liuYao, daLiuRen, xiaoLiuRen, meiHua）
  TextColumn get systemType => text()();

  /// 起卦时间
  DateTimeColumn get castTime => dateTime()();

  /// 起卦方式（coin, time, manual, number, random）
  TextColumn get castMethod => text()();

  /// 占卜结果数据（JSON）
  /// 存储完整的 DivinationResult 序列化数据
  TextColumn get resultData => text()();

  /// 农历信息（JSON）
  TextColumn get lunarData => text()();

  /// 问事主题加密ID
  TextColumn get questionId => text().withDefault(const Constant(''))();

  /// 详细说明加密ID
  TextColumn get detailId => text().withDefault(const Constant(''))();

  /// 个人解读加密ID
  TextColumn get interpretationId => text().withDefault(const Constant(''))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// LLM 提供者配置表
///
/// 存储各 LLM 提供者的配置信息（不含 API Key，API Key 存储在 SecureStorage）。
class ProviderConfigs extends Table {
  /// 提供者 ID（如 gemini, openai）
  TextColumn get providerId => text()();

  /// 配置数据 JSON（不含敏感信息）
  TextColumn get config => text()();

  /// 当前使用的模型
  TextColumn get currentModel => text().nullable()();

  /// 是否启用
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {providerId};
}

/// 提示词模板表
///
/// 存储用户自定义和内置的提示词模板。
class PromptTemplates extends Table {
  /// 模板唯一 ID
  TextColumn get id => text()();

  /// 模板名称
  TextColumn get name => text()();

  /// 模板描述
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 适用的术数系统类型
  TextColumn get systemType => text()();

  /// 模板类型（system, analysis, question, summary）
  TextColumn get templateType => text()();

  /// 模板内容
  TextColumn get content => text()();

  /// 变量定义 JSON
  TextColumn get variablesJson => text().withDefault(const Constant('{}'))();

  /// 是否为内置模板
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// 是否激活（同类型模板只能有一个激活）
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 用户偏好设置表
///
/// 存储用户的各类偏好设置。
class UserPreferences extends Table {
  /// 设置键
  TextColumn get key => text()();

  /// 设置值（JSON 格式）
  TextColumn get value => text()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
