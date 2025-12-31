import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('LunarInfo Model Tests', () {
    test('should create LunarInfo with required fields', () {
      final lunarInfo = LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
      );

      expect(lunarInfo.yueJian, '寅');
      expect(lunarInfo.riGan, '甲');
      expect(lunarInfo.riZhi, '子');
      expect(lunarInfo.riGanZhi, '甲子');
      expect(lunarInfo.kongWang.length, 2);
    });

    test('should be immutable', () {
      final lunarInfo = LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
      );

      final lunarInfo2 = lunarInfo.copyWith(yueJian: '卯');
      expect(lunarInfo.yueJian, '寅');
      expect(lunarInfo2.yueJian, '卯');
    });

    test('should serialize to/from JSON', () {
      final lunarInfo = LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
        solarTerm: '立春',
      );

      final json = lunarInfo.toJson();
      final lunarInfo2 = LunarInfo.fromJson(json);

      expect(lunarInfo2, lunarInfo);
    });

    test('isKongWang should return true for empty branches', () {
      final lunarInfo = LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
      );

      expect(lunarInfo.isKongWang('戌'), true);
      expect(lunarInfo.isKongWang('亥'), true);
    });

    test('isKongWang should return false for non-empty branches', () {
      final lunarInfo = LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
      );

      expect(lunarInfo.isKongWang('子'), false);
      expect(lunarInfo.isKongWang('丑'), false);
    });

    test('should handle optional solarTerm field', () {
      final lunarInfo = LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
      );

      expect(lunarInfo.solarTerm, null);

      final lunarInfo2 = lunarInfo.copyWith(solarTerm: '立春');
      expect(lunarInfo2.solarTerm, '立春');
    });
  });
}
