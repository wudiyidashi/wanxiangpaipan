import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/daliuren_cast_screen.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/dlr_cast_time_service.dart';

void main() {
  testWidgets('时间预览使用固定 offset 的 DLR calendar facts', (tester) async {
    final civilTime = DlrCivilTime(
      instant: DateTime.utc(2026, 2, 3, 20, 2, 8),
      sourceUtcOffsetMinutes: 0,
    );
    final resolved = DlrCastTimeService.resolve(civilTime);
    final pillars = resolved.pillars;

    await tester.pumpWidget(
      MaterialApp(
        home: DaLiuRenCastScreen(
          initialCastTime: civilTime.instantUtc,
          initialSourceUtcOffsetMinutes: civilTime.sourceUtcOffsetMinutes,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        '${pillars.yearGanZhi}年 ${pillars.monthGanZhi}月 '
        '${pillars.dayGanZhi}日 ${pillars.hourGanZhi}时',
      ),
      findsOneWidget,
    );
    expect(find.text('2026年02月03日 20时02分'), findsOneWidget);
  });
}
