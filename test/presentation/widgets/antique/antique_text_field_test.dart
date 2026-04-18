import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_text_field.dart';

void main() {
  group('AntiqueTextField', () {
    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(hint: '请输入'),
          ),
        ),
      );
      expect(find.text('请输入'), findsOneWidget);
    });

    testWidgets('forwards onChanged events', (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(onChanged: (v) => captured = v),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '甲');
      expect(captured, '甲');
    });

    testWidgets('respects maxLines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(maxLines: 3),
          ),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.maxLines, 3);
    });

    testWidgets('accepts null maxLines for unlimited growth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(maxLines: null),
          ),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.maxLines, isNull);
    });

    testWidgets('obscureText hides input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(obscureText: true),
          ),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
    });

    testWidgets('expands fills parent when true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: Column(
                children: const [
                  Expanded(
                    child: AntiqueTextField(expands: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.expands, isTrue);
    });
  });
}
