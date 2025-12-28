import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liushen_service.dart';

void main() {
  group('LiuShenService Tests', () {
    test('calculateLiuShen should return 6 liushen', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('甲');
      expect(liuShen.length, 6);
    });

    test('calculateLiuShen for 甲日 should start with 青龙', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('甲');
      expect(liuShen, <String>['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武']);
    });

    test('calculateLiuShen for 乙日 should start with 青龙', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('乙');
      expect(liuShen, <String>['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武']);
    });

    test('calculateLiuShen for 丙日 should start with 朱雀', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('丙');
      expect(liuShen, <String>['朱雀', '勾陈', '腾蛇', '白虎', '玄武', '青龙']);
    });

    test('calculateLiuShen for 丁日 should start with 朱雀', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('丁');
      expect(liuShen, <String>['朱雀', '勾陈', '腾蛇', '白虎', '玄武', '青龙']);
    });

    test('calculateLiuShen for 戊日 should start with 腾蛇', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('戊');
      expect(liuShen, <String>['腾蛇', '白虎', '玄武', '青龙', '朱雀', '勾陈']);
    });

    test('calculateLiuShen for 己日 should start with 腾蛇', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('己');
      expect(liuShen, <String>['腾蛇', '白虎', '玄武', '青龙', '朱雀', '勾陈']);
    });

    test('calculateLiuShen for 庚日 should start with 白虎', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('庚');
      expect(liuShen, <String>['白虎', '玄武', '青龙', '朱雀', '勾陈', '腾蛇']);
    });

    test('calculateLiuShen for 辛日 should start with 白虎', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('辛');
      expect(liuShen, <String>['白虎', '玄武', '青龙', '朱雀', '勾陈', '腾蛇']);
    });

    test('calculateLiuShen for 壬日 should start with 玄武', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('壬');
      expect(liuShen, <String>['玄武', '青龙', '朱雀', '勾陈', '腾蛇', '白虎']);
    });

    test('calculateLiuShen for 癸日 should start with 玄武', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('癸');
      expect(liuShen, <String>['玄武', '青龙', '朱雀', '勾陈', '腾蛇', '白虎']);
    });

    test('calculateLiuShen should handle invalid dayGan gracefully', () {
      final List<String> liuShen = LiuShenService.calculateLiuShen('无效');
      expect(liuShen.length, 6);
      expect(liuShen[0], '青龙');
    });
  });
}

