/// AI 模块初始化引导
///
/// 负责初始化 AI 分析模块的所有组件。
library;

import 'config/ai_config_manager.dart';
import 'llm_provider_registry.dart';
import 'output/structured_output_formatter.dart';
import 'output/formatters/liuyao_formatter.dart';
import 'output/formatters/daliuren_formatter.dart';
import 'providers/gemini_provider.dart';
import 'service/prompt_assembler.dart';
import 'service/ai_analysis_service.dart';
import '../data/database/app_database.dart';
import '../data/secure/secure_storage.dart';
import '../domain/divination_system.dart';

/// AI 模块初始化引导
///
/// 使用方式：
/// ```dart
/// final aiService = await AIBootstrap.initialize(
///   database: appDatabase,
///   secureStorage: secureStorage,
/// );
/// ```
class AIBootstrap {
  AIBootstrap._();

  static AIConfigManager? _configManager;
  static AIAnalysisService? _analysisService;
  static bool _initialized = false;

  /// 是否已初始化
  static bool get isInitialized => _initialized;

  /// 获取配置管理器
  static AIConfigManager get configManager {
    if (_configManager == null) {
      throw StateError('AI module not initialized. Call AIBootstrap.initialize() first.');
    }
    return _configManager!;
  }

  /// 获取分析服务
  static AIAnalysisService get analysisService {
    if (_analysisService == null) {
      throw StateError('AI module not initialized. Call AIBootstrap.initialize() first.');
    }
    return _analysisService!;
  }

  /// 初始化 AI 模块
  ///
  /// 参数：
  /// - [database]: 应用数据库实例
  /// - [secureStorage]: 加密存储实例
  ///
  /// 返回初始化好的 [AIAnalysisService]
  static Future<AIAnalysisService> initialize({
    required AppDatabase database,
    required SecureStorage secureStorage,
  }) async {
    if (_initialized) {
      return _analysisService!;
    }

    // 1. 创建配置管理器
    _configManager = AIConfigManager(
      database: database,
      secureStorage: secureStorage,
    );

    // 2. 初始化内置模板
    await _configManager!.initializeBuiltInTemplates();

    // 3. 注册结构化输出格式化器
    _registerFormatters();

    // 4. 注册 LLM 提供者
    await _registerProviders();

    // 5. 加载已保存的提供者配置
    await _loadSavedConfigs();

    // 6. 创建提示词组装器
    final promptAssembler = PromptAssembler(
      configManager: _configManager!,
      formatterRegistry: StructuredOutputFormatterRegistry.instance,
    );

    // 7. 创建分析服务
    _analysisService = AIAnalysisService(
      providerRegistry: LLMProviderRegistry.instance,
      promptAssembler: promptAssembler,
      configManager: _configManager!,
    );

    _initialized = true;
    return _analysisService!;
  }

  /// 注册结构化输出格式化器
  static void _registerFormatters() {
    final registry = StructuredOutputFormatterRegistry.instance;

    // 六爻格式化器
    registry.register(LiuYaoStructuredFormatter());

    // 大六壬格式化器
    registry.register(DaLiuRenStructuredFormatter());

    // 未来添加其他系统的格式化器...
  }

  /// 注册 LLM 提供者
  static Future<void> _registerProviders() async {
    final registry = LLMProviderRegistry.instance;

    // Gemini 提供者
    registry.register(GeminiProvider());

    // 未来添加其他提供者...
    // registry.register(OpenAIProvider());
    // registry.register(ClaudeProvider());
    // registry.register(DeepSeekProvider());
  }

  /// 加载已保存的提供者配置
  static Future<void> _loadSavedConfigs() async {
    final registry = LLMProviderRegistry.instance;

    // 加载 Gemini 配置
    final geminiConfig = await _configManager!.loadProviderConfig('gemini');
    if (geminiConfig != null) {
      final provider = registry.getProvider('gemini');
      if (provider is GeminiProvider) {
        provider.updateConfig(GeminiConfig.fromJson(geminiConfig));
      }
    }

    // 加载默认提供者设置
    final defaultProviderId = await _configManager!.getDefaultProviderId();
    if (defaultProviderId != null && registry.getProvider(defaultProviderId) != null) {
      registry.setDefaultProvider(defaultProviderId);
    }

    // 未来加载其他提供者配置...
  }

  /// 重置 AI 模块（用于测试）
  static void reset() {
    _configManager = null;
    _analysisService?.dispose();
    _analysisService = null;
    _initialized = false;

    LLMProviderRegistry.instance.clear();
    StructuredOutputFormatterRegistry.instance.clear();
  }
}

/// AI 模块的 Provider 封装
///
/// 用于在 Flutter 应用中通过 Provider 访问 AI 服务。
///
/// 使用示例：
/// ```dart
/// MultiProvider(
///   providers: [
///     ChangeNotifierProvider(create: (_) => AIBootstrap.analysisService),
///   ],
///   child: MyApp(),
/// )
/// ```
extension AIProviderExtension on AIAnalysisService {
  /// 检查指定术数系统是否支持 AI 分析
  bool isSystemSupported(DivinationType type) {
    return StructuredOutputFormatterRegistry.instance.hasFormatter(type);
  }

  /// 获取支持 AI 分析的术数系统列表
  List<DivinationType> get supportedSystems {
    return StructuredOutputFormatterRegistry.instance.registeredTypes;
  }
}
