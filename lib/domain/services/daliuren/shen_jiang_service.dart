import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/dlr_rule_contract.dart';
import '../../../divination_systems/daliuren/models/pan_params.dart';
import '../../../divination_systems/daliuren/models/shen_jiang_config.dart';
import '../../../divination_systems/daliuren/models/tianpan_map_contract.dart';

/// 神将配置服务
///
/// 大六壬十二神将的配置规则：
/// 1. 根据昼夜选择贵人所乘天盘支
/// 2. 由天盘逆映射求贵人所临地盘宫
/// 3. 按贵人落宫确定顺逆
/// 4. 以固定将序和有符号步进布列十二将
class ShenJiangService {
  ShenJiangService._();

  static const Set<String> _dayBranches = <String>{
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
  };

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
    DaLiuRenDayNightMode dayNightMode = DaLiuRenDayNightMode.auto,
    DaLiuRenGuiRenVerse guiRenVerse = DaLiuRenGuiRenVerse.classic,
  }) {
    final validatedMap = TianPanMapContract.validate(tianPanMap);
    if (!DaLiuRenConstants.tianGan.contains(riGan)) {
      throw ArgumentError.value(riGan, 'riGan', '无效天干');
    }
    if (!DaLiuRenConstants.diZhi.contains(shiZhi)) {
      throw ArgumentError.value(shiZhi, 'shiZhi', '无效地支');
    }
    if (guiRenVerse == DaLiuRenGuiRenVerse.jiaDayAlt) {
      throw ArgumentError.value(
        guiRenVerse,
        'guiRenVerse',
        'jiaDayAlt 仅用于历史盘解码，不得生成新盘',
      );
    }

    final isDay = switch (dayNightMode) {
      DaLiuRenDayNightMode.auto => _dayBranches.contains(shiZhi),
      DaLiuRenDayNightMode.day => true,
      DaLiuRenDayNightMode.night => false,
    };
    final guiRenPositions =
        DaLiuRenConstants.getGuiRenPositionByVerse(riGan, guiRenVerse);
    final isYangGui = isDay;
    final selectedGuiRenTianBranch =
        isDay ? guiRenPositions[0] : guiRenPositions[1];
    final heavenBranchToEarthPalace = <String, String>{
      for (final entry in validatedMap.entries) entry.value: entry.key,
    };
    final guiRenEarthPalace =
        heavenBranchToEarthPalace[selectedGuiRenTianBranch];
    if (guiRenEarthPalace == null) {
      throw StateError('天盘中找不到贵人天盘支: $selectedGuiRenTianBranch');
    }

    final actualDirection =
        ShenJiangConfig.shunEarthPalaces.contains(guiRenEarthPalace)
            ? ShenJiangDirection.shun
            : ShenJiangDirection.ni;
    final step = actualDirection == ShenJiangDirection.shun ? 1 : -1;
    final guiRenEarthIndex = DaLiuRenConstants.getDiZhiIndex(guiRenEarthPalace);
    final positions = <ShenJiangPosition>[];
    final tianBranchToGeneral = <String, ShenJiang>{};
    final earthPalaceToGeneral = <String, ShenJiang>{};

    for (var index = 0;
        index < DaLiuRenConstants.shenJiangOrder.length;
        index++) {
      final earthIndex = (guiRenEarthIndex + step * index + 12) % 12;
      final earthPalace = DaLiuRenConstants.getDiZhiByIndex(earthIndex);
      final heavenBranch = validatedMap[earthPalace]!;
      final shenJiang = DaLiuRenConstants.shenJiangOrder[index];

      positions.add(ShenJiangPosition(
        shenJiang: shenJiang,
        heavenBranch: heavenBranch,
        earthPalace: earthPalace,
      ));
      tianBranchToGeneral[heavenBranch] = shenJiang;
      earthPalaceToGeneral[earthPalace] = shenJiang;
    }

    return ShenJiangConfig(
      selectedGuiRenTianBranch: selectedGuiRenTianBranch,
      guiRenEarthPalace: guiRenEarthPalace,
      isYangGui: isYangGui,
      actualDirection: actualDirection,
      positions: positions,
      tianBranchToGeneral: tianBranchToGeneral,
      earthPalaceToGeneral: earthPalaceToGeneral,
      executionRuleRef: DlrRuleRef.projectPan(
        DlrProjectPanRuleIds.shenJiangLandingPalaceLayout,
      ),
      classicAttributionRuleIds: DlrShenJiangClassicRuleIds.currentAttributions,
    );
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
