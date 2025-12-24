/// LLM 提供者注册表
///
/// 管理所有已注册的 LLM 提供者，提供：
/// - 提供者注册和查询
/// - 默认提供者管理
/// - 提供者状态监控
library;

import 'llm_provider.dart';

/// LLM 提供者注册表
///
/// 使用单例模式管理所有 LLM 提供者。
class LLMProviderRegistry {
  static final LLMProviderRegistry _instance = LLMProviderRegistry._();
  static LLMProviderRegistry get instance => _instance;

  LLMProviderRegistry._();

  final Map<String, LLMProvider> _providers = {};
  String? _defaultProviderId;

  /// 注册提供者
  ///
  /// 如果是第一个注册的提供者，自动设置为默认提供者。
  void register(LLMProvider provider) {
    _providers[provider.id] = provider;
    _defaultProviderId ??= provider.id;
  }

  /// 注销提供者
  void unregister(String id) {
    _providers.remove(id);
    if (_defaultProviderId == id) {
      _defaultProviderId = _providers.keys.firstOrNull;
    }
  }

  /// 获取提供者
  LLMProvider? getProvider(String id) => _providers[id];

  /// 获取默认提供者
  LLMProvider? get defaultProvider =>
      _defaultProviderId != null ? _providers[_defaultProviderId] : null;

  /// 获取默认提供者 ID
  String? get defaultProviderId => _defaultProviderId;

  /// 设置默认提供者
  ///
  /// 抛出 [ArgumentError] 如果提供者不存在
  void setDefaultProvider(String id) {
    if (!_providers.containsKey(id)) {
      throw ArgumentError('Provider not found: $id');
    }
    _defaultProviderId = id;
  }

  /// 获取所有已注册的提供者
  List<LLMProvider> get providers => _providers.values.toList();

  /// 获取所有提供者 ID
  List<String> get providerIds => _providers.keys.toList();

  /// 获取已配置的提供者列表
  List<LLMProvider> get configuredProviders =>
      _providers.values.where((p) => p.isConfigured).toList();

  /// 获取可用的提供者列表（已配置且验证通过）
  List<LLMProvider> get availableProviders =>
      _providers.values.where((p) => p.status == LLMProviderStatus.valid).toList();

  /// 检查是否有可用的提供者
  bool get hasAvailableProvider => availableProviders.isNotEmpty;

  /// 检查是否有已配置的提供者
  bool get hasConfiguredProvider => configuredProviders.isNotEmpty;

  /// 获取所有提供者的信息（用于 UI 展示）
  List<LLMProviderInfo> getProvidersInfo() {
    return _providers.values.map((p) => LLMProviderInfo(
      id: p.id,
      displayName: p.displayName,
      description: p.description,
      isConfigured: p.isConfigured,
      status: p.status,
      supportedModels: p.supportedModels,
      currentModel: p.getConfigInfo()?['model'] as String?,
    )).toList();
  }

  /// 获取指定类型的第一个可用提供者
  ///
  /// 如果指定 ID 的提供者可用，返回该提供者；
  /// 否则返回默认提供者；
  /// 如果都不可用，返回 null。
  LLMProvider? getAvailableProvider([String? preferredId]) {
    if (preferredId != null) {
      final preferred = _providers[preferredId];
      if (preferred != null && preferred.isConfigured) {
        return preferred;
      }
    }

    final defaultProv = defaultProvider;
    if (defaultProv != null && defaultProv.isConfigured) {
      return defaultProv;
    }

    return configuredProviders.firstOrNull;
  }

  /// 清空所有注册
  void clear() {
    _providers.clear();
    _defaultProviderId = null;
  }
}
