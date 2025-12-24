import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'divination_record_dao.g.dart';

/// 占卜记录 DAO
///
/// 提供对 DivinationRecords 表的数据访问操作。
@DriftAccessor(tables: [DivinationRecords])
class DivinationRecordDao extends DatabaseAccessor<AppDatabase>
    with _$DivinationRecordDaoMixin {
  DivinationRecordDao(AppDatabase db) : super(db);

  // ==================== 查询操作 ====================

  /// 获取所有占卜记录（按时间倒序）
  ///
  /// 返回所有占卜记录，最新的记录在前面。
  Future<List<DivinationRecord>> getAllRecords() {
    return (select(divinationRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 根据 ID 获取占卜记录
  ///
  /// [id] 记录 ID
  /// 返回对应的占卜记录，如果不存在返回 null
  Future<DivinationRecord?> getRecordById(String id) {
    return (select(divinationRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 根据术数系统类型获取记录
  ///
  /// [systemType] 术数系统类型（如 'liuYao'）
  /// 返回该术数系统的所有记录，按时间倒序
  Future<List<DivinationRecord>> getRecordsBySystemType(String systemType) {
    return (select(divinationRecords)
          ..where((t) => t.systemType.equals(systemType))
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 根据起卦方式获取记录
  ///
  /// [castMethod] 起卦方式（如 'coin'）
  /// 返回该起卦方式的所有记录，按时间倒序
  Future<List<DivinationRecord>> getRecordsByCastMethod(String castMethod) {
    return (select(divinationRecords)
          ..where((t) => t.castMethod.equals(castMethod))
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 根据时间范围获取记录
  ///
  /// [startTime] 开始时间
  /// [endTime] 结束时间
  /// 返回指定时间范围内的所有记录，按时间倒序
  Future<List<DivinationRecord>> getRecordsByTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) {
    return (select(divinationRecords)
          ..where((t) =>
              t.castTime.isBiggerOrEqualValue(startTime) &
              t.castTime.isSmallerOrEqualValue(endTime))
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 分页获取记录
  ///
  /// [limit] 每页记录数
  /// [offset] 偏移量
  /// 返回分页后的记录列表
  Future<List<DivinationRecord>> getRecordsPaginated({
    required int limit,
    required int offset,
  }) {
    return (select(divinationRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// 获取记录总数
  ///
  /// 返回数据库中的记录总数
  Future<int> getRecordCount() async {
    final countExp = divinationRecords.id.count();
    final query = selectOnly(divinationRecords)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// 根据术数系统类型获取记录数
  ///
  /// [systemType] 术数系统类型
  /// 返回该术数系统的记录总数
  Future<int> getRecordCountBySystemType(String systemType) async {
    final countExp = divinationRecords.id.count();
    final query = selectOnly(divinationRecords)
      ..addColumns([countExp])
      ..where(divinationRecords.systemType.equals(systemType));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // ==================== 插入操作 ====================

  /// 插入新的占卜记录
  ///
  /// [record] 要插入的记录
  /// 返回插入的记录 ID
  Future<String> insertRecord(DivinationRecordsCompanion record) async {
    await into(divinationRecords).insert(record);
    return record.id.value;
  }

  // ==================== 更新操作 ====================

  /// 更新占卜记录
  ///
  /// [record] 要更新的记录
  /// 返回是否更新成功
  Future<bool> updateRecord(DivinationRecord record) async {
    return await update(divinationRecords).replace(record);
  }

  /// 更新记录的加密字段 ID
  ///
  /// [id] 记录 ID
  /// [questionId] 问事主题加密 ID
  /// [detailId] 详细说明加密 ID
  /// [interpretationId] 个人解读加密 ID
  Future<void> updateEncryptedIds({
    required String id,
    String? questionId,
    String? detailId,
    String? interpretationId,
  }) async {
    await (update(divinationRecords)..where((t) => t.id.equals(id))).write(
      DivinationRecordsCompanion(
        questionId: questionId != null ? Value(questionId) : const Value.absent(),
        detailId: detailId != null ? Value(detailId) : const Value.absent(),
        interpretationId:
            interpretationId != null ? Value(interpretationId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ==================== 删除操作 ====================

  /// 删除占卜记录
  ///
  /// [id] 记录 ID
  /// 返回删除的记录数
  Future<int> deleteRecord(String id) {
    return (delete(divinationRecords)..where((t) => t.id.equals(id))).go();
  }

  /// 删除所有记录
  ///
  /// 警告：此操作会删除所有占卜记录，通常仅用于测试或清理
  /// 返回删除的记录数
  Future<int> deleteAllRecords() {
    return delete(divinationRecords).go();
  }

  /// 删除指定术数系统的所有记录
  ///
  /// [systemType] 术数系统类型
  /// 返回删除的记录数
  Future<int> deleteRecordsBySystemType(String systemType) {
    return (delete(divinationRecords)
          ..where((t) => t.systemType.equals(systemType)))
        .go();
  }

  /// 删除指定时间之前的记录
  ///
  /// [beforeTime] 时间阈值
  /// 返回删除的记录数
  Future<int> deleteRecordsBeforeTime(DateTime beforeTime) {
    return (delete(divinationRecords)
          ..where((t) => t.castTime.isSmallerThanValue(beforeTime)))
        .go();
  }

  // ==================== 搜索操作 ====================

  /// 搜索记录（根据多个条件）
  ///
  /// [systemType] 术数系统类型（可选）
  /// [castMethod] 起卦方式（可选）
  /// [startTime] 开始时间（可选）
  /// [endTime] 结束时间（可选）
  /// 返回符合条件的记录列表
  Future<List<DivinationRecord>> searchRecords({
    String? systemType,
    String? castMethod,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final query = select(divinationRecords);

    if (systemType != null) {
      query.where((t) => t.systemType.equals(systemType));
    }

    if (castMethod != null) {
      query.where((t) => t.castMethod.equals(castMethod));
    }

    if (startTime != null) {
      query.where((t) => t.castTime.isBiggerOrEqualValue(startTime));
    }

    if (endTime != null) {
      query.where((t) => t.castTime.isSmallerOrEqualValue(endTime));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
    ]);

    return query.get();
  }

  // ==================== 统计操作 ====================

  /// 获取最近的 N 条记录
  ///
  /// [limit] 记录数量
  /// 返回最近的记录列表
  Future<List<DivinationRecord>> getRecentRecords(int limit) {
    return (select(divinationRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  /// 获取最早的记录
  ///
  /// 返回最早的占卜记录，如果没有记录返回 null
  Future<DivinationRecord?> getEarliestRecord() {
    return (select(divinationRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.asc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取最新的记录
  ///
  /// 返回最新的占卜记录，如果没有记录返回 null
  Future<DivinationRecord?> getLatestRecord() {
    return (select(divinationRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 检查记录是否存在
  ///
  /// [id] 记录 ID
  /// 返回 true 如果记录存在，否则返回 false
  Future<bool> recordExists(String id) async {
    final record = await getRecordById(id);
    return record != null;
  }

  // ==================== 批量操作 ====================

  /// 批量插入记录
  ///
  /// [records] 要插入的记录列表
  Future<void> insertRecordsBatch(
      List<DivinationRecordsCompanion> records) async {
    await batch((batch) {
      batch.insertAll(divinationRecords, records);
    });
  }

  /// 批量删除记录
  ///
  /// [ids] 要删除的记录 ID 列表
  /// 返回删除的记录数
  Future<int> deleteRecordsBatch(List<String> ids) async {
    return await (delete(divinationRecords)
          ..where((t) => t.id.isIn(ids)))
        .go();
  }
}
