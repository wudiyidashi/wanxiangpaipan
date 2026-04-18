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
  });
}
