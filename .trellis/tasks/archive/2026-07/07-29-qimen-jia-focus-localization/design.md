# 奇门甲日分析兼容与界面中文化设计

## 1. 根因与目标数据流

当前失败链：

```text
schema 1 dayGanZhi=甲*
  -> QimenFocusResolver 固定拒绝 self
  -> diagnostics 非空 / D00
  -> QimenResultScreen 设置 unavailableReason
  -> AIAnalysisWidget 禁止调用
```

修复后的 current/v2 链：

```text
dayGanZhi
  -> 六十甲子索引 -> 日旬首 -> 冻结旬首遁仪
  -> 天盘干唯一 occurrence（中五时读取显式寄宫）
  -> self + matter 主焦点
  -> facts / conflicts / verdict / yingQi
  -> formatter -> AIAnalysisService
```

排盘结果、仓储 JSON 和数据库不变；分析仍在结果渲染与 formatter 使用时派生。

## 2. 规则版本

`QimenRuleCatalog` 增加 `v2`，`current=v2`，released 同时保留 v1/v2。两版本共享
既有规则定义集合，因为本任务不改事实目录、冲突、裁决和应期；版本差异只由
`QimenFocusResolver.resolve(result, ruleSetVersion:)` 明确分派。

- v1：保留 `QMV1-E-DAY-JIA-FOCUS-UNRESOLVED`。
- v2：甲日按日柱索引所在十项旬的首项求旬首，再以
  `QimenConstants.xunHiddenStem` 求遁仪并调用既有 `_addStemFocus`。
- 非甲日：两版本走完全相同的日干定位。
- `QimenAnalyzer` 必须把已解析的规则版本传给 focus resolver；各事实 service 继续接收
  resolved version，报告和投影标记 v2。

日旬首/遁仪只是由已持久化日柱得到的确定性中间值，不写回 pan schema。trace 的
input refs 引用日柱和最终命中的天盘/寄宫字段，保持 graph validator 可解析。

## 3. 中文展示投影

新增单一 presentation helper，集中提供：

- `roleId -> 中文焦点名`，覆盖所有八类问事角色；
- `ruleId -> QimenRuleCatalog.rule(id).displayTerm`；
- `sourceId -> QimenSourceRef.title`；
- trace stage/status、冲突 policy、应期 trigger、分析状态与诊断的中文标签；
- occurrence ID 通过当前 projection 的 facts 映射为规则中文名，未知值显示“未识别事实”；
- 规则集显示“时家转盘奇门 v1/v2”。

helper 只做展示映射，不参与事实筛选或裁决。`QimenResultSections` 与
`QimenPalaceDetailSheet` 统一调用它，禁止各自维护重复 switch。wire codec、report、
projection 和 formatter 中的稳定 ID 不改。

诊断主面板显示中文原因与字段语义；代码/JSON path 如需保留，只放进折叠的技术详情。
正常 v2 甲日没有诊断，因此用户主流程不再看到兼容卡片。

## 4. AI 验证

三层验证防止“只隐藏报错”：

1. analyzer：v2 甲日 report 完整、diagnostics 为空、self/matter 唯一；
2. formatter：对同一结果生成 v2 结构化分析，不抛异常；
3. widget：配置 fake provider/service，点击“开始分析”，断言 service 收到该
   `QimenResult` 且响应内容出现在页面。

显式 v1 甲日和真实无效 pan 继续提供 `unavailableReason`，证明门禁未被整体关闭。

## 5. 兼容与回滚

- 不迁移历史数据；历史结果默认 current 时获得 v2 修复，显式 v1 仍可复算旧报告。
- 不修改 v1 fixture。新增独立 v2 六旬矩阵和 UI/formatter regression。
- 若 v2 甲日焦点无法满足 graph validator，回滚 v2 注册与 resolver 分派即可；v1 路径
  始终保留。
- 共享工作区已有大量大六壬及用户资源改动，所有 staging、diff、格式与测试命令必须
  使用奇门显式路径白名单；必要时在隔离 worktree 验证全量测试。
