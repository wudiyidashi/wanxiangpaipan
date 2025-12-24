import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/ke.dart';
import '../../../divination_systems/daliuren/models/si_ke.dart';
import '../../../divination_systems/daliuren/models/shen_jiang_config.dart';
import '../shared/wuxing_service.dart';

/// 四课排列服务
///
/// 大六壬四课的排列规则：
/// - 一课：日干寄宫为下神，其上天盘地支为上神
/// - 二课：一课上神为下神，其上天盘地支为上神
/// - 三课：日支为下神，其上天盘地支为上神
/// - 四课：三课上神为下神，其上天盘地支为上神
class SiKeService {
  SiKeService._();

  /// 排列四课
  ///
  /// [riGan] 日干
  /// [riZhi] 日支
  /// [tianPanMap] 天盘映射表（地盘地支 -> 天盘地支）
  /// [shenJiangConfig] 神将配置（可选，用于获取乘神）
  /// 返回 SiKe 模型
  static SiKe arrangeSiKe({
    required String riGan,
    required String riZhi,
    required Map<String, String> tianPanMap,
    ShenJiangConfig? shenJiangConfig,
  }) {
    // 获取日干寄宫
    final riGanJiGong = DaLiuRenConstants.getGanJiGong(riGan);

    // 一课：日干寄宫为下神，其上天盘地支为上神
    final ke1XiaShen = riGanJiGong;
    final ke1ShangShen = tianPanMap[ke1XiaShen] ?? ke1XiaShen;

    // 二课：一课上神为下神，其上天盘地支为上神
    final ke2XiaShen = ke1ShangShen;
    final ke2ShangShen = tianPanMap[ke2XiaShen] ?? ke2XiaShen;

    // 三课：日支为下神，其上天盘地支为上神
    final ke3XiaShen = riZhi;
    final ke3ShangShen = tianPanMap[ke3XiaShen] ?? ke3XiaShen;

    // 四课：三课上神为下神，其上天盘地支为上神
    final ke4XiaShen = ke3ShangShen;
    final ke4ShangShen = tianPanMap[ke4XiaShen] ?? ke4XiaShen;

    // 创建四课
    final ke1 = _createKe(
      index: 1,
      shangShen: ke1ShangShen,
      xiaShen: ke1XiaShen,
      riGan: riGan,
      shenJiangConfig: shenJiangConfig,
    );

    final ke2 = _createKe(
      index: 2,
      shangShen: ke2ShangShen,
      xiaShen: ke2XiaShen,
      riGan: riGan,
      shenJiangConfig: shenJiangConfig,
    );

    final ke3 = _createKe(
      index: 3,
      shangShen: ke3ShangShen,
      xiaShen: ke3XiaShen,
      riGan: riGan,
      shenJiangConfig: shenJiangConfig,
    );

    final ke4 = _createKe(
      index: 4,
      shangShen: ke4ShangShen,
      xiaShen: ke4XiaShen,
      riGan: riGan,
      shenJiangConfig: shenJiangConfig,
    );

    return SiKe(
      ke1: ke1,
      ke2: ke2,
      ke3: ke3,
      ke4: ke4,
      riGan: riGan,
      riZhi: riZhi,
    );
  }

  /// 创建单课
  static Ke _createKe({
    required int index,
    required String shangShen,
    required String xiaShen,
    required String riGan,
    ShenJiangConfig? shenJiangConfig,
  }) {
    // 获取上下神五行
    final shangShenWuXing = WuXingService.getWuXingFromBranch(shangShen);
    final xiaShenWuXing = WuXingService.getWuXingFromBranch(xiaShen);

    // 计算五行关系
    String? wuXingRelation;
    bool hasKe = false;
    bool isZeiKe = false;
    bool isBiYong = false;

    if (shangShenWuXing != null && xiaShenWuXing != null) {
      // 下克上为贼克
      if (WuXingService.isKe(xiaShenWuXing, shangShenWuXing)) {
        wuXingRelation = '下克上（贼克）';
        hasKe = true;
        isZeiKe = true;
      }
      // 上克下为比用
      else if (WuXingService.isKe(shangShenWuXing, xiaShenWuXing)) {
        wuXingRelation = '上克下';
        hasKe = true;
        isBiYong = true;
      }
      // 上生下
      else if (WuXingService.isSheng(shangShenWuXing, xiaShenWuXing)) {
        wuXingRelation = '上生下';
      }
      // 下生上
      else if (WuXingService.isSheng(xiaShenWuXing, shangShenWuXing)) {
        wuXingRelation = '下生上';
      }
      // 比和
      else if (shangShenWuXing == xiaShenWuXing) {
        wuXingRelation = '比和';
      }
    }

    // 获取乘神（神将）
    ShenJiang chengShen = ShenJiang.guiRen; // 默认值
    if (shenJiangConfig != null) {
      final sj = shenJiangConfig.getShenJiangByDiZhi(shangShen);
      if (sj != null) {
        chengShen = sj;
      }
    }

    return Ke(
      index: index,
      shangShen: shangShen,
      xiaShen: xiaShen,
      chengShen: chengShen,
      shangShenWuXing: shangShenWuXing?.name ?? '',
      xiaShenWuXing: xiaShenWuXing?.name ?? '',
      wuXingRelation: wuXingRelation,
      hasKe: hasKe,
      isZeiKe: isZeiKe,
      isBiYong: isBiYong,
    );
  }

  /// 判断四课是否为伏吟
  ///
  /// 伏吟：天地盘同位（即天盘地支与地盘地支相同）
  static bool isFuYin(Map<String, String> tianPanMap) {
    // 检查所有位置是否天地盘相同
    for (final entry in tianPanMap.entries) {
      if (entry.key != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// 判断四课是否为反吟
  ///
  /// 反吟：天地盘相冲（即天盘地支与地盘地支对冲）
  static bool isFanYin(Map<String, String> tianPanMap) {
    // 检查所有位置是否天地盘相冲
    for (final entry in tianPanMap.entries) {
      final diPan = entry.key;
      final tianPan = entry.value;
      final chong = DaLiuRenConstants.getChongZhi(diPan);
      if (tianPan != chong) {
        return false;
      }
    }
    return true;
  }
}
