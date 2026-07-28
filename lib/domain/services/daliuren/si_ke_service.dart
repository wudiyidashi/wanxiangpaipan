import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/ke.dart';
import '../../../divination_systems/daliuren/models/si_ke.dart';
import '../../../divination_systems/daliuren/models/tianpan_map_contract.dart';
import '../shared/tiangan_dizhi_service.dart';
import '../shared/wuxing_service.dart';

typedef ChengShenResolver = ShenJiang? Function(String tianPanZhi);

/// 四课排列服务
///
/// 大六壬四课的排列规则：
/// - 一课：日干为下神，日干寄宫上的天盘地支为上神
/// - 二课：一课上神为下神，其上天盘地支为上神
/// - 三课：日支为下神，其上天盘地支为上神
/// - 四课：三课上神为下神，其上天盘地支为上神
class SiKeService {
  SiKeService._();

  /// 排列四课
  ///
  /// [riGan] 日干
  /// [riZhi] 日支
  /// [tianPanMap] 天盘映射表（地盘地支 -> 天盘地支）
  /// [resolveChengShen] 按天盘上神解析乘神，查无结果时构造失败
  /// 返回 SiKe 模型
  static SiKe arrangeSiKe({
    required String riGan,
    required String riZhi,
    required Map<String, String> tianPanMap,
    required ChengShenResolver resolveChengShen,
  }) {
    _validateDayGanZhi(riGan, riZhi);
    final validatedMap = TianPanMapContract.validate(tianPanMap);

    // 获取日干寄宫
    final riGanJiGong = DaLiuRenConstants.getGanJiGong(riGan);

    // 一课：日干为下神，其寄宫上的天盘地支为上神
    final ke1XiaShen = riGan;
    final ke1ShangShenFromJiGong = validatedMap[riGanJiGong]!;

    // 二课：一课上神为下神，其上天盘地支为上神
    final ke2XiaShen = ke1ShangShenFromJiGong;
    final ke2ShangShen = validatedMap[ke2XiaShen]!;

    // 三课：日支为下神，其上天盘地支为上神
    final ke3XiaShen = riZhi;
    final ke3ShangShen = validatedMap[ke3XiaShen]!;

    // 四课：三课上神为下神，其上天盘地支为上神
    final ke4XiaShen = ke3ShangShen;
    final ke4ShangShen = validatedMap[ke4XiaShen]!;

    // 创建四课
    final ke1 = _createKe(
      index: 1,
      shangShen: ke1ShangShenFromJiGong,
      xiaShen: ke1XiaShen,
      resolveChengShen: resolveChengShen,
    );

    final ke2 = _createKe(
      index: 2,
      shangShen: ke2ShangShen,
      xiaShen: ke2XiaShen,
      resolveChengShen: resolveChengShen,
    );

    final ke3 = _createKe(
      index: 3,
      shangShen: ke3ShangShen,
      xiaShen: ke3XiaShen,
      resolveChengShen: resolveChengShen,
    );

    final ke4 = _createKe(
      index: 4,
      shangShen: ke4ShangShen,
      xiaShen: ke4XiaShen,
      resolveChengShen: resolveChengShen,
    );

    return SiKe(
      ke1: ke1,
      ke2: ke2,
      ke3: ke3,
      ke4: ke4,
      riGan: riGan,
      riZhi: riZhi,
    );
  }

  /// 创建单课
  static Ke _createKe({
    required int index,
    required String shangShen,
    required String xiaShen,
    required ChengShenResolver resolveChengShen,
  }) {
    final chengShen = resolveChengShen(shangShen);
    if (chengShen == null) {
      throw StateError('无法解析第$index课上神$shangShen的乘神');
    }
    return _createKeFromFacts(
      index: index,
      shangShen: shangShen,
      xiaShen: xiaShen,
      chengShen: chengShen,
    );
  }

  static Ke _createKeFromFacts({
    required int index,
    required String shangShen,
    required String xiaShen,
    required ShenJiang chengShen,
  }) {
    // 获取上下神五行
    final shangShenWuXing = _getWuXing(shangShen);
    final xiaShenWuXing = _getWuXing(xiaShen);

    // 计算五行关系
    String? wuXingRelation;
    bool hasKe = false;
    bool isZeiKe = false;
    bool isBiYong = false;

    if (shangShenWuXing != null && xiaShenWuXing != null) {
      // 两方向独立判定：
      // 下神克上神 → 下贼上（isZeiKe）；上神克下神 → 上克下（isBiYong）
      if (WuXingService.isKe(xiaShenWuXing, shangShenWuXing)) {
        wuXingRelation = '下克上';
        hasKe = true;
        isZeiKe = true;
      }
      if (WuXingService.isKe(shangShenWuXing, xiaShenWuXing)) {
        wuXingRelation = '上克下';
        hasKe = true;
        isBiYong = true;
      }
      if (!hasKe) {
        // 上生下
        if (WuXingService.isSheng(shangShenWuXing, xiaShenWuXing)) {
          wuXingRelation = '上生下';
        }
        // 下生上
        else if (WuXingService.isSheng(xiaShenWuXing, shangShenWuXing)) {
          wuXingRelation = '下生上';
        }
        // 比和
        else if (shangShenWuXing == xiaShenWuXing) {
          wuXingRelation = '比和';
        }
      }
    }

    return Ke(
      index: index,
      shangShen: shangShen,
      xiaShen: xiaShen,
      chengShen: chengShen,
      shangShenWuXing: shangShenWuXing?.name ?? '',
      xiaShenWuXing: xiaShenWuXing?.name ?? '',
      wuXingRelation: wuXingRelation,
      hasKe: hasKe,
      isZeiKe: isZeiKe,
      isBiYong: isBiYong,
    );
  }

  /// 判断四课是否为伏吟
  ///
  /// 伏吟：天地盘同位（即天盘地支与地盘地支相同）
  static bool isFuYin(Map<String, String> tianPanMap) {
    final validatedMap = TianPanMapContract.validate(tianPanMap);
    for (final entry in validatedMap.entries) {
      if (entry.key != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// 判断四课是否为反吟
  ///
  /// 反吟：天地盘相冲（即天盘地支与地盘地支对冲）
  static bool isFanYin(Map<String, String> tianPanMap) {
    final validatedMap = TianPanMapContract.validate(tianPanMap);
    for (final entry in validatedMap.entries) {
      final diPan = entry.key;
      final tianPan = entry.value;
      final chong = DaLiuRenConstants.getChongZhi(diPan);
      if (tianPan != chong) {
        return false;
      }
    }
    return true;
  }

  /// Validates an existing four-lesson model against the same day and plate.
  ///
  /// The general attached to each lesson is intentionally excluded because
  /// C04 owns the heaven-branch/general coordinate contract.
  static Map<String, String> validateSiKe(
    SiKe siKe,
    Map<String, String> tianPanMap,
  ) {
    _validateDayGanZhi(siKe.riGan, siKe.riZhi);
    final validatedMap = TianPanMapContract.validate(tianPanMap);
    final ganGong = DaLiuRenConstants.getGanJiGong(siKe.riGan);
    final ganShang = validatedMap[ganGong]!;
    final zhiShang = validatedMap[siKe.riZhi]!;
    final expectedPairs = <({String xia, String shang})>[
      (xia: siKe.riGan, shang: ganShang),
      (xia: ganShang, shang: validatedMap[ganShang]!),
      (xia: siKe.riZhi, shang: zhiShang),
      (xia: zhiShang, shang: validatedMap[zhiShang]!),
    ];

    for (var index = 0; index < expectedPairs.length; index++) {
      final actual = siKe.allKe[index];
      final pair = expectedPairs[index];
      final expected = _createKeFromFacts(
        index: index + 1,
        shangShen: pair.shang,
        xiaShen: pair.xia,
        chengShen: actual.chengShen,
      );
      if (!_sameDerivedFacts(actual, expected)) {
        throw ArgumentError.value(
          siKe,
          'siKe',
          '第${index + 1}课的课序、上下神链或五行克向与日干支及天盘不一致',
        );
      }
    }
    return validatedMap;
  }

  static void _validateDayGanZhi(String riGan, String riZhi) {
    final dayGanZhi = '$riGan$riZhi';
    if (!TianGanDiZhiService.isValidGanZhi(dayGanZhi)) {
      throw ArgumentError.value(dayGanZhi, 'riGan/riZhi', '必须组成合法六十甲子');
    }
  }

  static bool _sameDerivedFacts(Ke actual, Ke expected) =>
      actual.index == expected.index &&
      actual.shangShen == expected.shangShen &&
      actual.xiaShen == expected.xiaShen &&
      actual.shangShenWuXing == expected.shangShenWuXing &&
      actual.xiaShenWuXing == expected.xiaShenWuXing &&
      actual.wuXingRelation == expected.wuXingRelation &&
      actual.hasKe == expected.hasKe &&
      actual.isZeiKe == expected.isZeiKe &&
      actual.isBiYong == expected.isBiYong;

  static WuXing? _getWuXing(String symbol) {
    return WuXingService.getWuXingFromBranch(symbol) ??
        WuXingService.getWuXingFromStem(symbol);
  }
}
