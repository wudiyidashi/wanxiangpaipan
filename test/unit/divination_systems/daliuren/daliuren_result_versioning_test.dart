import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/daliuren_analyzer.dart';

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

  test('旧 JSON 缺 additive 字段时明确读成 legacy unknown/null', () {
    final legacyJson = Map<String, dynamic>.from(currentResult.toJson())
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

  test('C01 v1 snapshot zone-less castTime 结合 offset 恢复且保持 v1', () {
    final v1Json = Map<String, dynamic>.from(currentResult.toJson())
      ..['panRuleSetVersion'] = DlrRuleSetVersions.panV1
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
