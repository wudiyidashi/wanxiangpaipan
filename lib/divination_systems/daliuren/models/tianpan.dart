import 'package:freezed_annotation/freezed_annotation.dart';

import 'tianpan_map_contract.dart';

part 'tianpan.freezed.dart';

/// 天盘模型
///
/// 大六壬的天盘，由月将加临时支而成。
/// 天盘地支随月将位置顺时针排列在地盘十二宫上。
@Freezed(copyWith: false)
class TianPan with _$TianPan {
  const factory TianPan._validated({
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

  factory TianPan({
    required String yueJiang,
    required String yueJiangName,
    required String shiZhi,
    required Map<String, String> tianPanMap,
  }) {
    final validatedMap = TianPanMapContract.validateAnchoredMap(
      yueJiang: yueJiang,
      shiZhi: shiZhi,
      tianPanMap: tianPanMap,
    );
    return TianPan._validated(
      yueJiang: yueJiang,
      yueJiangName: yueJiangName,
      shiZhi: shiZhi,
      tianPanMap: validatedMap,
    );
  }

  factory TianPan.fromJson(Map<String, dynamic> json) {
    final rawMap = json['tianPanMap'];
    if (rawMap is! Map) {
      throw ArgumentError.value(rawMap, 'tianPanMap', '天盘映射必须是对象');
    }
    final parsedMap = <String, String>{};
    for (final entry in rawMap.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw ArgumentError.value(rawMap, 'tianPanMap', '天盘键值必须是字符串');
      }
      parsedMap[entry.key as String] = entry.value as String;
    }
    return TianPan(
      yueJiang: _requiredString(json, 'yueJiang'),
      yueJiangName: _requiredString(json, 'yueJiangName'),
      shiZhi: _requiredString(json, 'shiZhi'),
      tianPanMap: parsedMap,
    );
  }

  const TianPan._();

  TianPan copyWith({
    String? yueJiang,
    String? yueJiangName,
    String? shiZhi,
    Map<String, String>? tianPanMap,
  }) =>
      TianPan(
        yueJiang: yueJiang ?? this.yueJiang,
        yueJiangName: yueJiangName ?? this.yueJiangName,
        shiZhi: shiZhi ?? this.shiZhi,
        tianPanMap: tianPanMap ?? this.tianPanMap,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'yueJiang': yueJiang,
        'yueJiangName': yueJiangName,
        'shiZhi': shiZhi,
        'tianPanMap': Map<String, String>.from(_validatedMap),
      };

  Map<String, String> get _validatedMap =>
      TianPanMapContract.validateAnchoredMap(
        yueJiang: yueJiang,
        shiZhi: shiZhi,
        tianPanMap: tianPanMap,
      );

  /// 根据地盘地支获取天盘地支
  String getTianPanZhi(String diPanZhi) {
    final validatedMap = _validatedMap;
    TianPanMapContract.validateBranch(diPanZhi, 'diPanZhi');
    return validatedMap[diPanZhi]!;
  }

  /// 获取天盘十二宫的完整显示
  /// 返回格式：[{地盘: '子', 天盘: '亥'}, ...]
  List<Map<String, String>> get fullDisplay {
    final validatedMap = _validatedMap;
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
        '天盘': validatedMap[diPan]!,
      };
    }).toList();
  }

  /// 获取月将落宫描述
  String get yueJiangDescription => '$yueJiang将（$yueJiangName）加临$shiZhi时';

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw ArgumentError.value(value, key, '必须是字符串');
    }
    return value;
  }
}
