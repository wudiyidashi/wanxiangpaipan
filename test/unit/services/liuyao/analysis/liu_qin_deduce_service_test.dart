import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liu_qin_deduce_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  group('LiuQinDeduceService 六亲循环', () {
    test('妻财：原神子孙、忌神兄弟、仇神父母', () {
      expect(LiuQinDeduceService.yuanShenOf(LiuQin.qiCai), LiuQin.ziSun);
      expect(LiuQinDeduceService.jiShenOf(LiuQin.qiCai), LiuQin.xiongDi);
      expect(LiuQinDeduceService.chouShenOf(LiuQin.qiCai), LiuQin.fuMu);
    });

    test('官鬼：原神妻财、忌神子孙、仇神兄弟', () {
      expect(LiuQinDeduceService.yuanShenOf(LiuQin.guanGui), LiuQin.qiCai);
      expect(LiuQinDeduceService.jiShenOf(LiuQin.guanGui), LiuQin.ziSun);
      expect(LiuQinDeduceService.chouShenOf(LiuQin.guanGui), LiuQin.xiongDi);
    });
  });

  group('LiuQinDeduceService 推导链', () {
    // 乾：子孙子(1) 妻财寅(2) 父母辰(3) 官鬼午(4) 兄弟申(5) 父母戌(6)
    final qian = buildGua([7, 7, 7, 7, 7, 7]);

    test('用神妻财寅木：原忌仇闲各归其位', () {
      final chain = LiuQinDeduceService.deduce(qian, 2);
      expect(chain.position, 2);
      expect(chain.isFuShen, isFalse);
      expect(chain.yuanShenPosition, 1); // 子孙子水
      expect(chain.jiShenPosition, 5); // 兄弟申金
      expect(chain.chouShenPosition, 3); // 父母辰土（首现）
      expect(chain.xianShenPositions, [4]); // 官鬼午火
      expect(chain.duplicatePositions, isEmpty);
    });

    test('用神父母辰土：用神两现（戌土）', () {
      final chain = LiuQinDeduceService.deduce(qian, 3);
      expect(chain.duplicatePositions, [6]);
    });

    test('原神动爻优先于静爻首现', () {
      // 父母两现（辰3静、戌6动），用神兄弟申金五爻 → 原神父母取动爻戌
      final qianTopMoving = buildGua([7, 7, 7, 7, 7, 9]);
      final chain = LiuQinDeduceService.deduce(qianTopMoving, 5);
      expect(chain.yuanShenPosition, 6);
    });

    test('原神不上卦：天山遁用神伏神妻财，原神子孙亦伏藏', () {
      final dun = buildGua([8, 8, 7, 7, 7, 7]);
      final chain = LiuQinDeduceService.deduce(dun, 2, isFuShen: true);
      expect(chain.isFuShen, isTrue);
      expect(chain.position, 2);
      expect(chain.yuanShenPosition, isNull); // 子孙不上卦
      expect(chain.jiShenPosition, 3); // 兄弟申金
    });

    test('伏神取用但该爻位无伏神时抛出参数错误', () {
      expect(
        () => LiuQinDeduceService.deduce(qian, 2, isFuShen: true),
        throwsArgumentError,
      );
    });
  });
}
