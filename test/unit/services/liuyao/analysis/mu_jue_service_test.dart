import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/mu_jue_service.dart';

import 'helpers/analysis_fixtures.dart';

void main() {
  // 乾为天全静：初子 二寅 三辰 四午 五申 上戌
  final qianStatic = buildGua([7, 7, 7, 7, 7, 7]);
  // 上爻戌发动（午火的墓库动）
  final qianTopMoving = buildGua([7, 7, 7, 7, 7, 9]);

  group('MuJueService 入墓', () {
    test('甲戌日四爻午火：入日墓（火墓于戌）', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲戌');
      final tags =
          MuJueService.analyzeYao(qianStatic.yaos[3], qianStatic, lunar);
      final terms = tags.map((t) => t.term);
      expect(terms, contains('入日墓'));
      expect(tags.firstWhere((t) => t.term == '入日墓').polarity, Polarity.xiong);
    });

    test('戌月四爻午火：入月墓', () {
      final lunar = buildLunar(yueJian: '戌', riGanZhi: '甲子');
      final terms =
          MuJueService.analyzeYao(qianStatic.yaos[3], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, contains('入月墓'));
    });

    test('上爻戌动，四爻午火：入动墓且关联上爻', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');
      final tags =
          MuJueService.analyzeYao(qianTopMoving.yaos[3], qianTopMoving, lunar);
      final ruDongMu = tags.where((t) => t.term == '入动墓').toList();
      expect(ruDongMu, hasLength(1));
      expect(ruDongMu.first.relatedYao, contains(6));
    });

    test('墓支自身不入自己的动墓', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');
      final terms =
          MuJueService.analyzeYao(qianTopMoving.yaos[5], qianTopMoving, lunar)
              .map((t) => t.term);
      expect(terms, isNot(contains('入动墓')));
    });

    test('子日四爻午火：无入墓标签', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');
      final terms =
          MuJueService.analyzeYao(qianStatic.yaos[3], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, isNot(contains('入日墓')));
      expect(terms, isNot(contains('入月墓')));
    });
  });

  group('MuJueService 出墓', () {
    test('入动墓逢日冲墓库：出墓（辰日冲戌）', () {
      // 甲辰日：辰冲戌，冲开火库
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲辰');
      final tags =
          MuJueService.analyzeYao(qianTopMoving.yaos[3], qianTopMoving, lunar);
      final terms = tags.map((t) => t.term);
      expect(terms, contains('入动墓'));
      expect(terms, contains('出墓'));
      expect(tags.firstWhere((t) => t.term == '出墓').polarity, Polarity.ji);
    });

    test('未冲墓则无出墓', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');
      final terms =
          MuJueService.analyzeYao(qianTopMoving.yaos[3], qianTopMoving, lunar)
              .map((t) => t.term);
      expect(terms, isNot(contains('出墓')));
    });
  });

  group('MuJueService 临绝', () {
    test('乙亥日四爻午火：临绝（火绝于亥）', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '乙亥');
      final tags =
          MuJueService.analyzeYao(qianStatic.yaos[3], qianStatic, lunar);
      final terms = tags.map((t) => t.term);
      expect(terms, contains('临绝'));
      expect(tags.firstWhere((t) => t.term == '临绝').polarity, Polarity.xiong);
    });

    test('绝于月建亦临绝：亥月午火', () {
      final lunar = buildLunar(yueJian: '亥', riGanZhi: '甲子');
      final terms =
          MuJueService.analyzeYao(qianStatic.yaos[3], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, contains('临绝'));
    });

    test('非绝地无临绝标签', () {
      final lunar = buildLunar(yueJian: '寅', riGanZhi: '甲子');
      final terms =
          MuJueService.analyzeYao(qianStatic.yaos[3], qianStatic, lunar)
              .map((t) => t.term);
      expect(terms, isNot(contains('临绝')));
    });
  });
}
