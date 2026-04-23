import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';
import 'package:wanxiang_paipan/ai/model/ai_conversation.dart';
import 'package:wanxiang_paipan/ai/model/cast_snapshot.dart';
import 'package:wanxiang_paipan/ai/service/chat_repository.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

class _MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final results = <String, String>{};
    for (final key in keys) {
      if (_storage.containsKey(key)) results[key] = _storage[key]!;
    }
    return results;
  }

  @override
  Future<Map<String, String>> readAll() async =>
      Map.unmodifiable(_storage);

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}

AIConversation _sampleConv(String resultId) => AIConversation(
      version: 1,
      resultId: resultId,
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

void main() {
  late _MockSecureStorage storage;
  late ChatRepository repo;

  setUp(() {
    storage = _MockSecureStorage();
    repo = ChatRepository(secureStorage: storage);
  });

  group('ChatRepository', () {
    test('save 后可通过 load 读回完整 conversation', () async {
      final conv = _sampleConv('r1');
      await repo.save(conv);
      final loaded = await repo.load('r1');
      expect(loaded, equals(conv));
    });

    test('load 不存在的 resultId 返回 null', () async {
      expect(await repo.load('nope'), isNull);
    });

    test('delete 清理 conversation 与 legacy interpretation', () async {
      await storage.write('conversation_r1', 'something');
      await storage.write('interpretation_r1', 'legacy blob');
      await repo.delete('r1');
      expect(await storage.read('conversation_r1'), isNull);
      expect(await storage.read('interpretation_r1'), isNull);
    });

    test('load 从 legacy interpretation 回退构造临时 conversation', () async {
      await storage.write('interpretation_r2', '旧 markdown 内容');
      final loaded = await repo.load(
        'r2',
        legacySystemType: DivinationType.daLiuRen,
      );
      expect(loaded, isNotNull);
      expect(loaded!.resultId, 'r2');
      expect(loaded.systemType, DivinationType.daLiuRen);
      expect(loaded.castSnapshot, isNull);
      expect(loaded.messages, hasLength(1));
      expect(loaded.messages[0].role, ChatRole.assistant);
      expect(loaded.messages[0].content, '旧 markdown 内容');
      expect(loaded.messages[0].status, ChatMessageStatus.sent);
      // legacy fallback 不写回
      expect(await storage.read('conversation_r2'), isNull);
    });

    test('legacy fallback 要求 legacySystemType 参数', () async {
      await storage.write('interpretation_r3', 'blob');
      final loaded = await repo.load('r3');
      // 未提供 legacySystemType → 回退失败，返回 null
      expect(loaded, isNull);
    });

    test('save 后会自动清理旧 interpretation 字段', () async {
      await storage.write('interpretation_r4', 'stale');
      final conv = _sampleConv('r4');
      await repo.save(conv);
      expect(await storage.read('interpretation_r4'), isNull);
      expect(await storage.read('conversation_r4'), isNotNull);
    });

    test('反序列化失败返回 null，不抛异常', () async {
      await storage.write('conversation_r5', '{not valid json');
      final loaded = await repo.load('r5');
      expect(loaded, isNull);
    });

    test('保存的 JSON 可被手动解析回 AIConversation', () async {
      final conv = _sampleConv('r6');
      await repo.save(conv);
      final raw = await storage.read('conversation_r6');
      expect(raw, isNotNull);
      final decoded = AIConversation.fromJson(
          json.decode(raw!) as Map<String, dynamic>);
      expect(decoded, equals(conv));
    });
  });
}
