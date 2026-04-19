import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';

import 'divination_repository_test.dart' show MockSecureStorage;

/// 小六壬 repo 层 save/read 完整回环
///
/// 验证 UI → saveRecord → DAO → getAllRecords/getRecentRecords →
/// _tryConvertRecordToResult → XiaoLiuRenResult.fromJson 链路不吞记录。
void main() {
  group('XiaoLiuRen repository roundtrip', () {
    late AppDatabase database;
    late MockSecureStorage secureStorage;
    late DivinationRegistry registry;
    late DivinationRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = MockSecureStorage();
      registry = DivinationRegistry();
      registry.clear();
      registry.register(XiaoLiuRenSystem());

      repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: secureStorage,
        registry: registry,
      );
    });

    tearDown(() async {
      await database.close();
      registry.clear();
    });

    test('时间起六宫：保存后能通过 getAllRecords 拉回', () async {
      final system = XiaoLiuRenSystem();
      final cast = await system.cast(
        method: CastMethod.time,
        input: const {},
        castTime: DateTime(2026, 4, 19, 9, 22),
      );

      await repository.saveRecord(cast);

      final all = await repository.getAllRecords();
      expect(all, hasLength(1));
      final loaded = all.first;
      expect(loaded, isA<XiaoLiuRenResult>());
      final xiao = loaded as XiaoLiuRenResult;
      expect(xiao.finalPosition.name, '赤口');
      expect(xiao.palaceMode, XiaoLiuRenPalaceMode.sixPalaces);
      expect(xiao.getSummary(), '赤口 · 口舌是非');
    });

    test('getRecentRecords(1) 能拾取最新的小六壬记录', () async {
      final system = XiaoLiuRenSystem();
      final cast = await system.cast(
        method: CastMethod.reportNumber,
        input: const {
          'firstNumber': 4,
          'secondNumber': 18,
          'thirdNumber': 7,
        },
        castTime: DateTime(2026, 4, 19, 9, 22),
      );
      await repository.saveRecord(cast);

      final recent = await repository.getRecentRecords(1);
      expect(recent, hasLength(1));
      expect(recent.first, isA<XiaoLiuRenResult>());
    });

    test('getRecordsBySystemType(xiaoLiuRen) 返回小六壬记录', () async {
      final system = XiaoLiuRenSystem();
      final cast = await system.cast(
        method: CastMethod.characterStroke,
        input: const {
          'firstStroke': 8,
          'secondStroke': 11,
          'thirdStroke': 6,
        },
        castTime: DateTime(2026, 4, 19, 9, 22),
      );
      await repository.saveRecord(cast);

      final filtered =
          await repository.getRecordsBySystemType(DivinationType.xiaoLiuRen);
      expect(filtered, hasLength(1));
    });

    test('九宫记录也能完整回环', () async {
      final system = XiaoLiuRenSystem();
      final cast = await system.cast(
        method: CastMethod.time,
        input: const {'palaceMode': 'ninePalaces'},
        castTime: DateTime(2026, 4, 19, 9, 22),
      );
      await repository.saveRecord(cast);

      final all = await repository.getAllRecords();
      expect(all, hasLength(1));
      final xiao = all.first as XiaoLiuRenResult;
      expect(xiao.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
      expect(xiao.finalPosition.name, '大安');
    });
  });
}
