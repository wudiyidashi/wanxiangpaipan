import '../../../divination_systems/qimen/models/qimen_enums.dart';
import '../shared/tiangan_dizhi_service.dart';
import 'qimen_constants.dart';
import 'qimen_earth_plate_service.dart';

class QimenDutyFacts {
  const QimenDutyFacts({
    required this.xunShou,
    required this.xunHiddenStem,
    required this.dutyOriginPalace,
    required this.dutyEffectiveOriginPalace,
    required this.zhiFuStar,
    required this.zhiFuPalace,
    required this.zhiShiDoor,
    required this.zhiShiPalace,
  });

  final String xunShou;
  final String xunHiddenStem;
  final int dutyOriginPalace;
  final int dutyEffectiveOriginPalace;
  final String zhiFuStar;
  final int zhiFuPalace;
  final String zhiShiDoor;
  final int zhiShiPalace;
}

class QimenDutyService {
  QimenDutyService._();

  static QimenDutyFacts resolve({
    required String hourGanZhi,
    required QimenDun dun,
    required QimenEarthPlate earthPlate,
  }) {
    final hourIndex = TianGanDiZhiService.getGanZhiIndex(hourGanZhi);
    if (hourIndex < 0) throw ArgumentError('非法时柱: $hourGanZhi');
    final xunIndex = hourIndex ~/ 10 * 10;
    final xunShou = TianGanDiZhiService.getGanZhi(xunIndex);
    final hiddenStem = QimenConstants.xunHiddenStem[xunShou];
    if (hiddenStem == null) throw StateError('旬首遁仪缺失: $xunShou');

    final origin = earthPlate.palaceOf(hiddenStem, effective: false);
    final effectiveOrigin = origin == 5 ? earthPlate.hostingPalace : origin;
    final hourStem = hourGanZhi.substring(0, 1) == '甲'
        ? hiddenStem
        : hourGanZhi.substring(0, 1);
    final target = earthPlate.palaceOf(hourStem);
    final dutyDoorOrigin = origin == 5 ? earthPlate.hostingPalace : origin;
    final dutyDoor = QimenConstants.doorsByOrigin[dutyDoorOrigin];
    if (dutyDoor == null) throw StateError('值使门本位缺失: $dutyDoorOrigin');

    final xunBranchIndex =
        TianGanDiZhiService.getDiZhiIndex(xunShou.substring(1));
    final hourBranchIndex =
        TianGanDiZhiService.getDiZhiIndex(hourGanZhi.substring(1));
    final steps = (hourBranchIndex - xunBranchIndex) % 12;
    var zhiShiPalace = QimenConstants.moveFlying(origin, steps, dun);
    if (zhiShiPalace == 5) zhiShiPalace = earthPlate.hostingPalace;

    return QimenDutyFacts(
      xunShou: xunShou,
      xunHiddenStem: hiddenStem,
      dutyOriginPalace: origin,
      dutyEffectiveOriginPalace: effectiveOrigin,
      zhiFuStar: QimenConstants.starsByOrigin[origin]!,
      zhiFuPalace: target,
      zhiShiDoor: dutyDoor,
      zhiShiPalace: zhiShiPalace,
    );
  }
}
