import 'qimen_constants.dart';
import 'qimen_duty_service.dart';
import 'qimen_earth_plate_service.dart';

class QimenHeavenPlate {
  const QimenHeavenPlate({
    required this.stems,
    required this.hostedStems,
    required this.stars,
    required this.hostedStars,
  });

  final Map<int, String> stems;
  final Map<int, String> hostedStems;
  final Map<int, String> stars;
  final Map<int, String> hostedStars;
}

class QimenHeavenPlateService {
  QimenHeavenPlateService._();

  static QimenHeavenPlate arrange({
    required QimenEarthPlate earthPlate,
    required QimenDutyFacts duty,
  }) {
    final outer = QimenConstants.outerPalaces;
    final stemSourceStart = outer.indexOf(duty.dutyEffectiveOriginPalace);
    final starOriginPalace =
        duty.dutyOriginPalace == 5 ? 2 : duty.dutyOriginPalace;
    final starSourceStart = outer.indexOf(starOriginPalace);
    final targetStart = outer.indexOf(duty.zhiFuPalace);
    if (stemSourceStart < 0 || starSourceStart < 0 || targetStart < 0) {
      throw StateError('值符转盘起止宫不在外八宫');
    }
    final stemRotation = (targetStart - stemSourceStart) % outer.length;
    final starRotation = (targetStart - starSourceStart) % outer.length;
    final stems = <int, String>{5: earthPlate.stems[5]!};
    final stars = <int, String>{5: QimenConstants.starsByOrigin[5]!};
    final hostedStems = <int, String>{};
    final hostedStars = <int, String>{};

    for (var targetIndex = 0; targetIndex < outer.length; targetIndex++) {
      final targetPalace = outer[targetIndex];
      final stemSourcePalace =
          outer[(targetIndex - stemRotation + outer.length) % outer.length];
      final starSourcePalace =
          outer[(targetIndex - starRotation + outer.length) % outer.length];
      stems[targetPalace] = earthPlate.stems[stemSourcePalace]!;
      stars[targetPalace] = QimenConstants.starsByOrigin[starSourcePalace]!;
      if (stemSourcePalace == earthPlate.hostingPalace) {
        hostedStems[targetPalace] = earthPlate.stems[5]!;
      }
      if (starSourcePalace == 2) {
        hostedStars[targetPalace] = QimenConstants.starsByOrigin[5]!;
      }
    }
    return QimenHeavenPlate(
      stems: Map<int, String>.unmodifiable(stems),
      hostedStems: Map<int, String>.unmodifiable(hostedStems),
      stars: Map<int, String>.unmodifiable(stars),
      hostedStars: Map<int, String>.unmodifiable(hostedStars),
    );
  }
}
