import 'package:freezed_annotation/freezed_annotation.dart';

part 'lunar_info.freezed.dart';
part 'lunar_info.g.dart';

/// 农历信息模型
@freezed
class LunarInfo with _$LunarInfo {
  const factory LunarInfo({
    required String yueJian,
    required String riGan,
    required String riZhi,
    required String riGanZhi,
    required List<String> kongWang,
    required String yearGanZhi,
    required String monthGanZhi,
    String? solarTerm,
  }) = _LunarInfo;

  factory LunarInfo.fromJson(Map<String, dynamic> json) =>
      _$LunarInfoFromJson(json);

  const LunarInfo._();

  /// 检查某个地支是否空亡
  bool isKongWang(String branch) => kongWang.contains(branch);
}
