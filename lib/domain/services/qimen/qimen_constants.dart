import '../../../divination_systems/qimen/models/qimen_enums.dart';

class QimenPalaceMeta {
  const QimenPalaceMeta({
    required this.name,
    required this.trigram,
    required this.direction,
    required this.element,
    required this.branches,
  });

  final String name;
  final String trigram;
  final String direction;
  final String element;
  final List<String> branches;
}

class QimenConstants {
  QimenConstants._();

  static const List<String> solarTerms = <String>[
    '冬至',
    '小寒',
    '大寒',
    '立春',
    '雨水',
    '惊蛰',
    '春分',
    '清明',
    '谷雨',
    '立夏',
    '小满',
    '芒种',
    '夏至',
    '小暑',
    '大暑',
    '立秋',
    '处暑',
    '白露',
    '秋分',
    '寒露',
    '霜降',
    '立冬',
    '小雪',
    '大雪',
  ];

  /// 时家奇门二十四节气上、中、下元局数的唯一数据源。
  static const Map<String, List<int>> juBySolarTerm = <String, List<int>>{
    '冬至': <int>[1, 7, 4],
    '小寒': <int>[2, 8, 5],
    '大寒': <int>[3, 9, 6],
    '立春': <int>[8, 5, 2],
    '雨水': <int>[9, 6, 3],
    '惊蛰': <int>[1, 7, 4],
    '春分': <int>[3, 9, 6],
    '清明': <int>[4, 1, 7],
    '谷雨': <int>[5, 2, 8],
    '立夏': <int>[4, 1, 7],
    '小满': <int>[5, 2, 8],
    '芒种': <int>[6, 3, 9],
    '夏至': <int>[9, 3, 6],
    '小暑': <int>[8, 2, 5],
    '大暑': <int>[7, 1, 4],
    '立秋': <int>[2, 5, 8],
    '处暑': <int>[1, 4, 7],
    '白露': <int>[9, 3, 6],
    '秋分': <int>[7, 1, 4],
    '寒露': <int>[6, 9, 3],
    '霜降': <int>[5, 8, 2],
    '立冬': <int>[6, 9, 3],
    '小雪': <int>[5, 8, 2],
    '大雪': <int>[4, 7, 1],
  };

  static const List<String> qiYi = <String>[
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
    '丁',
    '丙',
    '乙',
  ];

  static const Map<String, String> xunHiddenStem = <String, String>{
    '甲子': '戊',
    '甲戌': '己',
    '甲申': '庚',
    '甲午': '辛',
    '甲辰': '壬',
    '甲寅': '癸',
  };

  static const Map<int, String> starsByOrigin = <int, String>{
    1: '天蓬',
    2: '天芮',
    3: '天冲',
    4: '天辅',
    5: '天禽',
    6: '天心',
    7: '天柱',
    8: '天任',
    9: '天英',
  };

  static const Map<int, String> doorsByOrigin = <int, String>{
    1: '休门',
    2: '死门',
    3: '伤门',
    4: '杜门',
    6: '开门',
    7: '惊门',
    8: '生门',
    9: '景门',
  };

  static const List<int> outerPalaces = <int>[1, 8, 3, 4, 9, 2, 7, 6];

  static const List<String> deities = <String>[
    '值符',
    '螣蛇',
    '太阴',
    '六合',
    '白虎',
    '玄武',
    '九地',
    '九天',
  ];

  static const Map<int, QimenPalaceMeta> palaceMeta = <int, QimenPalaceMeta>{
    1: QimenPalaceMeta(
      name: '坎一宫',
      trigram: '坎',
      direction: '北',
      element: '水',
      branches: <String>['子'],
    ),
    2: QimenPalaceMeta(
      name: '坤二宫',
      trigram: '坤',
      direction: '西南',
      element: '土',
      branches: <String>['未', '申'],
    ),
    3: QimenPalaceMeta(
      name: '震三宫',
      trigram: '震',
      direction: '东',
      element: '木',
      branches: <String>['卯'],
    ),
    4: QimenPalaceMeta(
      name: '巽四宫',
      trigram: '巽',
      direction: '东南',
      element: '木',
      branches: <String>['辰', '巳'],
    ),
    5: QimenPalaceMeta(
      name: '中五宫',
      trigram: '中',
      direction: '中',
      element: '土',
      branches: <String>[],
    ),
    6: QimenPalaceMeta(
      name: '乾六宫',
      trigram: '乾',
      direction: '西北',
      element: '金',
      branches: <String>['戌', '亥'],
    ),
    7: QimenPalaceMeta(
      name: '兑七宫',
      trigram: '兑',
      direction: '西',
      element: '金',
      branches: <String>['酉'],
    ),
    8: QimenPalaceMeta(
      name: '艮八宫',
      trigram: '艮',
      direction: '东北',
      element: '土',
      branches: <String>['丑', '寅'],
    ),
    9: QimenPalaceMeta(
      name: '离九宫',
      trigram: '离',
      direction: '南',
      element: '火',
      branches: <String>['午'],
    ),
  };

  static QimenDun dunForSolarTerm(String solarTerm) {
    final index = solarTerms.indexOf(solarTerm);
    if (index < 0) throw ArgumentError('未知节气: $solarTerm');
    return index < 12 ? QimenDun.yang : QimenDun.yin;
  }

  static int juFor(String solarTerm, QimenYuan yuan) {
    final values = juBySolarTerm[solarTerm];
    if (values == null) throw ArgumentError('未知节气: $solarTerm');
    return values[QimenYuan.values.indexOf(yuan)];
  }

  static int moveFlying(int palace, int steps, QimenDun dun) {
    final direction = dun == QimenDun.yang ? 1 : -1;
    return ((palace - 1 + direction * steps) % 9 + 9) % 9 + 1;
  }

  static int hostingPalace(QimenHostingMode mode, QimenDun dun) =>
      mode == QimenHostingMode.yangEightYinTwo && dun == QimenDun.yang ? 8 : 2;
}
