import 'dart:collection';

import '../daliuren_constants.dart';

/// Validates the complete earth-plate to heaven-plate mapping used by DLR.
class TianPanMapContract {
  TianPanMapContract._();

  /// Returns an immutable defensive snapshot after proving that [tianPanMap]
  /// is one of the twelve fixed cyclic rotations of the earthly branches.
  static Map<String, String> validate(
    Map<String, String> tianPanMap, {
    String parameterName = 'tianPanMap',
  }) {
    const branches = DaLiuRenConstants.diZhi;
    final expected = branches.toSet();

    if (tianPanMap.length != branches.length) {
      throw ArgumentError.value(
        tianPanMap,
        parameterName,
        '天盘必须恰有十二宫',
      );
    }
    if (!_setsEqual(tianPanMap.keys.toSet(), expected)) {
      throw ArgumentError.value(
        tianPanMap,
        parameterName,
        '天盘键必须恰为十二地支全集',
      );
    }
    if (!_setsEqual(tianPanMap.values.toSet(), expected)) {
      throw ArgumentError.value(
        tianPanMap,
        parameterName,
        '天盘值必须恰为互不重复的十二地支全集',
      );
    }

    final firstValueIndex = branches.indexOf(tianPanMap[branches.first]!);
    for (var index = 0; index < branches.length; index++) {
      final expectedValue =
          branches[(index + firstValueIndex) % branches.length];
      if (tianPanMap[branches[index]] != expectedValue) {
        throw ArgumentError.value(
          tianPanMap,
          parameterName,
          '天盘十二宫必须保持同一固定循环位移',
        );
      }
    }

    return UnmodifiableMapView<String, String>(
      Map<String, String>.from(tianPanMap),
    );
  }

  /// Validates the complete plate together with its month-general anchor.
  static Map<String, String> validateAnchoredMap({
    required String yueJiang,
    required String shiZhi,
    required Map<String, String> tianPanMap,
  }) {
    validateBranch(yueJiang, 'yueJiang');
    validateBranch(shiZhi, 'shiZhi');
    final validatedMap = validate(tianPanMap);
    if (validatedMap[shiZhi] != yueJiang) {
      throw ArgumentError.value(
        tianPanMap,
        'tianPanMap',
        '月将必须加临时支，即 tianPanMap[shiZhi] == yueJiang',
      );
    }
    return validatedMap;
  }

  static void validateBranch(String branch, String parameterName) {
    if (!DaLiuRenConstants.diZhi.contains(branch)) {
      throw ArgumentError.value(branch, parameterName, '必须是合法地支');
    }
  }

  static bool _setsEqual(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}
