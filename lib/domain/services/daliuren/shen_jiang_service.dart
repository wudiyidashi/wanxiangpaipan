import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/shen_jiang_config.dart';

/// 神将配置服务
///
/// 大六壬十二神将的配置规则：
/// 1. 先确定贵人位置（根据日干查表）
/// 2. 判断昼夜用阳贵还是阴贵
/// 3. 根据日干阴阳决定布神方向（阳日顺布，阴日逆布）
/// 4. 从贵人位置开始，按顺序排列十二神将
class ShenJiangService {
  ShenJiangService._();

  /// 配置十二神将
  ///
  /// [riGan] 日干
  /// [shiZhi] 时支（用于判断昼夜）
  /// [tianPanMap] 天盘映射表
  /// 返回 ShenJiangConfig 模型
  static ShenJiangConfig configureShenJiang({
    required String riGan,
    required String shiZhi,
    required Map<String, String> tianPanMap,
  }) {
    // 判断日干阴阳
    final isYangRi = DaLiuRenConstants.isYangGan(riGan);

    // 判断昼夜（卯-申为昼，酉-寅为夜）
    final isDay = _isDay(shiZhi);

    // 获取贵人位置（阳贵或阴贵）
    final guiRenPositions = DaLiuRenConstants.getGuiRenPosition(riGan);
    final isYangGui = isDay; // 昼用阳贵，夜用阴贵
    final guiRenPosition = isYangGui ? guiRenPositions[0] : guiRenPositions[1];

    // 获取神将顺序（阳日顺布，阴日逆布）
    final shenJiangOrder = isYangRi
        ? DaLiuRenConstants.shenJiangOrderYang
        : DaLiuRenConstants.shenJiangOrderYin;

    // 获取贵人所在地盘位置的索引
    final guiRenDiZhiIndex = DaLiuRenConstants.getDiZhiIndex(guiRenPosition);

    // 配置十二神将位置
    final positions = <ShenJiangPosition>[];
    final diZhiToShenJiang = <String, ShenJiang>{};

    for (var i = 0; i < 12; i++) {
      // 计算当前神将所在地盘位置
      int diZhiIndex;
      if (isYangRi) {
        // 阳日顺布
        diZhiIndex = (guiRenDiZhiIndex + i) % 12;
      } else {
        // 阴日逆布
        diZhiIndex = (guiRenDiZhiIndex - i + 12) % 12;
      }

      final diZhi = DaLiuRenConstants.getDiZhiByIndex(diZhiIndex);
      final tianPanZhi = tianPanMap[diZhi] ?? diZhi;
      final shenJiang = shenJiangOrder[i];

      positions.add(ShenJiangPosition(
        shenJiang: shenJiang,
        diZhi: diZhi,
        tianPanZhi: tianPanZhi,
      ));

      diZhiToShenJiang[diZhi] = shenJiang;
    }

    return ShenJiangConfig(
      guiRenPosition: guiRenPosition,
      isYangGui: isYangGui,
      isYangRi: isYangRi,
      positions: positions,
      diZhiToShenJiang: diZhiToShenJiang,
    );
  }

  /// 判断是否为昼（白天）
  ///
  /// 昼：卯时至申时（05:00-19:00）
  /// 夜：酉时至寅时（19:00-05:00）
  ///
  /// [shiZhi] 时支
  /// 返回 true 为昼，false 为夜
  static bool _isDay(String shiZhi) {
    const dayBranches = ['卯', '辰', '巳', '午', '未', '申'];
    return dayBranches.contains(shiZhi);
  }

  /// 根据地支获取神将
  ///
  /// [diZhi] 地盘地支
  /// [config] 神将配置
  /// 返回对应的神将
  static ShenJiang? getShenJiangByDiZhi(String diZhi, ShenJiangConfig config) {
    return config.diZhiToShenJiang[diZhi];
  }

  /// 获取神将的吉凶属性
  ///
  /// 吉神将：贵人、六合、青龙、太常、太阴、天后
  /// 凶神将：腾蛇、朱雀、勾陈、天空、白虎、玄武
  static bool isJiShenJiang(ShenJiang shenJiang) {
    const jiShenJiang = {
      ShenJiang.guiRen,
      ShenJiang.liuHe,
      ShenJiang.qingLong,
      ShenJiang.taiChang,
      ShenJiang.taiYin,
      ShenJiang.tianHou,
    };
    return jiShenJiang.contains(shenJiang);
  }

  /// 获取神将的主要含义
  static String getShenJiangMeaning(ShenJiang shenJiang) {
    return switch (shenJiang) {
      ShenJiang.guiRen => '贵人相助、吉庆、官禄',
      ShenJiang.tengShe => '惊恐、怪异、虚诈、忧疑',
      ShenJiang.zhuQue => '文书、口舌、信息、是非',
      ShenJiang.liuHe => '和合、婚姻、交易、媒介',
      ShenJiang.gouChen => '田土、争斗、牢狱、迟滞',
      ShenJiang.qingLong => '喜庆、财帛、婚姻、进益',
      ShenJiang.tianKong => '欺诈、空亡、虚假、落空',
      ShenJiang.baiHu => '凶丧、疾病、血光、道路',
      ShenJiang.taiChang => '宴会、衣冠、文书、娱乐',
      ShenJiang.xuanWu => '盗贼、暗昧、私情、奸邪',
      ShenJiang.taiYin => '阴私、暗事、女人、隐蔽',
      ShenJiang.tianHou => '后宫、妇女、阴私、柔顺',
    };
  }
}
