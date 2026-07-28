# 奇门遁甲排盘引擎规范

规则基准：时家转盘奇门；任务审定来源为
`.trellis/tasks/07-28-qimen-module/research/qimen-rule-baseline.md`。修改
`lib/domain/services/qimen/` 或 Qimen 结果 schema 前必须先读本文件。

## 边界与纯函数

- `QimenSystem` 只负责输入校验、时间/定局/盘面阶段编排和结果组装。
- 所有排盘算法是 `lib/domain/services/qimen/` 下的纯静态服务；不得访问仓储、UI 或设备状态。
- 干支、六十甲子与旬空复用 `TianGanDiZhiService`；精确节气和 Exact/Exact2 四柱只通过 `lunar` 取得。
- Qimen 在产品集成任务完成前不得加入 `registry_bootstrap.dart` 或 UI registry。

## 稳定合同

- 系统 ID 固定为 `qimen`，结果 `schemaVersion` 固定为 `1`。
- 所有 Qimen enum 使用自带 `id` 持久化；禁止使用 `enum.name`。
- `time` 只接受可选 `params`；`manual` 必须显式提供四柱、节气、阴阳遁、1..9 局与三元。
- `QimenResult.fromJson` 必须先校验 schema、system type 和 1..9 九宫完整性。
- 通用 Drift 仓储保存完整结果 JSON；不得为 Qimen 新建数据库表。

## 时间口径

- 当地民用时间使用来源 offset；未显式提供时从 `originalTime.toLocal()` 取得设备 offset。北京时间固定 UTC+8；真太阳时必须显式提供 offset 和有限的 `[-180, 180]` 经度。
- 真太阳时校正固定为 `noaa-eot-v1`：经度差 `4*(longitude-standardMeridian)` 加 NOAA 方程时近似。
- `ziInitial` 使用 `getDayInGanZhiExact()`；`midnight` 使用 `getDayInGanZhiExact2()`，时干一律按选定日干五鼠遁重算。
- `lunar` 的精确节气与 Exact 年/月柱按北京时间钟面解释。节气选择先以 `originalTime` 的绝对瞬间换算到北京时间，再把前一/当前/下一节气时刻转换到目标 offset；真太阳时对每个节气时刻单独应用校正。日/时柱继续使用选定的有效排盘墙钟。
- `originalTime` 和结果 `castTime` 统一以 UTC wire string 持久化；墙钟坐标以 UTC 字段编码但不代表绝对瞬间。历史重开只读持久化上下文。

## 定局口径

- 二十四节气三元局数表只能定义在 `QimenConstants.juBySolarTerm`。
- 拆补：日柱六十甲子索引回退 `index % 5` 至甲/己符头；符头支分上中下元。
- 茅山：精确交节所在双时辰起点起算，`<120h` 上元、`120..<240h` 中元，其后下元。
- 置闰：动态寻找上元符头和最近芒种/大雪；超神时 `chaoShenDays` 表示从符头边界到交节的完整经过日数，来源首尾包含称“十一日”时保存为 `10`。当前周期符头晚于实际交节时为接气，`isReceivingQi=true` 且 `chaoShenDays=0`，接气日数只写入推导。完整超神日数 `> 9` 时，符头起首个十五日周期已提前沿用芒种/大雪但 `isLeap=false`，第二个十五日重复周期才为 `isLeap=true`。闰中即使已过二至，`effectiveSolarTerm` 仍保存被重复的芒种/大雪；三十日结束后按实际二至重新对齐。`symbolHead` 始终保存当前五日元符头。不得回退拆补。
- 手动校盘输出同构 `QimenJuInfo(method=manual)`，并在 derivation 中记录显式事实。

## 转盘口径

- 地盘序列固定为戊己庚辛壬癸丁丙乙，阳顺阴逆飞 1..9 宫。
- 六甲遁仪、九星本位、八门本位、外八宫顺序和八神顺序仅定义在 `QimenConstants`。
- 中五宫始终保留自身地盘干、天盘干和天禽；寄宫事实写入 `hosted*` 字段，禁止覆盖主字段。
- 默认中五寄坤二，兼容口径阳遁寄艮八/阴遁寄坤二；天禽始终随天芮转布。
- 当旬首遁仪落中五时，值使门名按寄宫取门，但飞宫步数从原始五宫起算；只有最终结果落五宫时才按寄宫参数转换。
- 兼容阳遁寄艮时，中五天盘干随艮宫转动，天禽仍独立随坤二本位的天芮转动；实现不得把两种 hosted 旋转合并为同一锚点。
- 默认暗干从值使落宫起时干飞九宫；兼容口径取各门本位宫地盘干。
- 旬空按时柱，驿马按时支三合局；宫位地支来自单一 palace metadata 表。

## 测试门禁

- 来源化黄金盘：`test/unit/services/qimen/fixtures/qimen_golden_fixtures.dart`。2008-11-04 12:30 北京时间的九宫核心字段来自固定 revision 的 `3metaJun/3meta` 与 `xuanyuwang/QiMen`；两仓可能同谱系，测试必须披露并保留项目逐宫复核说明。
- 阶段测试必须覆盖阴阳九局、六旬首、两种寄宫/暗干、旬空/驿马、茅山边界和置闰前/中/后二至重排。
- 时间测试必须冻结 offset，不得依赖测试机时区。
- JSON 测试比较完整 `toJson()`；仓储测试必须覆盖保存、ID 读取、系统过滤和最近记录。

## 实施场景：时间与置闰坐标

### 1. Scope / Trigger

修改 `QimenTimeService`、`QimenTemporalContext`、`ZhiRunJuStrategy` 或任何
Qimen 时间 JSON 字段时适用。该场景防止把绝对瞬间、北京时间历法钟面和目标墙钟
混为一个 `DateTime`。

### 2. Signatures

```dart
QimenTemporalContext QimenTimeService.resolve(
  DateTime originalTime,
  QimenPanParams params,
)

QimenJuInfo ZhiRunJuStrategy.resolve(QimenTemporalContext context)
```

### 3. Contracts

- 输入 `originalTime` 是绝对瞬间；`basisWallTime` / `effectivePanTime` 是以 UTC
  字段编码的墙钟坐标。
- 年/月柱和节气选择读取北京时间历法上下文；日/时柱读取有效排盘墙钟。
- 上下文必须持久化 `previous/current/nextSolarTerm` 及其目标坐标精确时刻。
- `originalTime` / `castTime` wire string 必须以 `Z` 结尾；Qimen enum 必须用稳定 ID。
- 接气时 `isReceivingQi=true`、`chaoShenDays=0`；超神时保存完整经过日数。

### 4. Validation & Error Matrix

| 条件 | 结果 |
|---|---|
| 真太阳时缺 offset 或经度 | `ArgumentError` / `validateInput=false` |
| 经度为 NaN、Infinity 或越界 | `ArgumentError` / `validateInput=false` |
| 北京时间显式 offset 非 480 | `ArgumentError` / `validateInput=false` |
| 置闰无法找到合法符头/节气锚点 | `StateError`，禁止回退拆补 |
| 结果 schema/system/九宫不匹配 | `FormatException` |

### 5. Good / Base / Bad Cases

- Good：同一立春绝对瞬间以 `+08:00`、UTC、`+05:30` 输入，年/月柱与节气切换一致，节气墙钟按 offset 不同。
- Base：北京时间拆补盘不做校正，墙钟等于绝对瞬间加 480 分钟。
- Bad：把 UTC 墙钟直接交给 `lunar` 求精确交节，会把立春边界整体偏移八小时。

### 6. Tests Required

- 交节前一秒、当刻、后一秒：断言三种 offset 的节气、年柱、月柱一致。
- 1898-11-27 至 12-27：断言首轮、闰轮、跨冬至、重对齐、局/元/符头。
- 子初/午夜：断言 23:00 符头边界不同。
- JSON：断言绝对瞬间 UTC wire round-trip，墙钟和三段节气事实深比较不变。

### 7. Wrong vs Correct

```dart
// Wrong: target wall clock is not a Beijing lunar coordinate.
final lunar = Solar.fromDate(effectivePanTime).getLunar();
final year = lunar.getYearInGanZhiExact();

// Correct: year/month/terms use the same absolute instant in Beijing;
// day/hour remain on the selected effective wall clock.
final beijingWall = wallTimeAtOffset(originalTime, 480);
final absoluteLunar = Solar.fromDate(beijingWall).getLunar();
final effectiveLunar = Solar.fromDate(effectivePanTime).getLunar();
```
