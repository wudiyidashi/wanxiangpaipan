import '../../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../../divination_systems/qimen/models/qimen_result.dart';
import '../../shared/tiangan_dizhi_service.dart';
import '../qimen_constants.dart';
import 'models/qimen_analysis_models.dart';
import 'models/qimen_rule_models.dart';
import 'rules/qimen_rule_catalog.dart';

class QimenInputGuardResult {
  const QimenInputGuardResult({
    required this.status,
    required this.diagnostics,
  });

  final QimenAnalysisStatus status;
  final List<QimenAnalysisDiagnostic> diagnostics;

  bool get isValid => status == QimenAnalysisStatus.complete;
}

class QimenAnalysisInputGuard {
  QimenAnalysisInputGuard._();

  static const Set<String> _stars = <String>{
    '天蓬',
    '天芮',
    '天冲',
    '天辅',
    '天禽',
    '天心',
    '天柱',
    '天任',
    '天英',
  };
  static const Set<String> _doors = <String>{
    '休门',
    '生门',
    '伤门',
    '杜门',
    '景门',
    '死门',
    '惊门',
    '开门',
  };
  static const Set<String> _deities = <String>{
    '值符',
    '螣蛇',
    '太阴',
    '六合',
    '白虎',
    '玄武',
    '九地',
    '九天',
  };
  static QimenInputGuardResult unsupportedSchema({
    required Object? schemaVersion,
  }) =>
      QimenInputGuardResult(
        status: QimenAnalysisStatus.unsupportedPanSchema,
        diagnostics: <QimenAnalysisDiagnostic>[
          QimenAnalysisDiagnostic(
            code: 'QMV1-E-UNSUPPORTED-PAN-SCHEMA',
            path: r'$.schemaVersion',
            message: 'unsupported pan schema $schemaVersion; supported: '
                '${QimenResult.currentSchemaVersion}',
          ),
        ],
      );

  static QimenInputGuardResult validate(QimenResult result) {
    final diagnostics = <QimenAnalysisDiagnostic>[];

    void invalid(String code, String path, String message) {
      diagnostics.add(QimenAnalysisDiagnostic(
        code: code,
        path: path,
        message: message,
      ));
    }

    if (result.id.isEmpty) {
      invalid('QMV1-E-EMPTY-RESULT-ID', r'$.id', 'result ID is empty');
    }
    if (!TianGanDiZhiService.isValidGanZhi(
      result.temporalContext.monthGanZhi,
    )) {
      invalid(
        'QMV1-E-INVALID-MONTH-PILLAR',
        r'$.temporalContext.monthGanZhi',
        'month pillar is not a valid sexagenary pair',
      );
    }
    if (!TianGanDiZhiService.isValidGanZhi(
      result.temporalContext.dayGanZhi,
    )) {
      invalid(
        'QMV1-E-INVALID-DAY-PILLAR',
        r'$.temporalContext.dayGanZhi',
        'day pillar is not a valid sexagenary pair',
      );
    }
    if (!TianGanDiZhiService.isValidGanZhi(
      result.temporalContext.hourGanZhi,
    )) {
      invalid(
        'QMV1-E-INVALID-HOUR-PILLAR',
        r'$.temporalContext.hourGanZhi',
        'hour pillar is not a valid sexagenary pair',
      );
    }
    if (result.palaces.length != 9 ||
        result.palaces.map((palace) => palace.number).toSet().length != 9 ||
        !result.palaces
            .map((palace) => palace.number)
            .toSet()
            .containsAll(const <int>{1, 2, 3, 4, 5, 6, 7, 8, 9})) {
      invalid(
        'QMV1-E-INCOMPLETE-PALACES',
        r'$.palaces',
        'palaces must contain each number from 1 through 9 exactly once',
      );
    } else {
      final palaces = [...result.palaces]
        ..sort((left, right) => left.number.compareTo(right.number));
      final center = palaces.singleWhere((palace) => palace.number == 5);
      for (final palace in palaces) {
        final path = '\$.palaces[number=${palace.number}]';
        final expectedMeta = QimenConstants.palaceMeta[palace.number]!;
        if (palace.name.isEmpty ||
            palace.trigram.isEmpty ||
            palace.direction.isEmpty ||
            palace.element.isEmpty ||
            palace.earthStem.isEmpty ||
            palace.heavenStem.isEmpty ||
            palace.star.isEmpty) {
          invalid(
            'QMV1-E-MISSING-PALACE-FACT',
            path,
            'palace ${palace.number} has an empty required fact',
          );
        }
        if (palace.name != expectedMeta.name) {
          invalid(
            'QMV1-E-PALACE-NAME',
            '$path.name',
            'palace ${palace.number} name ${palace.name} does not match '
                'the frozen palace name ${expectedMeta.name}',
          );
        }
        if (palace.trigram != expectedMeta.trigram) {
          invalid(
            'QMV1-E-PALACE-TRIGRAM',
            '$path.trigram',
            'palace ${palace.number} trigram ${palace.trigram} does not match '
                'the frozen trigram ${expectedMeta.trigram}',
          );
        }
        if (palace.direction != expectedMeta.direction) {
          invalid(
            'QMV1-E-PALACE-DIRECTION',
            '$path.direction',
            'palace ${palace.number} direction ${palace.direction} does not '
                'match the frozen direction ${expectedMeta.direction}',
          );
        }
        if (palace.element != expectedMeta.element) {
          invalid(
            'QMV1-E-PALACE-ELEMENT',
            '$path.element',
            'palace ${palace.number} element ${palace.element} does not match '
                'the frozen palace element ${expectedMeta.element}',
          );
        }
        if (!_sameValues(palace.branches, expectedMeta.branches)) {
          invalid(
            'QMV1-E-PALACE-BRANCHES',
            '$path.branches',
            'palace ${palace.number} branches do not match frozen metadata',
          );
        }
        if (palace.number == 5) {
          if (palace.door != null || palace.deity != null) {
            invalid(
              'QMV1-E-CENTER-OUTER-FIELD',
              path,
              'center palace must not contain a door or deity',
            );
          }
        } else if (palace.door == null ||
            palace.deity == null ||
            palace.branches.isEmpty) {
          invalid(
            'QMV1-E-MISSING-OUTER-FIELD',
            path,
            'outer palace lacks a door, deity, or branch',
          );
        }
        if (palace.hiddenStem != null &&
            !QimenRuleCatalog.qiYi.contains(palace.hiddenStem)) {
          invalid(
            'QMV1-E-INVALID-HIDDEN-STEM',
            '$path.hiddenStem',
            'hidden stem is outside the frozen QiYi set',
          );
        }
      }

      _expectExactSet(
        values: palaces.map((palace) => palace.earthStem),
        expected: QimenRuleCatalog.qiYi.toSet(),
        code: 'QMV1-E-EARTH-STEMS',
        path: r'$.palaces[*].earthStem',
        invalid: invalid,
      );
      _expectExactSet(
        values: palaces.map((palace) => palace.heavenStem),
        expected: QimenRuleCatalog.qiYi.toSet(),
        code: 'QMV1-E-HEAVEN-STEMS',
        path: r'$.palaces[*].heavenStem',
        invalid: invalid,
      );
      _expectExactSet(
        values: palaces.map((palace) => palace.star),
        expected: _stars,
        code: 'QMV1-E-STARS',
        path: r'$.palaces[*].star',
        invalid: invalid,
      );
      _expectExactSet(
        values: palaces.map((palace) => palace.door).whereType<String>(),
        expected: _doors,
        code: 'QMV1-E-DOORS',
        path: r'$.palaces[*].door',
        invalid: invalid,
      );
      _expectExactSet(
        values: palaces.map((palace) => palace.deity).whereType<String>(),
        expected: _deities,
        code: 'QMV1-E-DEITIES',
        path: r'$.palaces[*].deity',
        invalid: invalid,
      );

      final hostedEarth = palaces
          .where((palace) => palace.hostedEarthStem != null)
          .toList(growable: false);
      final expectedHost =
          result.panParams.hostingMode == QimenHostingMode.yangEightYinTwo &&
                  result.juInfo.dun == QimenDun.yang
              ? 8
              : 2;
      if (hostedEarth.length != 1 ||
          hostedEarth.single.number != expectedHost ||
          hostedEarth.single.hostedEarthStem != center.earthStem) {
        invalid(
          'QMV1-E-HOSTED-EARTH',
          r'$.palaces[*].hostedEarthStem',
          'hosted earth stem does not preserve the selected center-hosting fact',
        );
      }
      final hostedHeaven = palaces
          .where((palace) => palace.hostedHeavenStem != null)
          .toList(growable: false);
      final earthHost = palaces.singleWhere(
        (palace) => palace.number == expectedHost,
      );
      if (hostedHeaven.length != 1 ||
          hostedHeaven.single.hostedHeavenStem != center.heavenStem ||
          hostedHeaven.single.heavenStem != earthHost.earthStem) {
        invalid(
          'QMV1-E-HOSTED-HEAVEN',
          r'$.palaces[*].hostedHeavenStem',
          'hosted heaven stem must preserve the center stem at the rotated '
              'host-source occurrence',
        );
      }
      final hostedStars = palaces
          .where((palace) => palace.hostedStar != null)
          .toList(growable: false);
      if (hostedStars.length != 1 ||
          hostedStars.single.hostedStar != '天禽' ||
          hostedStars.single.star != '天芮') {
        invalid(
          'QMV1-E-HOSTED-STAR',
          r'$.palaces[*].hostedStar',
          'hosted Tian Qin must occur exactly once with primary Tian Rui',
        );
      }

      final hiddenStems = palaces
          .map((palace) => palace.hiddenStem)
          .whereType<String>()
          .toList(growable: false);
      if (result.panParams.hiddenStemMode ==
          QimenHiddenStemMode.dutyDoorHourStem) {
        _expectExactSet(
          values: hiddenStems,
          expected: QimenRuleCatalog.qiYi.toSet(),
          code: 'QMV1-E-HIDDEN-STEMS',
          path: r'$.palaces[*].hiddenStem',
          invalid: invalid,
        );
      } else {
        final expectedHidden = QimenRuleCatalog.qiYi.toSet()
          ..remove(center.earthStem);
        if (center.hiddenStem != null) {
          invalid(
            'QMV1-E-HIDDEN-STEMS',
            r'$.palaces[number=5].hiddenStem',
            'door-origin hidden-stem mode keeps the center field null',
          );
        }
        _expectExactSet(
          values: hiddenStems,
          expected: expectedHidden,
          code: 'QMV1-E-HIDDEN-STEMS',
          path: r'$.palaces[*].hiddenStem',
          invalid: invalid,
        );
      }

      if (!_palaceContainsStar(result, result.zhiFuPalace, result.zhiFuStar)) {
        invalid(
          'QMV1-E-DUTY-STAR',
          r'$.zhiFuPalace',
          'duty-star palace does not contain the persisted duty star',
        );
      }
      final dutyDoorPalace = _palace(result, result.zhiShiPalace);
      if (dutyDoorPalace?.door != result.zhiShiDoor) {
        invalid(
          'QMV1-E-DUTY-DOOR',
          r'$.zhiShiPalace',
          'duty-door palace does not contain the persisted duty door',
        );
      }

      final horsePalaces = palaces.where((palace) => palace.isHorse).toList();
      final horsePalace = _palace(result, result.horsePalace);
      if (horsePalaces.length != 1 ||
          horsePalace == null ||
          !horsePalace.isHorse ||
          !horsePalace.branches.contains(result.horseBranch)) {
        invalid(
          'QMV1-E-HORSE',
          r'$.horsePalace',
          'horse result fields and palace marker disagree',
        );
      }

      final resultVoid = result.kongWangBranches.toSet();
      final palaceVoid =
          palaces.expand((palace) => palace.voidBranches).toSet();
      if (resultVoid.length != 2 ||
          !resultVoid.every(TianGanDiZhiService.isValidDiZhi) ||
          resultVoid.length != palaceVoid.length ||
          !resultVoid.containsAll(palaceVoid)) {
        invalid(
          'QMV1-E-VOID',
          r'$.kongWangBranches',
          'result-level and palace-level void branches disagree',
        );
      }
      for (final palace in palaces) {
        if (palace.voidBranches
            .any((branch) => !palace.branches.contains(branch))) {
          invalid(
            'QMV1-E-VOID-PALACE',
            '\$.palaces[number=${palace.number}].voidBranches',
            'a void branch is attached to a palace that does not contain it',
          );
        }
      }
    }

    if (QimenConstants.xunHiddenStem[result.xunShou] != result.xunHiddenStem) {
      invalid(
        'QMV1-E-XUN-HIDDEN-STEM',
        r'$.xunHiddenStem',
        'xun head and hidden instrument disagree',
      );
    }
    if (result.juInfo.juNumber < 1 || result.juInfo.juNumber > 9) {
      invalid(
        'QMV1-E-JU-NUMBER',
        r'$.juInfo.juNumber',
        'ju number must be from 1 through 9',
      );
    }
    if (!QimenConstants.solarTerms
            .contains(result.temporalContext.currentSolarTerm) ||
        !QimenConstants.solarTerms.contains(result.juInfo.effectiveSolarTerm)) {
      invalid(
        'QMV1-E-SOLAR-TERM',
        r'$.temporalContext.currentSolarTerm',
        'persisted solar-term facts must be present',
      );
    }

    return QimenInputGuardResult(
      status: diagnostics.isEmpty
          ? QimenAnalysisStatus.complete
          : QimenAnalysisStatus.invalidPanFacts,
      diagnostics: List<QimenAnalysisDiagnostic>.unmodifiable(diagnostics),
    );
  }

  static void _expectExactSet({
    required Iterable<String> values,
    required Set<String> expected,
    required String code,
    required String path,
    required void Function(String, String, String) invalid,
  }) {
    final list = values.toList(growable: false);
    if (list.length != expected.length ||
        list.toSet().length != expected.length ||
        !list.toSet().containsAll(expected)) {
      invalid(
          code, path, 'persisted values are missing, duplicated, or unknown');
    }
  }

  static bool _palaceContainsStar(
    QimenResult result,
    int palaceNumber,
    String star,
  ) {
    final palace = _palace(result, palaceNumber);
    return palace != null && (palace.star == star || palace.hostedStar == star);
  }

  static QimenPalace? _palace(QimenResult result, int number) {
    for (final palace in result.palaces) {
      if (palace.number == number) return palace;
    }
    return null;
  }

  static bool _sameValues(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
