# 大六壬规则身份、版本与重放契约

## 1. Scope / Trigger

本规范适用于大六壬规则命中、排盘结果持久化、历史盘分析以及任何会新增或消费规则身份的 C02-C16 工作。目标是把规则身份、中文展示、古籍证据、盘面版本和起课输入分开；任何行为变化必须升规则集版本，不能复用旧版本字符串改义。

## 2. Signatures

核心类型位于 `lib/divination_systems/daliuren/models/dlr_rule_contract.dart`：

```dart
DlrRuleRef({
  required String ruleId,
  required String ruleSetVersion,
  required DlrRuleKind kind,
  required DlrEvidenceLevel evidenceLevel,
  List<String> sourceIds,
  bool executableApproved,
});

DlrRuleRef.project(
  String ruleId, {
  String ruleSetVersion,
});

DlrRuleRef.projectPan(String ruleId);

DlrCivilTime({
  required DateTime instant,
  required int sourceUtcOffsetMinutes,
});

DlrCastInputSnapshot.capture({
  String schemaVersion,
  required CastMethod castMethod,
  required DateTime castTime,
  required int utcOffsetMinutes,
  required Map<String, dynamic> normalizedInput,
  required DlrReplayStatus replayStatus,
  List<String> missingFields,
});
```

`DaLiuRenResult` 必须 additive 保存 `panRuleSetVersion`、`evidenceCatalogVersion`、`castInputSnapshot`、`civilTime`、`monthGeneralResolution` 和 `recastFromId`。`DaLiuRenAnalysisReport` 必须声明 `analysisRuleSetVersion`、`sourcePanRuleSetVersion` 和 `compatibilityStatus`。

## 3. Contracts

- 古籍规则使用 `dlr.rule.*`；项目分析启发式使用 `dlr.project.analysis.*`；项目盘面规则使用 `dlr.project.pan.*`；纯展示使用 `dlr.display.*`。中文 `term`、`geName`、`reason` 和本地化文本不得参与相等性、裁决或持久化身份。
- `classic` A/B 规则必须引用 C00 `dlr.source.*`；`project`、`display` 只能为 D 级且不得挂古籍来源。C00 的 `adopted` 或 A/B 证据都不等于 `executableApproved`；只有 C00 当前明确批准的 A/B rule ID 可以把该位设为 `true`。
- `executableApproved` 只适用于 classic；project/display 必须保持 `false`。`isExecutable` 对 classic 读取批准位、对 project 为真、对 display 为假，消费者仍须校验 kind 与其支持的精确规则集版本。
- 当前发布常量为 `daliuren-classics/1.0.0`、`daliuren-pan/3.0.0`、snapshot `2.0.0` 和 `daliuren-analysis-project-v1/1.0.0`。具名保留 `panV1=daliuren-pan/1.0.0`、`panV2=daliuren-pan/2.0.0` 与 `castInputSchemaV1=1.0.0`；发布后不原地改义。
- 盘面执行来源必须用 `DlrRuleRef.projectPan()` 生成 `dlr.project.pan.*@daliuren-pan/3.0.0`；`DlrRuleRef.project()` 的默认规则集属于 analysis，不能用于月将或历法执行身份。自动月将可把 `pan.001/.002` 记录为非执行 attribution，但它们不得成为 `executionRuleRef`。
- typed 月将反序列化可保留未来 `daliuren-pan/*` 执行版本，但必须拒绝 analysis 规则集；古籍 attribution 只能是 `dlr.rule.*`，且 `manualOverride` 必须为空，不能把人工输入伪装成古籍推导。
- 新 snapshot 的 `castTime` 和 `DlrCivilTime.instantUtc` wire 必须带明确 zone 并统一 UTC 序列化；`utcOffsetMinutes/sourceUtcOffsetMinutes` 独立保存且限制为整数 `[-840, 840]`。顶层结果 `castTime` 保持跨系统 legacy 角色，不静默改义。
- C01 v1 无 zone 的 snapshot `castTime` 必须把词法墙上字段放入 UTC 容器后减保存的 offset，确定性恢复 absolute instant；v2 及 future schema 的无 zone 时间必须拒绝。带 `Z`/offset 的所有版本按显式 zone 解析。
- 旧 JSON 缺新增字段时必须读取为 `legacyUnknown/null`；未知未来版本必须原样保留，并优先判为 `versionMismatch`。
- pan version 与 current 逐字精确相等且存在非 legacy snapshot 才是 `current`；不得 trim 或大小写归一化。未知非空版本（含首尾空白）、空 snapshot 或 legacy snapshot 分别为 `versionMismatch` 或 `legacyUnknown`。
- snapshot 只保存重放输入白名单，不保存占问正文或派生盘面。时间起课保存 `params`；报数另存原数、实际时支和时柱；电脑起课保存实际值并缺 `randomSeed`；手动四柱保存四柱和参数，自动月将缺对应 civil time 时缺 `manualCivilDateTime`。
- `normalizedInput` 必须在构造、反序列化和 `copyWith` 边界做 JSON-safe 深复制。Freezed 只负责值语义，不能把生成的私有构造器当校验入口。
- v1 裁决只消费 `kind=project` 且 `ruleSetVersion=analysisCurrent` 的规则引用；display 或未知未来规则集不得改变裁决。

## 4. Validation & Error Matrix

| 条件 | 必须行为 |
|---|---|
| rule ID 与 kind 命名域不符 | 抛 `ArgumentError` |
| 空或带首尾空白的 `ruleSetVersion` / 空 snapshot schema | 抛 `ArgumentError` |
| classic A/B 无 source | 抛 `ArgumentError` |
| project/display 声称 A/B/C 或挂 source | 抛 `ArgumentError` |
| classic C/D、C00 未批准 ID 或非 classic 声称 `executableApproved=true` | 抛 `ArgumentError` |
| `projectPan()` 收到 analysis ID，或 typed 月将执行 ref 不属于 `dlr.project.pan.*@daliuren-pan/*` | 抛 `ArgumentError` |
| 月将古籍 attribution 非 `dlr.rule.*`，或 manual override 携带 attribution | 抛 `ArgumentError` |
| snapshot 含 DateTime、非字符串 Map key、非有限数或其他非 JSON 值 | 抛 `ArgumentError` |
| snapshot/civil offset 非整数或越出 `[-840, 840]` | 抛 `ArgumentError` |
| v2 或 future snapshot 时间无 `Z`/offset | 抛 `ArgumentError` |
| C01 v1 snapshot 时间无 zone | 按词法墙上字段减快照 offset 恢复，不读取机器时区 |
| `complete` 带 `missingFields` | 抛 `ArgumentError` |
| `incomplete` 无 `missingFields` | 抛 `ArgumentError` |
| 旧结果缺版本字段 | 正常读取为 `legacyUnknown`，不得补 current |
| `panRuleSetVersion` 为具名 v1/v2 | 保留原版本并可读，compatibility=`versionMismatch` |
| `panRuleSetVersion=daliuren-pan/3.0.0` 且 snapshot 非 legacy | compatibility=`current` |
| future、大小写不同或带空白的 pan version | 保留原串，compatibility=`versionMismatch` |

## 5. Good / Base / Bad Cases

- Good：报数新盘保存原数、实际解析时支/时柱、UTC civil instant、来源 offset、typed 月将来源及当前 pan/catalog/schema 版本；JSON round-trip 后完全一致。
- Base：旧盘没有四个新增字段仍可打开，但版本未知、snapshot 为空，分析报告显式标记 legacy。
- Bad：把旧 JSON 默认成 current；用 analysis 默认规则集构造 `dlr.project.pan.*`；把 v1 无 zone 时间交给机器本地 `DateTime.parse()`；把 caller 的可变 Map 直接存入 snapshot；让 display 标签的凶性改变 verdict。

## 6. Tests Required

- `dlr_rule_contract_test.dart`：命名域、证据组合、JSON-safe 深复制、非法 fromJson、replay 状态不变量。
- `daliuren_result_versioning_test.dart`：v3 current、v2/v1 mismatch、legacy/future JSON、UTC wire、`civilTime`/typed resolution、`recastFromId`、snapshot round-trip 和外部 Map 隔离。
- `daliuren_system_test.dart`：四种起课快照、fixed offset、两种 manual mode、输入白名单、resolved 值与 missing fields。
- repository/backup round-trip：current/v1/legacy 结果不丢 civil time、typed resolution、版本或兼容状态，且不增加数据库 migration。
- 分析生产者测试必须断言 `ruleRef.ruleId`；裁决测试必须覆盖中文改名、display-only 和未知规则集不改变行为。
- 修改本契约后运行 build_runner、大六壬定向、六爻共享回归、`flutter analyze` 和全量 `flutter test`。

## 7. Wrong vs Correct

```dart
// Wrong: 文案是可变展示字段，旧盘也被静默伪装成当前盘。
final isReturn = tag.term == '传归生身';
@Default(DlrRuleSetVersions.panCurrent) String panRuleSetVersion;

// Correct: 行为只认稳定 ID，缺字段保留未知。
final isReturn = tag.ruleRef.ruleId ==
    DlrProjectRuleIds.transmissionReturnsToGenerateSelf;
@Default(DlrRuleSetVersions.legacyUnknown) String panRuleSetVersion;

// Wrong: project() 默认绑定 analysis 规则集。
final ref = DlrRuleRef.project(DlrProjectPanRuleIds.monthGeneralByZhongQiInstant);

// Correct: 盘面执行身份显式绑定 current pan 规则集。
final ref = DlrRuleRef.projectPan(
  DlrProjectPanRuleIds.monthGeneralByZhongQiInstant,
);
```
