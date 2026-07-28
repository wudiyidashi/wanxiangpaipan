import '../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../divination_systems/qimen/models/qimen_ju_info.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';
import '../shared/tiangan_dizhi_service.dart';
import 'qimen_constants.dart';
import 'qimen_ju_strategy.dart';

class ChaiBuJuStrategy implements QimenJuStrategy {
  const ChaiBuJuStrategy();

  @override
  QimenJuInfo resolve(QimenTemporalContext context) {
    final dayIndex = TianGanDiZhiService.getGanZhiIndex(context.dayGanZhi);
    if (dayIndex < 0) throw ArgumentError('非法日柱: ${context.dayGanZhi}');
    final symbolHead = TianGanDiZhiService.getGanZhi(dayIndex - dayIndex % 5);
    final yuan = _yuanForSymbolHead(symbolHead.substring(1));
    final dun = QimenConstants.dunForSolarTerm(context.currentSolarTerm);

    return QimenJuInfo(
      method: QimenJuMethod.chaiBu,
      dun: dun,
      juNumber: QimenConstants.juFor(context.currentSolarTerm, yuan),
      yuan: yuan,
      solarTerm: context.currentSolarTerm,
      effectiveSolarTerm: context.currentSolarTerm,
      symbolHead: symbolHead,
      derivation: <String>[
        '日柱${context.dayGanZhi}回退${dayIndex % 5}日至符头$symbolHead',
        '符头支${symbolHead.substring(1)}定${yuan.label}',
        '精确交节后采用${context.currentSolarTerm}${dun.label}遁局数表',
      ],
    );
  }

  static QimenYuan _yuanForSymbolHead(String branch) {
    if ('子午卯酉'.contains(branch)) return QimenYuan.upper;
    if ('寅申巳亥'.contains(branch)) return QimenYuan.middle;
    if ('辰戌丑未'.contains(branch)) return QimenYuan.lower;
    throw ArgumentError('非法符头地支: $branch');
  }
}
