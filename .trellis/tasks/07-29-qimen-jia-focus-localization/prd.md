# 奇门甲日分析兼容与界面中文化

## Goal

修复合法甲日奇门盘被错误留在“焦点不完整”兼容状态的问题，使当前规则能够从
已持久化的日柱确定性定位自身焦点、生成完整程序分析并正常发起 AI 解读；同时把
结果页、宫位详情和审计展开区泄漏的内部英文 ID 全部替换为面向用户的中文术语。

## Background

- 用户实机截图显示主焦点只有 `matter`、`generalDutyStar`、
  `generalDutyDoor`，没有 `self`，且 AI 显示“奇门分析未通过兼容校验”。
- `QimenFocusResolver` 在日干为甲时固定产生
  `QMV1-E-DAY-JIA-FOCUS-UNRESOLVED`；这正是截图数据形态的唯一合法来源。
- schema 1 已持久化完整 `dayGanZhi`。其六十甲子旬首及遁仪可以由
  `TianGanDiZhiService.liuShiJiaZi` 与 `QimenConstants.xunHiddenStem`
  确定性推导，不需要借用时旬遁仪，也不需要修改排盘或数据库 schema。
- 发布合同规定 `8138c6e` 后焦点语义变化必须新增规则版本，因此不得覆盖 v1。
- 当前 UI 直接展示 `roleId`、`ruleId`、`sourceId`、`policyId`、occurrence ID、
  trace stage/status、应期 trigger kind 和规则集内部 ID；截图中的英文来自这些字段，
  不是 AI 输出。

## Requirements

### R1 甲日焦点与版本兼容

- 新增并发布 `qimen-shijia-zhuanpan-analysis/v2`，把 `current` 切换到 v2；
  `v1` 必须仍可显式选择并保持甲日返回原兼容诊断。
- v2 遇到甲日时，从完整 `dayGanZhi` 的六十甲子索引确定日旬首，再查冻结旬首遁仪
  定位 `self`；不得借用结果中的时旬 `xunHiddenStem`，不得调用排盘阶段 service。
- 推导证据必须引用持久化的 `$.temporalContext.dayGanZhi`，中五寄宫仍只读取
  显式 `hostedHeavenStem`；非甲日焦点结果与 v1 保持一致。
- 合法甲日盘在 current/v2 下必须为完整投影、无兼容诊断、同时具有唯一 `self` 和
  `matter` 主焦点；损坏盘、未知 schema 和真正无法定位的焦点仍必须禁用 AI。

### R2 AI 完整可用

- 结果页 current/v2 对合法甲日盘不得设置 `aiAnalysisUnavailableReason`。
- Qimen formatter 必须能对该盘生成包含完整盘面、程序事实、裁决和应期的结构化输入，
  不得由 AI 重排或补算自身焦点。
- widget 集成测试必须通过已配置的 fake AI service 从“开始分析”走到响应内容显示，
  证明不是只隐藏错误提示或只把按钮放开。
- AI 服务未配置、formatter 缺失、真实损坏盘或显式 v1 甲日盘仍使用受控不可用状态。

### R3 用户界面完整中文化

- 结果页及九宫详情不得直接展示焦点 role、规则、来源、冲突策略、事实 occurrence、
  trace stage/status、裁决行、应期尺度/触发类型或目标焦点的内部稳定 ID。
- 规则名称必须从 `QimenRuleCatalog.displayTerm` 取得，来源显示已有中文标题；焦点角色、
  trace 状态、冲突策略和应期触发类型使用集中式穷尽中文映射，禁止散落字符串替换。
- 未知 ID 必须有稳定中文兜底，不得重新原样泄漏英文；数据层 wire ID 和 AI 结构化
  审计字段保持不变。
- 分析版本面向用户显示为“时家转盘奇门 v2”；兼容诊断显示中文原因，技术编号仅允许
  收纳在明确的“技术详情”区域，不得作为主文案。

### R4 回归与交付边界

- v1 黄金 fixture 和显式 v1 快照不得改写；v2 只新增聚焦版本回归。
- 需要覆盖甲子、甲戌、甲申、甲午、甲辰、甲寅六旬的自身遁仪定位，以及寄中五时的
  原宫/作用宫证据。
- 奇门分析、formatter、结果页、全部奇门目标、静态分析和可执行范围内的全量测试通过。
- 只暂存和提交本任务奇门文件；现有大六壬、README、资源和 `tmp/` 改动保持原状。

## Acceptance Criteria

- [x] A1：`resolve('current')` 返回 v2，`resolve('v1')` 与 v1 甲日诊断行为保持不变，
  `resolve('v2')` 可用且 released catalog 不可变。
- [x] A2：六个甲旬在 v2 中均产生唯一 `self` 与 `matter`，日旬遁仪和宫位符合冻结映射，
  证据只引用持久化日柱/宫位字段。
- [x] A3：用户截图同型的合法甲日盘在结果页不再出现兼容错误，AI 控件可用；fake AI
  端到端调用成功并显示响应。
- [x] A4：显式 v1 甲日、损坏盘和未来 schema 仍显示受控诊断并禁止 AI。
- [x] A5：结果页、完整审计展开区和九宫详情测试断言不出现已知英文内部 ID，且中文规则、
  焦点、来源、冲突、trace、裁决和应期术语可见。
- [x] A6：formatter 对 v2 甲日生成完整结构化程序分析，仍明确“程序唯一计算方”策略。
- [x] A7：相关 spec 更新为 v1/v2 双版本合同；目标测试、全部奇门测试、
  `flutter analyze --no-pub`、格式与 `git diff --check` 通过。
- [x] A8：提交白名单不包含任何大六壬、用户资源、README 或 `tmp/` 路径。

## Acceptance Evidence

- 2026-07-29 聚焦 catalog/focus/analyzer/formatter/result 测试 55 项通过；独立
  `trellis-check` 扩大验证 296 项奇门相关测试通过。
- 排除共享资源断言后的完整奇门目标 223 项通过；单独运行
  `qimen_asset_test.dart` 时，1 项渲染测试通过，1 项仅因用户已修改的
  `qimen_background.png` 宽度为 576、旧断言要求 1024 而失败。本任务未修改图片或断言。
- `flutter analyze --no-pub` 无问题；12 个任务 Dart 文件格式检查与
  `git diff --check` 通过；任务 JSONL validate 通过。
- fake provider 端到端断言已收到 `qimen-shijia-zhuanpan-analysis/v2` 与
  `焦点 self：戊落4宫` prompt，并在结果页渲染返回内容。

## Out Of Scope

- 修改排盘 `QimenResult` schema、数据库或历史记录。
- 放宽损坏盘/未知 schema 的 AI 门禁，或让 AI 自行补算焦点。
- 改动 v1 黄金 fixture、v1 规则谓词、冲突、裁决或应期结果。
- 清理或提交共享工作区中的大六壬、README、资源或 `tmp/` 改动。

## Constraints

- v2 的甲日推导是规则语义变化，必须前向发布新版本；不得把它包装成 v1 非语义修复。
- UI 中文化只能消费 typed projection 与权威 catalog，不得从中文说明文案反推业务规则。
- AI 可用验收必须证明真实调用链到达 fake service 响应，不接受仅断言按钮存在。
