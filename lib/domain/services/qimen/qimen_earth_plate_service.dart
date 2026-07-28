import '../../../divination_systems/qimen/models/qimen_enums.dart';
import 'qimen_constants.dart';

class QimenEarthPlate {
  const QimenEarthPlate({
    required this.stems,
    required this.hostedStems,
    required this.hostingPalace,
  });

  final Map<int, String> stems;
  final Map<int, String> hostedStems;
  final int hostingPalace;

  int palaceOf(String stem, {bool effective = true}) {
    final main =
        stems.entries.where((entry) => entry.value == stem).firstOrNull;
    if (main == null) throw StateError('地盘未找到天干: $stem');
    if (effective && main.key == 5) return hostingPalace;
    return main.key;
  }
}

class QimenEarthPlateService {
  QimenEarthPlateService._();

  static QimenEarthPlate arrange({
    required QimenDun dun,
    required int juNumber,
    required QimenHostingMode hostingMode,
  }) {
    if (juNumber < 1 || juNumber > 9) {
      throw ArgumentError('奇门局数必须在 1..9');
    }
    final stems = <int, String>{};
    for (var index = 0; index < QimenConstants.qiYi.length; index++) {
      final palace = QimenConstants.moveFlying(juNumber, index, dun);
      stems[palace] = QimenConstants.qiYi[index];
    }
    if (stems.length != 9) throw StateError('地盘三奇六仪未覆盖九宫');
    final host = QimenConstants.hostingPalace(hostingMode, dun);
    return QimenEarthPlate(
      stems: Map<int, String>.unmodifiable(stems),
      hostedStems: <int, String>{host: stems[5]!},
      hostingPalace: host,
    );
  }
}
