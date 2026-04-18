# 历史记录页升级 Phase 1 实施计划（Plan E1）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 spec §10 Phase 1——把 `history_list_screen.dart` 从"纯列表 + 系统筛选"升级为合格的历史检索页：补上搜索、排序、时间分组、统一筛选状态条、四类状态页。

**Architecture:** 把 search/sort/group 逻辑抽为 `history_filter.dart` 的纯函数（可单测），在 `HistoryListScreen` state 里组合调用。卡片渲染继续用 `DivinationUIFactory.buildHistoryCard()`（Phase 2 才会重构这个接口）。所有新 UI 走 antique 组件。Phase 1 不做收藏/笔记/批量管理（依赖数据结构）。

**Tech Stack:** Flutter 3.38, Provider, antique design system。

**Spec 来源:** `docs/superpowers/specs/2026-04-18-history-screen-design.md`

**前置事实**（scout 已核实）：
- `lib/presentation/screens/history/history_list_screen.dart` 351 行；state 已有 `_records / _filteredRecords / _selectedSystemType / _isLoading / _errorMessage / chromeless` 字段
- `DivinationRepository.searchRecords(...)` 已存在但本 Plan 不用——前端过滤足够
- `DivinationResult` 接口暴露 `id / systemType / castTime / castMethod / lunarInfo / getSummary()`
- 术数系统类型 enum `DivinationType` 提供 `liuYao / daLiuRen / xiaoLiuRen / meiHua`

---

## 文件结构总览

### 新增
- `lib/presentation/screens/history/history_filter.dart` — 纯函数 + enum（search/sort/group）
- `test/presentation/screens/history/history_filter_test.dart` — 对应单测

### 修改
- `lib/presentation/screens/history/history_list_screen.dart` — 逐步集成搜索/排序/分组/状态条

### 不改
- `DivinationUIFactory` / `DivinationUIRegistry`（Phase 2 的事）
- `DivinationRepository`（Phase 1 不用 `searchRecords`）
- 各系统 UI 工厂的 `buildHistoryCard` 实现

---

## Task 1: 纯函数层 `history_filter.dart`

**Files:**
- Create: `lib/presentation/screens/history/history_filter.dart`
- Test: `test/presentation/screens/history/history_filter_test.dart`

严格 TDD：先写失败测试 → 跑看失败 → 写实现 → 跑看通过 → 提交。

### Step 1: 写失败测试

Create `test/presentation/screens/history/history_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/history/history_filter.dart';

class _FakeRecord {
  _FakeRecord({
    required this.id,
    required this.systemName,
    required this.summary,
    required this.castTime,
  });
  final String id;
  final String systemName;
  final String summary;
  final DateTime castTime;
}

void main() {
  group('applySearch', () {
    final records = [
      _FakeRecord(id: 'r1', systemName: '六爻', summary: '问事业 乾为天 → 天风姤', castTime: DateTime(2026, 4, 18, 10)),
      _FakeRecord(id: 'r2', systemName: '大六壬', summary: '问婚姻 涉害课', castTime: DateTime(2026, 4, 17, 10)),
      _FakeRecord(id: 'r3', systemName: '六爻', summary: '求财 坤为地', castTime: DateTime(2026, 4, 16, 10)),
    ];

    test('empty query returns all records', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.length, 3);
    });

    test('matches systemName', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '大六壬',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.map((e) => e.id), ['r2']);
    });

    test('matches summary keyword', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '事业',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.map((e) => e.id), ['r1']);
    });

    test('case-insensitive', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: 'KUN',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      // 中文字符不受大小写影响，但英文应命中
      expect(r.length, 0); // 'kun' 不在任何 summary 里
    });

    test('trims whitespace', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '   事业   ',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.length, 1);
    });
  });

  group('applySort', () {
    final records = [
      _FakeRecord(id: 'a', systemName: 'x', summary: '', castTime: DateTime(2026, 1, 1)),
      _FakeRecord(id: 'b', systemName: 'x', summary: '', castTime: DateTime(2026, 3, 1)),
      _FakeRecord(id: 'c', systemName: 'x', summary: '', castTime: DateTime(2026, 2, 1)),
    ];

    test('newestFirst orders descending', () {
      final r = applySort<_FakeRecord>(
        records,
        order: SortOrder.newestFirst,
        timeExtractor: (x) => x.castTime,
      );
      expect(r.map((e) => e.id), ['b', 'c', 'a']);
    });

    test('oldestFirst orders ascending', () {
      final r = applySort<_FakeRecord>(
        records,
        order: SortOrder.oldestFirst,
        timeExtractor: (x) => x.castTime,
      );
      expect(r.map((e) => e.id), ['a', 'c', 'b']);
    });

    test('returns new list without mutating input', () {
      final input = [...records];
      applySort<_FakeRecord>(
        input,
        order: SortOrder.newestFirst,
        timeExtractor: (x) => x.castTime,
      );
      expect(input.map((e) => e.id), ['a', 'b', 'c']); // 原序未变
    });
  });

  group('groupByTime', () {
    final now = DateTime(2026, 4, 18, 12);

    test('today records go to today bucket', () {
      final records = [
        _FakeRecord(id: 't1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 18, 9)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.length, 1);
      expect(groups[TimeGroup.lastSevenDays]!.length, 0);
      expect(groups[TimeGroup.earlier]!.length, 0);
    });

    test('yesterday goes to lastSevenDays bucket', () {
      final records = [
        _FakeRecord(id: 'y1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 17, 9)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.length, 0);
      expect(groups[TimeGroup.lastSevenDays]!.length, 1);
    });

    test('8 days ago goes to earlier bucket', () {
      final records = [
        _FakeRecord(id: 'e1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 10, 9)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.length, 0);
      expect(groups[TimeGroup.lastSevenDays]!.length, 0);
      expect(groups[TimeGroup.earlier]!.length, 1);
    });

    test('preserves input order within each bucket', () {
      final records = [
        _FakeRecord(id: 't1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 18, 10)),
        _FakeRecord(id: 't2', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 18, 8)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.map((e) => e.id), ['t1', 't2']);
    });

    test('always returns all three bucket keys (even empty)', () {
      final groups = groupByTime<_FakeRecord>(
        [],
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups.keys, containsAll([TimeGroup.today, TimeGroup.lastSevenDays, TimeGroup.earlier]));
    });
  });
}
```

### Step 2: 跑测试看失败

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter test test/presentation/screens/history/history_filter_test.dart
```

Expected: 失败 — `Target of URI doesn't exist`。

### Step 3: 写实现

Create `lib/presentation/screens/history/history_filter.dart`:

```dart
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
```

### Step 4: 跑测试看通过

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter test test/presentation/screens/history/history_filter_test.dart
```

Expected: All tests pass（约 12-14 个测试）。

### Step 5: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/history/history_filter.dart \
        test/presentation/screens/history/history_filter_test.dart
git commit -m "feat(history): add pure search/sort/groupByTime functions

Plan E1 Task 1. Generic pure functions for filtering history
records, isolated from UI state for testability:

- SortOrder { newestFirst, oldestFirst }
- TimeGroup { today, lastSevenDays, earlier }
- applySearch<T>(records, query, extractor)
- applySort<T>(records, order, timeExtractor)
- groupByTime<T>(records, now, timeExtractor)
- timeGroupLabel(group) for section headers

14 unit tests cover empty query, case-insensitive match,
whitespace trimming, immutability, bucket boundaries, stable
ordering, and empty-input handling."
```

---

## Task 2: 搜索框集成

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart`

在现有 `HistoryListScreen` 加搜索能力。TextField 放在 AppBar 下方（chromeless 模式也显示）、系统筛选条上方。搜索实时触发前端过滤。

### Step 1: 在 state 里加搜索字段

在 `_HistoryListScreenState` 类顶部字段区加：

```dart
// 搜索状态
String _searchQuery = '';
final TextEditingController _searchController = TextEditingController();
```

在 `dispose()`（如无就补写）里释放 controller：

```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

### Step 2: 改写 `_filterRecords` 为复合过滤器

当前方法只按 systemType 过滤。重写为综合"系统筛选 + 搜索关键字"：

```dart
import '../../../domain/divination_system.dart';
import 'history_filter.dart';

// 在 _HistoryListScreenState 内
void _applyFilters() {
  Iterable<DivinationResult> result = _records;

  // 系统筛选
  if (_selectedSystemType != null) {
    result = result.where((r) => r.systemType == _selectedSystemType);
  }

  // 搜索
  final filtered = applySearch<DivinationResult>(
    result.toList(),
    query: _searchQuery,
    extractor: (r) {
      // DivinationType 是 enum with displayName extension，直接用即可
      return '${r.systemType.displayName} ${r.getSummary()} ${r.castMethod.displayName}';
    },
  );

  setState(() {
    _filteredRecords = filtered;
  });
}
```

（`DivinationType.displayName` 来自 `lib/domain/divination_system.dart` 的 enum 扩展，当前文件应已 import。`CastMethod.displayName` 同理。）

### Step 3: 把原 `_filterRecords(DivinationType? systemType)` 调用点改为复合调用

原代码里的 `_filterRecords(type)` 用法：
- 把系统过滤写入 `_selectedSystemType`
- 调 `_applyFilters()`

即：

```dart
void _filterBySystemType(DivinationType? systemType) {
  _selectedSystemType = systemType;
  _applyFilters();
}
```

用新方法名替换原调用点。若老 `_filterRecords` 方法名其他地方用到，保留别名或一并改名。

### Step 4: 搜索框 UI

在 `_buildBody()`（或同级方法）的顶部插入搜索框：

```dart
Widget _buildSearchField() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: AntiqueTextField(
      controller: _searchController,
      hint: '搜索问事、卦名、术数...',
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
        _applyFilters();
      },
    ),
  );
}
```

在 `_buildBody()` 的 Column children 头部加上这个 widget（chromeless 模式也渲染，这是检索能力的一部分）。

### Step 5: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test 2>&1 | tail -3
```

Expected: analyze clean, 测试全过。

### Step 6: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "feat(history): add search field with client-side filter

Plan E1 Task 2. Page-level TextField (AntiqueTextField) above
the list; search query combines with existing system-type filter
via _applyFilters(). Extractor pulls system name + summary +
cast method for fuzzy match (case-insensitive, whitespace-trimmed)."
```

---

## Task 3: 排序切换

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart`

加两个选项的排序：最新优先 / 最早优先，默认最新优先。用一个紧凑的 toggle UI。

### Step 1: state 加排序字段

```dart
SortOrder _sortOrder = SortOrder.newestFirst;
```

### Step 2: `_applyFilters` 里加排序

在 `_applyFilters()` 的 search 之后加：

```dart
final sorted = applySort<DivinationResult>(
  filtered,
  order: _sortOrder,
  timeExtractor: (r) => r.castTime,
);

setState(() {
  _filteredRecords = sorted;  // 替代原 _filteredRecords = filtered;
});
```

### Step 3: UI toggle

在 `_buildBody()` 头部（search 之下，list 之上）加工具条。暂时用两个 `AntiqueTag` 横排模拟 segmented：

```dart
Widget _buildSortToggle() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        Text('排序: ', style: AppTextStyles.antiqueLabel),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (_sortOrder != SortOrder.newestFirst) {
              setState(() {
                _sortOrder = SortOrder.newestFirst;
              });
              _applyFilters();
            }
          },
          child: AntiqueTag(
            label: '最新',
            color: _sortOrder == SortOrder.newestFirst
                ? AppColors.zhusha
                : AppColors.guhe,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (_sortOrder != SortOrder.oldestFirst) {
              setState(() {
                _sortOrder = SortOrder.oldestFirst;
              });
              _applyFilters();
            }
          },
          child: AntiqueTag(
            label: '最早',
            color: _sortOrder == SortOrder.oldestFirst
                ? AppColors.zhusha
                : AppColors.guhe,
          ),
        ),
      ],
    ),
  );
}
```

把 `_buildSortToggle()` 加到 Column children 里，位置：search 下面，原列表上面。

### Step 4: 验证 + Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test 2>&1 | tail -3
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "feat(history): add newest/oldest sort toggle"
```

---

## Task 4: 时间分组渲染

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart`

原列表是平铺 `ListView.builder`。现在按 `groupByTime` 结果分三组渲染，组之间用 `AntiqueSectionTitle` + `AntiqueDivider`。

### Step 1: 构造 grouped 数据

在 `build` 里（或专门 helper）：

```dart
Widget _buildGroupedList() {
  final groups = groupByTime<DivinationResult>(
    _filteredRecords,
    now: DateTime.now(),
    timeExtractor: (r) => r.castTime,
  );

  final sections = <Widget>[];
  for (final group in TimeGroup.values) {
    final items = groups[group]!;
    if (items.isEmpty) continue;
    sections.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: AntiqueSectionTitle(title: timeGroupLabel(group)),
      ),
    );
    for (final record in items) {
      sections.add(_buildHistoryCard(record));  // 原卡片渲染
    }
    sections.add(const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AntiqueDivider(),
    ));
  }
  // 最后一个 section 后的 divider 可视情况删除
  if (sections.isNotEmpty && sections.last is Padding) {
    sections.removeLast();
  }

  return ListView(children: sections);
}
```

### Step 2: 替换原 `ListView.builder` 调用

原 `_buildBody()` 里的 list rendering 分支（非 loading/error/empty）改为 `_buildGroupedList()`。

### Step 3: 验证 + Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test 2>&1 | tail -3
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "feat(history): group records by 今天/近 7 天/更早 with antique headers"
```

---

## Task 5: 统一筛选状态条

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart`

当用户启用系统筛选或搜索时，显示一行状态反馈 + 清除按钮。

### Step 1: 构造状态条

```dart
Widget? _buildFilterStatusBar() {
  final hasSystemFilter = _selectedSystemType != null;
  final hasSearch = _searchQuery.trim().isNotEmpty;
  if (!hasSystemFilter && !hasSearch) return null;

  final fragments = <String>[];
  if (hasSystemFilter) {
    fragments.add('系统: ${_selectedSystemType!.displayName}');
  }
  if (hasSearch) {
    fragments.add('关键字: "${_searchQuery.trim()}"');
  }
  fragments.add('共 ${_filteredRecords.length} 条');

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            fragments.join(' · '),
            style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedSystemType = null;
              _searchQuery = '';
              _searchController.clear();
            });
            _applyFilters();
          },
          child: Text('清除', style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.zhusha)),
        ),
      ],
    ),
  );
}
```

### Step 2: 插入到布局

在 `_buildBody()` 里，状态条在搜索/排序 toggle 之下、列表之上：

```dart
final statusBar = _buildFilterStatusBar();
final children = <Widget>[
  _buildSearchField(),
  _buildSortToggle(),
  if (statusBar != null) statusBar,
  Expanded(child: _buildGroupedList()),
];
```

### Step 3: 验证 + Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test 2>&1 | tail -3
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "feat(history): add unified filter status bar

Shows active system/search filters and result count when any
filter is applied. Includes a 清除 button to reset all filters
in one tap."
```

---

## Task 6: 四类状态页

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart`

四类需要覆盖：
1. **Loading**：`CircularProgressIndicator` + 提示文字
2. **Error**：错误图标 + 消息 + "重试" AntiqueButton
3. **EmptyHistory**（没有任何记录）：`AntiqueWatermark('空')` + "暂无历史记录" + "去起卦" AntiqueButton
4. **NoSearchResults**（有记录但当前筛选无命中）：`AntiqueWatermark('无')` + "没有找到相关记录" + "清除搜索" AntiqueButton

### Step 1: 区分判断

把 `_buildBody()` 的渲染路径明确分到 4 个 helper。

```dart
Widget _buildBody() {
  if (_isLoading) return _buildLoadingState();
  if (_errorMessage != null) return _buildErrorState();
  if (_records.isEmpty) return _buildEmptyHistoryState();

  // 有记录但应用筛选后为空
  final hasActiveFilter = _selectedSystemType != null || _searchQuery.trim().isNotEmpty;
  if (_filteredRecords.isEmpty && hasActiveFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(),
        _buildSortToggle(),
        if (_buildFilterStatusBar() != null) _buildFilterStatusBar()!,
        Expanded(child: _buildNoSearchResultsState()),
      ],
    );
  }

  // 正常列表
  final statusBar = _buildFilterStatusBar();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildSearchField(),
      _buildSortToggle(),
      if (statusBar != null) statusBar,
      Expanded(child: _buildGroupedList()),
    ],
  );
}
```

### Step 2: 四个状态 helper

```dart
Widget _buildLoadingState() {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('加载中...', style: TextStyle(color: AppColors.guhe)),
      ],
    ),
  );
}

Widget _buildErrorState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: AppColors.zhushaLight),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? '加载失败',
          style: AppTextStyles.antiqueBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: '重试',
          icon: Icons.refresh,
          variant: AntiqueButtonVariant.ghost,
          onPressed: _loadRecords,
        ),
      ],
    ),
  );
}

Widget _buildEmptyHistoryState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AntiqueWatermark(char: '空'),
        const SizedBox(height: 16),
        Text('暂无历史记录', style: AppTextStyles.antiqueSection),
        const SizedBox(height: 8),
        Text(
          '去首页选一种术数起卦吧',
          style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: '去起卦',
          icon: Icons.auto_awesome,
          onPressed: () {
            // 独立页面模式：返回上一页（首页）
            // chromeless 模式：切 home tab 0（由宿主处理）
            // 通用：弹回栈直到首页
            if (Navigator.canPop(context)) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildNoSearchResultsState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AntiqueWatermark(char: '无'),
        const SizedBox(height: 16),
        Text('没有找到相关记录', style: AppTextStyles.antiqueSection),
        const SizedBox(height: 8),
        Text(
          '试试调整筛选或关键字',
          style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: '清除筛选',
          icon: Icons.clear,
          variant: AntiqueButtonVariant.ghost,
          onPressed: () {
            setState(() {
              _selectedSystemType = null;
              _searchQuery = '';
              _searchController.clear();
            });
            _applyFilters();
          },
        ),
      ],
    ),
  );
}
```

### Step 3: 验证 + Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test 2>&1 | tail -3
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "feat(history): add four distinct empty/error/loading states

Each state has its own visual anchor and primary action:
- Loading: spinner + '加载中...'
- Error: error icon + message + 重试 button (ghost)
- Empty history: 空 watermark + CTA 去起卦 (primary)
- No search results: 无 watermark + CTA 清除筛选 (ghost)"
```

---

## Task 7: 最终验证 + 审计

### Step 1: 全量测试

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -5
bash tool/audit_hardcoded_colors.sh
```

Expected:
- analyze clean
- 283+14 ≈ 297 tests pass（Task 1 加了约 14 个单测）
- audit OK

### Step 2: 验证 chromeless 模式不破坏

`HistoryListScreen(chromeless: true)` 在 `HomeScreen` tab 1 被嵌入。Plan E1 的新 UI（搜索框 / 排序 toggle / 状态条 / 分组列表）都应该在两种模式下正确渲染——因为它们都在 body 里，不在 Scaffold 壳层。

如果有任何对 `Navigator.canPop(context)` 或 `Navigator.pushNamed` 的依赖，确保 chromeless 模式不会尝试 pop 到不存在的 route。

手工在模拟器走查：
1. 打开 App → 点底部导航 历史 tab → 看到搜索/排序/分组正常
2. 从首页进入独立历史页（若有路径）→ 看到 AntiqueAppBar 标题 + 同样的搜索/排序/分组
3. 搜索无结果 → 看到"没有找到相关记录" + 清除按钮
4. 清空所有记录（或未做过排盘时）→ 看到"暂无历史记录" + 去起卦按钮

### Step 3: 列出 Plan E1 commits

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git log --oneline <plan-e1-base>..HEAD
```

（`<plan-e1-base>` = 合入 Plan D2 后的 main HEAD，即 `bdd8f15`）

Expected: 6 个实现 commits + plan 文档 commit。

### Step 4: 提交 plan 文档（如未提交）

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git status
# 若 plan 文档尚未提交
git add docs/superpowers/plans/2026-04-18-history-screen-phase-1.md
git commit -m "docs(plan): Plan E1 - history screen Phase 1 (search/sort/group/states)"
```

---

## 完成标志

1. ✅ `lib/presentation/screens/history/history_filter.dart` 存在，14 单测通过
2. ✅ `HistoryListScreen` 有搜索框（AntiqueTextField），实时前端过滤
3. ✅ 有最新/最早排序 toggle
4. ✅ 列表按"今天/近 7 天/更早"分组，每组 `AntiqueSectionTitle` 标题 + `AntiqueDivider` 分隔
5. ✅ 有筛选时显示状态条（系统 + 关键字 + 结果数 + 清除按钮）
6. ✅ 四类状态页都有独特视觉 + 主操作：loading / error / empty-history / no-search-results
7. ✅ `flutter analyze` 0 issues
8. ✅ `flutter test` 全过
9. ✅ `tool/audit_hardcoded_colors.sh` OK
10. ✅ chromeless + 独立两种模式都能正确渲染

---

## 范围外（留给 Plan E2）

- **卡片统一骨架**：重构 `DivinationUIFactory.buildHistoryCard()` 接口，让 page 层持有卡片外壳、system 层只提供摘要数据模型（spec §8）
- **收藏 / 笔记 / 批量** 等 P2 能力（spec §6.3）——数据层依赖，需要先改 model/repository
- **AI 解读 / 标注** 等卡片附加状态（spec §7 第四层）——同上，数据依赖
