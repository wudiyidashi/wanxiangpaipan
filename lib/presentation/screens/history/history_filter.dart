/// 历史记录页前端过滤/排序/分组纯函数与 enum。
///
/// 全部为无副作用函数。按泛型设计，便于测试与复用——
/// 真实调用时 T = `DivinationResult`。
library;

/// 排序方式
enum SortOrder {
  /// 最新优先
  newestFirst,

  /// 最早优先
  oldestFirst,
}

/// 时间分组
enum TimeGroup {
  /// 今天
  today,

  /// 近 7 天（含昨天到 7 天前）
  lastSevenDays,

  /// 更早
  earlier,
}

/// 按关键字模糊搜索。
///
/// [extractor] 从记录提取用于匹配的文本（通常拼系统名 + 摘要等）。
/// [query] 空字符串或纯空白时返回原列表副本。
List<T> applySearch<T>(
  List<T> records, {
  required String query,
  required String Function(T) extractor,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return List<T>.from(records);
  final needle = trimmed.toLowerCase();
  return records.where((r) {
    final haystack = extractor(r).toLowerCase();
    return haystack.contains(needle);
  }).toList();
}

/// 按时间排序。
///
/// 返回新列表，不修改输入。
List<T> applySort<T>(
  List<T> records, {
  required SortOrder order,
  required DateTime Function(T) timeExtractor,
}) {
  final sorted = List<T>.from(records);
  sorted.sort((a, b) {
    final ta = timeExtractor(a);
    final tb = timeExtractor(b);
    return order == SortOrder.newestFirst
        ? tb.compareTo(ta)
        : ta.compareTo(tb);
  });
  return sorted;
}

/// 按"今天 / 近 7 天 / 更早"分组。
///
/// 返回的 map 总是包含 3 个 key（即使对应列表为空）。
/// 组内顺序 = 输入顺序（调用方应先排序再分组）。
Map<TimeGroup, List<T>> groupByTime<T>(
  List<T> records, {
  required DateTime now,
  required DateTime Function(T) timeExtractor,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = today.subtract(const Duration(days: 7));

  final result = <TimeGroup, List<T>>{
    TimeGroup.today: <T>[],
    TimeGroup.lastSevenDays: <T>[],
    TimeGroup.earlier: <T>[],
  };

  for (final record in records) {
    final t = timeExtractor(record);
    if (!t.isBefore(today)) {
      result[TimeGroup.today]!.add(record);
    } else if (!t.isBefore(sevenDaysAgo)) {
      result[TimeGroup.lastSevenDays]!.add(record);
    } else {
      result[TimeGroup.earlier]!.add(record);
    }
  }

  return result;
}

/// 时间分组的显示名称（中文，用于 section 标题）。
String timeGroupLabel(TimeGroup group) {
  switch (group) {
    case TimeGroup.today:
      return '今天';
    case TimeGroup.lastSevenDays:
      return '近 7 天';
    case TimeGroup.earlier:
      return '更早';
  }
}
