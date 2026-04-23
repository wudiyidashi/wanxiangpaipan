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
  });
}
