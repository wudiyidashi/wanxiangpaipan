import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../ai/model/ai_chat_message.dart';
import '../../core/theme/app_text_styles.dart';

class AIChatBubble extends StatelessWidget {
  final AIChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;

  const AIChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onCopy,
  });

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = _isUser
        ? theme.primaryColor.withOpacity(0.12)
        : theme.cardColor;
    final borderColor = theme.dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isUser
                      ? SelectableText(
                          message.content,
                          style: AppTextStyles.antiqueBody,
                        )
                      : MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTextStyles.antiqueBody
                                .copyWith(height: 1.6),
                          ),
                        ),
                  if (message.status == ChatMessageStatus.failed)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            message.errorMessage ?? '发送失败',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.redAccent),
                          ),
                          if (onRetry != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onRetry,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  '重试',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      decoration:
                                          TextDecoration.underline),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (!_isUser && onCopy != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        tooltip: '复制本条',
                        visualDensity: VisualDensity.compact,
                        onPressed: onCopy,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
