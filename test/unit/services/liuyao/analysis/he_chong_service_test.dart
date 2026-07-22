import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/he_chong_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');

  List<String> termsAt(Map<int, List<YaoAnalysisTag>> result, int pos) =>
      (result[pos] ?? []).map((t) => t.term).toList();

  group('HeChongService 六合（爻间）', () {
    test('地天泰初爻子动合四爻丑静：动爻合住、静爻合起', () {
      // 泰：内乾（子寅辰）外坤（丑亥酉），子丑六合
      final tai = buildGua([9, 7, 7, 8, 8, 8]);
      final result = HeChongService.analyzeGua(tai, lunar);
      expect(termsAt(result, 1), contains('合住'));
      expect(termsAt(result, 4), contains('合起'));
      expect(
          result[1]!.firstWhere((t) => t.term == '合住').relatedYao, contains(4));
    });

    test('两动爻相合：双方合绊', () {
      final tai = buildGua([9, 7, 7, 6, 8, 8]);
      final result = HeChongService.analyzeGua(tai, lunar);
      expect(termsAt(result, 1), contains('合绊'));
      expect(termsAt(result, 4), contains('合绊'));
    });

    test('两静爻不论爻间合', () {
      final tai = buildGua([7, 7, 7, 8, 8, 8]);
      final result = HeChongService.analyzeGua(tai, lunar);
      expect(termsAt(result, 1), isNot(contains('合住')));
      expect(termsAt(result, 4), isNot(contains('合起')));
    });
  });

  group('HeChongService 冲开（合处逢冲）', () {
    test('子丑相合逢午日冲子：冲开', () {
      final tai = buildGua([9, 7, 7, 8, 8, 8]);
      final wuDay = buildLunar(yueJian: '寅', riGanZhi: '甲午');
      final result = HeChongService.analyzeGua(tai, wuDay);
      expect(termsAt(result, 1), contains('冲开'));
      expect(termsAt(result, 4), contains('冲开'));
    });
  });

  group('HeChongService 六冲（爻间）', () {
    test('乾卦二五寅申两动：只论相冲，不把两支直接标成三刑', () {
      final qian = buildGua([7, 9, 7, 7, 9, 7]);
      final result = HeChongService.analyzeGua(qian, lunar);
      expect(termsAt(result, 2), contains('相冲'));
      expect(termsAt(result, 5), contains('相冲'));
      expect(termsAt(result, 2), isNot(contains('相刑')));
      expect(termsAt(result, 2), isNot(contains('三刑')));
    });

    test('动爻冲静爻亦标注相冲', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]); // 初子动，四午静
      final result = HeChongService.analyzeGua(qian, lunar);
      expect(termsAt(result, 1), contains('相冲'));
      expect(termsAt(result, 4), contains('相冲'));
    });

    test('两静爻不论爻间冲', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final result = HeChongService.analyzeGua(qian, lunar);
      expect(termsAt(result, 1), isNot(contains('相冲')));
    });
  });

  group('HeChongService 三刑', () {
    test('寅巳申三支齐全且有动爻才标三刑', () {
      final base = buildGua([7, 7, 7, 7, 7, 7]);
      final gua = base.copyWith(yaos: [
        makeYao(position: 1, branch: '寅', moving: true),
        makeYao(position: 2, branch: '巳'),
        makeYao(position: 3, branch: '申'),
        makeYao(position: 4, branch: '子'),
        makeYao(position: 5, branch: '卯'),
        makeYao(position: 6, branch: '辰'),
      ]);

      final result = HeChongService.analyzeGua(gua, lunar);

      for (final position in [1, 2, 3]) {
        expect(termsAt(result, position), contains('三刑'));
      }
    });

    test('寅巳申三支皆静不形成有效三刑', () {
      final base = buildGua([7, 7, 7, 7, 7, 7]);
      final gua = base.copyWith(yaos: [
        makeYao(position: 1, branch: '寅'),
        makeYao(position: 2, branch: '巳'),
        makeYao(position: 3, branch: '申'),
        ...base.yaos.skip(3),
      ]);

      final result = HeChongService.analyzeGua(gua, lunar);

      expect(result.values.expand((tags) => tags).map((tag) => tag.term),
          isNot(contains('三刑')));
    });
  });

  group('HeChongService 三合局', () {
    test('乾卦子辰两动申静：申子辰三合水局', () {
      final qian = buildGua([9, 7, 9, 7, 7, 7]);
      final result = HeChongService.analyzeGua(qian, lunar);
      for (final pos in [1, 3, 5]) {
        expect(termsAt(result, pos), contains('三合局'), reason: '$pos 爻应在三合局中');
      }
      final tag = result[1]!.firstWhere((t) => t.term == '三合局');
      expect(tag.reason, contains('水'));
      expect(tag.relatedYao, containsAll([3, 5]));
    });

    test('三爻全静不成局', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final result = HeChongService.analyzeGua(qian, lunar);
      expect(termsAt(result, 1), isNot(contains('三合局')));
    });

    test('两动爻借日辰凑成三合局', () {
      // 泰：子(1)辰(3)动，申日补全申子辰
      final tai = buildGua([9, 7, 9, 8, 8, 8]);
      final shenDay = buildLunar(yueJian: '寅', riGanZhi: '甲申');
      final result = HeChongService.analyzeGua(tai, shenDay);
      expect(termsAt(result, 1), contains('三合成局'));
      expect(termsAt(result, 3), contains('三合成局'));
    });

    test('半合：两动爻含旺支', () {
      // 乾：子(1)动辰(3)静不含申——子辰半合（含旺支子）
      final qian = buildGua([9, 7, 9, 7, 7, 7]);
      // 已成三合局（申在卦中静爻）时不再标半合
      final result = HeChongService.analyzeGua(qian, lunar);
      expect(termsAt(result, 1), isNot(contains('半合')));
      // 泰卦子辰两动、卦中无申、日辰非申：半合
      final tai = buildGua([9, 7, 9, 8, 8, 8]);
      final result2 = HeChongService.analyzeGua(tai, lunar);
      expect(termsAt(result2, 1), contains('半合'));
      expect(termsAt(result2, 3), contains('半合'));
    });
  });

  group('HeChongService 相害', () {
    test('丰卦丑午两动：相害', () {
      // 丰：内离（卯丑亥）外震（午申戌）；二爻丑阴动、四爻午阳动
      final feng = buildGua([7, 6, 7, 9, 8, 8]);
      final result = HeChongService.analyzeGua(feng, lunar);
      expect(termsAt(result, 2), contains('相害'));
      expect(termsAt(result, 4), contains('相害'));
    });

    test('相害为低优先级凶标签', () {
      final feng = buildGua([7, 6, 7, 9, 8, 8]);
      final result = HeChongService.analyzeGua(feng, lunar);
      final tag = result[2]!.firstWhere((t) => t.term == '相害');
      expect(tag.polarity, Polarity.xiong);
      expect(tag.priority, greaterThanOrEqualTo(40));
    });
  });
}
