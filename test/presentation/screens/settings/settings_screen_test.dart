import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/settings_screen.dart';

void main() {
  testWidgets('关于弹窗展示安装包版本', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          applicationVersionLoader: () async => '1.6.1+2',
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final aboutTile = find.text('关于').last;
    await tester.tap(aboutTile);
    await tester.pumpAndSettle();

    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.text('1.6.1+2'), findsOneWidget);
  });
}
