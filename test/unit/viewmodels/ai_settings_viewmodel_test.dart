import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_provider_profile.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/ai_settings_viewmodel.dart';

class _FakeAISettingsService implements AISettingsService {
  _FakeAISettingsService({
    List<AIProviderProfile>? profiles,
    String? activeProfileId,
    this.validateResult = true,
  })  : _profiles = List<AIProviderProfile>.from(profiles ?? const []),
        _activeProfileId = activeProfileId;

  final List<AIProviderProfile> _profiles;
  final bool validateResult;
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
    final activeId = _activeProfileId;
    if (activeId == null) {
      return null;
    }

    for (final profile in _profiles) {
      if (profile.id == activeId) {
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
  Future<bool> validateProvider(String providerId) async => validateResult;
}

void main() {
  group('AISettingsViewModel', () {
    test('initialize 应加载激活配置到编辑器', () async {
      final primary = _createProfile(
        id: 'primary',
        name: '主配置',
        model: 'deepseek-chat',
      );
      final backup = _createProfile(
        id: 'backup',
        name: '备用配置',
        model: 'gpt-4.1',
      );
      final viewModel = AISettingsViewModel(
        service: _FakeAISettingsService(
          profiles: [primary, backup],
          activeProfileId: 'primary',
        ),
      );

      await viewModel.initialize();

      expect(viewModel.profiles.map((e) => e.id), ['primary', 'backup']);
      expect(viewModel.activeProfileId, 'primary');
      expect(viewModel.editingProfileId, 'primary');
      expect(viewModel.profileNameController.text, '主配置');
      expect(viewModel.apiKeyController.text, 'secret');
      expect(viewModel.modelController.text, 'deepseek-chat');
      expect(viewModel.availableModels, ['deepseek-chat']);
    });

    test('fetchModels 应校验 API Key 并写入可选模型', () async {
      final viewModel = AISettingsViewModel(
        service: _FakeAISettingsService(),
        modelFetcher: (_) async => ['deepseek-chat', 'deepseek-reasoner'],
      );

      await viewModel.fetchModels();
      expect(viewModel.validationSuccess, isFalse);
      expect(viewModel.validationMessage, '请先输入 API Key');

      viewModel.apiKeyController.text = 'secret-key';
      viewModel.modelController.text = '';

      await viewModel.fetchModels();

      expect(
        viewModel.availableModels,
        ['deepseek-chat', 'deepseek-reasoner'],
      );
      expect(viewModel.modelController.text, 'deepseek-chat');
      expect(viewModel.validationSuccess, isTrue);
      expect(viewModel.validationMessage, '获取到 2 个模型');
    });

    test('saveCurrentProfile 应保存并切换到当前配置', () async {
      final service = _FakeAISettingsService();
      final viewModel = AISettingsViewModel(service: service);

      await viewModel.initialize();
      viewModel.profileNameController.text = 'DeepSeek 主力';
      viewModel.apiKeyController.text = 'secret-key';
      viewModel.baseUrlController.text = 'https://api.deepseek.com/v1';
      viewModel.modelController.text = 'deepseek-chat';

      await viewModel.saveCurrentProfile();

      expect(service.savedProfiles, hasLength(1));
      final saved = service.savedProfiles.single;
      expect(saved.name, 'DeepSeek 主力');
      expect(saved.baseUrl, 'https://api.deepseek.com/v1');
      expect(saved.model, 'deepseek-chat');
      expect(viewModel.activeProfileId, saved.id);
      expect(viewModel.editingProfileId, saved.id);
      expect(viewModel.profiles.map((e) => e.id), [saved.id]);
      expect(viewModel.validationSuccess, isTrue);
      expect(viewModel.validationMessage, '配置保存成功，已切换到当前接口');
    });

    test('saveCurrentProfile 在连接验证失败时应保留保存结果并提示风险', () async {
      final service = _FakeAISettingsService(validateResult: false);
      final viewModel = AISettingsViewModel(service: service);

      await viewModel.initialize();
      viewModel.profileNameController.text = '失败校验配置';
      viewModel.apiKeyController.text = 'secret-key';
      viewModel.modelController.text = 'deepseek-chat';

      await viewModel.saveCurrentProfile();

      expect(service.savedProfiles, hasLength(1));
      expect(viewModel.activeProfileId, service.savedProfiles.single.id);
      expect(viewModel.validationSuccess, isFalse);
      expect(viewModel.validationMessage, '配置已保存，但连接验证失败');
    });

    test('deleteProfile 应刷新剩余配置并回填编辑器', () async {
      final primary = _createProfile(
        id: 'primary',
        name: '主配置',
        model: 'deepseek-chat',
      );
      final backup = _createProfile(
        id: 'backup',
        name: '备用配置',
        model: 'gpt-4.1',
      );
      final service = _FakeAISettingsService(
        profiles: [primary, backup],
        activeProfileId: 'backup',
      );
      final viewModel = AISettingsViewModel(service: service);

      await viewModel.initialize();
      await viewModel.deleteProfile(backup);

      expect(service.deletedProfileIds, ['backup']);
      expect(viewModel.profiles.map((e) => e.id), ['primary']);
      expect(viewModel.activeProfileId, 'primary');
      expect(viewModel.editingProfileId, 'primary');
      expect(viewModel.profileNameController.text, '主配置');
      expect(viewModel.modelController.text, 'deepseek-chat');
      expect(viewModel.validationSuccess, isTrue);
      expect(viewModel.validationMessage, '已删除「备用配置」');
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
    createdAt: DateTime(2026, 4, 19, 9),
    updatedAt: DateTime(2026, 4, 19, 9),
  );
}
