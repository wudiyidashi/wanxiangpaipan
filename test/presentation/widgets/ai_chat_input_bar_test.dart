import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/ai_chat_input_bar.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('空文本时发送按钮 disabled', (tester) async {
    await tester.pumpWidget(_wrap(AIChatInputBar(
      isStreaming: false,
      onSend: (_) {},
      onStop: () {},
    )));
    final btn = tester.widget<IconButton>(find.byKey(const Key('send_btn')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('输入文本后点发送回调 onSend', (tester) async {
    String? captured;
    await tester.pumpWidget(_wrap(AIChatInputBar(
      isStreaming: false,
      onSend: (text) => captured = text,
      onStop: () {},
    )));
    await tester.enterText(find.byType(TextField), '你好');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_btn')));
    expect(captured, '你好');
  });

  testWidgets('isStreaming=true 时显示停止按钮，点击回调 onStop', (tester) async {
    var stopped = false;
    await tester.pumpWidget(_wrap(AIChatInputBar(
      isStreaming: true,
      onSend: (_) {},
      onStop: () => stopped = true,
    )));
    await tester.tap(find.byKey(const Key('stop_btn')));
    expect(stopped, isTrue);
  });
}
