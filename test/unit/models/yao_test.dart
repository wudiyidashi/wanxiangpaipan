import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';

void main() {
  group('Yao Model Tests', () {
    test('should create Yao with required fields', () {
      final yao = Yao(
        position: 1,
        number: YaoNumber.laoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: true,
        isYingYao: false,
      );

      expect(yao.position, 1);
      expect(yao.number, YaoNumber.laoYang);
      expect(yao.isSeYao, true);
      expect(yao.branch, '子');
    });

    test('should be immutable', () {
      final yao = Yao(
        position: 1,
        number: YaoNumber.laoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: true,
        isYingYao: false,
      );

      final yao2 = yao.copyWith(position: 2);
      expect(yao.position, 1);
      expect(yao2.position, 2);
    });

    test('should serialize to/from JSON', () {
      final yao = Yao(
        position: 1,
        number: YaoNumber.laoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: true,
        isYingYao: false,
      );

      final json = yao.toJson();
      final yao2 = Yao.fromJson(json);

      expect(yao2, yao);
    });

    test('isMoving should return true for laoYin and laoYang', () {
      final laoYang = Yao(
        position: 1,
        number: YaoNumber.laoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: false,
        isYingYao: false,
      );

      final laoYin = Yao(
        position: 2,
        number: YaoNumber.laoYin,
        branch: '丑',
        stem: '乙',
        liuQin: LiuQin.fuMu,
        wuXing: WuXing.tu,
        isSeYao: false,
        isYingYao: false,
      );

      expect(laoYang.isMoving, true);
      expect(laoYin.isMoving, true);
    });

    test('isMoving should return false for shaoYin and shaoYang', () {
      final shaoYang = Yao(
        position: 1,
        number: YaoNumber.shaoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: false,
        isYingYao: false,
      );

      final shaoYin = Yao(
        position: 2,
        number: YaoNumber.shaoYin,
        branch: '丑',
        stem: '乙',
        liuQin: LiuQin.fuMu,
        wuXing: WuXing.tu,
        isSeYao: false,
        isYingYao: false,
      );

      expect(shaoYang.isMoving, false);
      expect(shaoYin.isMoving, false);
    });

    test('isYin and isYang should work correctly', () {
      final yangYao = Yao(
        position: 1,
        number: YaoNumber.laoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: false,
        isYingYao: false,
      );

      final yinYao = Yao(
        position: 2,
        number: YaoNumber.laoYin,
        branch: '丑',
        stem: '乙',
        liuQin: LiuQin.fuMu,
        wuXing: WuXing.tu,
        isSeYao: false,
        isYingYao: false,
      );

      expect(yangYao.isYang, true);
      expect(yangYao.isYin, false);
      expect(yinYao.isYin, true);
      expect(yinYao.isYang, false);
    });

    test('toChangedYao should convert moving yao correctly', () {
      final laoYang = Yao(
        position: 1,
        number: YaoNumber.laoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: false,
        isYingYao: false,
      );

      final changed = laoYang.toChangedYao();
      expect(changed.number, YaoNumber.shaoYin);
    });

    test('toChangedYao should not change static yao', () {
      final shaoYang = Yao(
        position: 1,
        number: YaoNumber.shaoYang,
        branch: '子',
        stem: '甲',
        liuQin: LiuQin.ziSun,
        wuXing: WuXing.shui,
        isSeYao: false,
        isYingYao: false,
      );

      final changed = shaoYang.toChangedYao();
      expect(changed, shaoYang);
    });
  });
}
