import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/special_service.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  // 乾：子(1) 寅(2) 辰(3) 午(4) 申(5) 戌(6)
  final qian = buildGua([7, 7, 7, 7, 7, 7]);
  final qianYao4Moving = buildGua([7, 7, 7, 9, 7, 7]);

  group('SpecialService 日月合爻', () {
    test('乙丑日合初爻子水：日合（静爻合起）', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '乙丑');
      final tags = SpecialService.analyzeYao(qian.yaos[0], lunar);
      final riHe = tags.firstWhere((t) => t.term == '日合');
      expect(riHe.reason, contains('合起'));
    });

    test('未月合四爻午火动爻：月合（动爻合绊）', () {
      final lunar = buildLunar(yueJian: '未', riGanZhi: '甲子');
      final tags =
          SpecialService.analyzeYao(qianYao4Moving.yaos[3], lunar);
      final yueHe = tags.firstWhere((t) => t.term == '月合');
      expect(yueHe.reason, contains('合绊'));
    });

    test('无合无标签', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲寅');
      final terms = SpecialService.analyzeYao(qian.yaos[0], lunar)
          .map((t) => t.term);
      expect(terms, isNot(contains('日合')));
    });
  });

  group('SpecialService 太岁入爻', () {
    test('甲子年初爻子水：太岁入爻', () {
      final lunar =
          buildLunar(yueJian: '午', riGanZhi: '丙寅', yearGanZhi: '甲子');
      final terms = SpecialService.analyzeYao(qian.yaos[0], lunar)
          .map((t) => t.term);
      expect(terms, contains('太岁入爻'));
    });

    test('非太岁支无标签', () {
      final lunar =
          buildLunar(yueJian: '午', riGanZhi: '丙寅', yearGanZhi: '甲子');
      final terms = SpecialService.analyzeYao(qian.yaos[1], lunar)
          .map((t) => t.term);
      expect(terms, isNot(contains('太岁入爻')));
    });
  });
}
