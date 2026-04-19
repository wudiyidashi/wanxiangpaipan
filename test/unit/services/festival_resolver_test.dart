import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';
import 'package:wanxiang_paipan/domain/services/shared/festival_resolver.dart';

Lunar _lunarOf(DateTime d) => Solar.fromDate(d).getLunar();

void main() {
  group('FestivalResolver', () {
    test('returns 春节 on lunar new year day 2026-02-17', () {
      final d = DateTime(2026, 2, 17);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, contains('春节'));
    });

    test('returns 元旦节 on 2026-01-01', () {
      final d = DateTime(2026, 1, 1);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, contains('元旦节'));
    });

    test('returns 国庆节 on 2026-10-01', () {
      final d = DateTime(2026, 10, 1);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, contains('国庆节'));
    });

    test('returns empty list on ordinary day 2026-04-20', () {
      final d = DateTime(2026, 4, 20);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, isEmpty);
    });

    test('returns unique names without duplicates', () {
      final d = DateTime(2026, 1, 1);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result.length, result.toSet().length,
          reason: '合并后应去重');
    });
  });
}
