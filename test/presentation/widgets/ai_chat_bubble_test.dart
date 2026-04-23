import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';
import 'package:wanxiang_paipan/presentation/widgets/ai_chat_bubble.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

AIChatMessage _m(ChatRole role, String content,
        [ChatMessageStatus status = ChatMessageStatus.sent,
        String? err]) =>
    AIChatMessage(
      id: 'x',
      role: role,
      content: content,
      timestamp: DateTime.utc(2026, 4, 23),
      status: status,
      errorMessage: err,
    );

void main() {
  testWidgets('assistant 气泡渲染 markdown 内容', (tester) async {
    await tester.pumpWidget(_wrap(
      AIChatBubble(message: _m(ChatRole.assistant, '## hello')),
    ));
    expect(find.textContaining('hello'), findsOneWidget);
  });

  testWidgets('user 气泡右对齐且显示文本', (tester) async {
    await tester.pumpWidget(_wrap(
      AIChatBubble(message: _m(ChatRole.user, '为什么？')),
    ));
    expect(find.text('为什么？'), findsOneWidget);
  });

  testWidgets('failed 状态显示错误提示和重试按钮', (tester) async {
    var retryClicked = false;
    await tester.pumpWidget(_wrap(
      AIChatBubble(
        message: _m(ChatRole.user, '失败了', ChatMessageStatus.failed, 'oops'),
        onRetry: () => retryClicked = true,
      ),
    ));
    expect(find.text('重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retryClicked, isTrue);
  });

  testWidgets('assistant 气泡可复制', (tester) async {
    var copied = false;
    await tester.pumpWidget(_wrap(
      AIChatBubble(
        message: _m(ChatRole.assistant, 'xx'),
        onCopy: () => copied = true,
      ),
    ));
    await tester.tap(find.byTooltip('复制本条'));
    expect(copied, isTrue);
  });
}
