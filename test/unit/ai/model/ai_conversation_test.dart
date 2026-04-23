import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';
import 'package:wanxiang_paipan/ai/model/ai_conversation.dart';
import 'package:wanxiang_paipan/ai/model/cast_snapshot.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('AIConversation', () {
    test('round-trip json with full snapshot', () {
      final conv = AIConversation(
        version: 1,
        resultId: 'r1',
        systemType: DivinationType.liuYao,
        castSnapshot: CastSnapshot(
          systemPrompt: 'sys',
          castUserPrompt: 'user',
          model: 'gpt-4',
          assembledAt: DateTime.utc(2026, 4, 23),
        ),
        messages: [
          AIChatMessage(
            id: 'm0',
            role: ChatRole.assistant,
            content: '初始分析',
            timestamp: DateTime.utc(2026, 4, 23),
            status: ChatMessageStatus.sent,
          ),
        ],
        updatedAt: DateTime.utc(2026, 4, 23),
      );

      final restored = AIConversation.fromJson(conv.toJson());
      expect(restored, equals(conv));
    });

    test('round-trip json with null snapshot (legacy state)', () {
      final conv = AIConversation(
        version: 1,
        resultId: 'r2',
        systemType: DivinationType.daLiuRen,
        castSnapshot: null,
        messages: const [],
        updatedAt: DateTime.utc(2026, 4, 23),
      );

      final restored = AIConversation.fromJson(conv.toJson());
      expect(restored.castSnapshot, isNull);
      expect(restored, equals(conv));
    });

    test('round-trip preserves multi-message ordering', () {
      final conv = AIConversation(
        version: 1,
        resultId: 'r3',
        systemType: DivinationType.liuYao,
        castSnapshot: CastSnapshot(
          systemPrompt: 'sys',
          castUserPrompt: 'user',
          model: 'gpt-4',
          assembledAt: DateTime.utc(2026, 4, 23),
        ),
        messages: [
          AIChatMessage(
            id: 'm0',
            role: ChatRole.assistant,
            content: '初始分析',
            timestamp: DateTime.utc(2026, 4, 23, 10),
            status: ChatMessageStatus.sent,
          ),
          AIChatMessage(
            id: 'm1',
            role: ChatRole.user,
            content: '追问',
            timestamp: DateTime.utc(2026, 4, 23, 11),
            status: ChatMessageStatus.sent,
          ),
          AIChatMessage(
            id: 'm2',
            role: ChatRole.assistant,
            content: '回复',
            timestamp: DateTime.utc(2026, 4, 23, 12),
            status: ChatMessageStatus.sent,
          ),
        ],
        updatedAt: DateTime.utc(2026, 4, 23),
      );

      final restored = AIConversation.fromJson(conv.toJson());

      expect(restored.messages.map((m) => m.id).toList(),
          ['m0', 'm1', 'm2']);
      expect(restored.messages.map((m) => m.role).toList(),
          [ChatRole.assistant, ChatRole.user, ChatRole.assistant]);
      expect(restored, equals(conv));
    });
  });
}
