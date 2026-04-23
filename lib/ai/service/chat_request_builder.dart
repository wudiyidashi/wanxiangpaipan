import '../llm_provider.dart';
import '../model/ai_chat_message.dart';
import '../model/ai_conversation.dart';

/// 将 [AIConversation] 组装为 Provider 级别的 message 列表。
///
/// 策略：固定锚点（system + cast user + 初始分析） + 最近 N 条追问（滑窗）。
/// 过滤掉 status=failed 的消息。
class ChatRequestBuilder {
  /// 初始分析之后保留的最大消息数（user/assistant 各算一条）
  static const int followUpWindowSize = 12;

  static List<ProviderChatMessage> build(AIConversation conversation) {
    if (conversation.castSnapshot == null) {
      throw StateError(
          'Cannot build chat request from conversation with null castSnapshot. '
          'Legacy conversations must have snapshot filled before first follow-up.');
    }
    if (conversation.messages.isEmpty ||
        conversation.messages.first.role != ChatRole.assistant) {
      throw StateError('Conversation must start with an assistant message.');
    }

    final snap = conversation.castSnapshot!;
    final anchors = <ProviderChatMessage>[
      ProviderChatMessage.system(snap.systemPrompt),
      ProviderChatMessage.user(snap.castUserPrompt),
      ProviderChatMessage.assistant(conversation.messages.first.content),
    ];

    final followUps = conversation.messages
        .skip(1)
        .where((m) => m.status != ChatMessageStatus.failed)
        .toList();

    final windowed = followUps.length <= followUpWindowSize
        ? followUps
        : followUps.sublist(followUps.length - followUpWindowSize);

    return [
      ...anchors,
      ...windowed.map(
          (m) => ProviderChatMessage(role: m.role, content: m.content)),
    ];
  }
}
