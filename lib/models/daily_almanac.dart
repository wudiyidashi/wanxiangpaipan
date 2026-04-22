import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_almanac.freezed.dart';
part 'daily_almanac.g.dart';

/// 12 时辰中的一格。
@freezed
class HourAlmanac with _$HourAlmanac {
  const factory HourAlmanac({
    required String zhi, // 子/丑/...
    required String ganZhi, // "甲子"
    required String tianShen, // 青龙/明堂/...
    required String huangHei, // "黄" / "黑"
    required String luck, // "吉" / "凶"
    required List<String> yi, // 时辰宜
    required List<String> ji, // 时辰忌
    required int startHour, // 23/1/3/5/...
    required int endHour, // 1/3/5/7/...
  }) = _HourAlmanac;

  factory HourAlmanac.fromJson(Map<String, dynamic> json) =>
      _$HourAlmanacFromJson(json);
}

/// 某一公历日的完整黄历信息。
/// 时间口径：统一走 lunar 包 Exact2。
@freezed
class DailyAlmanac with _$DailyAlmanac {
  const factory DailyAlmanac({
    required DateTime date,
    required String lunarDate,
    required String weekday,
    required String? currentJieQi,
    required String nextJieQi,
    required int nextJieQiDaysAway,
    required String yearGZ,
    required String monthGZ,
    required String dayGZ,
    required String yueXiang,
    required List<String> kongWang,
    required List<String> yi,
    required List<String> ji,
    required String pengZuGan,
    required String pengZuZhi,
    required List<String> festivals,
    required List<HourAlmanac> twelveHours,
  }) = _DailyAlmanac;

  factory DailyAlmanac.fromJson(Map<String, dynamic> json) =>
      _$DailyAlmanacFromJson(json);
}
