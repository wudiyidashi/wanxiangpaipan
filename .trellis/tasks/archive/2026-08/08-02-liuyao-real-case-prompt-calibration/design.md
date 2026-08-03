# 设计：六爻真实案例的阶段裁决与生产提示词校准

## 1. Problem Statement

当前错误不是一句 prompt 文案造成，而是五层信息被压平：历史阳历时间未保存、动爻前段作用被变爻后果立即抹掉、非所选爻事实没有稳定投影、六合带固定吉性、单一四值 verdict 把“形成”和“最终顺利”混为一谈。目标是让每层只拥有明确权限，并使生产 AI 能表达“事成而受困”。

```text
GuaName input + calendar provenance
  -> LiuYaoResult (stored facts)
  -> LiuYaoAnalyzer v3 (phase-aware effects, all actors)
  -> question focus + lifecycle assessment (pure deterministic service)
  -> LiuYaoAnalysisProjection schema 2
  -> PromptAssembler immutable guard policy 1.1
  -> model generation
  -> blind local judge (outcome visible only here)
```

## 2. Calendar Contract

在 `LiuYaoResult` 增加 additive 日历来源 enum，JSON 默认 `legacyUnknown`：

```text
derivedFromCastTime | providedSolar | providedGanZhi | userOverride | legacyUnknown
```

- 普通起卦写 `derivedFromCastTime`。
- 卦名卦阳历模式回调附带 `_solarTime`，父页将它作为 `castTime` 并写 `providedSolar`；`LiuYaoSystem` 校验四柱与 `LunarService(castTime)` 一致，失败关闭。
- 卦名卦干支模式写 `providedGanZhi`，`castTime` 明确为记录时间，分析只用给定四柱。
- 结果页四柱编辑后写 `userOverride`；旧记录为 `legacyUnknown`，不猜测来源。

projection calendar 增加 `inputMode`、`solarConsistency` 和 `analysisCalendarAuthority`。formatter 根据来源写“起卦阳历时间”或“记录时间”，不再把所有 `castTime` 都称为四柱对应公历。

## 3. Rule-Set v3：阶段化动变作用

发布 `LiuYaoRuleCatalog.v3` 并令 `current=v3`，保留 `v1-compat` 和 `v2` 的冻结行为。

### 3.1 两条时间线不能互相删除

current v2 的 `ActorAvailabilityService` 把回头克、化退等作为全局 blocker，使本卦动爻从一开始就无法对外作用。本案例因此把三爻卯木克世标成 suppressed。v3 改为：

```text
main moving effect       -> phase=formation|earlyProcess
changed-line consequence -> phase=laterProcess|finalState
```

- 本卦动爻只要在本卦阶段可用，先生成其外向生克 occurrence。
- 回头克/化退/化绝另生成后续限制 occurrence，可降低持续性、最终兑现或后段作用，不能追溯删除前段 occurrence。
- 真空、冲散等明确“当下不能发生”的状态仍可阻止前段作用；每种 blocker 必须在 v3 policy 中声明适用 phase。
- `DirectedEffectOccurrence` 增加稳定 `phase`/`horizon`，status 表达该阶段的 active/suppressed；trace 和 factor 保存阶段。
- 新口径先以项目约定发布，执行中继续核验本地《增删卜易》页级证据，不把推导规则伪装成古籍原文。

本案例正例锁定“卯木前段克初爻未土、后段受申金回头克”；另加非本案例反例，证明真正当下不可用的动爻仍不能传力。

### 3.2 条件必须有作用维度

`VerdictCondition` 增加或投影出 `scope/dimension`。伏神父母的 `hasRescue=false` 表示当前合同/权属轴没有明确释放路径，不再自动等价为整个交易不能形成。旧四值 verdict 可继续描述所选 actor 的单轴强弱，但不能冒充完整问题结论。

## 4. Lifecycle Judgment

不扩张共享 `VerdictTrend` 的四值语义。新增六爻专属、版本化 `LiuYaoLifecycleJudgment`，由纯函数 question assessment service 消费 `question + result + AnalysisReport`：

```text
formation: willForm | unlikely | pending | unclear
quality: favorable | adverse | mixed | unclear
continuity: stable | unstable | conditional | unclear
persistence: smooth | entangled | brief | unclear
headlineCode: formsButAdverse | ...
matchedDecisionRowId
evidenceOccurrenceIds per dimension
```

服务不读取实际结果，不按案例 ID/卦名特判。它只在问题分类和证据满足稳定 decision row 时输出；否则维度为 `unclear`，AI 不得补猜。

本案例的通用规则组合为：

- formation：双六合的合成/黏合范围，加应生世等关系形成证据；
- quality：初爻妻财月克、死，三爻旺忌在前段克世财；
- continuity：父母伏而飞克、应入动墓、另一财化绝等合同和后段证据；
- persistence：主证据不利且本变双六合，解释为不利关系持续黏住。

命中 `formsButAdverse` 时固定语义为“事必成，成而受困；合非吉兆，是套”。显示文案可自然化，但四个维度和证据 ID 不得改变。

## 5. Full-Actor Projection Schema 2

projection schema 2 增加：

- `calendarAuthority`
- `questionFocus`
- `actorFacts`：六个本卦爻、对应变爻和伏神的完整 tags/六神/世应/角色
- `useSpiritOccurrences`：所选用神及所有同六亲另一现分别评估
- `shiYingRelation`
- phase-aware `directedEffects`
- `lifecycleVerdict`
- tag/interpretation 的 `decisionScopes`、`authority` 和 `evidenceLevel`

`_tagToJson` 从 catalog 投影规则阶段和权限，不再让模型从 `polarity` 猜权限。辅助证据可以有局部 scope，但默认不能决定 `overallOutcome`。

上爻妻财同时输出 `旬空` 与 `假空`。机械 calculation 采用“动不为空”；其“收费名实/兑现风险”只能放在 `interpretiveEvidence`，不得改写 active state。

模型传输使用 compact view 时仍以 full schema 2 为程序真相。若 `conditions=[]` 且 `timingCandidates=[]`，full projection 仍保留 active `liuyao.rule.hechong.binding-opened` 以及同 actor、同 `relatedYao` 配对的 active `liuyao.rule.hechong.mutual-binding` 供审计；compact view 则闭包式移除两者的 actor tag、selected/use-spirit occurrence 引用和 source reference。assembler 不再从 full projection 生成“日冲已解除合绊。”或任何等价固定句，system guard 与 output contract 一致要求省略所有已解除/已冲开/已释放状态文字，并禁用“日冲已解除合绊”、`合绊=true` 和 `冲开=true` 等表达。触发条件只依赖结构化状态、actor 和稳定规则 ID，不得识别案例、卦名或问题文本。评测器保持现有 hard gates：省略释放描述可通过 `timingAndSourcesGrounded`，未来等待/择时、无投影条件或日期仍失败。

## 6. 六合、世应、六神与卦名

### 6.1 六合

`GuaChangeService.analyzeGua` 接受规则版本。v1/v2 保持冻结；v3 将六合 polarity 设为 context-dependent/neutral，理由改为“关系黏合、合住、牵绊、迟滞或持续，吉凶须随主证据”。

catalog 为六合声明：

```text
decisionScopes = [formation, persistence]
forbiddenScopes = [quality, overallOutcome]
```

若 lifecycle quality 为 adverse，question assessment 将双六合组合成 `entangled`；若主证据有利，可组合成稳定关系。不能仅按两个六合就判吉或凶。

### 6.2 世应、六神与卦名

- 新增纯函数世应关系投影，输出五行生克、合冲和方向；不把静爻生克伪装成与动爻同权的 force。
- 六神只细化事件性质。朱雀的言语/宣传/争执、白虎的损耗/压力在本地页级来源未核验前标 D 级 interpretive convention。
- 豫变旅的“前段安顿、后段寄居不稳”只作为低权限时间结构，不单独决定 lifecycle verdict，也不得伪造《周易》引文。

## 7. Question Focus And Prompt Policy 1.1

question focus resolver 仅组织角色，不自动持久化或替用户选择用神：

- 妻财：付款、押金、费用和损失；
- 父母：房屋、合同、权属和身份文书；
- 兄弟：竞争、额外费用和利益分流；
- 官鬼：争议和风险；
- 世/应：求测者与对方。

immutable guard 明确两个状态机：

```text
if verdictMode == abstain:
  state missing prerequisite
  suggest candidates and verification dimensions
  forbid overall conclusion and timing

if verdictMode == explainLifecycle:
  restate exact lifecycle dimensions
  explain formation before quality/continuity/persistence
  preserve evidence and counter-evidence by phase
  never collapse "formed" into "smooth"
```

comprehensive/brief 模板都按完整租期输出：签约/入住、出租权、费用、交付占有、持续履约。风险建议必须回链 occurrence ID 或明确标成低权限象意。不得依据 calibration outcome 写“二房东跑路”等输入外事实。

旧 template IDs 保持不变；assembler 继续在自定义模板之外追加 immutable guard 和 canonical projection。已有 `CastSnapshot` 不重写。

## 8. Evaluation Design

### 8.1 Fixture And Leakage Boundary

新增 real-world calibration fixture，包含原始盘面、规范化分析时间、问题、用神场景、实际结果和用户复盘。生成请求只读取 `question + pan + selected main-1 projection`；outcome 和事后映射只在两份输出完成后进入 blind judge。

确定性探针覆盖 main-1、main-6、hidden-1；真实模型配对覆盖：

- unselected：必须 abstain；
- selected main-1：必须输出 `willForm/adverse/unstable/entangled`。

### 8.2 Baseline/Candidate

- baseline：冻结 tag `v1.6.0` 的真实 system/user request 和 schema 1 投影。
- candidate：v3/analysis schema 2/projection schema 2/policy 1.1 的生产装配。
- 两者共享原始卦、规范化日历、问题、模型、temperature、max tokens、seed capability 和交错顺序；批准的结构差异写进 manifest。
- 每次实质调参升 candidate/run ID；旧结果只读。

### 8.3 Gates

确定性 hard gates 先于 judge：结论权限、四阶段保真、前后作用不互删、全爻证据完整、六合 scope、假空口径、条件/应期/来源无捏造。主观 judge 评分阶段完整性、风险相关性、证据层级、问题贴合、不确定性和清晰度。精确猜中已知结果但无盘面依据按 hallucination 扣分。

评测器 timeout 变为本地有界配置并写入 request identity；judge prompt 固定 exact JSON schema，解析器不静默接受缺字段。失败 attempt 独立编号、可重试、不覆盖。

## 9. Versions And Compatibility

| Contract | Current | Candidate |
|---|---|---|
| analysis schema | 1 | 2 |
| rule set | v2 | v3 |
| source catalog | 1.0.0 | 1.1.0 |
| projection schema | 1 | 2 |
| prompt policy | 1.0.0 | 1.1.20 |
| app | 1.6.0+1 | 1.6.1+2 |

数据库表不变；`LiuYaoResult` JSON 仅 additive default。v2、schema 1 和旧 snapshot 保留用于历史兼容；新评测使用新 run ID，不回写 `canonical-v2-r6`。

## 10. Rollback

- 日历修复可独立回滚 provenance 展示，但不得恢复 providedSolar 使用 now 的行为。
- v3 可将 `current` 回指 v2；v2 availability、golden 和 catalog 不得重写。
- lifecycle/projection/prompt 可回滚到 schema/policy 1；旧会话无需迁移。
- candidate 未过 hard gates 时拒绝发布，保留失败报告，不放宽 rubric 或读取 holdout 调参。

## 11. Bug Analysis: 无应期摘要跨层回流

### 1. Root Cause Category

- **Category**: B + D（跨层合同与测试覆盖缺口）。compact JSON 已省略释放链，但 formatter 又从 full projection 独立渲染 `verdict.summary`；模型可见输入并不只有 canonical JSON。

### 2. Why Fixes Failed

1. 首轮只收紧 system/user 合同，模型仍会复述结构化输入中的释放词，属于表层修复。
2. 随后只裁剪 resolved binding 与来源引用，遗漏 availability release IDs 和 full summary 的可读渲染路径，范围仍不完整。
3. 负面词表会把禁止词本身送给模型，增加复述概率；最终改为只描述允许的当前态输出面。

### 3. Prevention Mechanisms

| Priority | Mechanism | Specific Action | Status |
|---|---|---|---|
| P0 | Architecture | full projection 只供程序审计，模型只消费 compact view；formatter 不得旁路 compact 的省略决策 | DONE |
| P0 | Test Coverage | 同时断言 compact JSON、可读 analysis、assembled system/user 与 production adapter 的词频和出现位置 | DONE |
| P1 | Versioning | 每次实质提示词修改升 policy/run ID，旧评测只读且不得覆盖 | DONE |

### 4. Systematic Expansion

- **Similar Issues**: factors、模板正文和历史 snapshot 都可能成为第二模型输入面；新增省略规则时必须逐层审计，但旧 snapshot 按兼容合同保持冻结。
- **Design Improvement**: 省略条件由结构化状态与稳定 rule ID 决定，避免案例名或通用字符串清洗。
- **Process Improvement**: production adapter 重建与真实模型评测前，先跑“full 保留、compact 省略、assembled 无回流”的确定性门禁。

### 5. Knowledge Capture

- [x] 更新六爻领域 code-spec 的 full/compact/formatter 合同。
- [x] 更新跨层思考指南的模型可见输出面检查项。
- [x] 用租房 6 组和代表古例 9 组本地同模型配对验证最终 policy。
