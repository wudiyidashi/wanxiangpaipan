import 'package:freezed_annotation/freezed_annotation.dart';
import 'ke.dart';

part 'si_ke.freezed.dart';
part 'si_ke.g.dart';

/// 四课模型
///
/// 大六壬的四课，是判断课体和推导三传的基础。
/// 四课由日干支推演而成：
/// - 一课：日干上神（日干寄宫的天盘地支）
/// - 二课：日干寄宫（日干所寄的地支）
/// - 三课：日支上神（日支的天盘地支）
/// - 四课：日支本位（日支本身）
@freezed
class SiKe with _$SiKe {
  @JsonSerializable(explicitToJson: true)
  const factory SiKe({
    /// 第一课
    required Ke ke1,

    /// 第二课
    required Ke ke2,

    /// 第三课
    required Ke ke3,

    /// 第四课
    required Ke ke4,

    /// 日干
    required String riGan,

    /// 日支
    required String riZhi,
  }) = _SiKe;

  factory SiKe.fromJson(Map<String, dynamic> json) => _$SiKeFromJson(json);

  const SiKe._();

  /// 获取所有课的列表
  List<Ke> get allKe => [ke1, ke2, ke3, ke4];

  /// 获取有贼克的课（下克上）
  List<Ke> get zeiKeList => allKe.where((ke) => ke.isZeiKe).toList();

  /// 获取有比用的课（上克下）
  List<Ke> get biYongList => allKe.where((ke) => ke.isBiYong).toList();

  /// 是否有贼克
  bool get hasZeiKe => zeiKeList.isNotEmpty;

  /// 是否有比用
  bool get hasBiYong => biYongList.isNotEmpty;

  /// 贼克数量
  int get zeiKeCount => zeiKeList.length;

  /// 比用数量
  int get biYongCount => biYongList.length;
}
