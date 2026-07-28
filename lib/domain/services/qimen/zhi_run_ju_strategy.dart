import 'package:lunar/lunar.dart';

import '../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../divination_systems/qimen/models/qimen_ju_info.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';
import '../shared/tiangan_dizhi_service.dart';
import 'qimen_constants.dart';
import 'qimen_ju_strategy.dart';

class ZhiRunJuStrategy implements QimenJuStrategy {
  const ZhiRunJuStrategy();

  static const Set<String> _upperHeads = <String>{
    '甲子',
    '己卯',
    '甲午',
    '己酉',
  };

  @override
  QimenJuInfo resolve(QimenTemporalContext context) {
    final effectiveTime = context.effectivePanTime;
    final eligible = _eligibleTermForCycle(context);
    final eligibleHead = _latestUpperHead(
      eligible.time,
      context.dayBoundary,
    );
    final eligibleChaoDays = eligible.time.difference(eligibleHead.time).inDays;
    final firstCycleStart = eligibleHead.time;
    final leapStart = eligibleHead.time.add(const Duration(days: 15));
    final leapEnd = leapStart.add(const Duration(days: 15));
    final hasLeap = eligibleChaoDays > 9;
    final usesEligibleCycle = hasLeap &&
        !effectiveTime.isBefore(firstCycleStart) &&
        effectiveTime.isBefore(leapEnd);
    final isLeap = usesEligibleCycle && !effectiveTime.isBefore(leapStart);
    final effectiveTerm =
        usesEligibleCycle ? eligible.name : context.currentSolarTerm;

    final cycleHead = usesEligibleCycle
        ? eligibleHead
        : _latestUpperHead(effectiveTime, context.dayBoundary);
    final cycleStart = isLeap ? leapStart : cycleHead.time;
    final cycleDays = effectiveTime.difference(cycleStart).inDays;
    if (cycleDays < 0) {
      throw StateError('置闰周期推导失败：生效时间早于周期起点');
    }
    final yuan = QimenYuan.values[(cycleDays ~/ 5).clamp(0, 2)];
    final dun = QimenConstants.dunForSolarTerm(effectiveTerm);
    final symbolHead = _latestFiveDayHead(
      effectiveTime,
      context.dayBoundary,
    ).ganZhi;

    final relationTerm = usesEligibleCycle
        ? eligible
        : _EligibleTerm(
            name: context.currentSolarTerm,
            time: context.currentSolarTermTime,
          );
    final relationHead = usesEligibleCycle ? eligibleHead : cycleHead;
    final isReceivingQi =
        !usesEligibleCycle && relationHead.time.isAfter(relationTerm.time);
    final receivingDays = isReceivingQi
        ? relationHead.time.difference(relationTerm.time).inDays
        : 0;
    final chaoShenDays = isReceivingQi
        ? 0
        : relationTerm.time.difference(relationHead.time).inDays;

    return QimenJuInfo(
      method: QimenJuMethod.zhiRun,
      dun: dun,
      juNumber: QimenConstants.juFor(effectiveTerm, yuan),
      yuan: yuan,
      solarTerm: context.currentSolarTerm,
      effectiveSolarTerm: effectiveTerm,
      symbolHead: symbolHead,
      chaoShenDays: chaoShenDays,
      isReceivingQi: isReceivingQi,
      isLeap: isLeap,
      derivation: <String>[
        if (isReceivingQi)
          '${relationHead.ganZhi}符头晚于${relationTerm.name}交节完整'
              '$receivingDays日（接气）'
        else
          '${relationTerm.name}交节距${relationHead.ganZhi}符头完整'
              '$chaoShenDays日（超神）',
        '${eligible.name}交节距${eligibleHead.ganZhi}符头完整超神'
            '$eligibleChaoDays日，${hasLeap ? '满足' : '不满足'}九日置闰门槛',
        if (usesEligibleCycle && !isLeap)
          '首轮超神周期${firstCycleStart.toIso8601String()}'
              '至${leapStart.toIso8601String()}沿用${eligible.name}',
        if (isLeap)
          '闰周期${leapStart.toIso8601String()}至${leapEnd.toIso8601String()}重复${eligible.name}',
        '当前五日符头$symbolHead，周期第$cycleDays日归入${yuan.label}',
      ],
    );
  }

  static _UpperHead _latestUpperHead(
    DateTime time,
    QimenDayBoundary dayBoundary,
  ) {
    final head = _latestCycleHead(time, dayBoundary, 15);
    if (!_upperHeads.contains(head.ganZhi)) {
      throw StateError('置闰上元符头不合法: ${head.ganZhi}');
    }
    return head;
  }

  static _UpperHead _latestFiveDayHead(
    DateTime time,
    QimenDayBoundary dayBoundary,
  ) =>
      _latestCycleHead(time, dayBoundary, 5);

  static _UpperHead _latestCycleHead(
    DateTime time,
    QimenDayBoundary dayBoundary,
    int cycleDays,
  ) {
    final lunar = Solar.fromDate(time).getLunar();
    final dayGanZhi = dayBoundary == QimenDayBoundary.ziInitial
        ? lunar.getDayInGanZhiExact()
        : lunar.getDayInGanZhiExact2();
    final dayIndex = TianGanDiZhiService.getGanZhiIndex(dayGanZhi);
    if (dayIndex < 0) throw StateError('日干支不合法: $dayGanZhi');

    final midnight = time.isUtc
        ? DateTime.utc(time.year, time.month, time.day)
        : DateTime(time.year, time.month, time.day);
    final effectiveDayStart = dayBoundary == QimenDayBoundary.midnight
        ? midnight
        : time.hour >= 23
            ? midnight.add(const Duration(hours: 23))
            : midnight.subtract(const Duration(hours: 1));
    final offset = dayIndex % cycleDays;
    return _UpperHead(
      ganZhi: TianGanDiZhiService.getGanZhi(dayIndex - offset),
      time: effectiveDayStart.subtract(Duration(days: offset)),
    );
  }

  static _EligibleTerm _eligibleTermForCycle(
    QimenTemporalContext context,
  ) {
    if (_isEligibleTerm(context.currentSolarTerm)) {
      return _EligibleTerm(
        name: context.currentSolarTerm,
        time: context.currentSolarTermTime,
      );
    }
    if (_isEligibleTerm(context.nextSolarTerm)) {
      return _EligibleTerm(
        name: context.nextSolarTerm,
        time: context.nextSolarTermTime,
      );
    }
    if (_isEligibleTerm(context.previousSolarTerm)) {
      return _EligibleTerm(
        name: context.previousSolarTerm,
        time: context.previousSolarTermTime,
      );
    }
    return _latestEligibleTerm(context.effectivePanTime);
  }

  static bool _isEligibleTerm(String name) => name == '芒种' || name == '大雪';

  static _EligibleTerm _latestEligibleTerm(DateTime time) {
    final table = Solar.fromDate(time).getLunar().getJieQiTable();
    _EligibleTerm? latest;
    for (final entry in table.entries) {
      final name = entry.key == 'DA_XUE' ? '大雪' : entry.key;
      if (name != '芒种' && name != '大雪') continue;
      final solar = entry.value;
      final termTime = DateTime.utc(
        solar.getYear(),
        solar.getMonth(),
        solar.getDay(),
        solar.getHour(),
        solar.getMinute(),
        solar.getSecond(),
      );
      if (termTime.isAfter(time)) continue;
      if (latest == null || termTime.isAfter(latest.time)) {
        latest = _EligibleTerm(name: name, time: termTime);
      }
    }
    if (latest == null) {
      throw StateError('无法定位芒种或大雪置闰锚点');
    }
    return latest;
  }
}

class _UpperHead {
  const _UpperHead({required this.ganZhi, required this.time});
  final String ganZhi;
  final DateTime time;
}

class _EligibleTerm {
  const _EligibleTerm({required this.name, required this.time});
  final String name;
  final DateTime time;
}
