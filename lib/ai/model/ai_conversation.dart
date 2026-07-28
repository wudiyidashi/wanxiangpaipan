import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/divination_system.dart';
import 'ai_chat_message.dart';
import 'cast_snapshot.dart';

part 'ai_conversation.freezed.dart';
part 'ai_conversation.g.dart';

/// Serializes divination systems with their stable wire IDs while accepting
/// enum names written by older application versions.
class DivinationTypeJsonConverter
    implements JsonConverter<DivinationType, String> {
  const DivinationTypeJsonConverter();

  @override
  DivinationType fromJson(String json) {
    for (final type in DivinationType.values) {
      if (json == type.id || json == type.name) {
        return type;
      }
    }
    throw FormatException('Unknown divination type: $json');
  }

  @override
  String toJson(DivinationType object) => object.id;
}

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
    @DivinationTypeJsonConverter() required DivinationType systemType,
    required CastSnapshot? castSnapshot,
    required List<AIChatMessage> messages,
    required DateTime updatedAt,
  }) = _AIConversation;

  const AIConversation._();

  factory AIConversation.fromJson(Map<String, dynamic> json) =>
      _$AIConversationFromJson(json);
}
