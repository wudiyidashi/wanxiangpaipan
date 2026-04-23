/// LLM 提供者抽象接口
///
/// 本文件定义了 AI 分析底座的核心抽象，包括：
/// - [LLMConfig]: 提供者配置抽象基类
/// - [AnalysisRequest]: 分析请求
/// - [AnalysisResponse]: 分析响应
/// - [LLMProvider]: 提供者抽象接口
///
/// 设计原则：
/// 1. 策略模式 - 支持多种 LLM 提供者（Gemini, OpenAI, Claude 等）
/// 2. 配置与实现分离 - 配置数据独立于业务逻辑
/// 3. 流式支持 - 可选的流式响应能力
library;

import '../domain/divination_system.dart';

/// 分析类型枚举
enum AnalysisType {
  comprehensive('综合解读', 'comprehensive'),
  briefSummary('简要摘要', 'brief'),
  specificQuestion('针对问题', 'specific'),
  trend('趋势预测', 'trend'),
  advice('行动建议', 'advice');

  const AnalysisType(this.displayName, this.id);
  final String displayName;
  final String id;

  static AnalysisType fromId(String id) {
    return AnalysisType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => AnalysisType.comprehensive,
    );
  }
}

/// LLM 提供者配置抽象基类
abstract class LLMConfig {
  /// API 密钥
  String get apiKey;

  /// 自定义 API 地址（用于代理或私有部署）
  String? get baseUrl;

  /// 使用的模型
  String get model;

  /// 序列化为 JSON（不包含敏感信息）
  Map<String, dynamic> toJson();

  /// 序列化为 JSON（包含敏感信息，仅用于安全存储）
  Map<String, dynamic> toSecureJson() {
    final json = toJson();
    json['apiKey'] = apiKey;
    return json;
  }
}

/// 分析请求
class AnalysisRequest {
  /// 系统提示词
  final String systemPrompt;

  /// 用户提示词（包含结构化排盘数据）
  final String userPrompt;

  /// 原始排盘结果（用于元数据）
  final DivinationResult result;

  /// 用户问题（可选）
  final String? userQuestion;

  /// 分析类型
  final AnalysisType analysisType;

  const AnalysisRequest({
    required this.systemPrompt,
    required this.userPrompt,
    required this.result,
    this.userQuestion,
    this.analysisType = AnalysisType.comprehensive,
  });
}

/// 分析响应
class AnalysisResponse {
  /// 分析内容
  final String content;

  /// 使用的 token 数量
  final int tokensUsed;

  /// 响应延迟
  final Duration latency;

  /// 使用的模型
  final String model;

  /// 提供者 ID
  final String providerId;

  const AnalysisResponse({
    required this.content,
    required this.tokensUsed,
    required this.latency,
    required this.model,
    required this.providerId,
  });
}

/// LLM 提供者状态
enum LLMProviderStatus {
  notConfigured('未配置'),
  configured('已配置'),
  validating('验证中'),
  valid('可用'),
  invalid('不可用');

  const LLMProviderStatus(this.displayName);
  final String displayName;
}

/// LLM 提供者抽象接口
///
/// 所有 LLM 提供者（Gemini, OpenAI, Claude 等）都必须实现此接口。
abstract class LLMProvider {
  /// 提供者唯一标识符
  String get id;

  /// 显示名称
  String get displayName;

  /// 提供者描述
  String get description;

  /// 支持的模型列表
  List<String> get supportedModels;

  /// 默认模型
  String get defaultModel;

  /// 是否已配置
  bool get isConfigured;

  /// 当前状态
  LLMProviderStatus get status;

  /// 执行分析
  ///
  /// 参数：
  /// - [request]: 分析请求，包含系统提示词和用户提示词
  ///
  /// 返回：
  /// 返回分析响应，包含分析内容和元数据
  ///
  /// 异常：
  /// - [StateError]: 如果提供者未配置
  /// - [Exception]: 如果 API 调用失败
  Future<AnalysisResponse> analyze(AnalysisRequest request);

  /// 流式分析（可选实现）
  ///
  /// 返回 null 表示不支持流式分析
  Stream<String>? analyzeStream(AnalysisRequest request) => null;

  /// 多轮对话（非流式）
  ///
  /// 异常：
  /// - [StateError]: 如果提供者未配置
  /// - [Exception]: 如果 API 调用失败
  Future<ChatResponse> chat(ChatRequest request);

  /// 流式多轮对话（可选实现）
  ///
  /// 返回 null 表示不支持流式
  Stream<String>? chatStream(ChatRequest request) => null;

  /// 验证配置是否有效
  ///
  /// 返回 true 表示配置有效，API 可用
  Future<bool> validateConfig();

  /// 更新配置
  ///
  /// 参数：
  /// - [config]: 新的配置
  void updateConfig(LLMConfig config);

  /// 清除配置
  void clearConfig();

  /// 获取当前配置（不含敏感信息）
  Map<String, dynamic>? getConfigInfo();
}

/// LLM 提供者信息（用于 UI 展示）
class LLMProviderInfo {
  final String id;
  final String displayName;
  final String description;
  final bool isConfigured;
  final LLMProviderStatus status;
  final List<String> supportedModels;
  final String? currentModel;

  const LLMProviderInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.isConfigured,
    required this.status,
    required this.supportedModels,
    this.currentModel,
  });
}

/// Provider 侧的聊天消息（独立于 UI 层的 AIChatMessage，避免循环依赖）
class ProviderChatMessage {
  final String role; // 'system' / 'user' / 'assistant'
  final String content;

  const ProviderChatMessage({required this.role, required this.content});

  const ProviderChatMessage.system(this.content) : role = 'system';
  const ProviderChatMessage.user(this.content) : role = 'user';
  const ProviderChatMessage.assistant(this.content) : role = 'assistant';
}

/// 多轮对话请求
class ChatRequest {
  final List<ProviderChatMessage> messages;
  final double? temperature;
  final int? maxTokens;

  const ChatRequest({
    required this.messages,
    this.temperature,
    this.maxTokens,
  });
}

/// 多轮对话响应
class ChatResponse {
  final String content;
  final int tokensUsed;
  final Duration latency;
  final String model;
  final String providerId;

  const ChatResponse({
    required this.content,
    required this.tokensUsed,
    required this.latency,
    required this.model,
    required this.providerId,
  });
}
