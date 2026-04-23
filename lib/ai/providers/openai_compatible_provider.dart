/// OpenAI 兼容 LLM 提供者
///
/// 基于 openai_dart 包，支持所有 OpenAI 兼容接口：
/// - OpenAI、DeepSeek、通义千问、本地 Ollama 等
/// - 自定义 API 地址
/// - 动态获取模型列表
/// - 流式响应
library;

import 'dart:async';
import 'package:openai_dart/openai_dart.dart';
import '../llm_provider.dart';
import '../model/ai_chat_message.dart';

/// OpenAI 兼容配置
class OpenAICompatibleConfig implements LLMConfig {
  @override
  final String apiKey;

  @override
  final String? baseUrl;

  @override
  final String model;

  /// 温度参数（0.0 - 2.0）
  final double temperature;

  /// 最大输出 token 数
  final int maxOutputTokens;

  const OpenAICompatibleConfig({
    required this.apiKey,
    this.baseUrl,
    this.model = 'gpt-3.5-turbo',
    this.temperature = 0.7,
    this.maxOutputTokens = 4096,
  });

  factory OpenAICompatibleConfig.fromJson(Map<String, dynamic> json) {
    return OpenAICompatibleConfig(
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String? ?? 'gpt-3.5-turbo',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxOutputTokens: json['maxOutputTokens'] as int? ?? 4096,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'model': model,
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      };

  @override
  Map<String, dynamic> toSecureJson() {
    final json = toJson();
    json['apiKey'] = apiKey;
    return json;
  }

  OpenAICompatibleConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxOutputTokens,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
    );
  }
}

/// OpenAI 兼容 LLM 提供者
class OpenAICompatibleProvider implements LLMProvider {
  OpenAICompatibleConfig? _config;
  LLMProviderStatus _status = LLMProviderStatus.notConfigured;
  OpenAIClient? _client;

  /// 动态获取到的模型列表
  List<String> _fetchedModels = [];

  @override
  String get id => 'openai_compatible';

  @override
  String get displayName => 'OpenAI 兼容接口';

  @override
  String get description => '支持 OpenAI、DeepSeek、通义千问、Ollama 等兼容接口';

  @override
  List<String> get supportedModels =>
      _fetchedModels.isNotEmpty ? _fetchedModels : ['gpt-3.5-turbo'];

  @override
  String get defaultModel => 'gpt-3.5-turbo';

  @override
  bool get isConfigured => _config != null && _config!.apiKey.isNotEmpty;

  @override
  LLMProviderStatus get status => _status;

  void _ensureClient() {
    if (_config == null) return;
    _client = OpenAIClient(
      config: OpenAIConfig(
        authProvider: ApiKeyProvider(_config!.apiKey),
        baseUrl: _config!.baseUrl ?? 'https://api.openai.com/v1',
      ),
    );
  }

  @override
  void updateConfig(LLMConfig config) {
    if (config is OpenAICompatibleConfig) {
      _config = config;
      _status = config.apiKey.isNotEmpty
          ? LLMProviderStatus.configured
          : LLMProviderStatus.notConfigured;
      _ensureClient();
    } else {
      throw ArgumentError(
          'Expected OpenAICompatibleConfig, got ${config.runtimeType}');
    }
  }

  @override
  void clearConfig() {
    _config = null;
    _client = null;
    _status = LLMProviderStatus.notConfigured;
    _fetchedModels = [];
  }

  @override
  Map<String, dynamic>? getConfigInfo() {
    if (_config == null) return null;
    return {
      'model': _config!.model,
      'temperature': _config!.temperature,
      'maxOutputTokens': _config!.maxOutputTokens,
      'baseUrl': _config!.baseUrl,
    };
  }

  /// 从 API 获取可用模型列表
  Future<List<String>> fetchModels() async {
    if (_client == null) return [];

    try {
      final response = await _client!.models.list();
      final models = response.data.map((m) => m.id).toList();
      models.sort();
      _fetchedModels = models;
      return models;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> validateConfig() async {
    if (!isConfigured || _client == null) {
      _status = LLMProviderStatus.notConfigured;
      return false;
    }

    _status = LLMProviderStatus.validating;

    try {
      final models = await fetchModels();
      if (models.isNotEmpty) {
        _status = LLMProviderStatus.valid;
        return true;
      } else {
        _status = LLMProviderStatus.invalid;
        return false;
      }
    } catch (e) {
      _status = LLMProviderStatus.invalid;
      return false;
    }
  }

  @override
  Future<AnalysisResponse> analyze(AnalysisRequest request) async {
    final chatResponse = await chat(
      ChatRequest(
        messages: [
          ProviderChatMessage.system(request.systemPrompt),
          ProviderChatMessage.user(request.userPrompt),
        ],
      ),
    );
    return AnalysisResponse(
      content: chatResponse.content,
      tokensUsed: chatResponse.tokensUsed,
      latency: chatResponse.latency,
      model: chatResponse.model,
      providerId: chatResponse.providerId,
    );
  }

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    if (!isConfigured || _client == null) {
      throw StateError('请先在设置中配置 API');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client!.chat.completions.create(
        ChatCompletionCreateRequest(
          model: _config!.model,
          messages: request.messages.map(_toOpenAIMessage).toList(),
          temperature: request.temperature ?? _config!.temperature,
          maxCompletionTokens: request.maxTokens ?? _config!.maxOutputTokens,
        ),
      );

      stopwatch.stop();

      final content = response.choices.firstOrNull?.message.content ?? '';
      final tokensUsed = response.usage?.totalTokens ?? 0;

      return ChatResponse(
        content: content,
        tokensUsed: tokensUsed,
        latency: stopwatch.elapsed,
        model: _config!.model,
        providerId: id,
      );
    } catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  @override
  Stream<String>? analyzeStream(AnalysisRequest request) {
    return chatStream(
      ChatRequest(
        messages: [
          ProviderChatMessage.system(request.systemPrompt),
          ProviderChatMessage.user(request.userPrompt),
        ],
      ),
    );
  }

  @override
  Stream<String>? chatStream(ChatRequest request) {
    if (!isConfigured || _client == null) {
      throw StateError('请先在设置中配置 API');
    }

    return _chatStreamGenerate(request);
  }

  Stream<String> _chatStreamGenerate(ChatRequest request) async* {
    try {
      final stream = _client!.chat.completions.createStream(
        ChatCompletionCreateRequest(
          model: _config!.model,
          messages: request.messages.map(_toOpenAIMessage).toList(),
          temperature: request.temperature ?? _config!.temperature,
          maxCompletionTokens: request.maxTokens ?? _config!.maxOutputTokens,
        ),
      );

      await for (final event in stream) {
        final choices = event.choices;
        if (choices == null || choices.isEmpty) continue;
        final delta = choices.first.delta.content;
        if (delta != null && delta.isNotEmpty) {
          yield delta;
        }
      }
    } catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  ChatMessage _toOpenAIMessage(ProviderChatMessage m) {
    switch (m.role) {
      case ChatRole.system:
        return ChatMessage.system(m.content);
      case ChatRole.assistant:
        return ChatMessage.assistant(content: m.content);
      case ChatRole.user:
        return ChatMessage.user(m.content);
    }
  }

  /// 将 API 异常转为用户友好的中文提示
  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('resource_exhausted') || msg.contains('quota')) {
      return 'API 配额已用完，请稍后再试或更换其他服务商';
    }
    if (msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('invalid_api_key')) {
      return 'API Key 无效，请检查设置';
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      return '访问被拒绝，请检查 API Key 权限';
    }
    if (msg.contains('404') || msg.contains('not_found')) {
      return '模型不存在，请检查模型名称';
    }
    if (msg.contains('429') || msg.contains('rate_limit')) {
      return '请求过于频繁，请稍后再试';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return '请求超时，请检查网络连接';
    }
    if (msg.contains('socketexception') || msg.contains('connection')) {
      return '网络连接失败，请检查网络或 API 地址';
    }
    return '分析失败，请稍后重试';
  }
}
