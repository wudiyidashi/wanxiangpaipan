import 'dart:math';

/// 硬币面
enum CoinFace {
  front('正面'),
  back('反面');

  const CoinFace(this.name);
  final String name;
}

/// 起卦服务
class QiGuaService {
  QiGuaService._();

  static final _random = Random();

  /// 摇钱法：模拟三枚硬币投掷，返回一个爻数
  static int coinCastOnce() {
    final coin1 = _random.nextBool();
    final coin2 = _random.nextBool();
    final coin3 = _random.nextBool();
    final frontCount = [coin1, coin2, coin3].where((c) => c).length;

    switch (frontCount) {
      case 3: return 9;  // 老阳
      case 2: return 7;  // 少阳
      case 1: return 8;  // 少阴
      case 0: return 6;  // 老阴
      default: return 7;
    }
  }

  /// 完整摇钱法：返回6个爻数（从下到上）
  static List<int> coinCast() {
    return List.generate(6, (_) => coinCastOnce());
  }

  /// 时间起卦法：根据时间计算卦象
  static List<int> timeCast(DateTime time) {
    final year = time.year % 12 + 1;
    final month = time.month;
    final day = time.day;
    final hour = _getShiChen(time.hour);
    final sum = year + month + day + hour;

    final upperGua = ((sum - 1) % 8) + 1;
    final lowerGua = ((sum + hour - 1) % 8) + 1;
    final movingYao = ((sum - 1) % 6) + 1;

    return _generateYaoNumbersFromGua(upperGua, lowerGua, movingYao);
  }

  /// 手动输入法：根据用户输入的硬币正反面生成爻数
  static int manualCastOnce(List<CoinFace> faces) {
    if (faces.length != 3) {
      throw ArgumentError.value(faces.length, 'faces', '必须输入3枚硬币');
    }
    final frontCount = faces.where((f) => f == CoinFace.front).length;

    switch (frontCount) {
      case 3: return 9;
      case 2: return 7;
      case 1: return 8;
      case 0: return 6;
      default: return 7;
    }
  }

  /// 完整手动输入：用户输入6次，每次3枚硬币
  static List<int> manualCast(List<List<CoinFace>> allFaces) {
    if (allFaces.length != 6) {
      throw ArgumentError.value(allFaces.length, 'allFaces', '必须输入6次');
    }
    return allFaces.map((faces) => manualCastOnce(faces)).toList();
  }

  /// 获取时辰数（1-12）
  static int _getShiChen(int hour) {
    if (hour == 23 || hour == 0) return 1;
    return ((hour + 1) ~/ 2) + 1;
  }

  /// 根据上下卦和动爻生成爻数
  static List<int> _generateYaoNumbersFromGua(int upper, int lower, int moving) {
    final upperYaos = _guaNumberToYaos(upper);
    final lowerYaos = _guaNumberToYaos(lower);
    final allYaos = [...lowerYaos, ...upperYaos];

    final movingPos = moving - 1;
    allYaos[movingPos] = allYaos[movingPos] == 7 ? 9 : 6;

    return allYaos;
  }

  /// 八卦数转三个爻
  static List<int> _guaNumberToYaos(int guaNum) {
    const Map<int, List<int>> guaToYaos = {
      1: [7, 7, 7],  // 乾
      2: [8, 7, 7],  // 兑
      3: [7, 8, 7],  // 离
      4: [8, 8, 7],  // 震
      5: [7, 7, 8],  // 巽
      6: [8, 7, 8],  // 坎
      7: [7, 8, 8],  // 艮
      8: [8, 8, 8],  // 坤
    };
    return guaToYaos[guaNum] ?? [7, 7, 7];
  }
}
