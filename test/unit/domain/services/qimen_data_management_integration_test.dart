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
import 'package:wanxiang_paipan/divination_systems/meihua/meihua_system.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/data_management_service.dart';

import '../../services/qimen/fixtures/qimen_golden_fixtures.dart';

void main() {
  group('Qimen data management integration', () {
    late DivinationRegistry registry;
    final harnesses = <_Harness>[];
    final tempDirectories = <Directory>[];

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      registry = DivinationRegistry()..clear();
      registry
        ..register(QimenSystem())
        ..register(MeiHuaSystem());
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

    Future<Directory> createTempDirectory(String prefix) async {
      final directory = await Directory.systemTemp.createTemp(prefix);
      tempDirectories.add(directory);
      return directory;
    }

    test('export/import preserves the full Qimen result and encrypted fields',
        () async {
      final source = await createHarness();
      final target = await createHarness();
      final original = await _castQimen(DateTime.utc(2026, 7, 7, 4));
      await source.repository.saveRecord(original);
      await source.repository.saveEncryptedFieldsBatch(<String, String>{
        'question_${original.id}': '奇门备份占问',
        'detail_${original.id}': '奇门备份详情',
        'interpretation_${original.id}': '奇门备份解读',
      });

      final directory = await createTempDirectory('qimen_backup_roundtrip_');
      final exported =
          await source.service.exportBackup(outputDirectory: directory);
      final imported = await target.service.importBackup(
        File(exported.filePath),
        mode: BackupImportMode.merge,
      );

      final restored =
          await target.repository.getRecordById(original.id) as QimenResult?;
      final summary = await target.service.loadSummary();
      expect(imported.recordCount, 1);
      expect(restored, isNotNull);
      expect(restored!.toJson(), original.toJson());
      expect(summary.totalRecords, 1);
      expect(summary.qimenCount, 1);
      expect(
        await target.repository.readEncryptedField('question_${original.id}'),
        '奇门备份占问',
      );
      expect(
        await target.repository.readEncryptedField('detail_${original.id}'),
        '奇门备份详情',
      );
      expect(
        await target.repository
            .readEncryptedField('interpretation_${original.id}'),
        '奇门备份解读',
      );
    });

    test('unknown system record is reported and skipped during overwrite',
        () async {
      final harness = await createHarness();
      final original = await _castQimen(DateTime.utc(2026, 7, 7, 4));
      await harness.repository.saveRecord(original);
      final directory = await createTempDirectory('qimen_unknown_system_');
      final exported =
          await harness.service.exportBackup(outputDirectory: directory);
      final corrupted = await _rewriteRecords(
        File(exported.filePath),
        directory,
        (records) => records..first['systemType'] = 'future-system',
      );

      final imported = await harness.service.importBackup(
        corrupted,
        mode: BackupImportMode.overwrite,
      );

      expect(imported.recordCount, 0);
      expect(imported.skippedRecordCount, 1);
      expect(imported.skippedRecords.single.identifier, original.id);
      expect(imported.skippedRecords.single.reason, contains('Unknown'));
      expect(await harness.repository.recordExists(original.id), isFalse);
      expect(await harness.repository.getRecordCount(), 0);
    });

    test('future Qimen schema record is reported and skipped during overwrite',
        () async {
      final harness = await createHarness();
      final original = await _castQimen(DateTime.utc(2026, 7, 7, 4));
      await harness.repository.saveRecord(original);
      final directory = await createTempDirectory('qimen_future_schema_');
      final exported =
          await harness.service.exportBackup(outputDirectory: directory);
      final corrupted = await _rewriteRecords(
        File(exported.filePath),
        directory,
        (records) {
          final result = Map<String, dynamic>.from(
            records.first['result'] as Map,
          );
          records.first['result'] = result..['schemaVersion'] = 2;
        },
      );

      final imported = await harness.service.importBackup(
        corrupted,
        mode: BackupImportMode.overwrite,
      );

      expect(imported.recordCount, 0);
      expect(imported.skippedRecordCount, 1);
      expect(imported.skippedRecords.single.identifier, original.id);
      expect(imported.skippedRecords.single.reason, contains('schemaVersion'));
      expect(await harness.repository.getRecordById(original.id), isNull);
    });

    test('Qimen clear removes only Qimen rows and associated secure fields',
        () async {
      final harness = await createHarness();
      final qimen = await _castQimen(DateTime.utc(2026, 7, 7, 4));
      final meihua = await MeiHuaSystem().cast(
        method: CastMethod.time,
        input: const <String, dynamic>{},
        castTime: DateTime.utc(2026, 7, 8, 4),
      );
      await harness.repository.saveRecord(qimen);
      await harness.repository.saveRecord(meihua);
      await harness.repository.saveEncryptedFieldsBatch(<String, String>{
        'question_${qimen.id}': '应删除',
        'conversation_${qimen.id}': '应删除会话',
        'question_${meihua.id}': '应保留',
      });

      final deleted =
          await harness.service.clearHistoryBySystem(DivinationType.qiMen);
      final summary = await harness.service.loadSummary();

      expect(deleted, 1);
      expect(await harness.repository.recordExists(qimen.id), isFalse);
      expect(await harness.repository.recordExists(meihua.id), isTrue);
      expect(summary.totalRecords, 1);
      expect(summary.qimenCount, 0);
      expect(summary.meihuaCount, 1);
      expect(
        await harness.repository.readEncryptedField('question_${qimen.id}'),
        isNull,
      );
      expect(
        await harness.repository.readEncryptedField('conversation_${qimen.id}'),
        isNull,
      );
      expect(
        await harness.repository.readEncryptedField('question_${meihua.id}'),
        '应保留',
      );
    });
  });
}

Future<QimenResult> _castQimen(DateTime castTime) async {
  return await QimenSystem().cast(
    method: CastMethod.manual,
    input: qimenManualGoldenInput,
    castTime: castTime,
  ) as QimenResult;
}

Future<File> _rewriteRecords(
  File source,
  Directory directory,
  void Function(List<Map<String, dynamic>> records) mutate,
) async {
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
    mutate(records);
    final bytes = utf8.encode(jsonEncode(<String, dynamic>{
      'records': records,
    }));
    rewritten.addFile(ArchiveFile(entry.name, bytes.length, bytes));
  }

  final output = File(
    '${directory.path}${Platform.pathSeparator}corrupted_${source.uri.pathSegments.last}',
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
