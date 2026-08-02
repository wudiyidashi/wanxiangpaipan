import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../fushen_service.dart';
import '../../shared/liuqin_service.dart';
import 'actor_availability_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_trace.dart';
import 'rules/liuyao_catalog.dart';

/// 六亲推理链推导：由用户选定的用神推出元神、忌神、仇神、闲神。
///
/// 六亲相生：父→兄→子→财→官→父；相克：父克子、子克官、官克兄、兄克财、财克父。
/// 元神生用神，忌神克用神，仇神克元神而生忌神，其余为闲神。
/// 同六亲多爻时动爻优先，其次低爻位优先。
class LiuQinDeduceService {
  LiuQinDeduceService._();

  /// 我生者（父母生兄弟……官鬼生父母）
  static const Map<LiuQin, LiuQin> shengCycle = {
    LiuQin.fuMu: LiuQin.xiongDi,
    LiuQin.xiongDi: LiuQin.ziSun,
    LiuQin.ziSun: LiuQin.qiCai,
    LiuQin.qiCai: LiuQin.guanGui,
    LiuQin.guanGui: LiuQin.fuMu,
  };

  /// 我克者（父母克子孙……妻财克父母）
  static const Map<LiuQin, LiuQin> keCycle = {
    LiuQin.fuMu: LiuQin.ziSun,
    LiuQin.ziSun: LiuQin.guanGui,
    LiuQin.guanGui: LiuQin.xiongDi,
    LiuQin.xiongDi: LiuQin.qiCai,
    LiuQin.qiCai: LiuQin.fuMu,
  };

  /// 元神：生用神者
  static LiuQin yuanShenOf(LiuQin yongShen) =>
      shengCycle.entries.firstWhere((e) => e.value == yongShen).key;

  /// 忌神：克用神者
  static LiuQin jiShenOf(LiuQin yongShen) =>
      keCycle.entries.firstWhere((e) => e.value == yongShen).key;

  /// 仇神：克元神者（亦生忌神）
  static LiuQin chouShenOf(LiuQin yongShen) => jiShenOf(yuanShenOf(yongShen));

  /// 推导用神链。
  ///
  /// [yongShenPosition] 用神爻位；[isFuShen] 为 true 时取该爻位下的伏神为用神，
  /// 该爻位无伏神时抛出 [ArgumentError]。
  static YongShenChain deduce(
    Gua gua,
    int yongShenPosition, {
    bool isFuShen = false,
  }) {
    final LiuQin yongShenLiuQin;
    if (isFuShen) {
      final fuShen = FuShenService.calculateFuShen(gua)[yongShenPosition];
      if (fuShen == null) {
        throw ArgumentError('第$yongShenPosition爻无伏神，不能伏神取用');
      }
      yongShenLiuQin = fuShen.yao.liuQin;
    } else {
      yongShenLiuQin = gua.yaos[yongShenPosition - 1].liuQin;
    }

    final yuanShen = yuanShenOf(yongShenLiuQin);
    final jiShen = jiShenOf(yongShenLiuQin);
    final chouShen = chouShenOf(yongShenLiuQin);

    final duplicates = <int>[];
    if (!isFuShen) {
      for (final yao in gua.yaos) {
        if (yao.position != yongShenPosition && yao.liuQin == yongShenLiuQin) {
          duplicates.add(yao.position);
        }
      }
    }

    final xianShen = <int>[
      for (final yao in gua.yaos)
        if (yao.position != yongShenPosition &&
            !duplicates.contains(yao.position) &&
            yao.liuQin != yuanShen &&
            yao.liuQin != jiShen &&
            yao.liuQin != chouShen)
          yao.position,
    ];

    return YongShenChain(
      position: yongShenPosition,
      isFuShen: isFuShen,
      duplicatePositions: duplicates,
      yuanShenPosition: _findPosition(gua, yuanShen, yongShenPosition),
      jiShenPosition: _findPosition(gua, jiShen, yongShenPosition),
      chouShenPosition: _findPosition(gua, chouShen, yongShenPosition),
      xianShenPositions: xianShen,
    );
  }

  /// Keeps every role candidate while [YongShenChain] remains the UI projection.
  static List<LiuYaoRoleOccurrence> deduceRoleOccurrences(
    Gua gua,
    int yongShenPosition, {
    bool isFuShen = false,
  }) {
    final chain = deduce(
      gua,
      yongShenPosition,
      isFuShen: isFuShen,
    );
    final hiddenByPosition = FuShenService.calculateFuShen(gua);
    final hidden = isFuShen ? hiddenByPosition[yongShenPosition]!.yao : null;
    final yongShenLiuQin =
        hidden?.liuQin ?? gua.yaos[yongShenPosition - 1].liuQin;
    final yuanShen = yuanShenOf(yongShenLiuQin);
    final jiShen = jiShenOf(yongShenLiuQin);
    final chouShen = chouShenOf(yongShenLiuQin);
    final roles = <LiuYaoRoleOccurrence>[];

    LiuYaoRoleOccurrence occurrenceFor(
      Yao yao, {
      required bool isHiddenActor,
    }) {
      final LiuYaoRole role;
      final String roleRuleId;
      final bool selected;
      final bool representative;
      if (isHiddenActor && isFuShen && yao.position == yongShenPosition) {
        role = LiuYaoRole.yongShen;
        roleRuleId = LiuYaoRuleIds.ruleSelectedHiddenUseSpirit;
        selected = true;
        representative = true;
      } else if (!isHiddenActor &&
          !isFuShen &&
          yao.position == yongShenPosition) {
        role = LiuYaoRole.yongShen;
        roleRuleId = LiuYaoRuleIds.ruleSelectedUseSpirit;
        selected = true;
        representative = true;
      } else if (yao.liuQin == yongShenLiuQin) {
        role = LiuYaoRole.duplicateYongShen;
        roleRuleId = LiuYaoRuleIds.ruleDuplicateUseSpirit;
        selected = false;
        representative = false;
      } else if (yao.liuQin == yuanShen) {
        role = LiuYaoRole.yuanShen;
        roleRuleId = LiuYaoRuleIds.ruleSourceSpirit;
        selected = false;
        representative =
            !isHiddenActor && yao.position == chain.yuanShenPosition;
      } else if (yao.liuQin == jiShen) {
        role = LiuYaoRole.jiShen;
        roleRuleId = LiuYaoRuleIds.ruleAdverseSpirit;
        selected = false;
        representative = !isHiddenActor && yao.position == chain.jiShenPosition;
      } else if (yao.liuQin == chouShen) {
        role = LiuYaoRole.chouShen;
        roleRuleId = LiuYaoRuleIds.ruleEnemySpirit;
        selected = false;
        representative =
            !isHiddenActor && yao.position == chain.chouShenPosition;
      } else {
        role = LiuYaoRole.xianShen;
        roleRuleId = LiuYaoRuleIds.ruleIdleSpirit;
        selected = false;
        representative = false;
      }
      return LiuYaoRoleOccurrence(
        actor: isHiddenActor
            ? ActorAvailabilityService.hiddenActor(yao)
            : ActorAvailabilityService.mainActor(yao),
        role: role,
        roleRuleId: roleRuleId,
        reason: _roleReason(role, isHiddenActor: isHiddenActor),
        selected: selected,
        representative: representative,
      );
    }

    if (hidden != null) {
      roles.add(occurrenceFor(hidden, isHiddenActor: true));
    }
    for (final yao in gua.yaos) {
      roles.add(occurrenceFor(yao, isHiddenActor: false));
    }
    final hiddenEntries = hiddenByPosition.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in hiddenEntries) {
      if (isFuShen && entry.key == yongShenPosition) continue;
      roles.add(occurrenceFor(entry.value.yao, isHiddenActor: true));
    }
    return roles;
  }

  static String _roleReason(
    LiuYaoRole role, {
    required bool isHiddenActor,
  }) =>
      switch (role) {
        LiuYaoRole.yongShen => isHiddenActor ? '用户选定伏神为用神' : '用户选定的用神',
        LiuYaoRole.duplicateYongShen => '与所选用神同六亲',
        LiuYaoRole.yuanShen => '生用神者为元神',
        LiuYaoRole.jiShen => '克用神者为忌神',
        LiuYaoRole.chouShen => '克元神并生忌神者为仇神',
        LiuYaoRole.xianShen => isHiddenActor ? '不属用、元、忌、仇的伏神' : '不属用、元、忌、仇的本卦爻',
      };

  /// 同六亲多爻：动爻优先，其次低爻位
  static int? _findPosition(Gua gua, LiuQin liuQin, int excludePosition) {
    Yao? found;
    for (final yao in gua.yaos) {
      if (yao.position == excludePosition || yao.liuQin != liuQin) continue;
      if (yao.isMoving) return yao.position;
      found ??= yao;
    }
    return found?.position;
  }
}
