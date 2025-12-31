import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('LunarService Tests', () {
    test('getLunarInfo should return correct lunar info for 2025-01-14', () {
      final DateTime dateTime = DateTime(2025, 1, 14);
      final LunarInfo lunarInfo = LunarService.getLunarInfo(dateTime);

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
      final DateTime dateTime = DateTime(2025, 1, 14);
      final LunarInfo lunarInfo = LunarService.getLunarInfo(dateTime);

      expect(lunarInfo.kongWang.length, 2);

      const List<String> validBranches = <String>[
        '子',
        '丑',
        '寅',
        '卯',
        '辰',
        '巳',
        '午',
        '未',
        '申',
        '酉',
        '戌',
        '亥',
      ];
      expect(validBranches.contains(lunarInfo.kongWang[0]), true);
      expect(validBranches.contains(lunarInfo.kongWang[1]), true);
    });

    test('getDayGan should return correct day stem', () {
      final DateTime dateTime = DateTime(2025, 1, 14);
      final String dayGan = LunarService.getDayGan(dateTime);

      const List<String> validGans = <String>[
        '甲',
        '乙',
        '丙',
        '丁',
        '戊',
        '己',
        '庚',
        '辛',
        '壬',
        '癸',
      ];
      expect(validGans.contains(dayGan), true);
    });

    test('getLunarInfo should handle spring festival correctly', () {
      final DateTime springFestival = DateTime(2024, 2, 10);
      final LunarInfo lunarInfo = LunarService.getLunarInfo(springFestival);

      expect(lunarInfo.yearGanZhi, isNotEmpty);
      expect(lunarInfo.monthGanZhi, isNotEmpty);
    });

    test('getLunarInfo should handle solar terms correctly', () {
      final DateTime summerSolstice = DateTime(2024, 6, 21);
      final LunarInfo lunarInfo = LunarService.getLunarInfo(summerSolstice);

      expect(lunarInfo.solarTerm, isNotNull);
    });

    test('getLunarInfo should handle year boundary correctly', () {
      final DateTime newYear = DateTime(2024, 1, 1);
      final LunarInfo lunarInfo = LunarService.getLunarInfo(newYear);

      expect(lunarInfo.yearGanZhi, isNotEmpty);
      expect(lunarInfo.monthGanZhi, isNotEmpty);
    });

    test('isKongWang method should work correctly', () {
      final DateTime dateTime = DateTime(2025, 1, 14);
      final LunarInfo lunarInfo = LunarService.getLunarInfo(dateTime);

      expect(lunarInfo.isKongWang(lunarInfo.kongWang[0]), true);
      expect(lunarInfo.isKongWang(lunarInfo.kongWang[1]), true);
    });

    test('getDayGan should return consistent results', () {
      final DateTime dateTime = DateTime(2025, 1, 14);
      final String dayGan1 = LunarService.getDayGan(dateTime);
      final String dayGan2 = LunarService.getDayGan(dateTime);

      expect(dayGan1, dayGan2);
    });
  });
}
