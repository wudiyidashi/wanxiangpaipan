import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';

void main() {
  group('LunarService Tests', () {
    test('getLunarInfo should return correct lunar info for 2025-01-14', () {
      final dateTime = DateTime(2025, 1, 14);
      final lunarInfo = LunarService.getLunarInfo(dateTime);

      expect(lunarInfo.riGan, isNotEmpty);
      expect(lunarInfo.riZhi, isNotEmpty);
      expect(lunarInfo.riGanZhi, isNotEmpty);
      expect(lunarInfo.yueJian, isNotEmpty);
      expect(lunarInfo.yearGanZhi, isNotEmpty);
      expect(lunarInfo.monthGanZhi, isNotEmpty);
      expect(lunarInfo.kongWang.length, 2);
      expect(lunarInfo.riGanZhi.length, 2);
    });

    test('getLunarInfo should calculate kongWang correctly', () {
      final dateTime = DateTime(2025, 1, 14);
      final lunarInfo = LunarService.getLunarInfo(dateTime);

      expect(lunarInfo.kongWang.length, 2);

      const validBranches = ['子', '丑', '寅', '卯', '辰', '巳',
                             '午', '未', '申', '酉', '戌', '亥'];
      expect(validBranches.contains(lunarInfo.kongWang[0]), true);
      expect(validBranches.contains(lunarInfo.kongWang[1]), true);
    });

    test('getDayGan should return correct day stem', () {
      final dateTime = DateTime(2025, 1, 14);
      final dayGan = LunarService.getDayGan(dateTime);

      const validGans = ['甲', '乙', '丙', '丁', '戊',
                         '己', '庚', '辛', '壬', '癸'];
      expect(validGans.contains(dayGan), true);
    });

    test('getLunarInfo should handle spring festival correctly', () {
      final springFestival = DateTime(2024, 2, 10);
      final lunarInfo = LunarService.getLunarInfo(springFestival);

      expect(lunarInfo.yearGanZhi, isNotEmpty);
      expect(lunarInfo.monthGanZhi, isNotEmpty);
    });

    test('getLunarInfo should handle solar terms correctly', () {
      final summerSolstice = DateTime(2024, 6, 21);
      final lunarInfo = LunarService.getLunarInfo(summerSolstice);

      expect(lunarInfo.solarTerm, isNotNull);
    });

    test('getLunarInfo should handle year boundary correctly', () {
      final newYear = DateTime(2024, 1, 1);
      final lunarInfo = LunarService.getLunarInfo(newYear);

      expect(lunarInfo.yearGanZhi, isNotEmpty);
      expect(lunarInfo.monthGanZhi, isNotEmpty);
    });

    test('isKongWang method should work correctly', () {
      final dateTime = DateTime(2025, 1, 14);
      final lunarInfo = LunarService.getLunarInfo(dateTime);

      expect(lunarInfo.isKongWang(lunarInfo.kongWang[0]), true);
      expect(lunarInfo.isKongWang(lunarInfo.kongWang[1]), true);
    });

    test('getDayGan should return consistent results', () {
      final dateTime = DateTime(2025, 1, 14);
      final dayGan1 = LunarService.getDayGan(dateTime);
      final dayGan2 = LunarService.getDayGan(dateTime);

      expect(dayGan1, dayGan2);
    });
  });
}

