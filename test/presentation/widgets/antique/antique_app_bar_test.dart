import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_app_bar.dart';

void main() {
  group('AntiqueAppBar', () {
    testWidgets('renders title centered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AntiqueAppBar(title: '大六壬起课'),
            body: SizedBox(),
          ),
        ),
      );
      expect(find.text('大六壬起课'), findsOneWidget);
    });

    testWidgets('has transparent background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AntiqueAppBar(title: 'X'),
            body: SizedBox(),
          ),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AntiqueAppBar(
              title: 'X',
              actions: [
                IconButton(
                  key: const Key('settings'),
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      expect(find.byKey(const Key('settings')), findsOneWidget);
    });
  });
}
