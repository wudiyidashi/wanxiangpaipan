import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/core/theme/antique_tokens.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_card.dart';

void main() {
  group('AntiqueCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueCard(child: Text('hello')),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('uses default 16px padding on inner Container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueCard(child: SizedBox.shrink()),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueCard),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.padding, const EdgeInsets.all(16));
    });

    testWidgets('uses card radius from AntiqueTokens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueCard(child: Text('x'))),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueCard),
          matching: find.byType(Container),
        ).first,
      );
      final deco = container.decoration as BoxDecoration;
      expect(
        deco.borderRadius,
        BorderRadius.circular(AntiqueTokens.radiusCard),
      );
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueCard(
              onTap: () => tapped = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AntiqueCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('a11y: card with onTap has button semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueCard(
              onTap: () {},
              semanticsLabel: '系统卡片',
              child: const Text('内容'),
            ),
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(AntiqueCard));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      handle.dispose();
    });

    testWidgets('a11y: card without onTap has no button semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueCard(child: Text('内容')),
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(AntiqueCard));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isFalse);
      handle.dispose();
    });
  });
}
