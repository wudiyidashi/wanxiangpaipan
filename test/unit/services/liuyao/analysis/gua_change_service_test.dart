import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/gua_change_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  List<String> termsOf(List<YaoAnalysisTag> tags) =>
      tags.map((t) => t.term).toList();

  group('GuaChangeService 本卦特性', () {
    test('乾为天：六冲卦', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final tags = GuaChangeService.analyzeGua(qian, null);
      expect(termsOf(tags), contains('六冲卦'));
    });

    test('地天泰：六合卦', () {
      final tai = buildGua([7, 7, 7, 8, 8, 8]);
      final tags = GuaChangeService.analyzeGua(tai, null);
      expect(termsOf(tags), contains('六合卦'));
    });

    test('火地晋：游魂卦', () {
      final jin = buildGua([8, 8, 8, 7, 8, 7]);
      final tags = GuaChangeService.analyzeGua(jin, null);
      expect(termsOf(tags), contains('游魂卦'));
    });
  });

  group('GuaChangeService 卦变', () {
    test('天风姤初爻动变乾：卦变六冲', () {
      final gou = buildGua([6, 7, 7, 7, 7, 7]);
      final changing = buildChangingGua(gou)!;
      final tags = GuaChangeService.analyzeGua(gou, changing);
      expect(termsOf(tags), contains('卦变六冲'));
    });

    test('变卦为六合则卦变六合', () {
      // 地风升初爻动变地天泰（六合）
      final sheng = buildGua([6, 7, 7, 8, 8, 8]);
      final changing = buildChangingGua(sheng)!;
      expect(changing.id, '111000');
      final tags = GuaChangeService.analyzeGua(sheng, changing);
      expect(termsOf(tags), contains('卦变六合'));
    });
  });

  group('GuaChangeService 伏吟反吟', () {
    test('震变乾内卦伏吟（子寅辰不变）', () {
      // 震为雷二三爻动，内卦变乾，纳支仍子寅辰
      final zhen = buildGua([7, 6, 6, 7, 8, 8]);
      final changing = buildChangingGua(zhen)!;
      final tags = GuaChangeService.analyzeGua(zhen, changing);
      final fuYin = tags.firstWhere((t) => t.term == '伏吟');
      expect(fuYin.polarity, Polarity.xiong);
      expect(fuYin.reason, contains('内卦'));
    });

    test('风地观外卦动变坤：外卦反吟（未巳卯冲丑亥酉）', () {
      final guan = buildGua([8, 8, 8, 8, 9, 9]);
      final changing = buildChangingGua(guan)!;
      expect(changing.id, '000000');
      final tags = GuaChangeService.analyzeGua(guan, changing);
      final fanYin = tags.firstWhere((t) => t.term == '反吟');
      expect(fanYin.polarity, Polarity.xiong);
      expect(fanYin.reason, contains('外卦'));
    });

    test('普通卦变无伏吟反吟', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final changing = buildChangingGua(qian)!;
      final tags = GuaChangeService.analyzeGua(qian, changing);
      expect(termsOf(tags), isNot(contains('伏吟')));
      expect(termsOf(tags), isNot(contains('反吟')));
    });
  });
}
