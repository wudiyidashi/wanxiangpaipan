# 历法功能（黄历/万年历）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将首页第 3 个 Tab「历法」从占位空壳填充为完整的黄历/万年历浏览功能（月视图 + 当日详情分屏布局）。

**Architecture:** 新增 `AlmanacService`（纯函数封装 lunar 包 Exact2 口径）+ `DailyAlmanac` 数据模型 + `CalendarViewModel`（含 90 天 LRU 缓存）+ 一套仿古风 UI 组件挂在现有 HomeScreen Tab 上，复用 Antique Design System，零新增依赖、零持久化。

**Tech Stack:** Flutter / Dart / Provider / freezed / lunar package 1.7.8 / flutter_test

**Spec:** `docs/superpowers/specs/2026-04-19-calendar-almanac-design.md`

---

## 文件清单

### 新增

| 路径 | 责任 |
|---|---|
| `lib/models/daily_almanac.dart` | `DailyAlmanac` + `HourAlmanac` freezed 模型（含 `.freezed.dart` / `.g.dart` 生成物） |
| `lib/domain/services/shared/festival_resolver.dart` | 节日名合并（含传统 + 公历），不含放假/调休 |
| `lib/domain/services/shared/almanac_service.dart` | `AlmanacService.getDay(DateTime)` 纯函数服务 |
| `lib/presentation/screens/calendar/calendar_screen.dart` | 顶层屏幕，支持 `chromeless` |
| `lib/presentation/screens/calendar/calendar_viewmodel.dart` | `ChangeNotifier` + LRU 缓存 |
| `lib/presentation/screens/calendar/month_cell_info.dart` | 月视图格子轻量信息（不经 AlmanacService） |
| `lib/presentation/screens/calendar/month_grid_view.dart` | 6×7 月视图 + 顶栏 |
| `lib/presentation/screens/calendar/day_detail_view.dart` | 日详情容器（组合 7 个子模块） |
| `lib/presentation/screens/calendar/widgets/festival_banner.dart` | 节日横幅（有节日才渲染） |
| `lib/presentation/screens/calendar/widgets/almanac_header.dart` | 日期头（公历/农历/距下节气） |
| `lib/presentation/screens/calendar/widgets/four_pillars_card.dart` | 四柱干支卡 |
| `lib/presentation/screens/calendar/widgets/yiji_panel.dart` | 宜/忌双列 |
| `lib/presentation/screens/calendar/widgets/time_hour_bar.dart` | 12 时辰吉凶横向条 |
| `lib/presentation/screens/calendar/widgets/moon_phase_kongwang.dart` | 月相+空亡单行 |
| `lib/presentation/screens/calendar/widgets/pengzu_card.dart` | 彭祖百忌卡 |
| `test/unit/services/almanac_service_test.dart` | A1-A8 单元测试 |
| `test/unit/services/festival_resolver_test.dart` | 节日解析测试 |
| `test/unit/viewmodels/calendar_viewmodel_test.dart` | B1-B6 单元测试 |
| `test/presentation/screens/calendar/calendar_screen_test.dart` | C1-C4 Widget 测试 |
| `test/presentation/screens/calendar/day_detail_view_test.dart` | C5 + 子模块集成 |
| `test/presentation/screens/calendar/month_grid_view_test.dart` | 月视图格子行为测试 |

### 修改

| 路径 | 变动 |
|---|---|
| `lib/presentation/screens/home/home_screen.dart` | `_buildCalendarContent()` 从占位改为 `CalendarScreen(chromeless: true)` |

---

## 共用命令与约定

- **运行测试单文件**：`flutter test test/unit/services/almanac_service_test.dart`
- **运行全部测试**：`flutter test`
- **freezed 代码生成**：`dart run build_runner build --delete-conflicting-outputs`
- **监听生成**：`dart run build_runner watch --delete-conflicting-outputs`
- **提交风格**：参考 `docs(spec): 历法功能…`；本计划任务均用 `feat(calendar): …` 前缀

**归一化辅助函数**（多处复用，记在这里）：

```dart
/// 归一化到本地当日 00:00:00
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
```

放在 `AlmanacService` 私有静态方法即可，不单独抽文件。

---

## Task 1: DailyAlmanac 与 HourAlmanac 数据模型

**Files:**
- Create: `lib/models/daily_almanac.dart`
- Generated: `lib/models/daily_almanac.freezed.dart`, `lib/models/daily_almanac.g.dart`

- [ ] **Step 1: Create the freezed model file**

`lib/models/daily_almanac.dart`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_almanac.freezed.dart';
part 'daily_almanac.g.dart';

/// 12 时辰中的一格。
@freezed
class HourAlmanac with _$HourAlmanac {
  const factory HourAlmanac({
    required String zhi,          // 子/丑/...
    required String ganZhi,       // "甲子"
    required String tianShen,     // 青龙/明堂/...
    required String huangHei,     // "黄" / "黑"
    required String luck,         // "吉" / "凶"
    required List<String> yi,     // 时辰宜
    required List<String> ji,     // 时辰忌
    required int startHour,       // 23/1/3/5/...
    required int endHour,         // 1/3/5/7/...
  }) = _HourAlmanac;

  factory HourAlmanac.fromJson(Map<String, dynamic> json) =>
      _$HourAlmanacFromJson(json);
}

/// 某一公历日的完整黄历信息。
/// 时间口径：统一走 lunar 包 Exact2。
@freezed
class DailyAlmanac with _$DailyAlmanac {
  const factory DailyAlmanac({
    required DateTime date,            // 归一到本地午夜
    required String lunarDate,         // "农历三月初二" / "闰六月十五"
    required String weekday,           // "星期六"
    required String? currentJieQi,     // 当日节气名，无则 null
    required String nextJieQi,         // 下一节气名
    required int nextJieQiDaysAway,    // 距下一节气天数
    required String yearGZ,            // "丙午"
    required String monthGZ,           // Exact
    required String dayGZ,             // Exact2
    required String yueXiang,
    required List<String> kongWang,    // 2 地支
    required List<String> yi,
    required List<String> ji,
    required String pengZuGan,
    required String pengZuZhi,
    required List<String> festivals,
    required List<HourAlmanac> twelveHours,
  }) = _DailyAlmanac;

  factory DailyAlmanac.fromJson(Map<String, dynamic> json) =>
      _$DailyAlmanacFromJson(json);
}
```

- [ ] **Step 2: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `daily_almanac.freezed.dart` + `daily_almanac.g.dart` without errors.

- [ ] **Step 3: Smoke-check it compiles**

Run: `flutter analyze lib/models/daily_almanac.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/models/daily_almanac.dart lib/models/daily_almanac.freezed.dart lib/models/daily_almanac.g.dart
git commit -m "feat(calendar): DailyAlmanac/HourAlmanac freezed models"
```

---

## Task 2: FestivalResolver

**Files:**
- Create: `lib/domain/services/shared/festival_resolver.dart`
- Test: `test/unit/services/festival_resolver_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/services/festival_resolver_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';
import 'package:wanxiang_paipan/domain/services/shared/festival_resolver.dart';

Lunar _lunarOf(DateTime d) => Solar.fromDate(d).getLunar();

void main() {
  group('FestivalResolver', () {
    test('returns 春节 on lunar new year day 2026-02-17', () {
      final d = DateTime(2026, 2, 17);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, contains('春节'));
    });

    test('returns 元旦 on 2026-01-01', () {
      final d = DateTime(2026, 1, 1);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, contains('元旦'));
    });

    test('returns 国庆节 on 2026-10-01', () {
      final d = DateTime(2026, 10, 1);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, contains('国庆节'));
    });

    test('returns empty list on ordinary day 2026-04-19', () {
      final d = DateTime(2026, 4, 19);
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result, isEmpty);
    });

    test('returns unique names without duplicates', () {
      final d = DateTime(2026, 2, 17);  // 春节
      final result = FestivalResolver.resolve(d, _lunarOf(d));
      expect(result.length, result.toSet().length,
          reason: '合并后应去重');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/festival_resolver_test.dart`
Expected: FAIL with "Target of URI doesn't exist" / cannot find `FestivalResolver`.

- [ ] **Step 3: Write minimal implementation**

`lib/domain/services/shared/festival_resolver.dart`：

```dart
import 'package:lunar/lunar.dart';

/// 节日名解析：合并 lunar 传统节日 + 公历节日名。
/// 不处理放假/调休，那需要逐年变化的年表，本期不做。
class FestivalResolver {
  FestivalResolver._();

  static List<String> resolve(DateTime date, Lunar lunar) {
    final solar = lunar.getSolar();
    final names = <String>{};

    // 农历传统节日（春节/元宵/端午/中秋/重阳...）
    names.addAll(lunar.getFestivals());
    // 其他传统节日（七夕/寒食/腊八...）
    names.addAll(lunar.getOtherFestivals());
    // 公历节日（元旦/劳动节/国庆...）
    names.addAll(solar.getFestivals());
    names.addAll(solar.getOtherFestivals());

    return names.toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/festival_resolver_test.dart`
Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/shared/festival_resolver.dart test/unit/services/festival_resolver_test.dart
git commit -m "feat(calendar): FestivalResolver merges traditional + solar holiday names"
```

---

## Task 3: AlmanacService.getDay

**Files:**
- Create: `lib/domain/services/shared/almanac_service.dart`
- Test: `test/unit/services/almanac_service_test.dart`

- [ ] **Step 1: Write the failing tests (A1-A8)**

`test/unit/services/almanac_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';

void main() {
  final service = AlmanacService();

  group('AlmanacService.getDay - normalization (A1)', () {
    test('same day different times produce equal result', () {
      final a = service.getDay(DateTime(2026, 4, 18, 0, 0));
      final b = service.getDay(DateTime(2026, 4, 18, 23, 59, 59));
      expect(a, equals(b));
    });
  });

  group('AlmanacService.getDay - solar term boundary (A2)', () {
    test('monthGZ is stable across same-day hours around 交节', () {
      // 清明 2026 大致在 04-05；用该日 04:00 vs 06:00 验证
      final before = service.getDay(DateTime(2026, 4, 5, 4));
      final after = service.getDay(DateTime(2026, 4, 5, 6));
      expect(before.monthGZ, equals(after.monthGZ),
          reason: 'normalization 到午夜后两个调用应等价');
    });
  });

  group('AlmanacService.getDay - zi shi cross-day (A3)', () {
    test('twelveHours last slot (zi) ganZhi uses Exact2', () {
      final a = service.getDay(DateTime(2026, 4, 18));
      // 最后一格（子时）应存在且有完整字段
      final ziHour = a.twelveHours.firstWhere((h) => h.zhi == '子');
      expect(ziHour.ganZhi.length, 2);
      expect(ziHour.tianShen, isNotEmpty);
      expect(ziHour.huangHei, anyOf('黄', '黑'));
    });
  });

  group('AlmanacService.getDay - 春节 (A4)', () {
    test('春节日 has festival and lunar date 正月初一', () {
      final d = DateTime(2026, 2, 17);
      final a = service.getDay(d);
      expect(a.festivals, contains('春节'));
      expect(a.lunarDate, contains('正月'));
      expect(a.yearGZ, isNotEmpty);
    });
  });

  group('AlmanacService.getDay - 闰月 (A5)', () {
    test('2025 闰六月某日 lunarDate 含"闰六月"', () {
      // 2025 年闰六月；闰六月初一约 2025-07-25
      final d = DateTime(2025, 7, 25);
      final a = service.getDay(d);
      expect(a.lunarDate, contains('闰六月'));
    });
  });

  group('AlmanacService.getDay - out of range (A7)', () {
    test('year < 1900 throws AlmanacError', () {
      expect(
        () => service.getDay(DateTime(1800, 1, 1)),
        throwsA(isA<AlmanacError>()),
      );
    });
    test('year > 2099 throws AlmanacError', () {
      expect(
        () => service.getDay(DateTime(2200, 1, 1)),
        throwsA(isA<AlmanacError>()),
      );
    });
  });

  group('AlmanacService.getDay - 12 hours shape (A8)', () {
    test('twelveHours has 12 slots with all fields', () {
      final a = service.getDay(DateTime(2026, 4, 18));
      expect(a.twelveHours.length, 12);
      for (final h in a.twelveHours) {
        expect(h.zhi, isNotEmpty);
        expect(h.ganZhi.length, 2);
        expect(h.tianShen, isNotEmpty);
        expect(h.huangHei, anyOf('黄', '黑'));
        expect(h.luck, anyOf('吉', '凶'));
        expect(h.startHour, inInclusiveRange(0, 23));
        expect(h.endHour, inInclusiveRange(0, 23));
      }
    });
  });
}

// A6 月将边界 regression pin: 单独测试文件或在 daliuren 现有测试增补，
// 不在本服务职责内。若实现阶段发现差异，登记到 spec §3.2。
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/services/almanac_service_test.dart`
Expected: All fail — `AlmanacService` / `AlmanacError` not defined.

- [ ] **Step 3: Write the implementation**

`lib/domain/services/shared/almanac_service.dart`：

```dart
import 'package:lunar/lunar.dart';
import '../../../models/daily_almanac.dart';
import 'festival_resolver.dart';

class AlmanacError implements Exception {
  final String message;
  final Object? cause;
  AlmanacError(this.message, [this.cause]);

  @override
  String toString() => 'AlmanacError: $message${cause != null ? ' ($cause)' : ''}';
}

/// 黄历计算服务（封装 lunar 包 Exact2 口径）。
/// 纯函数，无状态，无缓存（缓存由 ViewModel 管）。
class AlmanacService {
  const AlmanacService();

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static const _huangDao = {
    '青龙', '明堂', '金匮', '天德', '玉堂', '司命',
  };

  /// 时辰起始小时表（按子/丑/寅.../亥 的顺序）。
  static const _zhiOrder = [
    '子', '丑', '寅', '卯', '辰', '巳',
    '午', '未', '申', '酉', '戌', '亥',
  ];
  // 子时跨日：23-1 使用 23；其余按双数起点。
  static const _startHours = [23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21];
  static const _endHours = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23];

  DailyAlmanac getDay(DateTime date) {
    final d = _dateOnly(date);
    if (d.year < 1900 || d.year > 2099) {
      throw AlmanacError('Year out of supported range: ${d.year}');
    }

    try {
      final solar = Solar.fromYmd(d.year, d.month, d.day);
      final lunar = solar.getLunar();

      final festivals = FestivalResolver.resolve(d, lunar);
      final twelveHours = _buildTwelveHours(lunar);
      final (nextName, nextDays) = _nextJieQiInfo(lunar);
      final currentJieQi = _currentJieQi(lunar);

      return DailyAlmanac(
        date: d,
        lunarDate: _formatLunarDate(lunar),
        weekday: _weekdayCn(d.weekday),
        currentJieQi: currentJieQi,
        nextJieQi: nextName,
        nextJieQiDaysAway: nextDays,
        yearGZ: lunar.getYearInGanZhi(),
        monthGZ: lunar.getMonthInGanZhiExact(),
        dayGZ: lunar.getDayInGanZhiExact2(),
        yueXiang: lunar.getYueXiang(),
        kongWang: _kongWang(lunar),
        yi: List<String>.from(lunar.getDayYi()),
        ji: List<String>.from(lunar.getDayJi()),
        pengZuGan: lunar.getPengZuGan(),
        pengZuZhi: lunar.getPengZuZhi(),
        festivals: festivals,
        twelveHours: twelveHours,
      );
    } on AlmanacError {
      rethrow;
    } catch (e) {
      throw AlmanacError('Failed to compute almanac for $d', e);
    }
  }

  String _formatLunarDate(Lunar lunar) {
    final monthCn = lunar.getMonthInChinese();
    final dayCn = lunar.getDayInChinese();
    final prefix = lunar.getMonth() < 0 ? '农历闰' : '农历';
    // getMonthInChinese 闰月版本自带"闰"前缀，避免双前缀
    if (monthCn.startsWith('闰')) {
      return '农历$monthCn月$dayCn';
    }
    return '$prefix$monthCn月$dayCn';
  }

  String _weekdayCn(int w) => const ['一', '二', '三', '四', '五', '六', '日'][w - 1]
      .let((s) => '星期$s');

  List<String> _kongWang(Lunar lunar) {
    final xk = lunar.getDayXunKong();
    if (xk.length == 2) return [xk[0], xk[1]];
    return [];
  }

  String? _currentJieQi(Lunar lunar) {
    final name = lunar.getJieQi();
    return name.isEmpty ? null : name;
  }

  (String, int) _nextJieQiInfo(Lunar lunar) {
    final table = lunar.getJieQiTable();
    DateTime? nearest;
    String nearestName = '';
    final now = DateTime(
      lunar.getSolar().getYear(),
      lunar.getSolar().getMonth(),
      lunar.getSolar().getDay(),
    );
    table.forEach((name, solar) {
      final dt = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      if (dt.isAfter(now) &&
          (nearest == null || dt.isBefore(nearest!))) {
        nearest = dt;
        nearestName = name;
      }
    });
    if (nearest == null) return ('', 0);
    final days = nearest!.difference(now).inDays;
    return (nearestName, days);
  }

  List<HourAlmanac> _buildTwelveHours(Lunar dayLunar) {
    final solar = dayLunar.getSolar();
    final y = solar.getYear();
    final m = solar.getMonth();
    final d = solar.getDay();

    final result = <HourAlmanac>[];
    for (int i = 0; i < 12; i++) {
      final start = _startHours[i];
      // 子时 23-1 跨日，以"当日 23 时"为代表构造；lunar 包内部按 Exact2 处理
      final probeHour = start == 23 ? 23 : start;
      final lt = Lunar.fromYmdHms(y, m, d, probeHour, 0, 0);
      final tianShen = lt.getDayTianShen();
      final huangHei = LunarUtil.TIAN_SHEN_TYPE[tianShen] ?? '黄';
      final luck = LunarUtil.TIAN_SHEN_TYPE_LUCK[huangHei] ?? '吉';
      final ganZhi = lt.getTimeInGanZhi();
      result.add(HourAlmanac(
        zhi: _zhiOrder[i],
        ganZhi: ganZhi,
        tianShen: tianShen,
        huangHei: huangHei,
        luck: luck,
        yi: List<String>.from(lt.getTimeYi()),
        ji: List<String>.from(lt.getTimeJi()),
        startHour: start,
        endHour: _endHours[i],
      ));
    }
    return result;
  }
}

extension _StringLet<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
```

> 实现注意：
> - `LunarUtil.TIAN_SHEN_TYPE` 与 `TIAN_SHEN_TYPE_LUCK` 是 lunar 包里的静态常量，若 import 冲突可全路径前缀。
> - `getMonthInChinese` 在闰月返回含"闰"前缀的字符串，已做防御（避免"农历闰闰X月"）。
> - 若 `getMonth() < 0` 口径不稳，以 `monthCn.startsWith('闰')` 分支为准。

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/services/almanac_service_test.dart`
Expected: All 8 tests pass. 若 A5 "闰六月" 日期值因口径不同而不准，以实际 lunar 返回为准调整断言日期。

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/shared/almanac_service.dart test/unit/services/almanac_service_test.dart
git commit -m "feat(calendar): AlmanacService with Exact2 pillars and 12-hour data"
```

---

## Task 4: CalendarViewModel

**Files:**
- Create: `lib/presentation/screens/calendar/calendar_viewmodel.dart`
- Test: `test/unit/viewmodels/calendar_viewmodel_test.dart`

- [ ] **Step 1: Write the failing tests (B1-B6)**

`test/unit/viewmodels/calendar_viewmodel_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_viewmodel.dart';

class _CountingService extends AlmanacService {
  int calls = 0;
  final AlmanacService _delegate;
  _CountingService(this._delegate);

  @override
  DailyAlmanac getDay(DateTime date) {
    calls++;
    return _delegate.getDay(date);
  }
}

void main() {
  late _CountingService service;
  late CalendarViewModel vm;
  final fixedNow = DateTime(2026, 4, 18, 10);

  setUp(() {
    service = _CountingService(const AlmanacService());
    vm = CalendarViewModel(service: service, now: () => fixedNow);
  });

  test('B1: same day hits cache on repeated selectDate', () {
    vm.selectDate(DateTime(2026, 4, 10, 8));
    vm.selectDate(DateTime(2026, 4, 10, 9));
    vm.selectDate(DateTime(2026, 4, 10, 23));
    expect(service.calls, 1);
  });

  test('B2: LRU eviction after 90 distinct days', () {
    for (int i = 0; i < 91; i++) {
      vm.selectDate(DateTime(2026, 1, 1).add(Duration(days: i)));
    }
    final before = service.calls;
    vm.selectDate(DateTime(2026, 1, 1));  // 第 1 天应已被淘汰
    expect(service.calls, before + 1);
  });

  test('B3: selectToday syncs displayed and selected', () {
    vm.goToMonth(DateTime(2026, 1, 15));
    vm.selectDate(DateTime(2026, 1, 10));
    vm.selectToday();
    expect(vm.displayedMonth, DateTime(2026, 4, 1));
    expect(vm.selectedDate, DateTime(2026, 4, 18));
  });

  test('B4: goToMonth does not change selectedDate', () {
    vm.selectDate(DateTime(2026, 4, 18));
    vm.goToMonth(DateTime(2026, 5, 1));
    expect(vm.selectedDate, DateTime(2026, 4, 18));
    expect(vm.displayedMonth, DateTime(2026, 5, 1));
  });

  test('B5: selectHour(null) falls back to now()-based hour', () {
    vm.selectDate(DateTime(2026, 4, 18));
    vm.selectHour('未');
    vm.selectHour(null);
    expect(vm.currentHourAlmanac.zhi, isNotEmpty);
  });

  test('B6: isDisplayedMonthToday true for today month, false otherwise', () {
    expect(vm.isDisplayedMonthToday, isTrue);
    vm.goToMonth(DateTime(2026, 5, 1));
    expect(vm.isDisplayedMonthToday, isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/viewmodels/calendar_viewmodel_test.dart`
Expected: All fail — `CalendarViewModel` not defined.

- [ ] **Step 3: Write the implementation**

`lib/presentation/screens/calendar/calendar_viewmodel.dart`：

```dart
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../domain/services/shared/almanac_service.dart';
import '../../../models/daily_almanac.dart';

class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required AlmanacService service,
    DateTime Function()? now,
  })  : _service = service,
        _now = now ?? DateTime.now {
    final today = _dateOnly(_now());
    _selectedDate = today;
    _displayedMonth = DateTime(today.year, today.month, 1);
  }

  static const int _cacheCap = 90;
  static const _zhiByHour = [
    '子', '丑', '丑', '寅', '寅', '卯', '卯', '辰', '辰', '巳', '巳',
    '午', '午', '未', '未', '申', '申', '酉', '酉', '戌', '戌', '亥', '亥', '子',
  ];

  final AlmanacService _service;
  final DateTime Function() _now;
  final LinkedHashMap<DateTime, DailyAlmanac> _cache = LinkedHashMap();

  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  String? _selectedHour;

  DateTime get displayedMonth => _displayedMonth;
  DateTime get selectedDate => _selectedDate;
  String? get selectedHour => _selectedHour;

  void selectDate(DateTime date) {
    final d = _dateOnly(date);
    if (d == _selectedDate) return;
    _selectedDate = d;
    _prime(d);
    notifyListeners();
  }

  void selectHour(String? zhi) {
    _selectedHour = zhi;
    notifyListeners();
  }

  void goToMonth(DateTime anyDateInMonth) {
    var m = DateTime(anyDateInMonth.year, anyDateInMonth.month, 1);
    // clamp 到 [1900-01, 2099-12]
    if (m.year < 1900) m = DateTime(1900, 1, 1);
    if (m.year > 2099) m = DateTime(2099, 12, 1);
    if (m == _displayedMonth) return;
    _displayedMonth = m;
    notifyListeners();
  }

  void selectToday() {
    final today = _dateOnly(_now());
    _selectedDate = today;
    _displayedMonth = DateTime(today.year, today.month, 1);
    _selectedHour = null;
    _prime(today);
    notifyListeners();
  }

  DailyAlmanac get currentAlmanac {
    final d = _selectedDate;
    return _cache.putIfAbsent(d, () {
      final v = _service.getDay(d);
      _evictIfNeeded();
      return v;
    });
  }

  HourAlmanac get currentHourAlmanac {
    final hours = currentAlmanac.twelveHours;
    if (_selectedHour != null) {
      return hours.firstWhere(
        (h) => h.zhi == _selectedHour,
        orElse: () => hours.first,
      );
    }
    final nowHour = _now().hour;
    final zhi = _zhiByHour[nowHour];
    return hours.firstWhere((h) => h.zhi == zhi, orElse: () => hours.first);
  }

  bool get isDisplayedMonthToday {
    final today = _dateOnly(_now());
    return _displayedMonth.year == today.year &&
        _displayedMonth.month == today.month;
  }

  void _prime(DateTime d) {
    if (_cache.containsKey(d)) {
      // LRU: 移到末尾
      final v = _cache.remove(d);
      _cache[d] = v!;
      return;
    }
    _cache[d] = _service.getDay(d);
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    while (_cache.length > _cacheCap) {
      _cache.remove(_cache.keys.first);
    }
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/viewmodels/calendar_viewmodel_test.dart`
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/calendar/calendar_viewmodel.dart test/unit/viewmodels/calendar_viewmodel_test.dart
git commit -m "feat(calendar): CalendarViewModel with 90-day LRU cache"
```

---

## Task 5: MonthCellInfo helper

**Files:**
- Create: `lib/presentation/screens/calendar/month_cell_info.dart`
- Test: `test/presentation/screens/calendar/month_cell_info_test.dart`

- [ ] **Step 1: Write the failing test**

`test/presentation/screens/calendar/month_cell_info_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/month_cell_info.dart';

void main() {
  group('MonthCellInfo.of', () {
    test('ordinary day has no dots', () {
      final info = MonthCellInfo.of(DateTime(2026, 4, 19));
      expect(info.hasJieQi, isFalse);
      expect(info.hasMoonPhase, isFalse);
      expect(info.hasFestival, isFalse);
    });

    test('solar term day has jieQi dot and label', () {
      // 清明 2026 约 4-05
      final info = MonthCellInfo.of(DateTime(2026, 4, 5));
      expect(info.hasJieQi, isTrue);
      expect(info.label, isNotEmpty);  // 节气名或农历日
    });

    test('2026-01-01 has festival dot (元旦)', () {
      final info = MonthCellInfo.of(DateTime(2026, 1, 1));
      expect(info.hasFestival, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/calendar/month_cell_info_test.dart`
Expected: FAIL — `MonthCellInfo` undefined.

- [ ] **Step 3: Write the implementation**

`lib/presentation/screens/calendar/month_cell_info.dart`：

```dart
import 'package:lunar/lunar.dart';

/// 月视图单格的轻量信息（不经 AlmanacService）。
/// 每月渲染 42 个格子，为避免构造 42 个完整 DailyAlmanac，
/// 这里只取几个便宜的 lunar 字段。
class MonthCellInfo {
  final int solarDay;              // 公历日（给 UI 显示）
  final String label;              // 节气名 or "初X"
  final bool hasJieQi;
  final bool hasMoonPhase;         // 朔/望/上弦/下弦
  final bool hasFestival;          // 传统/公历任一节日

  const MonthCellInfo({
    required this.solarDay,
    required this.label,
    required this.hasJieQi,
    required this.hasMoonPhase,
    required this.hasFestival,
  });

  static const _moonMilestones = {'朔', '望', '上弦', '下弦'};

  factory MonthCellInfo.of(DateTime date) {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final jieQi = lunar.getJieQi();
    final yueXiang = lunar.getYueXiang();

    final hasFestival = lunar.getFestivals().isNotEmpty ||
        lunar.getOtherFestivals().isNotEmpty ||
        solar.getFestivals().isNotEmpty ||
        solar.getOtherFestivals().isNotEmpty;

    final label = jieQi.isNotEmpty ? jieQi : lunar.getDayInChinese();

    return MonthCellInfo(
      solarDay: date.day,
      label: label,
      hasJieQi: jieQi.isNotEmpty,
      hasMoonPhase: _moonMilestones.contains(yueXiang),
      hasFestival: hasFestival,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/calendar/month_cell_info_test.dart`
Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/calendar/month_cell_info.dart test/presentation/screens/calendar/month_cell_info_test.dart
git commit -m "feat(calendar): MonthCellInfo lightweight cell data"
```

---

## Task 6: CalendarScreen skeleton (chromeless)

**Files:**
- Create: `lib/presentation/screens/calendar/calendar_screen.dart`
- Test: `test/presentation/screens/calendar/calendar_screen_test.dart`

目标：`CalendarScreen(chromeless: true)` 渲染顶栏 + 月视图占位 + Divider + 日详情占位。C1-C4 Widget 测试部分通过（C3/C5 在后续任务补齐）。

- [ ] **Step 1: Write the failing widget tests**

`test/presentation/screens/calendar/calendar_screen_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_screen.dart';

void main() {
  Future<void> pump(WidgetTester t, {bool chromeless = true}) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CalendarScreen(chromeless: chromeless),
      ),
    ));
  }

  testWidgets('C1: chromeless=true does not introduce Scaffold/AppBar', (t) async {
    await pump(t, chromeless: true);
    // 在 CalendarScreen 子树中不应出现 Scaffold/AppBar（外层 MaterialApp 的 Scaffold 不算）
    final calendarFinder = find.byType(CalendarScreen);
    final appBars = find.descendant(
      of: calendarFinder,
      matching: find.byType(AppBar),
    );
    expect(appBars, findsNothing);
  });

  testWidgets('C4: "今日" button hidden on today month, visible after switching', (t) async {
    await pump(t, chromeless: true);
    expect(find.text('今日'), findsNothing);

    // 翻到下个月：点 forward 箭头
    final forward = find.byKey(const Key('calendar-forward'));
    expect(forward, findsOneWidget);
    await t.tap(forward);
    await t.pumpAndSettle();

    expect(find.text('今日'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/calendar/calendar_screen_test.dart`
Expected: FAIL — `CalendarScreen` not found.

- [ ] **Step 3: Write the minimal CalendarScreen**

`lib/presentation/screens/calendar/calendar_screen.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/shared/almanac_service.dart';
import '../../widgets/antique/antique.dart';
import 'calendar_viewmodel.dart';
import 'day_detail_view.dart';
import 'month_grid_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.chromeless = false,
    this.viewModel,
    this.almanacService,
    this.now,
  });

  final bool chromeless;
  final CalendarViewModel? viewModel;
  final AlmanacService? almanacService;
  final DateTime Function()? now;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarViewModel _vm;
  late final bool _ownsVm;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _vm = widget.viewModel!;
      _ownsVm = false;
    } else {
      _vm = CalendarViewModel(
        service: widget.almanacService ?? const AlmanacService(),
        now: widget.now,
      );
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsVm) _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ChangeNotifierProvider<CalendarViewModel>.value(
      value: _vm,
      child: const _CalendarBody(),
    );
    if (widget.chromeless) return body;
    return AntiqueScaffold(
      appBar: const AntiqueAppBar(title: '历法'),
      body: body,
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Topbar(),
        const AntiqueDivider(),
        const MonthGridView(),
        const AntiqueDivider(),
        const Expanded(child: DayDetailView()),
      ],
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final m = vm.displayedMonth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('calendar-backward'),
            icon: const Icon(Icons.chevron_left, color: AppColors.xuanse),
            onPressed: () => vm.goToMonth(
              DateTime(m.year, m.month - 1, 1),
            ),
          ),
          Expanded(
            child: Center(
              child: InkWell(
                key: const Key('calendar-month-title'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: m,
                    firstDate: DateTime(1900, 1, 1),
                    lastDate: DateTime(2099, 12, 31),
                    helpText: '选择月份',
                    fieldLabelText: '年月',
                  );
                  if (picked != null) {
                    vm.goToMonth(DateTime(picked.year, picked.month, 1));
                  }
                },
                child: Text(
                  '${m.year}年${m.month}月',
                  style: AppTextStyles.antiqueTitle.copyWith(
                    color: AppColors.xuanse,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('calendar-forward'),
            icon: const Icon(Icons.chevron_right, color: AppColors.xuanse),
            onPressed: () => vm.goToMonth(
              DateTime(m.year, m.month + 1, 1),
            ),
          ),
          if (!vm.isDisplayedMonthToday)
            TextButton(
              onPressed: vm.selectToday,
              child: const Text('今日'),
            ),
        ],
      ),
    );
  }
}
```

先创建空的 `month_grid_view.dart` 与 `day_detail_view.dart` 让编译通过：

```dart
// lib/presentation/screens/calendar/month_grid_view.dart
import 'package:flutter/material.dart';

class MonthGridView extends StatelessWidget {
  const MonthGridView({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 300);
}
```

```dart
// lib/presentation/screens/calendar/day_detail_view.dart
import 'package:flutter/material.dart';

class DayDetailView extends StatelessWidget {
  const DayDetailView({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/calendar/calendar_screen_test.dart`
Expected: C1 + C4 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/calendar/calendar_screen.dart \
        lib/presentation/screens/calendar/month_grid_view.dart \
        lib/presentation/screens/calendar/day_detail_view.dart \
        test/presentation/screens/calendar/calendar_screen_test.dart
git commit -m "feat(calendar): CalendarScreen skeleton with topbar and today button"
```

---

## Task 7: MonthGridView (6×7 grid)

**Files:**
- Modify: `lib/presentation/screens/calendar/month_grid_view.dart`
- Test: `test/presentation/screens/calendar/month_grid_view_test.dart`

- [ ] **Step 1: Write the failing test**

`test/presentation/screens/calendar/month_grid_view_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_viewmodel.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/month_grid_view.dart';

void main() {
  Future<void> pump(WidgetTester t, CalendarViewModel vm) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider.value(
          value: vm,
          child: const MonthGridView(),
        ),
      ),
    ));
  }

  testWidgets('Tapping a day updates selectedDate', (t) async {
    final vm = CalendarViewModel(
      service: const AlmanacService(),
      now: () => DateTime(2026, 4, 18, 10),
    );
    await pump(t, vm);
    await t.pumpAndSettle();

    // 找到某日文本，点击（例如本月的 10 号）
    final day10 = find.text('10').first;
    await t.tap(day10);
    await t.pumpAndSettle();

    expect(vm.selectedDate, DateTime(2026, 4, 10));
  });

  testWidgets('Current month has 42 cells (6 rows × 7 cols)', (t) async {
    final vm = CalendarViewModel(
      service: const AlmanacService(),
      now: () => DateTime(2026, 4, 18, 10),
    );
    await pump(t, vm);
    await t.pumpAndSettle();

    final cells = find.byKey(const ValueKey('month-cell'));
    expect(cells, findsNWidgets(42));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/calendar/month_grid_view_test.dart`
Expected: FAIL — no cells render yet.

- [ ] **Step 3: Implement the month grid**

`lib/presentation/screens/calendar/month_grid_view.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'calendar_viewmodel.dart';
import 'month_cell_info.dart';

class MonthGridView extends StatelessWidget {
  const MonthGridView({super.key});

  static const _weekdayHeaders = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final days = _buildDays(vm.displayedMonth);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: _weekdayHeaders
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w,
                            style: AppTextStyles.antiqueLabel.copyWith(
                              color: AppColors.huise,
                            )),
                      ),
                    ))
                .toList(),
          ),
        ),
        for (int row = 0; row < 6; row++)
          SizedBox(
            height: 48,
            child: Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _Cell(
                      date: days[row * 7 + col],
                      inMonth:
                          days[row * 7 + col].month == vm.displayedMonth.month,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 返回 42 天（本月首日向前补齐到周日，向后补齐到周六）
  List<DateTime> _buildDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    // Dart: Monday=1..Sunday=7；我们要周日列在第 0 位
    final offsetFromSunday = first.weekday % 7;  // Sunday->0, Mon->1..
    final gridStart = first.subtract(Duration(days: offsetFromSunday));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.date, required this.inMonth});
  final DateTime date;
  final bool inMonth;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final info = MonthCellInfo.of(date);
    final today = DateTime.now();
    final isToday = _sameDay(date, today);
    final isSelected = _sameDay(date, vm.selectedDate);

    final bg = isToday
        ? AppColors.danjinLight
        : isSelected
            ? AppColors.xiangseLight
            : null;
    final border = isToday
        ? Border.all(color: AppColors.dailan, width: 1.2)
        : null;

    return InkWell(
      key: const ValueKey('month-cell'),
      onTap: () => vm.selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTextStyles.antiqueSection.copyWith(
                color: inMonth ? AppColors.xuanse : AppColors.huiseLight,
              ),
            ),
            Text(
              info.label,
              style: AppTextStyles.antiqueLabel.copyWith(
                color: inMonth ? AppColors.huise : AppColors.huiseLight,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            _Dots(info: info),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.info});
  final MonthCellInfo info;

  @override
  Widget build(BuildContext context) {
    final dots = <Widget>[];
    if (info.hasJieQi) dots.add(_dot(AppColors.zhusha));
    if (info.hasMoonPhase) dots.add(_dot(AppColors.danjin));
    if (info.hasFestival) dots.add(_dot(AppColors.dailan));
    if (dots.isEmpty) return const SizedBox(height: 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final d in dots) Padding(padding: const EdgeInsets.all(1), child: d),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
```

> 颜色 token 名称 (`danjinLight`, `xiangseLight`, `dailan`, `zhusha` 等) 若项目中真实命名不同，实现阶段按 `AppColors` 实际导出调整。实现者先打开 `lib/core/theme/app_colors.dart` 核对可用 token。

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/calendar/month_grid_view_test.dart`
Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/calendar/month_grid_view.dart test/presentation/screens/calendar/month_grid_view_test.dart
git commit -m "feat(calendar): MonthGridView with 42-cell grid and tap-to-select"
```

---

## Task 8: FestivalBanner widget

**Files:**
- Create: `lib/presentation/screens/calendar/widgets/festival_banner.dart`

- [ ] **Step 1: Write the test**

Append to `test/presentation/screens/calendar/day_detail_view_test.dart`（文件新建）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/festival_banner.dart';

void main() {
  testWidgets('FestivalBanner hides when festivals is empty', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: FestivalBanner(festivals: [])),
    ));
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('FestivalBanner shows names joined by ·', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: FestivalBanner(festivals: ['春节', '情人节'])),
    ));
    expect(find.text('春节 · 情人节'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/calendar/day_detail_view_test.dart`
Expected: FAIL — `FestivalBanner` undefined.

- [ ] **Step 3: Implementation**

`lib/presentation/screens/calendar/widgets/festival_banner.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FestivalBanner extends StatelessWidget {
  const FestivalBanner({super.key, required this.festivals});
  final List<String> festivals;

  @override
  Widget build(BuildContext context) {
    if (festivals.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.zhusha,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        festivals.join(' · '),
        style: AppTextStyles.antiqueSection.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/calendar/day_detail_view_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/calendar/widgets/festival_banner.dart test/presentation/screens/calendar/day_detail_view_test.dart
git commit -m "feat(calendar): FestivalBanner renders festival names"
```

---

## Task 9: AlmanacHeader widget

**Files:**
- Create: `lib/presentation/screens/calendar/widgets/almanac_header.dart`

- [ ] **Step 1: Implementation (widget only, visual coverage via golden later)**

`lib/presentation/screens/calendar/widgets/almanac_header.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';

class AlmanacHeader extends StatelessWidget {
  const AlmanacHeader({super.key, required this.almanac});
  final DailyAlmanac almanac;

  @override
  Widget build(BuildContext context) {
    final d = almanac.date;
    final primaryLine = '${d.year}年${d.month}月${d.day}日 · '
        '${almanac.weekday} · ${almanac.lunarDate}';
    final secondaryLine = almanac.currentJieQi != null
        ? '今日节气：${almanac.currentJieQi}'
        : '距${almanac.nextJieQi} ${almanac.nextJieQiDaysAway} 天';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(primaryLine, style: AppTextStyles.antiqueTitle.copyWith(
            color: AppColors.xuanse,
          )),
          const SizedBox(height: 4),
          Text(secondaryLine, style: AppTextStyles.antiqueBody.copyWith(
            color: AppColors.huise,
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Smoke widget test**

Append to `test/presentation/screens/calendar/day_detail_view_test.dart`：

```dart
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/almanac_header.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';

DailyAlmanac _fixture({
  String? currentJieQi,
  String nextJieQi = '立夏',
  int nextJieQiDaysAway = 17,
}) =>
    DailyAlmanac(
      date: DateTime(2026, 4, 18),
      lunarDate: '农历三月初二',
      weekday: '星期六',
      currentJieQi: currentJieQi,
      nextJieQi: nextJieQi,
      nextJieQiDaysAway: nextJieQiDaysAway,
      yearGZ: '丙午',
      monthGZ: '壬辰',
      dayGZ: '乙卯',
      yueXiang: '上弦',
      kongWang: ['子', '丑'],
      yi: ['祭祀'],
      ji: ['动土'],
      pengZuGan: '甲不开仓',
      pengZuZhi: '子不问卜',
      festivals: [],
      twelveHours: [],
    );

void mainAlmanacHeader() {
  testWidgets('AlmanacHeader shows primary + secondary lines', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: AlmanacHeader(almanac: _fixture())),
    ));
    expect(find.textContaining('2026年4月18日'), findsOneWidget);
    expect(find.textContaining('立夏'), findsOneWidget);
  });
}
```

（把 `mainAlmanacHeader()` 的内容合并进 `main()` 的 group；上面用单独函数名只是避免多 main 冲突）

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/calendar/widgets/almanac_header.dart test/presentation/screens/calendar/day_detail_view_test.dart
git commit -m "feat(calendar): AlmanacHeader with date, weekday, lunar and jieqi"
```

---

## Task 10: FourPillarsCard widget

**Files:**
- Create: `lib/presentation/screens/calendar/widgets/four_pillars_card.dart`

- [ ] **Step 1: Implementation**

`lib/presentation/screens/calendar/widgets/four_pillars_card.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';
import '../../../widgets/antique/antique.dart';

class FourPillarsCard extends StatelessWidget {
  const FourPillarsCard({
    super.key,
    required this.almanac,
    required this.hourGanZhi,
  });

  final DailyAlmanac almanac;
  final String hourGanZhi;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _pillar('年柱', almanac.yearGZ),
          _pillar('月柱', almanac.monthGZ),
          _pillar('日柱', almanac.dayGZ),
          _pillar('时柱', hourGanZhi),
        ],
      ),
    );
  }

  Widget _pillar(String label, String gz) => Column(
        children: [
          Text(label, style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.huise,
          )),
          const SizedBox(height: 4),
          Text(gz, style: AppTextStyles.antiqueSection.copyWith(
            color: AppColors.xuanse,
            fontWeight: FontWeight.w600,
          )),
        ],
      );
}
```

> `AntiqueCard` 构造参数若实际不支持 `margin/padding`，按真实签名调整。实现者打开 `lib/presentation/widgets/antique/antique_card.dart` 核对一次。

- [ ] **Step 2: Smoke test**

在 `day_detail_view_test.dart` 中增补：

```dart
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/four_pillars_card.dart';

testWidgets('FourPillarsCard shows 4 gz pairs', (t) async {
  await t.pumpWidget(MaterialApp(
    home: Scaffold(body: FourPillarsCard(
      almanac: _fixture(),
      hourGanZhi: '庚午',
    )),
  ));
  expect(find.text('丙午'), findsOneWidget);
  expect(find.text('壬辰'), findsOneWidget);
  expect(find.text('乙卯'), findsOneWidget);
  expect(find.text('庚午'), findsOneWidget);
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/calendar/widgets/four_pillars_card.dart test/presentation/screens/calendar/day_detail_view_test.dart
git commit -m "feat(calendar): FourPillarsCard with 4-column year/month/day/hour gz"
```

---

## Task 11: YijiPanel widget (宜/忌双列)

**Files:**
- Create: `lib/presentation/screens/calendar/widgets/yiji_panel.dart`

- [ ] **Step 1: Implementation**

`lib/presentation/screens/calendar/widgets/yiji_panel.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../widgets/antique/antique.dart';

class YijiPanel extends StatelessWidget {
  const YijiPanel({super.key, required this.yi, required this.ji});
  final List<String> yi;
  final List<String> ji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Column(
              title: '宜',
              items: yi,
              titleColor: AppColors.danjin,
              bgColor: AppColors.danjinLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Column(
              title: '忌',
              items: ji,
              titleColor: AppColors.zhusha,
              bgColor: AppColors.zhushaLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.items,
    required this.titleColor,
    required this.bgColor,
  });
  final String title;
  final List<String> items;
  final Color titleColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      padding: const EdgeInsets.all(10),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.antiqueSection.copyWith(
            color: titleColor,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text('—', style: AppTextStyles.antiqueBody.copyWith(
              color: AppColors.huiseLight,
            ))
          else
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('· $e', style: AppTextStyles.antiqueBody),
                )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Smoke test**

```dart
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/yiji_panel.dart';

testWidgets('YijiPanel shows yi and ji items', (t) async {
  await t.pumpWidget(const MaterialApp(
    home: Scaffold(body: YijiPanel(yi: ['祭祀', '祈福'], ji: ['动土'])),
  ));
  expect(find.text('· 祭祀'), findsOneWidget);
  expect(find.text('· 祈福'), findsOneWidget);
  expect(find.text('· 动土'), findsOneWidget);
});

testWidgets('YijiPanel shows em-dash when list is empty', (t) async {
  await t.pumpWidget(const MaterialApp(
    home: Scaffold(body: YijiPanel(yi: [], ji: [])),
  ));
  expect(find.text('—'), findsNWidgets(2));
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/calendar/widgets/yiji_panel.dart test/presentation/screens/calendar/day_detail_view_test.dart
git commit -m "feat(calendar): YijiPanel with yi/ji two-column layout"
```

---

## Task 12: TimeHourBar widget (12 时辰横向条)

**Files:**
- Create: `lib/presentation/screens/calendar/widgets/time_hour_bar.dart`

- [ ] **Step 1: Implementation**

`lib/presentation/screens/calendar/widgets/time_hour_bar.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';

class TimeHourBar extends StatelessWidget {
  const TimeHourBar({
    super.key,
    required this.hours,
    required this.selectedZhi,
    required this.onSelect,
  });

  final List<HourAlmanac> hours;
  final String? selectedZhi;
  final void Function(String zhi) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final h = hours[i];
          final selected = h.zhi == selectedZhi;
          final luckColor = h.luck == '吉' ? AppColors.danjin : AppColors.zhusha;
          return InkWell(
            key: ValueKey('hour-${h.zhi}'),
            onTap: () => onSelect(h.zhi),
            child: Container(
              width: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? AppColors.xiangseLight : null,
                border: Border.all(
                  color: luckColor,
                  width: selected ? 1.4 : 0.8,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${h.zhi}时',
                      style: AppTextStyles.antiqueBody.copyWith(
                        color: AppColors.xuanse,
                      )),
                  Text(h.huangHei == '黄' ? '黄道' : '黑道',
                      style: AppTextStyles.antiqueLabel.copyWith(
                        color: AppColors.huise,
                        fontSize: 10,
                      )),
                  Text(h.luck,
                      style: AppTextStyles.antiqueLabel.copyWith(
                        color: luckColor,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Smoke test**

```dart
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/time_hour_bar.dart';

HourAlmanac _h(String zhi, String luck) => HourAlmanac(
  zhi: zhi, ganZhi: '$zhi$zhi', tianShen: '青龙',
  huangHei: '黄', luck: luck, yi: [], ji: [],
  startHour: 0, endHour: 2,
);

testWidgets('TimeHourBar fires onSelect with tapped zhi', (t) async {
  String? picked;
  await t.pumpWidget(MaterialApp(
    home: Scaffold(body: TimeHourBar(
      hours: [_h('子', '吉'), _h('丑', '凶'), _h('寅', '吉')],
      selectedZhi: null,
      onSelect: (z) => picked = z,
    )),
  ));
  await t.tap(find.byKey(const ValueKey('hour-丑')));
  await t.pumpAndSettle();
  expect(picked, '丑');
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/calendar/widgets/time_hour_bar.dart test/presentation/screens/calendar/day_detail_view_test.dart
git commit -m "feat(calendar): TimeHourBar with 12-hour scrollable row"
```

---

## Task 13: MoonPhaseKongwang + PengzuCard widgets

**Files:**
- Create: `lib/presentation/screens/calendar/widgets/moon_phase_kongwang.dart`
- Create: `lib/presentation/screens/calendar/widgets/pengzu_card.dart`

- [ ] **Step 1: Implementations**

`moon_phase_kongwang.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MoonPhaseKongwang extends StatelessWidget {
  const MoonPhaseKongwang({
    super.key,
    required this.yueXiang,
    required this.kongWang,
  });
  final String yueXiang;
  final List<String> kongWang;

  @override
  Widget build(BuildContext context) {
    final kw = kongWang.isEmpty ? '—' : kongWang.join('');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '月相：$yueXiang · 空亡：$kw',
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.huise),
      ),
    );
  }
}
```

`pengzu_card.dart`：

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../widgets/antique/antique.dart';

class PengzuCard extends StatelessWidget {
  const PengzuCard({super.key, required this.gan, required this.zhi});
  final String gan;
  final String zhi;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('彭祖百忌',
              style: AppTextStyles.antiqueSection.copyWith(
                color: AppColors.xuanse,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text(gan, style: AppTextStyles.antiqueBody),
          Text(zhi, style: AppTextStyles.antiqueBody),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Smoke tests**

```dart
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/moon_phase_kongwang.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/pengzu_card.dart';

testWidgets('MoonPhaseKongwang renders combined string', (t) async {
  await t.pumpWidget(const MaterialApp(home: Scaffold(body:
    MoonPhaseKongwang(yueXiang: '上弦', kongWang: ['子', '丑']))));
  expect(find.text('月相：上弦 · 空亡：子丑'), findsOneWidget);
});

testWidgets('PengzuCard shows gan and zhi lines', (t) async {
  await t.pumpWidget(const MaterialApp(home: Scaffold(body:
    PengzuCard(gan: '甲不开仓', zhi: '子不问卜'))));
  expect(find.text('甲不开仓'), findsOneWidget);
  expect(find.text('子不问卜'), findsOneWidget);
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/calendar/widgets/moon_phase_kongwang.dart \
        lib/presentation/screens/calendar/widgets/pengzu_card.dart \
        test/presentation/screens/calendar/day_detail_view_test.dart
git commit -m "feat(calendar): MoonPhaseKongwang + PengzuCard widgets"
```

---

## Task 14: DayDetailView — compose 7 modules + C3/C5 tests

**Files:**
- Modify: `lib/presentation/screens/calendar/day_detail_view.dart`
- Modify: `test/presentation/screens/calendar/calendar_screen_test.dart` (C3, C5)

- [ ] **Step 1: Write the failing tests (C3 + C5)**

Append to `test/presentation/screens/calendar/calendar_screen_test.dart`：

```dart
import 'package:wanxiang_paipan/domain/services/shared/almanac_service.dart';

testWidgets('C3: tapping a day updates DayDetailView', (t) async {
  await t.pumpWidget(MaterialApp(home: Scaffold(
    body: CalendarScreen(
      chromeless: true,
      almanacService: const AlmanacService(),
      now: () => DateTime(2026, 4, 18, 10),
    ),
  )));
  await t.pumpAndSettle();

  // 初始显示 18 日
  expect(find.textContaining('2026年4月18日'), findsOneWidget);

  await t.tap(find.text('10').first);
  await t.pumpAndSettle();

  expect(find.textContaining('2026年4月10日'), findsOneWidget);
});

testWidgets('C5: tapping 未时 hour updates four-pillars 时柱', (t) async {
  await t.pumpWidget(MaterialApp(home: Scaffold(
    body: CalendarScreen(
      chromeless: true,
      almanacService: const AlmanacService(),
      now: () => DateTime(2026, 4, 18, 10),
    ),
  )));
  await t.pumpAndSettle();

  // 当前为午时（10:00）；点未时后 FourPillarsCard 时柱应变化
  final before = t.widget<Text>(find.byKey(const Key('pillar-hour-gz')));
  await t.tap(find.byKey(const ValueKey('hour-未')));
  await t.pumpAndSettle();
  final after = t.widget<Text>(find.byKey(const Key('pillar-hour-gz')));
  expect(before.data, isNot(equals(after.data)));
});
```

> `pillar-hour-gz` Key 将在 Step 3 的 FourPillarsCard 中补上；回到 `four_pillars_card.dart` 为时柱 gz Text 加 `key: const Key('pillar-hour-gz')`。

- [ ] **Step 2: Add Key to FourPillarsCard 时柱 gz**

在 Task 10 的 `_pillar` 方法中对"时柱"一列的 gz Text 加 key。修改为：

```dart
Widget _pillar(String label, String gz, {Key? gzKey}) => Column(
  children: [
    Text(label, ...),
    const SizedBox(height: 4),
    Text(gz, key: gzKey, style: ...),
  ],
);
```

调用处：

```dart
_pillar('时柱', hourGanZhi, gzKey: const Key('pillar-hour-gz')),
```

- [ ] **Step 3: Compose DayDetailView**

`lib/presentation/screens/calendar/day_detail_view.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'calendar_viewmodel.dart';
import 'widgets/almanac_header.dart';
import 'widgets/festival_banner.dart';
import 'widgets/four_pillars_card.dart';
import 'widgets/moon_phase_kongwang.dart';
import 'widgets/pengzu_card.dart';
import 'widgets/time_hour_bar.dart';
import 'widgets/yiji_panel.dart';

class DayDetailView extends StatefulWidget {
  const DayDetailView({super.key});

  @override
  State<DayDetailView> createState() => _DayDetailViewState();
}

class _DayDetailViewState extends State<DayDetailView> {
  final ScrollController _scroll = ScrollController();
  DateTime? _lastSelected;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final almanac = vm.currentAlmanac;
    final hour = vm.currentHourAlmanac;

    // 选中日变了 → 滚到顶
    if (_lastSelected != vm.selectedDate) {
      _lastSelected = vm.selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }

    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FestivalBanner(festivals: almanac.festivals),
          AlmanacHeader(almanac: almanac),
          FourPillarsCard(almanac: almanac, hourGanZhi: hour.ganZhi),
          YijiPanel(yi: almanac.yi, ji: almanac.ji),
          TimeHourBar(
            hours: almanac.twelveHours,
            selectedZhi: vm.selectedHour ?? hour.zhi,
            onSelect: vm.selectHour,
          ),
          MoonPhaseKongwang(
            yueXiang: almanac.yueXiang,
            kongWang: almanac.kongWang,
          ),
          PengzuCard(gan: almanac.pengZuGan, zhi: almanac.pengZuZhi),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run all calendar tests**

Run: `flutter test test/presentation/screens/calendar/ test/unit/services/ test/unit/viewmodels/`
Expected: 全部通过。

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/calendar/day_detail_view.dart \
        lib/presentation/screens/calendar/widgets/four_pillars_card.dart \
        test/presentation/screens/calendar/calendar_screen_test.dart
git commit -m "feat(calendar): DayDetailView composes 7 modules with scroll-to-top on date change"
```

---

## Task 15: Integrate into HomeScreen

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Replace `_buildCalendarContent()` with CalendarScreen**

打开 `lib/presentation/screens/home/home_screen.dart`，顶部 import 增加：

```dart
import '../calendar/calendar_screen.dart';
```

在 switch 里把 case 2 改为：

```dart
case 2:
  return _buildSimpleTab(
    title: '历法',
    child: const CalendarScreen(chromeless: true),
  );
```

然后删除 `_buildCalendarContent()` 方法（不再被引用）。

- [ ] **Step 2: Smoke manual check**

Run: `flutter analyze`
Expected: No issues.

假设模拟器已开（按用户偏好），直接：
Run: `flutter run`
手动：
1. 启动后 App 展示首页
2. 点底部导航"历法"
3. 验证：标题"历法"正常展示；下方直接是月视图（无双标题）；再下方是日详情，宜/忌/时辰条完整
4. 点月视图的某日 → 下方详情刷新
5. 翻下月 → 顶栏右侧"今日"按钮出现；点击回跳今日

- [ ] **Step 3: Run full test suite**

Run: `flutter test`
Expected: 全部通过（无回归）。

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/home/home_screen.dart
git commit -m "feat(calendar): wire CalendarScreen into HomeScreen calendar tab"
```

---

## Task 16: Manual QA walkthrough

- [ ] **Step 1: Run on real device/emulator**

Run: `flutter run`

- [ ] **Step 2: QA checklist**

逐项验证并截图保留（用户偏好：先在已开模拟器里跑）：

- [ ] 今日高亮：日历打开时当日格子有淡金色背景 + 黛蓝边框
- [ ] 节气日：清明日（2026-04-05）格子下方显示"清明"且有朱砂点
- [ ] 朔望日：按 lunar `getYueXiang` 计算的朔/望/上弦/下弦日格子下方有淡金点
- [ ] 节日日：元旦/春节/国庆等节日日下方有黛蓝点；点进详情顶部出现朱砂节日横幅
- [ ] 除夕→春节切换：2026-02-16 与 02-17 的 festivals 正确切换
- [ ] 子时跨日：今日 `twelveHours[子时].ganZhi` 与 `dayGZ` 若不一致（跨日），日详情 日柱列显示为 Exact2 值（可能是次日日柱）
- [ ] 时辰交互：点击未时 → 四柱卡时柱变化，其他不变
- [ ] 翻月 / 回今日按钮：切到 5 月后按钮出现；点击后月视图回 4 月、选中 18 日
- [ ] 闰月展示：切到 2025-07-25 日详情 lunarDate 含"闰六月"
- [ ] 仿古风一致性：所有卡片使用 AntiqueCard；颜色来自 AppColors；字体使用 AppTextStyles.antique*

- [ ] **Step 3: 登记已知差异（A6 月将边界 regression pin）**

对比同一节气边界日的：
- `AlmanacService.getDay(d).monthGZ`（本页用 Exact）
- `LunarService.getLunarInfo(d).monthGanZhi`（占卜链路用非 Exact）
- `YueJiangService.compute(...)` 结果

把差异点追加记录到 `docs/superpowers/specs/2026-04-19-calendar-almanac-design.md` §3.2 表末，作为后续 ADR 依据。

- [ ] **Step 4: Commit QA notes (if any divergence logged)**

```bash
git add docs/superpowers/specs/2026-04-19-calendar-almanac-design.md
git commit -m "docs(calendar): register observed time-basis divergences from QA"
```

---

## 验收标准

- ✅ `flutter test` 全部绿
- ✅ `flutter analyze` 无 error/warning
- ✅ 模拟器实机走查 Task 16 QA 清单每项通过
- ✅ 日历 Tab 从占位空壳变为完整可交互黄历视图
- ✅ 首页其他 Tab、占卜链路（六爻/大六壬）零回归

---

## 不做的事（YAGNI，与 spec §12 一致）

- 起卦辅助跳转
- 占卜日历视图
- 自建 JSON 宜忌/神煞数据
- AlmanacRepository
- `/calendar` 命名路由
- 修改 `LunarService` / `LunarInfo`
- 在 `main.dart` Provider 根树挂历法 Provider
- 跳转指定日期弹窗
- 首页"今日黄历摘要"卡
- 跨时区 / 夏令时
- 黑夜模式
- 多语言
