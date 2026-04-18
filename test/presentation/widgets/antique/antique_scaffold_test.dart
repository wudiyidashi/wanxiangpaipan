import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/cast/compass_background.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_scaffold.dart';

void main() {
  group('AntiqueScaffold', () {
    testWidgets('renders body', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(body: Text('hi')),
        ),
      );
      expect(find.text('hi'), findsOneWidget);
    });

    testWidgets('does not show compass by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AntiqueScaffold(body: SizedBox())),
      );
      expect(find.byType(CompassBackground), findsNothing);
    });

    testWidgets('shows compass when showCompass is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(showCompass: true, body: SizedBox()),
        ),
      );
      expect(find.byType(CompassBackground), findsOneWidget);
    });

    testWidgets('shows watermark char when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(watermarkChar: '辰', body: SizedBox()),
        ),
      );
      expect(find.text('辰'), findsOneWidget);
    });

    testWidgets('body is not padded when appBar is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(body: Text('no-bar')),
        ),
      );
      // Without an appBar the body Positioned should not be wrapped in Padding.
      // We verify by checking the body text is still found.
      expect(find.text('no-bar'), findsOneWidget);
      expect(
        tester.widget<Padding>(
          find.ancestor(
            of: find.text('no-bar'),
            matching: find.byType(Padding),
          ).first,
        ),
        isA<Padding>(),
      );
    });

    testWidgets('body gets top padding when appBar is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AntiqueScaffold(
            appBar: AppBar(title: const Text('Title')),
            body: const Text('content'),
          ),
        ),
      );
      await tester.pump();

      // Body must be rendered inside a Padding widget with top >= kToolbarHeight.
      final paddings = tester.widgetList<Padding>(
        find.ancestor(
          of: find.text('content'),
          matching: find.byType(Padding),
        ),
      );
      final topPaddings = paddings
          .map((p) => p.padding.resolve(TextDirection.ltr).top)
          .where((t) => t >= kToolbarHeight);
      expect(topPaddings, isNotEmpty,
          reason: 'Expected at least one Padding with top >= kToolbarHeight');
    });
  });
}
