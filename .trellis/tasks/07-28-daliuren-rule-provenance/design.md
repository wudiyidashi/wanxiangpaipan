# 设计：大六壬规则身份、版本与重放契约

## 1. Scope / Trigger

C02 起将开始改变盘面事实，C09 起将改变分析规则。当前 `DaLiuRenResult` 无规则版本，`DlrAnalysisTag` 以中文 `term` 充当身份，历史盘也没有可判断的重放输入。C01 必须先提供 additive 契约，但保持当前计算结果不变。

## 2. Signatures

新增 `lib/divination_systems/daliuren/models/dlr_rule_contract.dart`：

```dart
enum DlrRuleKind { classic, project, display }
enum DlrEvidenceLevel { a, b, c, d }
enum DlrReplayStatus { complete, incomplete, legacyUnknown }
enum DlrAnalysisCompatibility { current, legacyUnknown, versionMismatch }

@freezed
class DlrRuleRef with _$DlrRuleRef {
  const factory DlrRuleRef({
    required String ruleId,
    required String ruleSetVersion,
    required DlrRuleKind kind,
    required DlrEvidenceLevel evidenceLevel,
    @Default(<String>[]) List<String> sourceIds,
  }) = _DlrRuleRef;
}

@freezed
class DlrCastInputSnapshot with _$DlrCastInputSnapshot {
  const factory DlrCastInputSnapshot({
    @Default('1.0.0') String schemaVersion,
    required CastMethod castMethod,
    required DateTime castTime,
    required int utcOffsetMinutes,
    required Map<String, dynamic> normalizedInput,
    required DlrReplayStatus replayStatus,
    @Default(<String>[]) List<String> missingFields,
  }) = _DlrCastInputSnapshot;
}
```

集中常量类 `DlrRuleSetVersions` 至少暴露：

```dart
static const legacyUnknown = 'legacyUnknown';
static const evidenceCatalog = 'daliuren-classics/1.0.0';
static const panCurrent = 'daliuren-pan/1.0.0';
static const analysisCurrent = 'daliuren-analysis-project-v1/1.0.0';
```

`DaLiuRenResult` additive 字段：

```dart
@Default(DlrRuleSetVersions.legacyUnknown) String panRuleSetVersion,
@Default(DlrRuleSetVersions.legacyUnknown) String evidenceCatalogVersion,
DlrCastInputSnapshot? castInputSnapshot,
String? recastFromId,
```

`DlrAnalysisTag` 与 `KeGeInfo` 增加必填 `DlrRuleRef ruleRef`。`DaLiuRenAnalysisReport` 增加必填版本/兼容字段，由 `DaLiuRenAnalyzer.analyze(result)` 统一填充。

## 3. Contracts

### 3.1 Rule identity

- classic rule ID 必须来自 C00，例如 `dlr.rule.kejing.002`。
- project rule ID 使用独立命名域 `dlr.project.analysis.*`，不得占用 `dlr.rule.*` 冒充古籍条目。
- display-only ID 使用 `dlr.display.*`，不能进入裁决条件。
- `term`、`reason`、顺序和本地化文案均不是身份字段。
- classic A/B ref 必须有 C00 source ID；classic C/D 可以保存 locator/source，但不能被标成 executable。运行时模型不自行提升证据等级。

### 3.2 Result JSON

新 JSON 只增加四个顶层字段。旧 JSON 缺失时：

| 字段 | 旧 JSON 默认 |
|---|---|
| `panRuleSetVersion` | `legacyUnknown` |
| `evidenceCatalogVersion` | `legacyUnknown` |
| `castInputSnapshot` | `null` |
| `recastFromId` | `null` |

反序列化不得把缺字段替换成 current。未来未知版本字符串应原样保留，由 compatibility resolver 判为 `versionMismatch`。

### 3.3 Snapshot payload

`normalizedInput` 只允许 JSON-safe 原始/解析输入：

| 起课方式 | 必存字段 |
|---|---|
| time | `params`；时刻和 offset 使用顶层字段 |
| reportNumber | `number`、`resolvedShiZhi`、`resolvedHourGanZhi`、`params` |
| computer | `resolvedShiZhi`、`resolvedHourGanZhi`、`params`；无种子时写入 missing reason |
| manual | 四柱、`params`；自动月将无对应 civil time 时写入 missing reason |

不得保存问题正文、解释文本、派生盘面或由结果反推的伪输入。Map 在保存前深复制，调用方后续修改原 input 不得改变 snapshot。

### 3.4 Analysis compatibility

- `sourcePanRuleSetVersion == panCurrent` -> `current`。
- `legacyUnknown` 或 snapshot 为空的旧结果 -> `legacyUnknown`。
- 非空但不等于当前已支持版本 -> `versionMismatch`。
- 报告仍可为旧盘提供兼容 v1 信息，但必须带状态；C15/C16 决定是否展示或限制传统 v2 裁决。

## 4. Validation & Error Matrix

| 条件 | 行为 |
|---|---|
| `ruleId` 不符合稳定命名域 | 构造/validator 抛 `ArgumentError` |
| 空 `ruleSetVersion` | 拒绝构造 |
| classic A/B 无 source ID | 拒绝构造 |
| project rule 声称 A/B classic evidence | 拒绝构造或测试失败 |
| snapshot 包含非 JSON-safe 值 | capture 失败，不静默 stringify |
| snapshot 输入 Map 后续被调用方修改 | 已保存快照不变 |
| 旧 JSON 缺版本 | 正常读取为 `legacyUnknown` |
| 未来未知版本 | 保留原串并标 `versionMismatch` |
| manual + auto month general 缺对应 civil time | snapshot=`incomplete`，列出 `manualCivilDateTime` |
| computer 缺随机种子 | 保存实际 resolved 时支，并列出 `randomSeed`；不补造种子 |

## 5. Good/Base/Bad Cases

- Good：新报数盘保存原数字、实际时支、版本和完整 snapshot；JSON round-trip 后各字段一致。
- Base：旧盘没有任何新字段，仍能打开，但版本与 compatibility 明确未知。
- Bad：把旧盘缺失版本用 `@Default(panCurrent)` 读取，会把旧错盘伪装成当前盘，必须由测试禁止。
- Bad：以 `tag.term == '传归生身'` 作为裁决键；正确做法是比较 `tag.ruleRef.ruleId`。

## 6. Tests Required

- `dlr_rule_contract_test.dart`：ID、kind、evidence/source 组合与版本校验。
- `daliuren_result_versioning_test.dart`：新旧 JSON、未来版本、recast link round-trip。
- `daliuren_system_test.dart`：四种起课 snapshot；断言深复制、实际 resolved 时支和 missing fields。
- analysis tests：每个生产标签/课格都有 ruleRef；改中文 `term` 后 rule ID 不变；报告版本与 compatibility 正确。
- formatter/UI 仅做现有回归，本任务不新增可见区；C16 再展示版本与来源。
- build_runner 后检查 `.freezed.dart/.g.dart` 同步；运行大六壬定向、共享裁决、六爻分析及全量测试。

## 7. Wrong vs Correct

### Wrong

```dart
@Default(DlrRuleSetVersions.panCurrent) String panRuleSetVersion;
final isReturnToSelf = tag.term == '传归生身';
```

旧 JSON 会被伪装成当前版本，且文案改名会改变行为。

### Correct

```dart
@Default(DlrRuleSetVersions.legacyUnknown) String panRuleSetVersion;
final isReturnToSelf =
    tag.ruleRef.ruleId == DlrProjectRuleIds.transmissionReturnsToSelf;
```

## Rollback

所有字段 additive。回滚产品使用时保留生成代码可读取新字段；若撤销写入逻辑，新 JSON 仍可由旧客户端忽略未知键。禁止通过删除字段或把旧记录默认成 current 简化回滚。
