import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';

void main() {
  group('GuaCalculator Tests', () {
    test('calculateGua should return 6 yaos', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);
      expect(gua.yaos.length, 6);
    });

    test('calculateGua for 乾为天 (all yang)', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '乾为天');
      expect(gua.id, '111111');
      expect(gua.baGong, BaGong.qian);
      expect(gua.seYaoPosition, 6);
      expect(gua.yingYaoPosition, 3);
    });

    test('calculateGua for 坤为地 (all yin)', () {
      final yaoNumbers = [8, 8, 8, 8, 8, 8];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '坤为地');
      expect(gua.id, '000000');
      expect(gua.baGong, BaGong.kun);
      expect(gua.seYaoPosition, 6);
      expect(gua.yingYaoPosition, 3);
    });

    test('calculateGua for 震为雷', () {
      final yaoNumbers = [7, 8, 8, 7, 8, 8];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '震为雷');
      expect(gua.id, '100100');
      expect(gua.baGong, BaGong.zhen);
    });

    test('calculateGua should set correct yao positions', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      for (int i = 0; i < 6; i++) {
        expect(gua.yaos[i].position, i + 1);
      }
    });

    test('calculateGua should identify moving yaos', () {
      final yaoNumbers = [6, 7, 9, 8, 7, 8];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].isMoving, true);
      expect(gua.yaos[1].isMoving, false);
      expect(gua.yaos[2].isMoving, true);
      expect(gua.yaos[3].isMoving, false);
    });

    test('calculateGua should set seYao and yingYao correctly', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[5].isSeYao, true);
      expect(gua.yaos[2].isYingYao, true);
      expect(gua.seYao.position, 6);
      expect(gua.yingYao.position, 3);
    });

    test('calculateGua for 地天泰', () {
      final yaoNumbers = [7, 7, 7, 8, 8, 8];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '地天泰');
      expect(gua.id, '111000');
      expect(gua.baGong, BaGong.kun);
      expect(gua.seYaoPosition, 3);
      expect(gua.yingYaoPosition, 6);
      expect(gua.yaos[0].branch, '子');
      expect(gua.yaos[3].branch, '丑');
      expect(gua.yaos[3].stem, '癸');
    });

    test('calculateGua should assign correct branches for 乾卦', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].branch, '子');
      expect(gua.yaos[1].branch, '寅');
      expect(gua.yaos[2].branch, '辰');
      expect(gua.yaos[3].branch, '午');
      expect(gua.yaos[4].branch, '申');
      expect(gua.yaos[5].branch, '戌');
    });

    test('calculateGua should assign correct stems for 乾卦', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].stem, '甲');
      expect(gua.yaos[3].stem, '壬');
    });

    test('calculateGua should assign correct wuxing', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].wuXing, WuXing.shui);
      expect(gua.yaos[1].wuXing, WuXing.mu);
      expect(gua.yaos[3].wuXing, WuXing.huo);
      expect(gua.yaos[4].wuXing, WuXing.jin);
    });

    test('calculateGua should assign correct liuqin for 乾卦', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].liuQin, LiuQin.ziSun);
      expect(gua.yaos[4].liuQin, LiuQin.xiongDi);
    });

    test('generateChangingGua should return null when no moving yao', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua, null);
    });

    test('generateChangingGua should generate correct changing gua', () {
      final yaoNumbers = [6, 7, 7, 7, 7, 7];
      final mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua, isNotNull);
      expect(changingGua!.yaos[0].number, YaoNumber.shaoYang);
      expect(changingGua.yaos[1].number, YaoNumber.shaoYang);
    });

    test('generateChangingGua should change laoYin to shaoYang', () {
      final yaoNumbers = [6, 8, 8, 8, 8, 8];
      final mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua!.yaos[0].number.value, 7);
    });

    test('generateChangingGua should change laoYang to shaoYin', () {
      final yaoNumbers = [9, 7, 7, 7, 7, 7];
      final mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua!.yaos[0].number.value, 8);
    });

    test('changing gua liuqin should reference main gua baGong', () {
      final yaoNumbers = [9, 7, 7, 8, 8, 8];
      final mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final changingGua = GuaCalculator.generateChangingGua(mainGua)!;

      expect(mainGua.baGong, BaGong.kun);
      expect(changingGua.baGong, isNot(mainGua.baGong));

      final expected = LiuQinService.calculateLiuQinByGongName(
        '坤',
        changingGua.yaos.first.wuXing,
      );

      expect(expected, isNotNull);
      expect(changingGua.yaos.first.liuQin, expected);
    });

    test('hasMovingYao should return true when has moving yao', () {
      final yaoNumbers = [6, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.hasMovingYao, true);
    });

    test('hasMovingYao should return false when no moving yao', () {
      final yaoNumbers = [7, 7, 7, 7, 7, 7];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.hasMovingYao, false);
    });

    test('movingYaos should return correct list', () {
      final yaoNumbers = [6, 7, 9, 8, 7, 8];
      final gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.movingYaos.length, 2);
      expect(gua.movingYaos[0].position, 1);
      expect(gua.movingYaos[1].position, 3);
    });

    test('calculateGua should throw when input length invalid', () {
      expect(() => GuaCalculator.calculateGua([7, 7, 7]), throwsArgumentError);
    });
  });
}

