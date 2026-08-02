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

    test('旧快照 JSON 缺少版本字段时保留为 legacyUnknown', () {
      final json = _literalConversationJson('liuyao')
        ..['castSnapshot'] = <String, dynamic>{
          'systemPrompt': 'legacy system',
          'castUserPrompt': 'legacy user',
          'model': 'legacy-model',
          'assembledAt': '2026-04-23T00:00:00.000Z',
        };

      final snapshot = AIConversation.fromJson(json).castSnapshot!;

      expect(snapshot.systemPrompt, 'legacy system');
      expect(snapshot.analysisSchemaVersion, 'legacyUnknown');
      expect(snapshot.projectionSchemaVersion, 'legacyUnknown');
      expect(snapshot.ruleSetId, 'legacyUnknown');
      expect(snapshot.ruleSetVersion, 'legacyUnknown');
      expect(snapshot.sourceCatalogVersion, 'legacyUnknown');
      expect(snapshot.promptPolicyVersion, 'legacyUnknown');
      expect(snapshot.systemTemplateId, 'legacyUnknown');
      expect(snapshot.analysisTemplateId, 'legacyUnknown');
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

      expect(restored.messages.map((m) => m.id).toList(), ['m0', 'm1', 'm2']);
      expect(restored.messages.map((m) => m.role).toList(),
          [ChatRole.assistant, ChatRole.user, ChatRole.assistant]);
      expect(restored, equals(conv));
    });

    test('writes stable divination type IDs on the JSON wire', () {
      final conv = AIConversation(
        version: 1,
        resultId: 'qimen-result',
        systemType: DivinationType.qiMen,
        castSnapshot: null,
        messages: const [],
        updatedAt: DateTime.utc(2026, 7, 28),
      );

      expect(conv.toJson()['systemType'], 'qimen');
    });

    test('reads stable divination type IDs from literal JSON', () {
      const stableIds = {
        'liuyao': DivinationType.liuYao,
        'daliuren': DivinationType.daLiuRen,
        'xiaoliuren': DivinationType.xiaoLiuRen,
        'meihua': DivinationType.meiHua,
        'qimen': DivinationType.qiMen,
      };

      for (final entry in stableIds.entries) {
        final restored = AIConversation.fromJson(
          _literalConversationJson(entry.key),
        );
        expect(restored.systemType, entry.value, reason: entry.key);
      }
    });

    test('reads legacy enum names from literal JSON', () {
      const legacyNames = {
        'liuYao': DivinationType.liuYao,
        'daLiuRen': DivinationType.daLiuRen,
        'xiaoLiuRen': DivinationType.xiaoLiuRen,
        'meiHua': DivinationType.meiHua,
        'qiMen': DivinationType.qiMen,
      };

      for (final entry in legacyNames.entries) {
        final restored = AIConversation.fromJson(
          _literalConversationJson(entry.key),
        );
        expect(restored.systemType, entry.value, reason: entry.key);
      }
    });
  });
}

Map<String, dynamic> _literalConversationJson(String systemType) => {
      'version': 1,
      'resultId': 'literal-result',
      'systemType': systemType,
      'castSnapshot': null,
      'messages': <dynamic>[],
      'updatedAt': '2026-07-28T00:00:00.000Z',
    };
