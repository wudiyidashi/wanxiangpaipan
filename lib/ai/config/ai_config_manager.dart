/// AI 配置管理器
///
/// 统一管理所有 AI 相关配置，包括：
/// - LLM 提供者配置（API Key 加密存储）
/// - 提示词模板
/// - 用户偏好设置
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../../data/secure/secure_storage.dart';
import '../template/prompt_template.dart' as model;
import '../template/builtin_templates.dart';

/// AI 配置管理器
class AIConfigManager {
  final AppDatabase _database;
  final SecureStorage _secureStorage;

  AIConfigManager({
    required AppDatabase database,
    required SecureStorage secureStorage,
  })  : _database = database,
        _secureStorage = secureStorage;

  // ==================== Provider 配置管理 ====================

  /// 保存提供者配置
  ///
  /// API Key 会被加密存储在 SecureStorage 中，
  /// 其他配置存储在数据库中。
  Future<void> saveProviderConfig({
    required String providerId,
    required String apiKey,
    required Map<String, dynamic> config,
  }) async {
    // API Key 加密存储
    await _secureStorage.write(
      'llm_provider_${providerId}_apikey',
      apiKey,
    );

    // 其他配置存储到数据库
    final configJson = Map<String, dynamic>.from(config);
    configJson.remove('apiKey'); // 确保不存储敏感信息

    await _database.aIConfigDao.upsertProviderConfig(
      ProviderConfigsCompanion(
        providerId: Value(providerId),
        config: Value(jsonEncode(configJson)),
        currentModel: Value(configJson['model'] as String?),
        isEnabled: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 加载提供者配置
  ///
  /// 从 SecureStorage 加载 API Key，从数据库加载其他配置。
  Future<Map<String, dynamic>?> loadProviderConfig(String providerId) async {
    final apiKey = await _secureStorage.read(
      'llm_provider_${providerId}_apikey',
    );

    if (apiKey == null) return null;

    final configRecord =
        await _database.aIConfigDao.getProviderConfig(providerId);
    if (configRecord == null) return null;

    final config = jsonDecode(configRecord.config) as Map<String, dynamic>;
    config['apiKey'] = apiKey;
    config['isEnabled'] = configRecord.isEnabled;

    return config;
  }

  /// 删除提供者配置
  Future<void> deleteProviderConfig(String providerId) async {
    await _secureStorage.delete('llm_provider_${providerId}_apikey');
    await _database.aIConfigDao.deleteProviderConfig(providerId);
  }

  /// 检查提供者是否已配置
  Future<bool> isProviderConfigured(String providerId) async {
    final hasApiKey = await _secureStorage.containsKey(
      'llm_provider_${providerId}_apikey',
    );
    return hasApiKey;
  }

  /// 获取所有已配置的提供者 ID
  Future<List<String>> getConfiguredProviderIds() async {
    final configs = await _database.aIConfigDao.getAllProviderConfigs();
    final configuredIds = <String>[];

    for (final config in configs) {
      if (await isProviderConfigured(config.providerId)) {
        configuredIds.add(config.providerId);
      }
    }

    return configuredIds;
  }

  // ==================== 模板配置管理 ====================

  /// 初始化内置模板
  ///
  /// 在应用首次启动时调用，插入所有内置模板。
  Future<void> initializeBuiltInTemplates() async {
    final builtInTemplates = BuiltInTemplates.getAll();

    final companions = builtInTemplates
        .map((t) => PromptTemplatesCompanion(
              id: Value(t.id),
              name: Value(t.name),
              description: Value(t.description),
              systemType: Value(t.systemType),
              templateType: Value(t.templateType),
              content: Value(t.content),
              variablesJson: Value(t.variablesJson),
              isBuiltIn: Value(t.isBuiltIn),
              isActive: Value(t.isActive),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ))
        .toList();

    await _database.aIConfigDao.insertTemplates(companions);
  }

  /// 保存模板
  Future<void> saveTemplate(model.PromptTemplate template) async {
    await _database.aIConfigDao.upsertTemplate(
      PromptTemplatesCompanion(
        id: Value(template.id),
        name: Value(template.name),
        description: Value(template.description),
        systemType: Value(template.systemType),
        templateType: Value(template.templateType),
        content: Value(template.content),
        variablesJson: Value(template.variablesJson),
        isBuiltIn: Value(template.isBuiltIn),
        isActive: Value(template.isActive),
        createdAt: Value(template.createdAt ?? DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 获取所有模板
  Future<List<model.PromptTemplate>> getAllTemplates() async {
    final records = await _database.aIConfigDao.getAllTemplates();
    return records.map(_recordToTemplate).toList();
  }

  /// 获取指定系统的模板
  Future<List<model.PromptTemplate>> getTemplatesBySystem(
      String systemType) async {
    final records =
        await _database.aIConfigDao.getTemplatesBySystem(systemType);
    return records.map(_recordToTemplate).toList();
  }

  /// 获取指定类型的模板
  Future<List<model.PromptTemplate>> getTemplatesByType(
    String systemType,
    String templateType,
  ) async {
    final records = await _database.aIConfigDao.getTemplatesByType(
      systemType,
      templateType,
    );
    return records.map(_recordToTemplate).toList();
  }

  /// 获取激活的模板
  Future<model.PromptTemplate?> getActiveTemplate(
    String systemType,
    String templateType,
  ) async {
    final record = await _database.aIConfigDao.getActiveTemplate(
      systemType,
      templateType,
    );
    return record != null ? _recordToTemplate(record) : null;
  }

  /// 设置激活模板
  Future<void> setActiveTemplate(
    String templateId,
    String systemType,
    String templateType,
  ) async {
    await _database.aIConfigDao.setActiveTemplate(
      templateId,
      systemType,
      templateType,
    );
  }

  /// 删除模板
  Future<bool> deleteTemplate(String templateId) async {
    final count = await _database.aIConfigDao.deleteTemplate(templateId);
    return count > 0;
  }

  model.PromptTemplate _recordToTemplate(PromptTemplate record) {
    return model.PromptTemplate(
      id: record.id,
      name: record.name,
      description: record.description,
      systemType: record.systemType,
      templateType: record.templateType,
      content: record.content,
      variablesJson: record.variablesJson,
      isBuiltIn: record.isBuiltIn,
      isActive: record.isActive,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  // ==================== 用户偏好管理 ====================

  /// 获取字符串偏好
  Future<String?> getString(String key) async {
    return await _database.aIConfigDao.getPreference(key);
  }

  /// 设置字符串偏好
  Future<void> setString(String key, String value) async {
    await _database.aIConfigDao.setPreference(key, value);
  }

  /// 获取布尔偏好
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getString(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  /// 设置布尔偏好
  Future<void> setBool(String key, bool value) async {
    await setString(key, value.toString());
  }

  /// 获取整数偏好
  Future<int?> getInt(String key) async {
    final value = await getString(key);
    return value != null ? int.tryParse(value) : null;
  }

  /// 设置整数偏好
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  /// 获取 JSON 偏好
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 设置 JSON 偏好
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  /// 删除偏好
  Future<void> deletePreference(String key) async {
    await _database.aIConfigDao.deletePreference(key);
  }

  // ==================== 偏好常量 ====================

  /// 默认提供者 ID
  static const keyDefaultProviderId = 'ai_default_provider_id';

  /// 是否启用流式输出
  static const keyEnableStreaming = 'ai_enable_streaming';

  /// 是否自动保存分析结果
  static const keyAutoSaveAnalysis = 'ai_auto_save_analysis';

  /// 获取默认提供者 ID
  Future<String?> getDefaultProviderId() => getString(keyDefaultProviderId);

  /// 设置默认提供者 ID
  Future<void> setDefaultProviderId(String providerId) =>
      setString(keyDefaultProviderId, providerId);

  /// 获取是否启用流式输出
  Future<bool> isStreamingEnabled() =>
      getBool(keyEnableStreaming, defaultValue: true);

  /// 设置是否启用流式输出
  Future<void> setStreamingEnabled(bool enabled) =>
      setBool(keyEnableStreaming, enabled);
}
