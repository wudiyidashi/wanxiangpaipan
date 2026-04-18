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
  });
}
