# 历法功能（黄历 / 万年历）设计

- 日期：2026-04-19
- 状态：草案，待实现
- 范围：首页第 3 个 Tab「历法」从空壳填充为完整黄历/万年历功能
- 非范围：起卦辅助（已明确砍掉）、占卜日历回溯（不做）、云同步、多语言

---

## 1. 功能定位与范围

### 1.1 定位

纯**黄历/万年历**浏览功能。用户打开 Tab 可以：

- 逐月翻阅日历，一眼看到节气、朔望、节日分布
- 点选任一日查看完整黄历详情（干支、宜忌、时辰吉凶、月相、彭祖百忌…）
- 快速回跳今日

**不做**：不从日历跳到起卦界面；不持久化任何日历相关状态到数据库；不联网。

### 1.2 内容深度（标准档）

展示以下字段：

- 公历/农历日期、星期、节气、节气距离
- 年/月/日/时四柱干支
- 宜（`List<String>`，lunar 包提供）
- 忌（`List<String>`，lunar 包提供）
- 12 时辰吉凶（基于黄道/黑道）
- 月相
- 空亡
- 彭祖百忌（天干句 + 地支句）
- 节日（传统 + 公历法定节日**名称**；不含放假/调休）

### 1.3 视图形态

上下分屏：
- 上半屏：月视图（6×7 格子，固定高度）
- 下半屏：日详情（`Expanded` + 独立滚动，7 个模块竖向全展开）

---

## 2. 架构分层

### 2.1 新增产物

```
lib/
├─ domain/services/shared/
│   ├─ almanac_service.dart          新增：纯函数服务
│   └─ festival_resolver.dart        新增：节日名解析（非放假）
├─ models/
│   └─ daily_almanac.dart            新增：freezed 数据模型（含 HourAlmanac 子结构）
└─ presentation/screens/calendar/
    ├─ calendar_screen.dart          新增：顶层屏幕（支持 chromeless）
    ├─ calendar_viewmodel.dart       新增：ChangeNotifier（含 LRU 缓存）
    ├─ month_grid_view.dart          新增：月视图 Widget
    ├─ month_cell_info.dart          新增：月视图格子的轻量辅助（不经 AlmanacService）
    ├─ day_detail_view.dart          新增：日详情 Widget
    └─ widgets/
        ├─ almanac_header.dart       日期头 + 节气距离
        ├─ four_pillars_card.dart    四柱干支卡
        ├─ yiji_panel.dart           宜/忌双列
        ├─ time_hour_bar.dart        12 时辰吉凶条
        ├─ moon_phase_kongwang.dart  月相 + 空亡单行
        ├─ pengzu_card.dart          彭祖百忌卡
        └─ festival_banner.dart      节日横幅（当日无节日时不渲染）
```

### 2.2 修改点

- `lib/presentation/screens/home/home_screen.dart`
  - `_buildCalendarContent()` 从占位符改为 `CalendarScreen(chromeless: true)`

### 2.3 分层职责

```
Presentation (calendar/)
   ↓ listens to ChangeNotifier
ViewModel (CalendarViewModel)
   ↓ calls
Shared Service (AlmanacService.getDay)
   ↓ uses
lunar 包 (已有依赖)
```

- **不建 Repository**：黄历数据按需计算、无持久化，跳过 Repository 层
- **不建新路由**：挂 HomeScreen Tab，不需要 `/calendar` 命名路由
- **不改 LunarService / LunarInfo**：占卜链路零波及
- **不在 main.dart Provider 根树挂任何历法相关 Provider**：Provider 挂在 `CalendarScreen` 内部，对齐 `HistoryListScreen` 模式

---

## 3. 时间口径唯一化（关键约束）

### 3.1 本期口径

历法页**统一走 lunar 的 Exact2 口径**：
- 日柱：`Lunar.getDayInGanZhiExact2()`（处理早子/夜子跨日）
- 月柱：`Lunar.getMonthInGanZhiExact()`（按交节切换）
- 时柱：`Lunar.getTimeInGanZhi()`
- 年柱：按 `Solar.fromDateTime(d)` 构造的 `Lunar` 默认年柱

**所有字段来自同一 `Lunar.fromSolar(Solar.fromDateTime(d))` 实例**，绝不混调不同口径。

### 3.2 已知不一致（registered divergences，本期不强行收敛）

| 位置 | 口径 | 差异 |
|---|---|---|
| `lib/domain/services/shared/lunar_service.dart` | 非 Exact | 占卜链路，节气边界日与历法页日柱可能差一日 |
| `lib/presentation/widgets/home/time_engine_card.dart` | 直调 lunar，未核 | 需后续 ADR 统一 |
| `lib/presentation/widgets/extended_info_section.dart` | 自算中气 | 与 lunar 的 `getJie/getQi` 可能有边界差 |
| `lib/domain/services/daliuren/yue_jiang_service.dart` | 大六壬月将独立规则 | 业务特殊，保留 |

**承诺**：不新增第五套口径。后续以单独 ADR（`docs/decisions/00XX-time-basis-convergence.md`）推动现有四套向 Exact2 收敛。

### 3.3 子时跨日的展示规则

- `AlmanacService.getDay(2026-04-19 23:30)` → **按本地公历日归为 2026-04-19**
- 但其 `twelveHours[子时格].ganZhi` 使用 Exact2 → 日柱可能落到 04-20
- UI 不隐藏这个差异：`FourPillarsCard` 的"日柱"列直接呈现 Exact2 结果；当与日期头的公历日"看起来不一致"时，提供一个简短工具提示（`?` 图标悬浮/点击 → "按传统子时跨日规则，23:00 后日柱归次日"）

---

## 4. 数据模型

### 4.1 `DailyAlmanac`（freezed）

```dart
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
    required String monthGZ,           // Exact 口径
    required String dayGZ,             // Exact2 口径
    required String yueXiang,          // 月相
    required List<String> kongWang,    // 2 地支
    required List<String> yi,          // 宜
    required List<String> ji,          // 忌
    required String pengZuGan,         // "甲不开仓财物耗散"
    required String pengZuZhi,         // "子不问卜自惹祸殃"
    required List<String> festivals,   // 节日名
    required List<HourAlmanac> twelveHours,  // 固定 12 格
  }) = _DailyAlmanac;
}

@freezed
class HourAlmanac with _$HourAlmanac {
  const factory HourAlmanac({
    required String zhi,                // "子"、"丑"…
    required String ganZhi,             // "甲子"…
    required String tianShen,           // "青龙"/"明堂"…
    required String huangHei,           // "黄" / "黑"
    required String luck,               // "吉" / "凶"
    required List<String> yi,           // 时辰宜
    required List<String> ji,           // 时辰忌
    required int startHour,             // 23, 1, 3, …
    required int endHour,               // 1, 3, 5, …
  }) = _HourAlmanac;
}
```

### 4.2 数据来源映射（全部来自 lunar 包，零静态 JSON）

| 字段 | lunar API |
|---|---|
| lunarDate | `Lunar.toString()` / `getMonthInChinese()` + `getDayInChinese()`（闰月拼接） |
| currentJieQi / nextJieQi | `Lunar.getJieQi()` / `Lunar.getNextJieQi()` |
| yearGZ | `Lunar.getYearInGanZhi()` |
| monthGZ | `Lunar.getMonthInGanZhiExact()` |
| dayGZ | `Lunar.getDayInGanZhiExact2()` |
| yueXiang | `Lunar.getYueXiang()` |
| kongWang | 复用现有 `LunarService` / `TianGanDiZhiService` 算法 |
| yi / ji | `Lunar.getDayYi()` / `Lunar.getDayJi()` |
| pengZuGan / pengZuZhi | `Lunar.getPengZuGan()` / `getPengZuZhi()` |
| festivals | `FestivalResolver.resolve(date, lunar)` |
| twelveHours[i].tianShen | `LunarTime.getDayTianShen()`（12 个时辰实例分别取） |
| twelveHours[i].huangHei | `LunarUtil.TIAN_SHEN_TYPE[tianShen]` |
| twelveHours[i].yi / ji | `LunarTime.getTimeYi()` / `getTimeJi()` |

### 4.3 `FestivalResolver`

```dart
class FestivalResolver {
  /// 返回当日所有节日名（不含放假/调休）。
  /// 合并三类：
  ///   1. Lunar.getFestivals()      农历传统节日
  ///   2. Lunar.getOtherFestivals() 其他传统节日（七夕、寒食等）
  ///   3. Solar.getFestivals()      公历节日（元旦、劳动节、国庆等，由 lunar 包内置）
  ///   4. （可选）静态补名          仅当 lunar 未覆盖的公历节日名，const list
  /// 不做放假/调休判断 —— 放假表逐年变化，需年表，本期不做。
  static List<String> resolve(DateTime date, Lunar lunar);
}
```

---

## 5. 服务接口

### 5.1 `AlmanacService`

```dart
class AlmanacService {
  /// 返回某日的完整黄历信息。
  /// date 会被归一化到本地午夜（同一天任意时分秒等价）。
  /// 超出 lunar 包支持范围（< 1900 或 > 2099）抛 AlmanacError。
  DailyAlmanac getDay(DateTime date);
}

class AlmanacError implements Exception {
  final String message;
  final Object? cause;
  AlmanacError(this.message, [this.cause]);
}
```

**实现要点**：
1. 归一化：`final d = DateTime(date.year, date.month, date.day);`
2. 范围检查：`d.year` ∈ [1900, 2099]；越界抛 `AlmanacError`
3. 构造**同一** lunar 实例：`final lunar = Lunar.fromSolar(Solar.fromDateTime(d));`
4. 所有字段取自 `lunar` 及其派生的 12 个 `LunarTime`
5. **无状态、无缓存**（缓存由 ViewModel 管）

### 5.2 `CalendarViewModel`

```dart
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required AlmanacService service,
    DateTime Function()? now,
  });

  // --- 状态 ---
  DateTime get displayedMonth;   // 归一到该月 1 日 00:00
  DateTime get selectedDate;     // 归一到选中日 00:00
  String? get selectedHour;      // null = 跟当前时刻

  // --- 动作 ---
  void selectDate(DateTime date);
  void selectHour(String? zhi);
  void goToMonth(DateTime anyDateInMonth);   // 内部 clamp 到 [1900-01, 2099-12]
  void selectToday();

  // --- 派生 ---
  DailyAlmanac get currentAlmanac;
  HourAlmanac get currentHourAlmanac;
  bool get isDisplayedMonthToday;

  // --- 内部 ---
  // Map<DateTime, DailyAlmanac> _cache；cap = 90；按插入顺序 LRU 淘汰
}
```

---

## 6. UI 结构

### 6.1 CalendarScreen 骨架

```dart
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.chromeless = false,
    this.viewModel,        // 可选注入（测试）
    this.almanacService,   // 可选注入（测试）
    this.now,              // 可选注入（测试）
  });

  final bool chromeless;
  final CalendarViewModel? viewModel;
  final AlmanacService? almanacService;
  final DateTime Function()? now;
}
```

- `chromeless: true` → 返回 body Widget（Column：顶栏 + MonthGridView + Divider + Expanded(DayDetailView)）
- `chromeless: false` → 外层套 `AntiqueScaffold + AntiqueAppBar`，body 与 true 分支相同；代码量极小（仅包一层壳），对齐 `HistoryListScreen` 现有模式。本期首页 Tab 使用 true 分支；false 分支仅供未来独立路由使用，本期不主动测试
- `ChangeNotifierProvider.value(value: _vm)` 挂在 screen 内部，**不放 `main.dart` 根树**

### 6.2 尺寸分配

- 顶栏：~44dp，含左右翻月箭头 + 年月文字 + "今日"按钮
- 月视图：6 行 × 44dp ≈ 264dp（加间距约 300dp）
- Divider：1dp（`AntiqueDivider`）
- 日详情：`Expanded`，独立 `ScrollController`

### 6.3 月视图格子（已定：B 档标准格）

每格内容：
- 公历日（`AppTextStyles.antiqueSection`）
- 节气名（若当日有节气）或"初X"农历日（小字）
- 至多 3 个彩点：朱砂=节气，淡金=朔望，黛蓝=节日

格子状态样式：
| 状态 | 样式 |
|---|---|
| 今日 | 淡金色背景 + 黛蓝边框 |
| 选中日（≠ 今日） | 缃色淡底色 |
| 非当月日 | 文字 `AntiqueColors.textDisabled` |
| 普通日 | 无背景，纯文本 |

### 6.4 日详情 7 个模块

| 模块 | 原型 | 风格要点 |
|---|---|---|
| 节日横幅 | `AntiqueCard` 横条 | 朱砂底 + 白字；无节日不渲染 |
| 日期头 | 两行 Text | "2026年4月18日 星期六 · 农历三月初二" / "距立夏 17 天" |
| 四柱干支卡 | `AntiqueCard` + 4 列 | 年/月/日/时纵向；时柱随 `selectedHour` 或 now() |
| 宜忌双列 | 两列 `AntiqueCard` | 左"宜"淡金底 + 右"忌"朱砂淡底；竖排圆点 |
| 时辰条 | 横向可滚 Row（12 格） | 每格显黄/黑道 + 时辰名 + 吉/凶；点击 → 切换 FourPillarsCard 时柱 |
| 月相+空亡 | 单行 | "月相：上弦月 · 空亡：戌亥" |
| 彭祖百忌 | `AntiqueCard` | 两行干支句 |

### 6.5 仿古风 Token 使用

- 颜色：`xiangse`（选中）、`danjin`（今日背景/宜）、`dailan`（边框/节日点）、`zhusha`（节气点/忌）
- 间距：`gapTight=8`、`gapBase=12`、`gapSection=16`
- 字体：`antiqueTitle`、`antiqueSection`、`antiqueBody`、`antiqueLabel`
- 圆角：`radiusCard=8`、`radiusButton=26`
- 组件：`AntiqueCard`、`AntiqueDivider`、`AntiqueTag`（黄道/黑道标）

---

## 7. 数据流与交互

### 7.1 关键交互

| 事件 | 结果 |
|---|---|
| 翻月（箭头点击） | `vm.goToMonth(±1)` → MonthGridView 重渲；日详情**不变** |
| 点击月格子 | `vm.selectDate(date)` → DayDetailView 重渲 + 滚到顶 |
| 点击"今日"按钮 | `vm.selectToday()`；按钮 `isDisplayedMonthToday == false` 才显示 |
| 点击时辰条格子 | `vm.selectHour(zhi)` → FourPillarsCard 时柱更新，其他模块不重渲（Provider.select） |
| 点击年月文字 | 弹 `showDatePicker` 选月（第一版简化） |

### 7.2 性能

- `DailyAlmanac` 计算量：创建 1 个 Lunar + 12 个 LunarTime + 几个字段拼接，预期 < 5ms
- LRU 缓存 cap 90 天：一次连续翻月不会重复算
- 月视图单次渲 42 个格子：每格仅取 `lunar.getFestivals().isNotEmpty / getJieQi() / getYueXiang()`（轻量），不需要完整 `DailyAlmanac`。**月视图渲染不经 AlmanacService**，直接用轻量辅助函数 `MonthCellInfo.of(date)`（内部只调几个 lunar getter，不缓存）

---

## 8. 错误处理

| 场景 | 处理 |
|---|---|
| 日期超 lunar 范围（< 1900 或 > 2099） | `AlmanacService.getDay` 抛 `AlmanacError`；`CalendarViewModel.goToMonth` clamp；顶栏翻月按钮到边界禁用 |
| `Lunar.fromSolar` 抛异常 | catch → 重抛 `AlmanacError`；DayDetailView 展示 `AntiqueCard` 空态："该日期无黄历信息" |
| 时区 / 夏令时 | 按本地时区为准；不处理 UTC 跳变（中国大陆无夏令时，不是现实问题） |
| LRU 上限触达 | 静默淘汰最旧，不对用户可见 |
| 节日名解析缺失 | 静默回退到 lunar 自带列表 |

---

## 9. 导航便利性（已决）

| 功能 | 是否做 |
|---|---|
| "回今日"按钮 | ✅ 做 |
| 跳转指定日期（输入框/日历图标弹窗） | ❌ 第一版不做 |
| 首页联动（首页加"今日黄历摘要卡"） | ❌ 不做，首页保持现状 |

---

## 10. 测试矩阵

### 10.1 AlmanacService 单元测试（`test/domain/services/shared/almanac_service_test.dart`）

| # | 用例 | 断言 |
|---|---|---|
| A1 | 同日不同时分秒等价 | `getDay(d 00:00)` == `getDay(d 23:59)` |
| A2 | 交节前后同一天 | 清明交节日 04:00 vs 06:00 的 monthGZ 一致（Exact 按交节） |
| A3 | 子时跨日日柱 | `getDay(d).twelveHours[子时].ganZhi` = Exact2 结果，与 dayGZ 可能不同 |
| A4 | 除夕/春节切换 | 春节日 `festivals` 含"春节"；yearGZ 切换规则稳定 |
| A5 | 闰月展示 | 2025 闰六月某日的 `lunarDate` 含"闰六月" |
| A6 | 月将边界登记 | 与 `yue_jiang_service` 已知差异作为 regression pin |
| A7 | 越界抛错 | `getDay(1800-01-01)` throws `AlmanacError` |
| A8 | 12 时辰结构完整 | `twelveHours.length == 12`，每格字段齐全 |

### 10.2 CalendarViewModel 单元测试（`test/presentation/screens/calendar/calendar_viewmodel_test.dart`）

| # | 用例 | 断言 |
|---|---|---|
| B1 | 缓存命中 | 同日多次 `selectDate`，service 只被调一次 |
| B2 | LRU 淘汰 | 91 天后最旧被淘汰，miss 触发再调 |
| B3 | selectToday 同步 | displayedMonth 与 selectedDate 同步 |
| B4 | goToMonth 不改 selectedDate | 翻月不影响选中日 |
| B5 | selectHour(null) | currentHourAlmanac 回退到 now() 所在时辰 |
| B6 | isDisplayedMonthToday | today 月 = true，翻月后 = false |

### 10.3 CalendarScreen Widget 测试（`test/presentation/screens/calendar/calendar_screen_test.dart`）

| # | 用例 | 断言 |
|---|---|---|
| C1 | chromeless: true 无壳 | 不含 `Scaffold` / `AntiqueScaffold` / `AntiqueAppBar` |
| C2 | 嵌入 HomeScreen Tab 2 | 不出现重复标题 |
| C3 | 点击格子刷新详情 | 注入 fake service；tap → 日期文本更新 |
| C4 | "今日"按钮条件显示 | 翻下月后出现；点击后消失 |
| C5 | 时辰条交互 | tap(未时) → 四柱卡时柱更新为未时干支 |

### 10.4 Golden 测试（可选增量）

- `CalendarScreen` 默认态
- 节日横幅态
- 节气日选中态

---

## 11. 实现顺序建议（供 writing-plans 参考）

1. **Step 1**：建模 + 服务层
   - `DailyAlmanac` / `HourAlmanac` freezed + 生成
   - `AlmanacService.getDay` 实现
   - `FestivalResolver.resolve` 实现
   - A1-A8 全部单测通过

2. **Step 2**：ViewModel 层
   - `CalendarViewModel` 实现（含 LRU）
   - B1-B6 单测通过

3. **Step 3**：UI 骨架
   - `CalendarScreen`（chromeless 分支）
   - `MonthGridView`（含 MonthCellInfo 辅助）
   - `DayDetailView` 空壳（7 个子模块先占位）
   - C1-C4 Widget 测试通过

4. **Step 4**：日详情 7 个模块
   - 顺序：日期头 → 四柱卡 → 宜忌 → 时辰条 → 月相/空亡 → 彭祖 → 节日横幅
   - 每个模块完工即补对应 Widget 测试
   - C5 通过

5. **Step 5**：集成 + 打磨
   - `HomeScreen._buildCalendarContent` 切换
   - 真机走查：节气日、朔望日、节日日、除夕、闰月 2025 某日
   - Golden 补充（可选）

---

## 12. YAGNI 清单（显式不做）

- ❌ 起卦辅助（从日历跳起卦）
- ❌ 占卜记录日历视图（在格子上标记占过的日子）
- ❌ 自建宜忌 / 神煞 / 彭祖 JSON 数据（lunar 包全包）
- ❌ 自建法定节假日放假/调休年表
- ❌ `AlmanacRepository`（无持久化）
- ❌ `/calendar` 命名路由（挂 tab 即可）
- ❌ 修改 `LunarService` / `LunarInfo`
- ❌ 在 `main.dart` Provider 根树挂历法 Provider
- ❌ 跳转指定日期弹窗
- ❌ 首页"今日黄历摘要"卡
- ❌ 跨时区 / 夏令时处理
- ❌ 黑夜模式专属适配
- ❌ 多语言（英文）

---

## 13. 已知技术债与后续 ADR

- **时间口径收敛**：历法页引入 Exact2 后，项目已有 4 处时间计算仍非统一口径。后续以独立 ADR `docs/decisions/00XX-time-basis-convergence.md` 推动收敛。本期不阻塞。
- **节气边界日的展示一致性**：历法页若显示"日柱 = 甲子"，同一天同一时刻在占卜页可能显示"日柱 = 癸亥"（因 LunarService 口径不同）。本期在日详情的日柱附带工具提示说明传统子时跨日规则；跨页面展示一致性留给口径收敛 ADR。

---

## 14. 未决定（等实现时验证）

- 月视图顶栏"点击年月文字"是直接用 Flutter 默认 `showDatePicker` 还是自建仿古风年月轮盘。默认方案 = Flutter 原生 picker（快速落地）；若视觉不协调，再考虑自建。
- 12 时辰条的吉凶判定是否需要在"黄/黑道"之外再叠加一层"大吉/中吉/小凶"（lunar 未直接提供这层，需要额外规则）。默认方案 = **只用黄/黑道二分**；若用户反馈信息量不够再扩展。
