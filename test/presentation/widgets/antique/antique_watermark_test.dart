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

    testWidgets('a11y: watermark is excluded from semantics tree',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueWatermark(char: '占')),
        ),
      );
      // ExcludeSemantics blocks all child semantics — the top-level node
      // for the watermark widget should have an empty label (no text exposed).
      final semantics = tester.getSemantics(find.byType(AntiqueWatermark));
      expect(semantics.label, isEmpty);
      handle.dispose();
    });
  });
}
