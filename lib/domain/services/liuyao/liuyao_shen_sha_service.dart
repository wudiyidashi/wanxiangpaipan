import '../shared/tiangan_dizhi_service.dart';

/// 六爻排盘顶部常用的日神煞。
class LiuYaoDailyShenSha {
  const LiuYaoDailyShenSha({
    required this.yiMa,
    required this.taoHua,
    required this.riLu,
    required this.guiRen,
  });

  final String yiMa;
  final String taoHua;
  final String riLu;
  final List<String> guiRen;
}

/// 按日干、日支计算六爻排盘常用神煞。
class LiuYaoShenShaService {
  LiuYaoShenShaService._();

  static const Map<String, String> _yiMaByRiZhi = {
    '申': '寅',
    '子': '寅',
    '辰': '寅',
    '寅': '申',
    '午': '申',
    '戌': '申',
    '亥': '巳',
    '卯': '巳',
    '未': '巳',
    '巳': '亥',
    '酉': '亥',
    '丑': '亥',
  };

  static const Map<String, String> _taoHuaByRiZhi = {
    '申': '酉',
    '子': '酉',
    '辰': '酉',
    '寅': '卯',
    '午': '卯',
    '戌': '卯',
    '亥': '子',
    '卯': '子',
    '未': '子',
    '巳': '午',
    '酉': '午',
    '丑': '午',
  };

  static const Map<String, String> _riLuByRiGan = {
    '甲': '寅',
    '乙': '卯',
    '丙': '巳',
    '丁': '午',
    '戊': '巳',
    '己': '午',
    '庚': '申',
    '辛': '酉',
    '壬': '亥',
    '癸': '子',
  };

  static const Map<String, List<String>> _guiRenByRiGan = {
    '甲': ['丑', '未'],
    '戊': ['丑', '未'],
    '庚': ['丑', '未'],
    '乙': ['子', '申'],
    '己': ['子', '申'],
    '丙': ['亥', '酉'],
    '丁': ['亥', '酉'],
    '壬': ['卯', '巳'],
    '癸': ['卯', '巳'],
    '辛': ['午', '寅'],
  };

  static LiuYaoDailyShenSha calculate({
    required String riGan,
    required String riZhi,
  }) {
    if (!TianGanDiZhiService.isValidTianGan(riGan)) {
      throw ArgumentError.value(riGan, 'riGan', '必须是有效天干');
    }
    if (!TianGanDiZhiService.isValidDiZhi(riZhi)) {
      throw ArgumentError.value(riZhi, 'riZhi', '必须是有效地支');
    }

    return LiuYaoDailyShenSha(
      yiMa: _yiMaByRiZhi[riZhi]!,
      taoHua: _taoHuaByRiZhi[riZhi]!,
      riLu: _riLuByRiGan[riGan]!,
      guiRen: _guiRenByRiGan[riGan]!,
    );
  }
}
