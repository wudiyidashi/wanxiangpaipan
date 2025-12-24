import '../../../viewmodels/divination_viewmodel.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../daliuren_system.dart';
import '../models/daliuren_result.dart';
import '../models/si_ke.dart';
import '../models/san_chuan.dart';
import '../models/tianpan.dart';
import '../models/shen_jiang_config.dart';
import '../models/shen_sha.dart';
import '../daliuren_constants.dart';

/// 大六壬 ViewModel
///
/// 继承自 DivinationViewModel，提供大六壬特定的便捷属性和方法。
class DaLiuRenViewModel extends DivinationViewModel<DaLiuRenResult> {
  /// 构造函数
  DaLiuRenViewModel({
    required DaLiuRenSystem system,
    required DivinationRepository repository,
  }) : super(system: system, repository: repository);

  // ==================== 便捷属性 ====================

  /// 获取天盘
  TianPan? get tianPan => result?.tianPan;

  /// 获取四课
  SiKe? get siKe => result?.siKe;

  /// 获取三传
  SanChuan? get sanChuan => result?.sanChuan;

  /// 获取神将配置
  ShenJiangConfig? get shenJiangConfig => result?.shenJiangConfig;

  /// 获取神煞列表
  ShenShaList? get shenShaList => result?.shenShaList;

  /// 获取日干
  String? get riGan => result?.riGan;

  /// 获取日支
  String? get riZhi => result?.riZhi;

  /// 获取月将
  String? get yueJiang => result?.yueJiang;

  /// 获取时支
  String? get shiZhi => result?.shiZhi;

  /// 获取课体名称
  String? get keTypeName => result?.keTypeName;

  /// 是否为伏吟课
  bool get isFuYin => result?.isFuYin ?? false;

  /// 是否为反吟课
  bool get isFanYin => result?.isFanYin ?? false;

  /// 初传
  String? get chuChuan => result?.chuChuan;

  /// 中传
  String? get zhongChuan => result?.zhongChuan;

  /// 末传
  String? get moChuan => result?.moChuan;

  // ==================== 便捷方法 ====================

  /// 时间起课
  ///
  /// 使用当前时间进行起课
  Future<void> castByTime({DateTime? castTime}) async {
    await cast(
      method: CastMethod.time,
      input: {},
      castTime: castTime ?? DateTime.now(),
    );
  }

  /// 手动起课
  ///
  /// [riGan] 日干
  /// [riZhi] 日支
  /// [shiZhi] 时支（可选，默认子时）
  /// [yueJian] 月建（可选，默认寅月）
  Future<void> castByManual({
    required String riGan,
    required String riZhi,
    String? shiZhi,
    String? yueJian,
  }) async {
    await cast(
      method: CastMethod.manual,
      input: {
        'riGan': riGan,
        'riZhi': riZhi,
        if (shiZhi != null) 'shiZhi': shiZhi,
        if (yueJian != null) 'yueJian': yueJian,
      },
    );
  }

  /// 获取特定神将的位置信息
  ShenJiangPosition? getShenJiangPosition(ShenJiang shenJiang) {
    return shenJiangConfig?.getPositionByShenJiang(shenJiang);
  }

  /// 根据地支获取神将
  ShenJiang? getShenJiangByDiZhi(String diZhi) {
    return shenJiangConfig?.getShenJiangByDiZhi(diZhi);
  }

  /// 获取吉神列表
  List<ShenSha> get jiShenList => shenShaList?.jiShen ?? [];

  /// 获取凶神列表
  List<ShenSha> get xiongShenList => shenShaList?.xiongShen ?? [];

  /// 判断是否有特定神煞
  bool hasShenSha(String name) => shenShaList?.hasShenSha(name) ?? false;

  /// 获取课体判断说明
  String? get keTypeExplanation => sanChuan?.keTypeExplanation;

  /// 获取月将描述
  String? get yueJiangDescription => tianPan?.yueJiangDescription;

  /// 获取贵人类型描述
  String? get guiRenTypeDescription => shenJiangConfig?.guiRenTypeDescription;

  /// 获取布神方向描述
  String? get directionDescription => shenJiangConfig?.directionDescription;
}
