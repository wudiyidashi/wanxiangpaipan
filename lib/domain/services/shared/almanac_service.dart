import 'package:lunar/lunar.dart';
import '../../../models/daily_almanac.dart';
import 'festival_resolver.dart';

class AlmanacError implements Exception {
  final String message;
  final Object? cause;
  AlmanacError(this.message, [this.cause]);

  @override
  String toString() =>
      'AlmanacError: $message${cause != null ? ' ($cause)' : ''}';
}

/// 黄历计算服务（封装 lunar 包 Exact2 口径）。
/// 纯函数，无状态，无缓存（缓存由 ViewModel 管）。
class AlmanacService {
  const AlmanacService();

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static const _zhiOrder = [
    '子', '丑', '寅', '卯', '辰', '巳',
    '午', '未', '申', '酉', '戌', '亥',
  ];
  // 子时跨日：23-1 使用 23；其余按双数起点。
  static const _startHours = [23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21];
  static const _endHours = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23];

  DailyAlmanac getDay(DateTime date) {
    final d = _dateOnly(date);
    if (d.year < 1900 || d.year > 2099) {
      throw AlmanacError('Year out of supported range: ${d.year}');
    }

    try {
      final solar = Solar.fromYmd(d.year, d.month, d.day);
      final lunar = solar.getLunar();

      final festivals = FestivalResolver.resolve(d, lunar);
      final twelveHours = _buildTwelveHours(lunar);
      final (nextName, nextDays) = _nextJieQiInfo(lunar);
      final currentJieQi = _currentJieQi(lunar);

      return DailyAlmanac(
        date: d,
        lunarDate: _formatLunarDate(lunar),
        weekday: _weekdayCn(d.weekday),
        currentJieQi: currentJieQi,
        nextJieQi: nextName,
        nextJieQiDaysAway: nextDays,
        yearGZ: lunar.getYearInGanZhi(),
        monthGZ: lunar.getMonthInGanZhiExact(),
        dayGZ: lunar.getDayInGanZhiExact2(),
        yueXiang: lunar.getYueXiang(),
        kongWang: _kongWang(lunar),
        yi: List<String>.from(lunar.getDayYi()),
        ji: List<String>.from(lunar.getDayJi()),
        pengZuGan: lunar.getPengZuGan(),
        pengZuZhi: lunar.getPengZuZhi(),
        festivals: festivals,
        twelveHours: twelveHours,
      );
    } on AlmanacError {
      rethrow;
    } catch (e) {
      throw AlmanacError('Failed to compute almanac for $d', e);
    }
  }

  String _formatLunarDate(Lunar lunar) {
    final monthCn = lunar.getMonthInChinese();
    final dayCn = lunar.getDayInChinese();
    return '农历${monthCn}月${dayCn}';
  }

  String _weekdayCn(int w) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${names[w - 1]}';
  }

  List<String> _kongWang(Lunar lunar) {
    // Use Exact2 to match day pillar basis throughout
    final xk = lunar.getDayXunKongExact2();
    if (xk.length == 2) return [xk[0], xk[1]];
    return [];
  }

  String? _currentJieQi(Lunar lunar) {
    final name = lunar.getJieQi();
    return name.isEmpty ? null : name;
  }

  (String, int) _nextJieQiInfo(Lunar lunar) {
    final table = lunar.getJieQiTable();
    DateTime? nearest;
    String nearestName = '';
    final now = DateTime(
      lunar.getSolar().getYear(),
      lunar.getSolar().getMonth(),
      lunar.getSolar().getDay(),
    );
    table.forEach((name, solar) {
      final dt = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      if (dt.isAfter(now) &&
          (nearest == null || dt.isBefore(nearest!))) {
        nearest = dt;
        nearestName = name;
      }
    });
    if (nearest == null) return ('', 0);
    final days = nearest!.difference(now).inDays;
    return (nearestName, days);
  }

  List<HourAlmanac> _buildTwelveHours(Lunar dayLunar) {
    final solar = dayLunar.getSolar();
    final y = solar.getYear();
    final m = solar.getMonth();
    final d = solar.getDay();

    final result = <HourAlmanac>[];
    for (int i = 0; i < 12; i++) {
      final start = _startHours[i];
      final probeHour = start;
      // Build a Lunar object for this specific hour to get hour-level data
      final lt = Lunar.fromYmdHms(y, m, d, probeHour, 0, 0);
      // Use getTimeTianShen() — per-hour 天神 (uses _timeZhiIndex)
      final tianShen = lt.getTimeTianShen();
      // TIAN_SHEN_TYPE returns '黄道'/'黑道'; strip '道' to match HourAlmanac contract
      final huangHeiRaw = LunarUtil.TIAN_SHEN_TYPE[tianShen] ?? '黄道';
      final huangHei = huangHeiRaw.replaceAll('道', '');
      // TIAN_SHEN_TYPE_LUCK keys are '黄道'/'黑道'
      final luck = LunarUtil.TIAN_SHEN_TYPE_LUCK[huangHeiRaw] ?? '吉';
      final ganZhi = lt.getTimeInGanZhi();
      result.add(HourAlmanac(
        zhi: _zhiOrder[i],
        ganZhi: ganZhi,
        tianShen: tianShen,
        huangHei: huangHei,
        luck: luck,
        yi: List<String>.from(lt.getTimeYi()),
        ji: List<String>.from(lt.getTimeJi()),
        startHour: start,
        endHour: _endHours[i],
      ));
    }
    return result;
  }
}
