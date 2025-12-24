import 'package:freezed_annotation/freezed_annotation.dart';
import '../daliuren_constants.dart';

part 'chuan.freezed.dart';
part 'chuan.g.dart';

/// 传的位置枚举
enum ChuanPosition {
  /// 初传
  chu('初传'),

  /// 中传
  zhong('中传'),

  /// 末传
  mo('末传');

  const ChuanPosition(this.displayName);
  final String displayName;
}

/// 单传模型
///
/// 三传中的一传，包含地支、五行、乘神、六亲等信息。
@freezed
class Chuan with _$Chuan {
  const factory Chuan({
    /// 传的位置（初、中、末）
    required ChuanPosition position,

    /// 地支
    required String diZhi,

    /// 五行
    required String wuXing,

    /// 乘神（十二神将）
    required ShenJiang chengShen,

    /// 六亲（相对于日干）
    required String liuQin,

    /// 天干（三传的天干寄托）
    String? tianGan,

    /// 是否为旺相
    @Default(false) bool isWangXiang,

    /// 是否落空亡
    @Default(false) bool isKongWang,

    /// 与日干的关系描述
    String? relationToRiGan,
  }) = _Chuan;

  factory Chuan.fromJson(Map<String, dynamic> json) => _$ChuanFromJson(json);

  const Chuan._();

  /// 获取传名
  String get chuanName => position.displayName;

  /// 获取乘神名称
  String get chengShenName => chengShen.name;

  /// 获取完整显示文本
  String get displayText => '$diZhi ($liuQin)';
}
