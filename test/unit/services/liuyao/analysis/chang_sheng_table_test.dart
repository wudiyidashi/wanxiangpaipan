import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/tables/chang_sheng_table.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

void main() {
  group('ChangShengTable 长生/帝旺/墓/绝', () {
    test('金：长生巳 帝旺酉 墓丑 绝寅', () {
      expect(ChangShengTable.getStage(WuXing.jin, '巳'),
          ChangShengStage.changSheng);
      expect(ChangShengTable.getStage(WuXing.jin, '酉'), ChangShengStage.diWang);
      expect(ChangShengTable.getStage(WuXing.jin, '丑'), ChangShengStage.mu);
      expect(ChangShengTable.getStage(WuXing.jin, '寅'), ChangShengStage.jue);
    });

    test('木：长生亥 帝旺卯 墓未 绝申', () {
      expect(
          ChangShengTable.getStage(WuXing.mu, '亥'), ChangShengStage.changSheng);
      expect(ChangShengTable.getStage(WuXing.mu, '卯'), ChangShengStage.diWang);
      expect(ChangShengTable.getStage(WuXing.mu, '未'), ChangShengStage.mu);
      expect(ChangShengTable.getStage(WuXing.mu, '申'), ChangShengStage.jue);
    });

    test('火：长生寅 帝旺午 墓戌 绝亥', () {
      expect(ChangShengTable.getStage(WuXing.huo, '寅'),
          ChangShengStage.changSheng);
      expect(ChangShengTable.getStage(WuXing.huo, '午'), ChangShengStage.diWang);
      expect(ChangShengTable.getStage(WuXing.huo, '戌'), ChangShengStage.mu);
      expect(ChangShengTable.getStage(WuXing.huo, '亥'), ChangShengStage.jue);
    });

    test('水：长生申 帝旺子 墓辰 绝巳', () {
      expect(ChangShengTable.getStage(WuXing.shui, '申'),
          ChangShengStage.changSheng);
      expect(
          ChangShengTable.getStage(WuXing.shui, '子'), ChangShengStage.diWang);
      expect(ChangShengTable.getStage(WuXing.shui, '辰'), ChangShengStage.mu);
      expect(ChangShengTable.getStage(WuXing.shui, '巳'), ChangShengStage.jue);
    });

    test('土：水土同宫（长生申 墓辰 绝巳）', () {
      expect(
          ChangShengTable.getStage(WuXing.tu, '申'), ChangShengStage.changSheng);
      expect(ChangShengTable.getStage(WuXing.tu, '辰'), ChangShengStage.mu);
      expect(ChangShengTable.getStage(WuXing.tu, '巳'), ChangShengStage.jue);
    });

    test('十二阶段完整顺行（以金为例）', () {
      const branches = [
        '巳',
        '午',
        '未',
        '申',
        '酉',
        '戌',
        '亥',
        '子',
        '丑',
        '寅',
        '卯',
        '辰'
      ];
      for (var i = 0; i < 12; i++) {
        expect(ChangShengTable.getStage(WuXing.jin, branches[i]),
            ChangShengStage.values[i],
            reason: '金在${branches[i]}应为第$i阶段');
      }
    });

    test('快捷方法：墓支与绝支', () {
      expect(ChangShengTable.getMuBranch(WuXing.jin), '丑');
      expect(ChangShengTable.getMuBranch(WuXing.mu), '未');
      expect(ChangShengTable.getMuBranch(WuXing.huo), '戌');
      expect(ChangShengTable.getMuBranch(WuXing.shui), '辰');
      expect(ChangShengTable.getMuBranch(WuXing.tu), '辰');
      expect(ChangShengTable.getJueBranch(WuXing.huo), '亥');
      expect(ChangShengTable.getJueBranch(WuXing.shui), '巳');
    });

    test('isMu / isJue 判定', () {
      expect(ChangShengTable.isMu(WuXing.huo, '戌'), isTrue);
      expect(ChangShengTable.isMu(WuXing.huo, '辰'), isFalse);
      expect(ChangShengTable.isJue(WuXing.mu, '申'), isTrue);
      expect(ChangShengTable.isJue(WuXing.mu, '酉'), isFalse);
    });
  });
}
