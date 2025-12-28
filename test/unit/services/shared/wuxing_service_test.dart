import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

void main() {
  group('WuXingService Tests', () {
    group('getWuXingFromBranch', () {
      test('should return correct wuxing for water branches', () {
        expect(WuXingService.getWuXingFromBranch('子'), WuXing.shui);
        expect(WuXingService.getWuXingFromBranch('亥'), WuXing.shui);
      });

      test('should return correct wuxing for wood branches', () {
        expect(WuXingService.getWuXingFromBranch('寅'), WuXing.mu);
        expect(WuXingService.getWuXingFromBranch('卯'), WuXing.mu);
      });

      test('should return correct wuxing for fire branches', () {
        expect(WuXingService.getWuXingFromBranch('巳'), WuXing.huo);
        expect(WuXingService.getWuXingFromBranch('午'), WuXing.huo);
      });

      test('should return correct wuxing for metal branches', () {
        expect(WuXingService.getWuXingFromBranch('申'), WuXing.jin);
        expect(WuXingService.getWuXingFromBranch('酉'), WuXing.jin);
      });

      test('should return correct wuxing for earth branches', () {
        expect(WuXingService.getWuXingFromBranch('辰'), WuXing.tu);
        expect(WuXingService.getWuXingFromBranch('戌'), WuXing.tu);
        expect(WuXingService.getWuXingFromBranch('丑'), WuXing.tu);
        expect(WuXingService.getWuXingFromBranch('未'), WuXing.tu);
      });

      test('should return null for invalid branch', () {
        expect(WuXingService.getWuXingFromBranch('无效'), null);
      });
    });

    group('getWuXingFromStem', () {
      test('should return correct wuxing for wood stems', () {
        expect(WuXingService.getWuXingFromStem('甲'), WuXing.mu);
        expect(WuXingService.getWuXingFromStem('乙'), WuXing.mu);
      });

      test('should return correct wuxing for fire stems', () {
        expect(WuXingService.getWuXingFromStem('丙'), WuXing.huo);
        expect(WuXingService.getWuXingFromStem('丁'), WuXing.huo);
      });

      test('should return correct wuxing for earth stems', () {
        expect(WuXingService.getWuXingFromStem('戊'), WuXing.tu);
        expect(WuXingService.getWuXingFromStem('己'), WuXing.tu);
      });

      test('should return correct wuxing for metal stems', () {
        expect(WuXingService.getWuXingFromStem('庚'), WuXing.jin);
        expect(WuXingService.getWuXingFromStem('辛'), WuXing.jin);
      });

      test('should return correct wuxing for water stems', () {
        expect(WuXingService.getWuXingFromStem('壬'), WuXing.shui);
        expect(WuXingService.getWuXingFromStem('癸'), WuXing.shui);
      });

      test('should return null for invalid stem', () {
        expect(WuXingService.getWuXingFromStem('无效'), null);
      });
    });

    group('getRelation', () {
      test('should return biHe for same wuxing', () {
        expect(
          WuXingService.getRelation(WuXing.jin, WuXing.jin),
          WuXingRelation.biHe,
        );
        expect(
          WuXingService.getRelation(WuXing.mu, WuXing.mu),
          WuXingRelation.biHe,
        );
      });

      test('should return woSheng for sheng relation', () {
        expect(
          WuXingService.getRelation(WuXing.jin, WuXing.shui),
          WuXingRelation.woSheng,
        ); // 金生水
        expect(
          WuXingService.getRelation(WuXing.shui, WuXing.mu),
          WuXingRelation.woSheng,
        ); // 水生木
        expect(
          WuXingService.getRelation(WuXing.mu, WuXing.huo),
          WuXingRelation.woSheng,
        ); // 木生火
        expect(
          WuXingService.getRelation(WuXing.huo, WuXing.tu),
          WuXingRelation.woSheng,
        ); // 火生土
        expect(
          WuXingService.getRelation(WuXing.tu, WuXing.jin),
          WuXingRelation.woSheng,
        ); // 土生金
      });

      test('should return shengWo for reverse sheng relation', () {
        expect(
          WuXingService.getRelation(WuXing.shui, WuXing.jin),
          WuXingRelation.shengWo,
        ); // 金生水
        expect(
          WuXingService.getRelation(WuXing.mu, WuXing.shui),
          WuXingRelation.shengWo,
        ); // 水生木
      });

      test('should return woKe for ke relation', () {
        expect(
          WuXingService.getRelation(WuXing.jin, WuXing.mu),
          WuXingRelation.woKe,
        ); // 金克木
        expect(
          WuXingService.getRelation(WuXing.mu, WuXing.tu),
          WuXingRelation.woKe,
        ); // 木克土
        expect(
          WuXingService.getRelation(WuXing.tu, WuXing.shui),
          WuXingRelation.woKe,
        ); // 土克水
        expect(
          WuXingService.getRelation(WuXing.shui, WuXing.huo),
          WuXingRelation.woKe,
        ); // 水克火
        expect(
          WuXingService.getRelation(WuXing.huo, WuXing.jin),
          WuXingRelation.woKe,
        ); // 火克金
      });

      test('should return keWo for reverse ke relation', () {
        expect(
          WuXingService.getRelation(WuXing.mu, WuXing.jin),
          WuXingRelation.keWo,
        ); // 金克木
        expect(
          WuXingService.getRelation(WuXing.tu, WuXing.mu),
          WuXingRelation.keWo,
        ); // 木克土
      });
    });

    group('isSheng and isKe', () {
      test('isSheng should return true for sheng relation', () {
        expect(WuXingService.isSheng(WuXing.jin, WuXing.shui), true);
        expect(WuXingService.isSheng(WuXing.shui, WuXing.mu), true);
        expect(WuXingService.isSheng(WuXing.mu, WuXing.huo), true);
      });

      test('isSheng should return false for non-sheng relation', () {
        expect(WuXingService.isSheng(WuXing.jin, WuXing.mu), false);
        expect(WuXingService.isSheng(WuXing.jin, WuXing.jin), false);
      });

      test('isKe should return true for ke relation', () {
        expect(WuXingService.isKe(WuXing.jin, WuXing.mu), true);
        expect(WuXingService.isKe(WuXing.mu, WuXing.tu), true);
        expect(WuXingService.isKe(WuXing.tu, WuXing.shui), true);
      });

      test('isKe should return false for non-ke relation', () {
        expect(WuXingService.isKe(WuXing.jin, WuXing.shui), false);
        expect(WuXingService.isKe(WuXing.jin, WuXing.jin), false);
      });
    });

    group('getShengTarget and getKeTarget', () {
      test('getShengTarget should return correct target', () {
        expect(WuXingService.getShengTarget(WuXing.jin), WuXing.shui);
        expect(WuXingService.getShengTarget(WuXing.shui), WuXing.mu);
        expect(WuXingService.getShengTarget(WuXing.mu), WuXing.huo);
        expect(WuXingService.getShengTarget(WuXing.huo), WuXing.tu);
        expect(WuXingService.getShengTarget(WuXing.tu), WuXing.jin);
      });

      test('getKeTarget should return correct target', () {
        expect(WuXingService.getKeTarget(WuXing.jin), WuXing.mu);
        expect(WuXingService.getKeTarget(WuXing.mu), WuXing.tu);
        expect(WuXingService.getKeTarget(WuXing.tu), WuXing.shui);
        expect(WuXingService.getKeTarget(WuXing.shui), WuXing.huo);
        expect(WuXingService.getKeTarget(WuXing.huo), WuXing.jin);
      });
    });

    group('getShengSource and getKeSource', () {
      test('getShengSource should return correct source', () {
        expect(WuXingService.getShengSource(WuXing.shui), WuXing.jin);
        expect(WuXingService.getShengSource(WuXing.mu), WuXing.shui);
        expect(WuXingService.getShengSource(WuXing.huo), WuXing.mu);
        expect(WuXingService.getShengSource(WuXing.tu), WuXing.huo);
        expect(WuXingService.getShengSource(WuXing.jin), WuXing.tu);
      });

      test('getKeSource should return correct source', () {
        expect(WuXingService.getKeSource(WuXing.mu), WuXing.jin);
        expect(WuXingService.getKeSource(WuXing.tu), WuXing.mu);
        expect(WuXingService.getKeSource(WuXing.shui), WuXing.tu);
        expect(WuXingService.getKeSource(WuXing.huo), WuXing.shui);
        expect(WuXingService.getKeSource(WuXing.jin), WuXing.huo);
      });
    });

    group('wuXingToString and stringToWuXing', () {
      test('wuXingToString should convert correctly', () {
        expect(WuXingService.wuXingToString(WuXing.jin), 'jin');
        expect(WuXingService.wuXingToString(WuXing.mu), 'mu');
        expect(WuXingService.wuXingToString(WuXing.shui), 'shui');
        expect(WuXingService.wuXingToString(WuXing.huo), 'huo');
        expect(WuXingService.wuXingToString(WuXing.tu), 'tu');
      });

      test('stringToWuXing should convert correctly', () {
        expect(WuXingService.stringToWuXing('jin'), WuXing.jin);
        expect(WuXingService.stringToWuXing('mu'), WuXing.mu);
        expect(WuXingService.stringToWuXing('shui'), WuXing.shui);
        expect(WuXingService.stringToWuXing('huo'), WuXing.huo);
        expect(WuXingService.stringToWuXing('tu'), WuXing.tu);
      });

      test('stringToWuXing should return null for invalid string', () {
        expect(WuXingService.stringToWuXing('invalid'), null);
      });
    });

    group('getWuXingListFromBranches', () {
      test('should return correct wuxing list', () {
        final List<String> branches = <String>['子', '寅', '午', '申', '辰'];
        final List<WuXing> result = WuXingService.getWuXingListFromBranches(
          branches,
        );
        expect(result, <WuXing>[
          WuXing.shui,
          WuXing.mu,
          WuXing.huo,
          WuXing.jin,
          WuXing.tu,
        ]);
      });

      test('should skip invalid branches', () {
        final List<String> branches = <String>['子', '无效', '午'];
        final List<WuXing> result = WuXingService.getWuXingListFromBranches(
          branches,
        );
        expect(result, <WuXing>[WuXing.shui, WuXing.huo]);
      });
    });

    group('getWuXingListFromStems', () {
      test('should return correct wuxing list', () {
        final List<String> stems = <String>['甲', '丙', '庚', '壬', '戊'];
        final List<WuXing> result = WuXingService.getWuXingListFromStems(
          stems,
        );
        expect(result, <WuXing>[
          WuXing.mu,
          WuXing.huo,
          WuXing.jin,
          WuXing.shui,
          WuXing.tu,
        ]);
      });

      test('should skip invalid stems', () {
        final List<String> stems = <String>['甲', '无效', '庚'];
        final List<WuXing> result = WuXingService.getWuXingListFromStems(
          stems,
        );
        expect(result, <WuXing>[WuXing.mu, WuXing.jin]);
      });
    });
  });
}

