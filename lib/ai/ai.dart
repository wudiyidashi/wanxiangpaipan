/// AI 分析模块
///
/// 提供排盘结果的 AI 分析功能，支持：
/// - 多 LLM 提供者（Gemini, OpenAI, Claude 等）
/// - 结构化排盘数据输出
/// - 用户可配置提示词模板
/// - 流式响应
///
/// 使用示例：
/// ```dart
/// // 初始化
/// await AIBootstrap.initialize(
///   database: appDatabase,
///   secureStorage: secureStorage,
/// );
///
/// // 配置提供者
/// await AIBootstrap.analysisService.configureProvider(
///   providerId: 'gemini',
///   apiKey: 'your-api-key',
///   config: {'model': 'gemini-1.5-flash'},
/// );
///
/// // 分析排盘结果
/// final response = await AIBootstrap.analysisService.analyze(
///   liuYaoResult,
///   question: '今日求财是否顺利？',
/// );
/// ```
library ai;

// 核心接口
export 'llm_provider.dart';
export 'llm_provider_registry.dart';

// 配置管理
export 'config/ai_config_manager.dart';

// 结构化输出
export 'output/structured_output.dart';
export 'output/structured_output_formatter.dart';
export 'output/formatters/liuyao_formatter.dart';

// 模板系统
export 'template/prompt_template.dart';
export 'template/template_engine.dart';
export 'template/builtin_templates.dart';

// 提供者实现
export 'providers/gemini_provider.dart';

// 服务层
export 'service/prompt_assembler.dart';
export 'service/ai_analysis_service.dart';

// 初始化引导
export 'ai_bootstrap.dart';
