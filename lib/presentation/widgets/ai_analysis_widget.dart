import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../ai/service/ai_analysis_service.dart';
import '../../ai/service/ai_conversation_service.dart';
import '../../ai/ai_bootstrap.dart';
import '../../ai/service/prompt_assembler.dart';
import '../../ai/output/structured_output_formatter.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/divination_system.dart';
import 'ai_chat_sheet.dart';
import 'ai_snapshot_version_text.dart';

/// AI 分析组件
///
/// 内容直接展开，随外部页面一起滚动，无内部滚动。
class AIAnalysisWidget extends StatefulWidget {
  final DivinationResult result;
  final String? question;
  final String? unavailableReason;

  const AIAnalysisWidget({
    super.key,
    required this.result,
    this.question,
    this.unavailableReason,
  });

  @override
  State<AIAnalysisWidget> createState() => _AIAnalysisWidgetState();
}

class _AIAnalysisWidgetState extends State<AIAnalysisWidget> {
  String _persistedContent = '';
  String? _loadedResultId;
  bool _isLoadingPersistedContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersistedAnalysis(force: true);
    });
  }

  @override
  void didUpdateWidget(covariant AIAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.id != widget.result.id) {
      _persistedContent = '';
      _loadedResultId = null;
      _loadPersistedAnalysis(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();
    final conversationService = context.watch<AIConversationService?>();
    final conversation = conversationService?.conversationOf(widget.result.id);
    final unavailableReason = _resolveUnavailableReason(aiService);

    if (unavailableReason != null) {
      return _buildUnavailableState(context, unavailableReason);
    }

    final readyService = aiService!;
    final isCurrentResult = readyService.currentResultId == widget.result.id;
    final isAnalyzing = isCurrentResult && readyService.isAnalyzing;
    final error = isCurrentResult ? readyService.error : null;
    final content =
        isCurrentResult ? readyService.currentContent : _persistedContent;
    final hasContent = content.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            context,
            readyService,
            isAnalyzing: isAnalyzing,
            hasContent: hasContent,
            snapshotVersionText: conversation == null
                ? null
                : aiSnapshotVersionText(
                    systemType: conversation.systemType,
                    snapshot: conversation.castSnapshot,
                  ),
          ),
          if (isAnalyzing ||
              hasContent ||
              error != null ||
              _isLoadingPersistedContent)
            _buildContent(
              context,
              readyService,
              isCurrentResult: isCurrentResult,
              isAnalyzing: isAnalyzing,
              content: content,
              error: error,
            ),
        ],
      ),
    );
  }

  String? _resolveUnavailableReason(AIAnalysisService? aiService) {
    final callerReason = widget.unavailableReason?.trim();
    if (callerReason != null && callerReason.isNotEmpty) {
      return callerReason;
    }
    if (aiService == null) {
      return 'AI 分析服务正在初始化或暂不可用，本地排盘与规则分析不受影响。';
    }
    if (!StructuredOutputFormatterRegistry.instance
        .hasFormatter(widget.result.systemType)) {
      return '当前术数的 AI 数据格式化组件未就绪。为避免发送不完整排盘，'
          'AI 分析已暂停，本地结果仍可正常查看。';
    }
    return null;
  }

  Widget _buildUnavailableState(BuildContext context, String reason) =>
      Semantics(
        container: true,
        label: 'AI 分析暂不可用：$reason',
        child: Card(
          key: const ValueKey('ai-analysis-unavailable'),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 智能分析暂不可用',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reason,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeader(
    BuildContext context,
    AIAnalysisService aiService, {
    required bool isAnalyzing,
    required bool hasContent,
    required String? snapshotVersionText,
  }) {
    final isConfigured = aiService.hasAvailableProvider;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 智能分析',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (snapshotVersionText != null)
                  Text(
                    snapshotVersionText,
                    key: const ValueKey('liuyao-ai-snapshot-version'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          // 复制按钮
          if (isConfigured && !isAnalyzing)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              tooltip: '复制发送内容',
              onPressed: () => _copyPrompt(context),
              visualDensity: VisualDensity.compact,
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
              onPressed: () => _startOrRestart(context, aiService),
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

  Widget _buildContent(
    BuildContext context,
    AIAnalysisService aiService, {
    required bool isCurrentResult,
    required bool isAnalyzing,
    required String content,
    required String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),

          if (_isLoadingPersistedContent && !isAnalyzing && content.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('正在加载已保存的分析内容...')),
            )
          else if (error != null)
            _buildError(context, error)
          else if (content.isEmpty && isAnalyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('正在分析卦象...')),
            )
          else
            // Markdown 渲染，无内部滚动
            MarkdownBody(
              data: content,
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

          // 继续追问入口
          if (!isAnalyzing && error == null && content.isNotEmpty)
            Builder(builder: (context) {
              final convService = context.watch<AIConversationService?>();
              final conv = convService?.conversationOf(widget.result.id);
              final followUpCount = (conv?.messages.length ?? 1) - 1;
              final label =
                  followUpCount > 0 ? '继续对话 · $followUpCount 条' : '继续追问';
              return Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openChatSheet(context),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(
                    label,
                    style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
                  ),
                ),
              );
            }),

          // 清除按钮
          if (!isAnalyzing && error == null && content.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _clearAnalysisFull(context),
                icon: const Icon(Icons.clear, size: 16),
                label: Text('清除',
                    style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
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
    final unavailableReason = _resolveUnavailableReason(aiService);
    if (unavailableReason != null) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final response = await aiService.analyze(
        widget.result,
        question: widget.question,
        useStreaming: true,
      );
      final content = response.content.trim();
      if (!mounted) {
        return;
      }
      setState(() {
        _persistedContent = content;
        _loadedResultId = widget.result.id;
      });
    } catch (_) {
      // 错误已在 service 中处理
    }
  }

  void _openChatSheet(BuildContext context) {
    final convService = context.read<AIConversationService>();
    // 确保先载入（支持老数据恢复）
    convService.loadIfNeeded(widget.result.id,
        legacySystemType: widget.result.systemType);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChangeNotifierProvider<AIConversationService>.value(
        value: convService,
        child: AIChatSheet(
          resultId: widget.result.id,
          fallbackResult: widget.result,
        ),
      ),
    );
  }

  Future<void> _startOrRestart(
      BuildContext context, AIAnalysisService aiService) async {
    final unavailableReason = _resolveUnavailableReason(aiService);
    if (unavailableReason != null) {
      if (mounted) setState(() {});
      return;
    }
    final convService = context.read<AIConversationService>();
    final conv = convService.conversationOf(widget.result.id);
    if (conv != null && conv.messages.length > 1) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('重新分析'),
          content: const Text('重新分析会清空当前对话的所有追问内容。确定吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await convService.delete(widget.result.id);
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    await _startAnalysis(context, aiService);
  }

  Future<void> _clearAnalysisFull(BuildContext context) async {
    final convService = context.read<AIConversationService>();
    await convService.delete(widget.result.id);
    if (!mounted) return;
    setState(() {
      _persistedContent = '';
      _loadedResultId = widget.result.id;
    });
  }

  Future<String> _assemblePromptPreview() async {
    final callerReason = widget.unavailableReason?.trim();
    if (callerReason != null && callerReason.isNotEmpty) {
      return '无法生成预览: $callerReason';
    }
    if (!StructuredOutputFormatterRegistry.instance
        .hasFormatter(widget.result.systemType)) {
      return '无法生成预览: 当前术数的 AI 数据格式化组件未就绪';
    }
    try {
      final assembler = PromptAssembler(
        configManager: AIBootstrap.configManager,
        formatterRegistry: StructuredOutputFormatterRegistry.instance,
      );
      final prompt =
          await assembler.assemble(widget.result, question: widget.question);
      return '--- 系统提示词 ---\n${prompt.systemPrompt}\n\n--- 用户提示词 ---\n${prompt.userPrompt}';
    } catch (e) {
      return '无法生成预览: $e';
    }
  }

  Future<void> _copyPrompt(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final content = await _assemblePromptPreview();
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('已复制发送内容到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showPreview(BuildContext context) async {
    final previewContent = await _assemblePromptPreview();

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

  Future<void> _loadPersistedAnalysis({required bool force}) async {
    if (!force && _loadedResultId == widget.result.id) {
      return;
    }

    final convService = _tryReadConversationService();
    if (convService == null) {
      if (!mounted) return;
      setState(() {
        _persistedContent = '';
        _loadedResultId = widget.result.id;
        _isLoadingPersistedContent = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingPersistedContent = true;
      });
    }

    final resultId = widget.result.id;
    // 读新 conversation_<id>；ChatRepository 内部会在只有旧 interpretation_<id> 时
    // 回退构造一个单条 assistant 消息的 legacy 对话。
    final conv = await convService.loadIfNeeded(
      resultId,
      legacySystemType: widget.result.systemType,
    );

    if (!mounted || widget.result.id != resultId) {
      return;
    }

    final content = (conv != null && conv.messages.isNotEmpty)
        ? conv.messages.first.content.trim()
        : '';

    setState(() {
      _persistedContent = content;
      _loadedResultId = resultId;
      _isLoadingPersistedContent = false;
    });
  }

  AIConversationService? _tryReadConversationService() {
    try {
      return context.read<AIConversationService>();
    } catch (_) {
      return null;
    }
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
    final hasFormatter = StructuredOutputFormatterRegistry.instance
        .hasFormatter(result.systemType);

    if (aiService == null || !aiService.hasAvailableProvider || !hasFormatter) {
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
    final convService = context.read<AIConversationService>();
    convService.loadIfNeeded(result.id, legacySystemType: result.systemType);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          ChangeNotifierProvider<AIConversationService>.value(
        value: convService,
        child: AIChatSheet(
          resultId: result.id,
          fallbackResult: result,
        ),
      ),
    );
  }
}
