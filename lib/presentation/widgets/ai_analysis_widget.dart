import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../ai/service/ai_analysis_service.dart';
import '../../ai/ai_bootstrap.dart';
import '../../ai/service/prompt_assembler.dart';
import '../../ai/output/structured_output_formatter.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/divination_system.dart';

/// AI 分析组件
///
/// 内容直接展开，随外部页面一起滚动，无内部滚动。
class AIAnalysisWidget extends StatelessWidget {
  final DivinationResult result;
  final String? question;

  const AIAnalysisWidget({
    super.key,
    required this.result,
    this.question,
  });

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();

    if (aiService == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, aiService),
          if (aiService.isAnalyzing ||
              aiService.currentContent.isNotEmpty ||
              aiService.error != null)
            _buildContent(context, aiService),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AIAnalysisService aiService) {
    final isConfigured = aiService.hasAvailableProvider;
    final isAnalyzing = aiService.isAnalyzing;
    final hasContent = aiService.currentContent.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy,
            size: 20,
            color: isConfigured
                ? Theme.of(context).primaryColor
                : Colors.grey, // Material grey: unconfigured/disabled state
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI 智能分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // 预览按钮
          if (isConfigured && !isAnalyzing)
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 20),
              tooltip: '预览发送内容',
              onPressed: () => _showPreview(context),
              visualDensity: VisualDensity.compact,
            ),
          // 重新分析 / 开始分析
          if (isConfigured && !isAnalyzing)
            IconButton(
              icon: Icon(
                hasContent ? Icons.refresh : Icons.play_circle_outline,
                size: 20,
              ),
              tooltip: hasContent ? '重新分析' : '开始分析',
              onPressed: () => _startAnalysis(context, aiService),
              visualDensity: VisualDensity.compact,
            ),
          // 加载指示器
          if (isAnalyzing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          // 未配置 → 设置
          if (!isConfigured)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/ai-settings'),
              child: Text('去配置',
                  style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AIAnalysisService aiService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),

          if (aiService.error != null)
            _buildError(context, aiService)
          else if (aiService.currentContent.isEmpty && aiService.isAnalyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('正在分析卦象...')),
            )
          else
            // Markdown 渲染，无内部滚动
            MarkdownBody(
              data: aiService.currentContent,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.8),
                h1: AppTextStyles.antiqueTitle.copyWith(height: 2),
                h2: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height:
                        2), // 16pt bold heading: between antiqueTitle(18) and antiqueSection(15)
                h3: AppTextStyles.antiqueSection.copyWith(height: 2),
                listBullet: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.8),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.grey.withOpacity(
                      0.08), // Material grey: markdown blockquote bg tint
                  border: Border(
                      left: BorderSide(
                          color: Colors.grey.shade400,
                          width:
                              3)), // Material grey: markdown blockquote left border
                ),
              ),
            ),

          // 清除按钮
          if (aiService.state == AnalysisState.completed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => aiService.clearResult(),
                icon: const Icon(Icons.clear, size: 16),
                label: Text('清除',
                    style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, AIAnalysisService aiService) {
    final error = aiService.error ?? '分析失败';
    final message = error.replaceFirst(RegExp(r'^Exception:\s*'), '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(
            0.08), // domain: error/warning tint (no token equivalent)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                Colors.orange.withOpacity(0.3)), // domain: error/warning border
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Colors.orange, size: 18), // domain: warning icon
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.antiqueBody.copyWith(
                  color:
                      Colors.grey[800]), // Material grey[800]: error body text
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startAnalysis(
      BuildContext context, AIAnalysisService aiService) async {
    try {
      await aiService.analyze(
        result,
        question: question,
        useStreaming: true,
      );
    } catch (_) {
      // 错误已在 service 中处理
    }
  }

  Future<void> _showPreview(BuildContext context) async {
    String previewContent;
    try {
      final assembler = PromptAssembler(
        configManager: AIBootstrap.configManager,
        formatterRegistry: StructuredOutputFormatterRegistry.instance,
      );
      final prompt = await assembler.assemble(result, question: question);
      previewContent =
          '--- 系统提示词 ---\n${prompt.systemPrompt}\n\n--- 用户提示词 ---\n${prompt.userPrompt}';
    } catch (e) {
      previewContent = '无法生成预览: $e';
    }

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300], // Material grey[300]: drag handle pill
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '发送内容预览',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight
                              .bold), // 16pt bold heading: between antiqueTitle(18) and antiqueSection(15)
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  previewContent,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily:
                        'monospace', // monospace: prompt preview code display
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI 分析浮动按钮
class AIAnalysisFAB extends StatelessWidget {
  final DivinationResult result;
  final String? question;

  const AIAnalysisFAB({
    super.key,
    required this.result,
    this.question,
  });

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();

    if (aiService == null || !aiService.hasAvailableProvider) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _showAnalysisSheet(context, aiService),
      icon: aiService.isAnalyzing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.smart_toy),
      label: Text(aiService.isAnalyzing ? '分析中...' : 'AI 分析'),
    );
  }

  void _showAnalysisSheet(BuildContext context, AIAnalysisService aiService) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: aiService,
          child: _AIAnalysisSheet(
            result: result,
            question: question,
          ),
        );
      },
    );
  }
}

/// AI 分析底部抽屉
class _AIAnalysisSheet extends StatefulWidget {
  final DivinationResult result;
  final String? question;

  const _AIAnalysisSheet({
    required this.result,
    this.question,
  });

  @override
  State<_AIAnalysisSheet> createState() => _AIAnalysisSheetState();
}

class _AIAnalysisSheetState extends State<_AIAnalysisSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysisIfNeeded();
    });
  }

  void _startAnalysisIfNeeded() {
    final aiService = context.read<AIAnalysisService>();
    if (!aiService.isAnalyzing && aiService.currentContent.isEmpty) {
      aiService.analyze(
        widget.result,
        question: widget.question,
        useStreaming: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIAnalysisService>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300], // Material grey[300]: drag handle pill
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI 智能分析',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (aiService.isAnalyzing)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildSheetContent(context, aiService, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheetContent(
    BuildContext context,
    AIAnalysisService aiService,
    ScrollController scrollController,
  ) {
    if (aiService.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  size: 48, color: Colors.orange), // domain: warning icon
              const SizedBox(height: 16),
              Text(
                aiService.error!.replaceFirst(RegExp(r'^Exception:\s*'), ''),
                style: AppTextStyles.antiqueBody.copyWith(
                    color: Colors
                        .grey[700]), // Material grey[700]: muted error text
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (aiService.currentContent.isEmpty && aiService.isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('正在分析卦象，请稍候...'),
          ],
        ),
      );
    }

    return Markdown(
      data: aiService.currentContent,
      controller: scrollController,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8),
        h3: AppTextStyles.antiqueSection.copyWith(height: 2),
      ),
    );
  }
}
