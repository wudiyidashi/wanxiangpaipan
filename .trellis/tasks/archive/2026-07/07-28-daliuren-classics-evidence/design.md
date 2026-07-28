# 设计：大六壬古籍证据注册表

## 1. 目录结构

```text
assets/data/daliuren/classics/
  schema/
    source.schema.json
    rule.schema.json
    case.schema.json
  sources.json
  rules/
    pan.json
    shenjiang.json
    jiuzongmen.json
    derived-facts.json
    shensha.json
    kejing.json
    bifa.json
    nianming.json
    class-spirit.json
    judgment.json
    timing.json
  cases/
    duanan.json
    cunyan.json
  variants.json
tool/daliuren_classics/
  validate.dart
docs/research/daliuren/
  evidence-coverage.md
```

最终文件名以实现时统一拼写为准；一旦下游引用，不能无迁移改名。扫描件不在此目录。

## 2. Source 与页码

`ClassicSource` 至少包含：

- `sourceId`、题名、作者/编者、版本/丛书、馆藏和稳定 identifier。
- 卷册、远端文件名、访问日期、版权/使用说明。
- `paginationScheme`：PDF 页、scan leaf、书叶/版心页如何对应。
- `usage`：主底本、断课主依据、外例或补缺。
- `verificationStatus`：candidate / scanVerified / approved。

规则引用使用 `SourceLocus(sourceId, volume, scanLeaf, printedLeaf, pdfPage, imageLabel)`；至少一个稳定影印定位字段必填。OCR 文件和固定转录作为 secondary locator 单独引用，不和影印 locus 混为一个 source。

## 3. Rule Entry

`ClassicRuleEntry` 包含：

- `ruleId`、`family`、`ordinal`、传统名、采用状态。
- `sourceRefs[]`、必要短引、逐字核验者/日期。
- `interpretation`、`conditionsSummary`、`prioritySummary`。
- `evidenceLevel`、`variantGroupId`、`adoptedVariantId`。
- `fixtureIds[]`、`targetCapabilityId`、备注。
- `locatorOnly` 和 `executableApproved` 两个独立状态。

证据库不在此阶段表达任意可执行 predicate；它冻结语义和出处。后续规则任务在批准条目上增加 typed condition，并保持同一 ruleId。

## 4. Variant 与采用决策

每个 `VariantDecision` 记录差异会影响的盘面/结论、各版本 locus、默认采用理由、是否值得配置及不采用版本的展示策略。若差异证据不足，状态为 unresolved，并阻塞对应确定性规则。

只有同时满足以下条件才可标 configurable：至少两个 A/B 级口径、结果有实质差异、用户能理解选项、全分支可测试。其余异文只登记。

## 5. 外部课例

`ClassicCaseFixture` 分开保存：

- source locus 和原文上下文；
- 原始输入事实及可信等级；
- 独立复盘得到的 expected facts；
- 原书断语/结果只作为对照，不转成预测软件真实性验收；
- unresolvedFields 和 adoptedAssumptions；
- 覆盖 capability/rule IDs。

任何 expected 字段不得由 app service 或规则 registry 动态生成。缺时间、时区、性别等信息时保留 unknown，并限制该课例可验证的层级。

《断案》《存验》若只有固定转录或版本暂缺的网页，只登记 C/locator-only 候选。B 级完整课例可由已固定馆藏和页码体系的《指南》补足，但必须保留原书优先检索失败的记录，且不能借单张课例提升整套算法证据等级。

## 6. 校验器

`validate.dart` 使用 `dart:convert` 读取结构化 JSON，并实施：

- JSON shape、枚举、必填字段和相对路径校验；
- source/rule/case/variant 引用完整性；
- ruleId/ordinal 唯一及 family 数量约束；
- `kejing=64`、`bifa=100`；
- executableApproved 规则至少一个 fixture、至少一个影印 sourceRef、证据 A/B；
- locatorOnly 不能提升为 A/B；
- 短引长度上限和扫描文件禁止入库提示；
- 覆盖报告生成。

校验器只验证证据契约，不判断古文解释是否正确；解释必须由页级人工复核和交叉底本审校。

## 7. 研究流程

1. 用 OCR/转录搜索候选词。
2. 打开对应影印页，记录页码体系和短引。
3. 由第二次独立查看复核 locus、抄录和解释。
4. 登记异文并应用父任务底本优先级。
5. 录入 case fixture 和能力覆盖。
6. 运行 validator；未通过的条目不能交给实现子任务。

## 8. 回滚

证据目录按 rule family 独立文件，单个来源或解释争议可局部回滚。已发布 ruleId 不删除；撤销时设为 disabled/deprecated 并记录原因，避免历史报告失去引用。
