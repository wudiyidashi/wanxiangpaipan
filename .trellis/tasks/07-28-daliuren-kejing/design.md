# 设计：六十四课经结构化目录与匹配服务

## 1. 输入与输出

输入为前置任务定义的只读 `DaLiuRenFactSet`，至少包含四课、三传、课体、天将、空亡、遁干、旺相、六亲/关系和版本元数据。课经服务不得自行重排天地盘或重新计算九宗门。

输出为：

```text
KeJingReport
  catalogVersion
  sourcePanVersion
  compatibilityStatus
  matches: DlrRuleHit<KeJingResult>[]
  conflicts: DlrRuleConflict[]
```

`KeJingResult` 保存课经 ID、传统题名、结构化命中依据、主次/互斥状态和短摘要；完整短引文通过 sourceRef 查目录，不在每个报告实例复制。

## 2. 目录与生成

- 规范源：`assets/data/daliuren/classics/kejing.json`，只接受证据子任务批准的 schema。
- 条件节点是封闭枚举，例如课体、课位关系、三传结构、天将、空亡、旺相和布尔组合；禁止字符串 eval、正则解析古文或动态 Dart 代码。
- 生成器把每条规则编译为强类型 predicate tree，并检查所有字段、枚举和事实路径可解析。
- 目录必须声明 `ordinal` 1-64；ordinal、ruleId 和传统题名分别唯一。
- `implies`、`excludes`、`priority` 只有在底本明确或产品需要稳定呈现时填写；目录校验拒绝循环排除和悬空引用。

## 3. 匹配算法

1. 校验 fact set 与当前课经目录兼容。
2. 按 ordinal 评估全部 64 条 typed predicate。
3. 为命中规则记录每个原子条件实际读取的 fact 和值。
4. 应用显式互斥/主次关系；被抑制命中仍进入 conflict trace，不静默丢弃。
5. 以 `priority -> ordinal -> ruleId` 形成稳定输出。

课经只产生经典规则命中，不直接生成 `VerdictTrend`。最终断课服务可引用命中 ID，但不得解析课经摘要。

## 4. 兼容与呈现

- 报告为运行时派生，不写入 `DaLiuRenResult`；导出/AI 可序列化报告及所用版本。
- 旧盘仍可评估时标记“当前课经目录解释旧盘”；缺关键事实时返回 `unsupportedFacts`，不能以 false 冒充未命中。
- 基础 view projection 提供题名、摘要、证据等级、来源定位和命中依据；最终 Widget 由集成任务实现。

## 5. 测试设计

- 目录 contract test：64 条、唯一性、证据、引用、predicate 可编译、无关系环。
- 64 条数据驱动正例与反例；fixture 明确标记外部古例或独立手算来源。
- 组合测试：多命中、互斥、implies、稳定排序、缺事实和旧版本。
- 变异敏感性：对关键 fact 做单点变化，至少能让对应正例失配，防止恒真规则。

## 6. 回滚

目录、生成代码、模型和 evaluator 在同一提交内保持同步。某条证据被撤销时将其标记禁用并提升目录版本；不复用原 ruleId 表达新语义。

