import '../../../divination_systems/qimen/models/qimen_enums.dart';
import 'qimen_constants.dart';
import 'qimen_duty_service.dart';
import 'qimen_earth_plate_service.dart';

class QimenHiddenStemService {
  QimenHiddenStemService._();

  static Map<int, String?> arrange({
    required QimenHiddenStemMode mode,
    required QimenDun dun,
    required String hourGanZhi,
    required QimenDutyFacts duty,
    required QimenEarthPlate earthPlate,
    required Map<int, String> doors,
  }) {
    if (mode == QimenHiddenStemMode.doorOriginEarthStem) {
      return Map<int, String?>.unmodifiable(<int, String?>{
        for (var palace = 1; palace <= 9; palace++)
          palace: _doorOriginStem(doors[palace], earthPlate),
      });
    }

    final rawHourStem = hourGanZhi.substring(0, 1);
    final startStem = rawHourStem == '甲' ? duty.xunHiddenStem : rawHourStem;
    final startIndex = QimenConstants.qiYi.indexOf(startStem);
    if (startIndex < 0) throw StateError('时干无法进入暗干序列: $startStem');
    final result = <int, String?>{};
    for (var index = 0; index < 9; index++) {
      final palace = QimenConstants.moveFlying(duty.zhiShiPalace, index, dun);
      result[palace] = QimenConstants.qiYi[(startIndex + index) % 9];
    }
    return Map<int, String?>.unmodifiable(result);
  }

  static String? _doorOriginStem(
    String? door,
    QimenEarthPlate earthPlate,
  ) {
    if (door == null) return null;
    final origin = QimenConstants.doorsByOrigin.entries
        .singleWhere((entry) => entry.value == door)
        .key;
    return earthPlate.stems[origin];
  }
}
