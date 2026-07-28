import '../../../divination_systems/qimen/models/qimen_ju_info.dart';
import '../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../divination_systems/qimen/models/qimen_pan_params.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';
import 'qimen_constants.dart';
import 'qimen_deity_service.dart';
import 'qimen_door_service.dart';
import 'qimen_duty_service.dart';
import 'qimen_earth_plate_service.dart';
import 'qimen_heaven_plate_service.dart';
import 'qimen_hidden_stem_service.dart';
import 'qimen_marker_service.dart';

class QimenPanData {
  const QimenPanData({
    required this.palaces,
    required this.duty,
    required this.markers,
    required this.derivationSteps,
  });

  final List<QimenPalace> palaces;
  final QimenDutyFacts duty;
  final QimenMarkerFacts markers;
  final List<String> derivationSteps;
}

class QimenPanService {
  QimenPanService._();

  static QimenPanData arrange({
    required QimenTemporalContext temporalContext,
    required QimenJuInfo juInfo,
    required QimenPanParams params,
  }) {
    final earthPlate = QimenEarthPlateService.arrange(
      dun: juInfo.dun,
      juNumber: juInfo.juNumber,
      hostingMode: params.hostingMode,
    );
    final duty = QimenDutyService.resolve(
      hourGanZhi: temporalContext.hourGanZhi,
      dun: juInfo.dun,
      earthPlate: earthPlate,
    );
    final heavenPlate = QimenHeavenPlateService.arrange(
      earthPlate: earthPlate,
      duty: duty,
    );
    final doors = QimenDoorService.arrange(
      earthPlate: earthPlate,
      duty: duty,
    );
    final deities = QimenDeityService.arrange(
      dun: juInfo.dun,
      zhiFuPalace: duty.zhiFuPalace,
    );
    final hiddenStems = QimenHiddenStemService.arrange(
      mode: params.hiddenStemMode,
      dun: juInfo.dun,
      hourGanZhi: temporalContext.hourGanZhi,
      duty: duty,
      earthPlate: earthPlate,
      doors: doors,
    );
    final markers = QimenMarkerService.resolve(temporalContext.hourGanZhi);

    final palaces = <QimenPalace>[];
    for (var number = 1; number <= 9; number++) {
      final meta = QimenConstants.palaceMeta[number]!;
      final voidBranches = markers.voidByPalace[number]!;
      final marks = <String>[
        if (number == 5) '中宫',
        if (earthPlate.hostedStems.containsKey(number)) '地盘寄宫',
        if (heavenPlate.hostedStars.containsKey(number)) '天禽寄宫',
        if (voidBranches.isNotEmpty) '空亡',
        if (markers.horsePalace == number) '驿马',
      ];
      palaces.add(QimenPalace(
        number: number,
        name: meta.name,
        trigram: meta.trigram,
        direction: meta.direction,
        element: meta.element,
        branches: meta.branches,
        earthStem: earthPlate.stems[number]!,
        hostedEarthStem: earthPlate.hostedStems[number],
        heavenStem: heavenPlate.stems[number]!,
        hostedHeavenStem: heavenPlate.hostedStems[number],
        star: heavenPlate.stars[number]!,
        hostedStar: heavenPlate.hostedStars[number],
        door: doors[number],
        deity: deities[number],
        hiddenStem: hiddenStems[number],
        voidBranches: voidBranches,
        isHorse: markers.horsePalace == number,
        marks: marks,
      ));
    }
    _assertComplete(palaces);

    return QimenPanData(
      palaces: List<QimenPalace>.unmodifiable(palaces),
      duty: duty,
      markers: markers,
      derivationSteps: <String>[
        '${juInfo.dun.label}遁${juInfo.juNumber}局排地盘三奇六仪',
        '中五寄${earthPlate.hostingPalace}宫（${params.hostingMode.id}）',
        '${duty.xunShou}旬遁${duty.xunHiddenStem}，'
            '${duty.zhiFuStar}值符落${duty.zhiFuPalace}宫',
        '${duty.zhiShiDoor}值使落${duty.zhiShiPalace}宫',
        '暗干口径：${params.hiddenStemMode.id}',
        '旬空${markers.kongWangBranches.join()}，'
            '驿马${markers.horseBranch}落${markers.horsePalace}宫',
      ],
    );
  }

  static void _assertComplete(List<QimenPalace> palaces) {
    if (palaces.length != 9 ||
        palaces.map((palace) => palace.number).toSet().length != 9) {
      throw StateError('奇门九宫编号不完整');
    }
    if (palaces.where((palace) => palace.door != null).length != 8 ||
        palaces.where((palace) => palace.deity != null).length != 8) {
      throw StateError('奇门八门或八神排布不完整');
    }
    if (palaces.any((palace) =>
        palace.earthStem.isEmpty ||
        palace.heavenStem.isEmpty ||
        palace.star.isEmpty)) {
      throw StateError('奇门九宫必需槽位存在空值');
    }
  }
}
