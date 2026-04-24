import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qigua_service.dart';

void main() {
  group('QiGuaService Tests', () {
    test('coinCast should return 6 yao numbers', () {
      final List<int> yaoNumbers = QiGuaService.coinCast();
      expect(yaoNumbers.length, 6);
    });

    test('coinCast should return valid yao numbers (6-9)', () {
      final List<int> yaoNumbers = QiGuaService.coinCast();
      for (final int num in yaoNumbers) {
        expect(num, greaterThanOrEqualTo(6));
        expect(num, lessThanOrEqualTo(9));
      }
    });

    test('coinCastOnce should return valid yao number', () {
      for (int i = 0; i < 10; i++) {
        final int num = QiGuaService.coinCastOnce();
        expect(<int>[6, 7, 8, 9].contains(num), true);
      }
    });

    test('timeCast should return 6 yao numbers', () {
      final DateTime time = DateTime(2025, 1, 14, 10, 30);
      final List<int> yaoNumbers = QiGuaService.timeCast(time);
      expect(yaoNumbers.length, 6);
    });

    test('timeCast should be deterministic', () {
      final DateTime time = DateTime(2025, 1, 14, 10, 30);
      final List<int> yaoNumbers1 = QiGuaService.timeCast(time);
      final List<int> yaoNumbers2 = QiGuaService.timeCast(time);
      expect(yaoNumbers1, yaoNumbers2);
    });

    test('timeCast should return valid yao numbers', () {
      final DateTime time = DateTime(2025, 1, 14, 10, 30);
      final List<int> yaoNumbers = QiGuaService.timeCast(time);
      for (final int num in yaoNumbers) {
        expect(<int>[6, 7, 8, 9].contains(num), true);
      }
    });

    test('timeCast should match lunar time casting reference case', () {
      // 元亨利贞：公历 2026-04-24 11:30，农历丙午年三月初八午时
      // 年支午=7、月=3、日=8、时支午=7：上卦兑、下卦乾、初爻动
      final DateTime time = DateTime(2026, 4, 24, 11, 30);

      final List<int> yaoNumbers = QiGuaService.timeCast(time);

      expect(yaoNumbers, <int>[9, 7, 7, 7, 7, 8]);
    });

    test('timeCast should match Mao hour reference case', () {
      // 元亨利贞：公历 2026-04-24 05:30，农历丙午年三月初八卯时
      // 年支午=7、月=3、日=8、时支卯=4：上卦兑、下卦坎、四爻动
      final DateTime time = DateTime(2026, 4, 24, 5, 30);

      final List<int> yaoNumbers = QiGuaService.timeCast(time);

      expect(yaoNumbers, <int>[8, 7, 8, 9, 7, 8]);
    });

    test('manualCastOnce should convert 3 front to 9', () {
      final List<CoinFace> faces = <CoinFace>[
        CoinFace.front,
        CoinFace.front,
        CoinFace.front,
      ];
      final int num = QiGuaService.manualCastOnce(faces);
      expect(num, 9);
    });

    test('manualCastOnce should convert 2 front 1 back to 7', () {
      final List<CoinFace> faces = <CoinFace>[
        CoinFace.front,
        CoinFace.front,
        CoinFace.back,
      ];
      final int num = QiGuaService.manualCastOnce(faces);
      expect(num, 7);
    });

    test('manualCastOnce should convert 1 front 2 back to 8', () {
      final List<CoinFace> faces = <CoinFace>[
        CoinFace.front,
        CoinFace.back,
        CoinFace.back,
      ];
      final int num = QiGuaService.manualCastOnce(faces);
      expect(num, 8);
    });

    test('manualCastOnce should convert 3 back to 6', () {
      final List<CoinFace> faces = <CoinFace>[
        CoinFace.back,
        CoinFace.back,
        CoinFace.back,
      ];
      final int num = QiGuaService.manualCastOnce(faces);
      expect(num, 6);
    });

    test('manualCast should return 6 yao numbers', () {
      final List<List<CoinFace>> allFaces = List.generate(
        6,
        (int _) => <CoinFace>[CoinFace.front, CoinFace.front, CoinFace.back],
      );
      final List<int> yaoNumbers = QiGuaService.manualCast(allFaces);
      expect(yaoNumbers.length, 6);
      expect(yaoNumbers.every((int n) => n == 7), true);
    });

    test('manualCastOnce should throw when faces length invalid', () {
      expect(
        () => QiGuaService.manualCastOnce(<CoinFace>[CoinFace.front]),
        throwsArgumentError,
      );
    });
  });
}
