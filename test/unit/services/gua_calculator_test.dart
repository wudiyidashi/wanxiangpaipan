import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';

void main() {
  group('GuaCalculator Tests', () {
    test('calculateGua should return 6 yaos', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);
      expect(gua.yaos.length, 6);
    });

    test('calculateGua for 乾为天 (all yang)', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '乾为天');
      expect(gua.id, '111111');
      expect(gua.baGong, BaGong.qian);
      expect(gua.seYaoPosition, 6);
      expect(gua.yingYaoPosition, 3);
    });

    test('calculateGua for 坤为地 (all yin)', () {
      final List<int> yaoNumbers = <int>[8, 8, 8, 8, 8, 8];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '坤为地');
      expect(gua.id, '000000');
      expect(gua.baGong, BaGong.kun);
      expect(gua.seYaoPosition, 6);
      expect(gua.yingYaoPosition, 3);
    });

    test('calculateGua for 震为雷', () {
      final List<int> yaoNumbers = <int>[7, 8, 8, 7, 8, 8];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.name, '震为雷');
      expect(gua.id, '100100');
      expect(gua.baGong, BaGong.zhen);
    });

    test('calculateGua should set correct yao positions', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      for (int i = 0; i < 6; i++) {
        expect(gua.yaos[i].position, i + 1);
      }
    });

    test('calculateGua should identify moving yaos', () {
      final List<int> yaoNumbers = <int>[6, 7, 9, 8, 7, 8];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].isMoving, true);
      expect(gua.yaos[1].isMoving, false);
      expect(gua.yaos[2].isMoving, true);
      expect(gua.yaos[3].isMoving, false);
    });

    test('calculateGua should set seYao and yingYao correctly', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[5].isSeYao, true);
      expect(gua.yaos[2].isYingYao, true);
      expect(gua.seYao.position, 6);
      expect(gua.yingYao.position, 3);
    });

    test('calculateGua for 地天泰', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 8, 8, 8];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

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
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].branch, '子');
      expect(gua.yaos[1].branch, '寅');
      expect(gua.yaos[2].branch, '辰');
      expect(gua.yaos[3].branch, '午');
      expect(gua.yaos[4].branch, '申');
      expect(gua.yaos[5].branch, '戌');
    });

    test('calculateGua should assign correct stems for 乾卦', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].stem, '甲');
      expect(gua.yaos[3].stem, '壬');
    });

    test('all 64 gua should use the canonical inner and outer Na Jia', () {
      for (var value = 0; value < 64; value++) {
        final guaId = value.toRadixString(2).padLeft(6, '0');
        final yaoNumbers = guaId
            .split('')
            .map((bit) => bit == '1' ? 7 : 8)
            .toList(growable: false);
        final gua = GuaCalculator.calculateGua(yaoNumbers);
        final lowerTrigram = guaId.substring(0, 3);
        final upperTrigram = guaId.substring(3, 6);

        expect(
          gua.yaos.map((yao) => yao.branch).toList(),
          <String>[
            ..._innerBranches[lowerTrigram]!,
            ..._outerBranches[upperTrigram]!,
          ],
          reason: '$guaId ${gua.name} 的纳甲地支错误',
        );
        expect(
          gua.yaos.map((yao) => yao.stem).toList(),
          <String>[
            ...List.filled(3, _innerStems[lowerTrigram]!),
            ...List.filled(3, _outerStems[upperTrigram]!),
          ],
          reason: '$guaId ${gua.name} 的纳甲天干错误',
        );
      }
    });

    test('the eight Liu He gua should be identified correctly', () {
      const liuHeGuaIds = <String>{
        '111000', // 地天泰
        '000111', // 天地否
        '110010', // 水泽节
        '010110', // 泽水困
        '101001', // 山火贲
        '001101', // 火山旅
        '000100', // 雷地豫
        '100000', // 地雷复
      };

      for (var value = 0; value < 64; value++) {
        final guaId = value.toRadixString(2).padLeft(6, '0');
        final gua = GuaCalculator.calculateGua(
          guaId.split('').map((bit) => bit == '1' ? 7 : 8).toList(),
        );

        expect(
          gua.specialType == GuaSpecialType.liuHe,
          liuHeGuaIds.contains(guaId),
          reason: '${gua.name} 的六合标记错误',
        );
      }
    });

    test('calculateGua should assign correct wuxing', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].wuXing, WuXing.shui);
      expect(gua.yaos[1].wuXing, WuXing.mu);
      expect(gua.yaos[3].wuXing, WuXing.huo);
      expect(gua.yaos[4].wuXing, WuXing.jin);
    });

    test('calculateGua should assign correct liuqin for 乾卦', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.yaos[0].liuQin, LiuQin.ziSun);
      expect(gua.yaos[4].liuQin, LiuQin.xiongDi);
    });

    test('generateChangingGua should return null when no moving yao', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final Gua? changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua, null);
    });

    test('generateChangingGua should generate correct changing gua', () {
      final List<int> yaoNumbers = <int>[6, 7, 7, 7, 7, 7];
      final Gua mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final Gua? changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua, isNotNull);
      expect(changingGua!.yaos[0].number, YaoNumber.shaoYang);
      expect(changingGua.yaos[1].number, YaoNumber.shaoYang);
    });

    test('generateChangingGua should change laoYin to shaoYang', () {
      final List<int> yaoNumbers = <int>[6, 8, 8, 8, 8, 8];
      final Gua mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final Gua? changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua!.yaos[0].number.value, 7);
    });

    test('generateChangingGua should change laoYang to shaoYin', () {
      final List<int> yaoNumbers = <int>[9, 7, 7, 7, 7, 7];
      final Gua mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final Gua? changingGua = GuaCalculator.generateChangingGua(mainGua);

      expect(changingGua!.yaos[0].number.value, 8);
    });

    test('changing gua liuqin should reference main gua baGong', () {
      final List<int> yaoNumbers = <int>[9, 7, 7, 8, 8, 8];
      final Gua mainGua = GuaCalculator.calculateGua(yaoNumbers);
      final Gua changingGua = GuaCalculator.generateChangingGua(mainGua)!;

      expect(mainGua.baGong, BaGong.kun);
      expect(changingGua.baGong, isNot(mainGua.baGong));

      final LiuQin? expected = LiuQinService.calculateLiuQinByGongName(
        '坤',
        changingGua.yaos.first.wuXing,
      );

      expect(expected, isNotNull);
      expect(changingGua.yaos.first.liuQin, expected);
    });

    test('hasMovingYao should return true when has moving yao', () {
      final List<int> yaoNumbers = <int>[6, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.hasMovingYao, true);
    });

    test('hasMovingYao should return false when no moving yao', () {
      final List<int> yaoNumbers = <int>[7, 7, 7, 7, 7, 7];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.hasMovingYao, false);
    });

    test('movingYaos should return correct list', () {
      final List<int> yaoNumbers = <int>[6, 7, 9, 8, 7, 8];
      final Gua gua = GuaCalculator.calculateGua(yaoNumbers);

      expect(gua.movingYaos.length, 2);
      expect(gua.movingYaos[0].position, 1);
      expect(gua.movingYaos[1].position, 3);
    });

    test('calculateGua should throw when input length invalid', () {
      expect(
        () => GuaCalculator.calculateGua(<int>[7, 7, 7]),
        throwsArgumentError,
      );
    });
  });
}

const _innerBranches = <String, List<String>>{
  '111': ['子', '寅', '辰'],
  '110': ['巳', '卯', '丑'],
  '101': ['卯', '丑', '亥'],
  '100': ['子', '寅', '辰'],
  '011': ['丑', '亥', '酉'],
  '010': ['寅', '辰', '午'],
  '001': ['辰', '午', '申'],
  '000': ['未', '巳', '卯'],
};

const _outerBranches = <String, List<String>>{
  '111': ['午', '申', '戌'],
  '110': ['亥', '酉', '未'],
  '101': ['酉', '未', '巳'],
  '100': ['午', '申', '戌'],
  '011': ['未', '巳', '卯'],
  '010': ['申', '戌', '子'],
  '001': ['戌', '子', '寅'],
  '000': ['丑', '亥', '酉'],
};

const _innerStems = <String, String>{
  '111': '甲',
  '110': '丁',
  '101': '己',
  '100': '庚',
  '011': '辛',
  '010': '戊',
  '001': '丙',
  '000': '乙',
};

const _outerStems = <String, String>{
  '111': '壬',
  '110': '丁',
  '101': '己',
  '100': '庚',
  '011': '辛',
  '010': '戊',
  '001': '丙',
  '000': '癸',
};
