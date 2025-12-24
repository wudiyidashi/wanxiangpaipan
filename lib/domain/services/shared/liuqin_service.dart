import 'wuxing_service.dart';

/// 六亲枚举
///
/// 六亲是六爻占卜中用于判断事物关系的重要概念。
enum LiuQin {
  fuMu('父母'),
  xiongDi('兄弟'),
  ziSun('子孙'),
  qiCai('妻财'),
  guanGui('官鬼');

  const LiuQin(this.name);
  final String name;
}

/// 六亲服务
///
/// 提供六亲计算功能，基于五行生克关系。
/// 可被六爻及其他术数系统复用。
/// 所有方法均为纯静态函数，无副作用。
class LiuQinService {
  LiuQinService._();

  /// 根据五行关系计算六亲
  ///
  /// 六亲计算规则：
  /// - 我生者为子孙
  /// - 生我者为父母
  /// - 克我者为官鬼
  /// - 我克者为妻财
  /// - 比和者为兄弟
  ///
  /// [gongWuXing] 宫位五行（主体）
  /// [yaoWuXing] 爻的五行（客体）
  /// 返回对应的六亲
  static LiuQin calculateLiuQin(WuXing gongWuXing, WuXing yaoWuXing) {
    final relation = WuXingService.getRelation(gongWuXing, yaoWuXing);

    switch (relation) {
      case WuXingRelation.woSheng:
        return LiuQin.ziSun;   // 我生者为子孙
      case WuXingRelation.shengWo:
        return LiuQin.fuMu;    // 生我者为父母
      case WuXingRelation.keWo:
        return LiuQin.guanGui; // 克我者为官鬼
      case WuXingRelation.woKe:
        return LiuQin.qiCai;   // 我克者为妻财
      case WuXingRelation.biHe:
        return LiuQin.xiongDi; // 比和者为兄弟
    }
  }

  /// 根据宫位名称和爻的五行计算六亲
  ///
  /// [baGongName] 八宫名称，如 "乾"、"坤" 等
  /// [yaoWuXing] 爻的五行
  /// 返回对应的六亲，如果宫位名称无效返回 null
  static LiuQin? calculateLiuQinByGongName(String baGongName, WuXing yaoWuXing) {
    final gongWuXing = _getGongWuXing(baGongName);
    if (gongWuXing == null) return null;
    return calculateLiuQin(gongWuXing, yaoWuXing);
  }

  /// 根据宫位名称和地支计算六亲
  ///
  /// [baGongName] 八宫名称
  /// [branch] 地支
  /// 返回对应的六亲，如果参数无效返回 null
  static LiuQin? calculateLiuQinByBranch(String baGongName, String branch) {
    final gongWuXing = _getGongWuXing(baGongName);
    final yaoWuXing = WuXingService.getWuXingFromBranch(branch);

    if (gongWuXing == null || yaoWuXing == null) return null;
    return calculateLiuQin(gongWuXing, yaoWuXing);
  }

  /// 获取宫位对应的五行
  ///
  /// [baGongName] 八宫名称
  /// 返回对应的五行，如果宫位名称无效返回 null
  static WuXing? _getGongWuXing(String baGongName) {
    const baGongToWuXing = {
      '乾': WuXing.jin,
      '坤': WuXing.tu,
      '震': WuXing.mu,
      '巽': WuXing.mu,
      '坎': WuXing.shui,
      '离': WuXing.huo,
      '艮': WuXing.tu,
      '兑': WuXing.jin,
    };
    return baGongToWuXing[baGongName];
  }

  /// 判断六亲是否为吉神
  ///
  /// 在六爻占卜中，子孙和妻财通常被视为吉神
  static bool isJiShen(LiuQin liuQin) {
    return liuQin == LiuQin.ziSun || liuQin == LiuQin.qiCai;
  }

  /// 判断六亲是否为凶神
  ///
  /// 在六爻占卜中，官鬼通常被视为凶神
  static bool isXiongShen(LiuQin liuQin) {
    return liuQin == LiuQin.guanGui;
  }

  /// 判断六亲是否为中性
  ///
  /// 父母和兄弟通常被视为中性
  static bool isNeutral(LiuQin liuQin) {
    return liuQin == LiuQin.fuMu || liuQin == LiuQin.xiongDi;
  }

  /// 获取六亲的中文名称
  static String getLiuQinName(LiuQin liuQin) {
    return liuQin.name;
  }

  /// 根据六亲获取其代表的含义（用于解卦参考）
  ///
  /// 返回六亲在不同占卜场景中的常见含义
  static List<String> getLiuQinMeanings(LiuQin liuQin) {
    switch (liuQin) {
      case LiuQin.fuMu:
        return ['父母', '长辈', '文书', '房屋', '衣服', '舟车'];
      case LiuQin.xiongDi:
        return ['兄弟', '姐妹', '朋友', '同事', '竞争对手'];
      case LiuQin.ziSun:
        return ['子女', '晚辈', '医药', '僧道', '忠臣', '解忧'];
      case LiuQin.qiCai:
        return ['妻子', '财物', '钱财', '身体', '奴仆'];
      case LiuQin.guanGui:
        return ['官府', '上司', '疾病', '灾祸', '丈夫', '盗贼'];
    }
  }

  /// 批量计算六亲
  ///
  /// [gongWuXing] 宫位五行
  /// [yaoWuXingList] 爻的五行列表
  /// 返回对应的六亲列表
  static List<LiuQin> calculateLiuQinList(
    WuXing gongWuXing,
    List<WuXing> yaoWuXingList,
  ) {
    return yaoWuXingList
        .map((yaoWuXing) => calculateLiuQin(gongWuXing, yaoWuXing))
        .toList();
  }

  /// 根据宫位名称和地支列表批量计算六亲
  ///
  /// [baGongName] 八宫名称
  /// [branches] 地支列表
  /// 返回对应的六亲列表，无效的地支会被跳过
  static List<LiuQin> calculateLiuQinListByBranches(
    String baGongName,
    List<String> branches,
  ) {
    final gongWuXing = _getGongWuXing(baGongName);
    if (gongWuXing == null) return [];

    return branches
        .map((branch) => WuXingService.getWuXingFromBranch(branch))
        .whereType<WuXing>()
        .map((yaoWuXing) => calculateLiuQin(gongWuXing, yaoWuXing))
        .toList();
  }
}
