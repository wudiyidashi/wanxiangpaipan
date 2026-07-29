import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/daliuren_analyzer.dart';

import 'fixtures/legacy_daliuren_wire_fixture.dart';

void main() {
  late DaLiuRenResult currentResult;

  setUp(() async {
    currentResult = await DaLiuRenSystem().cast(
      method: CastMethod.time,
      input: const <String, dynamic>{},
      castTime: DateTime(2026, 4, 18, 22, 20),
    ) as DaLiuRenResult;
  });

  test('新盘版本、calendar facts、snapshot 与 recast link 完整 round-trip', () {
    final civilTime = DlrCivilTime(
      instant: DateTime.parse('2022-04-20T10:24:18+08:00'),
      sourceUtcOffsetMinutes: 480,
    );
    final monthGeneralResolution = DlrMonthGeneralResolution(
      yueJiang: '酉',
      mode: DlrMonthGeneralResolutionMode.zhongQi,
      effectiveZhongQi: '谷雨',
      effectiveZhongQiInstantUtc: DateTime.parse('2022-04-20T10:24:18+08:00'),
      calendarEngine: 'lunar',
      calendarEngineVersion: '1.7.8',
      algorithmVersion: 'daliuren-yuejiang-fixed-beijing-v1',
      executionRuleRef: DlrRuleRef.projectPan(
        DlrProjectPanRuleIds.monthGeneralByZhongQiInstant,
      ),
      classicAttributionRuleIds: const <String>[
        'dlr.rule.pan.001.month-general-by-zhongqi',
        'dlr.rule.pan.002.month-general-table',
      ],
    );
    final linked = currentResult.copyWith(
      civilTime: civilTime,
      monthGeneralResolution: monthGeneralResolution,
      recastFromId: 'legacy-dlr-001',
    );
    final encoded = linked.toJson();
    final decoded = DaLiuRenResult.fromJson(linked.toJson());

    expect(decoded.panRuleSetVersion, DlrRuleSetVersions.panCurrent);
    expect(
      decoded.evidenceCatalogVersion,
      DlrRuleSetVersions.evidenceCatalog,
    );
    expect(decoded.castInputSnapshot, linked.castInputSnapshot);
    expect(decoded.civilTime, civilTime);
    expect(decoded.monthGeneralResolution, monthGeneralResolution);
    expect(decoded.recastFromId, 'legacy-dlr-001');
    final cleared = linked.copyWith(
      civilTime: null,
      monthGeneralResolution: null,
      recastFromId: null,
    );
    expect(cleared.civilTime, isNull);
    expect(cleared.monthGeneralResolution, isNull);
    expect(cleared.recastFromId, isNull);
    expect(encoded['castTime'], linked.castTime.toIso8601String());
    expect(
      (encoded['civilTime'] as Map<String, dynamic>)['instantUtc'],
      '2022-04-20T02:24:18.000Z',
    );
    expect(
      (encoded['monthGeneralResolution']
          as Map<String, dynamic>)['effectiveZhongQiInstantUtc'],
      '2022-04-20T02:24:18.000Z',
    );
  });

  test('公开构造与 copyWith 均拒绝版本或四课乘将矛盾', () {
    final originalLesson = currentResult.siKe.ke1;
    final wrongGeneral = ShenJiang.values.firstWhere(
      (general) => general != originalLesson.chengShen,
    );
    final inconsistentSiKe = currentResult.siKe.copyWith(
      ke1: originalLesson.copyWith(chengShen: wrongGeneral),
    );

    expect(
      () => currentResult.copyWith(
        panRuleSetVersion: DlrRuleSetVersions.panV3,
      ),
      throwsArgumentError,
    );
    expect(
      () => currentResult.copyWith(
        evidenceCatalogVersion: DlrRuleSetVersions.legacyUnknown,
      ),
      throwsArgumentError,
    );
    expect(
      () => currentResult.copyWith(siKe: inconsistentSiKe),
      throwsArgumentError,
    );
    expect(
      () => DaLiuRenResult(
        id: currentResult.id,
        castTime: currentResult.castTime,
        castMethod: currentResult.castMethod,
        lunarInfo: currentResult.lunarInfo,
        tianPan: currentResult.tianPan,
        siKe: inconsistentSiKe,
        sanChuan: currentResult.sanChuan,
        shenJiangConfig: currentResult.shenJiangConfig,
        shenShaList: currentResult.shenShaList,
        panParams: currentResult.panParams,
        castInputSnapshot: currentResult.castInputSnapshot,
        civilTime: currentResult.civilTime,
        monthGeneralResolution: currentResult.monthGeneralResolution,
      ),
      throwsArgumentError,
    );
  });

  test('当前盘结果边界拒绝历史甲日特例', () {
    final historicalOnlyParams = currentResult.panParams.copyWith(
      guiRenVerse: DaLiuRenGuiRenVerse.jiaDayAlt,
    );

    expect(
      historicalOnlyParams.guiRenVerseLabel,
      '历史甲日特例（无古籍批准）',
    );
    expect(
      () => currentResult.copyWith(panParams: historicalOnlyParams),
      throwsArgumentError,
    );
  });

  test('反序列化拒绝三传乘将与天盘支映射矛盾', () {
    final invalid =
        jsonDecode(jsonEncode(currentResult.toJson())) as Map<String, dynamic>;
    final sanChuan = invalid['sanChuan'] as Map<String, dynamic>;
    final chuChuan = sanChuan['chuChuan'] as Map<String, dynamic>;
    final original = currentResult.sanChuan.chuChuan.chengShen;
    chuChuan['chengShen'] =
        ShenJiang.values.firstWhere((general) => general != original).name;

    expect(() => DaLiuRenResult.fromJson(invalid), throwsArgumentError);
  });

  test('旧 JSON 缺 additive 字段时明确读成 legacy unknown/null', () {
    final legacyJson = legacyShenJiangResultJson(
      currentResult,
      omitPanRuleSetVersion: true,
    )
      ..remove('panRuleSetVersion')
      ..remove('evidenceCatalogVersion')
      ..remove('castInputSnapshot')
      ..remove('civilTime')
      ..remove('monthGeneralResolution')
      ..remove('recastFromId');

    final decoded = DaLiuRenResult.fromJson(legacyJson);
    final report = DaLiuRenAnalyzer.analyze(decoded);

    expect(decoded.panRuleSetVersion, DlrRuleSetVersions.legacyUnknown);
    expect(
      decoded.evidenceCatalogVersion,
      DlrRuleSetVersions.legacyUnknown,
    );
    expect(decoded.castInputSnapshot, isNull);
    expect(decoded.civilTime, isNull);
    expect(decoded.monthGeneralResolution, isNull);
    expect(decoded.recastFromId, isNull);
    expect(
      report.compatibilityStatus,
      DlrAnalysisCompatibility.legacyUnknown,
    );
  });

  test('未来未知 pan 版本原样保留并优先判 version mismatch', () {
    const futureVersion = 'daliuren-pan/99.0.0';
    final futureJson =
        jsonDecode(jsonEncode(currentResult.toJson())) as Map<String, dynamic>;
    final resolution =
        futureJson['monthGeneralResolution'] as Map<String, dynamic>;
    final executionRuleRef =
        resolution['executionRuleRef'] as Map<String, dynamic>;
    futureJson['panRuleSetVersion'] = futureVersion;
    executionRuleRef['ruleSetVersion'] = futureVersion;
    final shenJiang = futureJson['shenJiangConfig'] as Map<String, dynamic>;
    final shenJiangExecutionRule =
        shenJiang['executionRuleRef'] as Map<String, dynamic>;
    shenJiangExecutionRule['ruleSetVersion'] = futureVersion;
    futureJson.remove('castInputSnapshot');

    final decoded = DaLiuRenResult.fromJson(futureJson);
    final report = DaLiuRenAnalyzer.analyze(decoded);

    expect(decoded.panRuleSetVersion, futureVersion);
    expect(
      decoded.monthGeneralResolution!.executionRuleRef.ruleSetVersion,
      futureVersion,
    );
    expect(report.sourcePanRuleSetVersion, futureVersion);
    expect(
      report.compatibilityStatus,
      DlrAnalysisCompatibility.versionMismatch,
    );
  });

  test('published pan v3 remains readable but is not current under v4', () {
    final v3Json = legacyShenJiangResultJson(currentResult);

    final decoded = DaLiuRenResult.fromJson(v3Json);
    final report = DaLiuRenAnalyzer.analyze(decoded);

    expect(decoded.panRuleSetVersion, 'daliuren-pan/3.0.0');
    expect(report.sourcePanRuleSetVersion, DlrRuleSetVersions.panV3);
    expect(
      report.compatibilityStatus,
      DlrAnalysisCompatibility.versionMismatch,
    );
    expect(DlrRuleSetVersions.castInputSchema, '2.0.0');
    expect(
      DlrRuleSetVersions.evidenceCatalog,
      'daliuren-classics/1.1.0',
    );
  });

  test('v3 real old shenjiang shape migrates read-old/write-new losslessly',
      () {
    final legacyJson = legacyShenJiangResultJson(currentResult);
    final originalSiKe = legacyJson['siKe'];
    final originalSanChuan = legacyJson['sanChuan'];

    final decoded = DaLiuRenResult.fromJson(legacyJson);
    final rewrittenConfig =
        decoded.toJson()['shenJiangConfig'] as Map<String, dynamic>;

    expect(decoded.panRuleSetVersion, DlrRuleSetVersions.panV3);
    expect(
      decoded.shenJiangConfig.selectedGuiRenTianBranch,
      currentResult.shenJiangConfig.selectedGuiRenTianBranch,
    );
    expect(
      decoded.shenJiangConfig.isYangGui,
      currentResult.shenJiangConfig.isYangGui,
    );
    expect(decoded.shenJiangConfig.actualDirection.name, 'shun');
    expect(
      decoded.shenJiangConfig.executionRuleRef.ruleId,
      DlrProjectPanRuleIds.shenJiangLegacyLayoutImport,
    );
    expect(
      decoded.shenJiangConfig.executionRuleRef.ruleSetVersion,
      DlrRuleSetVersions.panV3,
    );
    expect(decoded.shenJiangConfig.classicAttributionRuleIds, isEmpty);
    expect(decoded.toJson()['siKe'], originalSiKe);
    expect(decoded.toJson()['sanChuan'], originalSanChuan);
    expect(rewrittenConfig, isNot(contains('guiRenPosition')));
    expect(rewrittenConfig, isNot(contains('isYangRi')));
    expect(rewrittenConfig, isNot(contains('diZhiToShenJiang')));
    expect(rewrittenConfig, contains('selectedGuiRenTianBranch'));
    expect(rewrittenConfig, contains('tianBranchToGeneral'));
    expect(rewrittenConfig, contains('earthPalaceToGeneral'));
  });

  test('v4 rejects old shenjiang shape instead of treating it as current', () {
    final invalid = legacyShenJiangResultJson(currentResult)
      ..['panRuleSetVersion'] = DlrRuleSetVersions.panCurrent;

    expect(() => DaLiuRenResult.fromJson(invalid), throwsArgumentError);
  });

  test('old shenjiang positions must recover the persisted TianPan exactly',
      () {
    final invalid = legacyShenJiangResultJson(currentResult);
    final config = invalid['shenJiangConfig'] as Map<String, dynamic>;
    final positions = config['positions'] as List<dynamic>;
    final first = positions.first as Map<String, dynamic>;
    first['tianPanZhi'] = first['tianPanZhi'] == '子' ? '丑' : '子';

    expect(() => DaLiuRenResult.fromJson(invalid), throwsArgumentError);
  });

  test('known historical versions reject a current-layout execution identity',
      () {
    for (final version in <String>[
      DlrRuleSetVersions.legacyUnknown,
      DlrRuleSetVersions.panV1,
      DlrRuleSetVersions.panV2,
      DlrRuleSetVersions.panV3,
    ]) {
      final invalid = jsonDecode(jsonEncode(currentResult.toJson()))
          as Map<String, dynamic>
        ..['panRuleSetVersion'] = version;

      expect(
        () => DaLiuRenResult.fromJson(invalid),
        throwsArgumentError,
        reason: version,
      );
    }
  });

  test('all historical version forms migrate the real old shenjiang wire', () {
    final cases = <({String label, String? version})>[
      (label: 'missing', version: null),
      (label: 'legacyUnknown', version: DlrRuleSetVersions.legacyUnknown),
      (label: 'v1', version: DlrRuleSetVersions.panV1),
      (label: 'v2', version: DlrRuleSetVersions.panV2),
      (label: 'v3', version: DlrRuleSetVersions.panV3),
    ];

    for (final testCase in cases) {
      final oldJson = legacyShenJiangResultJson(
        currentResult,
        panRuleSetVersion: testCase.version ?? DlrRuleSetVersions.legacyUnknown,
        omitPanRuleSetVersion: testCase.version == null,
        id: 'legacy-${testCase.label}',
      );
      final originalSiKe = jsonEncode(oldJson['siKe']);
      final originalSanChuan = jsonEncode(oldJson['sanChuan']);

      final decoded = DaLiuRenResult.fromJson(oldJson);
      final rewritten = decoded.toJson();
      final decodedAgain = DaLiuRenResult.fromJson(
        jsonDecode(jsonEncode(rewritten)) as Map<String, dynamic>,
      );
      final expectedVersion =
          testCase.version ?? DlrRuleSetVersions.legacyUnknown;

      expect(decoded.panRuleSetVersion, expectedVersion,
          reason: testCase.label);
      expect(decoded.shenJiangConfig.executionRuleRef.ruleSetVersion,
          expectedVersion,
          reason: testCase.label);
      expect(decodedAgain.id, 'legacy-${testCase.label}');
      expect(jsonEncode(decodedAgain.toJson()['siKe']), originalSiKe);
      expect(jsonEncode(decodedAgain.toJson()['sanChuan']), originalSanChuan);
    }
  });

  test('nested malformed TianPan JSON cannot bypass result decoding', () {
    final malformed =
        jsonDecode(jsonEncode(currentResult.toJson())) as Map<String, dynamic>;
    final tianPan = malformed['tianPan'] as Map<String, dynamic>;
    tianPan['tianPanMap'] = <String, String>{'子': '子'};

    expect(
      () => DaLiuRenResult.fromJson(malformed),
      throwsArgumentError,
    );
  });

  test('C01 v1 snapshot zone-less castTime 结合 offset 恢复且保持 v1', () {
    final v1Json = legacyShenJiangResultJson(
      currentResult,
      panRuleSetVersion: DlrRuleSetVersions.panV1,
    )
      ..['castInputSnapshot'] = <String, dynamic>{
        'schemaVersion': DlrRuleSetVersions.castInputSchemaV1,
        'castMethod': CastMethod.manual.name,
        'castTime': '2022-04-20T10:24:18.000',
        'utcOffsetMinutes': 480,
        'normalizedInput': <String, dynamic>{
          'yearGanZhi': '壬寅',
          'monthGanZhi': '甲辰',
          'dayGanZhi': '癸卯',
          'hourGanZhi': '丁巳',
          'params': <String, dynamic>{},
        },
        'replayStatus': DlrReplayStatus.incomplete.name,
        'missingFields': <String>['manualCivilDateTime'],
      }
      ..remove('civilTime')
      ..remove('monthGeneralResolution');

    final decoded = DaLiuRenResult.fromJson(v1Json);

    expect(decoded.panRuleSetVersion, DlrRuleSetVersions.panV1);
    expect(
      decoded.castInputSnapshot!.schemaVersion,
      DlrRuleSetVersions.castInputSchemaV1,
    );
    expect(
      decoded.castInputSnapshot!.castTime,
      DateTime.utc(2022, 4, 20, 2, 24, 18),
    );
    expect(decoded.civilTime, isNull);
    expect(decoded.monthGeneralResolution, isNull);
    expect(
      DaLiuRenAnalyzer.analyze(decoded).compatibilityStatus,
      DlrAnalysisCompatibility.versionMismatch,
    );
  });

  test('toJson/fromJson 边界不会把外部 map 修改反向带入 snapshot', () {
    final serialized = currentResult.toJson();
    final snapshotJson =
        serialized['castInputSnapshot'] as Map<String, dynamic>;
    final normalized = snapshotJson['normalizedInput'] as Map<String, dynamic>;
    expect(
      () => normalized['lateMutation'] = true,
      throwsUnsupportedError,
    );

    final mutableJson =
        jsonDecode(jsonEncode(serialized)) as Map<String, dynamic>;
    final decoded = DaLiuRenResult.fromJson(mutableJson);
    final sourceSnapshot =
        mutableJson['castInputSnapshot'] as Map<String, dynamic>;
    final sourceNormalized =
        sourceSnapshot['normalizedInput'] as Map<String, dynamic>;
    final sourceParams = sourceNormalized['params'] as Map<String, dynamic>;
    sourceParams['monthGeneralMode'] = 'manual';
    sourceNormalized['lateMutation'] = true;

    final savedParams = decoded.castInputSnapshot!.normalizedInput['params']
        as Map<String, dynamic>;
    expect(savedParams['monthGeneralMode'], 'auto');
    expect(
      decoded.castInputSnapshot!.normalizedInput,
      isNot(contains('lateMutation')),
    );
  });
}
