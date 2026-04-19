import '../divination_system.dart';
import '../repositories/divination_repository.dart';

/// 跨系统"上次起卦方式"记忆服务
///
/// **历史记录即是权威真相源**：某术数系统"上次用了哪种起卦方式"直接查
/// [DivinationRepository]，避免各 UI 各自维护 SharedPreferences 导致的记忆漂移。
///
/// 过滤规则：
///
/// - 无历史记录 → 返回 `null`，UI 自行决定 fallback
/// - 历史记录里的 castMethod 已不在 [allowed] 中（比如某起卦方式后来被下架）
///   → 返回 `null`，避免把失效的方式回填给下拉框
class LastCastMethodService {
  final DivinationRepository repository;

  LastCastMethodService({required this.repository});

  /// 返回 [type] 系统上次使用的起卦方式。
  ///
  /// [allowed] 是当前系统 UI 允许的起卦方式白名单，用于兜底过滤。
  Future<CastMethod?> getLastMethod(
    DivinationType type, {
    required List<CastMethod> allowed,
  }) async {
    final records = await repository.getRecordsBySystemType(type);
    if (records.isEmpty) return null;
    final method = records.first.castMethod;
    if (!allowed.contains(method)) return null;
    return method;
  }
}
