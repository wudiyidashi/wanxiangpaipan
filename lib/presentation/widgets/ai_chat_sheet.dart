import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../ai/model/ai_chat_message.dart';
import '../../ai/model/ai_conversation.dart';
import '../../ai/service/ai_conversation_service.dart';
import '../../ai/service/chat_request_builder.dart';
import '../../domain/divination_system.dart';
import 'ai_chat_bubble.dart';
import 'ai_chat_input_bar.dart';

class AIChatSheet extends StatefulWidget {
  final String resultId;
  final DivinationResult? fallbackResult;

  const AIChatSheet({
    super.key,
    required this.resultId,
    this.fallbackResult,
  });

  @override
  State<AIChatSheet> createState() => _AIChatSheetState();
}

class _AIChatSheetState extends State<AIChatSheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _systemLabel(DivinationType type) {
    switch (type) {
      case DivinationType.liuYao:
        return '六爻';
      case DivinationType.daLiuRen:
        return '大六壬';
      case DivinationType.xiaoLiuRen:
        return '小六壬';
      case DivinationType.meiHua:
        return '梅花易数';
    }
  }

  String _roleLabel(ChatRole role) {
    switch (role) {
      case ChatRole.system:
        return 'system';
      case ChatRole.user:
        return 'user';
      case ChatRole.assistant:
        return 'assistant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AIConversationService>();
    final conv = service.conversationOf(widget.resultId);
    final isStreaming = service.isStreaming(widget.resultId);
    final error = service.errorOf(widget.resultId);

    if (conv != null) _scrollToBottom();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, outerController) {
        return Column(
          children: [
            _buildHeader(context, conv, service),
            const Divider(height: 1),
            Expanded(
              child: conv == null
                  ? const Center(child: Text('尚未开始分析'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conv.messages.length,
                      itemBuilder: (ctx, i) {
                        final m = conv.messages[i];
                        return AIChatBubble(
                          message: m,
                          onCopy: m.role == ChatRole.assistant
                              ? () => _copyMessage(context, m.content)
                              : null,
                          onRetry: m.status == ChatMessageStatus.failed &&
                                  m.role == ChatRole.user
                              ? () => service.retry(widget.resultId, m.id,
                                  fallbackResult: widget.fallbackResult)
                              : null,
                        );
                      },
                    ),
            ),
            if (error != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.withOpacity(0.1),
                width: double.infinity,
                child: Text(error,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            AIChatInputBar(
              isStreaming: isStreaming,
              onSend: (text) => service.sendFollowUp(
                widget.resultId,
                text,
                fallbackResult: widget.fallbackResult,
              ),
              onStop: () => service.stop(widget.resultId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AIConversation? conv,
      AIConversationService service) {
    final title =
        conv == null ? 'AI 对话' : 'AI 对话 · ${_systemLabel(conv.systemType)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.smart_toy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) =>
                _handleMenu(context, action, conv, service),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'reset', child: Text('新建话题')),
              PopupMenuItem(value: 'copy_all', child: Text('复制全文')),
              PopupMenuItem(value: 'preview', child: Text('预览下一次请求')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    String action,
    AIConversation? conv,
    AIConversationService service,
  ) async {
    if (conv == null) return;
    switch (action) {
      case 'reset':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('新建话题'),
            content: const Text('将清空当前所有追问（保留初始分析）。确定吗？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('确认')),
            ],
          ),
        );
        if (ok == true) await service.reset(widget.resultId);
        break;
      case 'copy_all':
        final buf = StringBuffer();
        for (final m in conv.messages) {
          buf.writeln(m.role == ChatRole.user ? '## 用户' : '## AI');
          buf.writeln(m.content);
          buf.writeln();
        }
        await Clipboard.setData(ClipboardData(text: buf.toString()));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已复制整段对话')),
          );
        }
        break;
      case 'preview':
        if (conv.castSnapshot == null) return;
        final list = ChatRequestBuilder.build(conv);
        final buf = StringBuffer();
        for (final m in list) {
          buf.writeln('--- ${_roleLabel(m.role)} ---');
          buf.writeln(m.content);
          buf.writeln();
        }
        if (context.mounted) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, sc) => SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  buf.toString(),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.6),
                ),
              ),
            ),
          );
        }
        break;
    }
  }

  Future<void> _copyMessage(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制')),
      );
    }
  }
}
