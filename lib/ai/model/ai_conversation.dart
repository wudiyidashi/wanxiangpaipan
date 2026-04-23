import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/divination_system.dart';
import 'ai_chat_message.dart';
import 'cast_snapshot.dart';

part 'ai_conversation.freezed.dart';
part 'ai_conversation.g.dart';

/// 一次排盘对应的完整 AI 对话
///
/// 约束：
/// - `messages[0].role == assistant`（初始分析）
/// - 之后顺序严格 user / assistant 交替
/// - `castSnapshot == null` 仅在 legacy 迁移临时态，必须在首次 follow-up 时填入
@freezed
class AIConversation with _$AIConversation {
  @JsonSerializable(explicitToJson: true)
  const factory AIConversation({
    required int version,
    required String resultId,
    required DivinationType systemType,
    required CastSnapshot? castSnapshot,
    required List<AIChatMessage> messages,
    required DateTime updatedAt,
  }) = _AIConversation;

  const AIConversation._();

  factory AIConversation.fromJson(Map<String, dynamic> json) =>
      _$AIConversationFromJson(json);
}
