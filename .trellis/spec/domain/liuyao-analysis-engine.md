# 六爻断卦分析引擎规范

> 来源任务：07-22-liuyao-analysis-engine（提交 489c3a1）、
> 08-01-liuyao-classics-analysis-prompt、08-02-liuyao-real-case-prompt-calibration。
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
| v3 阶段作用 | 本卦动爻的 formation/early-process 外向作用与本位变爻的 later-process/final-state 后果分别保留。回头克、化退、化绝等后段限制不得追溯删除已经成立的前段 occurrence；真正当下不可用的状态仍按 `blockedPhases` 阻断对应阶段。v2 的全局 suppression 只保留在显式兼容入口 | `actor_availability_service.dart`、`sheng_ke_service.dart`、`analysis_trace.dart` |
| 决策表 | 首行命中保证唯一。前置规则先于强弱分支（领域复核 2026-07-25）：用神自身回头克且无 L1 日月扶 → 难成（师之明夷，不被同卦连续相生反向覆盖）；用神回头生、无活跃忌神且无实质悬置条件（仅"待冲开"不算）→ 可成（复之震）。weak 只处理无救、忌神乘衰与衰而无助，不设元神分支；元神优先只在 mixed 中判定，且须有接续证据（连续相生/贪生忘克标签，或忌神不活跃）；元神仅暗动而忌神明动仍以忌神为先（临之泰）；mixed 且条件皆可解 → 待条件；mixed 且 L1 有扶 → 先难后成（克处逢生，否之讼） | 同上 switch |
| 稳定执行身份 | current 路径只消费 catalog `ruleId`、`occurrenceId`、`factorId`、`conditionId`、`timingId`；中文 `term` 只用于显示。只有显式 `v1-compat` 输入可经冻结 alias map 兼容旧 term，current 生产者给出空或未知 rule ID 必须失败关闭 | `rules/liuyao_catalog.dart`、`rule_identity_service.dart` |

**v3 动变投影边界**：`回头生/克`、`化进/退`、`化泄/克出`、`化合/冲` 等变爻后果在 catalog 中固定为 `laterProcess/subsequent`；`化空/破/墓/绝` 固定为 `finalState/terminal`。schema 2 的 tag 投影和 AI compact 视图必须沿用该 catalog 身份，decision scope 只开放 `continuity/persistence`，不得因同属 `dongBian` 家族重新获得即时 `quality` 权限。对应 directed effect 仍是作用方向和 actor 权限的唯一权威记录。

**测试**: 决策表行序或口径变更必须先更新共享
`test/fixtures/liuyao/classics_cases.v1.json` 的证据化期望，再同步领域测试。
该 fixture 固定 40 例（26 个原书占例 + 14 个章法校验例），其中 6 个原书例为
确定性 holdout。`tool/liuyao_classics/validator.dart` 同时复算盘面、运行时分析、
来源/规则/实例 ID 闭包、split 与 cohort hash；禁止在测试里维护第二份黄金表。

## Design Decision: 日历来源与生命周期结论分别授权

**Context**: 卦名卦曾用用户选择的阳历计算四柱，却以点击当下时间保存记录；旧四值 verdict 又只描述用神强弱，不能代表一件事从形成到完整周期都顺利。

**Decision**:

- `LiuYaoResult.calendarInputMode` 以 additive enum 区分 `derivedFromCastTime`、`providedSolar`、`providedGanZhi`、`userOverride`、`legacyUnknown`。旧 JSON 缺键固定恢复为 `legacyUnknown`。
- fresh 卦名卦只接受 `providedSolar` 或 `providedGanZhi`。`providedSolar` 必须由 `LiuYaoSystem` 校验 `castTime` 与四柱一致；`providedSolar` 与 `derivedFromCastTime` 在 schema 2 都声明 `authoritativeSolarTime`，投影也必须二次校验 `solarConsistency=true`。直接四柱、人工覆盖和旧记录以存储四柱为分析事实，不允许 formatter 或模型自行重算。
- v3 对适用问题由纯函数 `LiuYaoLifecycleAssessmentService` 输出 formation、quality、continuity、persistence 四维及逐维 evidence occurrence IDs。租房 continuity 必须同时审计所选用神、同六亲另一现与应爻的 active 持续风险事实（如应爻入动墓），不得只从所选轴取证。旧 `VerdictTrend` 继续只代表 `selectedUseSpiritAxis`。
- 未选用神固定 `verdictMode=abstain`；选定但无生命周期裁决固定 `explainSelectedVerdict`，两者都无 overall outcome 权限。只有 `explainLifecycle` 可解释程序给出的四维结论，且不得把 `formation=willForm` 改写为全程顺利。
- schema 2 的 `actorFacts` 覆盖六个本卦爻、对应变爻和伏神；`useSpiritOccurrences` 分开保存所选与另一现；六合只有 formation/persistence scope，六神和卦名保持 D 级、非决定性象意。

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
  --output .trellis/tasks/08-02-liuyao-real-case-prompt-calibration/research/eval \
  --repetitions 3 --confirm-real-model
```

规则集身份固定为 `liuyao-zengshan-primary`；current 为 `v3`，分析 schema 为 `2`，
projection schema 为 `2`，证据目录为 `liuyao-evidence/1.1.0`，生产 prompt policy 为
`liuyao-ai-policy/1.1.20`。`v1-compat` 和 `v2` 均为显式兼容入口；v2 继续生成 analysis/
projection schema `1`、source `1.0.0` 和 policy `1.0.0` 的冻结形状，不得被 current
语义回写。

### 3. Contracts

- 固定阶段顺序由 `LiuYaoAnalysisStages.ordered` 定义；report、projection 与 trace 必须一致。
- source/rule catalog 只保存公开 locator、固定 revision/指纹和采用边界，不保存本机绝对路径。
- `exactQuote` 仅允许 A 级页级核验短引；B/C/D 分别只能是 `paraphrase`、`locatorOnly`、`projectConvention`，非逐字引用不得携带 quote。
- 《增删卜易》为主裁决来源；当前《卜筮正宗》见证为 C 级 locator-only，三刑、六害保持低优先级、非决定性。
- `LiuYaoAnalysisProjection` 顶层 exact keys 按 schema 选择 `topLevelKeys` 或 `schema2TopLevelKeys`；selected 模式必须有程序 verdict，unselected 模式必须固定 `verdict=null`、`conditions=[]`、`timingCandidates=[]`、`lifecycleVerdict=null`。
- schema 2 的 lifecycle evidence 只能引用 report occurrence 或显式世应 observation ID；actor/tag/effect/factor/condition/timing/trace/source 均须通过规则、来源和 occurrence 闭包校验。
- 完整 schema 2 projection 必须保留在 formatter section metadata，供程序校验、UI 和评测门禁使用；模型输入使用确定性的 AI compact schema 1，将 availability、两现 tags/phase contributions、effect actor 和 source reference 的重复对象改为稳定 actor/occurrence 引用。selected-use facts 输出完整 occurrence ID 集合，并仅补充其他 compact 分支中不存在的事实记录，所有引用必须闭包。compact `sources.references` 只为取用、两现、阶段作用、生命周期、裁决、条件/应期和辅助证据等允许引用的解释链保留规则定位；生命周期中的 evidence occurrence ID 必须回解到 full projection 的 rule ID 后再裁剪来源。全 actor 事实仍完整保留，但其中未进入解释链的背景标签不再重复携带古籍定位。来源标题、定位、采用与限制边界仍保留，完整目录只留在 full metadata。不得删除生命周期、全 actor 关键标签、两现、阶段作用、条件、应期或已命中来源边界。
- `providedSolar` 与 `derivedFromCastTime` projection 必须 `solarConsistency=true`；`providedGanZhi`、`userOverride`、`legacyUnknown` 的 `castTimeRole=recordedAtOnly`，模型不得据记录时间覆盖存储四柱。
- assembler 必须在所有六爻 system prompt 末尾追加 immutable guard；自定义 analysis 模板省略 `{{structuredOutput}}` 时必须补回 canonical projection。
- 原始模型回复必须从 assembler 按 projection 生成的完整 `[LIUYAO_DECISION]` 标记 byte 0 开始。system guard 必须禁止 BOM、空白、寒暄、标题或代码围栏前缀；user prompt 末行重复唯一合法标记并要求发送前无声校验。评测器不得 trim 或修复模型正文后再判定本门禁。
- assembler 若在 full projection 中找到 active `moving-overcomes` earlyProcess 与回指该作用者的 active `return-overcomes` laterProcess，必须由 actor ID 生成一条确定性“阶段锚点”，要求模型逐字单独输出。锚点同时保留前段克制已发生、后段回头克只限后续/最终及不追溯抹除三个语义，不按卦名、问题文本或案例 ID 特判。
- `conditions=[]` 且 `timingCandidates=[]` 时，comprehensive、brief、自定义模板的最终输出合同都必须省略未决条件/时间观察段落、标题和缺省说明，避免模型把“无应期”扩写成等待、择日或行动建议。不得把程序未授权的推演、状态或观察写成无条件成立的事项结果，也不得以确定性结果措辞扩展程序裁决；该限制不得压掉 `explainLifecycle` 已授权的 `formation` 及其他生命周期原值。
- `timingCandidates=[]` 时，candidate system/user prompt 均不得携带精确应期观察锚点；`timingCandidates` 非空时，精确锚点只能由 assembler 在最终 user `[LIUYAO_OUTPUT_CONTRACT]` 内注入一次，system prompt、canonical projection 和其他 user 段落不得重复注入。
- `conditions=[]` 且 `timingCandidates=[]` 时，当前状态标签只允许现在时解释，不得补造任何将来状态变化、等待、择时、机会或届时行动句。租房核验建议只使用 projection 已有的抽象风险类别，不举例、不命名输入外具体人员身份、中介性质、违约动作、月份、周期或金额。
- `conditions=[]` 且 `timingCandidates=[]` 时，模型可见合同必须完全省略已解除/已冲开/已释放的状态说明，不再要求任何固定句。system guard 与 output contract 必须一致禁用“日冲已解除合绊”、`合绊=true`、`冲开=true` 以及出空、出月、填实、冲开、解除合绊、合绊已解、等待、择日、时机和届时等无投影词句；也不得给出行动建议或新日期。
- 在同一无条件/无应期场景中，full projection 继续保留 active `binding-opened` 以及同 actor、同 `relatedYao` 配对的 active `mutual-binding`，供程序校验和审计；AI compact view 必须闭包式省略两者的 actor tag、selected/use-spirit occurrence 引用及 source reference。该省略只由结构化状态、actor 和稳定规则 ID 触发，不按案例、卦名或问题文本特判。`timingAndSourcesGrounded` 保持现有严格性：省略释放描述即可通过，但无投影释放词、未来等待/择时、未授权日期和行动建议仍失败。
- full projection、AI compact canonical JSON 和 formatter 的可读分析行是三个不同输出面。无条件/无应期时 full projection 必须保留 `verdict.summary` 与 availability 的 `releaseConditionRuleIds` 供审计；compact view 必须删除 `verdict.summary` 并把所有 actor/use-spirit availability 的 `releaseConditionRuleIds` 置空。`LiuYaoStructuredFormatter._formatAnalysis` 不得再从 full verdict 重写 summary；摘要是否模型可见只由 compact verdict 是否含 `summary` 决定。
- 无条件/无应期且存在 active 假空时，只有 selected 非 abstain 的最终 user output contract 可注入一次当前状态锚点；system、unselected 和 canonical JSON 均不得重复注入。该锚点只说明“旺或动而不作全空，当前仍参与分析”，不得继续推演后续释放或日期。
- `verdictMode=abstain` 的正文只允许候选用神与待核验维度两组列表，随后立即结束；不得继续解释全爻、辅助标签、来源或条件术语。
- 当前真实案例的 candidate system+user prompt 必须保持在 `70 KiB` UTF-8 以内；full projection 大小不受该 AI 传输视图上限影响。
- 已有对话逐字使用其 `CastSnapshot.systemPrompt/castUserPrompt`；只有新建、无快照恢复或重新生成才组装 current prompt。无快照恢复必须把结果页已解密的原始问题原样传回 assembler，不能因丢失 question focus 把 `explainLifecycle` 降为 `explainSelectedVerdict`。版本字段 additive，旧 JSON 默认为 `legacyUnknown`。
- 真实评测凭据只允许 `LIUYAO_AI_EVAL_API_KEY`、`LIUYAO_AI_EVAL_BASE_URL`、`LIUYAO_AI_EVAL_MODEL`、可选 `LIUYAO_AI_EVAL_PROVIDER_LABEL` / `LIUYAO_AI_EVAL_TIMEOUT_SECONDS`，或精确 gitignored 的 `tool/liuyao_ai_eval/eval.local.json`；禁止读取应用 SecureStorage 或其他文件猜测凭据。timeout 必须在 30..600 秒内。
- 黄金 validator 必须使用 `full` fixture；候选构建必须使用 `evaluationDraft`，并在对象化前把 holdout 的 `expected`、`reference.adjudication` 替换为 withheld sentinel。draft 仍校验盘面、来源、split、运行时成功和 provenance，但不得比较 holdout 评分答案。
- 古例只声明月建与日干支时，production adapter 必须选择真实一致且确定性的公历见证，并排除会落入本卦六爻或所选伏神的年支；projection 不得出现 `LiuYaoRuleIds.yearCommand`。见证年份只是适配所需，不是原书年份证据。
- canonical fixture/adapter 是由共享 classics fixture 和生产装配生成的冻结工件，不是可手工维护的第二案例源；加载时必须重算共享 fixture hash，并由 `production_adapter_test.dart` 逐字节核对生成结果。
- `validate` 必须加载 generation fixture、production adapter 和 judge reference 全部真实案例资产；judge reference 的 scenario IDs、四阶段值、风险维度和评分维度必须 exact match。输出根目录只能是任务 `research/eval`，创建前还必须由 Git 证明该路径已忽略且未跟踪。
- `paired-model` / `real-world-paired-model` 每次尝试写 `command[-N]` 独立目录；paired run schema 固定为 `1.2.0`，real-world run schema 固定为 `1.3.0`。首次可联网尝试把 model、endpoint hash、timeout、generation 参数、judge prompt/参数/schema hash、judge reference 文件 SHA-256 的独立非敏感 manifest 及 transport retry policy 绑定到 command identity，后续编号重试任何漂移均以 `retryIdentityMismatch` 失败关闭。绑定和 generation 阶段只能读取 manifest，不得打开 reference 文件；同一 pair 的两份原始 generation 均完成 reference-free gates 且 candidate 全部门禁通过后，judge 阶段才可一次性读取 reference、核对 manifest SHA-256 并解析 hindsight JSON。baseline 门禁失败仍保留为盲评比较证据，不得借此跳过 candidate 失败关闭。同一 `runId + candidateHash + cohortHash` 的 reveal marker 可幂等续跑，不同身份仍为 regression-only。`compare` 只接受唯一带 `_SUCCESS` 的尝试。
- `classics-representative-paired-model` 固定只跑 calibration 的 `.001/.007/.037` 三例与三次重复，run schema 为 `1.0.0`，不创建或读取 holdout reveal。generation 前只读取包含固定 case IDs 与 reference SHA-256 的非敏感 manifest；任一 generation 失败时该 pair 的 reference 文件必须保持零读取。每个 pair 的两份 generation 都完成后，其 judge 阶段才可读取一次完整 reference、核对 manifest SHA-256 并解析评分事实；parsed reference 不得跨 pair 缓存到后续 generation。
- transport policy `liuyao-ai-transport-retry/1.2.0` 对 generation 与 judge 固定发送 `reasoning_effort=none`，使评测只消费用户可见的最终 `message.content`；`reasoning_content` 即使非空也不得冒充最终答复。策略继续对 `429`、`5xx` 和 HTTP 2xx 空模型正文最多追加两次同请求重试；空正文包括 HTTP 响应体为空、`message.content=null` 和空/纯空白字符串。连续空正文耗尽后固定为 `emptyModelResponse`；非空畸形响应仍立即 `malformedResponse`，不得借重试放宽解析合同。策略版本参与 run/request/manifest/status identity，修改策略必须得到新的运行 hash。
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
| 同一 retryable command 的 model/endpoint/timeout/retry policy/request/judge contract/judge reference 漂移 | `retryIdentityMismatch`，不得发请求或创建新 attempt |
| HTTP 2xx 连续返回空模型正文且两次追加重试耗尽 | `emptyModelResponse`，该 attempt 失败关闭 |
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
- AI：真实 formatter projection、comprehensive/brief/custom guard、旧 snapshot 兼容、版本可见性；无条件/无应期必须断言 full summary/release IDs 保留、compact summary/release IDs 省略、可读 formatter 不回流摘要、当前状态锚点仅在 selected user contract 出现一次。有应期路径必须保留合法 summary 且只出现一次。
- 评测：draft parser 用畸形 holdout `expected/adjudication` 证明字段未读取；real-world reference 嵌套身份和 `validate` 资产门禁；representative generation 失败时 reference 零读取；post-reveal transport 失败可同身份恢复；model/endpoint/timeout/judge contract/judge reference 漂移不可恢复；不同 candidate 仍拒绝；所有 canonical projection 均不含 `year-command`；UTF-8 字节上限正反例。
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
  ruleSetVersion: LiuYaoRuleCatalog.current,
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
- 序列化兼容：旧 JSON 无用神键 → null、无日历来源键 → `legacyUnknown`（`liuyao_analysis_controller_test.dart`）
- 应期日历边界：`calendar_gua_context_test.dart` 锁定日角标优先级和日详情，
  `liuyao_calendar_context_mapper_test.dart` 锁定日/月尺度分流，
  `calendar_screen_test.dart` 锁定月建命中时的整月提示条
