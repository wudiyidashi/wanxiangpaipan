import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'ai_config_dao.g.dart';

/// AI 配置数据访问对象
///
/// 管理 LLM 提供者配置、提示词模板和用户偏好设置的数据库操作。
@DriftAccessor(tables: [ProviderConfigs, PromptTemplates, UserPreferences])
class AIConfigDao extends DatabaseAccessor<AppDatabase>
    with _$AIConfigDaoMixin {
  AIConfigDao(super.db);

  // ==================== Provider 配置操作 ====================

  /// 获取所有提供者配置
  Future<List<ProviderConfig>> getAllProviderConfigs() {
    return select(providerConfigs).get();
  }

  /// 获取指定提供者配置
  Future<ProviderConfig?> getProviderConfig(String providerId) {
    return (select(providerConfigs)
          ..where((t) => t.providerId.equals(providerId)))
        .getSingleOrNull();
  }

  /// 保存或更新提供者配置
  Future<void> upsertProviderConfig(ProviderConfigsCompanion config) {
    return into(providerConfigs).insertOnConflictUpdate(config);
  }

  /// 删除提供者配置
  Future<int> deleteProviderConfig(String providerId) {
    return (delete(providerConfigs)
          ..where((t) => t.providerId.equals(providerId)))
        .go();
  }

  /// 更新提供者启用状态
  Future<bool> updateProviderEnabled(String providerId, bool enabled) async {
    final result = await (update(providerConfigs)
          ..where((t) => t.providerId.equals(providerId)))
        .write(ProviderConfigsCompanion(
      isEnabled: Value(enabled),
      updatedAt: Value(DateTime.now()),
    ));
    return result > 0;
  }

  // ==================== 提示词模板操作 ====================

  /// 获取所有模板
  Future<List<PromptTemplate>> getAllTemplates() {
    return select(promptTemplates).get();
  }

  /// 获取指定系统的模板
  Future<List<PromptTemplate>> getTemplatesBySystem(String systemType) {
    return (select(promptTemplates)
          ..where((t) => t.systemType.equals(systemType))
          ..orderBy([(t) => OrderingTerm.asc(t.templateType)]))
        .get();
  }

  /// 获取指定类型的模板
  Future<List<PromptTemplate>> getTemplatesByType(
    String systemType,
    String templateType,
  ) {
    return (select(promptTemplates)
          ..where((t) =>
              t.systemType.equals(systemType) &
              t.templateType.equals(templateType))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isActive),
            (t) => OrderingTerm.desc(t.isBuiltIn),
          ]))
        .get();
  }

  /// 获取激活的模板
  Future<PromptTemplate?> getActiveTemplate(
    String systemType,
    String templateType,
  ) {
    return (select(promptTemplates)
          ..where((t) =>
              t.systemType.equals(systemType) &
              t.templateType.equals(templateType) &
              t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// 获取指定模板
  Future<PromptTemplate?> getTemplate(String id) {
    return (select(promptTemplates)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 保存或更新模板
  Future<void> upsertTemplate(PromptTemplatesCompanion template) {
    return into(promptTemplates).insertOnConflictUpdate(template);
  }

  /// 批量插入模板（用于初始化内置模板）
  Future<void> insertTemplates(List<PromptTemplatesCompanion> templates) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(promptTemplates, templates);
    });
  }

  /// 设置激活模板（同时取消同类型其他模板的激活状态）
  Future<void> setActiveTemplate(
    String templateId,
    String systemType,
    String templateType,
  ) async {
    await transaction(() async {
      // 先取消同类型模板的激活状态
      await (update(promptTemplates)
            ..where((t) =>
                t.systemType.equals(systemType) &
                t.templateType.equals(templateType)))
          .write(const PromptTemplatesCompanion(isActive: Value(false)));

      // 激活指定模板
      await (update(promptTemplates)..where((t) => t.id.equals(templateId)))
          .write(PromptTemplatesCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }

  /// 删除模板（内置模板不可删除）
  Future<int> deleteTemplate(String id) {
    return (delete(promptTemplates)
          ..where((t) => t.id.equals(id) & t.isBuiltIn.equals(false)))
        .go();
  }

  /// 检查模板是否存在
  Future<bool> templateExists(String id) async {
    final count = await (selectOnly(promptTemplates)
          ..addColumns([promptTemplates.id.count()])
          ..where(promptTemplates.id.equals(id)))
        .map((row) => row.read(promptTemplates.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  // ==================== 用户偏好操作 ====================

  /// 获取用户偏好
  Future<String?> getPreference(String key) async {
    final result = await (select(userPreferences)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// 设置用户偏好
  Future<void> setPreference(String key, String value) {
    return into(userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除用户偏好
  Future<int> deletePreference(String key) {
    return (delete(userPreferences)..where((t) => t.key.equals(key))).go();
  }

  /// 获取所有用户偏好
  Future<Map<String, String>> getAllPreferences() async {
    final results = await select(userPreferences).get();
    return {for (var r in results) r.key: r.value};
  }
}
