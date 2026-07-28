import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
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

  test('新盘版本、snapshot 与 recast link 完整 round-trip', () {
    final linked = currentResult.copyWith(recastFromId: 'legacy-dlr-001');
    final decoded = DaLiuRenResult.fromJson(linked.toJson());

    expect(decoded.panRuleSetVersion, DlrRuleSetVersions.panCurrent);
    expect(
      decoded.evidenceCatalogVersion,
      DlrRuleSetVersions.evidenceCatalog,
    );
    expect(decoded.castInputSnapshot, linked.castInputSnapshot);
    expect(decoded.recastFromId, 'legacy-dlr-001');
  });

  test('旧 JSON 缺四个 additive 字段时明确读成 legacy unknown', () {
    final legacyJson = Map<String, dynamic>.from(currentResult.toJson())
      ..remove('panRuleSetVersion')
      ..remove('evidenceCatalogVersion')
      ..remove('castInputSnapshot')
      ..remove('recastFromId');

    final decoded = DaLiuRenResult.fromJson(legacyJson);
    final report = DaLiuRenAnalyzer.analyze(decoded);

    expect(decoded.panRuleSetVersion, DlrRuleSetVersions.legacyUnknown);
    expect(
      decoded.evidenceCatalogVersion,
      DlrRuleSetVersions.legacyUnknown,
    );
    expect(decoded.castInputSnapshot, isNull);
    expect(decoded.recastFromId, isNull);
    expect(
      report.compatibilityStatus,
      DlrAnalysisCompatibility.legacyUnknown,
    );
  });

  test('未来未知 pan 版本原样保留并优先判 version mismatch', () {
    const futureVersion = 'daliuren-pan/99.0.0';
    final futureJson = Map<String, dynamic>.from(currentResult.toJson())
      ..['panRuleSetVersion'] = futureVersion
      ..remove('castInputSnapshot');

    final decoded = DaLiuRenResult.fromJson(futureJson);
    final report = DaLiuRenAnalyzer.analyze(decoded);

    expect(decoded.panRuleSetVersion, futureVersion);
    expect(report.sourcePanRuleSetVersion, futureVersion);
    expect(
      report.compatibilityStatus,
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
