import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_viewmodel.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/month_grid_view.dart';

void main() {
  Future<void> pump(WidgetTester t, CalendarViewModel vm) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider.value(
          value: vm,
          child: const MonthGridView(),
        ),
      ),
    ));
  }

  testWidgets('Tapping a day updates selectedDate', (t) async {
    final vm = CalendarViewModel(
      service: const AlmanacService(),
      now: () => DateTime(2026, 4, 18, 10),
    );
    await pump(t, vm);
    await t.pumpAndSettle();

    final day10 = find.text('10').first;
    await t.tap(day10);
    await t.pumpAndSettle();

    expect(vm.selectedDate, DateTime(2026, 4, 10));
  });

  testWidgets('Current month has 42 cells (6 rows × 7 cols)', (t) async {
    final vm = CalendarViewModel(
      service: const AlmanacService(),
      now: () => DateTime(2026, 4, 18, 10),
    );
    await pump(t, vm);
    await t.pumpAndSettle();

    final cells = find.byKey(const ValueKey('month-cell'));
    expect(cells, findsNWidgets(42));
  });
}
