import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_jiang_config.dart';

void main() {
  group('ShenJiangConfig current contract', () {
    test('new wire round-trip uses only coordinate-explicit keys', () {
      final config = _validConfig();

      final json = config.toJson();
      final decoded = ShenJiangConfig.fromJson(json);

      expect(
        json.keys,
        unorderedEquals(<String>{
          'selectedGuiRenTianBranch',
          'guiRenEarthPalace',
          'isYangGui',
          'actualDirection',
          'positions',
          'tianBranchToGeneral',
          'earthPalaceToGeneral',
          'executionRuleRef',
          'classicAttributionRuleIds',
        }),
      );
      expect(
        (json['positions'] as List<dynamic>).first,
        <String, dynamic>{
          'shenJiang': 'guiRen',
          'heavenBranch': '子',
          'earthPalace': '子',
        },
      );
      expect(json, isNot(contains('guiRenPosition')));
      expect(json, isNot(contains('isYangRi')));
      expect(json, isNot(contains('diZhiToShenJiang')));
      expect(decoded, config);
      expect(decoded.generalForHeavenBranch('子'), ShenJiang.guiRen);
      expect(decoded.generalForEarthPalace('丑'), ShenJiang.tengShe);
      expect(decoded.positionOf(ShenJiang.qingLong)?.earthPalace, '巳');
    });

    test('constructor rejects incomplete maps and duplicate generals', () {
      final valid = _validConfig();
      final missingBranch = Map<String, ShenJiang>.from(
        valid.tianBranchToGeneral,
      )..remove('亥');
      final duplicateGeneral = Map<String, ShenJiang>.from(
        valid.earthPalaceToGeneral,
      )..['亥'] = ShenJiang.taiYin;

      expect(
        () => _copyConfig(valid, tianBranchToGeneral: missingBranch),
        throwsArgumentError,
      );
      expect(
        () => _copyConfig(valid, earthPalaceToGeneral: duplicateGeneral),
        throwsArgumentError,
      );
    });

    test('constructor rejects position, anchor, and direction contradictions',
        () {
      final valid = _validConfig();
      final duplicatePositions = List<ShenJiangPosition>.from(valid.positions)
        ..[11] = valid.positions.first;
      final conflictingMap = Map<String, ShenJiang>.from(
        valid.tianBranchToGeneral,
      );
      final first = conflictingMap['子']!;
      conflictingMap['子'] = conflictingMap['丑']!;
      conflictingMap['丑'] = first;

      for (final create in <ShenJiangConfig Function()>[
        () => _copyConfig(valid, positions: duplicatePositions),
        () => _copyConfig(valid, tianBranchToGeneral: conflictingMap),
        () => _copyConfig(valid, selectedGuiRenTianBranch: '丑'),
        () => _copyConfig(valid, guiRenEarthPalace: '丑'),
        () => _copyConfig(
              valid,
              actualDirection: ShenJiangDirection.ni,
            ),
      ]) {
        expect(create, throwsArgumentError);
      }
    });

    test('current direction is derived from the noble earth-palace six zones',
        () {
      expect(
        () => _validConfig(
          guiRenEarthPalace: '巳',
          direction: ShenJiangDirection.shun,
        ),
        throwsArgumentError,
      );
      expect(
        () => _validConfig(
          guiRenEarthPalace: '巳',
          direction: ShenJiangDirection.ni,
        ),
        returnsNormally,
      );
    });

    test('current attribution and execution identity are exact contracts', () {
      final valid = _validConfig();
      final fakeAttributions = List<String>.from(
        valid.classicAttributionRuleIds,
      )..[3] = 'dlr.rule.shenjiang.999.fabricated';
      final analysisVersionRef = valid.executionRuleRef.copyWith(
        ruleSetVersion: DlrRuleSetVersions.analysisCurrent,
      );

      expect(
        () => _copyConfig(valid, classicAttributionRuleIds: const <String>[]),
        throwsArgumentError,
      );
      expect(
        () => _copyConfig(
          valid,
          classicAttributionRuleIds: fakeAttributions,
        ),
        throwsArgumentError,
      );
      expect(
        () => _copyConfig(valid, executionRuleRef: analysisVersionRef),
        throwsArgumentError,
      );
    });

    test('legacy import keeps its historical layout but must match parent', () {
      final current = _validConfig();
      final legacy = _copyConfig(
        current,
        executionRuleRef: DlrRuleRef.projectPan(
          DlrProjectPanRuleIds.shenJiangLegacyLayoutImport,
          ruleSetVersion: DlrRuleSetVersions.panV3,
        ),
        classicAttributionRuleIds: const <String>[],
      );

      expect(
        () => legacy.validateForPanRuleSetVersion(DlrRuleSetVersions.panV3),
        returnsNormally,
      );
      expect(
        () => legacy.validateForPanRuleSetVersion(
          DlrRuleSetVersions.panCurrent,
        ),
        throwsArgumentError,
      );
      expect(
        () => current.validateForPanRuleSetVersion(
          DlrRuleSetVersions.panV3,
        ),
        throwsArgumentError,
      );
    });

    test('result boundary validation ties every heaven branch to TianPan', () {
      final config = _validConfig();
      final identity = <String, String>{
        for (final branch in DaLiuRenConstants.diZhi) branch: branch,
      };
      final shifted = <String, String>{
        for (var index = 0; index < DaLiuRenConstants.diZhi.length; index++)
          DaLiuRenConstants.diZhi[index]:
              DaLiuRenConstants.diZhi[(index + 1) % 12],
      };

      expect(() => config.validateAgainstTianPan(identity), returnsNormally);
      expect(
        () => config.validateAgainstTianPan(shifted),
        throwsArgumentError,
      );
    });

    test('constructor and copyWith take defensive snapshots', () {
      final seed = _validConfig();
      final positions = List<ShenJiangPosition>.from(seed.positions);
      final tianMap = Map<String, ShenJiang>.from(
        seed.tianBranchToGeneral,
      );
      final earthMap = Map<String, ShenJiang>.from(
        seed.earthPalaceToGeneral,
      );
      final attributions = List<String>.from(
        seed.classicAttributionRuleIds,
      );
      final config = ShenJiangConfig(
        selectedGuiRenTianBranch: seed.selectedGuiRenTianBranch,
        guiRenEarthPalace: seed.guiRenEarthPalace,
        isYangGui: seed.isYangGui,
        actualDirection: seed.actualDirection,
        positions: positions,
        tianBranchToGeneral: tianMap,
        earthPalaceToGeneral: earthMap,
        executionRuleRef: seed.executionRuleRef,
        classicAttributionRuleIds: attributions,
      );

      positions.clear();
      tianMap.clear();
      earthMap.clear();
      attributions.clear();

      expect(config.positions, hasLength(12));
      expect(config.tianBranchToGeneral, hasLength(12));
      expect(config.earthPalaceToGeneral, hasLength(12));
      expect(config.classicAttributionRuleIds, hasLength(4));
      expect(
        () => config.positions.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => config.tianBranchToGeneral.clear(),
        throwsUnsupportedError,
      );

      final replacement = Map<String, ShenJiang>.from(
        config.tianBranchToGeneral,
      );
      final copied = config.copyWith(tianBranchToGeneral: replacement);
      replacement.clear();
      expect(copied.tianBranchToGeneral, hasLength(12));
      expect(
        () => config.copyWith(actualDirection: ShenJiangDirection.ni),
        throwsArgumentError,
      );
    });

    test('fromJson rejects old, mixed, unknown, and malformed shapes', () {
      final valid = _validConfig().toJson();
      final oldField = Map<String, dynamic>.from(valid)
        ..['guiRenPosition'] = '子';
      final unknownDirection = Map<String, dynamic>.from(valid)
        ..['actualDirection'] = 'sideways';
      final malformedPositions = Map<String, dynamic>.from(valid)
        ..['positions'] = <dynamic>[];

      for (final json in <Map<String, dynamic>>[
        oldField,
        unknownDirection,
        malformedPositions,
      ]) {
        expect(() => ShenJiangConfig.fromJson(json), throwsArgumentError);
      }
    });
  });
}

ShenJiangConfig _validConfig({
  ShenJiangDirection direction = ShenJiangDirection.shun,
  String guiRenEarthPalace = '子',
}) {
  final branches = DaLiuRenConstants.diZhi;
  final step = direction == ShenJiangDirection.shun ? 1 : -1;
  final startIndex = branches.indexOf(guiRenEarthPalace);
  final positions = <ShenJiangPosition>[];
  final tianMap = <String, ShenJiang>{};
  final earthMap = <String, ShenJiang>{};
  for (var index = 0; index < ShenJiang.values.length; index++) {
    final branch = branches[(startIndex + step * index) % branches.length];
    final general = ShenJiang.values[index];
    positions.add(
      ShenJiangPosition(
        shenJiang: general,
        heavenBranch: branch,
        earthPalace: branch,
      ),
    );
    tianMap[branch] = general;
    earthMap[branch] = general;
  }
  return ShenJiangConfig(
    selectedGuiRenTianBranch: guiRenEarthPalace,
    guiRenEarthPalace: guiRenEarthPalace,
    isYangGui: true,
    actualDirection: direction,
    positions: positions,
    tianBranchToGeneral: tianMap,
    earthPalaceToGeneral: earthMap,
    executionRuleRef: DlrRuleRef.projectPan(
      DlrProjectPanRuleIds.shenJiangLandingPalaceLayout,
    ),
    classicAttributionRuleIds: DlrShenJiangClassicRuleIds.currentAttributions,
  );
}

ShenJiangConfig _copyConfig(
  ShenJiangConfig source, {
  String? selectedGuiRenTianBranch,
  String? guiRenEarthPalace,
  ShenJiangDirection? actualDirection,
  List<ShenJiangPosition>? positions,
  Map<String, ShenJiang>? tianBranchToGeneral,
  Map<String, ShenJiang>? earthPalaceToGeneral,
  DlrRuleRef? executionRuleRef,
  List<String>? classicAttributionRuleIds,
}) =>
    ShenJiangConfig(
      selectedGuiRenTianBranch:
          selectedGuiRenTianBranch ?? source.selectedGuiRenTianBranch,
      guiRenEarthPalace: guiRenEarthPalace ?? source.guiRenEarthPalace,
      isYangGui: source.isYangGui,
      actualDirection: actualDirection ?? source.actualDirection,
      positions: positions ?? source.positions,
      tianBranchToGeneral: tianBranchToGeneral ?? source.tianBranchToGeneral,
      earthPalaceToGeneral: earthPalaceToGeneral ?? source.earthPalaceToGeneral,
      executionRuleRef: executionRuleRef ?? source.executionRuleRef,
      classicAttributionRuleIds:
          classicAttributionRuleIds ?? source.classicAttributionRuleIds,
    );
