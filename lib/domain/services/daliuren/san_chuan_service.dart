import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../divination_systems/daliuren/models/chuan.dart';
import '../../../divination_systems/daliuren/models/san_chuan.dart';
import '../../../divination_systems/daliuren/models/si_ke.dart';
import '../../../divination_systems/daliuren/models/shen_jiang_config.dart';
import '../shared/wuxing_service.dart';

/// 三传推导服务
///
/// 大六壬三传的推导是排盘的核心，根据四课的五行关系，
/// 按照九种课体规则推导出初传、中传、末传。
///
/// 九种课体（按判断优先级）：
/// 1. 贼克 - 下克上，取下克上者为用
/// 2. 比用 - 上克下，取与日干比者为用
/// 3. 涉害 - 俱比俱不比，涉害深者为用
/// 4. 遥克 - 四课无克，遥克取之（TODO）
/// 5. 昴星 - 无遥克，昴星从位取之（TODO）
/// 6. 别责 - 阴阳不备，别责取之（TODO）
/// 7. 八专 - 干支同位，八专法取之（TODO）
/// 8. 伏吟 - 天盘与地盘同宫
/// 9. 反吟 - 天盘与地盘对冲
class SanChuanService {
  SanChuanService._();

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
    // 判断是否伏吟或反吟
    final isFuYin = _isFuYin(tianPanMap);
    final isFanYin = _isFanYin(tianPanMap);

    KeType keType;
    String chuChuanDiZhi;
    String? keTypeExplanation;

    if (isFuYin) {
      // 伏吟课
      keType = KeType.fuYin;
      chuChuanDiZhi = _deriveFuYinChuChuan(siKe);
      keTypeExplanation = '天地盘同位，伏吟法取用';
    } else if (isFanYin) {
      // 反吟课
      keType = KeType.fanYin;
      chuChuanDiZhi = _deriveFanYinChuChuan(siKe, tianPanMap);
      keTypeExplanation = '天地盘相冲，反吟法取用';
    } else if (siKe.hasZeiKe) {
      // 贼克课（下克上）
      keType = KeType.zeiKe;
      final result = _deriveZeiKeChuChuan(siKe);
      chuChuanDiZhi = result.diZhi;
      keTypeExplanation = result.explanation;
    } else if (siKe.hasBiYong) {
      // 比用课（上克下）
      keType = KeType.biYong;
      final result = _deriveBiYongChuChuan(siKe);
      chuChuanDiZhi = result.diZhi;
      keTypeExplanation = result.explanation;
    } else {
      // 涉害课或其他（暂时使用涉害法）
      keType = KeType.sheHai;
      chuChuanDiZhi = _deriveSheHaiChuChuan(siKe, tianPanMap);
      keTypeExplanation = '四课无贼克比用，涉害法取用';
    }

    // 根据初传推导中传和末传
    final zhongChuanDiZhi = tianPanMap[chuChuanDiZhi] ?? chuChuanDiZhi;
    final moChuanDiZhi = tianPanMap[zhongChuanDiZhi] ?? zhongChuanDiZhi;

    // 创建三传
    final chuChuan = _createChuan(
      position: ChuanPosition.chu,
      diZhi: chuChuanDiZhi,
      riGan: siKe.riGan,
      shenJiangConfig: shenJiangConfig,
      kongWang: kongWang,
    );

    final zhongChuan = _createChuan(
      position: ChuanPosition.zhong,
      diZhi: zhongChuanDiZhi,
      riGan: siKe.riGan,
      shenJiangConfig: shenJiangConfig,
      kongWang: kongWang,
    );

    final moChuan = _createChuan(
      position: ChuanPosition.mo,
      diZhi: moChuanDiZhi,
      riGan: siKe.riGan,
      shenJiangConfig: shenJiangConfig,
      kongWang: kongWang,
    );

    return SanChuan(
      chuChuan: chuChuan,
      zhongChuan: zhongChuan,
      moChuan: moChuan,
      keType: keType,
      keTypeExplanation: keTypeExplanation,
    );
  }

  /// 判断是否伏吟
  static bool _isFuYin(Map<String, String> tianPanMap) {
    for (final entry in tianPanMap.entries) {
      if (entry.key != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// 判断是否反吟
  static bool _isFanYin(Map<String, String> tianPanMap) {
    for (final entry in tianPanMap.entries) {
      final diPan = entry.key;
      final tianPan = entry.value;
      final chong = DaLiuRenConstants.getChongZhi(diPan);
      if (tianPan != chong) {
        return false;
      }
    }
    return true;
  }

  /// 伏吟法取初传
  ///
  /// 伏吟课取用规则：
  /// 阳日取日干寄宫的冲位，阴日取日支的刑位或冲位
  static String _deriveFuYinChuChuan(SiKe siKe) {
    final isYangGan = DaLiuRenConstants.isYangGan(siKe.riGan);
    if (isYangGan) {
      // 阳日：取日干寄宫的冲位
      final jiGong = DaLiuRenConstants.getGanJiGong(siKe.riGan);
      return DaLiuRenConstants.getChongZhi(jiGong);
    } else {
      // 阴日：取日支的冲位
      return DaLiuRenConstants.getChongZhi(siKe.riZhi);
    }
  }

  /// 反吟法取初传
  ///
  /// 反吟课取用规则：
  /// 取驿马为初传（寅申巳亥年驿马规则）
  /// 简化处理：取日支的冲位
  static String _deriveFanYinChuChuan(
      SiKe siKe, Map<String, String> tianPanMap) {
    // 简化处理：取四课中有克的作为初传，无克则取日支冲
    if (siKe.hasZeiKe) {
      return siKe.zeiKeList.first.xiaShen;
    }
    return DaLiuRenConstants.getChongZhi(siKe.riZhi);
  }

  /// 贼克法取初传
  ///
  /// 贼克课：下克上为贼，取下克上者的下神为初传
  /// 如果有多个贼克，取涉害深者
  static ({String diZhi, String explanation}) _deriveZeiKeChuChuan(SiKe siKe) {
    final zeiKeList = siKe.zeiKeList;

    if (zeiKeList.length == 1) {
      return (
        diZhi: zeiKeList.first.xiaShen,
        explanation:
            '下克上，第${zeiKeList.first.index}课${zeiKeList.first.xiaShen}贼${zeiKeList.first.shangShen}，取${zeiKeList.first.xiaShen}为用'
      );
    }

    // 多个贼克，需要进一步判断（比较涉害深度或取与日干比者）
    // 简化处理：取第一个贼克
    final selected = zeiKeList.first;
    return (
      diZhi: selected.xiaShen,
      explanation: '多贼克，取第${selected.index}课${selected.xiaShen}为用'
    );
  }

  /// 比用法取初传
  ///
  /// 比用课：上克下，取与日干同类（比）者的上神为初传
  static ({String diZhi, String explanation}) _deriveBiYongChuChuan(SiKe siKe) {
    final biYongList = siKe.biYongList;
    final riGanWuXing = WuXingService.getWuXingFromStem(siKe.riGan);

    if (biYongList.length == 1) {
      return (
        diZhi: biYongList.first.shangShen,
        explanation:
            '上克下，第${biYongList.first.index}课${biYongList.first.shangShen}克${biYongList.first.xiaShen}，取${biYongList.first.shangShen}为用'
      );
    }

    // 多个比用，取与日干五行相同（比）者
    if (riGanWuXing != null) {
      for (final ke in biYongList) {
        final shangShenWuXing = WuXingService.getWuXingFromBranch(ke.shangShen);
        if (shangShenWuXing == riGanWuXing) {
          return (
            diZhi: ke.shangShen,
            explanation: '多比用，取与日干${siKe.riGan}同五行的${ke.shangShen}为用'
          );
        }
      }
    }

    // 如果没有与日干比者，取第一个
    final selected = biYongList.first;
    return (
      diZhi: selected.shangShen,
      explanation: '上克下，取第${selected.index}课${selected.shangShen}为用'
    );
  }

  /// 涉害法取初传
  ///
  /// 涉害课：四课俱比俱不比，取涉害深者为用
  /// 涉害深度：从所克地支数到被克地支的距离
  static String _deriveSheHaiChuChuan(
      SiKe siKe, Map<String, String> tianPanMap) {
    // 涉害法较复杂，这里简化处理
    // 取日干寄宫上神为初传
    final jiGong = DaLiuRenConstants.getGanJiGong(siKe.riGan);
    return tianPanMap[jiGong] ?? jiGong;
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
