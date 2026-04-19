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
import 'ai_provider_profile.dart';
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

  static const keyProviderProfiles = 'ai_provider_profiles_v1';
  static const keyActiveProviderProfileId = 'ai_active_provider_profile_id';
  static const keyLastBackupAt = 'data_management_last_backup_at';
  static const internalPreferenceKeys = {
    keyProviderProfiles,
    keyActiveProviderProfileId,
    keyDefaultProviderId,
    keyLastBackupAt,
  };

  String _profileApiKeyStorageKey(String profileId) =>
      'llm_profile_${profileId}_apikey';
  String _legacyProviderApiKeyStorageKey(String providerId) =>
      'llm_provider_${providerId}_apikey';

  /// 获取全部命名接口配置。
  Future<List<AIProviderProfile>> getProviderProfiles() async {
    final raw = await getString(keyProviderProfiles);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      final profiles = <AIProviderProfile>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final json = Map<String, dynamic>.from(item);
        final profileId = json['id'] as String?;
        if (profileId == null || profileId.isEmpty) continue;
        final apiKey =
            await _secureStorage.read(_profileApiKeyStorageKey(profileId));
        profiles.add(AIProviderProfile.fromJson(json, apiKey: apiKey ?? ''));
      }

      profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return profiles;
    } catch (_) {
      return [];
    }
  }

  Future<AIProviderProfile?> getProviderProfile(String profileId) async {
    final profiles = await getProviderProfiles();
    for (final profile in profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  Future<void> saveProviderProfile(AIProviderProfile profile) async {
    final profiles = await getProviderProfiles();
    final updated = profile.copyWith(updatedAt: DateTime.now());
    final index = profiles.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      profiles[index] = updated;
    } else {
      profiles.add(updated);
    }

    await _secureStorage.write(
      _profileApiKeyStorageKey(updated.id),
      updated.apiKey,
    );
    await setString(
      keyProviderProfiles,
      jsonEncode(profiles.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteProviderProfile(String profileId) async {
    final profiles = await getProviderProfiles();
    profiles.removeWhere((item) => item.id == profileId);
    await _secureStorage.delete(_profileApiKeyStorageKey(profileId));

    if (profiles.isEmpty) {
      await deletePreference(keyProviderProfiles);
      await deletePreference(keyActiveProviderProfileId);
      return;
    }

    await setString(
      keyProviderProfiles,
      jsonEncode(profiles.map((item) => item.toJson()).toList()),
    );

    final activeId = await getActiveProviderProfileId();
    if (activeId == profileId) {
      await setActiveProviderProfileId(profiles.first.id);
    }
  }

  Future<int> getProviderProfileCount() async {
    final profiles = await getProviderProfiles();
    return profiles.length;
  }

  Future<void> clearAllProviderProfiles() async {
    final profiles = await getProviderProfiles();
    for (final profile in profiles) {
      await _secureStorage.delete(_profileApiKeyStorageKey(profile.id));
    }

    final legacyConfigs = await _database.aIConfigDao.getAllProviderConfigs();
    for (final config in legacyConfigs) {
      await _secureStorage.delete('llm_provider_${config.providerId}_apikey');
    }
    await _database.aIConfigDao.deleteAllProviderConfigs();

    await deletePreference(keyProviderProfiles);
    await deletePreference(keyActiveProviderProfileId);
    await deletePreference(keyDefaultProviderId);
  }

  Future<String?> getActiveProviderProfileId() =>
      getString(keyActiveProviderProfileId);

  Future<void> setActiveProviderProfileId(String profileId) =>
      setString(keyActiveProviderProfileId, profileId);

  Future<AIProviderProfile?> getActiveProviderProfile() async {
    final activeId = await getActiveProviderProfileId();
    if (activeId == null || activeId.isEmpty) {
      return null;
    }
    return getProviderProfile(activeId);
  }

  /// 将旧的单配置结构迁移到多命名配置。
  Future<void> migrateLegacyProviderConfigIfNeeded() async {
    final profiles = await getProviderProfiles();
    if (profiles.isNotEmpty) {
      return;
    }

    const legacyProviderId = 'openai_compatible';
    final legacy = await _loadLegacyProviderConfig(legacyProviderId);
    if (legacy == null) {
      return;
    }

    final profile = AIProviderProfile(
      id: 'openai_compatible_default',
      providerId: 'openai_compatible',
      name: '默认配置',
      apiKey: legacy['apiKey'] as String? ?? '',
      baseUrl: legacy['baseUrl'] as String?,
      model: legacy['model'] as String? ?? 'gpt-3.5-turbo',
      temperature: (legacy['temperature'] as num?)?.toDouble() ?? 0.7,
      maxOutputTokens: legacy['maxOutputTokens'] as int? ?? 4096,
      isEnabled: legacy['isEnabled'] as bool? ?? true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveProviderProfile(profile);
    await setActiveProviderProfileId(profile.id);
    await _deleteLegacyProviderConfig(legacyProviderId);
  }

  Future<Map<String, dynamic>?> _loadLegacyProviderConfig(
    String providerId,
  ) async {
    final apiKey =
        await _secureStorage.read(_legacyProviderApiKeyStorageKey(providerId));

    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final configRecord =
        await _database.aIConfigDao.getProviderConfig(providerId);
    if (configRecord == null) {
      return null;
    }

    final config = jsonDecode(configRecord.config) as Map<String, dynamic>;
    config['apiKey'] = apiKey;
    config['isEnabled'] = configRecord.isEnabled;
    return config;
  }

  Future<void> _deleteLegacyProviderConfig(String providerId) async {
    await _secureStorage.delete(_legacyProviderApiKeyStorageKey(providerId));
    await _database.aIConfigDao.deleteProviderConfig(providerId);
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

  Future<int> getCustomTemplateCount() async {
    final templates = await getAllTemplates();
    return templates.where((item) => !item.isBuiltIn).length;
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

  Future<int> restoreBuiltInTemplates() async {
    final deletedCustomCount =
        await _database.aIConfigDao.deleteCustomTemplates();
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
              createdAt: Value(t.createdAt ?? DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ))
        .toList();
    await _database.aIConfigDao.insertTemplates(companions);
    return deletedCustomCount + companions.length;
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

  Future<Map<String, String>> getAllPreferences() {
    return _database.aIConfigDao.getAllPreferences();
  }

  Future<Map<String, String>> getExportablePreferences() async {
    final all = await getAllPreferences();
    final result = <String, String>{};
    for (final entry in all.entries) {
      if (!internalPreferenceKeys.contains(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Future<void> replaceExportablePreferences(
    Map<String, String> preferences, {
    bool clearExisting = false,
  }) async {
    if (clearExisting) {
      final current = await getExportablePreferences();
      for (final key in current.keys) {
        await deletePreference(key);
      }
    }

    for (final entry in preferences.entries) {
      await setString(entry.key, entry.value);
    }
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

  Future<DateTime?> getLastBackupAt() async {
    final raw = await getString(keyLastBackupAt);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> setLastBackupAt(DateTime time) =>
      setString(keyLastBackupAt, time.toIso8601String());
}
