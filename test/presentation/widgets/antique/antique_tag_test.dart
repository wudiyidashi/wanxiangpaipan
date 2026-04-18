import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_tag.dart';

void main() {
  group('AntiqueTag', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTag(label: '六爻'),
          ),
        ),
      );
      expect(find.text('六爻'), findsOneWidget);
    });

    testWidgets('uses custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTag(label: '初传', color: Color(0xFF3A6EA5)),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueTag),
          matching: find.byType(Container),
        ).first,
      );
      final deco = container.decoration as BoxDecoration;
      expect((deco.border as Border).top.color,
          const Color(0xFF3A6EA5).withOpacity(0.3));
    });

    testWidgets('a11y: tag semantics label contains text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueTag(label: '六爻')),
        ),
      );
      final semantics = tester.getSemantics(find.byType(AntiqueTag));
      // The Semantics node label may include child text; assert it starts with the tag label
      expect(semantics.label, startsWith('六爻'));
      handle.dispose();
    });
  });
}
