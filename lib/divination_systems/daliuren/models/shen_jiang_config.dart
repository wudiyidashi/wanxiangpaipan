import 'package:freezed_annotation/freezed_annotation.dart';
import '../daliuren_constants.dart';

part 'shen_jiang_config.freezed.dart';
part 'shen_jiang_config.g.dart';

/// 单个神将配置
@freezed
class ShenJiangPosition with _$ShenJiangPosition {
  const factory ShenJiangPosition({
    /// 神将
    required ShenJiang shenJiang,

    /// 所临地支（地盘位置）
    required String diZhi,

    /// 天盘地支（神将所乘）
    required String tianPanZhi,
  }) = _ShenJiangPosition;

  factory ShenJiangPosition.fromJson(Map<String, dynamic> json) =>
      _$ShenJiangPositionFromJson(json);

  const ShenJiangPosition._();

  /// 神将名称
  String get name => shenJiang.name;

  /// 神将描述
  String get description => shenJiang.description;

  /// 显示文本
  String get displayText => '${shenJiang.name}临$diZhi';
}

/// 十二神将配置模型
///
/// 大六壬十二神将的完整配置，包含每个神将的位置信息。
/// 神将从贵人起，阳日顺布，阴日逆布。
@freezed
class ShenJiangConfig with _$ShenJiangConfig {
  const factory ShenJiangConfig({
    /// 贵人位置（阳贵或阴贵）
    required String guiRenPosition,

    /// 是否为阳贵（昼贵）
    required bool isYangGui,

    /// 是否为阳日（阳干）
    required bool isYangRi,

    /// 十二神将配置列表
    required List<ShenJiangPosition> positions,

    /// 神将地支映射表（地支 -> 神将）
    required Map<String, ShenJiang> diZhiToShenJiang,
  }) = _ShenJiangConfig;

  factory ShenJiangConfig.fromJson(Map<String, dynamic> json) =>
      _$ShenJiangConfigFromJson(json);

  const ShenJiangConfig._();

  /// 根据地支获取神将
  ShenJiang? getShenJiangByDiZhi(String diZhi) => diZhiToShenJiang[diZhi];

  /// 获取指定神将的位置信息
  ShenJiangPosition? getPositionByShenJiang(ShenJiang shenJiang) {
    try {
      return positions.firstWhere((p) => p.shenJiang == shenJiang);
    } catch (_) {
      return null;
    }
  }

  /// 获取贵人（天乙贵人）位置
  ShenJiangPosition? get guiRen =>
      getPositionByShenJiang(ShenJiang.guiRen);

  /// 获取青龙位置
  ShenJiangPosition? get qingLong =>
      getPositionByShenJiang(ShenJiang.qingLong);

  /// 获取白虎位置
  ShenJiangPosition? get baiHu =>
      getPositionByShenJiang(ShenJiang.baiHu);

  /// 获取玄武位置
  ShenJiangPosition? get xuanWu =>
      getPositionByShenJiang(ShenJiang.xuanWu);

  /// 贵人类型描述
  String get guiRenTypeDescription => isYangGui ? '阳贵（昼贵）' : '阴贵（夜贵）';

  /// 布神方向描述
  String get directionDescription => isYangRi ? '阳日顺布' : '阴日逆布';
}
