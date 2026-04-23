import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';
import 'package:wanxiang_paipan/ai/model/ai_conversation.dart';
import 'package:wanxiang_paipan/ai/model/cast_snapshot.dart';
import 'package:wanxiang_paipan/ai/service/ai_conversation_service.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/presentation/widgets/ai_chat_sheet.dart';

class _FakeConversationService extends ChangeNotifier
    implements AIConversationService {
  AIConversation? _conv;
  bool _streaming = false;

  void seed(AIConversation conv, {bool streaming = false}) {
    _conv = conv;
    _streaming = streaming;
    notifyListeners();
  }

  @override
  AIConversation? conversationOf(String resultId) => _conv;

  @override
  bool isStreaming(String resultId) => _streaming;

  @override
  String? errorOf(String resultId) => null;

  @override
  Future<void> sendFollowUp(String resultId, String userText,
      {DivinationResult? fallbackResult}) async {}

  @override
  Future<void> stop(String resultId) async {}

  @override
  Future<void> reset(String resultId) async {}

  @override
  Future<void> delete(String resultId) async {}

  @override
  Future<void> retry(String resultId, String failedUserMessageId,
      {DivinationResult? fallbackResult}) async {}

  @override
  Future<AIConversation?> loadIfNeeded(String resultId,
          {DivinationType? legacySystemType}) async =>
      _conv;

  @override
  Future<void> startConversation(DivinationResult result,
      {String? question}) async {}
}

AIConversation _sample({List<AIChatMessage>? messages}) => AIConversation(
      version: 1,
      resultId: 'r1',
      systemType: DivinationType.liuYao,
      castSnapshot: CastSnapshot(
        systemPrompt: 'sys',
        castUserPrompt: 'user',
        model: 'gpt-4',
        assembledAt: DateTime.utc(2026, 4, 23),
      ),
      messages: messages ??
          [
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

Widget _wrap(_FakeConversationService svc) {
  return ChangeNotifierProvider<AIConversationService>.value(
    value: svc,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (ctx) => ChangeNotifierProvider<
                    AIConversationService>.value(
                  value: svc,
                  child: const AIChatSheet(resultId: 'r1'),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('渲染对话消息列表', (tester) async {
    final svc = _FakeConversationService()..seed(_sample());
    await tester.pumpWidget(_wrap(svc));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.textContaining('初始分析'), findsOneWidget);
  });

  testWidgets('标题显示系统名', (tester) async {
    final svc = _FakeConversationService()..seed(_sample());
    await tester.pumpWidget(_wrap(svc));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.textContaining('六爻'), findsWidgets);
  });
}
