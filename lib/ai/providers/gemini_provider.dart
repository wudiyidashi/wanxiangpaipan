/// Gemini LLM 提供者
///
/// 实现 Google Gemini API 的调用，支持：
/// - 多模型选择（gemini-1.5-flash, gemini-1.5-pro, gemini-2.0-flash）
/// - 流式响应
/// - 自定义 API 地址（用于代理）
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../llm_provider.dart';

/// Gemini 配置
class GeminiConfig implements LLMConfig {
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

  /// Top-P 参数
  final double topP;

  /// Top-K 参数
  final int topK;

  const GeminiConfig({
    required this.apiKey,
    this.baseUrl,
    this.model = 'gemini-1.5-flash',
    this.temperature = 0.7,
    this.maxOutputTokens = 4096,
    this.topP = 0.95,
    this.topK = 40,
  });

  factory GeminiConfig.fromJson(Map<String, dynamic> json) {
    return GeminiConfig(
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String? ?? 'gemini-1.5-flash',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxOutputTokens: json['maxOutputTokens'] as int? ?? 4096,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.95,
      topK: json['topK'] as int? ?? 40,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'model': model,
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        'topP': topP,
        'topK': topK,
      };

  @override
  Map<String, dynamic> toSecureJson() {
    final Map<String, dynamic> json = toJson();
    json['apiKey'] = apiKey;
    return json;
  }

  GeminiConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxOutputTokens,
    double? topP,
    int? topK,
  }) {
    return GeminiConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
    );
  }
}

/// Gemini LLM 提供者
class GeminiProvider implements LLMProvider {
  GeminiConfig? _config;
  LLMProviderStatus _status = LLMProviderStatus.notConfigured;
  final http.Client _client;

  /// 默认 API 地址
  static const _defaultBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'gemini';

  @override
  String get displayName => 'Google Gemini';

  @override
  String get description => 'Google 的 Gemini AI 模型，支持多模态理解和生成';

  @override
  List<String> get supportedModels => [
        'gemini-2.0-flash-exp',
        'gemini-1.5-flash',
        'gemini-1.5-flash-8b',
        'gemini-1.5-pro',
      ];

  @override
  String get defaultModel => 'gemini-1.5-flash';

  @override
  bool get isConfigured => _config != null && _config!.apiKey.isNotEmpty;

  @override
  LLMProviderStatus get status => _status;

  String get _baseUrl => _config?.baseUrl ?? _defaultBaseUrl;

  @override
  void updateConfig(LLMConfig config) {
    if (config is GeminiConfig) {
      _config = config;
      _status = config.apiKey.isNotEmpty
          ? LLMProviderStatus.configured
          : LLMProviderStatus.notConfigured;
    } else {
      throw ArgumentError('Expected GeminiConfig, got ${config.runtimeType}');
    }
  }

  @override
  void clearConfig() {
    _config = null;
    _status = LLMProviderStatus.notConfigured;
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

  @override
  Future<bool> validateConfig() async {
    if (!isConfigured) {
      _status = LLMProviderStatus.notConfigured;
      return false;
    }

    _status = LLMProviderStatus.validating;

    try {
      final url = Uri.parse('$_baseUrl/models?key=${_config!.apiKey}');
      final response = await _client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('连接超时'),
      );

      if (response.statusCode == 200) {
        _status = LLMProviderStatus.valid;
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _status = LLMProviderStatus.invalid;
        return false;
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
    if (!isConfigured) {
      throw StateError('Gemini provider not configured');
    }

    final stopwatch = Stopwatch()..start();

    final url = Uri.parse(
      '$_baseUrl/models/${_config!.model}:generateContent?key=${_config!.apiKey}',
    );

    final body = _buildRequestBody(request);

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    stopwatch.stop();

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw Exception('Gemini API error: $error');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseResponse(data, stopwatch.elapsed);
  }

  @override
  Stream<String>? analyzeStream(AnalysisRequest request) {
    if (!isConfigured) {
      throw StateError('Gemini provider not configured');
    }

    return _streamGenerate(request);
  }

  Stream<String> _streamGenerate(AnalysisRequest request) async* {
    final url = Uri.parse(
      '$_baseUrl/models/${_config!.model}:streamGenerateContent?key=${_config!.apiKey}',
    );

    final body = _buildRequestBody(request);

    final httpRequest = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    final streamedResponse = await _client.send(httpRequest);

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      final error = _parseError(body);
      throw Exception('Gemini API error: $error');
    }

    // Gemini 流式响应格式处理
    final buffer = StringBuffer();
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer.write(chunk);

      // 尝试解析完整的 JSON 对象
      final content = buffer.toString();

      // Gemini 流式响应是 JSON 数组格式
      if (content.startsWith('[')) {
        // 移除开头的 [ 和可能的逗号
        var jsonStr = content.trimLeft();
        if (jsonStr.startsWith('[')) {
          jsonStr = jsonStr.substring(1);
        }

        // 尝试解析每个 JSON 对象
        final parts = jsonStr.split('\n');
        for (final part in parts) {
          var trimmed = part.trim();
          if (trimmed.isEmpty) continue;

          // 移除开头的逗号
          if (trimmed.startsWith(',')) {
            trimmed = trimmed.substring(1).trim();
          }
          // 移除结尾的 ]
          if (trimmed.endsWith(']')) {
            trimmed = trimmed.substring(0, trimmed.length - 1).trim();
          }

          if (trimmed.isEmpty) continue;

          try {
            final data = jsonDecode(trimmed) as Map<String, dynamic>;
            final text = _extractText(data);
            if (text != null && text.isNotEmpty) {
              yield text;
              buffer.clear();
            }
          } catch (e) {
            // 继续累积直到有完整的 JSON
          }
        }
      }
    }
  }

  Map<String, dynamic> _buildRequestBody(AnalysisRequest request) {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '${request.systemPrompt}\n\n${request.userPrompt}'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': _config!.temperature,
        'maxOutputTokens': _config!.maxOutputTokens,
        'topP': _config!.topP,
        'topK': _config!.topK,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE'
        },
      ],
    };
  }

  AnalysisResponse _parseResponse(Map<String, dynamic> data, Duration latency) {
    final text = _extractText(data) ?? '';
    final tokensUsed = _extractTokenCount(data);

    return AnalysisResponse(
      content: text,
      tokensUsed: tokensUsed,
      latency: latency,
      model: _config!.model,
      providerId: id,
    );
  }

  String? _extractText(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      return parts[0]['text'] as String?;
    } catch (e) {
      return null;
    }
  }

  int _extractTokenCount(Map<String, dynamic> data) {
    try {
      final usageMetadata = data['usageMetadata'] as Map<String, dynamic>?;
      if (usageMetadata == null) return 0;

      final totalTokens = usageMetadata['totalTokenCount'];
      return totalTokens is int ? totalTokens : 0;
    } catch (e) {
      return 0;
    }
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      if (error != null) {
        return error['message'] as String? ?? 'Unknown error';
      }
      return body;
    } catch (e) {
      return body;
    }
  }
}
