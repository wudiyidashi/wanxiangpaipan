import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../ai/config/ai_provider_profile.dart';
import '../../../ai/providers/openai_compatible_provider.dart';
import '../../../ai/service/ai_analysis_service.dart';

abstract class AISettingsService {
  Future<List<AIProviderProfile>> getProviderProfiles();
  Future<AIProviderProfile?> getActiveProviderProfile();
  Future<void> saveProviderProfile(
    AIProviderProfile profile, {
    bool activate = true,
  });
  Future<void> activateProviderProfile(String profileId);
  Future<void> deleteProviderProfile(String profileId);
  Future<bool> validateProvider(String providerId);
}

class AIAnalysisSettingsService implements AISettingsService {
  AIAnalysisSettingsService(this._analysisService);

  final AIAnalysisService _analysisService;

  @override
  Future<void> activateProviderProfile(String profileId) {
    return _analysisService.activateProviderProfile(profileId);
  }

  @override
  Future<void> deleteProviderProfile(String profileId) {
    return _analysisService.deleteProviderProfile(profileId);
  }

  @override
  Future<AIProviderProfile?> getActiveProviderProfile() {
    return _analysisService.getActiveProviderProfile();
  }

  @override
  Future<List<AIProviderProfile>> getProviderProfiles() {
    return _analysisService.getProviderProfiles();
  }

  @override
  Future<void> saveProviderProfile(
    AIProviderProfile profile, {
    bool activate = true,
  }) {
    return _analysisService.saveProviderProfile(profile, activate: activate);
  }

  @override
  Future<bool> validateProvider(String providerId) {
    return _analysisService.validateProvider(providerId);
  }
}

typedef AIModelFetcher = Future<List<String>> Function(
  OpenAICompatibleConfig config,
);

class AISettingsViewModel extends ChangeNotifier {
  AISettingsViewModel({
    required AISettingsService? service,
    AIModelFetcher? modelFetcher,
  })  : _service = service,
        _modelFetcher = modelFetcher ?? _defaultModelFetcher;

  final AISettingsService? _service;
  final AIModelFetcher _modelFetcher;

  final profileNameController = TextEditingController();
  final apiKeyController = TextEditingController();
  final baseUrlController = TextEditingController();
  final modelController = TextEditingController();

  final List<AIProviderProfile> _profiles = [];
  final List<String> _availableModels = [];

  String? _activeProfileId;
  String? _editingProfileId;
  bool _isSaving = false;
  bool _isFetchingModels = false;
  bool _obscureApiKey = true;
  bool _profilesLoaded = false;
  bool _initialized = false;
  bool _disposed = false;
  String? _validationMessage;
  bool? _validationSuccess;

  bool get serviceAvailable => _service != null;
  UnmodifiableListView<AIProviderProfile> get profiles =>
      UnmodifiableListView(_profiles);
  UnmodifiableListView<String> get availableModels =>
      UnmodifiableListView(_availableModels);
  String? get activeProfileId => _activeProfileId;
  String? get editingProfileId => _editingProfileId;
  bool get isSaving => _isSaving;
  bool get isFetchingModels => _isFetchingModels;
  bool get obscureApiKey => _obscureApiKey;
  bool get profilesLoaded => _profilesLoaded;
  String? get validationMessage => _validationMessage;
  bool? get validationSuccess => _validationSuccess;

  String? get selectedAvailableModel {
    final current = modelController.text.trim();
    if (current.isEmpty || !_availableModels.contains(current)) {
      return _availableModels.isEmpty ? null : _availableModels.first;
    }
    return current;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _loadProfiles();
  }

  Future<void> reloadProfiles() => _loadProfiles(preserveValidation: true);

  void startCreatingProfile() {
    _prepareNewProfile();
    _notify();
  }

  void applyPreset({
    required String name,
    required String baseUrl,
  }) {
    if (profileNameController.text.trim().isEmpty) {
      profileNameController.text = '$name 配置';
    }
    baseUrlController.text = baseUrl;
    _notify();
  }

  void toggleObscureApiKey() {
    _obscureApiKey = !_obscureApiKey;
    _notify();
  }

  void selectAvailableModel(String model) {
    modelController.text = model;
    _notify();
  }

  Future<void> fetchModels() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _setValidation('请先输入 API Key', success: false);
      return;
    }

    _isFetchingModels = true;
    _clearValidation();
    _notify();

    try {
      final config = OpenAICompatibleConfig(
        apiKey: apiKey,
        baseUrl: _normalizedBaseUrl,
        model: modelController.text.trim().isEmpty
            ? 'gpt-3.5-turbo'
            : modelController.text.trim(),
      );
      final models = await _modelFetcher(config);
      if (_disposed) {
        return;
      }

      _availableModels
        ..clear()
        ..addAll(models);
      if (models.isNotEmpty && modelController.text.trim().isEmpty) {
        modelController.text = models.first;
      }
      _validationSuccess = models.isNotEmpty;
      _validationMessage = models.isNotEmpty
          ? '获取到 ${models.length} 个模型'
          : '未获取到模型，请检查 API 地址和 Key';
    } catch (e) {
      if (_disposed) {
        return;
      }
      _setValidation('获取模型失败: $e', success: false, notify: false);
    } finally {
      _isFetchingModels = false;
      _notify();
    }
  }

  Future<void> saveCurrentProfile() async {
    final name = profileNameController.text.trim();
    final apiKey = apiKeyController.text.trim();
    final model = modelController.text.trim();

    if (name.isEmpty) {
      _setValidation('请输入配置名称', success: false);
      return;
    }
    if (apiKey.isEmpty) {
      _setValidation('请输入 API Key', success: false);
      return;
    }
    if (model.isEmpty) {
      _setValidation('请输入模型名称', success: false);
      return;
    }

    final service = _service;
    if (service == null) {
      _setValidation('AI 服务尚未初始化完成', success: false);
      return;
    }

    _isSaving = true;
    _clearValidation();
    _notify();

    try {
      final existing = _findProfile(_editingProfileId);
      final now = DateTime.now();
      final profile = AIProviderProfile(
        id: existing?.id ?? 'profile_${now.microsecondsSinceEpoch}',
        providerId: 'openai_compatible',
        name: name,
        apiKey: apiKey,
        baseUrl: _normalizedBaseUrl,
        model: model,
        temperature: existing?.temperature ?? 0.7,
        maxOutputTokens: existing?.maxOutputTokens ?? 4096,
        isEnabled: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await service.saveProviderProfile(profile, activate: true);
      final isValid = await service.validateProvider(profile.providerId);
      if (_disposed) {
        return;
      }

      _editingProfileId = profile.id;
      _activeProfileId = profile.id;
      _validationSuccess = isValid;
      _validationMessage = isValid ? '配置保存成功，已切换到当前接口' : '配置已保存，但连接验证失败';
      await _loadProfiles(preserveValidation: true);
    } catch (e) {
      if (_disposed) {
        return;
      }
      _setValidation('保存失败: $e', success: false, notify: false);
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  Future<void> activateProfile(AIProviderProfile profile) async {
    final service = _service;
    if (service == null) {
      _setValidation('AI 服务尚未初始化完成', success: false);
      return;
    }

    _isSaving = true;
    _clearValidation();
    _notify();

    try {
      await service.activateProviderProfile(profile.id);
      if (_disposed) {
        return;
      }
      _activeProfileId = profile.id;
      _editingProfileId = profile.id;
      _loadProfileIntoEditor(profile, clearValidation: false);
      _setValidation('已切换到「${profile.name}」', success: true, notify: false);
    } catch (e) {
      if (_disposed) {
        return;
      }
      _setValidation('切换失败: $e', success: false, notify: false);
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  Future<void> deleteProfile(AIProviderProfile profile) async {
    final service = _service;
    if (service == null) {
      _setValidation('AI 服务尚未初始化完成', success: false);
      return;
    }

    _isSaving = true;
    _clearValidation();
    _notify();

    try {
      await service.deleteProviderProfile(profile.id);
      if (_disposed) {
        return;
      }
      await _loadProfiles(preserveValidation: true);
      _setValidation('已删除「${profile.name}」', success: true, notify: false);
    } catch (e) {
      if (_disposed) {
        return;
      }
      _setValidation('删除失败: $e', success: false, notify: false);
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  AIProviderProfile? _findProfile(String? profileId) {
    if (profileId == null) {
      return null;
    }
    for (final profile in _profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  String? get _normalizedBaseUrl {
    final baseUrl = baseUrlController.text.trim();
    return baseUrl.isEmpty ? null : baseUrl;
  }

  Future<void> _loadProfiles({
    bool preserveValidation = false,
  }) async {
    final service = _service;
    if (service == null) {
      _profilesLoaded = true;
      _prepareNewProfile(clearValidation: !preserveValidation);
      _notify();
      return;
    }

    final profiles = await service.getProviderProfiles();
    final activeProfile = await service.getActiveProviderProfile();
    if (_disposed) {
      return;
    }

    _profilesLoaded = true;
    _profiles
      ..clear()
      ..addAll(profiles);
    _activeProfileId = activeProfile?.id;

    final profileToEdit =
        activeProfile ?? (profiles.isNotEmpty ? profiles.first : null);
    if (profileToEdit != null) {
      _loadProfileIntoEditor(
        profileToEdit,
        clearValidation: !preserveValidation,
      );
    } else {
      _prepareNewProfile(clearValidation: !preserveValidation);
    }
    _notify();
  }

  void _prepareNewProfile({
    bool clearValidation = true,
  }) {
    profileNameController.text = '';
    apiKeyController.text = '';
    baseUrlController.text = '';
    modelController.text = 'gpt-3.5-turbo';
    _availableModels.clear();
    _editingProfileId = null;
    if (clearValidation) {
      _clearValidation();
    }
  }

  void _loadProfileIntoEditor(
    AIProviderProfile profile, {
    bool clearValidation = true,
  }) {
    _editingProfileId = profile.id;
    profileNameController.text = profile.name;
    apiKeyController.text = profile.apiKey;
    baseUrlController.text = profile.baseUrl ?? '';
    modelController.text = profile.model;
    _availableModels
      ..clear()
      ..add(profile.model);
    if (clearValidation) {
      _clearValidation();
    }
  }

  void _clearValidation() {
    _validationMessage = null;
    _validationSuccess = null;
  }

  void _setValidation(
    String message, {
    required bool success,
    bool notify = true,
  }) {
    _validationMessage = message;
    _validationSuccess = success;
    if (notify) {
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  static Future<List<String>> _defaultModelFetcher(
    OpenAICompatibleConfig config,
  ) async {
    final provider = OpenAICompatibleProvider();
    provider.updateConfig(config);
    return provider.fetchModels();
  }

  @override
  void dispose() {
    _disposed = true;
    profileNameController.dispose();
    apiKeyController.dispose();
    baseUrlController.dispose();
    modelController.dispose();
    super.dispose();
  }
}
