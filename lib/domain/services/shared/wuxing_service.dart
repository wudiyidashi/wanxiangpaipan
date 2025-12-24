/// 五行枚举
///
/// 五行是中国传统哲学中的基本元素，用于描述事物的属性和相互关系。
enum WuXing {
  jin('金'),
  mu('木'),
  shui('水'),
  huo('火'),
  tu('土');

  const WuXing(this.name);
  final String name;
}

/// 五行关系类型
enum WuXingRelation {
  biHe('比和'),      // 同类
  woSheng('我生'),   // 我生者
  shengWo('生我'),   // 生我者
  woKe('我克'),      // 我克者
  keWo('克我');      // 克我者

  const WuXingRelation(this.name);
  final String name;
}

/// 五行服务
///
/// 提供五行生克关系计算功能，可被所有术数系统复用。
/// 所有方法均为纯静态函数，无副作用。
class WuXingService {
  WuXingService._();

  /// 地支对应的五行
  static const Map<String, WuXing> branchToWuXing = {
    '子': WuXing.shui,
    '亥': WuXing.shui,
    '寅': WuXing.mu,
    '卯': WuXing.mu,
    '巳': WuXing.huo,
    '午': WuXing.huo,
    '申': WuXing.jin,
    '酉': WuXing.jin,
    '辰': WuXing.tu,
    '戌': WuXing.tu,
    '丑': WuXing.tu,
    '未': WuXing.tu,
  };

  /// 天干对应的五行
  static const Map<String, WuXing> stemToWuXing = {
    '甲': WuXing.mu,
    '乙': WuXing.mu,
    '丙': WuXing.huo,
    '丁': WuXing.huo,
    '戊': WuXing.tu,
    '己': WuXing.tu,
    '庚': WuXing.jin,
    '辛': WuXing.jin,
    '壬': WuXing.shui,
    '癸': WuXing.shui,
  };

  /// 五行生关系（我生者）
  static const Map<WuXing, WuXing> shengRelation = {
    WuXing.jin: WuXing.shui,   // 金生水
    WuXing.shui: WuXing.mu,    // 水生木
    WuXing.mu: WuXing.huo,     // 木生火
    WuXing.huo: WuXing.tu,     // 火生土
    WuXing.tu: WuXing.jin,     // 土生金
  };

  /// 五行克关系（我克者）
  static const Map<WuXing, WuXing> keRelation = {
    WuXing.jin: WuXing.mu,     // 金克木
    WuXing.mu: WuXing.tu,      // 木克土
    WuXing.tu: WuXing.shui,    // 土克水
    WuXing.shui: WuXing.huo,   // 水克火
    WuXing.huo: WuXing.jin,    // 火克金
  };

  /// 根据地支获取五行
  ///
  /// [branch] 地支，如 "子"、"丑" 等
  /// 返回对应的五行，如果地支无效返回 null
  static WuXing? getWuXingFromBranch(String branch) {
    return branchToWuXing[branch];
  }

  /// 根据天干获取五行
  ///
  /// [stem] 天干，如 "甲"、"乙" 等
  /// 返回对应的五行，如果天干无效返回 null
  static WuXing? getWuXingFromStem(String stem) {
    return stemToWuXing[stem];
  }

  /// 计算两个五行之间的关系
  ///
  /// [from] 起始五行（主体）
  /// [to] 目标五行（客体）
  /// 返回从 from 到 to 的五行关系
  static WuXingRelation getRelation(WuXing from, WuXing to) {
    // 比和：同类
    if (from == to) {
      return WuXingRelation.biHe;
    }

    // 我生：from 生 to
    if (shengRelation[from] == to) {
      return WuXingRelation.woSheng;
    }

    // 生我：to 生 from
    if (shengRelation[to] == from) {
      return WuXingRelation.shengWo;
    }

    // 我克：from 克 to
    if (keRelation[from] == to) {
      return WuXingRelation.woKe;
    }

    // 克我：to 克 from
    if (keRelation[to] == from) {
      return WuXingRelation.keWo;
    }

    // 理论上不应该到达这里
    return WuXingRelation.biHe;
  }

  /// 判断 from 是否生 to
  static bool isSheng(WuXing from, WuXing to) {
    return shengRelation[from] == to;
  }

  /// 判断 from 是否克 to
  static bool isKe(WuXing from, WuXing to) {
    return keRelation[from] == to;
  }

  /// 获取五行所生的五行
  ///
  /// [wuXing] 五行
  /// 返回该五行所生的五行
  static WuXing getShengTarget(WuXing wuXing) {
    return shengRelation[wuXing]!;
  }

  /// 获取五行所克的五行
  ///
  /// [wuXing] 五行
  /// 返回该五行所克的五行
  static WuXing getKeTarget(WuXing wuXing) {
    return keRelation[wuXing]!;
  }

  /// 获取生该五行的五行
  ///
  /// [wuXing] 五行
  /// 返回生该五行的五行
  static WuXing getShengSource(WuXing wuXing) {
    return shengRelation.entries
        .firstWhere((entry) => entry.value == wuXing)
        .key;
  }

  /// 获取克该五行的五行
  ///
  /// [wuXing] 五行
  /// 返回克该五行的五行
  static WuXing getKeSource(WuXing wuXing) {
    return keRelation.entries
        .firstWhere((entry) => entry.value == wuXing)
        .key;
  }

  /// 将五行转换为字符串（用于存储和比较）
  ///
  /// [wuXing] 五行枚举
  /// 返回五行的字符串表示，如 "jin"、"mu" 等
  static String wuXingToString(WuXing wuXing) {
    const map = {
      WuXing.jin: 'jin',
      WuXing.mu: 'mu',
      WuXing.shui: 'shui',
      WuXing.huo: 'huo',
      WuXing.tu: 'tu',
    };
    return map[wuXing]!;
  }

  /// 将字符串转换为五行枚举
  ///
  /// [value] 五行字符串，如 "jin"、"mu" 等
  /// 返回对应的五行枚举，如果字符串无效返回 null
  static WuXing? stringToWuXing(String value) {
    const map = {
      'jin': WuXing.jin,
      'mu': WuXing.mu,
      'shui': WuXing.shui,
      'huo': WuXing.huo,
      'tu': WuXing.tu,
    };
    return map[value];
  }

  /// 判断五行是否相同
  static bool isSame(WuXing a, WuXing b) {
    return a == b;
  }

  /// 获取五行的中文名称
  static String getWuXingName(WuXing wuXing) {
    return wuXing.name;
  }

  /// 根据地支列表获取五行列表
  ///
  /// [branches] 地支列表
  /// 返回对应的五行列表，无效的地支会被跳过
  static List<WuXing> getWuXingListFromBranches(List<String> branches) {
    return branches
        .map((branch) => getWuXingFromBranch(branch))
        .whereType<WuXing>()
        .toList();
  }

  /// 根据天干列表获取五行列表
  ///
  /// [stems] 天干列表
  /// 返回对应的五行列表，无效的天干会被跳过
  static List<WuXing> getWuXingListFromStems(List<String> stems) {
    return stems
        .map((stem) => getWuXingFromStem(stem))
        .whereType<WuXing>()
        .toList();
  }
}
