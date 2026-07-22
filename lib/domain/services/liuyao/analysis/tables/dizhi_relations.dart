import '../../../shared/wuxing_service.dart';

/// 地支关系静态表：六合、六冲、三合局、半合、三刑、相害。
///
/// 规则依据《增删卜易》；三刑、相害按《卜筮正宗》补充。
/// 所有方法均为纯静态函数，无副作用。
class DiZhiRelations {
  DiZhiRelations._();

  /// 六合对（双向收录）
  static const Map<String, String> liuHe = {
    '子': '丑', '丑': '子',
    '寅': '亥', '亥': '寅',
    '卯': '戌', '戌': '卯',
    '辰': '酉', '酉': '辰',
    '巳': '申', '申': '巳',
    '午': '未', '未': '午',
  };

  /// 六冲对（双向收录）
  static const Map<String, String> liuChong = {
    '子': '午', '午': '子',
    '丑': '未', '未': '丑',
    '寅': '申', '申': '寅',
    '卯': '酉', '酉': '卯',
    '辰': '戌', '戌': '辰',
    '巳': '亥', '亥': '巳',
  };

  /// 三合局：[长生, 帝旺, 墓] → 局五行。土无三合局。
  static const Map<WuXing, List<String>> sanHeJu = {
    WuXing.shui: ['申', '子', '辰'],
    WuXing.mu: ['亥', '卯', '未'],
    WuXing.huo: ['寅', '午', '戌'],
    WuXing.jin: ['巳', '酉', '丑'],
  };

  /// 三刑组（无恩之刑寅巳申、恃势之刑丑戌未、无礼之刑子卯）
  static const List<List<String>> sanXingGroups = [
    ['寅', '巳', '申'],
    ['丑', '戌', '未'],
    ['子', '卯'],
  ];

  /// 自刑四支
  static const Set<String> ziXing = {'辰', '午', '酉', '亥'};

  /// 相害对（双向收录）
  static const Map<String, String> xiangHai = {
    '子': '未', '未': '子',
    '丑': '午', '午': '丑',
    '寅': '巳', '巳': '寅',
    '卯': '辰', '辰': '卯',
    '申': '亥', '亥': '申',
    '酉': '戌', '戌': '酉',
  };

  /// 六合化气：子丑化土、寅亥化木、卯戌化火、辰酉化金、巳申化水、午未化土
  static const Map<String, WuXing> _liuHeHua = {
    '子丑': WuXing.tu,
    '寅亥': WuXing.mu,
    '卯戌': WuXing.huo,
    '辰酉': WuXing.jin,
    '巳申': WuXing.shui,
    '午未': WuXing.tu,
  };

  static bool isLiuHe(String a, String b) => liuHe[a] == b;

  /// 两支六合所化五行；非六合对返回 null
  static WuXing? getLiuHeHua(String a, String b) {
    if (!isLiuHe(a, b)) return null;
    return _liuHeHua['$a$b'] ?? _liuHeHua['$b$a'];
  }

  /// 返回与 [zhi] 相合的地支，无效输入返回 null
  static String? getLiuHe(String zhi) => liuHe[zhi];

  static bool isLiuChong(String a, String b) => liuChong[a] == b;

  /// 返回与 [zhi] 相冲的地支，无效输入返回 null
  static String? getLiuChong(String zhi) => liuChong[zhi];

  /// 三支是否构成三合局；成局返回局五行，否则 null。与输入顺序无关。
  static WuXing? getSanHeElement(String a, String b, String c) {
    final input = {a, b, c};
    if (input.length != 3) return null;
    for (final entry in sanHeJu.entries) {
      if (input.containsAll(entry.value)) return entry.key;
    }
    return null;
  }

  /// 三合局的 [长生, 帝旺, 墓] 三支；土返回 null
  static List<String>? getSanHeGroup(WuXing wuXing) => sanHeJu[wuXing];

  /// 半合：三合局中含帝旺支的两支组合（申子/子辰等）。
  /// 缺帝旺支的两端（拱局）不算半合。成立返回局五行，否则 null。
  static WuXing? getBanHeElement(String a, String b) {
    if (a == b) return null;
    for (final entry in sanHeJu.entries) {
      final group = entry.value;
      final wang = group[1];
      if ((a == wang || b == wang) &&
          group.contains(a) &&
          group.contains(b)) {
        return entry.key;
      }
    }
    return null;
  }

  static bool isBanHe(String a, String b) => getBanHeElement(a, b) != null;

  /// 两支是否构成相刑（三刑组内任意两支，或自刑支同支）
  static bool isXing(String a, String b) {
    if (a == b) return ziXing.contains(a);
    for (final group in sanXingGroups) {
      if (group.contains(a) && group.contains(b)) return true;
    }
    return false;
  }

  /// 是否为自刑支（辰午酉亥）
  static bool isZiXing(String zhi) => ziXing.contains(zhi);

  static bool isHai(String a, String b) => xiangHai[a] == b;
}
