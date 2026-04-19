import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/config/ai_provider_profile.dart';
import 'package:wanxiang_paipan/ai/template/builtin_templates.dart';
import 'package:wanxiang_paipan/ai/template/prompt_template.dart' as model;
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';

class MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final result = <String, String>{};
    for (final key in keys) {
      final value = _storage[key];
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}

void main() {
  group('AIConfigManager', () {
    late AppDatabase database;
    late MockSecureStorage secureStorage;
    late AIConfigManager manager;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = MockSecureStorage();
      manager = AIConfigManager(
        database: database,
        secureStorage: secureStorage,
      );
      await manager.initializeBuiltInTemplates();
    });

    tearDown(() async {
      await database.close();
    });

    test('clearAllProviderProfiles 应清空配置、激活项和 API Key', () async {
      final profile = AIProviderProfile(
        id: 'profile_1',
        providerId: 'openai_compatible',
        name: '主力配置',
        apiKey: 'secret-key',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
        createdAt: DateTime(2026, 4, 19, 10),
        updatedAt: DateTime(2026, 4, 19, 10),
      );

      await manager.saveProviderProfile(profile);
      await manager.setActiveProviderProfileId(profile.id);
      await manager.setDefaultProviderId(profile.providerId);

      expect(await manager.getProviderProfileCount(), 1);
      expect(await secureStorage.containsKey('llm_profile_profile_1_apikey'),
          isTrue);

      await manager.clearAllProviderProfiles();

      expect(await manager.getProviderProfiles(), isEmpty);
      expect(await manager.getActiveProviderProfileId(), isNull);
      expect(await manager.getDefaultProviderId(), isNull);
      expect(await secureStorage.containsKey('llm_profile_profile_1_apikey'),
          isFalse);
    });

    test('restoreBuiltInTemplates 应删除自定义模板并恢复内置内容', () async {
      final builtIn = BuiltInTemplates.liuYaoSystemPrompt;
      final modifiedBuiltIn = builtIn.copyWith(content: 'modified content');
      final customTemplate = model.PromptTemplate(
        id: 'custom_template_1',
        name: '自定义模板',
        description: 'custom',
        systemType: 'liuyao',
        templateType: 'analysis',
        content: 'custom content',
        variablesJson: '{}',
        isBuiltIn: false,
        isActive: false,
        createdAt: DateTime(2026, 4, 19, 10),
        updatedAt: DateTime(2026, 4, 19, 10),
      );

      await manager.saveTemplate(modifiedBuiltIn);
      await manager.saveTemplate(customTemplate);
      expect(await manager.getCustomTemplateCount(), 1);

      await manager.restoreBuiltInTemplates();

      final restoredTemplates = await manager.getAllTemplates();
      final restoredBuiltIn =
          restoredTemplates.firstWhere((t) => t.id == builtIn.id);

      expect(restoredBuiltIn.content, builtIn.content);
      expect(restoredTemplates.any((t) => t.id == customTemplate.id), isFalse);
      expect(await manager.getCustomTemplateCount(), 0);
    });

    test('clearAllProviderProfiles 应顺带清理遗留旧配置残留', () async {
      await secureStorage.write(
        'llm_provider_openai_compatible_apikey',
        'legacy-key',
      );
      await database.aIConfigDao.upsertProviderConfig(
        ProviderConfigsCompanion(
          providerId: const drift.Value('openai_compatible'),
          config: drift.Value(
              '{"baseUrl":"https://api.deepseek.com/v1","model":"deepseek-chat"}'),
          currentModel: const drift.Value('deepseek-chat'),
          isEnabled: const drift.Value(true),
          updatedAt: drift.Value(DateTime(2026, 4, 19, 10)),
        ),
      );

      await manager.clearAllProviderProfiles();

      expect(
        await secureStorage
            .containsKey('llm_provider_openai_compatible_apikey'),
        isFalse,
      );
      expect(await database.aIConfigDao.getAllProviderConfigs(), isEmpty);
    });
  });
}
