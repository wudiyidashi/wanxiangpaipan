# 奇门遁甲分析引擎规范

规则集固定为 `qimen-shijia-zhuanpan-analysis/v1`。本层只读消费时家转盘
`QimenResult`，按“焦点 -> 事实 -> 冲突 -> 四值裁决 -> 应期观察窗”运行；分析
报告是运行时派生数据，不写回排盘 JSON、仓储或数据库。

## 首次发布基线

- `a83647e65befa69eb4d972b843ec343b020e3332` 是系统禁用、未注册且未进入
  tag/远端分支时的内部候选，不是用户可选择的旧规则版本。
- `8138c6e008a198562bc829f129aff0f8416353d8` 首次同时启用 Qimen 产品入口与
  经来源复核的分析实现，是 `qimen-shijia-zhuanpan-analysis/v1` 的发布基线。
- 该基线黄金 fixture 的 SHA-256 固定为
  `D575DC31D56C8F6585D365CB42212F36C56FD37D3C97A22DD288BEF9ADE73E2E`。
- 从此基线起，规则谓词、来源裁定、冲突关系、裁决表或应期语义发生任何变化，
  都必须新增规则版本；不得覆盖 `v1` 的 list、map 或黄金 fixture。非语义诊断修复
  也必须保持 schema 1 wire 兼容。

## 场景：从冻结排盘生成可审计分析

### 1. Scope / Trigger

- 修改 `lib/domain/services/qimen/analysis/`、分析 JSON、焦点映射、事实公式、
  冲突/裁决表或应期规则时适用。
- 输入真相仅为已经持久化并通过排盘层校验的 `QimenResult` schema 1。
- analysis 目录不得导入时间、定局、地盘、天盘、值符值使、门、神、暗干、
  标记或总排盘 service；分析层不得重排或“修正”宫位。
- 规则语义、来源裁定、冲突关系或决策表行为改变时必须新增规则版本；已经
  发布的 `v1` 列表和 map 均为不可变集合。

### 2. Signatures

```dart
QimenAnalysisReport QimenAnalyzer.analyze(
  QimenResult result, {
  String ruleSetVersion = 'current',
})

QimenAnalysisReport QimenAnalyzer.analyzePersisted(
  Map<String, dynamic> persistedPan, {
  String ruleSetVersion = 'current',
})

QimenAnalysisProjection QimenAnalysisProjection.fromReport(
  QimenAnalysisReport report,
)
```

报告 `analysisSchemaVersion=1`，投影 `projectionSchemaVersion=1`。规则、来源、
事实 occurrence、决策行、条件和应期均使用稳定 ID；wire codec 不依赖 enum
`.name`。

证据路径使用字段选择器而非数组下标：

```text
$.palaces[number=9].heavenStem
$.temporalContext.monthGanZhi
$.xunHiddenStem
```

每个事实/命中 trace 的 `QimenInputRef` 必须能由
`QimenInputRefResolver` 在原 `QimenResult.toJson()` 中解析到相同规范化值。

### 3. Contracts

#### 输入与焦点

- guard 验证月、日、时柱，九宫 `1..9` 唯一性，天地盘干、九星、八门、八神、
  寄宫、值符值使、空亡、驿马、旬首遁仪和局数；只报错，不补值。
- `self` 为日干天盘落宫，`matter` 为时干天盘落宫，二者始终是 primary。
- 时干为甲时读取持久化 `xunHiddenStem`；日干为甲时 schema 1 没有日旬遁仪，
  `self` 必须返回 `QMV1-E-DAY-JIA-FOCUS-UNRESOLVED`，不得借用时旬遁仪。
- 中五干的 `originPalaceNumber=5`，作用宫只取显式 `hostedHeavenStem`。
- `general/career/wealth/relationship/health/study/travel/litigation` 八类只添加
  secondary 指标，不能替换 primary。

#### 季令与约束公式

月令只取持久化月柱支：寅卯木、巳午火、申酉金、亥子水、辰未戌丑土。

```text
九星：同=相，星生月=旺，月生星=废，星克月=休，月克星=囚
八门：同=旺，月生门=相，月克门=休，门克月=囚，门生月=废
```

八门季令、门宫五行关系、门迫是三个独立事实。门迫仅为“门克宫”。

- 六仪击刑只检查 `xunHiddenStem` 的主/寄天盘 occurrence：戊震3、己坤2、
  庚艮8、辛离9、壬巽4、癸巽4；命中 occurrence 必须位于持久化
  `zhiFuPalace`，证据同时引用 `$.xunHiddenStem` 和 `$.zhiFuPalace`。
- 奇仪入墓：乙癸坤2、丙戊乾6、丁己庚艮8、辛壬巽4。主干与寄干分别记录。
- 入墓解除支由墓宫支之冲取得：未↔丑、辰↔戌；条件和应期使用显式
  `releaseScale`。

#### 克应与格局

- 十干克应是 9x9 typed catalog，共 81 个唯一 pair/rule ID，来源固定为
  `QMS-CLASSIC-BAOJIAN`；v1 把每对作为中性、contextual 结构，不把古文条目
  直接提升为综合裁决。
- `三奇得使` 只命中有向天/地盘干对：乙+己、乙+辛、丙+戊、
  丙+庚、丁+壬、丁+癸。主干与寄干 occurrence 分别评估，不扫描文案。
- 九遁为九个独立 catalog 谓词：

| Rule | Exact v1 predicate |
|---|---|
| 天遁 | 天盘丙 + 地盘丁 + 生门 |
| 地遁 | 天盘乙 + 地盘己 + 开门 |
| 人遁 | 天盘丁 + 休门 + 太阴 |
| 风遁 | 天盘乙 + 开/休/生门 + 巽四宫 |
| 云遁 | 天盘乙 + 地盘辛 + 开/休/生门 |
| 龙遁 | 天盘乙 + 休门 + 坎一宫 |
| 虎遁 | 天盘乙 + 地盘辛 + 休门 + 艮八宫 |
| 神遁 | 天盘丙 + 生门 + 九天 |
| 鬼遁 | 天盘乙 + 杜门 + 九地 |

  人遁固定采太阴见证，不把备选的地盘丙口径合并为 OR；龙遁、虎遁、
  鬼遁必须独立评估，共享天盘乙不构成相互暗示。
- 飞干=`日干加庚`，伏干=`庚加日干`。
- 天乙飞宫=`xunHiddenStem` 加庚，天乙伏宫=庚加 `xunHiddenStem`。
- 普通癸加癸不等于天网四张。v1 因“时加癸/癸临时干/癸加癸”见证分歧，
  必须产生 `skyNet` 的 `notApplicable` trace，不生成天网事实。

#### 冲突与裁决

冲突顺序固定为：目录显式 pair -> 焦点特异性 -> conflict tier -> 同层未决。
星门俱伏吟显式组合覆盖九星伏吟和八门伏吟，星门俱反吟同理覆盖
两个单项反吟；组件事实仍保留在 report facts 和 suppressed trace 中，
只有组合事实进入后续裁决，避免同一结构重复参与。
驿马不得压制或删除全局伏吟事实。只有与 `self` 或 `matter`
同宫的驿马才生成该焦点的发动观察窗；secondary 驿马不生成该候选。

决策表自上而下首行命中且只命中一行：

```text
QMV1-D00 输入/主焦点无效 -> 趋势不明
QMV1-D10 无解决定性阻断 -> 难成
QMV1-D20 主焦点有可解除条件 -> 待条件
QMV1-D30 类别不利收敛 -> 难成
QMV1-D40 类别有利收敛且无高层未决 -> 可成
QMV1-D50 决定性同层冲突 -> 趋势不明
QMV1-D60 只有背景或无决定规则 -> 趋势不明
```

未决冲突中的 inhibit 不能提前触发 D10。禁止 score、权重、百分比、标签计数或
来源强度算术。

#### 应期、历史与投影

- 应期只消费 active fact 和 verdict condition，不读取原始时间重算。
- 候选必须有上游 fact/condition、source、显式 `YingQiScale`，按
  `conditionRelease -> focusActivation -> contextWindow` 排序。
- 去重键为 `(scale, triggerKind, triggerValue, targetFocusRoleId)`；合并时稳定
  union 证据 ID，不按吉凶排序。
- 日尺度用于支填实/冲墓/驿马，月尺度只用于目录明确的季令/节气背景。
- v1 没有锁定的伏反吟或天干到临谓词产生 `notApplicable` trace，不猜候选。
- 来源黄金例 `QM-G16` 保留古籍升迁例和有利收敛，但 `matter`
  时干乙落持久化辰巳空亡的巽四宫，因首行优先命中 `QMV1-D20`。
  `QM-G17` 明示为《遁甲演义》公式见证而非历史占例；其坎一戊+丙、
  巽四乙+己及无更高条件的有利收敛锁定 `QMV1-D40` / 可成。
- `analyzePersisted` 只捕获 `QimenResult.fromJson` 的反序列化错误；反序列化成功
  后的 analyzer 缺陷必须向上抛出，不能伪报为 pan deserialization。
- report/projection decoder 拒绝未知 rule/source ID。投影保留 report 的
  `status/diagnostics`，使产品和 AI 能对不支持/损坏输入受控降级。
  投影顶层字段和 `policy` 字段必须精确匹配 schema 1，且固定：

```json
{
  "calculationOwner": "program",
  "mayRecalculatePan": false,
  "mayRecalculateAnalysis": false,
  "mayOverrideVerdict": false
}
```

### 4. Validation & Error Matrix

| 条件 | 行为 |
|---|---|
| raw pan schema 非 1 | `unsupportedPanSchema` + `QMV1-E-UNSUPPORTED-PAN-SCHEMA` + D00 |
| schema 1 JSON 不能反序列化 | `invalidPanFacts` + `QMV1-E-PAN-DESERIALIZATION` + D00 |
| 月/日/时柱或九宫事实无效 | `invalidPanFacts` + 精确稳定 error code + D00 |
| 日干甲缺少日旬遁仪 | focus diagnostic + D00，不猜 `self` |
| 未知规则集版本 | `ArgumentError` |
| report/projection schema 未支持 | `QimenAnalysisCompatibilityException` |
| report/projection 含未知 rule/source | `FormatException` |
| projection policy 可重算/可覆盖或字段漂移 | `FormatException` |
| YingQi condition 找不到 upstream fact | `StateError` |

### 5. Good / Base / Bad Cases

- Good：历史 schema-1 pan 经 `QimenSystem.resultFromJson` 恢复，再以显式 `v1`
  分析；完整 report 做真实 JSON round-trip 后规范 JSON 相等，原 pan 无
  `analysis` 字段。
- Base：只有 contextual/corroborating 事实，命中 D60；报告仍包含完整 non-match
  trace 和来源链。
- Bad：用当前节气代替月柱支算星门旺衰；把宫号当 `palaces` 的零基数组下标；
  扫描所有天盘干判六仪击刑；把癸加癸标天网；用 secondary 驿马解除全局伏吟。

### 6. Tests Required

- catalog：来源 fixed revision、唯一 ID、81 pair 完整性、不可变集合、未知 ID。
- evaluator：星/门五态独立公式；门宫与门迫分离；入墓完整表；仅旬首仪击刑；
  飞/伏干与飞/伏宫方向；癸加癸显式排除；81 pair 各自正反例。
- focus：八类别、时干甲、日干甲、中五 origin/hosted。
- conflict/verdict：每个 policy branch、D00..D60、首行唯一命中、无关事实不改变
  结论、入墓解除条件。
- YingQi：日/月尺度、dedupe、稳定顺序、orphan 拒绝、不保证成败措辞。
- wire/history/projection：真实 JSON 深往返、每个证据 ref 可解析、真实
  `QimenSystem.resultFromJson` 重开、未来 schema、未知 rule/source、精确 policy
  allowlist、禁止重算字段。
- 架构：analysis production 不导入任何排盘阶段 service；全仓搜索无评分逻辑。

### 7. Wrong vs Correct

```dart
// Wrong: palace number 9 is not list index 9.
final path = r'$.palaces[9].heavenStem';

// Correct: select by persisted stable palace number.
final path = r'$.palaces[number=9].heavenStem';
```

```dart
// Wrong: the same seasonal relation table for stars and doors.
final state = seasonalState(entityElement, solarTermElement);

// Correct: persisted month-pillar branch plus separate classical formulas.
final starState = starSeasonalState(starElement, monthElement);
final doorState = doorSeasonalState(doorElement, monthElement);
```

## 固定来源

- `QMS-CLASSIC-TONGZONG`：Wikisource oldid `1378608`
- `QMS-CLASSIC-YANYI`：Wikisource oldid `2082234`
- `QMS-CLASSIC-YUANLING`：Wikisource oldid `1378607`
- `QMS-CLASSIC-BAOJIAN`：Wikisource oldid `2353651`
- `QMS-CLASSIC-TUSHU-707`：Wikisource oldid `1942670`

固定转录只提供公开定位，不冒充校勘本。来源分歧必须写入 catalog 的
`adjudicationNote`；不能用外部软件快照单独授权断语。
