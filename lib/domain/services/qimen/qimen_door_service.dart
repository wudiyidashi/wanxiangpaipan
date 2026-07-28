import 'qimen_constants.dart';
import 'qimen_duty_service.dart';
import 'qimen_earth_plate_service.dart';

class QimenDoorService {
  QimenDoorService._();

  static Map<int, String> arrange({
    required QimenEarthPlate earthPlate,
    required QimenDutyFacts duty,
  }) {
    final outer = QimenConstants.outerPalaces;
    final sourceStart = outer.indexOf(duty.dutyEffectiveOriginPalace);
    final targetStart = outer.indexOf(duty.zhiShiPalace);
    if (sourceStart < 0 || targetStart < 0) {
      throw StateError('值使转盘起止宫不在外八宫');
    }
    final rotation = (targetStart - sourceStart) % outer.length;
    final doors = <int, String>{};
    for (var targetIndex = 0; targetIndex < outer.length; targetIndex++) {
      final sourceIndex =
          (targetIndex - rotation + outer.length) % outer.length;
      final sourcePalace = outer[sourceIndex];
      final targetPalace = outer[targetIndex];
      doors[targetPalace] = QimenConstants.doorsByOrigin[sourcePalace]!;
    }
    return Map<int, String>.unmodifiable(doors);
  }
}
