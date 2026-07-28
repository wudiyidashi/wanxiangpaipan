import 'package:lunar/lunar.dart';

import '../../../divination_systems/daliuren/models/dlr_cast_time.dart';
import '../../../models/lunar_info.dart';
import '../shared/tiangan_dizhi_service.dart';
import 'yue_jiang_service.dart';

class DlrCastTimeService {
  DlrCastTimeService._();

  static const int beijingUtcOffsetMinutes = 480;

  static DlrResolvedCastTime resolve(DlrCivilTime civilTime) {
    final beijingWall = DlrCivilTime.wallTimeAtOffset(
      civilTime.instantUtc,
      beijingUtcOffsetMinutes,
    );
    final sourceWall = civilTime.sourceWallTime;
    final beijingLunar = Solar.fromDate(beijingWall).getLunar();
    final sourceLunar = Solar.fromDate(sourceWall).getLunar();

    final yearGanZhi = beijingLunar.getYearInGanZhiExact();
    final monthGanZhi = beijingLunar.getMonthInGanZhiExact();
    final dayGanZhi = sourceLunar.getDayInGanZhi();
    final dayGan = dayGanZhi.substring(0, 1);
    final dayZhi = dayGanZhi.substring(1);
    final hourZhi = sourceLunar.getTimeZhi();
    final hourGan = DlrPillars.expectedHourGanFor(
      dayGan: dayGan,
      hourZhi: hourZhi,
    );
    final hourGanZhi = '$hourGan$hourZhi';
    final pillars = DlrPillars(
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      dayGanZhi: dayGanZhi,
      hourGanZhi: hourGanZhi,
    );
    final monthGeneralResolution = YueJiangService.resolve(civilTime);
    final lunarInfo = LunarInfo(
      yueJian: beijingLunar.getMonthZhiExact(),
      riGan: dayGan,
      riZhi: dayZhi,
      riGanZhi: dayGanZhi,
      hourGanZhi: hourGanZhi,
      kongWang: TianGanDiZhiService.getKongWang(dayGanZhi),
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      solarTerm: beijingLunar.getPrevJieQi(false).getName(),
    );

    return DlrResolvedCastTime(
      civilTime: civilTime,
      pillars: pillars,
      lunarInfo: lunarInfo,
      monthGeneralResolution: monthGeneralResolution,
    );
  }

  static String formatLunarDate(DlrCivilTime civilTime) {
    final lunar = Solar.fromDate(civilTime.sourceWallTime).getLunar();
    return '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }
}
