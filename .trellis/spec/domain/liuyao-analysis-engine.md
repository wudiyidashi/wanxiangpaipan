# 六爻断卦分析引擎规范

> 来源任务：07-22-liuyao-analysis-engine（提交 489c3a1）。
> 引擎位置：`lib/domain/services/liuyao/analysis/`，唯一入口 `LiuYaoAnalyzer.analyze()`。

## Design Decision: 断卦规则以《增删卜易》为裁决基准

**Context**: 六爻各流派对暗动、真空、刑害等规则存在分歧，引擎判定和单测的"正确答案"必须有唯一口径。

**Decision**: 一切流派分歧以《增删卜易》裁决；《增删卜易》弃用但产品需要的概念（三刑、相害）按《卜筮正宗》补充实现，且 priority 置最低档（≥45），不参与吉凶主判。

**关键口径（修改前必读，单测依赖这些结论）**:

| 规则 | 口径 | 实现位置 |
|-----|------|---------|
| 暗动 | 旺相静爻逢日冲；休囚静爻逢冲=日破；休囚动爻逢冲=冲散；旺相动爻冲之不散；旬空爻不论暗动（论冲空） | `dong_bian_service.dart` |
| 真空/假空 | 休囚安静之空为真空；动不为空、旺不为空为假空 | `kong_wang_service.dart` |
| 贪合忘生克 | 合的优先级高于生克：动爻被合住则忘生忘克 | `sheng_ke_service.dart` |
| 化进神对 | 寅→卯、巳→午、申→酉、亥→子、丑→辰→未→戌→丑（土循环） | `dong_bian_service.dart` jinShen 表 |
| 十二长生 | 五行论长生（不分阴阳干），水土同宫长生申 | `tables/chang_sheng_table.dart` |
| 半合 | 必须含帝旺支；缺旺支的两端（拱局）不算 | `tables/dizhi_relations.dart` |
| 三刑 | 寅巳申、丑戌未须三支齐全且至少一爻动；寅申两支优先只论冲克。子卯刑及辰午酉亥同支自刑可两支判定 | `he_chong_service.dart` |
| 应期 | 应期是状态解除或条件成熟的候选窗口，不代表事情必成；填实、出空、出月必须分开表达 | `ying_qi_service.dart` |

**近义术语归并约定**: 化扶/冲起/冲实/冲脱等近义概念**不单独出标签**，归并到主概念（化进退/暗动/冲空/冲开），仅在 `models/term_glossary.dart` 中以别名词条说明归并关系。新增术语时先查词典是否已有主概念。

**化变并存约定**（用户口径，2026-07-22）: 动爻与本位变爻的合冲与五行生克**可并存且须同时记录**（子化丑=化合兼回头克，卯化戌=化合兼克出），检查次序：进退→生克→合冲→化空→化破→化墓→化绝；「克出」=本爻克变爻。变爻只与本位动爻论关系，不与本卦他爻论合冲。关系图化变线并记全部关系（`·`分隔、双行绘制），线型取影响最大者。

**用神与应期约定**（用户口径，2026-07-23）: 先判断用神状态和事情趋势，再以空待实、破待出月/填实、合待冲、墓待开等条件生成应期候选。不得按吉凶标签数量直接输出总体吉凶。伏神取用时，状态、应期和总览必须分析伏神自身，不能复用同位飞神的旺衰空破标签。

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
