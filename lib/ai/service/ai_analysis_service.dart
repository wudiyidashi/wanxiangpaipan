/// AI 分析服务
///
/// 对外暴露的统一接口，整合所有 AI 分析功能。
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/ai_config_manager.dart';
import '../llm_provider.dart';
import '../llm_provider_registry.dart';
import '../providers/gemini_provider.dart';
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
class AIAnalysisService extends ChangeNotifier {
  final LLMProviderRegistry _providerRegistry;
  final PromptAssembler _promptAssembler;
  final AIConfigManager _configManager;

  AnalysisState _state = AnalysisState.idle;
  String _currentContent = '';
  String? _error;
  AnalysisResponse? _lastResponse;
  StreamSubscription<String>? _streamSubscription;

  AIAnalysisService({
    required LLMProviderRegistry providerRegistry,
    required PromptAssembler promptAssembler,
    required AIConfigManager configManager,
  })  : _providerRegistry = providerRegistry,
        _promptAssembler = promptAssembler,
        _configManager = configManager;

  // ==================== 状态访问器 ====================

  /// 当前状态
  AnalysisState get state => _state;

  /// 是否正在分析
  bool get isAnalyzing =>
      _state == AnalysisState.loading || _state == AnalysisState.streaming;

  /// 当前分析内容
  String get currentContent => _currentContent;

  /// 错误信息
  String? get error => _error;

  /// 最后一次响应
  AnalysisResponse? get lastResponse => _lastResponse;

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
    _state = AnalysisState.loading;
    _currentContent = '';
    _error = null;
    notifyListeners();

    try {
      // 1. 获取 Provider
      final provider = _getProvider(providerId);
      if (provider == null || !provider.isConfigured) {
        throw StateError('没有可用的 AI 服务，请先配置 API');
      }

      // 2. 组装 Prompt
      final prompt = await _promptAssembler.assemble(
        result,
        question: question,
        analysisType: analysisType,
        customVariables: customVariables,
      );

      // 3. 创建请求
      final request = AnalysisRequest(
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.userPrompt,
        result: result,
        userQuestion: question,
        analysisType: analysisType,
      );

      // 4. 判断是否使用流式
      final shouldStream = useStreaming ??
          await _configManager.isStreamingEnabled();

      if (shouldStream) {
        return await _analyzeWithStream(provider, request);
      } else {
        return await _analyzeSync(provider, request);
      }
    } catch (e) {
      _state = AnalysisState.error;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<AnalysisResponse> _analyzeSync(
    LLMProvider provider,
    AnalysisRequest request,
  ) async {
    final response = await provider.analyze(request);

    _currentContent = response.content;
    _lastResponse = response;
    _state = AnalysisState.completed;
    notifyListeners();

    return response;
  }

  Future<AnalysisResponse> _analyzeWithStream(
    LLMProvider provider,
    AnalysisRequest request,
  ) async {
    final stream = provider.analyzeStream(request);
    if (stream == null) {
      // 提供者不支持流式，回退到同步
      return _analyzeSync(provider, request);
    }

    _state = AnalysisState.streaming;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();
    final completer = Completer<AnalysisResponse>();

    _streamSubscription = stream.listen(
      (chunk) {
        buffer.write(chunk);
        _currentContent = buffer.toString();
        notifyListeners();
      },
      onDone: () {
        stopwatch.stop();
        final configModel = provider.getConfigInfo()?['model'];
        final response = AnalysisResponse(
          content: buffer.toString(),
          tokensUsed: 0, // 流式模式无法获取准确的 token 数
          latency: stopwatch.elapsed,
          model: configModel is String ? configModel : '',
          providerId: provider.id,
        );

        _lastResponse = response;
        _state = AnalysisState.completed;
        notifyListeners();

        completer.complete(response);
      },
      onError: (Object error) {
        stopwatch.stop();
        _state = AnalysisState.error;
        _error = error.toString();
        notifyListeners();

        completer.completeError(error);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// 取消当前分析
  void cancelAnalysis() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    if (isAnalyzing) {
      _state = AnalysisState.idle;
      notifyListeners();
    }
  }

  /// 清除当前结果
  void clearResult() {
    _currentContent = '';
    _error = null;
    _lastResponse = null;
    _state = AnalysisState.idle;
    notifyListeners();
  }

  // ==================== Provider 管理 ====================

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

  /// 配置提供者
  Future<void> configureProvider({
    required String providerId,
    required String apiKey,
    required Map<String, dynamic> config,
  }) async {
    // 保存到配置管理器
    await _configManager.saveProviderConfig(
      providerId: providerId,
      apiKey: apiKey,
      config: config,
    );

    // 更新提供者配置
    final provider = _providerRegistry.getProvider(providerId);
    if (provider != null) {
      final fullConfig = Map<String, dynamic>.from(config);
      fullConfig['apiKey'] = apiKey;

      if (provider is GeminiProvider) {
        provider.updateConfig(GeminiConfig.fromJson(fullConfig));
      }
      // 未来添加其他提供者...
    }

    // 设置为默认提供者（如果是第一个配置的）
    final defaultId = await _configManager.getDefaultProviderId();
    if (defaultId == null) {
      await _configManager.setDefaultProviderId(providerId);
      _providerRegistry.setDefaultProvider(providerId);
    }

    notifyListeners();
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
    _streamSubscription?.cancel();
    super.dispose();
  }
}
