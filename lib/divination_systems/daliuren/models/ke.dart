import 'package:freezed_annotation/freezed_annotation.dart';
import '../daliuren_constants.dart';

part 'ke.freezed.dart';
part 'ke.g.dart';

/// 单课模型
///
/// 大六壬四课中的一课，包含上神、下神及其关系。
/// 四课分别为：一课（日干上神）、二课（日支上神）、三课（日干寄宫上神）、四课（日支上神的上神）
@freezed
class Ke with _$Ke {
  const factory Ke({
    /// 课序（1-4）
    required int index,

    /// 上神（天盘地支）
    required String shangShen,

    /// 下神（地盘地支）
    required String xiaShen,

    /// 乘神（十二神将）
    required ShenJiang chengShen,

    /// 上神五行
    required String shangShenWuXing,

    /// 下神五行
    required String xiaShenWuXing,

    /// 五行关系描述（如"上克下"、"下克上"）
    String? wuXingRelation,

    /// 是否有克（用于课体判断）
    @Default(false) bool hasKe,

    /// 是否为贼克（下克上）
    @Default(false) bool isZeiKe,

    /// 是否为比用（上克下）
    @Default(false) bool isBiYong,
  }) = _Ke;

  factory Ke.fromJson(Map<String, dynamic> json) => _$KeFromJson(json);

  const Ke._();

  /// 获取课名
  String get keName => '第$index课';

  /// 获取上神名称（带地支）
  String get shangShenDisplay => shangShen;

  /// 获取下神名称（带地支）
  String get xiaShenDisplay => xiaShen;

  /// 获取乘神名称
  String get chengShenName => chengShen.name;
}
