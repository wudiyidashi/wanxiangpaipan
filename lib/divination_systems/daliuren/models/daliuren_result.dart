import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';
import 'si_ke.dart';
import 'san_chuan.dart';
import 'tianpan.dart';
import 'shen_jiang_config.dart';
import 'shen_sha.dart';

part 'daliuren_result.freezed.dart';
part 'daliuren_result.g.dart';

/// 大六壬占卜结果
///
/// 大六壬是中国古代三式之一，以天干地支、十二神将为基础，
/// 通过四课三传进行占断。
///
/// 核心数据结构：
/// - [tianPan]: 天盘（月将加临时支）
/// - [siKe]: 四课（日干支推演的四课）
/// - [sanChuan]: 三传（初传、中传、末传）
/// - [shenJiangConfig]: 十二神将配置
/// - [shenShaList]: 神煞列表
@freezed
class DaLiuRenResult with _$DaLiuRenResult implements DivinationResult {
  @JsonSerializable(explicitToJson: true)
  const factory DaLiuRenResult({
    /// 唯一标识
    required String id,

    /// 占卜时间
    required DateTime castTime,

    /// 起卦方式
    required CastMethod castMethod,

    /// 农历信息
    required LunarInfo lunarInfo,

    /// 天盘
    required TianPan tianPan,

    /// 四课
    required SiKe siKe,

    /// 三传
    required SanChuan sanChuan,

    /// 十二神将配置
    required ShenJiangConfig shenJiangConfig,

    /// 神煞列表
    required ShenShaList shenShaList,

    /// 占问ID（加密存储引用）
    @Default('') String questionId,

    /// 详情ID（加密存储引用）
    @Default('') String detailId,

    /// 解读ID（加密存储引用）
    @Default('') String interpretationId,
  }) = _DaLiuRenResult;

  factory DaLiuRenResult.fromJson(Map<String, dynamic> json) =>
      _$DaLiuRenResultFromJson(json);

  const DaLiuRenResult._();

  /// 系统类型（实现 DivinationResult 接口）
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  /// 获取结果摘要（实现 DivinationResult 接口）
  @override
  String getSummary() {
    final keTypeName = sanChuan.keTypeName;
    final chuChuan = sanChuan.chuChuanDiZhi;
    return '$keTypeName课 · 初传$chuChuan';
  }

  /// 获取日干
  String get riGan => siKe.riGan;

  /// 获取日支
  String get riZhi => siKe.riZhi;

  /// 获取月将
  String get yueJiang => tianPan.yueJiang;

  /// 获取时支
  String get shiZhi => tianPan.shiZhi;

  /// 获取课体类型
  String get keTypeName => sanChuan.keTypeName;

  /// 是否为伏吟课
  bool get isFuYin => sanChuan.isFuYin;

  /// 是否为反吟课
  bool get isFanYin => sanChuan.isFanYin;

  /// 初传地支
  String get chuChuan => sanChuan.chuChuanDiZhi;

  /// 中传地支
  String get zhongChuan => sanChuan.zhongChuanDiZhi;

  /// 末传地支
  String get moChuan => sanChuan.moChuanDiZhi;

  /// 吉神数量
  int get jiShenCount => shenShaList.jiCount;

  /// 凶神数量
  int get xiongShenCount => shenShaList.xiongCount;
}
