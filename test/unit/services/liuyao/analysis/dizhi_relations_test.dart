import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/tables/dizhi_relations.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

void main() {
  group('DiZhiRelations 六合', () {
    test('六组六合对判定为真', () {
      expect(DiZhiRelations.isLiuHe('子', '丑'), isTrue);
      expect(DiZhiRelations.isLiuHe('寅', '亥'), isTrue);
      expect(DiZhiRelations.isLiuHe('卯', '戌'), isTrue);
      expect(DiZhiRelations.isLiuHe('辰', '酉'), isTrue);
      expect(DiZhiRelations.isLiuHe('巳', '申'), isTrue);
      expect(DiZhiRelations.isLiuHe('午', '未'), isTrue);
    });

    test('六合对称且非合组合为假', () {
      expect(DiZhiRelations.isLiuHe('丑', '子'), isTrue);
      expect(DiZhiRelations.isLiuHe('子', '午'), isFalse);
      expect(DiZhiRelations.isLiuHe('子', '子'), isFalse);
    });

    test('getLiuHe 返回合支', () {
      expect(DiZhiRelations.getLiuHe('卯'), '戌');
      expect(DiZhiRelations.getLiuHe('戌'), '卯');
    });

    test('六合化气', () {
      expect(DiZhiRelations.getLiuHeHua('卯', '戌'), WuXing.huo);
      expect(DiZhiRelations.getLiuHeHua('戌', '卯'), WuXing.huo);
      expect(DiZhiRelations.getLiuHeHua('子', '丑'), WuXing.tu);
      expect(DiZhiRelations.getLiuHeHua('寅', '亥'), WuXing.mu);
      expect(DiZhiRelations.getLiuHeHua('辰', '酉'), WuXing.jin);
      expect(DiZhiRelations.getLiuHeHua('巳', '申'), WuXing.shui);
      expect(DiZhiRelations.getLiuHeHua('子', '午'), isNull);
    });
  });

  group('DiZhiRelations 六冲', () {
    test('六组六冲对判定为真', () {
      expect(DiZhiRelations.isLiuChong('子', '午'), isTrue);
      expect(DiZhiRelations.isLiuChong('丑', '未'), isTrue);
      expect(DiZhiRelations.isLiuChong('寅', '申'), isTrue);
      expect(DiZhiRelations.isLiuChong('卯', '酉'), isTrue);
      expect(DiZhiRelations.isLiuChong('辰', '戌'), isTrue);
      expect(DiZhiRelations.isLiuChong('巳', '亥'), isTrue);
    });

    test('六冲对称且非冲组合为假', () {
      expect(DiZhiRelations.isLiuChong('午', '子'), isTrue);
      expect(DiZhiRelations.isLiuChong('子', '丑'), isFalse);
    });

    test('getLiuChong 返回冲支', () {
      expect(DiZhiRelations.getLiuChong('辰'), '戌');
      expect(DiZhiRelations.getLiuChong('亥'), '巳');
    });
  });

  group('DiZhiRelations 三合局', () {
    test('四组三合局判定五行正确', () {
      expect(DiZhiRelations.getSanHeElement('申', '子', '辰'), WuXing.shui);
      expect(DiZhiRelations.getSanHeElement('亥', '卯', '未'), WuXing.mu);
      expect(DiZhiRelations.getSanHeElement('寅', '午', '戌'), WuXing.huo);
      expect(DiZhiRelations.getSanHeElement('巳', '酉', '丑'), WuXing.jin);
    });

    test('三合局与输入顺序无关', () {
      expect(DiZhiRelations.getSanHeElement('辰', '申', '子'), WuXing.shui);
      expect(DiZhiRelations.getSanHeElement('午', '戌', '寅'), WuXing.huo);
    });

    test('非三合组合返回 null', () {
      expect(DiZhiRelations.getSanHeElement('子', '丑', '寅'), isNull);
      expect(DiZhiRelations.getSanHeElement('申', '子', '子'), isNull);
    });

    test('getSanHeGroup 返回长生-帝旺-墓三支', () {
      expect(DiZhiRelations.getSanHeGroup(WuXing.shui), ['申', '子', '辰']);
      expect(DiZhiRelations.getSanHeGroup(WuXing.jin), ['巳', '酉', '丑']);
      expect(DiZhiRelations.getSanHeGroup(WuXing.tu), isNull); // 土无三合局
    });
  });

  group('DiZhiRelations 半合', () {
    test('含旺支的半合成立', () {
      // 水局旺支为子：申子、子辰为半合
      expect(DiZhiRelations.getBanHeElement('申', '子'), WuXing.shui);
      expect(DiZhiRelations.getBanHeElement('子', '辰'), WuXing.shui);
      expect(DiZhiRelations.getBanHeElement('卯', '未'), WuXing.mu);
      expect(DiZhiRelations.getBanHeElement('寅', '午'), WuXing.huo);
    });

    test('不含旺支（拱局两端）不算半合', () {
      // 申辰缺子（旺支）不成半合
      expect(DiZhiRelations.getBanHeElement('申', '辰'), isNull);
      expect(DiZhiRelations.getBanHeElement('巳', '丑'), isNull);
    });

    test('无关组合返回 null', () {
      expect(DiZhiRelations.getBanHeElement('子', '午'), isNull);
    });
  });

  group('DiZhiRelations 三刑与相害', () {
    test('寅巳申、丑戌未须三支齐全才成三刑', () {
      expect(DiZhiRelations.isXing('寅', '巳'), isFalse);
      expect(DiZhiRelations.isXing('巳', '申'), isFalse);
      expect(DiZhiRelations.isXing('寅', '申'), isFalse);
      expect(DiZhiRelations.isXing('丑', '戌'), isFalse);
      expect(DiZhiRelations.isXing('戌', '未'), isFalse);
      expect(DiZhiRelations.isSanXing('寅', '巳', '申'), isTrue);
      expect(DiZhiRelations.isSanXing('未', '丑', '戌'), isTrue);
      expect(DiZhiRelations.isSanXing('寅', '巳', '卯'), isFalse);
    });

    test('子卯可独立论刑', () {
      expect(DiZhiRelations.isXing('子', '卯'), isTrue);
      expect(DiZhiRelations.isXing('卯', '子'), isTrue);
    });

    test('自刑：辰午酉亥', () {
      expect(DiZhiRelations.isZiXing('辰'), isTrue);
      expect(DiZhiRelations.isZiXing('午'), isTrue);
      expect(DiZhiRelations.isZiXing('酉'), isTrue);
      expect(DiZhiRelations.isZiXing('亥'), isTrue);
      expect(DiZhiRelations.isZiXing('子'), isFalse);
      // 自刑需同支
      expect(DiZhiRelations.isXing('辰', '辰'), isTrue);
      expect(DiZhiRelations.isXing('子', '子'), isFalse);
    });

    test('非刑组合为假', () {
      expect(DiZhiRelations.isXing('子', '丑'), isFalse);
      expect(DiZhiRelations.isXing('寅', '卯'), isFalse);
    });

    test('六组相害对', () {
      expect(DiZhiRelations.isHai('子', '未'), isTrue);
      expect(DiZhiRelations.isHai('丑', '午'), isTrue);
      expect(DiZhiRelations.isHai('寅', '巳'), isTrue);
      expect(DiZhiRelations.isHai('卯', '辰'), isTrue);
      expect(DiZhiRelations.isHai('申', '亥'), isTrue);
      expect(DiZhiRelations.isHai('酉', '戌'), isTrue);
      expect(DiZhiRelations.isHai('未', '子'), isTrue);
      expect(DiZhiRelations.isHai('子', '丑'), isFalse);
    });
  });
}
