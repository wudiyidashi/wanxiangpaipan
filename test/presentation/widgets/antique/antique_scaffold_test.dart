import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/cast/compass_background.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_scaffold.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_app_bar.dart';

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

    testWidgets('does not wrap body in SafeArea when appBar is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(body: Text('no-bar')),
        ),
      );
      expect(find.text('no-bar'), findsOneWidget);
      // No SafeArea should be an ancestor of the body text when appBar is null.
      expect(
        find.ancestor(
          of: find.text('no-bar'),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
        reason: 'Body should not be wrapped in SafeArea when appBar is null',
      );
    });

    testWidgets('wraps body in SafeArea when appBar is set', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(
            appBar: AntiqueAppBar(title: 'X'),
            body: Text('content'),
          ),
        ),
      );
      await tester.pump();

      // Body must be rendered inside a SafeArea widget.
      expect(
        find.ancestor(
          of: find.text('content'),
          matching: find.byType(SafeArea),
        ),
        findsOneWidget,
        reason: 'Body should be wrapped in SafeArea when appBar is set',
      );
    });
  });
}
