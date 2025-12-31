import 'package:freezed_annotation/freezed_annotation.dart';

part 'tianpan.freezed.dart';
part 'tianpan.g.dart';

/// 天盘模型
///
/// 大六壬的天盘，由月将加临时支而成。
/// 天盘地支随月将位置顺时针排列在地盘十二宫上。
@freezed
class TianPan with _$TianPan {
  const factory TianPan({
    /// 月将（太阳所在宫位的对冲）
    required String yueJiang,

    /// 月将名称（如"登明"、"河魁"等）
    required String yueJiangName,

    /// 时支（起课时辰）
    required String shiZhi,

    /// 天盘地支映射表（地盘地支 -> 天盘地支）
    /// 例如：{'子': '亥', '丑': '子', ...}
    required Map<String, String> tianPanMap,
  }) = _TianPan;

  factory TianPan.fromJson(Map<String, dynamic> json) =>
      _$TianPanFromJson(json);

  const TianPan._();

  /// 根据地盘地支获取天盘地支
  String getTianPanZhi(String diPanZhi) => tianPanMap[diPanZhi] ?? diPanZhi;

  /// 获取天盘十二宫的完整显示
  /// 返回格式：[{地盘: '子', 天盘: '亥'}, ...]
  List<Map<String, String>> get fullDisplay {
    const diZhiOrder = [
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥'
    ];
    return diZhiOrder.map((diPan) {
      return {
        '地盘': diPan,
        '天盘': tianPanMap[diPan] ?? diPan,
      };
    }).toList();
  }

  /// 获取月将落宫描述
  String get yueJiangDescription => '$yueJiang将（$yueJiangName）加临$shiZhi时';
}
