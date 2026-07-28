# 设计：毕法赋百法规则引擎

## 1. 模型

```text
BiFaReport
  catalogVersion
  sourcePanVersion
  compatibilityStatus
  matches: DlrRuleHit<BiFaResult>[]
  conflicts: DlrRuleConflict[]
  missingFacts: FactKey[]
```

`BiFaResult` 只保存规则身份、结构化命中依据、组合标签和短摘要。来源元数据由 rule catalog 提供，避免报告复制古文。

## 2. 条件目录

- 规范源位于 `assets/data/daliuren/classics/bifa.json`。
- 每法 ordinal 固定为 1-100，ruleId 使用 `dlr.bifa.<stable-name>`；不可把序号单独当长期 ID。
- predicate 复用课经的 closed AST 和 `DaLiuRenFactSet`，可扩展的 fact 类型必须先进入共享 schema。
- 组合元数据包括 `requires`、`supports`、`excludes`、`overrides` 和 `priority`；生成器检查悬空引用和有向循环。
- 对原文语义无法可靠形式化的条目，先保持 `notExecutable` 并阻塞 100 法完成，不能写宽泛恒真条件。

## 3. 评估与冲突

1. 一次评估全部 100 法，保留每个原子条件的读取 trace。
2. 缺关键事实返回 unsupported，不等价于 false。
3. 对命中集应用显式 requires/supports/excludes/overrides 图。
4. 被覆盖规则仍保留为 suppressed match，并记录采用哪条规则及依据。
5. 以 `priority -> ordinal -> ruleId` 稳定输出。

百法服务不依赖现有中文 tag 或 `VerdictTrend`，也不执行 AI 生成的解释。

## 4. 与其他模块关系

- 基础 fact set 来自排盘、神煞、三传、课经等前置服务，毕法不回写这些事实。
- 课经与毕法分别产报告；若底本说明跨目录关系，由传统断课服务组合，不在任一目录内硬编码另一模块展示词。
- formatter 可以输出原始 rule hits；UI 详情和最终裁决使用统一 projection。

## 5. 兼容与测试

- 旧盘缺新 fact 时明确列出 missingFacts；只有足够事实时才评估。
- 100 条正/反 fixture 与生产算法独立；至少选取若干外部完整盘验证多法共现。
- mutation 测试或等价单点事实变更证明每法 predicate 非恒真、非恒假。
- 目录版本变化不复用 ID 表达不同语义，废弃关系写入 `deprecatedBy`。

## 6. 回滚

目录和生成器可以独立回滚；单法证据撤回时禁用条目并升级版本，不删除历史 sourceRef。若冲突图有问题，可暂时只显示未裁决命中，但不得回到 first-match 丢规则。

