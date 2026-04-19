import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_provider_profile.dart';

void main() {
  group('AIProviderProfile', () {
    test('toJson 默认不包含 apiKey', () {
      final profile = AIProviderProfile(
        id: 'p1',
        providerId: 'openai_compatible',
        name: 'DeepSeek 主力',
        apiKey: 'secret-key',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
        createdAt: DateTime(2026, 4, 19, 10),
        updatedAt: DateTime(2026, 4, 19, 11),
      );

      final json = profile.toJson();
      expect(json['name'], 'DeepSeek 主力');
      expect(json.containsKey('apiKey'), false);
    });

    test('toJson(includeApiKey: true) 应包含 apiKey', () {
      final profile = AIProviderProfile(
        id: 'p1',
        providerId: 'openai_compatible',
        name: 'OpenAI 备用',
        apiKey: 'secret-key',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4.1',
        createdAt: DateTime(2026, 4, 19, 10),
        updatedAt: DateTime(2026, 4, 19, 11),
      );

      final json = profile.toJson(includeApiKey: true);
      expect(json['apiKey'], 'secret-key');
    });

    test('fromJson 应恢复基础字段并注入 apiKey', () {
      final profile = AIProviderProfile.fromJson(
        {
          'id': 'p1',
          'providerId': 'openai_compatible',
          'name': '本地 Ollama',
          'baseUrl': 'http://127.0.0.1:11434/v1',
          'model': 'llama3.1',
          'temperature': 0.3,
          'maxOutputTokens': 2048,
          'isEnabled': true,
          'createdAt': '2026-04-19T10:00:00.000',
          'updatedAt': '2026-04-19T11:00:00.000',
        },
        apiKey: 'local-key',
      );

      expect(profile.id, 'p1');
      expect(profile.name, '本地 Ollama');
      expect(profile.apiKey, 'local-key');
      expect(profile.model, 'llama3.1');
      expect(profile.maxOutputTokens, 2048);
    });
  });
}
