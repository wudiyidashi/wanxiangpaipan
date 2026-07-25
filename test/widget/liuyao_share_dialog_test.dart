import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/widgets/liuyao_share_dialog.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  testWidgets('分享预览按占问、时间、干支、神煞顺序显示', (tester) async {
    final lunar = LunarInfo(
      yueJian: '未',
      riGan: '戊',
      riZhi: '戌',
      riGanZhi: '戊戌',
      hourGanZhi: '庚申',
      kongWang: const ['辰', '巳'],
      yearGanZhi: '丙午',
      monthGanZhi: '乙未',
    );
    final gua = GuaCalculator.calculateGua([7, 7, 7, 7, 7, 7]);
    final result = LiuYaoResult(
      id: 'share-test',
      castTime: DateTime(2026, 7, 24, 9, 30),
      castMethod: CastMethod.time,
      mainGua: gua,
      lunarInfo: lunar,
      liuShen: const ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
    );
    final report = LiuYaoAnalyzer.analyze(gua, null, lunar);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLiuYaoShareDialog(
              context,
              result: result,
              report: report,
              question: '求财',
            ),
            child: const Text('打开分享'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('打开分享'));
    await tester.pumpAndSettle();

    const expectedLines = [
      '占问：求财',
      '时间：2026-07-24 09:30',
      '干支：丙午年 乙未月 戊戌日 庚申时（空 辰巳）',
      '神煞：驿马申　桃花卯　日禄巳　贵人丑未',
    ];
    for (final line in expectedLines) {
      expect(find.text(line), findsOneWidget);
    }

    final topOffsets = expectedLines
        .map((line) => tester.getTopLeft(find.text(line)).dy)
        .toList();
    expect(topOffsets, orderedEquals([...topOffsets]..sort()));
  });
}
