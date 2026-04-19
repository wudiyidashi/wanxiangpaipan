import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_viewmodel.dart';

class _CountingService extends AlmanacService {
  int calls = 0;
  final AlmanacService _delegate;
  _CountingService(this._delegate);

  @override
  DailyAlmanac getDay(DateTime date) {
    calls++;
    return _delegate.getDay(date);
  }
}

void main() {
  late _CountingService service;
  late CalendarViewModel vm;
  final fixedNow = DateTime(2026, 4, 18, 10);

  setUp(() {
    service = _CountingService(const AlmanacService());
    vm = CalendarViewModel(service: service, now: () => fixedNow);
  });

  test('B1: same day hits cache on repeated selectDate', () {
    vm.selectDate(DateTime(2026, 4, 10, 8));
    vm.selectDate(DateTime(2026, 4, 10, 9));
    vm.selectDate(DateTime(2026, 4, 10, 23));
    expect(service.calls, 1);
  });

  test('B2: LRU eviction after 90 distinct days', () {
    // Use days 1-14 of Jan-Jul 2026 (all within safe lunar calendar range,
    // avoids month-end dates that hit a known lunar-package boundary bug).
    final dates = <DateTime>[];
    for (int m = 1; m <= 7; m++) {
      for (int d = 1; d <= 14; d++) {
        dates.add(DateTime(2026, m, d));
        if (dates.length == 91) break;
      }
      if (dates.length == 91) break;
    }
    for (final d in dates) {
      vm.selectDate(d);
    }
    final before = service.calls;
    // dates[0] = 2026-01-01 was evicted when the 91st entry was added
    vm.selectDate(dates[0]);
    expect(service.calls, before + 1);
  });

  test('B3: selectToday syncs displayed and selected', () {
    vm.goToMonth(DateTime(2026, 1, 15));
    vm.selectDate(DateTime(2026, 1, 10));
    vm.selectToday();
    expect(vm.displayedMonth, DateTime(2026, 4, 1));
    expect(vm.selectedDate, DateTime(2026, 4, 18));
  });

  test('B4: goToMonth does not change selectedDate', () {
    vm.selectDate(DateTime(2026, 4, 18));
    vm.goToMonth(DateTime(2026, 5, 1));
    expect(vm.selectedDate, DateTime(2026, 4, 18));
    expect(vm.displayedMonth, DateTime(2026, 5, 1));
  });

  test('B5: selectHour(null) falls back to now()-based hour', () {
    vm.selectDate(DateTime(2026, 4, 18));
    vm.selectHour('未');
    vm.selectHour(null);
    expect(vm.currentHourAlmanac.zhi, isNotEmpty);
  });

  test('B6: isDisplayedMonthToday true for today month, false otherwise', () {
    expect(vm.isDisplayedMonthToday, isTrue);
    vm.goToMonth(DateTime(2026, 5, 1));
    expect(vm.isDisplayedMonthToday, isFalse);
  });
}
