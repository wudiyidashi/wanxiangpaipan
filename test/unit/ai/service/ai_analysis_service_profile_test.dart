import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/config/ai_provider_profile.dart';
import 'package:wanxiang_paipan/ai/llm_provider_registry.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/providers/openai_compatible_provider.dart';
import 'package:wanxiang_paipan/ai/service/ai_analysis_service.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';

class _MockSecureStorage implements SecureStorage {
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
  group('AIAnalysisService profile lifecycle', () {
    late AppDatabase database;
    late _MockSecureStorage secureStorage;
    late AIConfigManager configManager;
    late LLMProviderRegistry providerRegistry;
    late AIAnalysisService analysisService;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = _MockSecureStorage();
      configManager = AIConfigManager(
        database: database,
        secureStorage: secureStorage,
      );
      await configManager.initializeBuiltInTemplates();

      providerRegistry = LLMProviderRegistry.instance;
      providerRegistry.clear();
      providerRegistry.register(OpenAICompatibleProvider());
      StructuredOutputFormatterRegistry.instance.clear();

      analysisService = AIAnalysisService(
        providerRegistry: providerRegistry,
        promptAssembler: PromptAssembler(
          configManager: configManager,
          formatterRegistry: StructuredOutputFormatterRegistry.instance,
        ),
        configManager: configManager,
      );
    });

    tearDown(() async {
      analysisService.dispose();
      providerRegistry.clear();
      StructuredOutputFormatterRegistry.instance.clear();
      await database.close();
    });

    test('saveProviderProfile(activate: true) 应激活并同步 provider 配置', () async {
      final profile = _createProfile(
        id: 'profile_primary',
        name: '主力配置',
        apiKey: 'secret-key-1',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
      );

      await analysisService.saveProviderProfile(profile, activate: true);

      expect(await configManager.getActiveProviderProfileId(), profile.id);
      expect(providerRegistry.defaultProviderId, 'openai_compatible');

      final provider = providerRegistry.getProvider('openai_compatible')
          as OpenAICompatibleProvider;
      final config = provider.getConfigInfo();
      expect(provider.isConfigured, isTrue);
      expect(config?['model'], 'deepseek-chat');
      expect(config?['baseUrl'], 'https://api.deepseek.com/v1');
    });

    test('activateProviderProfile 应切换到指定 profile', () async {
      final primary = _createProfile(
        id: 'profile_primary',
        name: '主力配置',
        apiKey: 'secret-key-1',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
      );
      final backup = _createProfile(
        id: 'profile_backup',
        name: '备用配置',
        apiKey: 'secret-key-2',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4.1',
      );

      await analysisService.saveProviderProfile(primary, activate: true);
      await analysisService.saveProviderProfile(backup, activate: false);
      await analysisService.activateProviderProfile(backup.id);

      final active = await configManager.getActiveProviderProfile();
      final provider = providerRegistry.getProvider('openai_compatible')
          as OpenAICompatibleProvider;
      final config = provider.getConfigInfo();

      expect(active?.id, backup.id);
      expect(config?['model'], 'gpt-4.1');
      expect(config?['baseUrl'], 'https://api.openai.com/v1');
    });

    test('deleteProviderProfile 删除当前激活项后应切回剩余配置', () async {
      final primary = _createProfile(
        id: 'profile_primary',
        name: '主力配置',
        apiKey: 'secret-key-1',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
      );
      final backup = _createProfile(
        id: 'profile_backup',
        name: '备用配置',
        apiKey: 'secret-key-2',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4.1',
      );

      await analysisService.saveProviderProfile(primary, activate: true);
      await analysisService.saveProviderProfile(backup, activate: false);
      await analysisService.activateProviderProfile(backup.id);
      await analysisService.deleteProviderProfile(backup.id);

      final active = await configManager.getActiveProviderProfile();
      final provider = providerRegistry.getProvider('openai_compatible')
          as OpenAICompatibleProvider;
      final config = provider.getConfigInfo();

      expect(active?.id, primary.id);
      expect(config?['model'], 'deepseek-chat');
      expect(config?['baseUrl'], 'https://api.deepseek.com/v1');
    });
  });
}

AIProviderProfile _createProfile({
  required String id,
  required String name,
  required String apiKey,
  required String baseUrl,
  required String model,
}) {
  return AIProviderProfile(
    id: id,
    providerId: 'openai_compatible',
    name: name,
    apiKey: apiKey,
    baseUrl: baseUrl,
    model: model,
    createdAt: DateTime(2026, 4, 19, 12),
    updatedAt: DateTime(2026, 4, 19, 12),
  );
}
