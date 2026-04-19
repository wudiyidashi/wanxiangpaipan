import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../domain/services/shared/almanac_service.dart';
import '../../../models/daily_almanac.dart';

class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required AlmanacService service,
    DateTime Function()? now,
  })  : _service = service,
        _now = now ?? DateTime.now {
    final today = _dateOnly(_now());
    _selectedDate = today;
    _displayedMonth = DateTime(today.year, today.month, 1);
  }

  static const int _cacheCap = 90;

  // 将 DateTime.hour (0..23) 映射到对应时辰地支
  // 0: 子, 1-2: 丑, 3-4: 寅, 5-6: 卯, 7-8: 辰, 9-10: 巳,
  // 11-12: 午, 13-14: 未, 15-16: 申, 17-18: 酉, 19-20: 戌, 21-22: 亥, 23: 子
  static const _zhiByHour = [
    '子', '丑', '丑', '寅', '寅', '卯', '卯', '辰', '辰', '巳', '巳',
    '午', '午', '未', '未', '申', '申', '酉', '酉', '戌', '戌', '亥', '亥', '子',
  ];

  final AlmanacService _service;
  final DateTime Function() _now;
  final LinkedHashMap<DateTime, DailyAlmanac> _cache = LinkedHashMap();

  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  String? _selectedHour;

  DateTime get displayedMonth => _displayedMonth;
  DateTime get selectedDate => _selectedDate;
  String? get selectedHour => _selectedHour;

  void selectDate(DateTime date) {
    final d = _dateOnly(date);
    if (d == _selectedDate) return;
    _selectedDate = d;
    _prime(d);
    notifyListeners();
  }

  void selectHour(String? zhi) {
    _selectedHour = zhi;
    notifyListeners();
  }

  void goToMonth(DateTime anyDateInMonth) {
    var m = DateTime(anyDateInMonth.year, anyDateInMonth.month, 1);
    if (m.year < 1900) m = DateTime(1900, 1, 1);
    if (m.year > 2099) m = DateTime(2099, 12, 1);
    if (m == _displayedMonth) return;
    _displayedMonth = m;
    notifyListeners();
  }

  void selectToday() {
    final today = _dateOnly(_now());
    _selectedDate = today;
    _displayedMonth = DateTime(today.year, today.month, 1);
    _selectedHour = null;
    _prime(today);
    notifyListeners();
  }

  DailyAlmanac get currentAlmanac {
    _prime(_selectedDate);
    return _cache[_selectedDate]!;
  }

  HourAlmanac get currentHourAlmanac {
    final hours = currentAlmanac.twelveHours;
    if (_selectedHour != null) {
      return hours.firstWhere(
        (h) => h.zhi == _selectedHour,
        orElse: () => hours.first,
      );
    }
    final nowHour = _now().hour;
    final zhi = _zhiByHour[nowHour];
    return hours.firstWhere((h) => h.zhi == zhi, orElse: () => hours.first);
  }

  bool get isDisplayedMonthToday {
    final today = _dateOnly(_now());
    return _displayedMonth.year == today.year &&
        _displayedMonth.month == today.month;
  }

  void _prime(DateTime d) {
    if (_cache.containsKey(d)) {
      // Move to tail (most-recently-used)
      final v = _cache.remove(d);
      _cache[d] = v!;
      return;
    }
    _cache[d] = _service.getDay(d);
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    while (_cache.length > _cacheCap) {
      _cache.remove(_cache.keys.first);
    }
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
