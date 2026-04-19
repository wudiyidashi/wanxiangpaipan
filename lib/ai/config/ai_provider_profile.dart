library;

/// 命名 AI 接口配置。
///
/// 当前主要承载 OpenAI 兼容接口的不同 endpoint / model / key 组合，
/// 例如：
/// - OpenAI GPT-4.1
/// - DeepSeek Chat
/// - 本地 Ollama
class AIProviderProfile {
  final String id;
  final String providerId;
  final String name;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final double temperature;
  final int maxOutputTokens;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIProviderProfile({
    required this.id,
    required this.providerId,
    required this.name,
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.temperature = 0.7,
    this.maxOutputTokens = 4096,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIProviderProfile.fromJson(
    Map<String, dynamic> json, {
    String apiKey = '',
  }) {
    return AIProviderProfile(
      id: json['id'] as String,
      providerId: json['providerId'] as String? ?? 'openai_compatible',
      name: json['name'] as String? ?? '未命名配置',
      apiKey: apiKey,
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String? ?? 'gpt-3.5-turbo',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxOutputTokens: json['maxOutputTokens'] as int? ?? 4096,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeApiKey = false}) {
    final json = <String, dynamic>{
      'id': id,
      'providerId': providerId,
      'name': name,
      'baseUrl': baseUrl,
      'model': model,
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (includeApiKey) {
      json['apiKey'] = apiKey;
    }
    return json;
  }

  AIProviderProfile copyWith({
    String? id,
    String? providerId,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxOutputTokens,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBaseUrl = false,
  }) {
    return AIProviderProfile(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: clearBaseUrl ? null : (baseUrl ?? this.baseUrl),
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
