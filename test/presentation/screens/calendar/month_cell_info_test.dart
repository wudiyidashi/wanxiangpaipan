import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/month_cell_info.dart';

void main() {
  group('MonthCellInfo.of', () {
    test('ordinary day has no dots', () {
      final info = MonthCellInfo.of(DateTime(2026, 4, 21));
      expect(info.hasJieQi, isFalse);
      expect(info.hasMoonPhase, isFalse);
      expect(info.hasFestival, isFalse);
    });

    test('solar term day has jieQi dot and label', () {
      // 清明 2026 约 4-05
      final info = MonthCellInfo.of(DateTime(2026, 4, 5));
      expect(info.hasJieQi, isTrue);
      expect(info.label, isNotEmpty);
    });

    test('2026-01-01 has festival dot (元旦)', () {
      final info = MonthCellInfo.of(DateTime(2026, 1, 1));
      expect(info.hasFestival, isTrue);
    });
  });
}
