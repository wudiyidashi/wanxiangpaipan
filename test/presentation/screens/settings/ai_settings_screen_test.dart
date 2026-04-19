import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_provider_profile.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/ai_settings_screen.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/ai_settings_viewmodel.dart';

class _FakeAISettingsService implements AISettingsService {
  _FakeAISettingsService({
    List<AIProviderProfile>? profiles,
    String? activeProfileId,
  })  : _profiles = List<AIProviderProfile>.from(profiles ?? const []),
        _activeProfileId = activeProfileId;

  final List<AIProviderProfile> _profiles;
  final List<AIProviderProfile> savedProfiles = [];
  final List<String> activatedProfileIds = [];
  final List<String> deletedProfileIds = [];
  String? _activeProfileId;

  @override
  Future<void> activateProviderProfile(String profileId) async {
    _activeProfileId = profileId;
    activatedProfileIds.add(profileId);
  }

  @override
  Future<void> deleteProviderProfile(String profileId) async {
    deletedProfileIds.add(profileId);
    _profiles.removeWhere((profile) => profile.id == profileId);
    if (_activeProfileId == profileId) {
      _activeProfileId = _profiles.isEmpty ? null : _profiles.first.id;
    }
  }

  @override
  Future<AIProviderProfile?> getActiveProviderProfile() async {
    final id = _activeProfileId;
    if (id == null) {
      return null;
    }
    for (final profile in _profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  @override
  Future<List<AIProviderProfile>> getProviderProfiles() async {
    return List<AIProviderProfile>.from(_profiles);
  }

  @override
  Future<void> saveProviderProfile(
    AIProviderProfile profile, {
    bool activate = true,
  }) async {
    savedProfiles.add(profile);
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    if (index >= 0) {
      _profiles[index] = profile;
    } else {
      _profiles.add(profile);
    }
    if (activate) {
      _activeProfileId = profile.id;
    }
  }

  @override
  Future<bool> validateProvider(String providerId) async => true;
}

void main() {
  group('AISettingsScreen', () {
    testWidgets('支持获取模型并保存新配置', (tester) async {
      final service = _FakeAISettingsService();

      await tester.pumpWidget(
        MaterialApp(
          home: AISettingsScreen(
            service: service,
            modelFetcher: (_) async => ['deepseek-chat', 'deepseek-reasoner'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('ai_profile_name_field')),
        'DeepSeek 主力',
      );
      await tester.enterText(
        find.byKey(const ValueKey('ai_api_key_field')),
        'secret-key',
      );
      await tester.enterText(
        find.byKey(const ValueKey('ai_model_field')),
        'deepseek-chat',
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ai_fetch_models_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('ai_fetch_models_button')));
      await tester.pumpAndSettle();

      expect(find.text('获取到 2 个模型'), findsOneWidget);
      expect(find.text('快速选择'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ai_save_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('ai_save_button')));
      await tester.pumpAndSettle();

      expect(service.savedProfiles, hasLength(1));
      expect(service.savedProfiles.single.name, 'DeepSeek 主力');
      expect(find.text('配置保存成功，已切换到当前接口'), findsOneWidget);
      expect(find.byTooltip('删除'), findsOneWidget);
    });

    testWidgets('支持切换和删除已有配置', (tester) async {
      final profiles = [
        _createProfile(id: 'primary', name: '主配置', model: 'gpt-4.1'),
        _createProfile(id: 'backup', name: '备用配置', model: 'deepseek-chat'),
      ];
      final service = _FakeAISettingsService(
        profiles: profiles,
        activeProfileId: 'primary',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AISettingsScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ai_profile_tile_primary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ai_profile_tile_backup')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('ai_profile_tile_backup')));
      await tester.pumpAndSettle();

      expect(service.activatedProfileIds, ['backup']);
      expect(find.text('已切换到「备用配置」'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ai_delete_profile_backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();

      expect(service.deletedProfileIds, ['backup']);
      expect(find.text('已删除「备用配置」'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('ai_profile_tile_backup')), findsNothing);
    });
  });
}

AIProviderProfile _createProfile({
  required String id,
  required String name,
  required String model,
}) {
  return AIProviderProfile(
    id: id,
    providerId: 'openai_compatible',
    name: name,
    apiKey: 'secret',
    baseUrl: 'https://api.example.com/v1',
    model: model,
    createdAt: DateTime(2026, 4, 19, 9, 0),
    updatedAt: DateTime(2026, 4, 19, 9, 0),
  );
}
