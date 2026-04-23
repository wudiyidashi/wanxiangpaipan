import 'dart:convert';

import '../../data/secure/secure_storage.dart';
import '../../domain/divination_system.dart';
import '../model/ai_chat_message.dart';
import '../model/ai_conversation.dart';

/// 封装 AIConversation 的加密存储与老数据迁移
class ChatRepository {
  final SecureStorage _secureStorage;

  ChatRepository({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  static String _conversationKey(String resultId) => 'conversation_$resultId';
  static String _legacyKey(String resultId) => 'interpretation_$resultId';

  /// 读取对话。若新字段不存在但提供了 [legacySystemType]，会尝试从旧
  /// `interpretation_<id>` 字段构造一个临时 conversation（castSnapshot 为 null）。
  /// 临时 conversation 不会写回存储。
  Future<AIConversation?> load(
    String resultId, {
    DivinationType? legacySystemType,
  }) async {
    final raw = await _secureStorage.read(_conversationKey(resultId));
    if (raw != null) {
      try {
        return AIConversation.fromJson(
            json.decode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null; // 反序列化失败不阻塞 UI
      }
    }

    if (legacySystemType == null) return null;
    return _tryLegacyFallback(resultId, legacySystemType);
  }

  /// 持久化对话；成功后会清理 legacy interpretation 字段。
  Future<void> save(AIConversation conversation) async {
    final raw = json.encode(conversation.toJson());
    await _secureStorage.write(_conversationKey(conversation.resultId), raw);
    await _secureStorage.delete(_legacyKey(conversation.resultId));
  }

  /// 删除对话（含 legacy 字段）
  Future<void> delete(String resultId) async {
    await _secureStorage.delete(_conversationKey(resultId));
    await _secureStorage.delete(_legacyKey(resultId));
  }

  Future<AIConversation?> _tryLegacyFallback(
    String resultId,
    DivinationType systemType,
  ) async {
    final legacy = await _secureStorage.read(_legacyKey(resultId));
    if (legacy == null || legacy.isEmpty) return null;

    final now = DateTime.now();
    return AIConversation(
      version: 1,
      resultId: resultId,
      systemType: systemType,
      castSnapshot: null,
      messages: [
        AIChatMessage(
          id: 'legacy-$resultId',
          role: ChatRole.assistant,
          content: legacy,
          timestamp: now,
          status: ChatMessageStatus.sent,
        ),
      ],
      updatedAt: now,
    );
  }
}
