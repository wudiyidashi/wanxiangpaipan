import 'package:freezed_annotation/freezed_annotation.dart';
import '../daliuren_constants.dart';

part 'shen_sha.freezed.dart';
part 'shen_sha.g.dart';

/// 神煞模型
///
/// 大六壬中的神煞，包含吉神、凶神、中性神煞。
@freezed
class ShenSha with _$ShenSha {
  const factory ShenSha({
    /// 神煞名称
    required String name,

    /// 神煞类型（吉/凶/中）
    required ShenShaType type,

    /// 所临地支
    required String diZhi,

    /// 神煞描述
    required String description,

    /// 对占断的影响说明
    String? influence,
  }) = _ShenSha;

  factory ShenSha.fromJson(Map<String, dynamic> json) =>
      _$ShenShaFromJson(json);

  const ShenSha._();

  /// 是否为吉神
  bool get isJi => type == ShenShaType.ji;

  /// 是否为凶神
  bool get isXiong => type == ShenShaType.xiong;

  /// 类型名称
  String get typeName => type.name;

  /// 完整显示文本
  String get displayText => '$name临$diZhi';
}

/// 神煞列表模型
///
/// 包含一次占断中所有的神煞信息。
@freezed
class ShenShaList with _$ShenShaList {
  const factory ShenShaList({
    /// 所有神煞
    required List<ShenSha> allShenSha,
  }) = _ShenShaList;

  factory ShenShaList.fromJson(Map<String, dynamic> json) =>
      _$ShenShaListFromJson(json);

  const ShenShaList._();

  /// 获取吉神列表
  List<ShenSha> get jiShen =>
      allShenSha.where((s) => s.type == ShenShaType.ji).toList();

  /// 获取凶神列表
  List<ShenSha> get xiongShen =>
      allShenSha.where((s) => s.type == ShenShaType.xiong).toList();

  /// 获取中性神煞列表
  List<ShenSha> get zhongShen =>
      allShenSha.where((s) => s.type == ShenShaType.zhong).toList();

  /// 吉神数量
  int get jiCount => jiShen.length;

  /// 凶神数量
  int get xiongCount => xiongShen.length;

  /// 根据地支获取神煞
  List<ShenSha> getShenShaByDiZhi(String diZhi) =>
      allShenSha.where((s) => s.diZhi == diZhi).toList();

  /// 根据名称获取神煞
  ShenSha? getShenShaByName(String name) {
    try {
      return allShenSha.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 是否有特定神煞
  bool hasShenSha(String name) =>
      allShenSha.any((s) => s.name == name);
}
