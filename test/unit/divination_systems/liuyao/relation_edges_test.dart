import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/widgets/relation_edges.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

LunarInfo lunar({String yueJian = '寅', String riGanZhi = '甲寅'}) {
  final split = TianGanDiZhiService.splitGanZhi(riGanZhi)!;
  return LunarInfo(
    yueJian: yueJian,
    riGan: split[0],
    riZhi: split[1],
    riGanZhi: riGanZhi,
    kongWang: TianGanDiZhiService.getKongWang(riGanZhi),
    yearGanZhi: '丙午',
    monthGanZhi: '庚寅',
  );
}

void main() {
  group('buildRelationEdges 爻间生克', () {
    test('乾初爻子水动：生二爻寅（有向）、克四爻午', () {
      final qian = GuaCalculator.calculateGua([9, 7, 7, 7, 7, 7]);
      final report = LiuYaoAnalyzer.analyze(qian, null, lunar());
      final edges = buildRelationEdges(report);

      final sheng = edges.firstWhere((e) => e.term == '生' && e.to == 2);
      expect(sheng.from, 1);
      expect(sheng.directed, isTrue);
      expect(sheng.kind, RelationKind.sheng);

      final ke = edges.firstWhere((e) => e.term == '克' && e.to == 4);
      expect(ke.from, 1);
      expect(ke.kind, RelationKind.ke);
    });

    test('全静卦无爻间边', () {
      final qian = GuaCalculator.calculateGua([7, 7, 7, 7, 7, 7]);
      // 寅月甲寅日：初爻子水无日月破冲合
      final report = LiuYaoAnalyzer.analyze(qian, null, lunar());
      final edges = buildRelationEdges(report);
      expect(edges.where((e) => e.from <= 6 && e.to <= 6), isEmpty);
    });
  });

  group('buildRelationEdges 合冲去重', () {
    test('泰初爻子动合四爻丑：合住+合起归一为一条六合边', () {
      final tai = GuaCalculator.calculateGua([9, 7, 7, 8, 8, 8]);
      final report = LiuYaoAnalyzer.analyze(tai, null, lunar());
      final edges = buildRelationEdges(report);
      final heEdges = edges.where((e) => e.term == '六合').toList();
      expect(heEdges, hasLength(1));
      expect(heEdges.first.directed, isFalse);
      expect({heEdges.first.from, heEdges.first.to}, {1, 4});
    });

    test('三合局三爻两两连线且去重（三角形三条边）', () {
      // 乾子(1)辰(3)动申(5)静：申子辰水局
      final qian = GuaCalculator.calculateGua([9, 7, 9, 7, 7, 7]);
      final report = LiuYaoAnalyzer.analyze(qian, null, lunar());
      final edges = buildRelationEdges(report);
      final sanHe = edges.where((e) => e.term == '三合局').toList();
      expect(sanHe, hasLength(3));
    });
  });

  group('buildRelationEdges 变爻边', () {
    test('泰初爻子化丑（化合+回头克）：按优先级取回头克，变爻→本爻', () {
      final tai = GuaCalculator.calculateGua([9, 7, 7, 8, 8, 8]);
      final changing = GuaCalculator.generateChangingGua(tai);
      final report = LiuYaoAnalyzer.analyze(tai, changing, lunar());
      final edges = buildRelationEdges(report, movingPositions: {1});
      final bian = edges.where((e) => e.isBianEdge).toList();
      expect(bian, hasLength(1));
      expect(bian.first.term, '回头克');
      expect(bian.first.from, 1 + RelationEdge.bianNodeOffset);
      expect(bian.first.to, 1);
      expect(bian.first.directed, isTrue);
    });

    test('贪合忘生克不再产生连线', () {
      final tai = GuaCalculator.calculateGua([9, 7, 7, 8, 8, 8]);
      final report = LiuYaoAnalyzer.analyze(tai, null, lunar());
      final edges = buildRelationEdges(report);
      expect(edges.where((e) => e.term.contains('贪')), isEmpty);
    });
  });

  group('buildRelationEdges 日月边', () {
    test('午月初爻子水：月破边（月建→初爻）', () {
      final qian = GuaCalculator.calculateGua([7, 7, 7, 7, 7, 7]);
      final report = LiuYaoAnalyzer.analyze(
          qian, null, lunar(yueJian: '午', riGanZhi: '甲寅'));
      final edges = buildRelationEdges(report);
      final yuePo = edges.firstWhere((e) => e.term == '月破');
      expect(yuePo.from, RelationEdge.yueNode);
      expect(yuePo.to, 1);
    });

    test('亥月甲午日冲初爻子（旺相）：暗动边（日辰→初爻）', () {
      final qian = GuaCalculator.calculateGua([7, 7, 7, 7, 7, 7]);
      final report = LiuYaoAnalyzer.analyze(
          qian, null, lunar(yueJian: '亥', riGanZhi: '甲午'));
      final edges = buildRelationEdges(report);
      final anDong = edges.firstWhere((e) => e.term == '暗动');
      expect(anDong.from, RelationEdge.riNode);
      expect(anDong.to, 1);
    });
  });
}
