import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/widgets/relation_graph_dialog.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

LunarInfo _lunar({String yueJian = '寅', String riGanZhi = '甲寅'}) {
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
  testWidgets('有跨爻关系时渲染六爻节点、日月节点与图例', (tester) async {
    final qian = GuaCalculator.calculateGua([9, 7, 7, 7, 7, 7]);
    final lunar = _lunar();
    final report = LiuYaoAnalyzer.analyze(qian, null, lunar);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RelationGraphView(
          mainGua: qian,
          lunarInfo: lunar,
          report: report,
          yongShenPosition: 2,
        ),
      ),
    ));

    expect(find.text('生克关系图'), findsOneWidget);
    expect(find.textContaining('月建 寅'), findsOneWidget);
    expect(find.textContaining('日辰 寅'), findsOneWidget);
    // 六个爻节点
    expect(find.textContaining('初爻'), findsOneWidget);
    expect(find.textContaining('上爻'), findsOneWidget);
    // 用神节点标记
    expect(find.textContaining('·用'), findsOneWidget);
    // 图例
    expect(find.text('生扶'), findsOneWidget);
    expect(find.text('克冲刑害'), findsOneWidget);
  });

  testWidgets('无跨爻关系时显示空态文案', (tester) async {
    // 丰卦全静（卯丑亥午申戌），丑月乙丑日：丑之冲（未）合（子）皆不在卦中
    final feng = GuaCalculator.calculateGua([7, 8, 7, 7, 8, 8]);
    final lunar = _lunar(yueJian: '丑', riGanZhi: '乙丑');
    final report = LiuYaoAnalyzer.analyze(feng, null, lunar);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RelationGraphView(
          mainGua: feng,
          lunarInfo: lunar,
          report: report,
        ),
      ),
    ));

    expect(find.text('本卦当前无跨爻生克合冲关系'), findsOneWidget);
    expect(find.text('生扶'), findsNothing);
  });
}
