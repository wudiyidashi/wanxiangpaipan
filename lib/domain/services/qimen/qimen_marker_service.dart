import '../shared/tiangan_dizhi_service.dart';
import 'qimen_constants.dart';

class QimenMarkerFacts {
  const QimenMarkerFacts({
    required this.kongWangBranches,
    required this.voidByPalace,
    required this.horseBranch,
    required this.horsePalace,
  });

  final List<String> kongWangBranches;
  final Map<int, List<String>> voidByPalace;
  final String horseBranch;
  final int horsePalace;
}

class QimenMarkerService {
  QimenMarkerService._();

  static QimenMarkerFacts resolve(String hourGanZhi) {
    final kongWang = TianGanDiZhiService.getKongWang(hourGanZhi);
    final voidByPalace = <int, List<String>>{};
    for (final entry in QimenConstants.palaceMeta.entries) {
      final matches =
          entry.value.branches.where(kongWang.contains).toList(growable: false);
      voidByPalace[entry.key] = matches;
    }
    final hourBranch = hourGanZhi.substring(1);
    final horseBranch = switch (hourBranch) {
      '申' || '子' || '辰' => '寅',
      '寅' || '午' || '戌' => '申',
      '巳' || '酉' || '丑' => '亥',
      '亥' || '卯' || '未' => '巳',
      _ => throw ArgumentError('非法时支: $hourBranch'),
    };
    final horsePalace = QimenConstants.palaceMeta.entries
        .singleWhere((entry) => entry.value.branches.contains(horseBranch))
        .key;
    return QimenMarkerFacts(
      kongWangBranches: List<String>.unmodifiable(kongWang),
      voidByPalace: Map<int, List<String>>.unmodifiable(voidByPalace),
      horseBranch: horseBranch,
      horsePalace: horsePalace,
    );
  }
}
