# 六爻系统说明

**系统类型**：`DivinationType.liuYao`  
**状态**：Enabled  
**当前权威实现**：

- `lib/divination_systems/liuyao/liuyao_system.dart`
- `lib/divination_systems/liuyao/liuyao_result.dart`
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`
- `lib/presentation/widgets/liuyao_table_widget.dart`

---

## 1. 系统定位

六爻系统用于根据爻数生成本卦、变卦，并结合六神、世应、六亲等要素进行展示与解读。

它是当前四个系统里契约最完整、UI 最完整的一个，因此后续其它术数的接入应参考六爻的分层方式，而不是复制早期临时实现。

---

## 2. 支持的排盘方法

| 方法 | `CastMethod` | 状态 | 说明 |
|---|---|---|---|
| 钱币卦 | `coin` | 已实现 | 系统随机生成六次投币结果 |
| 爻名卦 | `manual` | 已实现 | 手动输入爻数或手动输入铜钱结果 |
| 数字卦 | `number` | 已实现 | 输入一个整数起卦 |
| 报数卦 | `reportNumber` | 已实现 | 输入上卦数、下卦数、动爻数 |
| 时间卦 | `time` | 已实现 | 依据 `castTime` 起卦 |
| 电脑卦 | `computer` | 已实现 | 系统随机起卦 |
| 卦名卦 | `guaName` | 已实现 | 指定本卦/变卦和月日干支重放排盘 |

---

## 3. 输入契约

### 3.1 通用要求

- `castTime` 可以为空；为空时系统使用当前时间。
- `manual` 模式必须显式提供 `manualMode`。
- 不允许再回到“看到某个字段就猜输入模式”的旧设计。

### 3.2 各方法 payload

#### `coin`

```dart
{}
```

说明：

- 不需要额外字段
- 爻数由 `QiGuaService.coinCast()` 生成

#### `time`

```dart
{}
```

说明：

- 不需要额外字段
- 卦象由 `QiGuaService.timeCast(castTime)` 生成

#### `manual`

六爻 `manual` 当前是一个方法名下的两种显式模式。

模式 A：直接提供爻数

```dart
{
  'manualMode': 'yaoNumbers',
  'yaoNumbers': <int>[6, 7, 8, 9, 8, 7],
}
```

约束：

- `manualMode` 必须为 `'yaoNumbers'`
- `yaoNumbers` 长度必须为 6
- 每个值必须在 `6..9`

模式 B：提供六次铜钱输入

```dart
{
  'manualMode': 'coinInputs',
  'coinInputs': <List<CoinFace>>[
    [CoinFace.front, CoinFace.back, CoinFace.back],
    ...
  ],
}
```

约束：

- `manualMode` 必须为 `'coinInputs'`
- 外层长度必须为 6
- 每组必须恰好 3 枚铜钱

#### `number`

```dart
{
  'number': 123,
}
```

约束：

- `number` 必须为 `int`

#### `reportNumber`

```dart
{
  'upperNum': 3,
  'lowerNum': 7,
  'movingNum': 5,
}
```

约束：

- 三个字段都必须为 `int`

#### `computer`

```dart
{}
```

说明：

- 不需要额外字段
- 爻数由 `QiGuaService.computerCast()` 生成

---

## 4. 排盘计算流程

所有六爻方法最终收敛为同一条计算链：

1. 先根据起卦方式生成六个爻数
2. 通过 `LunarService.getLunarInfo()` 计算农历信息
3. 通过 `GuaCalculator.calculateGua()` 生成本卦
4. 通过 `GuaCalculator.generateChangingGua()` 生成变卦
5. 通过 `LiuShenService.calculateLiuShen()` 生成六神
6. 组装 `LiuYaoResult`

排盘完成后的分析不写回结果对象，而是按
`LiuYaoAnalysisStages.ordered` 的 11 个固定阶段按需执行：

1. `liuyao.stage.01.validate-input`：校验六爻顺序、本变卦、动爻和用神输入。
2. `liuyao.stage.02.freeze-facts`：冻结盘面、日月、空亡等输入事实。
3. `liuyao.stage.03.build-roles`：建立用神模式与完整角色清单。
4. `liuyao.stage.04.calculate-state`：计算日月旺衰、空破、墓绝和特殊状态。
5. `liuyao.stage.05.calculate-availability`：计算动变、飞伏与 actor availability。
6. `liuyao.stage.06.calculate-directed-effects`：生成有向生克、扶助、合冲及连续作用事实。
7. `liuyao.stage.07.auxiliary-evidence`：生成卦变、世应、六神等辅助证据。
8. `liuyao.stage.08.arbitrate-conflicts`：记录 active/suppressed/not-applicable 与冲突原因。
9. `liuyao.stage.09.judge-verdict`：按稳定决策行形成四值、nuance、因素和完整条件集。
10. `liuyao.stage.10.calculate-timing`：只由尚未解除且可解的条件生成应期观察窗。
11. `liuyao.stage.11.build-projection`：建立版本化 AI projection 和来源投影。

`LiuYaoAnalyzer.analyze()` 是唯一分析入口。current 规则身份为
`liuyao-zengshan-primary/v3`，analysis schema 为 2；`v1-compat` 与 `v2` 仅用于显式
兼容验证，其中 v2 继续生成冻结的 schema-1 suppression 语义，未知版本失败关闭。

这意味着：

- 起卦方式只是“爻数来源”不同
- 结果展示层不应按不同方式分裂成不同结果结构

### 4.1 爻序与纳甲契约

- `yaoNumbers`、`Gua.yaos` 和六位卦 ID 始终按初爻到上爻排列。
- 六位卦 ID 的前三位是内卦（下卦），后三位是外卦（上卦）。
- 结果页仅在渲染时按上爻到初爻倒序显示，不得反向修改领域数据。
- 纳甲干支必须根据内外八卦规则动态组合；不得维护 64 卦逐条展开的派生表。
- 变卦只翻转动爻在原列表中的对应位置，再通过同一计算链重新生成卦名、纳甲和六亲。
- 读取旧六爻记录时，以保存的六个爻数为源数据重新计算本卦与变卦，修正历史派生字段。

纳甲改动必须用全部 64 卦遍历测试校验，并保留已知参考盘测试，不能只验证单个纯卦。

分析引擎还必须遵守以下作用边界：

- 变爻只与本位动爻论回头生克、化合化冲等关系，不跨位作用本卦其他爻。
- v3 将本卦动爻的 `formation/earlyProcess` 外向作用与本位变爻的
  `laterProcess/finalState` 后果分别记录；回头克、化退、化绝不得追溯删除已成立的
  前段 occurrence。v2 保留旧的全局 suppression，仅供显式兼容。
- 寅申两支优先论相冲及申金克寅木；寅巳申三支齐全且形成有效作用时才标三刑。
- 应期是空破合墓等状态被解除或触发的候选窗口，不代表事情必然成功。
- 填实、出空、出月是不同条件，不得合并成同一个日支标签。
- 不得以吉凶标签数量直接计算事情总体成败。

---

## 5. 结果对象契约

六爻结果必须至少包含以下字段：

| 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `id` | `String` | 是 | 记录唯一标识 |
| `castTime` | `DateTime` | 是 | 起卦时间 |
| `castMethod` | `CastMethod` | 是 | 起卦方式 |
| `systemType` | `DivinationType.liuYao` | 是 | 系统类型 |
| `lunarInfo` | `LunarInfo` | 是 | 农历上下文 |
| `mainGua` | `Gua` | 是 | 本卦 |
| `changingGua` | `Gua?` | 否 | 变卦 |
| `liuShen` | `List<String>` | 是 | 六神 |
| `calendarInputMode` | `LiuYaoCalendarInputMode` | 是 | 日历来源；旧 JSON 缺键恢复为 `legacyUnknown` |
| `questionId` | `String` | 是 | 加密问事引用 |
| `detailId` | `String` | 是 | 加密详情引用 |
| `interpretationId` | `String` | 是 | 加密解读引用 |
| `yongShenPosition` | `int?` | 否 | 用户选定的 1..6 爻位；null 表示未选 |
| `yongShenIsFuShen` | `bool` | 是 | 选中的是否为该位伏神，默认 false |

补充要求：

- `toJson()` / `fromJson()` 必须可逆
- `systemType` 通过 getter 固定为 `liuYao`
- `getSummary()` 必须在有变卦时输出 `本卦 → 变卦`
- `providedSolar` 必须由 `LiuYaoSystem` 校验 `castTime` 与存储四柱一致；
  `providedGanZhi` / `userOverride` / `legacyUnknown` 的 `castTime` 只表示记录时间，分析和
  AI 不得用它重算并覆盖存储四柱。
- fresh 卦名卦只接受 `providedSolar` 或 `providedGanZhi`；普通起卦使用
  `derivedFromCastTime`，结果页改四柱后写 `userOverride`。

---

## 6. 结果页显示规范

### 6.1 区块顺序

六爻结果页必须按以下顺序展示：

1. 占问事宜
2. 扩展信息
3. 本卦 / 变卦对照
4. 卦象特性
5. AI 分析

### 6.2 各区块必须显示的要素

#### 占问事宜

- 用户输入的问题文本
- 无内容时可以不显示整个区块

#### 扩展信息

- 权威阳历起卦时间；若来源为直接四柱、人工覆盖或旧记录，则明确显示为记录时间
- 农历月日
- 年月日时干支
- 空亡
- 月建、日建

#### 本卦 / 变卦对照

表头必须显示：

- 区块标题：本卦 / 变卦
- 八宫
- 卦名
- 特殊卦类型 badge（若存在）
- 紧凑卦符

表体必须显示：

- 本卦侧：六神、六亲地支、世应
- 中间列：动爻标记
- 变卦侧：六亲地支
- 顺序按上爻到初爻展示

说明：

- `LiuYaoTableWidget` 已经定义了这张表的当前标准结构。
- 伏神行已由 `LiuYaoTableWidget` 按宿主爻位展示；选伏神为用神时只持久化宿主爻位和
  `yongShenIsFuShen`，状态、飞伏关系、条件和应期仍由分析报告派生。

#### 卦象特性

仅在存在特殊卦类型时显示：

- 特性名称
- 对应解释文案

#### AI 分析

- formatter 从一次真实 `AnalysisReport` 生成 current schema `2` canonical projection；显式 v2 仍生成 schema 1。AI 只解释投影，不重算盘面、重选用神或覆盖程序裁决
- schema 2 稳定输出 calendar authority、六个本卦爻/对应变爻/伏神的 `actorFacts`、所选与另一现的 `useSpiritOccurrences`、世应关系、阶段作用、question focus、生命周期裁决和 D 级 interpretive evidence
- 完整 schema 2 projection 留在 section metadata 供程序、UI 与门禁使用；实际模型请求使用 AI compact schema 1，把重复 availability、两现 tags/phase contributions、effect actor 与 source reference 改为稳定 ID 引用；selected-use facts 保留完整 occurrence ID 集合，只内嵌其他分支中缺失的事实记录。canonical JSON 前只保留取用模式和生命周期摘要，不再重复展开角色、作用、因素和条件。本案例 selected 请求由约 `109 KiB` 降至 `69.55 KiB`，unselected 为 `57.36 KiB`，且保留上述裁决证据
- 未选用神固定 `verdictMode=abstain`，正文只列候选用神和待核验维度后立即结束；选定但无生命周期裁决固定 `explainSelectedVerdict`，两者都不得输出总体成败。只有 `explainLifecycle` 可按 formation → quality → continuity → persistence 解释程序结论，且形成不等于全程顺利
- comprehensive 与 brief 都按日历/问题边界、取用/权限、生命周期、两现、全爻阶段证据、世应/合同/费用/持续性、辅助证据、条件/应期、来源和核验建议输出；条件与应期均空时省略对应段落和缺省说明
- system prompt 最后固定追加 `liuyao-ai-policy/1.1.20` guard；自定义模板不能移除，省略结构化变量时 assembler 会补回 canonical AI projection。模型回复必须从 assembler 给定的 `[LIUYAO_DECISION]` byte 0 开始，user prompt 末行重复该唯一首行并要求无声校验。阶段作用由投影生成必须逐字输出的阶段锚点，同时锁定前段已经发生和后段回头限制；租房风险只用 projection 已有抽象类别，不举例或猜输入外身份、违约方式、时间、周期与金额。abstain 两组列表后直接结束，不携带 selected 模式的释放条件例外；其他无条件/无应期场景必须省略全部已解除/已冲开/已释放状态文字，不再要求固定句，并禁用“日冲已解除合绊”、`合绊=true`、`冲开=true` 及其他无投影释放/时间词。同一边界下不得以确定性结果措辞扩展程序未授权的推演、状态或观察，但仍须保留 `explainLifecycle` 已授权的四阶段原值。精确应期观察锚点在无 `timingCandidates` 时不进入任何 candidate prompt；有候选时只由 assembler 在最终 user output contract 内注入一次，system 与 canonical projection 不重复携带
- AI compact `sources.references` 仅携带取用、两现、阶段作用、裁决、条件/应期与辅助证据等可引用解释链所需的规则参考；全 actor 事实仍保留，背景标签不重复携带古籍定位，全量目录留在 full schema 2 metadata
- 无条件且无应期时，full metadata 保留 active `binding-opened` 及同 actor、同 `relatedYao` 配对的 active `mutual-binding` 供程序门禁和审计，AI compact view 则闭包省略两者对应 actor tag、occurrence 引用和 source reference；模型对该 resolved-release 状态保持沉默
- 同一无条件/无应期边界下，full metadata 继续保留裁决摘要和 availability 释放规则供审计；AI compact 删除 `verdict.summary`、清空 actor/use-spirit 的 `releaseConditionRuleIds`，formatter 可读摘要也不得从 full projection 把这些内容重新带回 prompt。active 假空只由 selected user output contract 注入一次当前状态锚点，说明当前仍参与分析，不延伸为等待或择时
- 六合在 v3 为 context-dependent，只能参与 formation/persistence，不能单独决定 quality 或 overall outcome；六神和卦名为 D 级项目象意，不得伪造古籍引文
- 古籍引用严格区分页级短引、采用释义、项目约定和仅定位；仅 `exactQuote` 可显示引号原文
- 新对话冻结 analysis/projection/rule/source/prompt policy 和模板 ID；已有对话继续逐字使用原 prompt，旧快照显示为旧版
- AI 区块不是替代结构化排盘的主展示层

### 6.3 分享预览头部

分享图片顶部固定按以下顺序显示：

1. `占问：`
2. `时间：`
3. `干支：`（年月日时干支及空亡）
4. `神煞：`（驿马、桃花、日禄、天乙贵人）

月建、日建不并入神煞行；神煞按日干、日支由领域服务计算。

---

## 7. 历史卡片规范

六爻历史卡片必须采用 5 层结构：

1. 占问事项
2. 时间
3. 结果摘要
4. 系统类型 badge
5. 起卦方式 badge

摘要格式要求：

- 无变卦：`天雷无妄`
- 有变卦：`天雷无妄 → 天风姤`

不允许：

- 只显示系统名称
- 只显示“六爻”
- 丢掉变卦信息

---

## 8. 当前实现缺陷与约束

以下问题必须被明确识别，不能被误当成正式契约：

1. 起卦页里“钱币卦”当前仍经由爻数列表路径落到 ViewModel 便捷方法，这属于实现细节，不应反向定义六爻契约。
2. `manual` 下同时存在两种模式是现实需求，不是允许继续模糊输入的理由；所有调用方必须显式传 `manualMode`。
3. 伏神由 `FuShenService` 运行时派生；结果只持久化用户选择的宿主爻位和
   `yongShenIsFuShen`。伏神自身状态、飞伏关系、条件和应期均在分析报告/projection
   中生成，禁止把派生报告写入历史排盘 JSON。

## 9. 证据与版本边界

- current source catalog：`liuyao-evidence/1.1.0`；显式 v2 兼容仍使用
  `liuyao-evidence/1.0.0`。
- 《增删卜易（校对：中国男儿）》固定 SHA-256
  `DE5C6C0CB5A73C47960A4D6C5EB87337CD677A59B768E15E42CFCB24C932FD68`；
  已核验回头生、克处逢生、旺静日冲、旺/动不为空四组页级见证。
- 《卜筮正宗》候选本固定 SHA-256
  `1DB6308DED165DD19ECDAC5D50D0F1F6479BF4F2896A983C01D3EE5F31A08655`；
  因字体映射不可可靠核引，目前只允许 locator-only，三刑/六害不参与决定性裁决。
- 四值、强弱三分类、首行命中和冲突顺序是明确的项目约定，不冒充古籍原文。
- 40 例共享 fixture 是规则和评测的单一事实源：26 原书占例、14 章法校验例，
  其中 6 个原书例为确定性 holdout。
- evaluator 中的 canonical fixture/adapter 只是由共享 fixture 和生产装配确定性生成、
  并以 `sourceFixtureVersion/sourceFixtureHash` 绑定的冻结缓存，禁止手工维护第二套案例。
- 黄金校验使用 `full` 读取模式；候选冻结使用 `evaluationDraft`，在对象化前将
  holdout 的 `expected` 和 `reference.adjudication` 替换为 withheld sentinel。
  draft 仍校验盘面、来源、split、运行时结果和 provenance，但不能读取评分答案。
- 原书未声明年份时，适配器只选择满足月日干支的确定性公历见证，并排除会命中
  本卦六爻或所选伏神的年支；该见证年份不是原书证据，projection 禁止产生
  `liuyao.rule.special.year-command`（太岁入爻）。

### 9.1 AI 评测恢复与当前状态

- `paired-model` 的每次尝试写入独立目录。holdout 揭示后，只有同一
  `runId + candidateHash + cohortHash` 的冻结候选可以在新序号目录恢复；不同候选
  只能把该 cohort 当作 regression set。`compare` 只接受唯一带 `_SUCCESS` 的尝试。
- paired run schema `1.2.0` 与 real-world run schema `1.3.0` 会锁定 model、endpoint hash、
  30..600 秒 timeout、transport retry policy、generation 参数及 judge system prompt/参数/
  schema hash；同一 run 的后续尝试发生任何漂移都以 `retryIdentityMismatch` 在发送请求前
  失败关闭。工件只保存非敏感 hash 和安全 model metadata。
- transport policy `liuyao-ai-transport-retry/1.2.0` 对 generation 与 judge 固定发送
  `reasoning_effort=none`，评测只消费用户可见的最终 `message.content`，不得把
  `reasoning_content` 当成最终答复。策略对 `429`、`5xx` 和 HTTP 2xx 空正文最多追加两次
  同请求重试；空正文覆盖 HTTP 响应体为空、`message.content=null` 和空/纯空白字符串。
  连续空正文耗尽后以 `emptyModelResponse` 失败关闭，非空畸形响应仍立即按
  `malformedResponse` 拒绝；策略版本参与 run/request/manifest/status identity，策略变化会产生
  新的运行 hash。
- 联网前按 UTF-8 预检输入：generation 上限 `128 KiB`，judge 上限 `256 KiB`；
  超限在发送请求前失败关闭。
- 2026-08-02 冻结运行 `canonical-v2-r5` 的 fixture、adapter、candidate、projection、
  case-input、request-parameters 和 holdout cohort hash 已固定；baseline/candidate 的
  projection、案例输入和参数完全一致，离线比较与敏感扫描通过。
- 该运行的真实配对状态仍为 `blockedMissingCredentials`，holdout 未揭示，因此
  AC9 仍未完成，不能宣称候选已通过真实模型改善门禁。

---

## 10. 后续改动准则

后续如果改六爻系统，必须同步修改本文件的场景：

- 增减起卦方式
- 调整 `manual` 模式 payload
- 调整 `LiuYaoResult` 字段
- 修改结果页区块顺序
- 修改历史摘要格式
- 修改 source/rule/projection/prompt policy 版本或分析阶段顺序
- 修改有向作用、actor availability、裁决条件或应期语义
