# 六爻断卦分析引擎规范

> 来源任务：07-22-liuyao-analysis-engine（提交 489c3a1）。
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

**Decision**: `verdict_service.dart` 按四步顺序求值：受力归集（按层级日月 > 动爻 > 暗动 > 变爻）→ 元/忌活跃性 → 悬置状态转条件 → 决策表首行命中。输出 `VerdictJudgment{trend, nuance, conditions, factors, summary}`，趋势四值（可成/难成/待条件/趋势不明），派生不落库。

**关键口径（修改前必读，单测依赖）**:

| 规则 | 口径 | 实现位置 |
|-----|------|---------|
| 净强弱三分类 | strong=L1 有扶且重抑集空；weak=重抑集非空且全层无扶；余为 mixed。重抑集=月克/日克/囚/死/日破/冲散/回头克/化退神/飞克伏/伏神受制。**动爻克不入重抑集**（即忌神动，由 jiActive 处理，避免双重计数）；'休'记中性。yuanActive 的三条来源均会产生扶因素，因此与 weak 互斥；重抑与元神生并见必归 mixed | `verdict_service.dart` |
| 悬置转条件 | 旬空/月破/入墓/合住合绊/化空破墓绝/伏藏不判凶，转 `VerdictCondition`；真空与月破的 hasRescue=非 weak，飞克伏的出伏条件 hasRescue=false；日合月合仅动爻悬置，静爻论合起（扶）；化合按化扶归 L4 扶，不悬置。新增条件须同步 `YingQiService` 的解除候选 | 同上 `_buildConditions`、`ying_qi_service.dart` |
| 元忌活跃性 | 标签驱动：yuanActive=动爻生/连续相生/暗动生；jiActive=动爻克/连续相克/暗动克。贪合忘生克已由事实层替换标签，无需二次判遮蔽；攻击爻自身回头克/化退/冲散则忌神受制 | 同上 |
| 决策表 | 首行命中保证唯一。前置规则先于强弱分支（领域复核 2026-07-25）：用神自身回头克且无 L1 日月扶 → 难成（师之明夷，不被同卦连续相生反向覆盖）；用神回头生、无活跃忌神且无实质悬置条件（仅"待冲开"不算）→ 可成（复之震）。weak 只处理无救、忌神乘衰与衰而无助，不设元神分支；元神优先只在 mixed 中判定，且须有接续证据（连续相生/贪生忘克标签，或忌神不活跃）；元神仅暗动而忌神明动仍以忌神为先（临之泰）；mixed 且条件皆可解 → 待条件；mixed 且 L1 有扶 → 先难后成（克处逢生，否之讼） | 同上 switch |
| 消费标签 | 裁决层按 term 字符串消费既有标签（与 YingQiService 同模式），不重算事实层；术语改名须同步 `verdict_service.dart` 的 term 集合 | 同上常量集 |

**测试**: 决策表行序或口径变更必须同步 `verdict_service_test.dart` 与 `verdict_golden_test.dart`（黄金断例 40 例 = 26 个原书占例 + 14 个明确标注的"章法校验例"，均注明问事、月日、卦与动爻、取用、章节及校对本页码，覆盖矩阵与来源构成下限见任务 design.md §6，不得静默降低）。领域复核发现不一致时先裁定并修正断例；只有断例期望确定后才调整引擎。

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

**跨模块上下文传递**: 日历应期模式用纯字符串对象 `CalendarGuaContext`（title/yongShenBranch/yingQiByBranch）经 route arguments 传入，**日历模块不得 import 六爻分析模型**。

## Gotcha: 应期日历角标只匹配日尺度候选

> **Warning**: `CalendarGuaContext.yingQiByBranch` 只收 `YingQiScale.ri` 的候选（构造于 `liuyao_result_screen.dart`），月视图「应」角标按日支匹配。月尺度候选（如“出月解除月破”）只显示在应期卡，不进入日格角标。调整 scale 前先确认日历侧影响。

## Tests Required

- 引擎每个概念 ≥1 正例 + 1 反例：`test/unit/services/liuyao/analysis/`（夹具 `helpers/analysis_fixtures.dart` 提供 buildGua/buildLunar/makeYao）
- 规则口径变更必须同步改对应单测并在本文件更新口径表
- 序列化兼容：旧 JSON 无用神键 → null（`liuyao_analysis_controller_test.dart`）
