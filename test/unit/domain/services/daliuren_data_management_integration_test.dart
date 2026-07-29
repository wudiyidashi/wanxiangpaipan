import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/data_management_service.dart';

import '../../divination_systems/daliuren/fixtures/legacy_daliuren_wire_fixture.dart';

void main() {
  group('Daliuren data management integration', () {
    late DivinationRegistry registry;
    final harnesses = <_Harness>[];
    final tempDirectories = <Directory>[];

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      registry = DivinationRegistry()..clear();
      registry.register(DaLiuRenSystem());
    });

    tearDown(() async {
      for (final harness in harnesses.reversed) {
        await harness.database.close();
      }
      for (final directory in tempDirectories.reversed) {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
      harnesses.clear();
      tempDirectories.clear();
      registry.clear();
    });

    Future<_Harness> createHarness() async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final storage = _MemorySecureStorage();
      final manager = AIConfigManager(
        database: database,
        secureStorage: storage,
      );
      final repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: storage,
        registry: registry,
      );
      final harness = _Harness(
        database: database,
        repository: repository,
        service: DataManagementService(
          repository: repository,
          aiConfigManager: manager,
          registry: registry,
        ),
      );
      harnesses.add(harness);
      return harness;
    }

    Future<Directory> createTempDirectory() async {
      final directory =
          await Directory.systemTemp.createTemp('daliuren_backup_roundtrip_');
      tempDirectories.add(directory);
      return directory;
    }

    test('current、C01 v1 与 legacy JSON 通过备份完整往返', () async {
      final source = await createHarness();
      final target = await createHarness();
      final current = await DaLiuRenSystem().cast(
        method: CastMethod.time,
        input: const <String, dynamic>{'sourceUtcOffsetMinutes': 330},
        castTime: DateTime.utc(2022, 4, 20, 2, 24, 18),
      ) as DaLiuRenResult;
      final v1 = _buildV1(current);
      final legacy = _buildLegacy(current);
      final v3 = _buildV3(current);

      for (final result in <DaLiuRenResult>[current, v1, legacy, v3]) {
        await source.repository.saveRecord(result);
      }
      await source.repository.saveEncryptedFieldsBatch(<String, String>{
        'question_${current.id}': '大六壬备份占问',
      });

      final directory = await createTempDirectory();
      final exported = await source.service.exportBackup(
        outputDirectory: directory,
      );
      final legacyShapedBackup = await _rewriteDlrCompatibilityShapes(
        File(exported.filePath),
        directory,
        v1Id: v1.id,
        legacyId: legacy.id,
        v3Id: v3.id,
      );
      final imported = await target.service.importBackup(
        legacyShapedBackup,
        mode: BackupImportMode.merge,
      );

      final restoredCurrent =
          await target.repository.getRecordById(current.id) as DaLiuRenResult?;
      final restoredV1 =
          await target.repository.getRecordById(v1.id) as DaLiuRenResult?;
      final restoredLegacy =
          await target.repository.getRecordById(legacy.id) as DaLiuRenResult?;
      final restoredV3 =
          await target.repository.getRecordById(v3.id) as DaLiuRenResult?;
      final summary = await target.service.loadSummary();

      expect(imported.recordCount, 4);
      expect(imported.skippedRecordCount, 0);
      expect(restoredCurrent!.toJson(), current.toJson());
      expect(restoredV1!.toJson(), v1.toJson());
      expect(
        restoredV1.castInputSnapshot!.castTime,
        DateTime.utc(2022, 4, 20, 2, 24, 18),
      );
      expect(
          restoredLegacy!.panRuleSetVersion, DlrRuleSetVersions.legacyUnknown);
      expect(restoredLegacy.castInputSnapshot, isNull);
      expect(restoredLegacy.civilTime, isNull);
      expect(restoredLegacy.monthGeneralResolution, isNull);
      expect(restoredV3!.id, v3.id);
      expect(restoredV3.panRuleSetVersion, DlrRuleSetVersions.panV3);
      expect(restoredV3.siKe, v3.siKe);
      expect(restoredV3.sanChuan, v3.sanChuan);
      expect(
        restoredV3.shenJiangConfig.executionRuleRef.ruleId,
        DlrProjectPanRuleIds.shenJiangLegacyLayoutImport,
      );
      expect(summary.totalRecords, 4);
      expect(summary.daliurenCount, 4);
      expect(
        await target.repository.readEncryptedField('question_${current.id}'),
        '大六壬备份占问',
      );
    });
  });
}

DaLiuRenResult _buildV1(DaLiuRenResult source) {
  final json = legacyShenJiangResultJson(
    source,
    id: '${source.id}_v1',
    panRuleSetVersion: DlrRuleSetVersions.panV1,
  )
    ..['castInputSnapshot'] = <String, dynamic>{
      'schemaVersion': DlrRuleSetVersions.castInputSchemaV1,
      'castMethod': CastMethod.time.name,
      'castTime': '2022-04-20T10:24:18.000',
      'utcOffsetMinutes': 480,
      'normalizedInput': <String, dynamic>{
        'params': <String, dynamic>{},
      },
      'replayStatus': DlrReplayStatus.complete.name,
      'missingFields': <String>[],
    }
    ..remove('civilTime')
    ..remove('monthGeneralResolution');
  return DaLiuRenResult.fromJson(json);
}

DaLiuRenResult _buildLegacy(DaLiuRenResult source) {
  final json = legacyShenJiangResultJson(
    source,
    id: '${source.id}_legacy',
    omitPanRuleSetVersion: true,
  )
    ..remove('panRuleSetVersion')
    ..remove('evidenceCatalogVersion')
    ..remove('castInputSnapshot')
    ..remove('civilTime')
    ..remove('monthGeneralResolution')
    ..remove('recastFromId');
  return DaLiuRenResult.fromJson(json);
}

DaLiuRenResult _buildV3(DaLiuRenResult source) => DaLiuRenResult.fromJson(
      legacyShenJiangResultJson(
        source,
        id: '${source.id}_v3_old_shenjiang',
      ),
    );

Future<File> _rewriteDlrCompatibilityShapes(
  File source,
  Directory directory, {
  required String v1Id,
  required String legacyId,
  required String v3Id,
}) async {
  final decoded = ZipDecoder().decodeBytes(await source.readAsBytes());
  final rewritten = Archive();

  for (final entry in decoded.files) {
    if (entry.name != 'records.json') {
      final bytes = List<int>.from(entry.content as List);
      rewritten.addFile(ArchiveFile(entry.name, bytes.length, bytes));
      continue;
    }

    final payload = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(entry.content as List<int>)) as Map,
    );
    final records = List<Map<String, dynamic>>.from(
      (payload['records'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    for (final record in records) {
      final result = Map<String, dynamic>.from(record['result'] as Map);
      if (result['id'] == v1Id) {
        final snapshot =
            Map<String, dynamic>.from(result['castInputSnapshot'] as Map);
        snapshot['castTime'] = '2022-04-20T10:24:18.000';
        result['castInputSnapshot'] = snapshot;
      } else if (result['id'] == legacyId) {
        result
          ..remove('panRuleSetVersion')
          ..remove('evidenceCatalogVersion')
          ..remove('castInputSnapshot')
          ..remove('civilTime')
          ..remove('monthGeneralResolution')
          ..remove('recastFromId');
      } else if (result['id'] == v3Id) {
        result['shenJiangConfig'] = legacyShenJiangConfigJson(result);
      }
      record['result'] = result;
    }
    final bytes = utf8.encode(jsonEncode(<String, dynamic>{
      'records': records,
    }));
    rewritten.addFile(ArchiveFile(entry.name, bytes.length, bytes));
  }

  final output = File(
    '${directory.path}${Platform.pathSeparator}legacy_shapes_${source.uri.pathSegments.last}',
  );
  await output.writeAsBytes(ZipEncoder().encode(rewritten)!);
  return output;
}

class _Harness {
  const _Harness({
    required this.database,
    required this.repository,
    required this.service,
  });

  final AppDatabase database;
  final DivinationRepositoryImpl repository;
  final DataManagementService service;
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async =>
      <String, String>{
        for (final key in keys)
          if (_values[key] case final String value) key: value,
      };

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
