import 'package:lunar/lunar.dart';
import '../../../models/lunar_info.dart';

/// 农历计算服务（封装 lunar 库）
class LunarService {
  LunarService._();

  /// 根据公历时间获取农历信息
  static LunarInfo getLunarInfo(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();

    final riGanZhi = lunar.getDayInGanZhi();
    final riGan = lunar.getDayGan();
    final riZhi = lunar.getDayZhi();
    final yueJian = lunar.getMonthZhi();
    final kongWang = _calculateKongWang(lunar);
    final yearGanZhi = lunar.getYearInGanZhi();
    final monthGanZhi = lunar.getMonthInGanZhi();
    final solarTerm = lunar.getJieQi();

    return LunarInfo(
      yueJian: yueJian,
      riGan: riGan,
      riZhi: riZhi,
      riGanZhi: riGanZhi,
      kongWang: kongWang,
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      solarTerm: solarTerm.isNotEmpty ? solarTerm : null,
    );
  }

  /// 计算空亡（两个相邻地支）
  static List<String> _calculateKongWang(Lunar lunar) {
    final xunKong = lunar.getDayXunKong();
    if (xunKong.length == 2) {
      return [xunKong[0], xunKong[1]];
    }
    return [];
  }

  /// 获取日干（用于六神计算）
  static String getDayGan(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();
    return lunar.getDayGan();
  }
}
