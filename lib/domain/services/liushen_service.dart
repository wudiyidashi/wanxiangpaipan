/// 六神计算服务
class LiuShenService {
  LiuShenService._();

  /// 六神顺序
  static const List<String> _liushenOrder = [
    '青龙',
    '朱雀',
    '勾陈',
    '腾蛇',
    '白虎',
    '玄武'
  ];

  /// 天干对应六神起始索引
  static const Map<String, int> _ganToLiuShenStart = {
    '甲': 0, '乙': 0, // 青龙
    '丙': 1, '丁': 1, // 朱雀
    '戊': 3, '己': 3, // 腾蛇
    '庚': 4, '辛': 4, // 白虎
    '壬': 5, '癸': 5, // 玄武
  };

  /// 根据日干计算六神顺序（从初爻到六爻）
  static List<String> calculateLiuShen(String dayGan) {
    final startIndex = _ganToLiuShenStart[dayGan] ?? 0;
    return List.generate(6, (i) => _liushenOrder[(startIndex + i) % 6]);
  }
}
