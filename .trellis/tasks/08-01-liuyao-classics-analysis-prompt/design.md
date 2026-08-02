# 设计：六爻古籍证据化分析与 AI 解释链

## 1. 设计目标

本任务不重做排盘，也不把六爻判断交给模型。目标是在现有
`LiuYaoAnalyzer` 上建立一条可执行、可追踪、可评测的链路：

```text
LiuYaoResult
  -> 输入完整性与盘面事实
  -> 用户用神模式与角色清单
  -> 爻状态与 actor availability
  -> 有向作用事实
  -> 冲突与压制
  -> 四值裁决和完整条件集
  -> 由可解条件产生应期观察窗
  -> 版本化 AI projection
  -> 不可移除的 system guard
  -> AI 解释
```

程序拥有排盘、规则、裁决与应期的计算权。AI 只负责把提供的事实与
用户问题组织成易读解释，不重新取代程序结果。未选用神时，程序不产出
四值裁决和应期；AI 只能明确标注为“候选建议”，不得把建议伪装成程序取用。

## 2. 固定边界与不变量

- `LiuYaoAnalyzer.analyze()` 仍是唯一领域入口，保持纯函数和无 I/O。
- `LiuYaoResult`、数据库 schema 和历史记录 JSON 不变；分析报告继续运行时派生。
- 用户保存的用神位置和伏神标志为最高优先级事实，本期不自动改写或持久化推荐。
- 《增删卜易》为主裁决基准；《卜筮正宗》只补低优先级三刑、六害。
- 六神、神煞、卦义、世应象意属于辅助证据，不能推翻用神中心裁决。
- 四值、强弱三分类、层级顺序和首行命中均标记为项目约定，不冒充古籍原文。
- 既有中文 `term` 和模板 ID 保留；执行身份改用稳定 ID。
- 旧对话继续读取冻结的 system/user prompt，新建或重新生成时才采用新版本。

## 3. 来源与规则目录

### 3.1 来源合同

新增六爻专属 source catalog。每条 source 至少包含：

- `sourceId`、`kind`、题名、版本或固定 revision；
- 文件指纹或公开固定 locator；
- 页码体系和定位说明；
- 摘义、采用边界、裁定说明和复核日期。

rule/case catalog 中的每条 evidence ref 另行记录 `sourceId`、定位、
`evidenceLevel`（A/B/C/D）和 `referenceKind`（`exactQuote`、
`paraphrase`、`projectConvention`、`locatorOnly`）。

首版至少登记：

- `liuyao.source.zengshan.zhongguonaner-pdf`：
  《增删卜易（校对：中国男儿）》；SHA-256
  `DE5C6C0CB5A73C47960A4D6C5EB87337CD677A59B768E15E42CFCB24C932FD68`；
- `liuyao.source.bushi-zhengzong.distiller-2004-pdf`：
  《卜筮正宗》候选本；SHA-256
  `1DB6308DED165DD19ECDAC5D50D0F1F6479BF4F2896A983C01D3EE5F31A08655`，
  暂为 `locatorOnly`；
- `liuyao.source.project.analysis-contract`：六爻分析规则集项目约定来源，
  固定到 spec/Git revision。

目录只存版本、指纹和可公开的页码/章节定位，不存本机绝对路径。直接引文只来自
视觉复核页；没有页级证据的条目只能输出转述或 locator。

证据等级只决定“可以怎样声称来源”，不参与吉凶或冲突权重：

| 等级 | 合法 reference kind | 必要条件 | 执行边界 |
|---|---|---|---|
| A | `exactQuote` / `paraphrase` | 固定指纹、页级渲染与文本复核、locator 和 reviewer 齐全 | adopted 古籍谓词可作为事实依据 |
| B | `paraphrase` | 固定版本和可靠 locator，释义已复核但未批准逐字短引 | 只输出转述；执行资格另由项目裁定 |
| C | `locatorOnly` | 只有候选定位或元数据，页面不能可靠复核 | 非决定性，禁止逐字引文 |
| D | `projectConvention` | 引用固定 project source 并说明软件收敛目的 | 项目规则可执行，但不得冒充古籍 |

`evidenceLevel` 属于每条 evidence ref，而不是整个 rule。同一 rule 可以同时链接
C 级古籍 locator 和 D 级项目采用约定，两者仍各守自己的展示边界。
`exactQuote` 必须有短引、页级 locator、source fingerprint 和 reviewer；
`paraphrase`、`projectConvention`、`locatorOnly` 均不得携带会被 UI 当成逐字原文的
quote 字段。执行范围与采用状态必须显式登记，不能从 A-D 自动推导。

### 3.2 规则合同

新增稳定 `ruleId` 目录，覆盖所有 analyzer 主规则、裁决行和应期规则：

- `ruleId`、规则集版本、规则族、执行阶段和显示主词；
- aliases，只映射显示词，不产生第二次执行；
- polarity、裁决层级、适用条件和排除边界；
- `evidenceRefs`，含 source ID、等级、定位、短引/转述类型和采用说明；
- adoption/evidence 状态和是否允许参与决定性裁决；
- 正例、反例或明确 coverage exemption。

ID 不从中文词条动态生成。目录 validator 检查重复 ID、悬空 source、
非法证据状态、决定性 locator-only 规则、缺失覆盖和别名重复执行。

ID namespace 固定为：

```text
sourceId        liuyao.source.<work-or-project>.<witness>
ruleId          liuyao.rule.<family>.<predicate>
projectRuleId   liuyao.project.<family>.<policy>
decisionRowId   liuyao.decision.<semantic-row>
conditionRuleId liuyao.condition.<state>.<release-contract>
timingRuleId    liuyao.timing.<state>.<trigger-contract>
```

首版 `ruleSetId` 固定为 `liuyao-zengshan-primary`。迁移时先冻结一个
`v1-compat` 身份基线，其结果与任务前未版本化行为一致；current 指向修正有向作用、
availability 和 condition-driven timing 的 `v2`。规则显示词仍保持当前 UI 文案。
已发布 ID 的语义不得原地修改；语义变化升规则版本，wire shape 变化另升 schema，
不能用一个版本字符串同时承担两者。

### 3.3 已核验高影响证据

首版把以下页级见证写入目录，并限制为短引或准确转述：

| PDF/印刷页 | 规则族 | 可支持的结论 |
|---|---|---|
| 25/24 | 回头生 | 复之震例“相生为吉” |
| 26/25 | 克处逢生 | 否之讼例，受克同时得生 |
| 31/30 | 日冲 | 旺静为暗动、衰静为日破 |
| 46/45 | 旬空 | 旺不为空、动不为空及其边界 |

《卜筮正宗》当前不能稳定渲染或抽取，三刑、六害继续保持
`locatorOnly`、低优先级和非决定性。

## 4. 运行时领域合同

### 4.1 版本和诊断

`AnalysisReport` 兼容扩展：

- `analysisSchemaVersion`；
- `ruleSetId`、`ruleSetVersion`；
- `status` 和 diagnostics；
- 已用来源、规则命中、作用事实、压制事实和 trace。

新增字段提供默认值或由唯一 analyzer 统一构造，不写入历史结果。

首发版本维度分别固定：

| 字段 | 首发值 |
|---|---|
| `analysisSchemaVersion` | `1` |
| `ruleSetId` | `liuyao-zengshan-primary` |
| 兼容规则版本 | `v1-compat` |
| current 规则版本 | `v2` |
| `sourceCatalogVersion` | `liuyao-evidence/1.0.0` |
| `projectionSchemaVersion` | `1` |
| `promptPolicyVersion` | `liuyao-ai-policy/1.0.0` |
| `rubricVersion` | `liuyao-ai-rubric/1.0.0` |

`LiuYaoAnalyzer.analyze()` 增加默认 `ruleSetVersion=current` 参数；未知版本抛
`ArgumentError`，不静默转成 current。source metadata 修订只升 catalog version；
规则谓词、冲突、decision 或 timing 语义改变才升 rule-set version。

### 4.2 规则命中

`YaoAnalysisTag` 增加稳定 `ruleId`，保留 `term`、category、polarity、
priority、reason 和 relatedYao。裁决与应期迁移期按以下顺序消费：

1. 已登记 `ruleId`；
2. 仅对明确列入 legacy alias map 的旧 term 兼容读取；
3. 显式 legacy 输入的未登记规则进入 diagnostic 且不参与裁决；current analyzer
   自己产出未知/空 ID 属开发合同破坏，立即 `StateError`，formatter 不发送模型。

`priority` 仍只负责 UI 排序；裁决层级由规则目录和显式决策行决定。

Catalog ID 表示跨运行稳定语义；运行时 ID 表示同一盘面的确定性实例。actor 使用
`main:yao:1..6`、`changed:yao:1..6`、`hidden:host-yao:1..6`、
`calendar:day|month` 等结构引用，不使用中文文案或 list 下标。实例 ID 由
`LiuyaoTraceIdFactory` 对 canonical tuple 做 SHA-256 并取固定长度十六进制值：

```text
occurrenceId = lyo-<hash>(stageId, ruleId, subjectRef, from?, to?, pathStep?)
factorId     = lyf-<hash>(factorRuleId, sorted occurrenceIds, arbitrationTier)
conditionId  = lyc-<hash>(conditionRuleId, focusActorId,
                          sorted upstreamOccurrenceIds)
timingId     = lyt-<hash>(timingRuleId, scale, triggerKind, triggerValue,
                          targetActorId, sorted upstreamConditionIds)
```

tuple 不含 `term/reason/priority`、当前时间或输入 list 顺序。相同 tuple 去重；同一
report 内 hash 冲突立即失败。这样展示词改名不会改变 occurrence、condition 或 timing
身份，同一个时间候选合并更多上游条件时也能得到可复现的新 ID。

### 4.3 Actor 与有向作用

用 `LiuYaoActorRef` 表达本卦爻、变爻、伏神、日辰和月建。用统一
`ActorAvailability` 判定作用者是否能传递力量：

- active / suspended / suppressed / unavailable；
- 原因 rule IDs；
- 回头克、化退、冲散、旬空/月破、日/月合绊等状态；
- 当前阶段和解除条件。

用 `DirectedEffectOccurrence` 表达：

- `occurrenceId`、`ruleId`；
- `fromActor`、`toActor`；
- 生、克、扶、泄、耗、合、冲等 effect；
- path 和 step 顺序；
- active/suppressed 状态及 `suppressedByRuleIds`；
- source IDs 和输入字段引用。

连续相生/相克必须保留路径方向。只有路径最终指向用神、且每个作用者均可用时，
才能生成用神受力因素。元神与忌神调用同一个 availability 判定，消除当前不对称。

availability policy 以 rule-set version 固定，不能根据 tag polarity 猜测。v2 至少逐项
覆盖回头克、化退、冲散、动爻被日合/月合、被他爻合住/合绊及已经冲开的反例；
旬空/月破等是否阻断也必须在 policy 中明示。helper 和 attacker 对同一 blocker 得到
同一状态。`DirectedEffectOccurrence` 同时保存 `suppressedByOccurrenceIds`，
`suppressedByRuleIds` 只作规则说明，不能替代实际压制事实链接。

对于 `a -> b -> c`，报告保存两条有向边与一个有序 path。用神在 `a` 时不能因自己
向外生/克而被算作受生/受克；在 `b` 时只消费 `a -> b`；在 `c` 时仅当整条 path
active 才消费终点作用。suppressed path 仍进入 projection 解释“为何未参与”，但不改变四值。

### 4.4 用神模式

报告显式区分：

- `selected`：用户已选可见爻或伏神，程序输出角色、裁决和应期；
- `unselected`：无程序用神，无程序裁决和应期；
- `invalid`：选择越界、伏神不存在或本变卦契约不一致，返回 diagnostic。

角色清单保留全部用神同类、元神、忌神、仇神和闲神 occurrence，不再只依赖
一个代表位置。现有 `YongShenChain` 字段继续作为 UI 兼容投影。

未选模式可把盘面和问题交给 AI 生成一个或多个“候选用神建议”，但 guard 强制：
这是 AI 建议，不是程序结果；不得继续伪造四值和应期。

## 5. 固定分析阶段

1. 校验六爻顺序、本变卦对应、动爻和用神输入。
2. 冻结排盘事实、日月与空亡等输入引用。
3. 建立用神模式与完整角色清单。
4. 计算日月旺衰、空破、墓绝和特殊状态。
5. 计算动静、化变、飞伏和 actor availability。
6. 生成有向生克、扶助、合冲和连续作用事实。
7. 生成卦变、世应、六神等辅助证据。
8. 记录 active/suppressed/not-applicable 及冲突原因。
9. 按稳定决策行形成四值、nuance、全部因素和条件。
10. 只从仍未解除且 `hasRescue=true` 的条件生成应期。
11. 建立版本化 AI projection 和用户可见来源投影。

阶段顺序同时写入 spec、架构文档、报告 trace 和测试，避免 formatter 或 UI
自行重算另一套结果。projection 顶层必须带按上述顺序排列的
`analysisStages` 稳定 stage ID 列表；validator 同时校验 trace 覆盖和顺序，不能只靠
文档或自然语言说明满足该合同。

## 6. 裁决与应期

### 6.1 裁决

保留现有四值和首行命中语义，但每个因素和决策行增加：

- `factorId` / `decisionRowId`；
- `ruleId`、`sourceIds`；
- actor/occurrence 输入引用；
- active 或 suppressed 状态；
- reason 和 evidence boundary。

裁决只消费有向、有效且实际作用到用神的事实。语义修正顺序固定为：

1. 根据古籍见证和项目裁定更新独立 fixture 期望；
2. 写正反回归；
3. 再修改引擎；
4. 禁止按 case ID 或卦名写个案分支。

factor 顺序使用显式 `arbitrationTier/arbitrationOrder`，固定为日月 -> 有效动爻 ->
有效暗动 -> 本位变爻 -> 悬置/反证 -> 命中 decision row，不读取 UI priority。
最后一条 factor 必须引用唯一 `decisionRowId` 和 project source。古籍谓词分别留在
前置 factors 中，禁止再生成笼统的“《增删卜易》断法总论”来源字符串。

v1-compat 至少冻结现有十三行语义 ID：

```text
liuyao.decision.return-overcome-without-l1-support
liuyao.decision.return-generate-unblocked
liuyao.decision.weak-unrescuable
liuyao.decision.weak-adverse-active
liuyao.decision.weak-unsupported
liuyao.decision.strong-clear
liuyao.decision.strong-with-conditions
liuyao.decision.strong-adverse-active
liuyao.decision.mixed-source-continuity
liuyao.decision.mixed-adverse-active
liuyao.decision.mixed-rescuable-conditions
liuyao.decision.mixed-l1-support
liuyao.decision.mixed-unresolved
```

v2 可调整 decision predicate/行序，但必须复用语义未变的 ID；语义改变的行使用新 ID，并让旧行
只存在于 v1-compat catalog。每次只能命中一行。

### 6.2 条件先于应期

`VerdictCondition` 增加 `conditionId`、`conditionRuleId`、`sourceIds`、
状态和 `upstreamOccurrenceIds`。`YingQiCandidate` 增加 `timingId`、
`timingRuleId`、`upstreamConditionIds`、`upstreamRuleIds` 和 `sourceIds`。
共享 Freezed 类型只做有默认值/可空的 additive provenance 扩展，Liuyao current
report validator 要求这些字段非空；其他术数的构造和行为不变。

新顺序为：

```text
facts -> judgment + complete conditions -> eligible unresolved conditions -> timing
```

- `hasRescue=false` 不产生暗示成功的通用候选；
- 已解除条件不再保留，例如伏神已得出时删除“待出伏”；
- 同一候选解除多个条件时保留全部 condition IDs；
- 日/月尺度和日历角标行为保持现有兼容。

`YingQiService` 新入口只接收裁决后的 unresolved conditions、selected actor、
`LunarInfo` 和规则版本，不再接收原始 `yongShenTags`。先过滤
`hasRescue=true`；空输入返回空列表。去重键固定为
`(scale, triggerKind, triggerValue, targetActorId)`，合并时稳定 union 全部上游
condition/rule/source IDs。只有 `YingQiScale.ri` 进入日历日格，月尺度仍只显示在应期卡。

## 7. AI Projection 与提示词

### 7.1 Projection

新增 `LiuYaoAnalysisProjection`，采用严格、版本化 JSON 合同，至少包含：

- schema/rule-set/source-catalog 版本、固定分析阶段和分析状态；
- 用神模式、用户选择和角色清单；
- 用神自身事实，伏神与飞神事实分离；
- 有向 active/suppressed effects；
- 四值、nuance、matched decision row；
- 全部因素、条件和应期的上游链接；
- 本次实际使用的 source records；
- immutable policy：
  `calculationOwner=program`、
  `mayRecalculatePan=false`、
  `mayRecalculateAnalysis=false`、
  `mayReselectYongShen=false`、
  `mayOverrideVerdict=false`、
  `mayInventSources=false`、
  `mayInventTiming=false`、
  `timingIsGuarantee=false`。

v1 顶层 exact-key 至少为：

```text
projectionSchemaVersion, analysisSchemaVersion,
ruleSetId, ruleSetVersion, sourceCatalogVersion,
status, diagnostics, analysisStages, policy, pan, useSpirit, roles,
selectedUseSpiritFacts, actorAvailability, directedEffects,
auxiliaryEvidence, conflicts, factors, verdict, conditions,
timingCandidates, sources, trace
```

`useSpirit.mode` 精确区分 `selectedVisible|selectedHidden|unselected`。selected 模式
完整输出用户选择、全部用/元/忌/仇角色、伏神自身事实和飞神关系；unselected 模式
固定 `verdict=null`、`conditions=[]`、`timingCandidates=[]`，只开放
`maySuggestYongShen=true` 的 AI 建议边界。辅助 evidence 固定
`decisionEligible=false`。

formatter 只从一份 report/projection 格式化，继续保留现有 `analysis` section key，
并把 projection 放入结构化 metadata，同时用 canonical renderer 写入现有
`structuredOutput`。版本字段通过 typed `AnalysisContractMetadata` 暴露给 assembler/UI，
避免各消费者从 `Map<String,dynamic>` 私自 cast。

canonical projection 内的 `policy` 是 baseline/candidate 共享、字节相同的程序计算
所有权合同，不含 variant-specific prompt 内容或版本。`promptPolicyVersion` 属于最终
assembly/snapshot/evaluation request metadata；baseline 与 candidate 可以不同，但不得
改变 canonical projection、case input 或 request parameter hash。

projection 只带本盘实际引用到的 source 闭包，控制 token。decoder/validator 拒绝
未知 ID、孤儿 upstream、额外/缺失顶层字段和被改写的 immutable policy；非法 projection
不得发送给模型。source renderer 只有 `exactQuote` 可显示短引与引号，其他三种形态
分别标成采用释义、项目约定或仅定位。

### 7.2 不可移除 Guard

在 `PromptAssembler` 的最终组装边界追加六爻专属 system guard，而不是仅写入
built-in template。assemble 和 preview 使用同一函数，因此 built-in、brief、
active custom template 均不能删除以下约束：

- 程序拥有计算权，不重排、不重算、不覆盖裁决；
- 只引用 projection 提供的来源、短引和 locator；
- 不补写古籍原文或页码；
- 应期是条件观察窗，不承诺事件发生；
- 未选用神时只给明确标注的候选，不伪造程序裁决。

最终 block 至少固定包含并位于自定义 system 内容之后：

```text
[LIUYAO_IMMUTABLE_POLICY liuyao-ai-policy/1.0.0]
calculationOwner=program
mayRecalculatePan=false
mayRecalculateAnalysis=false
mayReselectYongShen=false
mayOverrideVerdict=false
mayInventTiming=false
...来源白名单、引用形态、用神与应期 allowlist 边界...
[/LIUYAO_IMMUTABLE_POLICY]
```

若 active custom analysis template 未引用 `{{structuredOutput}}`，guard 仍存在；模型
因缺少 program facts 只能声明资料不足，不能自行补算。guard 是唯一 policy 真相源，
built-in 只定义输出结构，不复制一套可能漂移的安全规则。测试断言最终 system prompt
以规范化 guard 结尾，而不只检查某个 substring。

保留 `builtin_liuyao_system`、`builtin_liuyao_analysis`、
`builtin_liuyao_brief` ID，不以改 ID 绕过 active selection。重写
comprehensive/brief 的结构为：

1. 问题与取用边界；
2. 盘面和世应；
3. 日月与状态；
4. 动变和有向作用；
5. 裁决、反证与被压制事实；
6. 未决条件；
7. 应期观察窗；
8. 古籍/项目依据；
9. 有边界的建议。

`_buildContext` 明确提供 `hasChangingGua` 等真实变量，测试必须从
`LiuYaoResult -> formatter -> PromptAssembler` 运行，不再手工注入掩盖缺字段。

### 7.3 快照兼容

`AssembledPromptMetadata` 和新 `CastSnapshot` 以有默认值的 additive 字段记录
`analysisSchemaVersion`、`projectionSchemaVersion`、`ruleSetId/version`、
`sourceCatalogVersion`、`promptPolicyVersion` 和实际 template IDs。旧 JSON 缺字段
仍可读取为 `legacyUnknown`，不得推断成 current。现有对话继续逐字使用原
system/user prompt，follow-up 不追补 guard；重新生成会创建新 snapshot，不原地改写旧消息。

AI 对话/提示词预览现有界面增加一行紧凑版本信息，例如
“分析 v2 · 投影 1 · 提示策略 1.0.0”；缺字段显示“旧版冻结提示词”。这只增加
版本可见性，不重设计结果页。

## 8. 用户可见古籍参考

`TermGlossary` 由 rule catalog 投影来源信息，保留当前定义、条件和含义，并增加：

- 主规则 ID、来源类型和题名；
- 经复核的章节/印刷页或安全 locator；
- `exactQuote` / `paraphrase` / `projectConvention` / `locatorOnly` 标签；
- 项目采用释义和证据边界。

弹窗不显示本机绝对路径，不把转述加引号，不把 locator-only 渲染成原文。
结果页布局不重做，只增强已有词典弹窗。

`lookupByRuleId()` 为主入口；`lookup(term)` 只经 catalog alias map 兼容。alias 弹窗
显示主规则来源并标注别名，不复制来源记录。`exactQuote` 显示“页级核验短引”；
`paraphrase` 显示“采用释义”；`projectConvention` 明示“项目约定”；
`locatorOnly` 明示“未完成页级复核、非决定性”。长内容放入受约束高度的滚动区域，
避免弹窗在小屏溢出。

## 9. 提示词评测设计

### 9.1 先冻结基线

修改提示词前，把当前六爻 system/analysis/brief prompt 和哈希冻结为
`legacy-e2e-diagnostic` 资产。评测器 variant 精确固定为
`legacy-e2e-diagnostic`、`canonical-v2-baseline` 和
`canonical-v2-candidate`，不依赖工作区 Git 历史临时还原。其中 `v2` 指
`ruleSetVersion=v2`，不是 `projectionSchemaVersion=2`。

公平 prompt 对照中二者接收字节相同的 projection/case input。旧 formatter 对比另记为
end-to-end 诊断，不能混入 prompt 因果结论。`canonical-v2-baseline` 使用冻结旧模板且
不追加候选 immutable guard；该绕过只存在于离线 evaluator，不得复用生产
`PromptAssembler`。`canonical-v2-candidate` 使用新模板和新 guard。两者必须断言
projection hash、case-input hash 和请求参数 hash 完全相同，允许不同的只有 assembled
system/user prompt、template IDs 和 prompt-policy metadata/hash。

把 40 例元数据迁移为单一版本化 JSON fixture 源，黄金测试和 evaluator 共同读取，
不得抓取 Dart 私有常量或复制 case。manifest 使用两个正交字段：
`caseKind=originalBook|ruleValidation` 与 `evaluationSplit=calibration|holdout`。
validator 强制所有 `ruleValidation` 都属于 `calibration`，`holdout` 只允许
`originalBook`；这样原书/章法性质不会与调优/留出用途混为一谈。

holdout 固定为 6 个 originalBook 案例；冻结 salt 字面量为
`liuyao-holdout-v1-2026-08-01`，对 UTF-8 字节
`salt + "\\n" + caseId` 做 SHA-256，按小写十六进制 hash、再按 `caseId` 升序取前 6 个。
迁移 fixture 时把有序成员 ID、每项 selection hash 和由 canonical JSON 计算的 cohort hash
写死在 manifest；validator 必须重算并逐字节核对。draft 模式拒绝读取其
expected/adjudication，最终 holdout phase 才启用。
holdout 第一次揭示后写入不可覆盖的 reveal marker（candidate hash、run ID、UTC 时间和
cohort hash）；runner 拒绝第二个 candidate 用同一 cohort 满足 AC9。后续查看只能明确标为
`regression`，不得继续称为 holdout 或作为新候选的调优证据。
manifest validator 继续锁定至少 26 个 original、14 个 rule-validation，并把声明
卦名、动爻、用神与 `GuaCalculator` 实际盘面交叉校验。

模型输入不得包含原断结果、期望趋势、期望因素或评分答案；只有生产程序本来就会
给出的 projection 可以进入输入。

### 9.2 离线硬门禁

对每个输出先做确定性检查：

- 不改写程序四值；
- 不遗漏未决条件，尤其 `hasRescue=false`；
- 不捏造盘面、用神、动爻、应期支或 source locator；
- 不把应期写成必然发生；
- 不出现输入 source registry 之外的古籍引用；
- 不出现伪造逐字引文或页码。

硬门禁失败即记为候选失败，不用主观总分掩盖。

可机器判定项直接使用 projection allowlist 和稳定 IDs；语义矛盾/必然性采用锁定
rubric 的盲审，reviewer 看不到 baseline/candidate 标签。机械 AC9 使用同一配置中的
endpoint 和精确 `model` 作为 judge，不引入第五个本地配置字段：temperature=0、
max completion tokens=2048、JSON response format、支持时 seed=271828；不支持 seed 时
记录 capability fallback。judge prompt/rubric 版本和 hash 必须冻结。盲化顺序由
`SHA-256("liuyao-judge-order-v1\\n" + runId + "\\n" + caseId + "\\n" + repetition)`
的最低位决定，blind label 映射随产物保留。judge 返回 malformed、缺维度或不确定时该
pair 失败关闭；人工复核只能作为补充说明，不能把机械失败改成 AC9 通过。candidate 最终
产物要求所有硬门禁 100% 通过，并且每个声明 cohort 的通过率不得低于 baseline。

### 9.3 真实模型配对

新增显式 opt-in CLI。baseline/candidate 使用相同 endpoint、精确 model、
结构化输入、max tokens、最低 temperature、response format 和请求次序控制。
支持时使用相同 seed；不支持时每例至少 3 次并交替请求顺序。

请求使用 non-streaming 路径；每个 `(caseId,repetition)` 的 baseline/candidate
按稳定 pair hash 交替 `AB/BA`。只重试 transport、429 和 5xx，并保留 logical pair ID，
不能选择性重试低分输出。seed 即使支持也至少重复 3 次，以满足“可重复改善”门禁。

记录非敏感元数据、prompt/fixture hash、延迟、token 和评分。主观维度采用
0-2 固定 rubric：证据覆盖、冲突解释、问题贴合、来源忠实、条件/应期解释、
不确定性边界、清晰度。每个锚点在 rubric 中给出 0/1/2 的可执行判据。产物保留经过
脱敏的 normalized generation output、judge request/response、blind-label mapping 和每项
解析结果，使评分可独立重放；任一缺失 pair、重试耗尽或解析失败均使 AC9 失败关闭。

聚合顺序固定为：先求同一 `(caseId, repetition, dimension)` 的 candidate-baseline
配对差；再对一个 case 的全部有效 repetition 求均值；最后对 cohort 内 case 做不加权
平均，模型重复不能当成独立案例。声明 cohort 固定为 `overall`、`originalBook`、
`ruleValidation`、`holdout`。七个维度在四个 cohort 的 delta 都必须 `>=0.00`；不确定性
边界和清晰度同样不得退化，不存在平均分抵消。pair delta=0 为 tie，非零才进入胜率分母；
任一 cohort 没有有效 case、任一 case 少于 3 个完整 pair 或任一维度缺失均失败关闭。

候选必须：

- 所有硬门禁不低于基线；
- original、validation、holdout 分组均无高严重度退化；
- 七个维度必须在上述四个 cohort 的每个单元格逐项不下降；五个核心维度中至少一项
  达到可重复改善，不能以 aggregate 平均分抵消单项回归。

“可重复改善”固定为至少一个预注册核心维度在 overall 和 holdout 的 case-level
0-2 平均分都提升 `>=0.20`，两组各自的非平局 pair 中 candidate 胜率 `>=60%`，且每个
计入改善的 case 在三个 repetition 中至少两个方向一致。没有非平局 pair 时胜率条件
不成立。该门禁是小样本启发式发布门禁，不宣称统计显著性或把 3 次重复当作 18 个独立
holdout 样本。任何新增高严重度 hallucination 直接失败，不能用总分抵消。

“靠拢实际结果”只表示与已核验原书占例、程序证据链和记录原断不冲突，
不声明现实预测准确率。

### 9.4 凭据和产物

凭据优先来自 `LIUYAO_AI_EVAL_API_KEY`、`LIUYAO_AI_EVAL_BASE_URL`、
`LIUYAO_AI_EVAL_MODEL`，可选 provider label 来自
`LIUYAO_AI_EVAL_PROVIDER_LABEL`；其次来自精确 gitignore 的
`tool/liuyao_ai_eval/eval.local.json`。标准 `devtools_options.yaml`、应用 Drift/
SecureStorage、snapshot 和命令行参数都不作为凭据容器。CLI 必须带
`--confirm-real-model` 才联网。

本地 JSON 只允许 `apiKey`、`baseUrl`、`model`、可选 `providerLabel` 四个 key，未知 key、
空必填值或非字符串值均 fail closed；环境变量逐字段覆盖本地 JSON。统一
`realModelStatus` 枚举为 `ready|blockedMissingCredentials|blockedInvalidConfiguration|
failedTransport|completed`，缺配置必须返回 `blockedMissingCredentials`，不再使用第二个
同义状态名，也不写伪成功报告。
启动时只报告“已配置/未配置”，不得打印 key 的值、长度、前后缀或 hash。

写入产物前后扫描已知 secret 值、`Authorization` 和 bearer 模式；输出目录
限制在指定 eval 目录，异常先归一化/脱敏再记录。

runner 先在内存中挑选允许记录的字段，再替换实际 secret 并扫描 Authorization、
Bearer 和 API-key 模式；零命中才原子写入。写完后递归扫描整个 run 目录，零命中
才创建 success marker。base URL（可能含内网地址）、headers、raw config、raw
exception/stack 均不落盘；异常只记录 `errorKind/statusCode/retryCount`。非敏感产物
固定写到本任务 `research/eval/<runId>/`，含 model/参数、prompt/input/fixture/rubric
hash、latency、tokens、逐项分数及理由和双重扫描结果。
每个 CLI 子命令都必须显式接收同一个 `--run-id`；除新建 run 外不得猜测“最新目录”。
prepare/model/judge/compare/scan 在读入时重算并核对 run manifest、fixture、rubric、model、
projection、请求参数和 variant hash，任何不一致或陈旧产物均失败关闭。

## 10. 兼容、迁移与回滚

- **阶段 1，identity baseline**：先冻结当前 40 例 fixture hash，落 catalog、稳定 ID、
  dual-read 和 validator；`v1-compat` 必须保留显式可调用入口，并对全部冻结 report、
  condition、timing 和 formatter baseline 做字节/语义等价门禁，证明与任务前结果一致。
- **阶段 2，semantic v2**：先按证据/项目裁定修改 fixture 期望，再启用有向 edge、
  对称 availability、伏神已出修正和 condition-driven timing。
- **阶段 3，projection/guard**：formatter 改成单次 report -> projection，修复真实
  `hasChangingGua` context；assembler 末端追加 guard，再更新 built-ins。
- **阶段 4，history/UI/eval**：加 snapshot 版本、glossary 来源和 opt-in evaluator；
  无有效凭据时 AC9 保持 deferred。
- 规则身份采用 dual-read、single-write：新执行引用只写稳定 ID，`term` 仅作显示；旧 term 只由冻结 legacy map 兼容解析。
- Freezed/共享模型只做有默认值的兼容扩展；其他术数现有行为必须回归。
- 不迁移数据库、不写回历史盘、不批量重生成旧对话。
- formatter 保留 section keys，模板保留 IDs，UI 保留当前布局。
- 领域规则、AI projection、prompt guard、词典来源和 evaluator 分逻辑提交。
- 规则回滚只需把 `LiuyaoRuleSetVersions.current` 从 v2 指回冻结的 `v1-compat`；
  v1 catalog/policy 至少保留一个发布周期，不需要重写排盘或数据库。
- Prompt 可回到冻结 baseline 文案，但 immutable guard 作为事实/引用安全边界保留，
  不能按普通模板一起回滚掉。projection v1 wire 保持可读。
- UI 可隐藏新增版本/source 行而保留 additive 数据；evaluator 是 opt-in 工具，删除
  gitignored config 和本地产物不影响产品启动。

若规则回滚，旧排盘运行时显示 v1 分析版本；已创建的 v2 对话仍逐字重放 v2 snapshot，
通过版本标签解释差异，不能把 v1 新分析和 v2 旧对话静默混成同一上下文。

## 11. 主要风险

| 风险 | 控制 |
|---|---|
| 稳定 ID 迁移遗漏某个 term | catalog validator、producer coverage 和 term 改名不改行为测试 |
| 共享模型扩展影响其他术数 | 默认字段、定向共享回归和全量测试 |
| 来源条目数量多但证据弱 | 证据状态显式化，locator-only 不参与决定性裁决 |
| 修方向性后黄金结果变化 | 先修独立期望，再改引擎，禁止个案特判 |
| projection 变长导致 token 上升 | 只投影本盘实际命中来源，评测 token 和解释质量 |
| 自定义模板绕过安全边界 | assembler 末端追加 immutable guard，assemble/preview 同路 |
| 真实模型不支持 seed | 记录能力并用重复、交替顺序和分组统计 |
| 当前无有效评测配置 | 其余实现与离线评测继续，真实调用保持未通过状态 |

## 12. 验证矩阵

| 测试面 | 必须覆盖 |
|---|---|
| Catalog | ID 唯一、引用闭包、A-D/referenceKind 合法组合、alias 单映射、immutability、未知 ID |
| 主规则完整性 | 所有 analyzer 主 term、decision、condition、timing 都解析到 rule/source；项目裁决不冒充古籍 |
| 证据 | 四组已核页才可 `exactQuote`；《卜筮正宗》只能 C/`locatorOnly`/非决定性；无绝对路径 |
| Term 迁移 | 同 `ruleId` 改中文 term 不改变 verdict/timing；legacy fallback 只认冻结 map |
| 有向作用 | 连续相生/相克在用神为起点/中点/终点的正反例；suppressed path 不参与 |
| Availability | 元神/忌神分别覆盖回头克、化退、冲散、日合、月合和已冲开，证明对称 |
| 伏神 | 使用伏神自身事实；已得出无待出伏；无救 condition 无 timing；冲飞引用正确 actor |
| 裁决 | factor 按 arbitration order，唯一 decision ID，所有 factor/condition upstream 闭合 |
| 应期 | 只消费可解 condition、无孤儿、多条件同候选 union、日/月 scale 与 Calendar 回归 |
| Projection | exact-key round-trip、完整角色/作用/factors/conditions/timing/sources、policy 不可改、unselected 空裁决 |
| Formatter | 真实 `LiuYaoResult -> Analyzer -> Projection -> render`，完整伏神事实和真实 `hasChangingGua` |
| Prompt | comprehensive/brief/default/custom/preview 均保留末尾 guard，built-in IDs 不变 |
| Conversation | 旧 JSON 解码、旧 prompt 精确重放、regenerate 用新版本、legacy/current 版本展示 |
| Glossary | 主规则/alias、四种 reference kind、locatorOnly 非引文、长文本小屏布局、无 path |
| Golden | 至少 26 original + 14 validation；声明卦名/动爻/用神与计算结果一致；语义先改 fixture |
| Evaluator offline | 缺配置、路径限制、seed fallback、AB/BA、retry、artifact schema、双重敏感扫描 |
| Evaluator real | 同模型/参数/输入 paired run、硬门禁 100%、分组不退化和可重复改善 |
| 全仓 | 六爻定向、共享 verdict、其他 formatter/prompt 回归、`flutter analyze`、全量 `flutter test` |

## 13. 主要实现边界

- `lib/domain/services/liuyao/analysis/rules/`：source/rule/decision/condition/timing
  catalogs、版本、ID factory 和 validator。
- `lib/domain/services/liuyao/analysis/models/`：occurrence、actor、availability、
  directed effect、trace、projection 和 glossary identity。
- `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart`：固定阶段编排，只生成一份 report。
- `sheng_ke_service.dart`、`verdict_service.dart`、`ying_qi_service.dart`：有向关系、
  stable-ID 裁决和 condition-only timing；其他 fact services 经统一 rule factory 产出 tag。
- `lib/domain/services/shared/analysis/models/verdict_models.dart`：仅 additive provenance 字段。
- `lib/ai/output/formatters/liuyao_formatter.dart`：projection 和 canonical renderer；
  `lib/ai/service/prompt_assembler.dart`：不可移除 guard；`builtin_templates.dart`：输出结构。
- `lib/ai/model/cast_snapshot.dart` 与现有 AI 对话 UI：additive 版本 metadata 和可见性。
- `term_glossary.dart`、`term_glossary_dialog.dart`：rule-based source projection。
- `test/fixtures/liuyao/` 和现有六爻/AI tests：黄金单一事实源与跨层门禁。
- `tool/liuyao_ai_eval/`、`.gitignore`：opt-in 真实模型评测与专用本地配置。
- 实现后同步 `.trellis/spec/domain/liuyao-analysis-engine.md` 与
  `docs/architecture/divination-systems/liuyao.md`，使版本、阶段、证据和 AI 边界一致。
