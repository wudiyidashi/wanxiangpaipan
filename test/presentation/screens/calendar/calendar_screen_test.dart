import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_screen.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';

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

  testWidgets('C3: tapping a day updates DayDetailView', (t) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(
      body: CalendarScreen(
        chromeless: true,
        almanacService: const AlmanacService(),
        now: () => DateTime(2026, 4, 18, 10),
      ),
    )));
    await t.pumpAndSettle();

    // 初始显示 18 日
    expect(find.textContaining('2026年4月18日'), findsOneWidget);

    await t.tap(find.text('10').first);
    await t.pumpAndSettle();

    expect(find.textContaining('2026年4月10日'), findsOneWidget);
  });

  testWidgets('C5: tapping 未时 hour updates four-pillars 时柱', (t) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(
      body: CalendarScreen(
        chromeless: true,
        almanacService: const AlmanacService(),
        now: () => DateTime(2026, 4, 18, 10),
      ),
    )));
    await t.pumpAndSettle();

    // 当前为巳时（10:00 → 巳）；点未时后 FourPillarsCard 时柱应变化
    final before = t.widget<Text>(find.byKey(const Key('pillar-hour-gz')));

    // 未时 可能在横向 ListView 屏外，先滚到可见再 tap
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('hour-未')),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('hour-未')));
    await t.pumpAndSettle();
    final after = t.widget<Text>(find.byKey(const Key('pillar-hour-gz')));
    expect(before.data, isNot(equals(after.data)));
  });
}
