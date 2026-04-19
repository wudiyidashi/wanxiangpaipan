import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_screen.dart';

void main() {
  Future<void> pump(WidgetTester t, {bool chromeless = true}) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CalendarScreen(chromeless: chromeless),
      ),
    ));
  }

  testWidgets('C1: chromeless=true does not introduce Scaffold/AppBar', (t) async {
    await pump(t, chromeless: true);
    final calendarFinder = find.byType(CalendarScreen);
    final appBars = find.descendant(
      of: calendarFinder,
      matching: find.byType(AppBar),
    );
    expect(appBars, findsNothing);
  });

  testWidgets('C4: "今日" button hidden on today month, visible after switching', (t) async {
    await pump(t, chromeless: true);
    expect(find.text('今日'), findsNothing);

    final forward = find.byKey(const Key('calendar-forward'));
    expect(forward, findsOneWidget);
    await t.tap(forward);
    await t.pumpAndSettle();

    expect(find.text('今日'), findsOneWidget);
  });
}
