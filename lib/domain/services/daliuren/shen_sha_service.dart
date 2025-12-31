import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/shen_sha.dart';

/// 神煞计算服务
///
/// 大六壬神煞体系完整，包含吉神、凶神、中性神煞等30+种。
/// 神煞的计算主要基于日干、日支、月建、时支等因素。
class ShenShaService {
  ShenShaService._();

  /// 计算所有神煞
  ///
  /// [riGan] 日干
  /// [riZhi] 日支
  /// [yueJian] 月建（月支）
  /// [shiZhi] 时支
  /// 返回 ShenShaList 模型
  static ShenShaList calculateShenSha({
    required String riGan,
    required String riZhi,
    required String yueJian,
    required String shiZhi,
  }) {
    final allShenSha = <ShenSha>[];

    // 计算各类神煞
    allShenSha.addAll(_calculateJiShen(riGan, riZhi, yueJian));
    allShenSha.addAll(_calculateXiongShen(riGan, riZhi, yueJian));
    allShenSha.addAll(_calculateZhongShen(riGan, riZhi, yueJian));

    return ShenShaList(allShenSha: allShenSha);
  }

  /// 计算吉神
  static List<ShenSha> _calculateJiShen(
    String riGan,
    String riZhi,
    String yueJian,
  ) {
    final result = <ShenSha>[];

    // 天德
    final tianDe = _getTianDe(yueJian);
    if (tianDe != null) {
      result.add(ShenSha(
        name: '天德',
        type: ShenShaType.ji,
        diZhi: tianDe,
        description: '天德贵人，主贵人相助，逢凶化吉',
        influence: '有天德临则吉，主得贵人扶助',
      ));
    }

    // 月德
    final yueDe = _getYueDe(yueJian);
    if (yueDe != null) {
      result.add(ShenSha(
        name: '月德',
        type: ShenShaType.ji,
        diZhi: yueDe,
        description: '月德贵人，主吉祥如意',
        influence: '月德临处主吉，有解厄之功',
      ));
    }

    // 天喜
    final tianXi = _getTianXi(yueJian);
    result.add(ShenSha(
      name: '天喜',
      type: ShenShaType.ji,
      diZhi: tianXi,
      description: '天喜星，主喜庆、婚姻',
      influence: '天喜临处主喜事',
    ));

    // 驿马
    final yiMa = _getYiMa(riZhi);
    result.add(ShenSha(
      name: '驿马',
      type: ShenShaType.ji,
      diZhi: yiMa,
      description: '驿马星，主动、出行、变迁',
      influence: '驿马临处主动象，利出行、调动',
    ));

    // 天医
    final tianYi = _getTianYi(yueJian);
    result.add(ShenSha(
      name: '天医',
      type: ShenShaType.ji,
      diZhi: tianYi,
      description: '天医星，主医药、健康',
      influence: '天医临处利求医问药',
    ));

    return result;
  }

  /// 计算凶神
  static List<ShenSha> _calculateXiongShen(
    String riGan,
    String riZhi,
    String yueJian,
  ) {
    final result = <ShenSha>[];

    // 白虎
    final baiHu = _getBaiHu(yueJian);
    result.add(ShenSha(
      name: '白虎',
      type: ShenShaType.xiong,
      diZhi: baiHu,
      description: '白虎煞，主凶丧、血光、疾病',
      influence: '白虎临处主凶，忌动土、见血',
    ));

    // 丧门
    final sangMen = _getSangMen(riZhi);
    result.add(ShenSha(
      name: '丧门',
      type: ShenShaType.xiong,
      diZhi: sangMen,
      description: '丧门星，主丧事、哭泣',
      influence: '丧门临处主丧事、忧愁',
    ));

    // 吊客
    final diaoKe = _getDiaoKe(riZhi);
    result.add(ShenSha(
      name: '吊客',
      type: ShenShaType.xiong,
      diZhi: diaoKe,
      description: '吊客星，主丧吊之事',
      influence: '吊客临处主悲伤、丧事',
    ));

    // 劫煞
    final jieSha = _getJieSha(riZhi);
    result.add(ShenSha(
      name: '劫煞',
      type: ShenShaType.xiong,
      diZhi: jieSha,
      description: '劫煞，主劫难、损失',
      influence: '劫煞临处主破财、灾难',
    ));

    // 灾煞
    final zaiSha = _getZaiSha(riZhi);
    result.add(ShenSha(
      name: '灾煞',
      type: ShenShaType.xiong,
      diZhi: zaiSha,
      description: '灾煞，主灾祸、疾病',
      influence: '灾煞临处主灾病',
    ));

    // 天狗
    final tianGou = _getTianGou(yueJian);
    result.add(ShenSha(
      name: '天狗',
      type: ShenShaType.xiong,
      diZhi: tianGou,
      description: '天狗煞，主是非、口舌',
      influence: '天狗临处主口舌是非',
    ));

    return result;
  }

  /// 计算中性神煞
  static List<ShenSha> _calculateZhongShen(
    String riGan,
    String riZhi,
    String yueJian,
  ) {
    final result = <ShenSha>[];

    // 华盖
    final huaGai = _getHuaGai(riZhi);
    result.add(ShenSha(
      name: '华盖',
      type: ShenShaType.zhong,
      diZhi: huaGai,
      description: '华盖星，主孤独、艺术、宗教',
      influence: '华盖临处主孤高，利艺术、修行',
    ));

    // 将星
    final jiangXing = _getJiangXing(riZhi);
    result.add(ShenSha(
      name: '将星',
      type: ShenShaType.zhong,
      diZhi: jiangXing,
      description: '将星，主权力、领导',
      influence: '将星临处主权力、领导之才',
    ));

    // 天罗
    final tianLuo = _getTianLuo();
    result.add(ShenSha(
      name: '天罗',
      type: ShenShaType.zhong,
      diZhi: tianLuo,
      description: '天罗，主阻滞、束缚',
      influence: '天罗临处主阻滞',
    ));

    // 地网
    final diWang = _getDiWang();
    result.add(ShenSha(
      name: '地网',
      type: ShenShaType.zhong,
      diZhi: diWang,
      description: '地网，主困顿、牢狱',
      influence: '地网临处主困顿',
    ));

    return result;
  }

  // ==================== 吉神计算方法 ====================

  /// 天德：正月在丁，二月在申，三月在壬...
  static String? _getTianDe(String yueJian) {
    const tianDeMap = {
      '寅': '丁',
      '卯': '申',
      '辰': '壬',
      '巳': '辛',
      '午': '亥',
      '未': '甲',
      '申': '癸',
      '酉': '寅',
      '戌': '丙',
      '亥': '乙',
      '子': '巳',
      '丑': '庚',
    };
    return tianDeMap[yueJian];
  }

  /// 月德：寅午戌月在丙，申子辰月在壬，亥卯未月在甲，巳酉丑月在庚
  static String? _getYueDe(String yueJian) {
    if (['寅', '午', '戌'].contains(yueJian)) return '丙';
    if (['申', '子', '辰'].contains(yueJian)) return '壬';
    if (['亥', '卯', '未'].contains(yueJian)) return '甲';
    if (['巳', '酉', '丑'].contains(yueJian)) return '庚';
    return null;
  }

  /// 天喜：正月在戌，二月在亥...
  static String _getTianXi(String yueJian) {
    const tianXiMap = {
      '寅': '戌',
      '卯': '亥',
      '辰': '子',
      '巳': '丑',
      '午': '寅',
      '未': '卯',
      '申': '辰',
      '酉': '巳',
      '戌': '午',
      '亥': '未',
      '子': '申',
      '丑': '酉',
    };
    return tianXiMap[yueJian] ?? '子';
  }

  /// 驿马：申子辰马在寅，寅午戌马在申，亥卯未马在巳，巳酉丑马在亥
  static String _getYiMa(String riZhi) {
    if (['申', '子', '辰'].contains(riZhi)) return '寅';
    if (['寅', '午', '戌'].contains(riZhi)) return '申';
    if (['亥', '卯', '未'].contains(riZhi)) return '巳';
    if (['巳', '酉', '丑'].contains(riZhi)) return '亥';
    return '寅';
  }

  /// 天医：正月在丑，二月在寅...
  static String _getTianYi(String yueJian) {
    final index = DaLiuRenConstants.getDiZhiIndex(yueJian);
    // 天医在月建前一位
    return DaLiuRenConstants.getDiZhiByIndex((index + 11) % 12);
  }

  // ==================== 凶神计算方法 ====================

  /// 白虎：正月在申，二月在酉...
  static String _getBaiHu(String yueJian) {
    final index = DaLiuRenConstants.getDiZhiIndex(yueJian);
    // 白虎在月建后六位（对冲）
    return DaLiuRenConstants.getDiZhiByIndex((index + 6) % 12);
  }

  /// 丧门：申子辰在寅，寅午戌在申，亥卯未在巳，巳酉丑在亥（同驿马位）
  static String _getSangMen(String riZhi) {
    return _getYiMa(riZhi);
  }

  /// 吊客：丧门对冲
  static String _getDiaoKe(String riZhi) {
    final sangMen = _getSangMen(riZhi);
    return DaLiuRenConstants.getChongZhi(sangMen);
  }

  /// 劫煞：申子辰在巳，寅午戌在亥，亥卯未在申，巳酉丑在寅
  static String _getJieSha(String riZhi) {
    if (['申', '子', '辰'].contains(riZhi)) return '巳';
    if (['寅', '午', '戌'].contains(riZhi)) return '亥';
    if (['亥', '卯', '未'].contains(riZhi)) return '申';
    if (['巳', '酉', '丑'].contains(riZhi)) return '寅';
    return '巳';
  }

  /// 灾煞：劫煞后一位
  static String _getZaiSha(String riZhi) {
    final jieSha = _getJieSha(riZhi);
    final index = DaLiuRenConstants.getDiZhiIndex(jieSha);
    return DaLiuRenConstants.getDiZhiByIndex((index + 1) % 12);
  }

  /// 天狗：正月在戌，二月在亥...
  static String _getTianGou(String yueJian) {
    final index = DaLiuRenConstants.getDiZhiIndex(yueJian);
    return DaLiuRenConstants.getDiZhiByIndex((index + 8) % 12);
  }

  // ==================== 中性神煞计算方法 ====================

  /// 华盖：申子辰在辰，寅午戌在戌，亥卯未在未，巳酉丑在丑
  static String _getHuaGai(String riZhi) {
    if (['申', '子', '辰'].contains(riZhi)) return '辰';
    if (['寅', '午', '戌'].contains(riZhi)) return '戌';
    if (['亥', '卯', '未'].contains(riZhi)) return '未';
    if (['巳', '酉', '丑'].contains(riZhi)) return '丑';
    return '辰';
  }

  /// 将星：申子辰在子，寅午戌在午，亥卯未在卯，巳酉丑在酉
  static String _getJiangXing(String riZhi) {
    if (['申', '子', '辰'].contains(riZhi)) return '子';
    if (['寅', '午', '戌'].contains(riZhi)) return '午';
    if (['亥', '卯', '未'].contains(riZhi)) return '卯';
    if (['巳', '酉', '丑'].contains(riZhi)) return '酉';
    return '子';
  }

  /// 天罗：固定在戌
  static String _getTianLuo() => '戌';

  /// 地网：固定在辰
  static String _getDiWang() => '辰';
}
