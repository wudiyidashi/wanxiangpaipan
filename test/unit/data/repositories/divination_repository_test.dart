import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

/// Mock SecureStorage（用于测试）
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final results = <String, String>{};
    for (final key in keys) {
      final value = _storage[key];
      if (value != null) {
        results[key] = value;
      }
    }
    return results;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }
}

void main() {
  group('DivinationRepositoryImpl', () {
    late AppDatabase database;
    late MockSecureStorage secureStorage;
    late DivinationRegistry registry;
    late DivinationRepositoryImpl repository;

    setUp(() {
      // 创建内存数据库用于测试
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = MockSecureStorage();
      registry = DivinationRegistry();
      registry.clear();
      registry.register(LiuYaoSystem());

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

    group('保存和查询记录', () {
      test('应该成功保存占卜记录', () async {
        final result = _createMockLiuYaoResult();

        final id = await repository.saveRecord(result);

        expect(id, result.id);

        // 验证记录已保存
        final retrieved = await repository.getRecordById(id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, result.id);
        expect(retrieved.systemType, DivinationType.liuYao);
      });

      test('应该能够查询所有记录', () async {
        final result1 = _createMockLiuYaoResult(id: 'id1');
        final result2 = _createMockLiuYaoResult(id: 'id2');

        await repository.saveRecord(result1);
        await repository.saveRecord(result2);

        final allRecords = await repository.getAllRecords();

        expect(allRecords.length, 2);
      });

      test('应该按时间倒序返回记录', () async {
        final result1 = _createMockLiuYaoResult(
          id: 'id1',
          castTime: DateTime(2025, 1, 1),
        );
        final result2 = _createMockLiuYaoResult(
          id: 'id2',
          castTime: DateTime(2025, 1, 15),
        );

        await repository.saveRecord(result1);
        await repository.saveRecord(result2);

        final allRecords = await repository.getAllRecords();

        expect(allRecords.first.id, 'id2'); // 最新的在前面
        expect(allRecords.last.id, 'id1');
      });

      test('应该根据 ID 查询记录', () async {
        final result = _createMockLiuYaoResult(id: 'test-id');

        await repository.saveRecord(result);

        final retrieved = await repository.getRecordById('test-id');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'test-id');
      });

      test('应该在记录不存在时返回 null', () async {
        final retrieved = await repository.getRecordById('non-existent-id');
        expect(retrieved, isNull);
      });
    });

    group('根据系统类型查询', () {
      test('应该根据系统类型查询记录', () async {
        final liuyaoResult = _createMockLiuYaoResult(id: 'liuyao-1');

        await repository.saveRecord(liuyaoResult);

        final liuyaoRecords =
            await repository.getRecordsBySystemType(DivinationType.liuYao);

        expect(liuyaoRecords.length, 1);
        expect(liuyaoRecords.first.systemType, DivinationType.liuYao);
      });

      test('应该在没有该系统类型的记录时返回空列表', () async {
        final records =
            await repository.getRecordsBySystemType(DivinationType.daLiuRen);
        expect(records, isEmpty);
      });
    });

    group('根据起卦方式查询', () {
      test('应该根据起卦方式查询记录', () async {
        final coinResult = _createMockLiuYaoResult(
          id: 'coin-1',
          castMethod: CastMethod.coin,
        );
        final timeResult = _createMockLiuYaoResult(
          id: 'time-1',
          castMethod: CastMethod.time,
        );

        await repository.saveRecord(coinResult);
        await repository.saveRecord(timeResult);

        final coinRecords =
            await repository.getRecordsByCastMethod(CastMethod.coin);

        expect(coinRecords.length, 1);
        expect(coinRecords.first.castMethod, CastMethod.coin);
      });
    });

    group('时间范围查询', () {
      test('应该根据时间范围查询记录', () async {
        final result1 = _createMockLiuYaoResult(
          id: 'id1',
          castTime: DateTime(2025, 1, 1),
        );
        final result2 = _createMockLiuYaoResult(
          id: 'id2',
          castTime: DateTime(2025, 1, 15),
        );
        final result3 = _createMockLiuYaoResult(
          id: 'id3',
          castTime: DateTime(2025, 2, 1),
        );

        await repository.saveRecord(result1);
        await repository.saveRecord(result2);
        await repository.saveRecord(result3);

        final records = await repository.getRecordsByTimeRange(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        expect(records.length, 2);
        expect(records.map((r) => r.id), containsAll(['id1', 'id2']));
      });
    });

    group('分页查询', () {
      test('应该支持分页查询', () async {
        // 创建 5 条记录
        for (int i = 0; i < 5; i++) {
          await repository.saveRecord(_createMockLiuYaoResult(id: 'id$i'));
        }

        // 第一页（2 条）
        final page1 = await repository.getRecordsPaginated(limit: 2, offset: 0);
        expect(page1.length, 2);

        // 第二页（2 条）
        final page2 = await repository.getRecordsPaginated(limit: 2, offset: 2);
        expect(page2.length, 2);

        // 第三页（1 条）
        final page3 = await repository.getRecordsPaginated(limit: 2, offset: 4);
        expect(page3.length, 1);
      });
    });

    group('统计操作', () {
      test('应该正确统计记录总数', () async {
        expect(await repository.getRecordCount(), 0);

        await repository.saveRecord(_createMockLiuYaoResult(id: 'id1'));
        expect(await repository.getRecordCount(), 1);

        await repository.saveRecord(_createMockLiuYaoResult(id: 'id2'));
        expect(await repository.getRecordCount(), 2);
      });

      test('应该根据系统类型统计记录数', () async {
        await repository.saveRecord(_createMockLiuYaoResult(id: 'id1'));
        await repository.saveRecord(_createMockLiuYaoResult(id: 'id2'));

        final count =
            await repository.getRecordCountBySystemType(DivinationType.liuYao);
        expect(count, 2);
      });

      test('应该获取最新的记录', () async {
        final result1 = _createMockLiuYaoResult(
          id: 'id1',
          castTime: DateTime(2025, 1, 1),
        );
        final result2 = _createMockLiuYaoResult(
          id: 'id2',
          castTime: DateTime(2025, 1, 15),
        );

        await repository.saveRecord(result1);
        await repository.saveRecord(result2);

        final latest = await repository.getLatestRecord();

        expect(latest, isNotNull);
        expect(latest!.id, 'id2');
      });

      test('应该获取最近的 N 条记录', () async {
        for (int i = 0; i < 5; i++) {
          await repository.saveRecord(_createMockLiuYaoResult(id: 'id$i'));
        }

        final recent = await repository.getRecentRecords(3);

        expect(recent.length, 3);
      });

      test('应该检查记录是否存在', () async {
        final result = _createMockLiuYaoResult(id: 'test-id');
        await repository.saveRecord(result);

        expect(await repository.recordExists('test-id'), true);
        expect(await repository.recordExists('non-existent'), false);
      });
    });

    group('更新操作', () {
      test('应该成功更新记录', () async {
        final result = _createMockLiuYaoResult(id: 'test-id');
        await repository.saveRecord(result);

        // 创建更新后的结果
        final updatedResult = result.copyWith(
          castMethod: CastMethod.time,
        );

        final success = await repository.updateRecord(updatedResult);

        expect(success, true);

        // 验证更新
        final retrieved = await repository.getRecordById('test-id');
        expect(retrieved!.castMethod, CastMethod.time);
      });
    });

    group('删除操作', () {
      test('应该成功删除记录', () async {
        final result = _createMockLiuYaoResult(id: 'test-id');
        await repository.saveRecord(result);

        final count = await repository.deleteRecord('test-id');

        expect(count, 1);
        expect(await repository.recordExists('test-id'), false);
      });

      test('应该删除记录时同时删除加密字段', () async {
        final result = _createMockLiuYaoResult(id: 'test-id');
        await repository.saveRecord(result);

        // 保存加密字段
        await repository.saveEncryptedField('question_test-id', '测试问题');
        await repository.saveEncryptedField('detail_test-id', '测试详情');

        // 删除记录
        await repository.deleteRecord('test-id');

        // 验证加密字段也被删除
        expect(await repository.readEncryptedField('question_test-id'), isNull);
        expect(await repository.readEncryptedField('detail_test-id'), isNull);
      });

      test('应该根据系统类型删除记录', () async {
        await repository.saveRecord(_createMockLiuYaoResult(id: 'id1'));
        await repository.saveRecord(_createMockLiuYaoResult(id: 'id2'));

        final count =
            await repository.deleteRecordsBySystemType(DivinationType.liuYao);

        expect(count, 2);
        expect(await repository.getRecordCount(), 0);
      });

      test('应该删除所有记录', () async {
        await repository.saveRecord(_createMockLiuYaoResult(id: 'id1'));
        await repository.saveRecord(_createMockLiuYaoResult(id: 'id2'));

        final count = await repository.deleteAllRecords();

        expect(count, 2);
        expect(await repository.getRecordCount(), 0);
      });
    });

    group('加密字段操作', () {
      test('应该成功保存和读取加密字段', () async {
        await repository.saveEncryptedField('test-key', 'test-value');

        final value = await repository.readEncryptedField('test-key');

        expect(value, 'test-value');
      });

      test('应该在字段不存在时返回 null', () async {
        final value = await repository.readEncryptedField('non-existent');
        expect(value, isNull);
      });

      test('应该成功删除加密字段', () async {
        await repository.saveEncryptedField('test-key', 'test-value');
        await repository.deleteEncryptedField('test-key');

        final value = await repository.readEncryptedField('test-key');
        expect(value, isNull);
      });

      test('应该批量保存加密字段', () async {
        final fields = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        };

        await repository.saveEncryptedFieldsBatch(fields);

        expect(await repository.readEncryptedField('key1'), 'value1');
        expect(await repository.readEncryptedField('key2'), 'value2');
        expect(await repository.readEncryptedField('key3'), 'value3');
      });

      test('应该批量读取加密字段', () async {
        await repository.saveEncryptedField('key1', 'value1');
        await repository.saveEncryptedField('key2', 'value2');

        final results =
            await repository.readEncryptedFieldsBatch(['key1', 'key2', 'key3']);

        expect(results['key1'], 'value1');
        expect(results['key2'], 'value2');
        expect(results['key3'], isNull);
      });

      test('应该批量删除加密字段', () async {
        await repository.saveEncryptedField('key1', 'value1');
        await repository.saveEncryptedField('key2', 'value2');

        await repository.deleteEncryptedFieldsBatch(['key1', 'key2']);

        expect(await repository.readEncryptedField('key1'), isNull);
        expect(await repository.readEncryptedField('key2'), isNull);
      });
    });

    group('搜索操作', () {
      test('应该根据多个条件搜索记录', () async {
        final result1 = _createMockLiuYaoResult(
          id: 'id1',
          castMethod: CastMethod.coin,
          castTime: DateTime(2025, 1, 1),
        );
        final result2 = _createMockLiuYaoResult(
          id: 'id2',
          castMethod: CastMethod.time,
          castTime: DateTime(2025, 1, 15),
        );

        await repository.saveRecord(result1);
        await repository.saveRecord(result2);

        // 搜索摇钱法的记录
        final coinRecords = await repository.searchRecords(
          castMethod: CastMethod.coin,
        );

        expect(coinRecords.length, 1);
        expect(coinRecords.first.castMethod, CastMethod.coin);

        // 搜索指定时间范围的记录
        final timeRangeRecords = await repository.searchRecords(
          startTime: DateTime(2025, 1, 10),
          endTime: DateTime(2025, 1, 20),
        );

        expect(timeRangeRecords.length, 1);
        expect(timeRangeRecords.first.id, 'id2');
      });
    });

    group('数据转换', () {
      test('应该正确序列化和反序列化占卜结果', () async {
        final originalResult = _createMockLiuYaoResult();

        await repository.saveRecord(originalResult);

        final retrieved = await repository.getRecordById(originalResult.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, originalResult.id);
        expect(retrieved.systemType, originalResult.systemType);
        expect(retrieved.castMethod, originalResult.castMethod);
        expect(retrieved.castTime, originalResult.castTime);

        // 验证六爻特定数据
        final liuyaoResult = retrieved as LiuYaoResult;
        expect(liuyaoResult.mainGua.name, originalResult.mainGua.name);
        expect(liuyaoResult.liuShen, originalResult.liuShen);
      });
    });
  });
}

/// 创建 Mock 六爻结果（用于测试）
LiuYaoResult _createMockLiuYaoResult({
  String? id,
  CastMethod castMethod = CastMethod.coin,
  DateTime? castTime,
}) {
  return LiuYaoResult(
    id: id ?? 'mock-id',
    castTime: castTime ?? DateTime(2025, 1, 15),
    castMethod: castMethod,
    mainGua: _createMockGua(),
    changingGua: null,
    lunarInfo: const LunarInfo(
      yueJian: '寅',
      riGan: '甲',
      riZhi: '子',
      riGanZhi: '甲子',
      kongWang: ['戌', '亥'],
      yearGanZhi: '甲子',
      monthGanZhi: '丙寅',
    ),
    liuShen: ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
  );
}

/// 创建 Mock 卦象（用于测试）
Gua _createMockGua() {
  final yaos = List.generate(
    6,
    (i) => Yao(
      position: i + 1,
      number: YaoNumber.shaoYang,
      branch: '子',
      stem: '甲',
      liuQin: LiuQin.fuMu,
      wuXing: WuXing.shui,
      isSeYao: i == 4,
      isYingYao: i == 1,
    ),
  );

  return Gua(
    id: 'mock-gua-id',
    yaos: yaos,
    name: '天雷无妄',
    baGong: BaGong.qian,
    seYaoPosition: 5,
    yingYaoPosition: 2,
  );
}
