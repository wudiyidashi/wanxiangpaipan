import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_dialog.dart';

void main() {
  group('AntiqueDialog', () {
    testWidgets('renders title and content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueDialog(
              title: '确认删除',
              content: Text('删除后无法恢复'),
            ),
          ),
        ),
      );
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('删除后无法恢复'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueDialog(
              title: 'X',
              content: const SizedBox(),
              actions: [
                TextButton(
                  key: const Key('cancel'),
                  onPressed: () {},
                  child: const Text('取消'),
                ),
                TextButton(
                  key: const Key('confirm'),
                  onPressed: () {},
                  child: const Text('确认'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('cancel')), findsOneWidget);
      expect(find.byKey(const Key('confirm')), findsOneWidget);
    });

    testWidgets('showAntiqueDialog opens and returns value', (tester) async {
      late BuildContext dialogContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              dialogContext = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      final future = showAntiqueDialog<bool>(
        context: dialogContext,
        title: '确认',
        content: const Text('ok?'),
        actions: [
          Builder(
            builder: (c) => TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('是'),
            ),
          ),
        ],
      );

      await tester.pumpAndSettle();
      expect(find.text('确认'), findsOneWidget);
      expect(find.text('ok?'), findsOneWidget);

      await tester.tap(find.text('是'));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, isTrue);
    });

    testWidgets('a11y: dialog has scopesRoute and namesRoute semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueDialog(
              title: '确认删除',
              content: Text('删除后无法恢复'),
            ),
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(AntiqueDialog));
      expect(semantics.hasFlag(SemanticsFlag.scopesRoute), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.namesRoute), isTrue);
      expect(semantics.label, '确认删除');
      handle.dispose();
    });
  });
}
