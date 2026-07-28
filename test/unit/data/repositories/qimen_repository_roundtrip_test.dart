import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_result_screen.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_ui_factory.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';

import '../../services/qimen/fixtures/qimen_golden_fixtures.dart';
import 'divination_repository_test.dart' show MockSecureStorage;

void main() {
  group('Qimen repository roundtrip', () {
    late AppDatabase database;
    late DivinationRegistry registry;
    late DivinationUIRegistry uiRegistry;
    late DivinationRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      registry = DivinationRegistry()..clear();
      registry.register(QimenSystem());
      uiRegistry = DivinationUIRegistry()..clear();
      uiRegistry.registerUI(QimenUIFactory());
      repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: MockSecureStorage(),
        registry: registry,
      );
    });

    tearDown(() async {
      await database.close();
      registry.clear();
      uiRegistry.clear();
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

      final analysis = QimenAnalyzer.analyze(
        loaded,
        ruleSetVersion: QimenRuleCatalog.v1,
      );
      expect(analysis.status, QimenAnalysisStatus.complete);
      expect(analysis.inputResultId, loaded.id);
      expect(loaded.toJson(), isNot(contains('analysis')));

      final bySystem =
          await repository.getRecordsBySystemType(DivinationType.qiMen);
      expect(bySystem, hasLength(1));
      expect(await repository.getLatestRecord(), isA<QimenResult>());
    });

    test('recent/filter queries and UI reopen use the restored Qimen result',
        () async {
      final older = await QimenSystem().cast(
        method: CastMethod.manual,
        input: qimenManualGoldenInput,
        castTime: DateTime.utc(2026, 7, 7, 4),
      );
      final newer = await QimenSystem().cast(
        method: CastMethod.time,
        input: qimenPublicGoldenTimeInput,
        castTime: DateTime.utc(2026, 7, 8, 4),
      );
      await repository.saveRecord(older);
      await repository.saveRecord(newer);

      final recent = await repository.getRecentRecords(1);
      final manual = await repository.getRecordsByCastMethod(CastMethod.manual);
      final searched = await repository.searchRecords(
        systemType: DivinationType.qiMen,
        castMethod: CastMethod.time,
      );

      expect(recent.single.id, newer.id);
      expect(manual.map((result) => result.id), contains(older.id));
      expect(searched.map((result) => result.id), [newer.id]);

      final reopened = await repository.getRecordById(newer.id) as QimenResult?;
      expect(reopened, isNotNull);
      expect(reopened!.toJson(), newer.toJson());
      expect(
        uiRegistry.buildResultScreen(reopened),
        isA<QimenResultScreen>(),
      );
    });
  });
}
