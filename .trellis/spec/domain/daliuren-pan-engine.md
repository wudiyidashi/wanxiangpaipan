# 大六壬排盘引擎规范

规则基准采用分层底本：《钦定四库全书·六壬大全》负责起例、神将、神煞、课经与毕法，《大六壬指南》负责断课；派系分歧必须经证据目录裁决，不能由现有代码反证古法。改动三传/四课逻辑前必须先读本文件；黄金课例见 `test/unit/services/daliuren/san_chuan_service_test.dart`（13 例，来源：任务 07-27-daliuren-sanchuan-fix design.md 手工推演）。

## 古籍证据门槛

- 规则来源以 `assets/data/daliuren/classics/` 的稳定 `ruleId`、`sourceRefs`、`variantGroupId` 和 `fixtureIds` 为准。只有 `evidenceLevel` 为 A/B 且 `executableApproved=true` 的条目可称为已批准古籍规则；C/D 或 `pending` 条目只能作为候选、项目基线或研究线索。
- OCR、固定转录和候选来源只能定位。没有回到明确影印页并经不同 reviewer 复核时，禁止升为 A/B；缺少独立 fixture 时，禁止仅凭页文把复杂推导标为可执行批准。
- 贵人选择、贵人所临地盘宫、实际顺逆、天盘支乘将和地盘宫落将是不同事实。昼夜只参与取贵，不能直接等同顺逆；主底本“昼顺夜逆”页明言“近不用”。
- 候选《御定六壬直指》表与当前表在甲、乙、丙、辛、壬五干的阳/阴贵均互换。现有仅交换甲日的 `jiaDayAlt` 不能代表该版本；未完成整表异文裁决前，不得用它作版本切换或古籍依据。

测试断言至少覆盖：A/B 越权失败、候选来源不进入默认算法、昼/夜与顺/逆的四类交叉盘，以及贵人表版本按整表而非单干切换。

## 场景：起课历法与月将解析

### 1. Scope / Trigger

凡新增或修改时间、报数、电脑、手工四柱入口，或消费大六壬四柱、月建、中气、月将和民用时间的 UI/formatter，都必须遵守本节。古籍只支持“随中气取将”和十二月将表；秒级交节、UTC、固定 offset 及 `lunar` 依赖行为属于 `dlr.project.pan.*` 项目历法合同，不得表述为古法。

### 2. Signatures

```dart
DlrCivilTime({
  required DateTime instant,
  required int sourceUtcOffsetMinutes,
});

DlrResolvedCastTime DlrCastTimeService.resolve(DlrCivilTime civilTime);
DlrMonthGeneralResolution YueJiangService.resolve(DlrCivilTime civilTime);
DlrMonthGeneralResolution YueJiangService.manualOverride(String yueJiang);

Future<void> DaLiuRenViewModel.castByManual({
  required String yearGanZhi,
  required String monthGanZhi,
  required String dayGanZhi,
  required String hourGanZhi,
  required String monthGeneral,
  DaLiuRenPanParams params,
});

Future<void> DaLiuRenViewModel.castByCalendarBackedManual({
  required DateTime manualCivilDateTime,
  required int sourceUtcOffsetMinutes,
  required DlrPillars expectedPillars,
  DateTime? castTime,
  DaLiuRenPanParams params,
});
```

### 3. Contracts

- `DateTime` 一律表示绝对时刻；构造 `DlrCivilTime` 时立即 `toUtc()`。`sourceUtcOffsetMinutes` 只定义来源民用墙上坐标，范围 `[-840, 840]`，不代表 IANA 时区、历史 DST、经度或真太阳时。
- 年柱、月柱和月建使用该绝对时刻的北京 UTC+8 墙上坐标及 `getYearInGanZhiExact()` / `getMonthInGanZhiExact()` / `getMonthZhiExact()`；日柱使用来源 offset 的民用午夜日界；时干必须由同一日干和民用时支按五鼠遁重算。
- 自动月将只能在北京墙上坐标调用 `getPrevQi(false)` 与 `getNextQi(false)`，把返回时刻减 480 分钟还原为 absolute instant，并验证半开区间 `[previous, next)`。恰等于中气时换将，节不换将；禁止 `getCurrentQi()`、整日匹配和月建 fallback。
- 时间、报数和电脑入口先生成同一个 `DlrResolvedCastTime`。报数/电脑只能覆盖时支，并从解析日干重算时柱；不得重新解析月将或改变年月日事实。
- `rawPillars` 必须提供合法四柱及显式月将，校验五虎遁年月干联动和五鼠遁日时干联动；不得提供 `manualCivilDateTime`，不得读取操作时间补四柱、中气或月将，结果 `civilTime=null`、`solarTerm=null`、`calendarValidated=false`。
- `calendarBacked` 必须提供带明确 zone 的 `manualCivilDateTime`、显式 offset、完整四柱和自动月将模式；四柱须与统一 resolver 逐项全等。操作 `castTime` 仅是记录创建上下文。
- `DaLiuRenResult.civilTime` 与 `monthGeneralResolution` 是新盘权威事实。结果页、预览、human formatter 与 AI `coreData` 必须消费它们和持久化 `LunarInfo`；顶层 legacy `castTime` 不得参与新盘历法重算。共享 `ExtendedInfoSection` 通过 `resolvedRows` 接收大六壬权威展示行。
- `YueJiangService.getYueJiangBySolarTerm()` / `getYueJiang()` 是 legacy/name-table helper，不是新起课 resolver；任何新权威路径不得调用它们作失败回退。

### 4. Validation & Error Matrix

| 条件 | 必须行为 |
|---|---|
| offset 非整数或越出 `[-840, 840]` | `ArgumentError`，不得读取设备时区代替显式非法值 |
| 自动中气区间不包含输入 instant、依赖返回未登记中气 | `StateError`，不得退回月建 |
| raw 缺月将、带 civil time、四柱非法或干支联动错误 | 产盘前拒绝 |
| calendar-backed 缺显式 instant/offset、使用手动月将或任一柱不一致 | 产盘前拒绝，并指出不一致柱 |
| 新结果缺可证明的历法事实 | 保持 `null/unknown`，不得用操作时刻现场补算 |

### 5. Good / Base / Bad Cases

- Good：`2022-04-20T02:24:18Z` 无论来源 offset 是 `+08:00`、UTC 或 `+05:30`，均以北京 `2022-04-20 10:24:18` 精确命中谷雨/酉将；来源 offset 只改变民用日时柱和显示。
- Base：旧 JSON 没有 `civilTime` / typed resolution 时仍可展示既有 legacy 数据，但不得伪造当前 resolver 来源。
- Bad：把 `DateTime` 墙上字段直接传给 `Solar.fromDate()`；用 `getCurrentQi()` 在交节日零点提前换将；raw 四柱从操作 `castTime` 补中气。

### 6. Tests Required

- `yue_jiang_service_test.dart`：冻结 2022 十二中气的 `t-1s/t/t+1s`、清明前中后一秒、同 instant 多 offset、typed provenance 与无 fallback。
- `dlr_cast_time_service_test.dart`：精确立春/节边界、来源 offset、民用午夜换日、年/月/日/时柱与五虎遁/五鼠遁。
- system/ViewModel/widget/formatter：四入口共享 facts、raw/calendar-backed 成功与拒绝矩阵、预览和结果一致、raw 不泄漏操作时刻。
- repository/backup：current、C01 v1、legacy、future JSON round-trip；修改本合同后还必须运行大六壬定向、六爻共享回归、`flutter analyze` 和全量 `flutter test`。

### 7. Wrong vs Correct

```dart
// Wrong: DateTime 墙上字段和绝对时刻混用，失败时又静默按月建取将。
final lunar = Solar.fromDate(castTime).getLunar();
final yueJiang = YueJiangService.getYueJiangBySolarTerm(
  lunar.getPrevJieQi().getName(),
  lunar.getMonthZhiExact(),
);

// Correct: 入口只捕获一次 absolute instant + fixed offset，统一解析。
final context = DlrCastTimeService.resolve(
  DlrCivilTime(
    instant: castTime,
    sourceUtcOffsetMinutes: capturedOffsetMinutes,
  ),
);
final yueJiang = context.monthGeneralResolution.yueJiang;
```

## 常量口径（`daliuren_constants.dart`）

- **天干寄宫**：甲寅、乙辰、丙戊巳、丁己未、庚申、辛戌、壬亥、癸丑。四正（子午卯酉）不寄干。歌诀"甲课寅兮乙课辰…分明不用四正神"。**这不是禄位表**——禄位（乙禄卯、丁己禄午等）如未来神煞需要须另建表，两者不得混用（历史教训：曾误用禄位表导致乙丁己辛癸日四课全错）。
- `getGanJiGong` 对无效输入抛 `ArgumentError`，禁止静默兜底。
- 八专日 = 干寄宫==日支，恰为古籍五日：甲寅、庚申、丁未、己未、癸丑（此对应关系是寄宫表正确性的旁证，测试已锁定）。
- 三刑：子↔卯、丑→戌→未→丑、寅→巳→申→寅、辰午酉亥自刑。驿马按日支三合局：申子辰→寅、寅午戌→申、巳酉丑→亥、亥卯未→巳。

## 场景：天盘与四课严格结构合同

### 1. Scope / Trigger

凡新增或修改天盘排列、模型/JSON、神将配置、四课或三传入口，都必须复用本节的唯一天盘合同。C03 只确立盘面结构与失败语义；贵人取法、顺逆及“天盘支/地盘宫 -> 神将”坐标属于 C04，不能因为增加 map 校验而顺手改写。

### 2. Signatures

```dart
Map<String, String> TianPanMapContract.validate(
  Map<String, String> tianPanMap, {
  String parameterName = 'tianPanMap',
});

TianPan({
  required String yueJiang,
  required String yueJiangName,
  required String shiZhi,
  required Map<String, String> tianPanMap,
});

typedef ChengShenResolver = ShenJiang? Function(String tianPanZhi);

SiKe SiKeService.arrangeSiKe({
  required String riGan,
  required String riZhi,
  required Map<String, String> tianPanMap,
  required ChengShenResolver resolveChengShen,
});

Map<String, String> SiKeService.validateSiKe(
  SiKe siKe,
  Map<String, String> tianPanMap,
);

ShenJiangConfig ShenJiangService.configureShenJiang({
  required String riGan,
  required String shiZhi,
  required Map<String, String> tianPanMap,
  DaLiuRenDayNightMode dayNightMode,
  DaLiuRenGuiRenVerse guiRenVerse,
});

SanChuan SanChuanService.deriveSanChuan({
  required SiKe siKe,
  required Map<String, String> tianPanMap,
  required ShenJiangConfig shenJiangConfig,
  List<String>? kongWang,
});
```

### 3. Contracts

- 合法天盘必须恰有十二地支键、十二个不重复的地支值，且存在同一固定位移 `delta`，使 `P(B[i]) == B[(i + delta) mod 12]`。任意乱序双射不是天盘。
- `TianPanMapContract.validate()` 是唯一结构校验实现，成功时返回基于输入快照的不可变 map。`TianPanService`、`TianPan`、`ShenJiangService`、`SiKeService` 和 `SanChuanService` 均不得绕过它或保留原 map 引用。
- `TianPan` 还必须满足 `tianPanMap[shiZhi] == yueJiang`。`fromJson`、`copyWith`、`toJson`、正反向查询与完整显示都不得用“查不到就回本支”补缺；`yueJiangName` 只是展示元数据。
- `ShenJiangService` 在任何昼夜或坐标计算前先取得已验证快照，`ShenJiangPosition.heavenBranch` 只能从同一张天盘按 `earthPalace` 读取。贵人选择、落宫与顺逆的具体合同见下一节。
- 日干支必须组成六十甲子。设 `G=日干寄宫`、`P(x)=tianPanMap[x]`，四课依次为 `P(G)/日干`、`P(P(G))/P(G)`、`P(日支)/日支`、`P(P(日支))/P(日支)`。
- `isZeiKe` 只表示下克上，`isBiYong` 只表示上克下。`ChengShenResolver` 按每课上神解析乘神，返回 `null` 时必须失败，禁止默认“贵人”。
- 三传入口必须重算并核对 1-4 课序、上下神链、五行、关系文案和克向标志；`chengShen` 不在 C03 重算。伏吟只是完整同位盘，反吟只是完整六冲盘。

### 4. Validation & Error Matrix

| 条件 | 必须行为 |
|---|---|
| 月将、时支或查询支不是合法地支 | `ArgumentError` |
| map 为空/部分、带额外键、非法键值、重复值或乱序双射 | 所有公开消费者抛 `ArgumentError` |
| `tianPanMap[shiZhi] != yueJiang` | `TianPan` 构造/JSON/`copyWith` 抛 `ArgumentError` |
| 日干支不属于六十甲子 | `arrangeSiKe` 或三传入口抛 `ArgumentError` |
| 任一课上神的 resolver 返回 `null` | `StateError`，不产出 `SiKe` |
| 传入的 `SiKe` 课序、链路或派生五行/克向矛盾 | 三传入口抛 `ArgumentError` |
| 非法天盘传给神将服务 | 坐标计算前抛 `ArgumentError`，不产出同支伪位置 |

### 5. Good / Base / Bad Cases

- Good：壬寅日、癸卯时、巳将得四课 `壬/丑、丑/卯、寅/辰、辰/午`，预期为已批准且不调用生产算法的独立手排 oracle。
- Base：完整 identity map 只判伏吟，完整 `delta=6` map 只判反吟；一般合法位移两者均为假。
- Bad：空 map 通过 `?? 本支` 生成同位神将、伪伏吟或伪四课；十二支乱序双射因为键值集完整而被误接受。

### 6. Tests Required

- `tianpan_service_test.dart`：12x12 月将/时支、固定循环、不可变快照、全部 malformed map 类型、月将锚点、正反查询、模型 JSON，以及神将入口在坐标计算前拒绝非法 map。
- `si_ke_service_test.dart`：六十甲子、五类五行关系、resolver 失败、完整伏/反吟，以及三张《指南》独立固定 oracle。
- `san_chuan_service_test.dart`：空/部分/不同合法盘、篡改课序/链路/克向失败，且 13 个原三传位移盘零改期望。
- `daliuren_result_versioning_test.dart`：合法 TianPan round-trip、嵌套 malformed TianPan 失败、v4 current、v3/v2/v1/legacy/future 兼容及旧神将 wire 迁移。

### 7. Wrong vs Correct

```dart
// Wrong: 缺失盘面事实被伪造为同支/贵人。
final tianPanZhi = tianPanMap[diZhi] ?? diZhi;
final chengShen = resolveChengShen(shangShen) ?? ShenJiang.guiRen;

// Correct: 所有消费者先使用同一不可变快照，缺事实显式失败。
final validatedMap = TianPanMapContract.validate(tianPanMap);
final tianPanZhi = validatedMap[diZhi]!;
final chengShen = resolveChengShen(shangShen);
if (chengShen == null) {
  throw StateError('无法解析上神的乘神');
}
```

## 场景：贵人与十二天将双坐标合同

### 1. Scope / Trigger

凡修改贵人昼夜选择、十二天将布列、四课/三传乘将、圆盘落将、结果 JSON 或历史盘读取，都必须使用本节合同。候选《御定六壬直指》的贵人整表仍未裁决；当前完整表只称项目基线，`jiaDayAlt` 仅供旧 JSON 解码，不能生成新盘。

### 2. Signatures

```dart
ShenJiangConfig ShenJiangService.configureShenJiang({
  required String riGan,
  required String shiZhi,
  required Map<String, String> tianPanMap,
  DaLiuRenDayNightMode dayNightMode,
  DaLiuRenGuiRenVerse guiRenVerse,
});

ShenJiang? ShenJiangConfig.generalForHeavenBranch(String heavenBranch);
ShenJiang? ShenJiangConfig.generalForEarthPalace(String earthPalace);
ShenJiangPosition? ShenJiangConfig.positionOf(ShenJiang general);
void ShenJiangConfig.validateAgainstTianPan(Map<String, String> earthToHeaven);
void ShenJiangConfig.validateForPanRuleSetVersion(String panRuleSetVersion);
```

Current wire 明确保存 `selectedGuiRenTianBranch`、`guiRenEarthPalace`、`actualDirection`、`positions[].heavenBranch/earthPalace`、`tianBranchToGeneral`、`earthPalaceToGeneral`、`executionRuleRef` 和 `classicAttributionRuleIds`。

### 3. Contracts

- 自动模式以卯至申为昼贵、酉至寅为夜贵；强制昼/夜只覆盖贵人选择。非法日干或时支抛错，不回退丑未。
- 设合法天盘为 `P: earthPalace -> heavenBranch`。先选贵人天盘支 `Q`，再以 `inverse(P)[Q]` 得贵人落宫 `E`；昼夜不能直接决定顺逆。
- `E` 在亥子丑寅卯辰时顺布，在巳午未申酉戌时逆布。十二将身份次序固定为贵人、腾蛇、朱雀、六合、勾陈、青龙、天空、白虎、太常、玄武、太阴、天后。
- `tianBranchToGeneral` 只供四课、三传等天盘上神消费者；`earthPalaceToGeneral` 只供圆盘与落宫展示。禁止重新引入含混的通用地支 resolver。
- current config 构造和 JSON 读取必须验证十二支/十二将双射、positions 与两张 map 一致、贵人双锚点、相邻将序、落宫六区方向、精确 execution rule 和 `001/004/005/006` attribution 集合，并对所有集合做防御性快照。
- `DaLiuRenResult` 的公开构造、手写 `copyWith`、`fromJson` 及 `DaLiuRenSystem` 产盘都必须执行结果级交叉校验：每个 `heavenBranch == tianPanMap[earthPalace]`，四课/三传乘将与天盘支 map 一致，且嵌套 execution rule ID/version、证据目录与顶层 `panRuleSetVersion` 相符。Freezed 私有构造器不能作为外部入口。
- 当前盘使用 `dlr.project.pan.shenjiang.landing-palace-layout@daliuren-pan/4.0.0`。古籍 001/004/005/006 只作 attribution，完整算法仍不得声称 classic executable。
- v1/v2/v3/缺版本旧五字段 wire 只在 `DaLiuRenResult.fromJson` 边界迁移：旧 `diZhiToShenJiang` 按历史实际语义恢复为天盘支 map，从旧 positions 恢复天盘并反查地宫；不得重算四课、三传或乘将。v4 搭配旧 shape 必须拒绝。
- 旧布局使用 `dlr.project.pan.shenjiang.legacy-layout-import`，规则版本与来源盘一致、attribution 为空；新写出统一使用 current shape，但顶层历史盘版本保持不变。

### 4. Validation & Error Matrix

| 条件 | 必须行为 |
|---|---|
| 非法日干/时支，或新盘选择 `jiaDayAlt` | `ArgumentError`；不产盘 |
| 天盘不完整、非固定位移或贵人天盘支无法反查 | `ArgumentError` / `StateError`；不伪造落宫 |
| map 缺支、重复将、position/map 矛盾、贵人锚点或方向矛盾 | config 构造/JSON 抛 `ArgumentError` |
| 四课或三传查不到上神乘将 | `StateError`；禁止默认贵人 |
| current pan 与 legacy rule/shape，或历史 pan 与 current rule | 结果边界抛 `ArgumentError` |
| 旧 positions 恢复的天盘与结果天盘不同 | 迁移失败；repository/backup 不静默改盘 |
| future 规范 pan version 与嵌套 rule version 不同 | 抛 `ArgumentError`；不把 future 当 current |

### 5. Good / Base / Bad Cases

- Good：壬寅日癸卯时、巳将，昼贵巳反查临卯，落顺区后顺布；四课、三传按天盘支取将，圆盘按地宫显示同一 positions。
- Base：旧 v3 五字段配置读取后得到双坐标 current shape，但顶层仍是 v3、execution identity 仍是 v3 legacy import，原四课三传逐字段不变。
- Bad：把“夜贵”直接解释成逆布；把所选贵人天盘支当地宫；四课和圆盘共用同一个含混 map；缺乘将时返回贵人；让 v4 JSON 携带旧五字段结构。

### 6. Tests Required

- `shen_jiang_service_test.dart`：昼/夜贵 x 顺/逆区四类固定预期、十二时支边界、强制昼夜、非法输入及三张《指南》昼贵盘。
- `shen_jiang_config_test.dart`：完整 malformed 矩阵、精确 rule/attribution、六区方向、集合快照、copyWith 与天盘交叉校验。
- `daliuren_result_versioning_test.dart`：公开构造/copyWith 无法绕过版本、证据目录、四课/三传乘将合同；current 与 legacy/future 的嵌套规则版本保持一致。
- system/san-chuan/formatter/widget：四课三传取 heaven map，圆盘取 earth map，结果页和 AI 同时显示所选天盘支、落宫与实际方向。
- result/repository/backup：缺版本、`legacyUnknown`、v1、v2、v3 的真实五字段 fixture，v4 old-shape rejection，重存/导入零 skipped 且旧四课三传不变。

### 7. Wrong vs Correct

```dart
// Wrong: 同一个“地支”方法同时服务天盘与地盘，并从昼夜猜顺逆。
final general = config.getShenJiangByDiZhi(branch) ?? ShenJiang.guiRen;
final direction = isDay ? ShenJiangDirection.shun : ShenJiangDirection.ni;

// Correct: 调用者声明坐标；顺逆来自贵人落宫。
final lessonGeneral = config.generalForHeavenBranch(shangShen);
final diskGeneral = config.generalForEarthPalace(earthPalace);
final direction = ShenJiangConfig.shunEarthPalaces.contains(guiRenEarthPalace)
    ? ShenJiangDirection.shun
    : ShenJiangDirection.ni;
```

## 三传九宗门（`san_chuan_service.dart`）

判定顺序：**伏吟 → 反吟 → 八专日无克特判 → 贼克（下贼上优先）→ 比用 → 涉害 → 遥克 → 昴星（四课全）/别责（三课备）**。

- 贼克："取课先从下贼呼，如无下贼上克初"——下贼上**优先**于上克下；初传一律取所选课**上神**。单一下贼上=重审，单一上克下=元首。
- 比用：同方向多候选取与日干俱比（阴阳同）者；俱比/俱不比 → 涉害。有下贼上时上克下课不参与。
- 涉害：候选自所临地盘宫起（**含**临宫）顺行历数至本家止（**不含**本家），每宫地支本气+所寄天干克候选者各计一害，深者胜；并列 → 孟上（见机）→ 仲上（察微）→ 刚日干上/柔日支上。【分歧：有派孟仲即止】
- 遥克：取二、三、四课上神（一课之克已被贼克穷尽）；上神克日干（蒿矢）先于日干克上神（弹射）；多者取比，再取课序前。
- 昴星：四课全（上神四位各异）。刚日仰视：初=地盘酉上神，中=支上神，末=干上神；柔日俯视：初=天盘酉所临地盘支，中=干上神，末=支上神。
- 别责：三课备。刚日初=干五合之干寄宫上神【分歧：有派取寄宫本位】；柔日初=支三合局前辰（生旺墓循环次位）；中末皆干上神。
- 八专：无克时阳日=干上神顺数三位（含本位），阴日=第四课上神逆数三位；中末皆干上神。有克走贼克流程，课体仍标 baZhuan。【分歧：有派标贼克】
- 伏吟：有克取克裁选；无克刚日干上（自任）/柔日支上（自信）。中末走**刑传链**（非天盘链）：中=初传之刑；初传自刑→刚日取支上/柔日取干上；末=中传之刑；中传自刑→末取中传之冲。
- 反吟：有克按贼克/比用/涉害裁选取**上神**，中末走天盘链（自然成 X-冲X-X）；无克六日为丁丑、己丑、辛丑、丁未、己未、辛未，初=日支驿马，中=支上神，末=干上神（井栏射）。六日依据《六壬大全》卷一 PDF/scan leaf 15、书叶 3a：“若知六日该无克，丑未同干丁己辛”。
- 中末传通用规则（贼克/比用/涉害/遥克适用）：中=tianPanMap[初]，末=tianPanMap[中]。
- 每种课体 `keTypeExplanation` 必须写明取用理由（涉害含深度数值）。

## 兼容约定

- `TianPan`/`Ke`/`SiKe`/`SanChuan`/`Chuan` JSON 字段结构冻结；规则修正只发生在计算侧，历史存量记录不迁移。
- 当前盘面规则集为 `daliuren-pan/4.0.0`；`daliuren-pan/1.0.0`、`2.0.0`、`3.0.0` 具名保留且可读，但 compatibility 为 `versionMismatch`。snapshot 仍为 `2.0.0`，证据目录为 `daliuren-classics/1.1.0`。
- 修改任何取传规则必须同步更新黄金课例并保持零改期望通过；新增课体分支须补黄金例。
