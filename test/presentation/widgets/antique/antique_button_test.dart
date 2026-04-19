import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_button.dart';

void main() {
  group('AntiqueButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(label: '起卦', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('起卦'), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(
              label: '起卦',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AntiqueButton));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('disables tap when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueButton(label: '起卦', onPressed: null),
          ),
        ),
      );
      expect(find.text('起卦'), findsOneWidget);
    });

    testWidgets('ghost variant has no fill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(
              label: '取消',
              variant: AntiqueButtonVariant.ghost,
              onPressed: () {},
            ),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AntiqueButton),
              matching: find.byType(Container),
            )
            .first,
      );
      final deco = container.decoration as BoxDecoration;
      expect(deco.gradient, isNull);
    });

    testWidgets('a11y: enabled button has button semantics with label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(label: '起卦', onPressed: () {}),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AntiqueButton)),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          label: '起卦',
        ),
      );
      handle.dispose();
    });

    testWidgets('a11y: disabled button has button semantics, enabled=false',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueButton(label: '起卦', onPressed: null),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AntiqueButton)),
        matchesSemantics(
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          label: '起卦',
        ),
      );
      handle.dispose();
    });
  });
}
