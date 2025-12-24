import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qigua_service.dart';

void main() {
  group('QiGuaService Tests', () {
    test('coinCast should return 6 yao numbers', () {
      final yaoNumbers = QiGuaService.coinCast();
      expect(yaoNumbers.length, 6);
    });

    test('coinCast should return valid yao numbers (6-9)', () {
      final yaoNumbers = QiGuaService.coinCast();
      for (final num in yaoNumbers) {
        expect(num, greaterThanOrEqualTo(6));
        expect(num, lessThanOrEqualTo(9));
      }
    });

    test('coinCastOnce should return valid yao number', () {
      for (int i = 0; i < 10; i++) {
        final num = QiGuaService.coinCastOnce();
        expect([6, 7, 8, 9].contains(num), true);
      }
    });

    test('timeCast should return 6 yao numbers', () {
      final time = DateTime(2025, 1, 14, 10, 30);
      final yaoNumbers = QiGuaService.timeCast(time);
      expect(yaoNumbers.length, 6);
    });

    test('timeCast should be deterministic', () {
      final time = DateTime(2025, 1, 14, 10, 30);
      final yaoNumbers1 = QiGuaService.timeCast(time);
      final yaoNumbers2 = QiGuaService.timeCast(time);
      expect(yaoNumbers1, yaoNumbers2);
    });

    test('timeCast should return valid yao numbers', () {
      final time = DateTime(2025, 1, 14, 10, 30);
      final yaoNumbers = QiGuaService.timeCast(time);
      for (final num in yaoNumbers) {
        expect([6, 7, 8, 9].contains(num), true);
      }
    });

    test('manualCastOnce should convert 3 front to 9', () {
      final faces = [CoinFace.front, CoinFace.front, CoinFace.front];
      final num = QiGuaService.manualCastOnce(faces);
      expect(num, 9);
    });

    test('manualCastOnce should convert 2 front 1 back to 7', () {
      final faces = [CoinFace.front, CoinFace.front, CoinFace.back];
      final num = QiGuaService.manualCastOnce(faces);
      expect(num, 7);
    });

    test('manualCastOnce should convert 1 front 2 back to 8', () {
      final faces = [CoinFace.front, CoinFace.back, CoinFace.back];
      final num = QiGuaService.manualCastOnce(faces);
      expect(num, 8);
    });

    test('manualCastOnce should convert 3 back to 6', () {
      final faces = [CoinFace.back, CoinFace.back, CoinFace.back];
      final num = QiGuaService.manualCastOnce(faces);
      expect(num, 6);
    });

    test('manualCast should return 6 yao numbers', () {
      final allFaces = List.generate(
        6,
        (_) => [CoinFace.front, CoinFace.front, CoinFace.back],
      );
      final yaoNumbers = QiGuaService.manualCast(allFaces);
      expect(yaoNumbers.length, 6);
      expect(yaoNumbers.every((n) => n == 7), true);
    });

    test('manualCastOnce should throw when faces length invalid', () {
      expect(() => QiGuaService.manualCastOnce([CoinFace.front]), throwsArgumentError);
    });
  });
}

