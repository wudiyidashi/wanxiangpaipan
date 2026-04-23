import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';
import 'package:wanxiang_paipan/ai/model/ai_conversation.dart';
import 'package:wanxiang_paipan/ai/model/cast_snapshot.dart';
import 'package:wanxiang_paipan/ai/service/chat_request_builder.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

AIChatMessage _msg(String id, ChatRole role, String content,
        [ChatMessageStatus status = ChatMessageStatus.sent]) =>
    AIChatMessage(
      id: id,
      role: role,
      content: content,
      timestamp: DateTime.utc(2026, 4, 23),
      status: status,
    );

AIConversation _conv(List<AIChatMessage> messages) => AIConversation(
      version: 1,
      resultId: 'r1',
      systemType: DivinationType.liuYao,
      castSnapshot: CastSnapshot(
        systemPrompt: 'SYS',
        castUserPrompt: 'CAST',
        model: 'gpt-4',
        assembledAt: DateTime.utc(2026, 4, 23),
      ),
      messages: messages,
      updatedAt: DateTime.utc(2026, 4, 23),
    );

void main() {
  group('ChatRequestBuilder.build', () {
    test('零追问：返回 system + cast + initial', () {
      final conv = _conv([_msg('m0', ChatRole.assistant, '初始分析')]);
      final msgs = ChatRequestBuilder.build(conv);
      expect(msgs.map((m) => m.role).toList(),
          [ChatRole.system, ChatRole.user, ChatRole.assistant]);
      expect(msgs[0].content, 'SYS');
      expect(msgs[1].content, 'CAST');
      expect(msgs[2].content, '初始分析');
    });

    test('1 轮追问：在 anchors 之后追加 user + assistant', () {
      final conv = _conv([
        _msg('m0', ChatRole.assistant, '初始分析'),
        _msg('m1', ChatRole.user, '追问1'),
        _msg('m2', ChatRole.assistant, '回复1'),
      ]);
      final msgs = ChatRequestBuilder.build(conv);
      expect(msgs.map((m) => m.role).toList(), [
        ChatRole.system,
        ChatRole.user,
        ChatRole.assistant,
        ChatRole.user,
        ChatRole.assistant,
      ]);
      expect(msgs[3].content, '追问1');
      expect(msgs[4].content, '回复1');
    });

    test('恰好 12 条追问：不丢弃', () {
      final messages = [_msg('m0', ChatRole.assistant, '初始分析')];
      for (var i = 0; i < 12; i++) {
        messages.add(_msg('m${i + 1}',
            i.isEven ? ChatRole.user : ChatRole.assistant, 't$i'));
      }
      final conv = _conv(messages);
      final msgs = ChatRequestBuilder.build(conv);
      // 3 anchors + 12 follow-ups = 15
      expect(msgs.length, 15);
      expect(msgs[3].content, 't0');
      expect(msgs.last.content, 't11');
    });

    test('13 条追问：丢弃最早一条', () {
      final messages = [_msg('m0', ChatRole.assistant, '初始分析')];
      for (var i = 0; i < 13; i++) {
        messages.add(_msg('m${i + 1}',
            i.isEven ? ChatRole.user : ChatRole.assistant, 't$i'));
      }
      final conv = _conv(messages);
      final msgs = ChatRequestBuilder.build(conv);
      expect(msgs.length, 15); // 3 + 12
      expect(msgs[3].content, 't1'); // t0 被丢
      expect(msgs.last.content, 't12');
    });

    test('过滤掉 failed 状态的消息', () {
      final conv = _conv([
        _msg('m0', ChatRole.assistant, '初始分析'),
        _msg('m1', ChatRole.user, '失败的', ChatMessageStatus.failed),
        _msg('m2', ChatRole.user, '成功的'),
        _msg('m3', ChatRole.assistant, '回复'),
      ]);
      final msgs = ChatRequestBuilder.build(conv);
      expect(msgs.map((m) => m.content).toList(),
          ['SYS', 'CAST', '初始分析', '成功的', '回复']);
    });

    test('castSnapshot 为 null 抛 StateError', () {
      final conv = AIConversation(
        version: 1,
        resultId: 'r2',
        systemType: DivinationType.liuYao,
        castSnapshot: null,
        messages: [_msg('m0', ChatRole.assistant, '初始')],
        updatedAt: DateTime.utc(2026, 4, 23),
      );
      expect(() => ChatRequestBuilder.build(conv), throwsStateError);
    });

    test('首条非 assistant 抛 StateError', () {
      final conv = _conv([_msg('m0', ChatRole.user, '不该是 user')]);
      expect(() => ChatRequestBuilder.build(conv), throwsStateError);
    });
  });
}
