import 'package:lunar/lunar.dart';

void main() {
  final solar = Solar.fromDate(DateTime(2026, 7, 31, 8));
  final lunar = solar.getLunar();

  print('solar=${solar.toYmdHms()}');
  print('yearGanZhi=${lunar.getYearInGanZhi()}');
  print('monthGanZhi=${lunar.getMonthInGanZhi()}');
  print('monthBranch=${lunar.getMonthZhi()}');
  print('dayGanZhi=${lunar.getDayInGanZhi()}');
  print('hourGanZhi=${lunar.getTimeInGanZhi()}');
  print('dayXunKong=${lunar.getDayXunKong()}');
  print('jieQi=${lunar.getJieQi()}');

  final matches = <String>[];
  for (var day = DateTime(2026);
      day.year == 2026;
      day = day.add(const Duration(days: 1))) {
    final candidate =
        Solar.fromDate(DateTime(day.year, day.month, day.day, 8)).getLunar();
    if (candidate.getMonthInGanZhi() == '庚寅' &&
        candidate.getDayInGanZhi() == '癸酉') {
      matches.add('${day.toIso8601String().substring(0, 10)} 08:00');
    }
  }
  print('matchingDates=${matches.isEmpty ? 'none' : matches.join(',')}');
}
