import 'package:freezed_annotation/freezed_annotation.dart';
import '../daliuren_constants.dart';
import 'chuan.dart';

part 'san_chuan.freezed.dart';
part 'san_chuan.g.dart';

/// 三传模型
///
/// 大六壬的三传（初传、中传、末传），是占断的核心。
/// 三传由四课通过课体规则推导而来。
@freezed
class SanChuan with _$SanChuan {
  const factory SanChuan({
    /// 初传（发用）
    required Chuan chuChuan,

    /// 中传
    required Chuan zhongChuan,

    /// 末传
    required Chuan moChuan,

    /// 课体类型
    required KeType keType,

    /// 课体判断说明
    String? keTypeExplanation,
  }) = _SanChuan;

  factory SanChuan.fromJson(Map<String, dynamic> json) =>
      _$SanChuanFromJson(json);

  const SanChuan._();

  /// 获取所有传的列表
  List<Chuan> get allChuan => [chuChuan, zhongChuan, moChuan];

  /// 获取课体名称
  String get keTypeName => keType.name;

  /// 获取课体描述
  String get keTypeDescription => keType.description;

  /// 是否为伏吟课
  bool get isFuYin => keType == KeType.fuYin;

  /// 是否为反吟课
  bool get isFanYin => keType == KeType.fanYin;

  /// 初传地支
  String get chuChuanDiZhi => chuChuan.diZhi;

  /// 中传地支
  String get zhongChuanDiZhi => zhongChuan.diZhi;

  /// 末传地支
  String get moChuanDiZhi => moChuan.diZhi;

  /// 三传六亲列表
  List<String> get liuQinList =>
      allChuan.map((chuan) => chuan.liuQin).toList();

  /// 是否有空亡
  bool get hasKongWang => allChuan.any((chuan) => chuan.isKongWang);
}
