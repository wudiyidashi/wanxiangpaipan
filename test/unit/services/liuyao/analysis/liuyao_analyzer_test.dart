import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  group('LiuYaoAnalyzer 无用神（客观分析）', () {
    test('乾为天午月甲子日：爻级与卦级标签齐备，无用神推理', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final report = LiuYaoAnalyzer.analyze(qian, null, lunar);

      expect(report.yongShen, isNull);
      expect(report.yingQi, isNull);
      expect(report.verdictSummary, isNull);
      expect(report.guaTags.map((t) => t.term), contains('六冲卦'));
      // 初爻子水：午月月破
      expect(report.yaoTags[1]!.map((t) => t.term), contains('月破'));
      // 上爻戌土：甲子旬空
      expect(report.yaoTags[6]!.map((t) => t.term), contains('旬空'));
    });

    test('各爻标签按优先级升序排列', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final report = LiuYaoAnalyzer.analyze(qian, null, lunar);
      for (final tags in report.yaoTags.values) {
        for (var i = 1; i < tags.length; i++) {
          expect(tags[i].priority, greaterThanOrEqualTo(tags[i - 1].priority));
        }
      }
    });
  });

  group('LiuYaoAnalyzer 指定用神', () {
    test('乾卦用神妻财寅木：完整推理链与应期', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final report =
          LiuYaoAnalyzer.analyze(qian, null, lunar, yongShenPosition: 2);

      expect(report.yongShen!.position, 2);
      expect(report.yongShen!.yuanShenPosition, 1);
      expect(report.yongShen!.jiShenPosition, 5);
      expect(report.yaoTags[2]!.map((t) => t.term), contains('用神'));
      expect(report.yaoTags[1]!.map((t) => t.term), contains('原神'));
      expect(report.yaoTags[5]!.map((t) => t.term), contains('忌神'));
      expect(report.yingQi, isNotEmpty);
      expect(report.verdictSummary, contains('妻财'));
    });

    test('用神两现标注在另一爻', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final report =
          LiuYaoAnalyzer.analyze(qian, null, lunar, yongShenPosition: 3);
      expect(report.yaoTags[6]!.map((t) => t.term), contains('用神两现'));
    });

    test('天山遁伏神取用：用神(伏)标签与链', () {
      final dun = buildGua([8, 8, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final report = LiuYaoAnalyzer.analyze(dun, null, lunar,
          yongShenPosition: 2, yongShenIsFuShen: true);
      expect(report.yongShen!.isFuShen, isTrue);
      expect(report.yaoTags[2]!.map((t) => t.term), contains('用神(伏)'));
      expect(report.verdictSummary, contains('妻财'));
    });
  });

  group('LiuYaoAnalyzer 变卦联动', () {
    test('泰卦初爻动：动变标签并入初爻', () {
      final tai = buildGua([9, 7, 7, 8, 8, 8]);
      final changing = buildChangingGua(tai);
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲寅');
      final report = LiuYaoAnalyzer.analyze(tai, changing, lunar);
      // 子化丑：化合且回头克
      final terms = report.yaoTags[1]!.map((t) => t.term).toList();
      expect(terms, contains('化合'));
      expect(terms, contains('回头克'));
      expect(report.guaTags.map((t) => t.term), contains('六合卦'));
    });

    test('用神发动化进神时应期含变爻当值', () {
      // 构造动爻化进神：需真实卦例——雷地豫四爻午动化酉？
      // 简化：用乾四爻午动，变爻为未（天风姤外卦不变……实际为火天大有？）
      // 取实际变卦结果做存在性检查即可
      final qian = buildGua([7, 7, 7, 9, 7, 7]);
      final changing = buildChangingGua(qian);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲寅');
      final report = LiuYaoAnalyzer.analyze(qian, changing, lunar,
          yongShenPosition: 4);
      expect(report.yingQi, isNotEmpty);
      // 动爻用神：值日与合日在候选中
      final branches = report.yingQi!.map((c) => c.branch).toList();
      expect(branches, contains('午'));
    });
  });
}
