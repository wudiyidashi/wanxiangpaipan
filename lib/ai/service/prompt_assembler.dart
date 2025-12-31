/// 提示词组装器
///
/// 将模板、结构化数据、用户输入组合成最终的提示词。
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../config/ai_config_manager.dart';
import '../output/structured_output.dart';
import '../output/structured_output_formatter.dart';
import '../template/template_engine.dart';
import '../template/builtin_templates.dart';
import '../llm_provider.dart';
import '../../domain/divination_system.dart';

part 'prompt_assembler.freezed.dart';

/// 组装后的提示词
@freezed
class AssembledPrompt with _$AssembledPrompt {
  const factory AssembledPrompt({
    /// 系统提示词
    required String systemPrompt,

    /// 用户提示词（包含结构化排盘数据）
    required String userPrompt,

    /// 结构化输出数据
    required StructuredDivinationOutput structuredOutput,

    /// 组装元数据
    required AssembledPromptMetadata metadata,
  }) = _AssembledPrompt;
}

/// 组装元数据
@freezed
class AssembledPromptMetadata with _$AssembledPromptMetadata {
  const factory AssembledPromptMetadata({
    /// 使用的系统模板 ID
    String? systemTemplateId,

    /// 使用的分析模板 ID
    String? analysisTemplateId,

    /// 组装时间
    required DateTime timestamp,

    /// 术数系统类型
    required String systemType,
  }) = _AssembledPromptMetadata;
}

/// 提示词组装器
///
/// 负责将排盘结果、用户问题、模板组合成完整的提示词。
class PromptAssembler {
  final AIConfigManager _configManager;
  final PromptTemplateEngine _engine;
  final StructuredOutputFormatterRegistry _formatterRegistry;

  PromptAssembler({
    required AIConfigManager configManager,
    required StructuredOutputFormatterRegistry formatterRegistry,
    PromptTemplateEngine? engine,
  })  : _configManager = configManager,
        _engine = engine ?? PromptTemplateEngine(),
        _formatterRegistry = formatterRegistry;

  /// 组装完整的提示词
  ///
  /// 参数：
  /// - [result]: 排盘结果
  /// - [question]: 用户问题（可选）
  /// - [analysisType]: 分析类型
  /// - [customVariables]: 自定义变量（可选）
  Future<AssembledPrompt> assemble(
    DivinationResult result, {
    String? question,
    AnalysisType analysisType = AnalysisType.comprehensive,
    Map<String, dynamic>? customVariables,
  }) async {
    // 1. 获取结构化输出
    final formatter = _formatterRegistry.getFormatter(result.systemType);
    final structuredOutput = formatter.format(result, question: question);
    final renderedOutput = formatter.render(structuredOutput);

    // 2. 获取活动模板
    final systemTemplate = await _configManager.getActiveTemplate(
      result.systemType.id,
      'system',
    );
    final analysisTemplate = await _configManager.getActiveTemplate(
      result.systemType.id,
      'analysis',
    );

    // 3. 构建上下文
    final context = _buildContext(
      structuredOutput: structuredOutput,
      renderedOutput: renderedOutput,
      question: question,
      analysisType: analysisType,
      customVariables: customVariables,
    );

    // 4. 渲染模板
    final systemPrompt = systemTemplate != null
        ? _engine.render(systemTemplate.content, context)
        : _getDefaultSystemPrompt(result.systemType);

    final userPrompt = analysisTemplate != null
        ? _engine.render(analysisTemplate.content, context)
        : _getDefaultUserPrompt(renderedOutput, question, analysisType);

    return AssembledPrompt(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      structuredOutput: structuredOutput,
      metadata: AssembledPromptMetadata(
        systemTemplateId: systemTemplate?.id,
        analysisTemplateId: analysisTemplate?.id,
        timestamp: DateTime.now(),
        systemType: result.systemType.id,
      ),
    );
  }

  Map<String, dynamic> _buildContext({
    required StructuredDivinationOutput structuredOutput,
    required String renderedOutput,
    String? question,
    required AnalysisType analysisType,
    Map<String, dynamic>? customVariables,
  }) {
    return {
      // 结构化输出
      'structuredOutput': renderedOutput,

      // 用户问题
      'question': question,
      'hasQuestion': question != null && question.isNotEmpty,

      // 核心数据
      ...structuredOutput.coreData,

      // 时间信息
      'temporal': {
        'yearGanZhi': structuredOutput.temporal.yearGanZhi,
        'monthGanZhi': structuredOutput.temporal.monthGanZhi,
        'dayGanZhi': structuredOutput.temporal.dayGanZhi,
        'kongWang': structuredOutput.temporal.kongWang,
      },

      // 分析类型
      'analysisType': analysisType.id,
      'isComprehensive': analysisType == AnalysisType.comprehensive,
      'isBrief': analysisType == AnalysisType.briefSummary,
      'includeAdvice': analysisType == AnalysisType.advice ||
          analysisType == AnalysisType.comprehensive,

      // 用户自定义变量
      ...?customVariables,
    };
  }

  String _getDefaultSystemPrompt(DivinationType type) {
    // 尝试获取内置模板
    final builtIn = BuiltInTemplates.getDefaultSystemPrompt(type.id);
    if (builtIn != null) {
      return builtIn.content;
    }

    // 回退到通用提示词
    return switch (type) {
      DivinationType.liuYao => '''
你是一位精通六爻占卜的易学专家。请根据提供的卦象信息进行专业解读。
分析时注意：
1. 首先判断卦象整体格局
2. 以用神为核心进行分析
3. 重点关注动爻变化
4. 考虑空亡、月建、日辰的影响
''',
      DivinationType.meiHua => '你是一位精通梅花易数的易学专家。',
      DivinationType.daLiuRen => '你是一位精通大六壬的易学专家。',
      DivinationType.xiaoLiuRen => '你是一位精通小六壬的易学专家。',
    };
  }

  String _getDefaultUserPrompt(
    String renderedOutput,
    String? question,
    AnalysisType analysisType,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('请根据以下排盘信息进行解读：');
    buffer.writeln();
    buffer.writeln(renderedOutput);

    if (question != null && question.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【求测问题】$question');
      buffer.writeln();
      buffer.writeln('请针对上述问题进行分析。');
    } else {
      buffer.writeln();
      buffer.writeln(switch (analysisType) {
        AnalysisType.comprehensive => '请对此卦进行全面、系统的解读。',
        AnalysisType.briefSummary => '请用简洁的语言概括此卦的核心含义。',
        AnalysisType.trend => '请分析此卦所示的发展趋势。',
        AnalysisType.advice => '请根据卦象给出具体的行动建议。',
        AnalysisType.specificQuestion => '请解读此卦。',
      });
    }

    return buffer.toString();
  }

  /// 预览组装效果（不保存）
  Future<AssembledPrompt> preview(
    DivinationResult result, {
    String? question,
    String? systemTemplateContent,
    String? analysisTemplateContent,
    Map<String, dynamic>? customVariables,
  }) async {
    // 获取结构化输出
    final formatter = _formatterRegistry.getFormatter(result.systemType);
    final structuredOutput = formatter.format(result, question: question);
    final renderedOutput = formatter.render(structuredOutput);

    // 构建上下文
    final context = _buildContext(
      structuredOutput: structuredOutput,
      renderedOutput: renderedOutput,
      question: question,
      analysisType: AnalysisType.comprehensive,
      customVariables: customVariables,
    );

    // 渲染模板
    final systemPrompt = systemTemplateContent != null
        ? _engine.render(systemTemplateContent, context)
        : _getDefaultSystemPrompt(result.systemType);

    final userPrompt = analysisTemplateContent != null
        ? _engine.render(analysisTemplateContent, context)
        : _getDefaultUserPrompt(
            renderedOutput, question, AnalysisType.comprehensive);

    return AssembledPrompt(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      structuredOutput: structuredOutput,
      metadata: AssembledPromptMetadata(
        timestamp: DateTime.now(),
        systemType: result.systemType.id,
      ),
    );
  }
}
