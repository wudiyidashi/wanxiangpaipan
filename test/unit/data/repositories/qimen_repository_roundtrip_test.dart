import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

import '../../services/qimen/fixtures/qimen_golden_fixtures.dart';
import 'divination_repository_test.dart' show MockSecureStorage;

void main() {
  group('Qimen repository roundtrip', () {
    late AppDatabase database;
    late DivinationRegistry registry;
    late DivinationRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      registry = DivinationRegistry()..clear();
      registry.register(QimenSystem());
      repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: MockSecureStorage(),
        registry: registry,
      );
    });

    tearDown(() async {
      await database.close();
      registry.clear();
    });

    test('save, load, system query, and latest record preserve the full pan',
        () async {
      final result = await QimenSystem().cast(
        method: CastMethod.manual,
        input: qimenManualGoldenInput,
        castTime: DateTime.utc(2026, 7, 7, 4),
      );
      await repository.saveRecord(result);

      final loaded = await repository.getRecordById(result.id) as QimenResult?;
      expect(loaded, isNotNull);
      expect(loaded!.toJson(), result.toJson());

      final bySystem =
          await repository.getRecordsBySystemType(DivinationType.qiMen);
      expect(bySystem, hasLength(1));
      expect(await repository.getLatestRecord(), isA<QimenResult>());
    });
  });
}
