/// AI 分析服务
///
/// 对外暴露的统一接口，整合所有 AI 分析功能。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../config/ai_config_manager.dart';
import '../config/ai_provider_profile.dart';
import '../llm_provider.dart';
import '../llm_provider_registry.dart';
import '../model/ai_chat_message.dart';
import '../providers/openai_compatible_provider.dart';
import 'ai_conversation_service.dart';
import 'prompt_assembler.dart';
import '../../domain/divination_system.dart';

/// 分析状态
enum AnalysisState {
  idle,
  loading,
  streaming,
  completed,
  error,
}

/// AI 分析服务
///
/// 提供排盘结果的 AI 分析功能，支持：
/// - 多 LLM 提供者
/// - 流式输出
/// - 自定义模板
///
/// 当提供 [AIConversationService] 时，所有对话状态委托给它管理；
/// 否则回退到内部状态机（兼容旧的启动路径，待 Task 11 迁移后移除）。
class AIAnalysisService extends ChangeNotifier {
  final LLMProviderRegistry _providerRegistry;
  final PromptAssembler _promptAssembler;
  final AIConfigManager _configManager;
  final AIConversationService? _conversationService;

  // ---- legacy state (used only when _conversationService == null) ----
  AnalysisState _legacyState = AnalysisState.idle;
  String _legacyContent = '';
  String? _legacyError;
  StreamSubscription<String>? _streamSubscription;
  Completer<AnalysisResponse>? _pendingStreamCompleter;
  // --------------------------------------------------------------------

  AnalysisResponse? _lastResponse;
  String? _currentResultId;

  AIAnalysisService({
    required LLMProviderRegistry providerRegistry,
    required PromptAssembler promptAssembler,
    required AIConfigManager configManager,
    AIConversationService? conversationService,
  })  : _providerRegistry = providerRegistry,
        _promptAssembler = promptAssembler,
        _configManager = configManager,
        _conversationService = conversationService {
    _conversationService?.addListener(_onConversationChanged);
  }

  void _onConversationChanged() {
    notifyListeners();
  }

  // ==================== 状态访问器 ====================

  /// 当前状态
  AnalysisState get state {
    final cs = _conversationService;
    if (cs == null) return _legacyState;
    if (_currentResultId == null) return _legacyState;
    final conv = cs.conversationOf(_currentResultId!);
    if (conv == null) return AnalysisState.idle;
    final firstStatus = conv.messages.isEmpty
        ? ChatMessageStatus.sent
        : conv.messages.first.status;
    switch (firstStatus) {
      case ChatMessageStatus.streaming:
        return AnalysisState.streaming;
      case ChatMessageStatus.sending:
        return AnalysisState.loading;
      case ChatMessageStatus.failed:
        return AnalysisState.error;
      case ChatMessageStatus.sent:
        return AnalysisState.completed;
    }
  }

  /// 是否正在分析
  bool get isAnalyzing =>
      state == AnalysisState.loading || state == AnalysisState.streaming;

  /// 当前分析内容
  String get currentContent {
    final cs = _conversationService;
    if (cs == null) return _legacyContent;
    if (_currentResultId == null) return '';
    final conv = cs.conversationOf(_currentResultId!);
    if (conv == null || conv.messages.isEmpty) return '';
    return conv.messages.first.content;
  }

  /// 错误信息
  String? get error {
    final cs = _conversationService;
    if (cs == null) return _legacyError;
    if (_currentResultId == null) return null;
    return cs.errorOf(_currentResultId!);
  }

  /// 最后一次响应
  AnalysisResponse? get lastResponse => _lastResponse;

  /// 当前分析对应的排盘记录 ID
  String? get currentResultId => _currentResultId;

  // ==================== 分析方法 ====================

  /// 分析排盘结果
  ///
  /// 参数：
  /// - [result]: 排盘结果
  /// - [question]: 用户问题（可选）
  /// - [providerId]: 指定提供者 ID（可选，默认使用默认提供者）
  /// - [analysisType]: 分析类型
  /// - [useStreaming]: 是否使用流式输出
  /// - [customVariables]: 自定义变量
  Future<AnalysisResponse> analyze(
    DivinationResult result, {
    String? question,
    String? providerId,
    AnalysisType analysisType = AnalysisType.comprehensive,
    bool? useStreaming,
    Map<String, dynamic>? customVariables,
  }) async {
    final cs = _conversationService;
    if (cs != null) {
      return _analyzeViaConversationService(cs, result, question: question);
    }
    return _analyzeLegacy(
      result,
      question: question,
      providerId: providerId,
      analysisType: analysisType,
      useStreaming: useStreaming,
      customVariables: customVariables,
    );
  }

  Future<AnalysisResponse> _analyzeViaConversationService(
    AIConversationService cs,
    DivinationResult result, {
    String? question,
  }) async {
    _currentResultId = result.id;
    _legacyState = AnalysisState.loading;
    notifyListeners();

    await cs.startConversation(result, question: question);

    final conv = cs.conversationOf(result.id);
    final errMsg = cs.errorOf(result.id);
    if (errMsg != null || conv == null || conv.messages.isEmpty) {
      throw Exception(errMsg ?? '对话启动失败');
    }

    final first = conv.messages.first;
    final providerInfo = _providerRegistry.getAvailableProvider();
    final resp = AnalysisResponse(
      content: first.content,
      tokensUsed: 0,
      latency: Duration.zero,
      model: (providerInfo?.getConfigInfo()?['model'] as String?) ?? '',
      providerId: providerInfo?.id ?? '',
    );
    _lastResponse = resp;
    return resp;
  }

  // ---- Legacy path (used when conversationService is null) ----

  Future<AnalysisResponse> _analyzeLegacy(
    DivinationResult result, {
    String? question,
    String? providerId,
    AnalysisType analysisType = AnalysisType.comprehensive,
    bool? useStreaming,
    Map<String, dynamic>? customVariables,
  }) async {
    await _cancelActiveStreamIfNeeded();

    _currentResultId = result.id;
    _legacyState = AnalysisState.loading;
    _legacyContent = '';
    _legacyError = null;
    notifyListeners();

    try {
      final provider = _getProvider(providerId);
      if (provider == null || !provider.isConfigured) {
        throw StateError('没有可用的 AI 服务，请先配置 API');
      }

      final prompt = await _promptAssembler.assemble(
        result,
        question: question,
        analysisType: analysisType,
        customVariables: customVariables,
      );

      final request = AnalysisRequest(
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.userPrompt,
        result: result,
        userQuestion: question,
        analysisType: analysisType,
      );

      final shouldStream =
          useStreaming ?? await _configManager.isStreamingEnabled();

      if (shouldStream) {
        return await _analyzeWithStream(provider, request);
      } else {
        return await _analyzeSync(provider, request);
      }
    } catch (e) {
      _legacyState = AnalysisState.error;
      _legacyError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<AnalysisResponse> _analyzeSync(
    LLMProvider provider,
    AnalysisRequest request,
  ) async {
    final response = await provider.analyze(request);
    _legacyContent = response.content;
    _lastResponse = response;
    _legacyState = AnalysisState.completed;
    notifyListeners();
    return response;
  }

  Future<AnalysisResponse> _analyzeWithStream(
    LLMProvider provider,
    AnalysisRequest request,
  ) async {
    final stream = provider.analyzeStream(request);
    if (stream == null) {
      return _analyzeSync(provider, request);
    }

    _legacyState = AnalysisState.streaming;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();
    final completer = Completer<AnalysisResponse>();
    _pendingStreamCompleter = completer;

    _streamSubscription = stream.listen(
      (chunk) {
        buffer.write(chunk);
        _legacyContent = buffer.toString();
        _safeNotify();
      },
      onDone: () {
        stopwatch.stop();
        final configModel = provider.getConfigInfo()?['model'];
        final response = AnalysisResponse(
          content: buffer.toString(),
          tokensUsed: 0,
          latency: stopwatch.elapsed,
          model: configModel is String ? configModel : '',
          providerId: provider.id,
        );
        _lastResponse = response;
        _legacyState = AnalysisState.completed;
        _pendingStreamCompleter = null;
        _streamSubscription = null;
        notifyListeners();
        completer.complete(response);
      },
      onError: (Object error) {
        stopwatch.stop();
        _legacyState = AnalysisState.error;
        _legacyError = error.toString();
        _pendingStreamCompleter = null;
        _streamSubscription = null;
        notifyListeners();
        completer.completeError(error);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  // ---- End legacy path ----

  /// 取消当前分析
  Future<void> cancelAnalysis() async {
    final cs = _conversationService;
    if (cs != null) {
      final id = _currentResultId;
      if (id != null) {
        await cs.stop(id);
      }
    } else {
      await _cancelActiveStreamIfNeeded();
      if (isAnalyzing) {
        _legacyState = AnalysisState.idle;
        notifyListeners();
      }
    }
  }

  /// 清除当前结果
  void clearResult() {
    _currentResultId = null;
    _lastResponse = null;
    _legacyState = AnalysisState.idle;
    _legacyContent = '';
    _legacyError = null;
    notifyListeners();
  }

  // ==================== Provider 管理 ====================

  void _safeNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  LLMProvider? _getProvider(String? providerId) {
    if (providerId != null) {
      return _providerRegistry.getProvider(providerId);
    }
    return _providerRegistry.getAvailableProvider();
  }

  /// 获取所有提供者信息
  List<LLMProviderInfo> getProvidersInfo() {
    return _providerRegistry.getProvidersInfo();
  }

  /// 检查是否有可用的提供者
  bool get hasAvailableProvider => _providerRegistry.hasConfiguredProvider;

  /// 获取默认提供者
  LLMProvider? get defaultProvider => _providerRegistry.defaultProvider;

  /// 获取所有命名配置
  Future<List<AIProviderProfile>> getProviderProfiles() {
    return _configManager.getProviderProfiles();
  }

  /// 获取当前激活配置
  Future<AIProviderProfile?> getActiveProviderProfile() {
    return _configManager.getActiveProviderProfile();
  }

  /// 保存命名配置
  Future<void> saveProviderProfile(
    AIProviderProfile profile, {
    bool activate = true,
  }) async {
    await _configManager.saveProviderProfile(profile);

    final activeId = await _configManager.getActiveProviderProfileId();
    if (activate || activeId == null) {
      await activateProviderProfile(profile.id);
    } else {
      notifyListeners();
    }
  }

  /// 激活命名配置
  Future<void> activateProviderProfile(String profileId) async {
    final profile = await _configManager.getProviderProfile(profileId);
    if (profile == null) {
      throw StateError('未找到指定 AI 配置');
    }

    await _applyProviderProfile(profile);
    await _configManager.setActiveProviderProfileId(profile.id);
    await _configManager.setDefaultProviderId(profile.providerId);
    _providerRegistry.setDefaultProvider(profile.providerId);
    notifyListeners();
  }

  /// 删除命名配置
  Future<void> deleteProviderProfile(String profileId) async {
    final activeId = await _configManager.getActiveProviderProfileId();
    await _configManager.deleteProviderProfile(profileId);

    final nextActive = await _configManager.getActiveProviderProfile();
    if (activeId == profileId) {
      if (nextActive != null) {
        await _applyProviderProfile(nextActive);
        await _configManager.setDefaultProviderId(nextActive.providerId);
        _providerRegistry.setDefaultProvider(nextActive.providerId);
      } else {
        final provider = _providerRegistry.getProvider('openai_compatible');
        provider?.clearConfig();
      }
    }

    notifyListeners();
  }

  Future<int> clearAllProviderProfiles() async {
    final count = await _configManager.getProviderProfileCount();
    await _configManager.clearAllProviderProfiles();
    final provider = _providerRegistry.getProvider('openai_compatible');
    provider?.clearConfig();
    notifyListeners();
    return count;
  }

  Future<void> syncActiveProviderProfile() async {
    final activeProfile = await _configManager.getActiveProviderProfile();
    if (activeProfile != null) {
      await _applyProviderProfile(activeProfile);
      await _configManager.setDefaultProviderId(activeProfile.providerId);
      _providerRegistry.setDefaultProvider(activeProfile.providerId);
    } else {
      final provider = _providerRegistry.getProvider('openai_compatible');
      provider?.clearConfig();
    }
    notifyListeners();
  }

  Future<void> _applyProviderProfile(AIProviderProfile profile) async {
    final provider = _providerRegistry.getProvider(profile.providerId);
    if (provider is OpenAICompatibleProvider) {
      provider.updateConfig(
        OpenAICompatibleConfig(
          apiKey: profile.apiKey,
          baseUrl: profile.baseUrl,
          model: profile.model,
          temperature: profile.temperature,
          maxOutputTokens: profile.maxOutputTokens,
        ),
      );
      return;
    }

    throw UnsupportedError('暂不支持的 AI 提供者: ${profile.providerId}');
  }

  /// 配置提供者
  Future<void> configureProvider({
    required String providerId,
    required String apiKey,
    required Map<String, dynamic> config,
  }) async {
    final now = DateTime.now();
    final profile = AIProviderProfile(
      id: '${providerId}_default',
      providerId: providerId,
      name: '默认配置',
      apiKey: apiKey,
      baseUrl: config['baseUrl'] as String?,
      model: config['model'] as String? ?? 'gpt-3.5-turbo',
      temperature: (config['temperature'] as num?)?.toDouble() ?? 0.7,
      maxOutputTokens: config['maxOutputTokens'] as int? ?? 4096,
      createdAt: now,
      updatedAt: now,
    );
    await saveProviderProfile(profile, activate: true);
  }

  /// 验证提供者配置
  Future<bool> validateProvider(String providerId) async {
    final provider = _providerRegistry.getProvider(providerId);
    if (provider == null) return false;
    return await provider.validateConfig();
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    _conversationService?.removeListener(_onConversationChanged);
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cancelActiveStreamIfNeeded() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    final completer = _pendingStreamCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(StateError('分析已取消'));
    }
    _pendingStreamCompleter = null;
  }
}
