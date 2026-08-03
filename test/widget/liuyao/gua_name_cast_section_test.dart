import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';
import 'package:wanxiang_paipan/presentation/widgets/cast/gua_name_cast_section.dart';

void main() {
  testWidgets('阳历模式回调携带与四柱一致的选定时间', (tester) async {
    ({
      String? year,
      String month,
      String day,
      String? hour,
      String mainGua,
      String? changingGua,
      DateTime? solarTime,
    })? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GuaNameCastSection(
              onCast:
                  (year, month, day, hour, mainGua, changingGua, solarTime) {
                captured = (
                  year: year,
                  month: month,
                  day: day,
                  hour: hour,
                  mainGua: mainGua,
                  changingGua: changingGua,
                  solarTime: solarTime,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('阳历时间'));
    await tester.pump();
    await tester.tap(find.text('起卦'));

    expect(captured, isNotNull);
    final solarTime = captured!.solarTime;
    expect(solarTime, isNotNull);
    final lunar = LunarService.getLunarInfo(solarTime!);
    expect(captured!.year, lunar.yearGanZhi);
    expect(captured!.month, lunar.monthGanZhi);
    expect(captured!.day, lunar.riGanZhi);
    expect(captured!.hour, lunar.hourGanZhi);
    expect(captured!.mainGua, '111111');
    expect(captured!.changingGua, isNull);
  });
}
