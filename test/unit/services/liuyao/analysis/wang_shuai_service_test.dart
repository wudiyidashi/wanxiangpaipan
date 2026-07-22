import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/wang_shuai_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  // 乾为天（全静）：初子 二寅 三辰 四午 五申 上戌
  final qian = buildGua([7, 7, 7, 7, 7, 7]);

  group('WangShuaiService.getLevel 旺相休囚死', () {
    test('当令者旺：午月火旺', () {
      expect(WangShuaiService.getLevel(WuXing.huo, '午'), WangShuaiLevel.wang);
    });
    test('月生者相：午月土相', () {
      expect(WangShuaiService.getLevel(WuXing.tu, '午'), WangShuaiLevel.xiang);
    });
    test('生月者休：午月木休', () {
      expect(WangShuaiService.getLevel(WuXing.mu, '午'), WangShuaiLevel.xiu);
    });
    test('克月者囚：午月水囚', () {
      expect(WangShuaiService.getLevel(WuXing.shui, '午'), WangShuaiLevel.qiu);
    });
    test('月克者死：午月金死', () {
      expect(WangShuaiService.getLevel(WuXing.jin, '午'), WangShuaiLevel.si);
    });
  });

  group('WangShuaiService.analyzeYao 月建相关', () {
    final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');

    List<String> termsOf(int position) => WangShuaiService.analyzeYao(
        qian.yaos[position - 1], lunar).map((t) => t.term).toList();

    test('四爻午火：临月建 + 旺', () {
      final terms = termsOf(4);
      expect(terms, contains('临月建'));
      expect(terms, contains('旺'));
    });

    test('初爻子水：月破（午月冲子）', () {
      final terms = termsOf(1);
      expect(terms, contains('月破'));
      expect(terms, contains('囚'));
      expect(terms, isNot(contains('临月建')));
    });

    test('五爻申金：月克 + 死', () {
      final terms = termsOf(5);
      expect(terms, contains('月克'));
      expect(terms, contains('死'));
    });

    test('三爻辰土：月生 + 相', () {
      final terms = termsOf(3);
      expect(terms, contains('月生'));
      expect(terms, contains('相'));
    });

    test('二爻寅木：休，无月生月克', () {
      final terms = termsOf(2);
      expect(terms, contains('休'));
      expect(terms, isNot(contains('月生')));
      expect(terms, isNot(contains('月克')));
    });

    test('月破为最高优先级凶标签', () {
      final tags = WangShuaiService.analyzeYao(qian.yaos[0], lunar);
      final yuePo = tags.firstWhere((t) => t.term == '月破');
      expect(yuePo.polarity, Polarity.xiong);
      expect(tags.every((t) => t.term == '月破' || t.priority > yuePo.priority),
          isTrue);
    });
  });

  group('WangShuaiService.analyzeYao 日辰相关', () {
    test('初爻子水在甲子日：临日建', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final terms = WangShuaiService.analyzeYao(qian.yaos[0], lunar)
          .map((t) => t.term);
      expect(terms, contains('临日建'));
    });

    test('四爻午火在甲子日：日克', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final terms = WangShuaiService.analyzeYao(qian.yaos[3], lunar)
          .map((t) => t.term);
      expect(terms, contains('日克'));
    });

    test('二爻寅木在甲子日：日生', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final terms = WangShuaiService.analyzeYao(qian.yaos[1], lunar)
          .map((t) => t.term);
      expect(terms, contains('日生'));
    });

    test('初爻子水在乙亥日：日扶（同五行异支）', () {
      final lunar = buildLunar(yueJian: '午', riGanZhi: '乙亥');
      final terms = WangShuaiService.analyzeYao(qian.yaos[0], lunar)
          .map((t) => t.term);
      expect(terms, contains('日扶'));
      expect(terms, isNot(contains('临日建')));
    });

    test('日冲不在本服务出标签（暗动/日破由动变服务判定）', () {
      // 甲午日冲初爻子水
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲午');
      final terms = WangShuaiService.analyzeYao(qian.yaos[0], lunar)
          .map((t) => t.term);
      expect(terms, isNot(contains('暗动')));
      expect(terms, isNot(contains('日破')));
    });
  });
}
