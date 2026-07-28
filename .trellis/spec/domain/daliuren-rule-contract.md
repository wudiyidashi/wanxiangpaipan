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

`DaLiuRenResult` 必须 additive 保存 `panRuleSetVersion`、`evidenceCatalogVersion`、`castInputSnapshot` 和 `recastFromId`。`DaLiuRenAnalysisReport` 必须声明 `analysisRuleSetVersion`、`sourcePanRuleSetVersion` 和 `compatibilityStatus`。

## 3. Contracts

- 古籍规则使用 `dlr.rule.*`；项目分析启发式使用 `dlr.project.analysis.*`；项目盘面规则使用 `dlr.project.pan.*`；纯展示使用 `dlr.display.*`。中文 `term`、`geName`、`reason` 和本地化文本不得参与相等性、裁决或持久化身份。
- `classic` A/B 规则必须引用 C00 `dlr.source.*`；`project`、`display` 只能为 D 级且不得挂古籍来源。C00 的 `adopted` 或 A/B 证据都不等于 `executableApproved`；只有 C00 当前明确批准的 A/B rule ID 可以把该位设为 `true`。
- `executableApproved` 只适用于 classic；project/display 必须保持 `false`。`isExecutable` 对 classic 读取批准位、对 project 为真、对 display 为假，消费者仍须校验 kind 与其支持的精确规则集版本。
- 当前发布常量为 `daliuren-classics/1.0.0`、`daliuren-pan/1.0.0` 和 `daliuren-analysis-project-v1/1.0.0`。发布后不原地改义。
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
| snapshot 含 DateTime、非字符串 Map key、非有限数或其他非 JSON 值 | 抛 `ArgumentError` |
| `complete` 带 `missingFields` | 抛 `ArgumentError` |
| `incomplete` 无 `missingFields` | 抛 `ArgumentError` |
| 旧结果缺版本字段 | 正常读取为 `legacyUnknown`，不得补 current |
| future、大小写不同或带空白的 pan version | 保留原串，compatibility=`versionMismatch` |

## 5. Good / Base / Bad Cases

- Good：报数新盘保存原数、实际解析时支/时柱、当前 pan/catalog 版本；JSON round-trip 后完全一致。
- Base：旧盘没有四个新增字段仍可打开，但版本未知、snapshot 为空，分析报告显式标记 legacy。
- Bad：把旧 JSON 默认成 current；把 `tag.term == '传归生身'` 当裁决键；把 caller 的可变 Map 直接存入 snapshot；让 display 标签的凶性改变 verdict。

## 6. Tests Required

- `dlr_rule_contract_test.dart`：命名域、证据组合、JSON-safe 深复制、非法 fromJson、replay 状态不变量。
- `daliuren_result_versioning_test.dart`：新旧/future JSON、`recastFromId`、snapshot round-trip 和外部 Map 隔离。
- `daliuren_system_test.dart`：四种起课快照、UTC offset、输入白名单、resolved 值与 missing fields。
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
```
