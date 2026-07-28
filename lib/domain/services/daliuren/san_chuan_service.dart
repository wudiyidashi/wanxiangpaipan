import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/chuan.dart';
import '../../../divination_systems/daliuren/models/ke.dart';
import '../../../divination_systems/daliuren/models/san_chuan.dart';
import '../../../divination_systems/daliuren/models/si_ke.dart';
import '../../../divination_systems/daliuren/models/shen_jiang_config.dart';
import '../shared/wuxing_service.dart';
import 'si_ke_service.dart';

/// 三传推导内部结果
typedef _Derivation = ({
  KeType keType,
  String chu,
  String zhong,
  String mo,
  String explanation,
});

/// 发用裁选结果（贼克/比用/涉害）
typedef _FaYong = ({KeType keType, String chu, String explanation});

/// 三传推导服务
///
/// 大六壬三传的推导是排盘的核心，按《大六壬指南》九宗门口径实现。
///
/// 判定顺序：
/// 1. 伏吟 - 天地盘同位（刑传链，自任/自信/自刑分支）
/// 2. 反吟 - 天地盘对冲（有克取上神裁选；无克取日支驿马，井栏射）
/// 3. 八专 - 八专日（甲寅/庚申/丁未/己未/癸丑）无克，阳顺三阴逆三
/// 4. 贼克 - 下贼上优先于上克下，取上神发用（重审/元首）
/// 5. 比用 - 同方向多课取与日干俱比者（知一）
/// 6. 涉害 - 俱比俱不比，涉害深者发用；并列取孟/仲/刚柔日
/// 7. 遥克 - 四课无克，二三四课上神遥克（蒿矢先、弹射后）
/// 8. 昴星 - 四课全无遥克，刚仰柔俯酉位取用
/// 9. 别责 - 三课备无遥克，刚日干合寄宫上神、柔日支前合
class SanChuanService {
  SanChuanService._();

  /// 四孟
  static const List<String> _mengZhi = ['寅', '申', '巳', '亥'];

  /// 四仲
  static const List<String> _zhongZhi = ['子', '午', '卯', '酉'];

  /// 推导三传
  ///
  /// [siKe] 四课
  /// [tianPanMap] 天盘映射表
  /// [shenJiangConfig] 神将配置（可选）
  /// [kongWang] 空亡地支列表（可选）
  /// 返回 SanChuan 模型
  static SanChuan deriveSanChuan({
    required SiKe siKe,
    required Map<String, String> tianPanMap,
    ShenJiangConfig? shenJiangConfig,
    List<String>? kongWang,
  }) {
    final validatedMap = SiKeService.validateSiKe(siKe, tianPanMap);
    final derivation = _derive(siKe, validatedMap);

    final chuChuan = _createChuan(
      position: ChuanPosition.chu,
      diZhi: derivation.chu,
      riGan: siKe.riGan,
      shenJiangConfig: shenJiangConfig,
      kongWang: kongWang,
    );

    final zhongChuan = _createChuan(
      position: ChuanPosition.zhong,
      diZhi: derivation.zhong,
      riGan: siKe.riGan,
      shenJiangConfig: shenJiangConfig,
      kongWang: kongWang,
    );

    final moChuan = _createChuan(
      position: ChuanPosition.mo,
      diZhi: derivation.mo,
      riGan: siKe.riGan,
      shenJiangConfig: shenJiangConfig,
      kongWang: kongWang,
    );

    return SanChuan(
      chuChuan: chuChuan,
      zhongChuan: zhongChuan,
      moChuan: moChuan,
      keType: derivation.keType,
      keTypeExplanation: derivation.explanation,
    );
  }

  /// 九宗门总流程
  static _Derivation _derive(SiKe siKe, Map<String, String> tianPanMap) {
    // 1. 伏吟：天地盘同位
    if (_isFuYin(tianPanMap)) {
      return _deriveFuYin(siKe, tianPanMap);
    }

    // 2. 反吟：天地盘对冲
    if (_isFanYin(tianPanMap)) {
      return _deriveFanYin(siKe, tianPanMap);
    }

    final isBaZhuanDay = DaLiuRenConstants.isBaZhuanDay(siKe.riGan, siKe.riZhi);
    final hasAnyKe = siKe.hasZeiKe || siKe.hasBiYong;

    // 3. 八专日无克 → 八专法
    if (isBaZhuanDay && !hasAnyKe) {
      return _deriveBaZhuan(siKe);
    }

    // 4/5. 有克 → 贼克/比用/涉害裁选（八专日有克仍标 baZhuan）
    if (hasAnyKe) {
      final selected = _selectFaYong(siKe, tianPanMap);
      final zhong = _tianPan(tianPanMap, selected.chu);
      final mo = _tianPan(tianPanMap, zhong);
      if (isBaZhuanDay) {
        return (
          keType: KeType.baZhuan,
          chu: selected.chu,
          zhong: zhong,
          mo: mo,
          explanation: '八专日有克，取克发用；${selected.explanation}',
        );
      }
      return (
        keType: selected.keType,
        chu: selected.chu,
        zhong: zhong,
        mo: mo,
        explanation: selected.explanation,
      );
    }

    // 6. 四课全无克 → 遥克
    final yaoKe = _tryYaoKe(siKe);
    if (yaoKe != null) {
      final zhong = _tianPan(tianPanMap, yaoKe.chu);
      final mo = _tianPan(tianPanMap, zhong);
      return (
        keType: KeType.yaoKe,
        chu: yaoKe.chu,
        zhong: zhong,
        mo: mo,
        explanation: yaoKe.explanation,
      );
    }

    // 7/8. 无遥克：四课全 → 昴星；四课不全（三课备）→ 别责
    if (_isSiKeQuan(siKe)) {
      return _deriveMaoXing(siKe, tianPanMap);
    }
    return _deriveBieZe(siKe, tianPanMap);
  }

  // ==================== 贼克 / 比用 / 涉害 ====================

  /// 有克时的发用裁选：贼克（下贼上优先）→ 比用 → 涉害
  ///
  /// 初传一律取所选课的上神。
  static _FaYong _selectFaYong(SiKe siKe, Map<String, String> tianPanMap) {
    final List<Ke> candidates;
    final String directionLabel;
    if (siKe.hasZeiKe) {
      // "取课先从下贼呼"：有下贼上时，上克下课全部不参与
      candidates = siKe.zeiKeList;
      directionLabel = '下贼上';
    } else {
      candidates = siKe.biYongList;
      directionLabel = '上克下';
    }

    // 贼克：同方向仅一课，直接发用
    if (candidates.length == 1) {
      final ke = candidates.first;
      final traditionalName = directionLabel == '下贼上' ? '重审' : '元首';
      return (
        keType: KeType.zeiKe,
        chu: ke.shangShen,
        explanation: '$directionLabel：第${ke.index}课'
            '${ke.xiaShen}与${ke.shangShen}相克，'
            '取上神${ke.shangShen}发用（$traditionalName课）',
      );
    }

    // 比用：取上神与日干俱比（阴阳相同）者
    final biList = candidates
        .where((ke) => _isSameParityAsRiGan(ke.shangShen, siKe.riGan))
        .toList();
    if (biList.length == 1) {
      final ke = biList.first;
      final names = candidates.map((k) => k.shangShen).join('、');
      return (
        keType: KeType.biYong,
        chu: ke.shangShen,
        explanation: '多课$directionLabel（候选$names），'
            '取与日干${siKe.riGan}俱比之${ke.shangShen}发用（比用·知一课）',
      );
    }

    // 涉害：俱比（≥2 比）在比者内部决胜；俱不比（0 比）在全体候选内决胜
    final pool = biList.length >= 2 ? biList : candidates;
    return _deriveSheHai(pool, siKe, tianPanMap, directionLabel);
  }

  /// 涉害裁选：深度计数 → 四孟 → 四仲 → 刚日干上/柔日支上
  static _FaYong _deriveSheHai(
    List<Ke> pool,
    SiKe siKe,
    Map<String, String> tianPanMap,
    String directionLabel,
  ) {
    // 按上神去重（同支涉害深度相同）
    final uniqueShen = <String>[];
    for (final ke in pool) {
      if (!uniqueShen.contains(ke.shangShen)) {
        uniqueShen.add(ke.shangShen);
      }
    }

    final depths = <String, int>{
      for (final shen in uniqueShen) shen: _sheHaiDepth(shen, tianPanMap),
    };
    final depthDesc =
        uniqueShen.map((shen) => '$shen涉${depths[shen]}害').join('、');

    // 1) 深者胜
    final maxDepth = depths.values.reduce((a, b) => a > b ? a : b);
    final deepest =
        uniqueShen.where((shen) => depths[shen] == maxDepth).toList();
    if (deepest.length == 1) {
      return (
        keType: KeType.sheHai,
        chu: deepest.first,
        explanation: '涉害：多课$directionLabel比用不决，历数涉害深度'
            '（$depthDesc），取深者${deepest.first}发用（涉害课）',
      );
    }

    // 2) 深度并列 → 所临地盘宫为四孟者（见机）
    final linGongOf = <String, String>{
      for (final shen in deepest) shen: _linGong(shen, tianPanMap),
    };
    final mengList =
        deepest.where((shen) => _mengZhi.contains(linGongOf[shen])).toList();
    if (mengList.length == 1) {
      return (
        keType: KeType.sheHai,
        chu: mengList.first,
        explanation: '涉害：深度并列（$depthDesc），'
            '取临四孟之${mengList.first}发用（涉害·见机课）',
      );
    }

    // 3) 无孟 → 四仲者（察微）
    if (mengList.isEmpty) {
      final zhongList =
          deepest.where((shen) => _zhongZhi.contains(linGongOf[shen])).toList();
      if (zhongList.length == 1) {
        return (
          keType: KeType.sheHai,
          chu: zhongList.first,
          explanation: '涉害：深度并列（$depthDesc），'
              '取临四仲之${zhongList.first}发用（涉害·察微课）',
        );
      }
    }

    // 4) 仍并列 → 刚日取干上神，柔日取支上神
    final isYang = DaLiuRenConstants.isYangGan(siKe.riGan);
    final chu = isYang ? siKe.ke1.shangShen : siKe.ke3.shangShen;
    final riDesc = isYang ? '刚日取干上神' : '柔日取支上神';
    return (
      keType: KeType.sheHai,
      chu: chu,
      explanation: '涉害：深度孟仲仍并列（$depthDesc），$riDesc$chu发用（涉害课）',
    );
  }

  /// 涉害深度：候选神自所临地盘宫（含）顺行历数至本家地盘宫（不含），
  /// 每宫的地支本气与所寄天干中，五行克候选神者各计一害。
  static int _sheHaiDepth(String shen, Map<String, String> tianPanMap) {
    final shenWuXing = WuXingService.getWuXingFromBranch(shen);
    if (shenWuXing == null) {
      return 0;
    }

    var index = DaLiuRenConstants.getDiZhiIndex(_linGong(shen, tianPanMap));
    final homeIndex = DaLiuRenConstants.getDiZhiIndex(shen);
    var depth = 0;
    while (index != homeIndex) {
      final gong = DaLiuRenConstants.getDiZhiByIndex(index);
      final gongWuXing = WuXingService.getWuXingFromBranch(gong);
      if (gongWuXing != null && WuXingService.isKe(gongWuXing, shenWuXing)) {
        depth++;
      }
      for (final gan in DaLiuRenConstants.getGongJiGan(gong)) {
        final ganWuXing = WuXingService.getWuXingFromStem(gan);
        if (ganWuXing != null && WuXingService.isKe(ganWuXing, shenWuXing)) {
          depth++;
        }
      }
      index = (index + 1) % 12;
    }
    return depth;
  }

  /// 候选神所临的地盘宫（天盘映射为双射，取首个匹配）
  static String _linGong(String shen, Map<String, String> tianPanMap) {
    for (final entry in tianPanMap.entries) {
      if (entry.value == shen) {
        return entry.key;
      }
    }
    throw StateError('合法天盘中找不到天盘支$shen所临地宫');
  }

  // ==================== 遥克 ====================

  /// 遥克：四课上下无克时，取二三四课上神与日干遥克。
  /// 先取上神克日干者（蒿矢），无则取日干克上神者（弹射）。
  static ({String chu, String explanation})? _tryYaoKe(SiKe siKe) {
    final riGanWuXing = WuXingService.getWuXingFromStem(siKe.riGan);
    if (riGanWuXing == null) {
      return null;
    }

    final candidates = [siKe.ke2, siKe.ke3, siKe.ke4];

    final haoShi = candidates.where((ke) {
      final wx = WuXingService.getWuXingFromBranch(ke.shangShen);
      return wx != null && WuXingService.isKe(wx, riGanWuXing);
    }).toList();

    final tanShe = candidates.where((ke) {
      final wx = WuXingService.getWuXingFromBranch(ke.shangShen);
      return wx != null && WuXingService.isKe(riGanWuXing, wx);
    }).toList();

    final List<Ke> pool;
    final String name;
    final String direction;
    if (haoShi.isNotEmpty) {
      pool = haoShi;
      name = '蒿矢';
      direction = '上神克日干';
    } else if (tanShe.isNotEmpty) {
      pool = tanShe;
      name = '弹射';
      direction = '日干克上神';
    } else {
      return null;
    }

    // 多者取与日干俱比者，仍不唯一取课序在前者
    Ke selected;
    var tieBreak = '';
    if (pool.length == 1) {
      selected = pool.first;
    } else {
      final biList = pool
          .where((ke) => _isSameParityAsRiGan(ke.shangShen, siKe.riGan))
          .toList();
      if (biList.length == 1) {
        selected = biList.first;
        tieBreak = '，多者取与日干俱比者';
      } else if (biList.length > 1) {
        selected = biList.first;
        tieBreak = '，俱比不唯一取课序在前者';
      } else {
        selected = pool.first;
        tieBreak = '，俱不比取课序在前者';
      }
    }

    return (
      chu: selected.shangShen,
      explanation: '四课无近克，遥克取用：$direction，'
          '第${selected.index}课上神${selected.shangShen}与日干${siKe.riGan}遥克'
          '$tieBreak，取${selected.shangShen}发用（遥克·$name课）',
    );
  }

  // ==================== 昴星 ====================

  /// 四课全：四课上神四位各异（design §3/§4.5 口径）
  static bool _isSiKeQuan(SiKe siKe) {
    return siKe.allKe.map((ke) => ke.shangShen).toSet().length == 4;
  }

  /// 昴星：四课全、无上下克、无遥克。刚日仰取地盘酉宫上神，柔日俯取天盘酉下之支。
  static _Derivation _deriveMaoXing(SiKe siKe, Map<String, String> tianPanMap) {
    final ganShang = siKe.ke1.shangShen;
    final zhiShang = siKe.ke3.shangShen;

    if (DaLiuRenConstants.isYangGan(siKe.riGan)) {
      // 刚日：初传取地盘酉宫上神，中传支上神，末传干上神（虎视）
      final chu = _tianPan(tianPanMap, '酉');
      return (
        keType: KeType.maoXing,
        chu: chu,
        zhong: zhiShang,
        mo: ganShang,
        explanation: '四课全无克无遥克，刚日昴星仰取地盘酉宫上神$chu发用，'
            '中传支上神$zhiShang，末传干上神$ganShang（昴星·虎视课）',
      );
    }

    // 柔日：初传取天盘酉所临之地盘支，中传干上神，末传支上神（冬蛇掩目）
    final chu = _linGong('酉', tianPanMap);
    return (
      keType: KeType.maoXing,
      chu: chu,
      zhong: ganShang,
      mo: zhiShang,
      explanation: '四课全无克无遥克，柔日昴星俯取天盘酉所临地盘之支$chu发用，'
          '中传干上神$ganShang，末传支上神$zhiShang（昴星·冬蛇掩目课）',
    );
  }

  // ==================== 别责 ====================

  /// 别责：四课不全（三课备）、无上下克、无遥克。
  /// 刚日取日干五合之干寄宫上神，柔日取日支三合前辰；中末传皆干上神。
  static _Derivation _deriveBieZe(SiKe siKe, Map<String, String> tianPanMap) {
    final ganShang = siKe.ke1.shangShen;

    if (DaLiuRenConstants.isYangGan(siKe.riGan)) {
      final heGan = DaLiuRenConstants.getGanWuHe(siKe.riGan)!;
      final heGong = DaLiuRenConstants.getGanJiGong(heGan);
      final chu = _tianPan(tianPanMap, heGong);
      return (
        keType: KeType.bieZe,
        chu: chu,
        zhong: ganShang,
        mo: ganShang,
        explanation: '三课备无克无遥克，刚日别责取日干${siKe.riGan}五合之'
            '$heGan寄宫$heGong上神$chu发用，中末传皆干上神$ganShang（别责课）',
      );
    }

    final chu = DaLiuRenConstants.getSanHeNext(siKe.riZhi);
    return (
      keType: KeType.bieZe,
      chu: chu,
      zhong: ganShang,
      mo: ganShang,
      explanation: '三课备无克无遥克，柔日别责取日支${siKe.riZhi}三合局前辰'
          '$chu发用，中末传皆干上神$ganShang（别责课）',
    );
  }

  // ==================== 八专 ====================

  /// 八专：八专日无上下克。阳日自干上神顺数三位（含本位），
  /// 阴日自第四课上神逆数三位（含本位）；中末传皆干上神。
  static _Derivation _deriveBaZhuan(SiKe siKe) {
    final ganShang = siKe.ke1.shangShen;

    if (DaLiuRenConstants.isYangGan(siKe.riGan)) {
      final index = DaLiuRenConstants.getDiZhiIndex(ganShang);
      final chu = DaLiuRenConstants.getDiZhiByIndex(index + 2);
      return (
        keType: KeType.baZhuan,
        chu: chu,
        zhong: ganShang,
        mo: ganShang,
        explanation: '八专日无克，阳日自干上神$ganShang顺数三位取$chu发用，'
            '中末传皆干上神$ganShang（八专课）',
      );
    }

    final ke4Shang = siKe.ke4.shangShen;
    final index = DaLiuRenConstants.getDiZhiIndex(ke4Shang);
    final chu = DaLiuRenConstants.getDiZhiByIndex(index - 2 + 12);
    return (
      keType: KeType.baZhuan,
      chu: chu,
      zhong: ganShang,
      mo: ganShang,
      explanation: '八专日无克，阴日自第四课上神$ke4Shang逆数三位取$chu发用，'
          '中末传皆干上神$ganShang（八专课）',
    );
  }

  // ==================== 伏吟 ====================

  /// 伏吟：天地盘同位。有克取克发用；无克刚日自任（干上）、柔日自信（支上）。
  /// 中末传走刑传链：中传=初传所刑；初传自刑则刚日取支上、柔日取干上；
  /// 末传=中传所刑；中传自刑则取其冲。
  static _Derivation _deriveFuYin(SiKe siKe, Map<String, String> tianPanMap) {
    final isYang = DaLiuRenConstants.isYangGan(siKe.riGan);
    final ganShang = siKe.ke1.shangShen;
    final zhiShang = siKe.ke3.shangShen;

    final String chu;
    final String faYongDesc;
    if (siKe.hasZeiKe || siKe.hasBiYong) {
      final selected = _selectFaYong(siKe, tianPanMap);
      chu = selected.chu;
      faYongDesc = '有克取克发用（${selected.explanation}）';
    } else if (isYang) {
      chu = ganShang;
      faYongDesc = '无克刚日取干上神$chu发用（自任）';
    } else {
      chu = zhiShang;
      faYongDesc = '无克柔日取支上神$chu发用（自信）';
    }

    // 中传：初传所刑；初传自刑则"次传颠倒日辰并"
    final String zhong;
    final String zhongDesc;
    if (DaLiuRenConstants.isZiXing(chu)) {
      zhong = isYang ? zhiShang : ganShang;
      zhongDesc = '初传$chu自刑，中传${isYang ? '刚日取支上神' : '柔日取干上神'}$zhong';
    } else {
      zhong = DaLiuRenConstants.getXingZhi(chu);
      zhongDesc = '中传取初传所刑之$zhong';
    }

    // 末传：中传所刑；中传自刑则取冲
    final String mo;
    final String moDesc;
    if (DaLiuRenConstants.isZiXing(zhong)) {
      mo = DaLiuRenConstants.getChongZhi(zhong);
      moDesc = '中传$zhong自刑，末传取其冲$mo';
    } else {
      mo = DaLiuRenConstants.getXingZhi(zhong);
      moDesc = '末传取中传所刑之$mo';
    }

    return (
      keType: KeType.fuYin,
      chu: chu,
      zhong: zhong,
      mo: mo,
      explanation: '天地盘同位伏吟：$faYongDesc；$zhongDesc；$moDesc',
    );
  }

  // ==================== 反吟 ====================

  /// 反吟：天地盘对冲。有克按贼克/比用/涉害取上神，中末传天盘链；
  /// 无克取日支驿马发用，中传支上神，末传干上神（井栏射）。
  static _Derivation _deriveFanYin(SiKe siKe, Map<String, String> tianPanMap) {
    if (siKe.hasZeiKe || siKe.hasBiYong) {
      final selected = _selectFaYong(siKe, tianPanMap);
      final zhong = _tianPan(tianPanMap, selected.chu);
      final mo = _tianPan(tianPanMap, zhong);
      return (
        keType: KeType.fanYin,
        chu: selected.chu,
        zhong: zhong,
        mo: mo,
        explanation: '天地盘对冲反吟，有克取克发用：${selected.explanation}',
      );
    }

    final chu = DaLiuRenConstants.getYiMa(siKe.riZhi);
    final zhiShang = siKe.ke3.shangShen;
    final ganShang = siKe.ke1.shangShen;
    return (
      keType: KeType.fanYin,
      chu: chu,
      zhong: zhiShang,
      mo: ganShang,
      explanation: '天地盘对冲反吟，四课无克，取日支${siKe.riZhi}驿马$chu发用，'
          '中传支上神$zhiShang，末传干上神$ganShang（井栏射）',
    );
  }

  // ==================== 结构判定与工具 ====================

  /// 判断是否伏吟
  static bool _isFuYin(Map<String, String> tianPanMap) {
    return SiKeService.isFuYin(tianPanMap);
  }

  /// 判断是否反吟
  static bool _isFanYin(Map<String, String> tianPanMap) {
    return SiKeService.isFanYin(tianPanMap);
  }

  /// 天盘链取值（地盘支 -> 天盘支）
  static String _tianPan(Map<String, String> tianPanMap, String zhi) {
    final result = tianPanMap[zhi];
    if (result == null) {
      throw StateError('合法天盘缺少地盘支$zhi');
    }
    return result;
  }

  static bool _isSameParityAsRiGan(String branch, String riGan) {
    return DaLiuRenConstants.isYangZhi(branch) ==
        DaLiuRenConstants.isYangGan(riGan);
  }

  /// 创建单传
  static Chuan _createChuan({
    required ChuanPosition position,
    required String diZhi,
    required String riGan,
    ShenJiangConfig? shenJiangConfig,
    List<String>? kongWang,
  }) {
    // 获取五行
    final wuXing = WuXingService.getWuXingFromBranch(diZhi);

    // 获取六亲（根据日干五行和地支五行的关系）
    final riGanWuXing = WuXingService.getWuXingFromStem(riGan);
    String liuQin = '比肩';
    if (wuXing != null && riGanWuXing != null) {
      final relation = WuXingService.getRelation(riGanWuXing, wuXing);
      liuQin = switch (relation) {
        WuXingRelation.woSheng => '子孙',
        WuXingRelation.shengWo => '父母',
        WuXingRelation.keWo => '官鬼',
        WuXingRelation.woKe => '妻财',
        WuXingRelation.biHe => '兄弟',
      };
    }

    // 获取乘神
    ShenJiang chengShen = ShenJiang.guiRen;
    if (shenJiangConfig != null) {
      final sj = shenJiangConfig.getShenJiangByDiZhi(diZhi);
      if (sj != null) {
        chengShen = sj;
      }
    }

    // 判断是否空亡
    final isKongWang = kongWang?.contains(diZhi) ?? false;

    return Chuan(
      position: position,
      diZhi: diZhi,
      wuXing: wuXing?.name ?? '',
      chengShen: chengShen,
      liuQin: liuQin,
      isKongWang: isKongWang,
    );
  }
}
