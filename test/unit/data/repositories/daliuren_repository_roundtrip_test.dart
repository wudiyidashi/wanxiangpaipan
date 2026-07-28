import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

import 'divination_repository_test.dart' show MockSecureStorage;

void main() {
  group('DaLiuRen repository roundtrip', () {
    late AppDatabase database;
    late DivinationRegistry registry;
    late DivinationRepositoryImpl repository;
    late DaLiuRenResult currentResult;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      registry = DivinationRegistry()..clear();
      registry.register(DaLiuRenSystem());
      repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: MockSecureStorage(),
        registry: registry,
      );
      currentResult = await DaLiuRenSystem().cast(
        method: CastMethod.time,
        input: const <String, dynamic>{'sourceUtcOffsetMinutes': 330},
        castTime: DateTime.utc(2022, 4, 20, 2, 24, 18),
      ) as DaLiuRenResult;
    });

    tearDown(() async {
      await database.close();
      registry.clear();
    });

    test('current v2 preserves UTC civil time and typed month-general facts',
        () async {
      await repository.saveRecord(currentResult);

      final rawRecord =
          await database.divinationRecordDao.getRecordById(currentResult.id);
      final rawJson = jsonDecode(rawRecord!.resultData) as Map<String, dynamic>;
      final snapshot = rawJson['castInputSnapshot'] as Map<String, dynamic>;
      final civilTime = rawJson['civilTime'] as Map<String, dynamic>;
      final resolution =
          rawJson['monthGeneralResolution'] as Map<String, dynamic>;
      final executionRule =
          resolution['executionRuleRef'] as Map<String, dynamic>;

      expect(rawJson['panRuleSetVersion'], DlrRuleSetVersions.panCurrent);
      expect(snapshot['schemaVersion'], DlrRuleSetVersions.castInputSchema);
      expect(snapshot['castTime'], '2022-04-20T02:24:18.000Z');
      expect(snapshot['utcOffsetMinutes'], 330);
      expect(civilTime['instantUtc'], '2022-04-20T02:24:18.000Z');
      expect(civilTime['sourceUtcOffsetMinutes'], 330);
      expect(resolution['yueJiang'], '酉');
      expect(resolution['effectiveZhongQi'], '谷雨');
      expect(
        resolution['effectiveZhongQiInstantUtc'],
        '2022-04-20T02:24:18.000Z',
      );
      expect(executionRule['kind'], 'project');
      expect(
        executionRule['ruleSetVersion'],
        DlrRuleSetVersions.panCurrent,
      );

      final loaded = await repository.getRecordById(currentResult.id);
      expect(loaded, isA<DaLiuRenResult>());
      expect(loaded!.toJson(), currentResult.toJson());
    });

    test('C01 v1 zone-less snapshot restores by its saved offset', () async {
      final v1Json = _jsonCopy(currentResult.toJson())
        ..['id'] = 'daliuren-c01-v1'
        ..['panRuleSetVersion'] = DlrRuleSetVersions.panV1
        ..['castInputSnapshot'] = <String, dynamic>{
          'schemaVersion': DlrRuleSetVersions.castInputSchemaV1,
          'castMethod': CastMethod.time.name,
          'castTime': '2022-04-20T07:54:18.000',
          'utcOffsetMinutes': 330,
          'normalizedInput': <String, dynamic>{
            'params': currentResult.panParams.toJson(),
          },
          'replayStatus': DlrReplayStatus.complete.name,
          'missingFields': <String>[],
        }
        ..remove('civilTime')
        ..remove('monthGeneralResolution');
      await _insertRawResultJson(database, v1Json);

      final loaded = await repository.getRecordById('daliuren-c01-v1');
      expect(loaded, isA<DaLiuRenResult>());
      final daliuren = loaded! as DaLiuRenResult;
      expect(daliuren.panRuleSetVersion, DlrRuleSetVersions.panV1);
      expect(
        daliuren.castInputSnapshot!.schemaVersion,
        DlrRuleSetVersions.castInputSchemaV1,
      );
      expect(
        daliuren.castInputSnapshot!.castTime,
        DateTime.utc(2022, 4, 20, 2, 24, 18),
      );
      expect(daliuren.castInputSnapshot!.utcOffsetMinutes, 330);
      expect(daliuren.civilTime, isNull);
      expect(daliuren.monthGeneralResolution, isNull);

      expect(await repository.updateRecord(daliuren), isTrue);
      final reloaded = await repository.getRecordById(daliuren.id);
      expect(reloaded!.toJson(), daliuren.toJson());
      final normalizedRecord =
          await database.divinationRecordDao.getRecordById(daliuren.id);
      final normalizedJson =
          jsonDecode(normalizedRecord!.resultData) as Map<String, dynamic>;
      final normalizedSnapshot =
          normalizedJson['castInputSnapshot'] as Map<String, dynamic>;
      expect(normalizedSnapshot['schemaVersion'],
          DlrRuleSetVersions.castInputSchemaV1);
      expect(normalizedSnapshot['castTime'], '2022-04-20T02:24:18.000Z');
    });

    test('legacy JSON missing additive fields remains readable after resave',
        () async {
      final legacyJson = _jsonCopy(currentResult.toJson())
        ..['id'] = 'daliuren-legacy-no-additive-fields'
        ..remove('panRuleSetVersion')
        ..remove('evidenceCatalogVersion')
        ..remove('castInputSnapshot')
        ..remove('civilTime')
        ..remove('monthGeneralResolution')
        ..remove('recastFromId');
      await _insertRawResultJson(database, legacyJson);

      final loaded = await repository.getRecordById(
        'daliuren-legacy-no-additive-fields',
      );
      expect(loaded, isA<DaLiuRenResult>());
      final daliuren = loaded! as DaLiuRenResult;
      expect(
        daliuren.panRuleSetVersion,
        DlrRuleSetVersions.legacyUnknown,
      );
      expect(
        daliuren.evidenceCatalogVersion,
        DlrRuleSetVersions.legacyUnknown,
      );
      expect(daliuren.castInputSnapshot, isNull);
      expect(daliuren.civilTime, isNull);
      expect(daliuren.monthGeneralResolution, isNull);
      expect(daliuren.recastFromId, isNull);
      expect(daliuren.tianPan.toJson(), currentResult.tianPan.toJson());

      expect(await repository.updateRecord(daliuren), isTrue);
      final reloaded = await repository.getRecordById(daliuren.id);
      expect(reloaded!.toJson(), daliuren.toJson());
    });
  });
}

Map<String, dynamic> _jsonCopy(Map<String, dynamic> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

Future<void> _insertRawResultJson(
  AppDatabase database,
  Map<String, dynamic> resultJson,
) async {
  final castTime = DateTime.parse(resultJson['castTime'] as String);
  await database.divinationRecordDao.insertRecord(
    DivinationRecordsCompanion(
      id: drift.Value(resultJson['id'] as String),
      systemType: drift.Value(DivinationType.daLiuRen.id),
      castTime: drift.Value(castTime),
      castMethod: drift.Value(CastMethod.time.id),
      resultData: drift.Value(jsonEncode(resultJson)),
      lunarData: drift.Value(jsonEncode(resultJson['lunarInfo'])),
      questionId: const drift.Value(''),
      detailId: const drift.Value(''),
      interpretationId: const drift.Value(''),
      createdAt: drift.Value(castTime),
      updatedAt: drift.Value(castTime),
    ),
  );
}
