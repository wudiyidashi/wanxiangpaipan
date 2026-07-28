import '../../../divination_systems/qimen/models/qimen_enums.dart';
import 'qimen_constants.dart';

class QimenDeityService {
  QimenDeityService._();

  static Map<int, String> arrange({
    required QimenDun dun,
    required int zhiFuPalace,
  }) {
    final outer = QimenConstants.outerPalaces;
    final start = outer.indexOf(zhiFuPalace);
    if (start < 0) throw StateError('值符落宫不在外八宫');
    final direction = dun == QimenDun.yang ? 1 : -1;
    final result = <int, String>{};
    for (var index = 0; index < outer.length; index++) {
      final targetIndex = (start + direction * index) % outer.length;
      result[outer[targetIndex]] = QimenConstants.deities[index];
    }
    return Map<int, String>.unmodifiable(result);
  }
}
