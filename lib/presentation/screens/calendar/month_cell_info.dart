import 'package:lunar/lunar.dart';

/// 月视图单格的轻量信息（不经 AlmanacService）。
/// 每月渲染 42 个格子，为避免构造 42 个完整 DailyAlmanac，
/// 这里只取几个便宜的 lunar 字段。
class MonthCellInfo {
  final int solarDay;
  final String label;
  final bool hasJieQi;
  final bool hasMoonPhase;
  final bool hasFestival;

  const MonthCellInfo({
    required this.solarDay,
    required this.label,
    required this.hasJieQi,
    required this.hasMoonPhase,
    required this.hasFestival,
  });

  static const _moonMilestones = {'朔', '望', '上弦', '下弦'};

  factory MonthCellInfo.of(DateTime date) {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final jieQi = lunar.getJieQi();
    final yueXiang = lunar.getYueXiang();

    final hasFestival = lunar.getFestivals().isNotEmpty ||
        lunar.getOtherFestivals().isNotEmpty ||
        solar.getFestivals().isNotEmpty ||
        solar.getOtherFestivals().isNotEmpty;

    final label = jieQi.isNotEmpty ? jieQi : lunar.getDayInChinese();

    return MonthCellInfo(
      solarDay: date.day,
      label: label,
      hasJieQi: jieQi.isNotEmpty,
      hasMoonPhase: _moonMilestones.contains(yueXiang),
      hasFestival: hasFestival,
    );
  }
}
