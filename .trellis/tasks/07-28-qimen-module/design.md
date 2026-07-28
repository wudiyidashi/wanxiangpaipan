# 奇门遁甲板块总体设计

## 1. 交付边界

父任务负责跨层合同、子任务顺序与最终集成验收，不直接修改产品代码。实现拆为三个串行子任务：

```text
qimen-pan-engine
  -> qimen-analysis-engine
    -> qimen-product-integration
      -> parent integration review
```

排盘模型是后两项的输入合同。任何模型或规则口径变更必须先回到排盘子任务文档，并重新运行其黄金盘。

## 2. 总体数据流

```text
Cast input
  -> QimenTimeService.normalize
  -> QimenJuService.resolve(strategy)
  -> staged pan services
  -> QimenResult (persisted fact)
  -> QimenAnalyzer.analyze (derived report)
  -> QimenResultScreen / QimenStructuredFormatter
```

历史读取经 `systemType=qimen -> QimenSystem.resultFromJson()` 还原相同 `QimenResult`，再重新派生分析报告。分析规则升级可以改善旧记录，不得改变旧记录保存的盘面事实。

## 3. 跨层合同

- `DivinationType.qiMen('奇门遁甲', 'qimen')` 是唯一外部系统标识。
- 复用 `CastMethod.time` 与 `CastMethod.manual`；输入 schema 由 `(qimen, method)` 定义。
- `QimenPanParams` 保存定局法、时间基准、换日、寄宫、暗干与问事类型的稳定 enum ID。
- `QimenTemporalContext` 保存原始/标准/实际排盘时间、offset、经度、校正值、四柱和精确节气。
- `QimenJuInfo` 保存定局法、阴阳遁、局数、三元、符头、超神/接气和置闰信息。
- `QimenPalace` 是九宫唯一事实模型；UI、分析与 formatter 都消费它，不各自解析 Map。
- `QimenResult` 保存参数、时间上下文、定局、九宫、值符值使、旬空、驿马和推导轨迹，摘要格式为“阴/阳遁N局 · X值符 / X门值使”。

完整字段与输入 schema 由排盘子任务 `design.md` 锁定。

## 4. 算法边界

- 历法：复用 `lunar` 的精确节气与 Exact/Exact2 日柱能力；00:00 换日时重算时干。
- 真太阳时：版本化 NOAA 方程时近似 + 经度差校正；保存校正分钟和版本。
- 定局：策略接口下实现拆补、茅山、置闰与手动覆盖，公共局数表只有一个数据源。
- 排盘：按时间、定局、地盘、旬首/值符值使、天盘九星、八门、八神、暗干、空亡驿马/标记的固定顺序执行。
- 所有阶段为无副作用纯静态服务；编排器不得混入 UI 或仓储逻辑。
- 具体公式、分歧口径和黄金政策以 `research/qimen-rule-baseline.md` 为准。

## 5. 分析边界

分析沿用现有大六壬模式：

```text
QimenResult
  -> palace/global fact services
  -> question focus resolver
  -> ordered verdict table (first match)
  -> ying-qi candidates
  -> QimenAnalysisReport
```

- 事实标签包含名称、分类、极性、优先级、理由、来源与关联宫位。
- 传统确定性较低的事项裁决明确标注“本项目约定（奇门分析 v1）”。
- 不持久化 report，不用加权分数，不让 AI 替代规则事实。

## 6. UI 与交互

- 起局页把常用输入置顶，高级口径折叠；真太阳时只有在对应模式下显示经度输入。
- 九宫盘固定洛书 3x3 和稳定纵横比；单宫显示摘要，点击进入详情 sheet，避免在小格中堆满解释文字。
- 结果页顺序：时间/口径摘要 → 九宫盘 → 值符值使与关键标记 → 裁决总览 → 格局/宫位事实 → 应期 → AI。
- 首页、历史、数据管理与 AI 均通过现有注册/通用骨架接入，不另建平行导航或数据库。

## 7. 兼容与发布

- 通用 Drift JSON 记录无需迁移；新增 enum 后必须补齐全部穷举 switch。
- `resultFromJson` 对当前 schema 严格校验；结果内保存 `schemaVersion=1`，为未来兼容预留。
- 旧术数数据和 UI 不修改业务行为。
- 产品集成子任务完成前不注册启用奇门，避免历史记录无法重开或 AI formatter 缺失。

## 8. 回滚

- 每个子任务独立提交并通过全量测试后再进入下一项。
- 排盘子任务失败时不进入分析；分析失败时不进入产品注册。
- 产品集成出现问题可整体撤销注册/UI/AI 子任务，排盘和分析纯 Dart 模块仍不影响现有系统。

