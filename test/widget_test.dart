// 万象排盘应用 Widget 测试
//
// 验证 Hello World 界面是否正确显示

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wanxiang_paipan/main.dart';

void main() {
  testWidgets('Hello World screen displays correctly',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WanxiangPaipanApp());

    // Verify that the app bar title is displayed.
    expect(find.text('万象排盘'), findsOneWidget);

    // Verify that "Hello World" is displayed.
    expect(find.text('Hello World'), findsOneWidget);

    // Verify that the success message is displayed.
    expect(find.text('万象排盘 Flutter MVVM 架构初始化成功'), findsOneWidget);

    // Verify that the success icon is displayed.
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}



