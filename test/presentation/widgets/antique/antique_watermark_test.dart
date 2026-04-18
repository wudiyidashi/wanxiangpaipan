import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_watermark.dart';

void main() {
  group('AntiqueWatermark', () {
    testWidgets('renders character', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueWatermark(char: '占')),
        ),
      );
      expect(find.text('占'), findsOneWidget);
    });

    testWidgets('uses default size 96', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueWatermark(char: '占')),
        ),
      );
      final text = tester.widget<Text>(find.text('占'));
      expect(text.style?.fontSize, 96);
    });
  });
}
