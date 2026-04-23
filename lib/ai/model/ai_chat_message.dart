import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_chat_message.freezed.dart';
part 'ai_chat_message.g.dart';

/// 消息发送者角色
enum ChatRole { system, user, assistant }

/// 消息状态
///
/// - [sending]: 用户消息已加入列表，但请求尚未发出
/// - [streaming]: AI 正在流式生成回复
/// - [sent]: 已完成
/// - [failed]: 发送或生成失败
enum ChatMessageStatus { sending, streaming, sent, failed }

/// 单条聊天消息
@freezed
class AIChatMessage with _$AIChatMessage {
  const factory AIChatMessage({
    required String id,
    required ChatRole role,
    required String content,
    required DateTime timestamp,
    required ChatMessageStatus status,
    String? errorMessage,
  }) = _AIChatMessage;

  const AIChatMessage._();

  factory AIChatMessage.fromJson(Map<String, dynamic> json) =>
      _$AIChatMessageFromJson(json);
}
