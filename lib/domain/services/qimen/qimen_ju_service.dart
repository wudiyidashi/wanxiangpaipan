import '../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../divination_systems/qimen/models/qimen_ju_info.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';
import 'chai_bu_ju_strategy.dart';
import 'mao_shan_ju_strategy.dart';
import 'qimen_ju_strategy.dart';
import 'zhi_run_ju_strategy.dart';

class QimenJuService {
  QimenJuService._();

  static QimenJuInfo resolve(
    QimenJuMethod method,
    QimenTemporalContext context,
  ) {
    final QimenJuStrategy strategy = switch (method) {
      QimenJuMethod.chaiBu => const ChaiBuJuStrategy(),
      QimenJuMethod.maoShan => const MaoShanJuStrategy(),
      QimenJuMethod.zhiRun => const ZhiRunJuStrategy(),
      QimenJuMethod.manual => throw ArgumentError('manual 定局必须显式提供局数事实'),
    };
    return strategy.resolve(context);
  }

  static QimenJuInfo manual({
    required QimenDun dun,
    required int juNumber,
    required QimenYuan yuan,
    required String solarTerm,
  }) {
    if (juNumber < 1 || juNumber > 9) {
      throw ArgumentError('手动局数必须在 1..9');
    }
    return QimenJuInfo(
      method: QimenJuMethod.manual,
      dun: dun,
      juNumber: juNumber,
      yuan: yuan,
      solarTerm: solarTerm,
      effectiveSolarTerm: solarTerm,
      derivation: <String>[
        '手动校盘：${dun.label}遁$juNumber局、${yuan.label}、$solarTerm',
      ],
    );
  }
}
