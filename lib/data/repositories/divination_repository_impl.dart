import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../domain/divination_system.dart';
import '../../domain/repositories/divination_repository.dart';
import '../../domain/divination_registry.dart';
import '../database/app_database.dart';
import '../secure/secure_storage.dart';

/// 占卜记录仓库实现
///
/// 实现 DivinationRepository 接口，提供数据持久化功能。
/// 使用 Drift 数据库存储占卜记录，使用 SecureStorage 存储加密字段。
class DivinationRepositoryImpl implements DivinationRepository {
  final AppDatabase _database;
  final SecureStorage _secureStorage;
  final DivinationRegistry _registry;

  DivinationRepositoryImpl({
    required AppDatabase database,
    required SecureStorage secureStorage,
    required DivinationRegistry registry,
  })  : _database = database,
        _secureStorage = secureStorage,
        _registry = registry;

  // ==================== 查询操作 ====================

  @override
  Future<List<DivinationResult>> getAllRecords() async {
    final records = await _database.divinationRecordDao.getAllRecords();
    return _convertRecordsToResults(records);
  }

  @override
  Future<DivinationResult?> getRecordById(String id) async {
    final record = await _database.divinationRecordDao.getRecordById(id);
    if (record == null) return null;
    return _convertRecordToResult(record);
  }

  @override
  Future<List<DivinationResult>> getRecordsBySystemType(
      DivinationType systemType) async {
    final records = await _database.divinationRecordDao
        .getRecordsBySystemType(systemType.name);
    return _convertRecordsToResults(records);
  }

  @override
  Future<List<DivinationResult>> getRecordsByCastMethod(
      CastMethod castMethod) async {
    final records = await _database.divinationRecordDao
        .getRecordsByCastMethod(castMethod.name);
    return _convertRecordsToResults(records);
  }

  @override
  Future<List<DivinationResult>> getRecordsByTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final records = await _database.divinationRecordDao
        .getRecordsByTimeRange(startTime, endTime);
    return _convertRecordsToResults(records);
  }

  @override
  Future<List<DivinationResult>> getRecordsPaginated({
    required int limit,
    required int offset,
  }) async {
    final records = await _database.divinationRecordDao
        .getRecordsPaginated(limit: limit, offset: offset);
    return _convertRecordsToResults(records);
  }

  @override
  Future<int> getRecordCount() async {
    return await _database.divinationRecordDao.getRecordCount();
  }

  @override
  Future<int> getRecordCountBySystemType(DivinationType systemType) async {
    return await _database.divinationRecordDao
        .getRecordCountBySystemType(systemType.name);
  }

  @override
  Future<List<DivinationResult>> getRecentRecords(int limit) async {
    final records = await _database.divinationRecordDao.getRecentRecords(limit);
    return _convertRecordsToResults(records);
  }

  @override
  Future<DivinationResult?> getLatestRecord() async {
    final record = await _database.divinationRecordDao.getLatestRecord();
    if (record == null) return null;
    return _convertRecordToResult(record);
  }

  // ==================== 插入操作 ====================

  @override
  Future<String> saveRecord(DivinationResult result) async {
    final companion = _convertResultToCompanion(result);
    return await _database.divinationRecordDao.insertRecord(companion);
  }

  // ==================== 更新操作 ====================

  @override
  Future<bool> updateRecord(DivinationResult result) async {
    final record = _convertResultToRecord(result);
    return await _database.divinationRecordDao.updateRecord(record);
  }

  // ==================== 删除操作 ====================

  @override
  Future<int> deleteRecord(String id) async {
    // 删除数据库记录
    final count = await _database.divinationRecordDao.deleteRecord(id);

    // 删除关联的加密字段
    await deleteEncryptedFieldsBatch([
      'question_$id',
      'detail_$id',
      'interpretation_$id',
    ]);

    return count;
  }

  @override
  Future<int> deleteAllRecords() async {
    // 删除所有数据库记录
    final count = await _database.divinationRecordDao.deleteAllRecords();

    // 删除所有加密字段
    await _secureStorage.deleteAll();

    return count;
  }

  @override
  Future<int> deleteRecordsBySystemType(DivinationType systemType) async {
    // 获取该系统类型的所有记录 ID
    final records = await getRecordsBySystemType(systemType);
    final ids = records.map((r) => r.id).toList();

    // 删除数据库记录
    final count = await _database.divinationRecordDao
        .deleteRecordsBySystemType(systemType.name);

    // 删除关联的加密字段
    final encryptedKeys = <String>[];
    for (final id in ids) {
      encryptedKeys.addAll([
        'question_$id',
        'detail_$id',
        'interpretation_$id',
      ]);
    }
    await deleteEncryptedFieldsBatch(encryptedKeys);

    return count;
  }

  // ==================== 加密字段操作 ====================

  @override
  Future<void> saveEncryptedField(String key, String value) async {
    await _secureStorage.write(key, value);
  }

  @override
  Future<String?> readEncryptedField(String key) async {
    return await _secureStorage.read(key);
  }

  @override
  Future<void> deleteEncryptedField(String key) async {
    await _secureStorage.delete(key);
  }

  @override
  Future<void> saveEncryptedFieldsBatch(Map<String, String> fields) async {
    for (final entry in fields.entries) {
      await _secureStorage.write(entry.key, entry.value);
    }
  }

  @override
  Future<Map<String, String?>> readEncryptedFieldsBatch(
      List<String> keys) async {
    final results = <String, String?>{};
    for (final key in keys) {
      results[key] = await _secureStorage.read(key);
    }
    return results;
  }

  @override
  Future<void> deleteEncryptedFieldsBatch(List<String> keys) async {
    for (final key in keys) {
      await _secureStorage.delete(key);
    }
  }

  // ==================== 搜索操作 ====================

  @override
  Future<List<DivinationResult>> searchRecords({
    DivinationType? systemType,
    CastMethod? castMethod,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final records = await _database.divinationRecordDao.searchRecords(
      systemType: systemType?.name,
      castMethod: castMethod?.name,
      startTime: startTime,
      endTime: endTime,
    );
    return _convertRecordsToResults(records);
  }

  // ==================== 统计操作 ====================

  @override
  Future<bool> recordExists(String id) async {
    return await _database.divinationRecordDao.recordExists(id);
  }

  // ==================== 私有辅助方法 ====================

  /// 将数据库记录转换为占卜结果
  DivinationResult _convertRecordToResult(DivinationRecord record) {
    // 解析系统类型
    final systemType = DivinationType.values.firstWhere(
      (t) => t.name == record.systemType,
      orElse: () => throw StateError('未知的系统类型: ${record.systemType}'),
    );

    // 获取对应的排盘
    final system = _registry.getSystem(systemType);

    // 解析结果数据
    final resultData = jsonDecode(record.resultData) as Map<String, dynamic>;

    // 使用系统的 resultFromJson 方法恢复结果
    return system.resultFromJson(resultData);
  }

  /// 批量将数据库记录转换为占卜结果
  List<DivinationResult> _convertRecordsToResults(
      List<DivinationRecord> records) {
    return records.map(_convertRecordToResult).toList();
  }

  /// 将占卜结果转换为数据库 Companion
  DivinationRecordsCompanion _convertResultToCompanion(
      DivinationResult result) {
    return DivinationRecordsCompanion(
      id: drift.Value(result.id),
      systemType: drift.Value(result.systemType.name),
      castTime: drift.Value(result.castTime),
      castMethod: drift.Value(result.castMethod.name),
      resultData: drift.Value(jsonEncode(result.toJson())),
      lunarData: drift.Value(jsonEncode(result.lunarInfo.toJson())),
      questionId: const drift.Value(''),
      detailId: const drift.Value(''),
      interpretationId: const drift.Value(''),
      createdAt: drift.Value(DateTime.now()),
      updatedAt: drift.Value(DateTime.now()),
    );
  }

  /// 将占卜结果转换为数据库记录
  DivinationRecord _convertResultToRecord(DivinationResult result) {
    return DivinationRecord(
      id: result.id,
      systemType: result.systemType.name,
      castTime: result.castTime,
      castMethod: result.castMethod.name,
      resultData: jsonEncode(result.toJson()),
      lunarData: jsonEncode(result.lunarInfo.toJson()),
      questionId: '',
      detailId: '',
      interpretationId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
