import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';

void main() {
  final service = AlmanacService();

  group('AlmanacService.getDay - normalization (A1)', () {
    test('same day different times produce equal result', () {
      final a = service.getDay(DateTime(2026, 4, 18, 0, 0));
      final b = service.getDay(DateTime(2026, 4, 18, 23, 59, 59));
      expect(a, equals(b));
    });
  });

  group('AlmanacService.getDay - solar term boundary (A2)', () {
    test('monthGZ is stable across same-day hours around 交节', () {
      final before = service.getDay(DateTime(2026, 4, 5, 4));
      final after = service.getDay(DateTime(2026, 4, 5, 6));
      expect(before.monthGZ, equals(after.monthGZ),
          reason: 'normalization 到午夜后两个调用应等价');
    });
  });

  group('AlmanacService.getDay - zi shi cross-day (A3)', () {
    test('twelveHours last slot (zi) ganZhi uses Exact2', () {
      final a = service.getDay(DateTime(2026, 4, 18));
      final ziHour = a.twelveHours.firstWhere((h) => h.zhi == '子');
      expect(ziHour.ganZhi.length, 2);
      expect(ziHour.tianShen, isNotEmpty);
      expect(ziHour.huangHei, anyOf('黄', '黑'));
    });
  });

  group('AlmanacService.getDay - 春节 (A4)', () {
    test('春节日 has festival and lunar date 正月初一', () {
      final d = DateTime(2026, 2, 17);
      final a = service.getDay(d);
      expect(a.festivals, contains('春节'));
      expect(a.lunarDate, contains('正月'));
      expect(a.yearGZ, isNotEmpty);
    });
  });

  group('AlmanacService.getDay - 闰月 (A5)', () {
    test('2025 闰六月某日 lunarDate 含"闰六月"', () {
      // 2025 年农历闰六月：公历 2025-07-25 ~ 2025-08-22
      // 使用 2025-08-01 作为可靠的闰六月日期
      final d = DateTime(2025, 8, 1);
      final a = service.getDay(d);
      expect(a.lunarDate, contains('闰六月'));
    });
  });

  group('AlmanacService.getDay - out of range (A7)', () {
    test('year < 1900 throws AlmanacError', () {
      expect(
        () => service.getDay(DateTime(1800, 1, 1)),
        throwsA(isA<AlmanacError>()),
      );
    });
    test('year > 2099 throws AlmanacError', () {
      expect(
        () => service.getDay(DateTime(2200, 1, 1)),
        throwsA(isA<AlmanacError>()),
      );
    });
  });

  group('AlmanacService.getDay - 12 hours shape (A8)', () {
    test('twelveHours has 12 slots with all fields', () {
      final a = service.getDay(DateTime(2026, 4, 18));
      expect(a.twelveHours.length, 12);
      for (final h in a.twelveHours) {
        expect(h.zhi, isNotEmpty);
        expect(h.ganZhi.length, 2);
        expect(h.tianShen, isNotEmpty);
        expect(h.huangHei, anyOf('黄', '黑'));
        expect(h.luck, anyOf('吉', '凶'));
        expect(h.startHour, inInclusiveRange(0, 23));
        expect(h.endHour, inInclusiveRange(0, 23));
      }
    });
  });
}
