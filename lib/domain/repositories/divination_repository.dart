import '../divination_system.dart';

/// 占卜记录仓库接口
///
/// 定义占卜记录的数据访问操作，支持多术数系统。
/// 这是 Domain 层的接口，不依赖具体的数据存储实现。
abstract class DivinationRepository {
  // ==================== 查询操作 ====================

  /// 获取所有占卜记录（按时间倒序）
  ///
  /// 返回所有占卜记录，最新的记录在前面。
  Future<List<DivinationResult>> getAllRecords();

  /// 根据 ID 获取占卜记录
  ///
  /// [id] 记录 ID
  /// 返回对应的占卜结果，如果不存在返回 null
  Future<DivinationResult?> getRecordById(String id);

  /// 根据术数系统类型获取记录
  ///
  /// [systemType] 术数系统类型
  /// 返回该术数系统的所有记录，按时间倒序
  Future<List<DivinationResult>> getRecordsBySystemType(
      DivinationType systemType);

  /// 根据起卦方式获取记录
  ///
  /// [castMethod] 起卦方式
  /// 返回该起卦方式的所有记录，按时间倒序
  Future<List<DivinationResult>> getRecordsByCastMethod(CastMethod castMethod);

  /// 根据时间范围获取记录
  ///
  /// [startTime] 开始时间
  /// [endTime] 结束时间
  /// 返回指定时间范围内的所有记录，按时间倒序
  Future<List<DivinationResult>> getRecordsByTimeRange(
    DateTime startTime,
    DateTime endTime,
  );

  /// 分页获取记录
  ///
  /// [limit] 每页记录数
  /// [offset] 偏移量
  /// 返回分页后的记录列表
  Future<List<DivinationResult>> getRecordsPaginated({
    required int limit,
    required int offset,
  });

  /// 获取记录总数
  ///
  /// 返回数据库中的记录总数
  Future<int> getRecordCount();

  /// 根据术数系统类型获取记录数
  ///
  /// [systemType] 术数系统类型
  /// 返回该术数系统的记录总数
  Future<int> getRecordCountBySystemType(DivinationType systemType);

  /// 获取最近的 N 条记录
  ///
  /// [limit] 记录数量
  /// 返回最近的记录列表
  Future<List<DivinationResult>> getRecentRecords(int limit);

  /// 获取最新的记录
  ///
  /// 返回最新的占卜记录，如果没有记录返回 null
  Future<DivinationResult?> getLatestRecord();

  // ==================== 插入操作 ====================

  /// 保存占卜记录
  ///
  /// [result] 占卜结果
  /// 返回保存的记录 ID
  Future<String> saveRecord(DivinationResult result);

  // ==================== 更新操作 ====================

  /// 更新占卜记录
  ///
  /// [result] 要更新的占卜结果
  /// 返回是否更新成功
  Future<bool> updateRecord(DivinationResult result);

  // ==================== 删除操作 ====================

  /// 删除占卜记录
  ///
  /// [id] 记录 ID
  /// 返回删除的记录数
  Future<int> deleteRecord(String id);

  /// 删除所有记录
  ///
  /// 警告：此操作会删除所有占卜记录，通常仅用于测试或清理
  /// 返回删除的记录数
  Future<int> deleteAllRecords();

  /// 删除指定术数系统的所有记录
  ///
  /// [systemType] 术数系统类型
  /// 返回删除的记录数
  Future<int> deleteRecordsBySystemType(DivinationType systemType);

  // ==================== 加密字段操作 ====================

  /// 保存加密字段
  ///
  /// [key] 加密字段的键（如 'question_xxx'）
  /// [value] 要加密存储的值
  Future<void> saveEncryptedField(String key, String value);

  /// 读取加密字段
  ///
  /// [key] 加密字段的键
  /// 返回解密后的值，如果不存在返回 null
  Future<String?> readEncryptedField(String key);

  /// 删除加密字段
  ///
  /// [key] 加密字段的键
  Future<void> deleteEncryptedField(String key);

  /// 批量保存加密字段
  ///
  /// [fields] 键值对映射
  Future<void> saveEncryptedFieldsBatch(Map<String, String> fields);

  /// 批量读取加密字段
  ///
  /// [keys] 键列表
  /// 返回键值对映射
  Future<Map<String, String?>> readEncryptedFieldsBatch(List<String> keys);

  /// 批量删除加密字段
  ///
  /// [keys] 键列表
  Future<void> deleteEncryptedFieldsBatch(List<String> keys);

  // ==================== 搜索操作 ====================

  /// 搜索记录（根据多个条件）
  ///
  /// [systemType] 术数系统类型（可选）
  /// [castMethod] 起卦方式（可选）
  /// [startTime] 开始时间（可选）
  /// [endTime] 结束时间（可选）
  /// 返回符合条件的记录列表
  Future<List<DivinationResult>> searchRecords({
    DivinationType? systemType,
    CastMethod? castMethod,
    DateTime? startTime,
    DateTime? endTime,
  });

  // ==================== 统计操作 ====================

  /// 检查记录是否存在
  ///
  /// [id] 记录 ID
  /// 返回 true 如果记录存在，否则返回 false
  Future<bool> recordExists(String id);
}
