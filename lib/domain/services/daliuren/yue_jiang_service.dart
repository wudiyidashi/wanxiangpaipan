import '../../../divination_systems/daliuren/daliuren_constants.dart';

/// 月将计算服务
///
/// 大六壬中月将是排盘的起点，由节气确定。
/// 月将为太阳所在宫位的对冲。
class YueJiangService {
  YueJiangService._();

  /// 根据月建（月支）获取月将
  ///
  /// 月将是太阳所在宫位的对冲。
  /// 正月（寅月）太阳在亥宫，对冲为巳，但大六壬中月将取亥（太阳位置）。
  ///
  /// 实际上，大六壬月将的对应关系是：
  /// - 正月（寅月）：亥将（登明）
  /// - 二月（卯月）：戌将（河魁）
  /// - 以此类推...
  ///
  /// [yueJian] 月建（月支），如 "寅"、"卯" 等
  /// 返回月将地支
  static String getYueJiang(String yueJian) {
    return DaLiuRenConstants.yueJianToYueJiang[yueJian] ?? yueJian;
  }

  /// 获取月将名称
  ///
  /// 十二月将各有名称：
  /// - 子将：神后
  /// - 丑将：大吉
  /// - 寅将：功曹
  /// - 卯将：太冲
  /// - 辰将：天罡
  /// - 巳将：太乙
  /// - 午将：胜光
  /// - 未将：小吉
  /// - 申将：传送
  /// - 酉将：从魁
  /// - 戌将：河魁
  /// - 亥将：登明
  ///
  /// [yueJiang] 月将地支
  /// 返回月将名称
  static String getYueJiangName(String yueJiang) {
    return DaLiuRenConstants.yueJiangName[yueJiang] ?? '';
  }

  /// 根据月建同时获取月将和月将名称
  ///
  /// [yueJian] 月建（月支）
  /// 返回 {月将地支, 月将名称}
  static ({String yueJiang, String name}) getYueJiangInfo(String yueJian) {
    final yueJiang = getYueJiang(yueJian);
    final name = getYueJiangName(yueJiang);
    return (yueJiang: yueJiang, name: name);
  }

  /// 根据节气精确计算月将
  ///
  /// 大六壬月将的切换以节气为准，而非农历月份。
  /// 这里根据节气名称返回对应的月将。
  ///
  /// 节气与月将对应：
  /// - 雨水后至春分前：亥将（登明）
  /// - 春分后至谷雨前：戌将（河魁）
  /// - 谷雨后至小满前：酉将（从魁）
  /// - 小满后至夏至前：申将（传送）
  /// - 夏至后至大暑前：未将（小吉）
  /// - 大暑后至处暑前：午将（胜光）
  /// - 处暑后至秋分前：巳将（太乙）
  /// - 秋分后至霜降前：辰将（天罡）
  /// - 霜降后至小雪前：卯将（太冲）
  /// - 小雪后至冬至前：寅将（功曹）
  /// - 冬至后至大寒前：丑将（大吉）
  /// - 大寒后至雨水前：子将（神后）
  ///
  /// [solarTerm] 当前节气名称，可为空
  /// [yueJian] 月建（月支），作为备用
  /// 返回月将地支
  static String getYueJiangBySolarTerm(String? solarTerm, String yueJian) {
    if (solarTerm == null || solarTerm.isEmpty) {
      return getYueJiang(yueJian);
    }

    // 节气到月将的映射
    const solarTermToYueJiang = {
      '雨水': '亥',
      '惊蛰': '亥',
      '春分': '戌',
      '清明': '戌',
      '谷雨': '酉',
      '立夏': '酉',
      '小满': '申',
      '芒种': '申',
      '夏至': '未',
      '小暑': '未',
      '大暑': '午',
      '立秋': '午',
      '处暑': '巳',
      '白露': '巳',
      '秋分': '辰',
      '寒露': '辰',
      '霜降': '卯',
      '立冬': '卯',
      '小雪': '寅',
      '大雪': '寅',
      '冬至': '丑',
      '小寒': '丑',
      '大寒': '子',
      '立春': '子',
    };

    return solarTermToYueJiang[solarTerm] ?? getYueJiang(yueJian);
  }
}
