import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('DivinationType', () {
    test('应该包含所有术数系统类型', () {
      expect(DivinationType.values.length, 4);
      expect(DivinationType.values, contains(DivinationType.liuYao));
      expect(DivinationType.values, contains(DivinationType.daLiuRen));
      expect(DivinationType.values, contains(DivinationType.xiaoLiuRen));
      expect(DivinationType.values, contains(DivinationType.meiHua));
    });

    test('displayName 应该返回正确的中文名称', () {
      expect(DivinationType.liuYao.displayName, '六爻');
      expect(DivinationType.daLiuRen.displayName, '大六壬');
      expect(DivinationType.xiaoLiuRen.displayName, '小六壬');
      expect(DivinationType.meiHua.displayName, '梅花易数');
    });

    test('id 应该返回正确的唯一标识符', () {
      expect(DivinationType.liuYao.id, 'liuyao');
      expect(DivinationType.daLiuRen.id, 'daliuren');
      expect(DivinationType.xiaoLiuRen.id, 'xiaoliuren');
      expect(DivinationType.meiHua.id, 'meihua');
    });

    test('fromId 应该根据 ID 返回正确的枚举值', () {
      expect(DivinationType.fromId('liuyao'), DivinationType.liuYao);
      expect(DivinationType.fromId('daliuren'), DivinationType.daLiuRen);
      expect(DivinationType.fromId('xiaoliuren'), DivinationType.xiaoLiuRen);
      expect(DivinationType.fromId('meihua'), DivinationType.meiHua);
    });

    test('fromId 应该在 ID 不存在时抛出 ArgumentError', () {
      expect(
        () => DivinationType.fromId('invalid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => DivinationType.fromId(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('所有 ID 应该是唯一的', () {
      final ids = DivinationType.values.map((e) => e.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });
  });

  group('CastMethod', () {
    test('应该包含所有起卦方式', () {
      expect(CastMethod.values.length, 5);
      expect(CastMethod.values, contains(CastMethod.coin));
      expect(CastMethod.values, contains(CastMethod.time));
      expect(CastMethod.values, contains(CastMethod.manual));
      expect(CastMethod.values, contains(CastMethod.number));
      expect(CastMethod.values, contains(CastMethod.random));
    });

    test('displayName 应该返回正确的中文名称', () {
      expect(CastMethod.coin.displayName, '摇钱法');
      expect(CastMethod.time.displayName, '时间起卦');
      expect(CastMethod.manual.displayName, '手动输入');
      expect(CastMethod.number.displayName, '数字起卦');
      expect(CastMethod.random.displayName, '随机起卦');
    });

    test('id 应该返回正确的唯一标识符', () {
      expect(CastMethod.coin.id, 'coin');
      expect(CastMethod.time.id, 'time');
      expect(CastMethod.manual.id, 'manual');
      expect(CastMethod.number.id, 'number');
      expect(CastMethod.random.id, 'random');
    });

    test('fromId 应该根据 ID 返回正确的枚举值', () {
      expect(CastMethod.fromId('coin'), CastMethod.coin);
      expect(CastMethod.fromId('time'), CastMethod.time);
      expect(CastMethod.fromId('manual'), CastMethod.manual);
      expect(CastMethod.fromId('number'), CastMethod.number);
      expect(CastMethod.fromId('random'), CastMethod.random);
    });

    test('fromId 应该在 ID 不存在时抛出 ArgumentError', () {
      expect(
        () => CastMethod.fromId('invalid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => CastMethod.fromId(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('所有 ID 应该是唯一的', () {
      final ids = CastMethod.values.map((e) => e.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });
  });
}
