import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/fu_shen_relation_service.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  List<String> termsAt(Map<int, List<YaoAnalysisTag>> result, int pos) =>
      (result[pos] ?? []).map((t) => t.term).toList();

  group('FuShenRelationService 飞伏生克', () {
    test('天风姤：妻财寅木伏二爻亥水下，飞生伏', () {
      final gou = buildGua([8, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final result = FuShenRelationService.analyzeGua(gou, lunar);
      expect(termsAt(result, 2), contains('飞生伏'));
      final tag = result[2]!.firstWhere((t) => t.term == '飞生伏');
      expect(tag.polarity, Polarity.ji);
      expect(tag.reason, contains('寅'));
    });

    test('天山遁：子孙子水伏初爻辰土下，飞克伏', () {
      final dun = buildGua([8, 8, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final result = FuShenRelationService.analyzeGua(dun, lunar);
      expect(termsAt(result, 1), contains('飞克伏'));
    });

    test('天山遁：妻财寅木伏二爻午火下，伏生飞（泄）', () {
      final dun = buildGua([8, 8, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final result = FuShenRelationService.analyzeGua(dun, lunar);
      expect(termsAt(result, 2), contains('伏生飞'));
    });

    test('伏克飞：伏神制飞神为有力', () {
      final tags = FuShenRelationService.analyzeFuShen(
        makeYao(position: 3, branch: '酉'), // 飞神酉金
        makeYao(position: 3, branch: '午'), // 伏神午火克酉金
        buildLunar(yueJian: '午', riGanZhi: '甲子'),
      );
      expect(tags.map((t) => t.term), contains('伏克飞'));
    });

    test('无伏神的爻不出飞伏标签', () {
      final qian = buildGua([7, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final result = FuShenRelationService.analyzeGua(qian, lunar);
      expect(result, isEmpty);
    });
  });

  group('FuShenRelationService 伏神得出/受制', () {
    test('日冲飞神：伏神得出', () {
      // 遁初爻飞神辰土，甲戌日冲辰
      final dun = buildGua([8, 8, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲戌');
      final result = FuShenRelationService.analyzeGua(dun, lunar);
      expect(termsAt(result, 1), contains('伏神得出'));
    });

    test('飞神旬空：伏神得出', () {
      // 姤二爻飞神亥水，甲子旬戌亥空
      final gou = buildGua([8, 7, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');
      final result = FuShenRelationService.analyzeGua(gou, lunar);
      expect(termsAt(result, 2), contains('伏神得出'));
    });

    test('飞克伏且日克伏神：伏神受制', () {
      // 遁初爻：飞辰土克伏子水，甲辰日辰土再克
      final dun = buildGua([8, 8, 7, 7, 7, 7]);
      final lunar = buildLunar(yueJian: '午', riGanZhi: '甲辰');
      final result = FuShenRelationService.analyzeGua(dun, lunar);
      final tags = result[1]!;
      expect(tags.map((t) => t.term), contains('伏神受制'));
      expect(tags.firstWhere((t) => t.term == '伏神受制').polarity,
          Polarity.xiong);
    });
  });
}
