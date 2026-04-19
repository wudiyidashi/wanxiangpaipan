import 'package:freezed_annotation/freezed_annotation.dart';

part 'pan_params.freezed.dart';
part 'pan_params.g.dart';

enum DaLiuRenMonthGeneralMode {
  auto('auto'),
  manual('manual');

  const DaLiuRenMonthGeneralMode(this.id);
  final String id;

  static DaLiuRenMonthGeneralMode fromId(String id) {
    return DaLiuRenMonthGeneralMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw ArgumentError('未知的月将模式: $id'),
    );
  }
}

enum DaLiuRenDayNightMode {
  auto('auto'),
  day('day'),
  night('night');

  const DaLiuRenDayNightMode(this.id);
  final String id;

  static DaLiuRenDayNightMode fromId(String id) {
    return DaLiuRenDayNightMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw ArgumentError('未知的昼夜模式: $id'),
    );
  }
}

enum DaLiuRenGuiRenVerse {
  classic('classic'),
  jiaDayAlt('jiaDayAlt');

  const DaLiuRenGuiRenVerse(this.id);
  final String id;

  static DaLiuRenGuiRenVerse fromId(String id) {
    return DaLiuRenGuiRenVerse.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw ArgumentError('未知的贵人口诀版本: $id'),
    );
  }
}

enum DaLiuRenXunShouMode {
  day('day'),
  hour('hour');

  const DaLiuRenXunShouMode(this.id);
  final String id;

  static DaLiuRenXunShouMode fromId(String id) {
    return DaLiuRenXunShouMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw ArgumentError('未知的旬位模式: $id'),
    );
  }
}

@freezed
class DaLiuRenPanParams with _$DaLiuRenPanParams {
  const factory DaLiuRenPanParams({
    int? birthYear,
    @Default(DaLiuRenMonthGeneralMode.auto)
    DaLiuRenMonthGeneralMode monthGeneralMode,
    String? manualMonthGeneral,
    @Default(DaLiuRenDayNightMode.auto) DaLiuRenDayNightMode dayNightMode,
    @Default(DaLiuRenGuiRenVerse.classic) DaLiuRenGuiRenVerse guiRenVerse,
    @Default(DaLiuRenXunShouMode.day) DaLiuRenXunShouMode xunShouMode,
    @Default(true) bool showSanChuanOnTop,
  }) = _DaLiuRenPanParams;

  factory DaLiuRenPanParams.fromJson(Map<String, dynamic> json) =>
      _$DaLiuRenPanParamsFromJson(json);

  const DaLiuRenPanParams._();

  bool get usesManualMonthGeneral =>
      monthGeneralMode == DaLiuRenMonthGeneralMode.manual;

  String get monthGeneralModeLabel =>
      monthGeneralMode == DaLiuRenMonthGeneralMode.auto ? '自动取将' : '手动月将';

  String get dayNightModeLabel => switch (dayNightMode) {
        DaLiuRenDayNightMode.auto => '昼夜自动',
        DaLiuRenDayNightMode.day => '昼贵',
        DaLiuRenDayNightMode.night => '夜贵',
      };

  String get guiRenVerseLabel => switch (guiRenVerse) {
        DaLiuRenGuiRenVerse.classic => '甲戊庚牛羊',
        DaLiuRenGuiRenVerse.jiaDayAlt => '甲羊戊庚牛',
      };

  String get xunShouModeLabel => switch (xunShouMode) {
        DaLiuRenXunShouMode.day => '日柱旬遁干',
        DaLiuRenXunShouMode.hour => '时柱旬遁干',
      };
}
