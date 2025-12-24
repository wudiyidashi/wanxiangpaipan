import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/divination_system.dart';
import 'models/gua.dart';
import 'models/yao.dart';
import '../../models/lunar_info.dart';

part 'liuyao_result.freezed.dart';
part 'liuyao_result.g.dart';

/// 六爻占卜结果
///
/// 继承自 DivinationResult，包含六爻特定的数据结构。
@freezed
class LiuYaoResult with _$LiuYaoResult implements DivinationResult {
  const factory LiuYaoResult({
    required String id,
    required DateTime castTime,
    required CastMethod castMethod,
    required Gua mainGua,
    Gua? changingGua,
    required LunarInfo lunarInfo,
    required List<String> liuShen,
    @Default('') String questionId,
    @Default('') String detailId,
    @Default('') String interpretationId,
  }) = _LiuYaoResult;

  factory LiuYaoResult.fromJson(Map<String, dynamic> json) =>
      _$LiuYaoResultFromJson(json);

  const LiuYaoResult._();

  /// 系统类型（实现 DivinationResult 接口）
  @override
  DivinationType get systemType => DivinationType.liuYao;

  /// 获取结果摘要（实现 DivinationResult 接口）
  @override
  String getSummary() => mainGua.name;

  /// 是否有变卦
  bool get hasChangingGua => changingGua != null;

  /// 获取世爻
  Yao get seYao => mainGua.seYao;

  /// 获取应爻
  Yao get yingYao => mainGua.yingYao;

  /// 获取所有动爻
  List<Yao> get movingYaos => mainGua.movingYaos;

  /// 是否有动爻
  bool get hasMovingYao => mainGua.hasMovingYao;
}
