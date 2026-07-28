import '../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../divination_systems/qimen/models/qimen_ju_info.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';
import 'qimen_constants.dart';
import 'qimen_ju_strategy.dart';

class MaoShanJuStrategy implements QimenJuStrategy {
  const MaoShanJuStrategy();

  @override
  QimenJuInfo resolve(QimenTemporalContext context) {
    final start = _doubleHourStart(context.currentSolarTermTime);
    final elapsed = context.effectivePanTime.difference(start);
    if (elapsed.isNegative) {
      throw StateError('茅山法生效时间早于交节时辰起点');
    }
    final yuan = elapsed < const Duration(hours: 120)
        ? QimenYuan.upper
        : elapsed < const Duration(hours: 240)
            ? QimenYuan.middle
            : QimenYuan.lower;
    final dun = QimenConstants.dunForSolarTerm(context.currentSolarTerm);

    return QimenJuInfo(
      method: QimenJuMethod.maoShan,
      dun: dun,
      juNumber: QimenConstants.juFor(context.currentSolarTerm, yuan),
      yuan: yuan,
      solarTerm: context.currentSolarTerm,
      effectiveSolarTerm: context.currentSolarTerm,
      derivation: <String>[
        '${context.currentSolarTerm}交节所在时辰起点${start.toIso8601String()}',
        '累计${elapsed.inHours}小时，归入${yuan.label}',
      ],
    );
  }

  static DateTime _doubleHourStart(DateTime time) {
    if (time.hour == 0) {
      final previous = time.subtract(const Duration(days: 1));
      return DateTime.utc(previous.year, previous.month, previous.day, 23);
    }
    final hour = time.hour.isOdd ? time.hour : time.hour - 1;
    return DateTime.utc(time.year, time.month, time.day, hour);
  }
}
