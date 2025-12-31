/// 天干地支服务
///
/// 提供天干地支相关的基础计算功能，可被所有术数系统复用。
/// 所有方法均为纯静态函数，无副作用。
class TianGanDiZhiService {
  TianGanDiZhiService._();

  /// 十天干
  static const List<String> tianGan = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸'
  ];

  /// 十二地支
  static const List<String> diZhi = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥'
  ];

  /// 六十甲子（天干地支组合）
  static const List<String> liuShiJiaZi = [
    '甲子',
    '乙丑',
    '丙寅',
    '丁卯',
    '戊辰',
    '己巳',
    '庚午',
    '辛未',
    '壬申',
    '癸酉',
    '甲戌',
    '乙亥',
    '丙子',
    '丁丑',
    '戊寅',
    '己卯',
    '庚辰',
    '辛巳',
    '壬午',
    '癸未',
    '甲申',
    '乙酉',
    '丙戌',
    '丁亥',
    '戊子',
    '己丑',
    '庚寅',
    '辛卯',
    '壬辰',
    '癸巳',
    '甲午',
    '乙未',
    '丙申',
    '丁酉',
    '戊戌',
    '己亥',
    '庚子',
    '辛丑',
    '壬寅',
    '癸卯',
    '甲辰',
    '乙巳',
    '丙午',
    '丁未',
    '戊申',
    '己酉',
    '庚戌',
    '辛亥',
    '壬子',
    '癸丑',
    '甲寅',
    '乙卯',
    '丙辰',
    '丁巳',
    '戊午',
    '己未',
    '庚申',
    '辛酉',
    '壬戌',
    '癸亥',
  ];

  /// 获取天干索引（0-9）
  ///
  /// 如果天干不存在，返回 -1
  static int getTianGanIndex(String gan) {
    return tianGan.indexOf(gan);
  }

  /// 获取地支索引（0-11）
  ///
  /// 如果地支不存在，返回 -1
  static int getDiZhiIndex(String zhi) {
    return diZhi.indexOf(zhi);
  }

  /// 根据索引获取天干
  ///
  /// [index] 天干索引（0-9）
  /// 如果索引超出范围，使用模运算循环
  static String getTianGanByIndex(int index) {
    return tianGan[index % 10];
  }

  /// 根据索引获取地支
  ///
  /// [index] 地支索引（0-11）
  /// 如果索引超出范围，使用模运算循环
  static String getDiZhiByIndex(int index) {
    return diZhi[index % 12];
  }

  /// 计算干支组合
  ///
  /// [index] 六十甲子索引（0-59）
  /// 返回干支组合字符串，如 "甲子"
  static String getGanZhi(int index) {
    final normalizedIndex = index % 60;
    return liuShiJiaZi[normalizedIndex];
  }

  /// 根据干支组合获取索引
  ///
  /// [ganZhi] 干支组合，如 "甲子"
  /// 返回六十甲子索引（0-59），如果不存在返回 -1
  static int getGanZhiIndex(String ganZhi) {
    return liuShiJiaZi.indexOf(ganZhi);
  }

  /// 判断是否为有效的天干
  static bool isValidTianGan(String gan) {
    return tianGan.contains(gan);
  }

  /// 判断是否为有效的地支
  static bool isValidDiZhi(String zhi) {
    return diZhi.contains(zhi);
  }

  /// 判断是否为有效的干支组合
  static bool isValidGanZhi(String ganZhi) {
    return liuShiJiaZi.contains(ganZhi);
  }

  /// 计算下一个天干
  ///
  /// [gan] 当前天干
  /// 返回下一个天干，如果输入无效返回 null
  static String? getNextTianGan(String gan) {
    final index = getTianGanIndex(gan);
    if (index == -1) return null;
    return getTianGanByIndex(index + 1);
  }

  /// 计算下一个地支
  ///
  /// [zhi] 当前地支
  /// 返回下一个地支，如果输入无效返回 null
  static String? getNextDiZhi(String zhi) {
    final index = getDiZhiIndex(zhi);
    if (index == -1) return null;
    return getDiZhiByIndex(index + 1);
  }

  /// 计算天干地支的距离
  ///
  /// [from] 起始天干或地支
  /// [to] 目标天干或地支
  /// [isTianGan] 是否为天干（true）还是地支（false）
  /// 返回从 from 到 to 的距离（正数表示顺时针，负数表示逆时针）
  static int getDistance(String from, String to, {required bool isTianGan}) {
    if (isTianGan) {
      final fromIndex = getTianGanIndex(from);
      final toIndex = getTianGanIndex(to);
      if (fromIndex == -1 || toIndex == -1) return 0;
      return (toIndex - fromIndex) % 10;
    } else {
      final fromIndex = getDiZhiIndex(from);
      final toIndex = getDiZhiIndex(to);
      if (fromIndex == -1 || toIndex == -1) return 0;
      return (toIndex - fromIndex) % 12;
    }
  }

  /// 根据天干地支索引计算干支组合
  ///
  /// [ganIndex] 天干索引（0-9）
  /// [zhiIndex] 地支索引（0-11）
  /// 返回干支组合字符串
  static String combineGanZhi(int ganIndex, int zhiIndex) {
    final gan = getTianGanByIndex(ganIndex);
    final zhi = getDiZhiByIndex(zhiIndex);
    return '$gan$zhi';
  }

  /// 拆分干支组合
  ///
  /// [ganZhi] 干支组合，如 "甲子"
  /// 返回 [天干, 地支] 数组，如果输入无效返回 null
  static List<String>? splitGanZhi(String ganZhi) {
    if (ganZhi.length != 2) return null;
    final gan = ganZhi[0];
    final zhi = ganZhi[1];
    if (!isValidTianGan(gan) || !isValidDiZhi(zhi)) return null;
    return [gan, zhi];
  }

  /// 计算空亡（旬空）
  ///
  /// 空亡是六爻占卜中的重要概念，根据日干支所在的旬来确定。
  /// 六十甲子分为六旬，每旬有两个空亡地支（相邻的两个地支）。
  ///
  /// 旬空规则：
  /// - 甲子旬（甲子-癸酉）：空戌亥
  /// - 甲戌旬（甲戌-癸未）：空申酉
  /// - 甲申旬（甲申-癸巳）：空午未
  /// - 甲午旬（甲午-癸卯）：空辰巳
  /// - 甲辰旬（甲辰-癸丑）：空寅卯
  /// - 甲寅旬（甲寅-癸亥）：空子丑
  ///
  /// [dayGanZhi] 日干支，如 "甲子"、"乙丑" 等
  /// 返回空亡的两个地支，如果日干支无效返回空列表
  static List<String> getKongWang(String dayGanZhi) {
    final index = getGanZhiIndex(dayGanZhi);
    if (index == -1) return [];

    // 计算所在旬的起始索引（每旬10个干支）
    final xunStartIndex = (index ~/ 10) * 10;

    // 计算空亡地支的索引
    // 每旬的空亡是该旬最后两个地支（第10和第11个地支）
    // 例如：甲子旬（0-9），地支从子（0）到酉（9），空戌（10）亥（11）
    final kongWangZhiIndex1 = (xunStartIndex + 10) % 12;
    final kongWangZhiIndex2 = (xunStartIndex + 11) % 12;

    return [
      getDiZhiByIndex(kongWangZhiIndex1),
      getDiZhiByIndex(kongWangZhiIndex2),
    ];
  }

  /// 判断地支是否在空亡中
  ///
  /// [zhi] 地支
  /// [dayGanZhi] 日干支
  /// 返回 true 表示该地支在空亡中，false 表示不在
  static bool isKongWang(String zhi, String dayGanZhi) {
    final kongWangList = getKongWang(dayGanZhi);
    return kongWangList.contains(zhi);
  }
}
