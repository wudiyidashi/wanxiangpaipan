import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/kong_wang_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  // 乾为天全静：初子 二寅 三辰 四午 五申 上戌；甲子旬空戌亥
  final qianStatic = buildGua([7, 7, 7, 7, 7, 7]);
  // 上爻戌发动
  final qianTopMoving = buildGua([7, 7, 7, 7, 7, 9]);

  group('KongWangService 旬空判定', () {
    test('甲子日上爻戌土：旬空', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final terms =
          KongWangService.analyzeYao(qianStatic.yaos[5], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, contains('旬空'));
    });

    test('非空爻无旬空标签', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final terms =
          KongWangService.analyzeYao(qianStatic.yaos[0], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, isNot(contains('旬空')));
      expect(terms, isEmpty);
    });
  });

  group('KongWangService 真空/假空', () {
    test('休囚静爻逢空为真空：卯月戌土（月克死地）', () {
      final lunar = buildLunar(yueJian: '卯', riGanZhi: '甲子');
      final tags =
          KongWangService.analyzeYao(qianStatic.yaos[5], qianStatic, lunar);
      final terms = tags.map((t) => t.term);
      expect(terms, contains('真空'));
      expect(terms, isNot(contains('假空')));
      expect(tags.firstWhere((t) => t.term == '真空').polarity, Polarity.xiong);
    });

    test('旺相之爻逢空为假空（旺不为空）：午月戌土相地', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final tags =
          KongWangService.analyzeYao(qianStatic.yaos[5], qianStatic, lunar);
      final terms = tags.map((t) => t.term);
      expect(terms, contains('假空'));
      expect(terms, isNot(contains('真空')));
      expect(tags.firstWhere((t) => t.term == '假空').reason, contains('旺不为空'));
    });

    test('动爻逢空为假空（动不为空）：卯月戌土动', () {
      final lunar = buildLunar(yueJian: '卯', riGanZhi: '甲子');
      final tags = KongWangService.analyzeYao(
          qianTopMoving.yaos[5], qianTopMoving, lunar);
      final terms = tags.map((t) => t.term);
      expect(terms, contains('假空'));
      expect(tags.firstWhere((t) => t.term == '假空').reason, contains('动不为空'));
    });
  });

  group('KongWangService 冲空', () {
    test('戊辰日冲空爻戌土：冲空', () {
      // 戊辰在甲子旬，戌亥仍空；辰冲戌
      final lunar = buildLunar(yueJian: '午', riGanZhi: '戊辰');
      final terms =
          KongWangService.analyzeYao(qianStatic.yaos[5], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, contains('旬空'));
      expect(terms, contains('冲空'));
    });

    test('非冲日无冲空标签', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final terms =
          KongWangService.analyzeYao(qianStatic.yaos[5], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, isNot(contains('冲空')));
    });
  });
}
