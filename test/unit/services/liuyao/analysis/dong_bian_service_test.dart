import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/dong_bian_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');

  List<String> transformTerms(String from, String to, {String? riGanZhi}) {
    final l = riGanZhi == null ? lunar : buildLunar(yueJian: '午', riGanZhi: riGanZhi);
    return DongBianService.analyzeTransform(
      makeYao(branch: from, moving: true),
      makeYao(branch: to),
      l,
    ).map((t) => t.term).toList();
  }

  group('DongBianService 化进退', () {
    test('寅化卯为化进神', () {
      final terms = transformTerms('寅', '卯');
      expect(terms, contains('化进神'));
      expect(terms, isNot(contains('化退神')));
    });

    test('卯化寅为化退神', () {
      expect(transformTerms('卯', '寅'), contains('化退神'));
    });

    test('丑化辰为化进神（土支顺行）', () {
      expect(transformTerms('丑', '辰'), contains('化进神'));
    });

    test('异五行不论进退', () {
      expect(transformTerms('寅', '午'), isNot(contains('化进神')));
    });
  });

  group('DongBianService 回头生克与化泄', () {
    test('酉金化午火：回头克', () {
      final tags = DongBianService.analyzeTransform(
          makeYao(branch: '酉', moving: true), makeYao(branch: '午'), lunar);
      final huiTouKe = tags.firstWhere((t) => t.term == '回头克');
      expect(huiTouKe.polarity, Polarity.xiong);
    });

    test('午火化卯木：回头生', () {
      expect(transformTerms('午', '卯'), contains('回头生'));
    });

    test('卯木化午火：化泄', () {
      expect(transformTerms('卯', '午'), contains('化泄'));
    });
  });

  group('DongBianService 化空破墓绝合冲', () {
    test('卯化戌：化合、克出（卯木克戌土）且化空（甲子旬戌亥空）', () {
      final terms = transformTerms('卯', '戌');
      expect(terms, contains('化合'));
      expect(terms, contains('克出'));
      expect(terms, contains('化空'));
    });

    test('申化子于午月：化破（午冲子）', () {
      expect(transformTerms('申', '子', riGanZhi: '甲寅'), contains('化破'));
    });

    test('午化戌：化墓（火墓于戌，甲寅旬戌不空）', () {
      final l = buildLunar(yueJian: '寅', riGanZhi: '甲寅');
      final terms = DongBianService.analyzeTransform(
        makeYao(branch: '午', moving: true),
        makeYao(branch: '戌'),
        l,
      ).map((t) => t.term);
      expect(terms, contains('化墓'));
      expect(terms, isNot(contains('化空')));
    });

    test('午化亥：化绝且回头克', () {
      final terms = transformTerms('午', '亥');
      expect(terms, contains('化绝'));
      expect(terms, contains('回头克'));
    });

    test('子化午：化冲', () {
      expect(transformTerms('子', '午'), contains('化冲'));
    });

    test('化出同支（爻伏吟）不出变化标签', () {
      expect(transformTerms('子', '子'), isEmpty);
    });
  });

  group('DongBianService 日冲定性（暗动/日破/冲散）', () {
    test('旺相静爻逢日冲：暗动', () {
      // 亥月子水旺，甲午日冲子（甲午旬空辰巳，子不空）
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final l = buildLunar(yueJian: '亥', riGanZhi: '甲午');
      final result = DongBianService.analyzeGua(qian, null, l);
      final terms = (result[1] ?? []).map((t) => t.term);
      expect(terms, contains('暗动'));
      expect(terms, isNot(contains('日破')));
    });

    test('休囚静爻逢日冲：日破', () {
      // 午月子水囚，甲午日冲子
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final l = buildLunar(yueJian: '午', riGanZhi: '甲午');
      final result = DongBianService.analyzeGua(qian, null, l);
      final terms = (result[1] ?? []).map((t) => t.term);
      expect(terms, contains('日破'));
      expect(terms, isNot(contains('暗动')));
    });

    test('休囚动爻逢日冲：冲散', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final l = buildLunar(yueJian: '午', riGanZhi: '甲午');
      final result = DongBianService.analyzeGua(qian, null, l);
      expect((result[1] ?? []).map((t) => t.term), contains('冲散'));
    });

    test('旺相动爻逢日冲：冲不散，无凶标签', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final l = buildLunar(yueJian: '亥', riGanZhi: '甲午');
      final result = DongBianService.analyzeGua(qian, null, l);
      final terms = (result[1] ?? []).map((t) => t.term);
      expect(terms, isNot(contains('冲散')));
      expect(terms, isNot(contains('日破')));
    });

    test('旬空静爻逢日冲不论暗动（由冲空判定）', () {
      // 甲子旬戌亥空；戊辰日（同旬）冲上爻戌
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final l = buildLunar(yueJian: '午', riGanZhi: '戊辰');
      final result = DongBianService.analyzeGua(qian, null, l);
      final terms = (result[6] ?? []).map((t) => t.term);
      expect(terms, isNot(contains('暗动')));
      expect(terms, isNot(contains('日破')));
    });
  });

  group('DongBianService 独发独静', () {
    test('一爻独动为独发', () {
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final result = DongBianService.analyzeGua(qian, null, lunar);
      expect((result[1] ?? []).map((t) => t.term), contains('独发'));
    });

    test('五动一静为独静', () {
      final qian = buildGua([9, 9, 9, 9, 7, 9]);
      final result = DongBianService.analyzeGua(qian, null, lunar);
      expect((result[5] ?? []).map((t) => t.term), contains('独静'));
    });

    test('两动无独发', () {
      final qian = buildGua([9, 9, 7, 7, 7, 7]);
      final result = DongBianService.analyzeGua(qian, null, lunar);
      expect((result[1] ?? []).map((t) => t.term), isNot(contains('独发')));
    });
  });

  group('DongBianService 变卦联动', () {
    test('动爻自动附带化爻变化标签', () {
      // 乾初爻动 → 变姤卦，初爻子化丑：子丑六合 → 化合
      final qian = buildGua([9, 7, 7, 7, 7, 7]);
      final changing = buildChangingGua(qian);
      final result = DongBianService.analyzeGua(qian, changing, lunar);
      expect((result[1] ?? []).map((t) => t.term), contains('化合'));
    });
  });
}
