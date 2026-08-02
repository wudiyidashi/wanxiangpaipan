# 六爻断卦分析引擎规范

> 来源任务：07-22-liuyao-analysis-engine（提交 489c3a1）、
> 08-01-liuyao-classics-analysis-prompt。
> 引擎位置：`lib/domain/services/liuyao/analysis/`，唯一入口 `LiuYaoAnalyzer.analyze()`。

## Design Decision: 断卦规则以《增删卜易》为裁决基准

**Context**: 六爻各流派对暗动、真空、刑害等规则存在分歧，引擎判定和单测的"正确答案"必须有唯一口径。

**Decision**: 一切流派分歧以《增删卜易》裁决；《增删卜易》弃用但产品需要的概念（三刑、相害）按《卜筮正宗》补充实现，且 priority 置最低档（≥45），不参与吉凶主判。

**关键口径（修改前必读，单测依赖这些结论）**:

| 规则 | 口径 | 实现位置 |
|-----|------|---------|
| 暗动/日冲 | 旺相静爻逢日冲=暗动；休囚静爻=日破；休囚动爻=冲散；旺相动爻=日冲催动而不散；旬空爻论冲空。关系图对每个爻位都保留日冲结构线，再标注作用结果 | `dong_bian_service.dart`、`relation_edges.dart` |
| 真空/假空 | 休囚安静之空为真空；动不为空、旺不为空为假空 | `kong_wang_service.dart` |
| 贪合忘生克 | 合的优先级高于生克：动爻被合住则忘生忘克 | `sheng_ke_service.dart` |
| 化进神对 | 寅→卯、巳→午、申→酉、亥→子、丑→辰→未→戌→丑（土循环） | `dong_bian_service.dart` jinShen 表 |
| 十二长生 | 五行论长生（不分阴阳干），水土同宫长生申 | `tables/chang_sheng_table.dart` |
| 半合 | 必须含帝旺支；缺旺支的两端（拱局）不算 | `tables/dizhi_relations.dart` |
| 三刑 | 寅巳申、丑戌未须三支齐全且至少一爻动；寅申两支优先只论冲克。子卯刑及辰午酉亥同支自刑可两支判定 | `he_chong_service.dart` |
| 应期 | 应期是状态解除或条件成熟的候选窗口，不代表事情必成；填实、出空、出月必须分开表达 | `ying_qi_service.dart` |

**近义术语归并约定**: 化扶/冲起/冲实/冲脱等近义概念**不单独出标签**；《六合章》所谓“化扶”归并为“化合”，冲起/冲实/冲脱分别归并到暗动/冲空/冲开，仅在 `models/term_glossary.dart` 中以别名词条说明。新增术语时先查词典是否已有主概念。

**化变并存约定**（用户口径，2026-07-22；领域复核 2026-07-25）: 动爻与本位变爻的合冲与五行生克**可并存且须同时记录**（子化丑=化合兼回头克，卯化戌=化合兼克出），检查次序：进退→生克→合冲→化空→化破→化墓→化绝；「克出」=本爻克变爻。变爻只与本位动爻论关系，不与本卦他爻论合冲。关系图化变线并记全部关系（`·`分隔、双行绘制），线型取影响最大者。裁决层依《六合章》将“化合”解释为“化扶”（扶），不作合绊；只有动爻被日月或他爻合住/合绊才转“待冲开”。

**用神与应期约定**（用户口径，2026-07-23）: 先判断用神状态和事情趋势，再以空待实、破待出月/填实、合待冲、墓待开等条件生成应期候选。不得按吉凶标签数量直接输出总体吉凶。伏神取用时，状态、应期和总览必须分析伏神自身，不能复用同位飞神的旺衰空破标签。

## Design Decision: 裁决层为分类决策表，不是吉凶打分

**Context**: 任务 07-25-liuyao-verdict-engine。选定用神后需输出趋势结论，但 spec 禁止按标签数量判吉凶。

**Decision**: `verdict_service.dart` 按四步顺序求值：有向受力归集（按层级日月 > 有效动爻 > 有效暗动 > 本位变爻）→ 元/忌 actor availability → 悬置状态转完整条件集 → 决策表首行命中。输出 `VerdictJudgment{trend, nuance, conditions, factors, summary}`，趋势四值（可成/难成/待条件/趋势不明），派生不落库。

**关键口径（修改前必读，单测依赖）**:

| 规则 | 口径 | 实现位置 |
|-----|------|---------|
| 净强弱三分类 | strong=L1 有扶且重抑集空；weak=重抑集非空且全层无扶；余为 mixed。重抑集=月克/日克/囚/死/日破/冲散/回头克/化退神/飞克伏/伏神受制。**动爻克不入重抑集**（即忌神动，由 jiActive 处理，避免双重计数）；'休'记中性。yuanActive 的三条来源均会产生扶因素，因此与 weak 互斥；重抑与元神生并见必归 mixed | `verdict_service.dart` |
| 悬置转条件 | 旬空/月破/入墓/合住合绊/化空破墓绝/伏藏不判凶，转 `VerdictCondition`；真空与月破的 hasRescue=非 weak，飞克伏的出伏条件 hasRescue=false；日合月合仅动爻悬置，静爻论合起（扶）；化合按化扶归 L4 扶，不悬置。新增条件须同步 `YingQiService` 的解除候选 | 同上 `_buildConditions`、`ying_qi_service.dart` |
| 元忌活跃性 | 元神、忌神及其他作用者统一经过 `ActorAvailabilityService`。只有 `DirectedEffectOccurrence` 的路径最终指向用神、路径各 actor 可用且 occurrence 为 active，才进入扶抑；回头克、化退、冲散、旬空/月破和日/月合绊均由版本化 policy 对称处理 | `actor_availability_service.dart`、`sheng_ke_service.dart`、`verdict_service.dart` |
| 决策表 | 首行命中保证唯一。前置规则先于强弱分支（领域复核 2026-07-25）：用神自身回头克且无 L1 日月扶 → 难成（师之明夷，不被同卦连续相生反向覆盖）；用神回头生、无活跃忌神且无实质悬置条件（仅"待冲开"不算）→ 可成（复之震）。weak 只处理无救、忌神乘衰与衰而无助，不设元神分支；元神优先只在 mixed 中判定，且须有接续证据（连续相生/贪生忘克标签，或忌神不活跃）；元神仅暗动而忌神明动仍以忌神为先（临之泰）；mixed 且条件皆可解 → 待条件；mixed 且 L1 有扶 → 先难后成（克处逢生，否之讼） | 同上 switch |
| 稳定执行身份 | current 路径只消费 catalog `ruleId`、`occurrenceId`、`factorId`、`conditionId`、`timingId`；中文 `term` 只用于显示。只有显式 `v1-compat` 输入可经冻结 alias map 兼容旧 term，current 生产者给出空或未知 rule ID 必须失败关闭 | `rules/liuyao_catalog.dart`、`rule_identity_service.dart` |

**测试**: 决策表行序或口径变更必须先更新共享
`test/fixtures/liuyao/classics_cases.v1.json` 的证据化期望，再同步领域测试。
该 fixture 固定 40 例（26 个原书占例 + 14 个章法校验例），其中 6 个原书例为
确定性 holdout。`tool/liuyao_classics/validator.dart` 同时复算盘面、运行时分析、
来源/规则/实例 ID 闭包、split 与 cohort hash；禁止在测试里维护第二份黄金表。

## Scenario: 版本化证据分析到 AI 解释

### 1. Scope / Trigger

- 修改 source/rule catalog、分析阶段、有向作用、裁决、条件、应期、AI formatter、prompt assembler 或六爻评测器时适用。
- 目标是保持一条单一事实链：`LiuYaoResult -> AnalysisReport -> LiuYaoAnalysisProjection -> PromptAssembler -> frozen CastSnapshot`。

### 2. Signatures

```dart
LiuYaoAnalyzer.analyze(
  Gua mainGua,
  Gua? changingGua,
  LunarInfo lunarInfo, {
  int? yongShenPosition,
  bool yongShenIsFuShen = false,
  String ruleSetVersion = LiuYaoRuleCatalog.current,
})

LiuYaoAnalysisProjection.fromReport({
  required LiuYaoResult result,
  required AnalysisReport report,
})

dart run tool/liuyao_ai_eval/run.dart paired-model \
  --run-id <frozen-run-id> \
  --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval \
  --repetitions 3 --confirm-real-model
```

规则集身份固定为 `liuyao-zengshan-primary`；兼容版为 `v1-compat`，current 为
`v2`。分析 schema 为 `1`，projection schema 为 `1`，证据目录为
`liuyao-evidence/1.0.0`，生产 prompt policy 为 `liuyao-ai-policy/1.0.0`。

### 3. Contracts

- 固定阶段顺序由 `LiuYaoAnalysisStages.ordered` 定义；report、projection 与 trace 必须一致。
- source/rule catalog 只保存公开 locator、固定 revision/指纹和采用边界，不保存本机绝对路径。
- `exactQuote` 仅允许 A 级页级核验短引；B/C/D 分别只能是 `paraphrase`、`locatorOnly`、`projectConvention`，非逐字引用不得携带 quote。
- 《增删卜易》为主裁决来源；当前《卜筮正宗》见证为 C 级 locator-only，三刑、六害保持低优先级、非决定性。
- `LiuYaoAnalysisProjection` 顶层 exact keys 以 `topLevelKeys` 为准；selected 模式必须有程序 verdict，unselected 模式必须固定 `verdict=null`、`conditions=[]`、`timingCandidates=[]`。
- assembler 必须在所有六爻 system prompt 末尾追加 immutable guard；自定义 analysis 模板省略 `{{structuredOutput}}` 时必须补回 canonical projection。
- 已有对话逐字使用其 `CastSnapshot.systemPrompt/castUserPrompt`；只有新建、无快照恢复或重新生成才组装 current prompt。版本字段 additive，旧 JSON 默认为 `legacyUnknown`。
- 真实评测凭据只允许 `LIUYAO_AI_EVAL_API_KEY`、`LIUYAO_AI_EVAL_BASE_URL`、`LIUYAO_AI_EVAL_MODEL`、可选 `LIUYAO_AI_EVAL_PROVIDER_LABEL`，或精确 gitignored 的 `tool/liuyao_ai_eval/eval.local.json`；禁止读取应用 SecureStorage 或其他文件猜测凭据。
- 黄金 validator 必须使用 `full` fixture；候选构建必须使用 `evaluationDraft`，并在对象化前把 holdout 的 `expected`、`reference.adjudication` 替换为 withheld sentinel。draft 仍校验盘面、来源、split、运行时成功和 provenance，但不得比较 holdout 评分答案。
- 古例只声明月建与日干支时，production adapter 必须选择真实一致且确定性的公历见证，并排除会落入本卦六爻或所选伏神的年支；projection 不得出现 `LiuYaoRuleIds.yearCommand`。见证年份只是适配所需，不是原书年份证据。
- canonical fixture/adapter 是由共享 classics fixture 和生产装配生成的冻结工件，不是可手工维护的第二案例源；加载时必须重算共享 fixture hash，并由 `production_adapter_test.dart` 逐字节核对生成结果。
- `paired-model` 每次尝试写 `paired-model[-N]` 独立目录；同一 `runId + candidateHash + cohortHash` 的 reveal marker 可幂等续跑，不同身份仍为 regression-only。`compare` 只接受唯一带 `_SUCCESS` 的尝试。
- 联网前 generation system+user prompt 的 UTF-8 总字节数不得超过 `128 KiB`；judge 输入不得超过 `256 KiB`。这是传输无关的失败前置门禁，不替代供应商模型上下文声明。

### 4. Validation & Error Matrix

| 条件 | 行为 |
|---|---|
| 未知 rule-set version | `ArgumentError`，不得转 current |
| current 产出空/未知 rule ID | `StateError`，不得发送模型 |
| projection 顶层、policy、阶段顺序漂移 | `FormatException` |
| condition/timing/factor/trace 上游 ID 孤立 | `FormatException` |
| source 含绝对路径或非法 quote 边界 | catalog/projection validator 失败 |
| selected 无 verdict，或 unselected 含 verdict/condition/timing | projection validator 失败 |
| 六爻 formatter 无 canonical projection | `PromptAssembler` 抛 `StateError` |
| 评测凭据缺失 | `blockedMissingCredentials`；不得宣告真实模型门禁通过 |
| draft holdout 未 withheld，或 full 读取到 withheld | classics validator 失败 |
| 未知原例年份产生 `year-command` | production adapter/validator 失败，不得冻结资产 |
| generation/judge 输入超过冻结字节上限 | `generationInputTooLarge` / `judgeInputTooLarge`，不得发请求 |
| reveal marker 与同一冻结身份一致 | 允许新序号尝试续跑；marker 保持原 UTC 时间 |
| reveal marker 属于不同 run/candidate/cohort | `holdoutAlreadyRevealedRegressionOnly` |
| paired 尝试没有或存在多个 `_SUCCESS` | `requiredArtifactMissingOrInvalid`，compare 失败关闭 |

### 5. Good/Base/Bad Cases

- Good：`a -> b -> 用神` 全路径 active，终点作用进入 factor，condition 与 timing 保存全部上游 ID。
- Base：未选用神时仍输出完整盘面和辅助事实，只开放明确标注的候选用神建议。
- Bad：用神位于链首却因向外生克被算成自身受力；或无救 condition 仍生成暗示成功的通用应期。
- Good（评测）：calibration 完成后首次 holdout transport 失败；同一冻结身份写入 `paired-model-2` 并完成，原失败工件和 reveal marker 都保留。
- Bad（评测）：用固定但原例未声明的年柱生成“太岁入爻”，或在候选冻结前读取 holdout `expected/adjudication`。

### 6. Tests Required

- catalog/fixture：`test/tool/liuyao_classics/`、`liuyao_catalog_test.dart`，断言 40/26/14/6、指纹、证据边界、绝对路径和 ID 闭包。
- 领域：方向链首/中/尾、元忌对称 availability、伏神已出/未出、无救条件零应期、同窗多条件 union、`v1-compat` 回归。
- AI：真实 formatter projection、comprehensive/brief/custom guard、旧 snapshot 兼容、版本可见性。
- 评测：draft parser 用畸形 holdout `expected/adjudication` 证明字段未读取；post-reveal transport 失败可同身份恢复；不同 candidate 仍拒绝；所有 canonical projection 均不含 `year-command`；UTF-8 字节上限正反例。
- 跨系统：共享 verdict 模型变更后必须运行 Qimen、Daliuren 和 shared tests。
- 发布前：`flutter analyze`、全量 `flutter test`、评测敏感扫描、数据库/`LiuYaoResult` 不变门禁。

### 7. Wrong vs Correct

```dart
// Wrong: 中文展示词直接决定行为，并从原始标签另算应期。
if (tag.term == '旬空') buildTiming(tag);

// Correct: 程序裁决先产出带稳定身份的未决条件，应期只消费可解条件。
final conditions = judgment.conditions.where((item) => item.hasRescue);
final timing = YingQiService.calculate(
  yongShen: selectedYao,
  conditions: conditions.toList(),
  selectedActor: selectedActor,
  lunarInfo: lunar,
  ruleSetVersion: LiuYaoRuleCatalog.v2,
);

// Wrong: 未知年份统一补为丙午，随后把太岁标签送入模型。
final lunar = sourceMonthAndDay.copyWith(yearGanZhi: '丙午');

// Correct: 选真实月日见证，并确保归一化年支不命中任何分析 actor；
// draft 也不读取 holdout 的评分答案。
final fixture = LiuYaoClassicsFixture.fromJson(
  source,
  readMode: LiuYaoClassicsReadMode.evaluationDraft,
);
```

## Convention: 派生数据不落库

**What**: `AnalysisReport` 及全部 `YaoAnalysisTag` 一律运行时由 `LiuYaoAnalyzer.analyze()` 纯函数重算，**永不持久化**。只持久化用户选择：`LiuYaoResult.yongShenPosition`（`int?`）与 `yongShenIsFuShen`（`bool`，默认 false），存于 resultData JSON。

**Why**: 分析规则会持续迭代修正；不存则规则升级后旧卦自动获得新分析，无历史数据失效问题。可空字段使旧记录（JSON 无键）自然兼容，无 schema 迁移。

```dart
// Good：选用神只改字段并 updateRecord，分析即时重算
_result = _result.copyWith(yongShenPosition: position);
_report = LiuYaoAnalyzer.analyze(...);  // 派生

// Bad：把分析标签写入 resultData 或新表
```

## Convention: 共享 Widget 扩展一律可空参数

**What**: 给共享 widget（`LiuYaoTableWidget`、`CalendarScreen`、`DiagramComparisonRow` 等）加新能力时，新参数一律可空且**不传 = 与原版行为完全一致**。

**Why**: 这些 widget 被多个术数系统/页面复用（大六壬也用表格、首页 tab 内嵌日历），可空参数保证其他调用方零影响，并可用"不传参数"的回归测试锁定。

**跨模块上下文传递**: 日历应期模式用纯字符串对象 `CalendarGuaContext`
（`title/yongShenBranch/yingQiByBranch/yingQiMonthByBranch`）经 route arguments
传入，**日历模块不得 import 六爻分析模型**。六爻结果页通过
`LiuYaoCalendarContextMapper` 在边界按 `YingQiScale` 分流，不在日历模块重解领域模型。

## Gotcha: 应期日历按日/月尺度分流

> **Warning**: `CalendarGuaContext.yingQiByBranch` 只收 `YingQiScale.ri` 候选，
> `markerFor/describeDay` 按日支生成日格「应」角标和日详情；
> `yingQiMonthByBranch` 只收 `YingQiScale.yue` 候选，当前显示月份的月建命中时由
> 日历顶部整月提示条展示。月尺度候选不进入每日角标，日尺度候选也不触发月提示条。
> 调整 scale 或映射前必须同时运行 context、mapper 和 calendar screen 回归。

## Tests Required

- 引擎每个概念 ≥1 正例 + 1 反例：`test/unit/services/liuyao/analysis/`（夹具 `helpers/analysis_fixtures.dart` 提供 buildGua/buildLunar/makeYao）
- 规则口径变更必须同步改对应单测并在本文件更新口径表
- 序列化兼容：旧 JSON 无用神键 → null（`liuyao_analysis_controller_test.dart`）
- 应期日历边界：`calendar_gua_context_test.dart` 锁定日角标优先级和日详情，
  `liuyao_calendar_context_mapper_test.dart` 锁定日/月尺度分流，
  `calendar_screen_test.dart` 锁定月建命中时的整月提示条
