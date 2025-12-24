import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/tianpan.dart';
import 'yue_jiang_service.dart';

/// 天盘排列服务
///
/// 大六壬天盘的排列规则：月将加临时支。
/// 即将月将所代表的地支放在时支位置，然后按顺时针排列其余地支。
class TianPanService {
  TianPanService._();

  /// 排列天盘
  ///
  /// 天盘排列规则：
  /// 1. 将月将加临（放置于）时支位置
  /// 2. 其余地支按顺时针（子丑寅卯...）顺序排列
  ///
  /// 例如：月将为亥（登明），时支为午
  /// 则亥加临午位，子加临未位，丑加临申位...
  ///
  /// [yueJiang] 月将地支
  /// [shiZhi] 时支
  /// 返回天盘映射表（地盘地支 -> 天盘地支）
  static Map<String, String> arrangeTianPan(String yueJiang, String shiZhi) {
    final diZhi = DaLiuRenConstants.diZhi;
    final tianPanMap = <String, String>{};

    // 获取月将在地支中的索引
    final yueJiangIndex = DaLiuRenConstants.getDiZhiIndex(yueJiang);
    // 获取时支在地支中的索引
    final shiZhiIndex = DaLiuRenConstants.getDiZhiIndex(shiZhi);

    // 计算偏移量：月将需要移动到时支位置
    // 偏移量 = 时支索引 - 月将索引
    final offset = shiZhiIndex - yueJiangIndex;

    // 为每个地盘地支计算对应的天盘地支
    for (var i = 0; i < 12; i++) {
      final diPanZhi = diZhi[i]; // 地盘地支
      // 天盘地支索引 = 地盘索引 - 偏移量（向反方向移动）
      final tianPanIndex = (i - offset + 12) % 12;
      final tianPanZhi = diZhi[tianPanIndex];
      tianPanMap[diPanZhi] = tianPanZhi;
    }

    return tianPanMap;
  }

  /// 创建天盘模型
  ///
  /// [yueJian] 月建（月支）
  /// [shiZhi] 时支
  /// [solarTerm] 节气（可选，用于精确计算月将）
  /// 返回 TianPan 模型
  static TianPan createTianPan({
    required String yueJian,
    required String shiZhi,
    String? solarTerm,
  }) {
    // 计算月将
    final yueJiang = solarTerm != null
        ? YueJiangService.getYueJiangBySolarTerm(solarTerm, yueJian)
        : YueJiangService.getYueJiang(yueJian);

    // 获取月将名称
    final yueJiangName = YueJiangService.getYueJiangName(yueJiang);

    // 排列天盘
    final tianPanMap = arrangeTianPan(yueJiang, shiZhi);

    return TianPan(
      yueJiang: yueJiang,
      yueJiangName: yueJiangName,
      shiZhi: shiZhi,
      tianPanMap: tianPanMap,
    );
  }

  /// 根据地盘地支获取天盘地支
  ///
  /// [tianPanMap] 天盘映射表
  /// [diPanZhi] 地盘地支
  /// 返回对应的天盘地支
  static String getTianPanZhi(Map<String, String> tianPanMap, String diPanZhi) {
    return tianPanMap[diPanZhi] ?? diPanZhi;
  }

  /// 根据天盘地支获取地盘地支
  ///
  /// [tianPanMap] 天盘映射表
  /// [tianPanZhi] 天盘地支
  /// 返回对应的地盘地支列表（可能有多个）
  static List<String> getDiPanZhi(
      Map<String, String> tianPanMap, String tianPanZhi) {
    return tianPanMap.entries
        .where((entry) => entry.value == tianPanZhi)
        .map((entry) => entry.key)
        .toList();
  }
}
