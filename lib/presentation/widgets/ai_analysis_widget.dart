import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ai/service/ai_analysis_service.dart';
import '../../domain/divination_system.dart';

/// AI 分析组件
///
/// 用于在结果页面显示 AI 分析入口和结果。
/// 支持流式输出，实时显示分析内容。
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          _buildHeader(context, aiService),

          // 分析内容区域
          if (aiService.isAnalyzing || aiService.currentContent.isNotEmpty)
            _buildContentArea(context, aiService),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AIAnalysisService aiService) {
    final isConfigured = aiService.hasAvailableProvider;
    final isAnalyzing = aiService.isAnalyzing;

    return InkWell(
      onTap: isConfigured && !isAnalyzing
          ? () => _startAnalysis(context, aiService)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.smart_toy,
              color:
                  isConfigured ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 智能分析',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    isConfigured
                        ? (isAnalyzing ? '分析中...' : '点击开始 AI 分析')
                        : '请先在设置中配置 API Key',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (isAnalyzing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isConfigured)
              Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).primaryColor,
              )
            else
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, AIAnalysisService aiService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // 分析内容
          if (aiService.error != null)
            _buildErrorContent(context, aiService)
          else
            _buildAnalysisContent(context, aiService),

          // 操作按钮
          if (aiService.state == AnalysisState.completed ||
              aiService.error != null)
            _buildActionButtons(context, aiService),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(
      BuildContext context, AIAnalysisService aiService) {
    final content = aiService.currentContent;

    if (content.isEmpty && aiService.isAnalyzing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在分析卦象...'),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: SelectableText(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, AIAnalysisService aiService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              aiService.error ?? '分析失败',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AIAnalysisService aiService) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => aiService.clearResult(),
            icon: const Icon(Icons.clear),
            label: const Text('清除'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _startAnalysis(context, aiService),
            icon: const Icon(Icons.refresh),
            label: const Text('重新分析'),
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分析失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// AI 分析浮动按钮
///
/// 用于在结果页面右下角显示一个浮动按钮，
/// 点击后弹出底部抽屉显示分析结果。
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
    // 自动开始分析
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
            // 拖动指示器
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: Theme.of(context).primaryColor,
                  ),
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

            // 内容区域
            Expanded(
              child: _buildContent(context, aiService, scrollController),
            ),

            // 底部操作栏
            if (!aiService.isAnalyzing) _buildBottomBar(context, aiService),
          ],
        );
      },
    );
  }

  Widget _buildContent(
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '分析失败',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                aiService.error!,
                style: TextStyle(color: Colors.grey[600]),
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

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        aiService.currentContent,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.8,
            ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AIAnalysisService aiService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () {
              aiService.clearResult();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              aiService.analyze(
                widget.result,
                question: widget.question,
                useStreaming: true,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新分析'),
          ),
        ],
      ),
    );
  }
}
