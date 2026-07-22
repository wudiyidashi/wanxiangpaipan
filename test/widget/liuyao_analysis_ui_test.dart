import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/widgets/analysis_overview_card.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/widgets/ying_qi_card.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';
import 'package:wanxiang_paipan/presentation/widgets/liuyao_table_widget.dart';

LunarInfo _lunar() {
  const riGanZhi = '甲子';
  final split = TianGanDiZhiService.splitGanZhi(riGanZhi)!;
  return LunarInfo(
    yueJian: '午',
    riGan: split[0],
    riZhi: split[1],
    riGanZhi: riGanZhi,
    kongWang: TianGanDiZhiService.getKongWang(riGanZhi),
    yearGanZhi: '丙午',
    monthGanZhi: '甲午',
  );
}

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  final qian = GuaCalculator.calculateGua([7, 7, 7, 7, 7, 7]);
  const liuShen = ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'];

  group('LiuYaoTableWidget 分析徽标', () {
    testWidgets('提供 yaoTags 时渲染内联徽标', (tester) async {
      final report = LiuYaoAnalyzer.analyze(qian, null, _lunar());
      await tester.pumpWidget(_wrap(LiuYaoTableWidget(
        gua: qian,
        liuShen: liuShen,
        title: '本卦',
        yaoTags: report.yaoTags,
      )));
      // 初爻子水午月：月破徽标
      expect(find.text('月破'), findsOneWidget);
      // 上爻戌土甲子旬：旬空徽标
      expect(find.text('旬空'), findsOneWidget);
    });

    testWidgets('不传 yaoTags 时行为与原版一致（无徽标）', (tester) async {
      await tester.pumpWidget(_wrap(LiuYaoTableWidget(
        gua: qian,
        liuShen: liuShen,
        title: '本卦',
      )));
      expect(find.text('月破'), findsNothing);
    });

    testWidgets('点击爻行触发 onYaoTap', (tester) async {
      int? tapped;
      await tester.pumpWidget(_wrap(LiuYaoTableWidget(
        gua: qian,
        liuShen: liuShen,
        title: '本卦',
        onYaoTap: (position) => tapped = position,
      )));
      // 上爻（第一行数据行）：戌
      await tester.tap(find.textContaining('戌').first);
      expect(tapped, 6);
    });
  });

  group('AnalysisOverviewCard 状态', () {
    testWidgets('未选用神显示引导态', (tester) async {
      final report = LiuYaoAnalyzer.analyze(qian, null, _lunar());
      await tester.pumpWidget(_wrap(AnalysisOverviewCard(
        mainGua: qian,
        report: report,
        yongShenPosition: null,
        yongShenIsFuShen: false,
        onSelectYongShen: (_, {bool isFuShen = false}) {},
        onClearYongShen: () {},
      )));
      expect(find.text('选用神'), findsOneWidget);
      expect(find.text('取消用神'), findsNothing);
    });

    testWidgets('选定用神后显示推理链与结论', (tester) async {
      final report =
          LiuYaoAnalyzer.analyze(qian, null, _lunar(), yongShenPosition: 2);
      await tester.pumpWidget(_wrap(AnalysisOverviewCard(
        mainGua: qian,
        report: report,
        yongShenPosition: 2,
        yongShenIsFuShen: false,
        onSelectYongShen: (_, {bool isFuShen = false}) {},
        onClearYongShen: () {},
      )));
      expect(find.textContaining('用神'), findsWidgets);
      expect(find.textContaining('原神'), findsOneWidget);
      expect(find.textContaining('忌神'), findsOneWidget);
      expect(find.text('取消用神'), findsOneWidget);
    });
  });

  group('YingQiCard', () {
    testWidgets('渲染候选应期', (tester) async {
      final report =
          LiuYaoAnalyzer.analyze(qian, null, _lunar(), yongShenPosition: 2);
      await tester.pumpWidget(_wrap(YingQiCard(
        candidates: report.yingQi!,
        onViewCalendar: () {},
      )));
      expect(find.text('应期推算'), findsOneWidget);
      expect(find.text('查看应期日历'), findsOneWidget);
    });
  });
}
