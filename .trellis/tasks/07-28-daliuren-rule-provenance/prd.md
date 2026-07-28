# 大六壬规则来源与版本契约

## Goal

在不改变当前排盘数值与分析结论的前提下，为后续 C02-C16 建立稳定的规则身份、证据等级、盘面/分析版本和可重放输入快照契约，使中文展示词、算法升级与历史盘事实彼此解耦。

## Dependency

- 硬前置：C00 `07-28-daliuren-classics-evidence` 必须完成校验并归档。
- 本任务只消费 C00 的稳定 `ruleId`、source ID、证据等级和 catalog version；不得在代码中另造同义 ID。
- 依赖未归档时不得开始产品实现。

## Requirements

- 新增大六壬专属 typed 规则引用，至少包含 `ruleId`、`ruleSetVersion`、规则种类、证据等级和 source IDs；展示词不得参与相等性、分支或持久化身份。
- 建立集中版本常量：当前盘面规则集、当前分析规则集、C00 证据目录和 `legacyUnknown`。版本字符串发布后不可原地改义；行为变化必须升版本。
- 为现有 `DlrAnalysisTag` 和课格信息分配稳定 rule ID，并由所有生产者显式提供；修改 `term/reason` 不得改变身份。
- 为 `DaLiuRenResult` 增加向后兼容字段：`panRuleSetVersion`、`evidenceCatalogVersion`、`castInputSnapshot`、`recastFromId`。旧 JSON 缺字段时必须读成版本未知且 snapshot 为空，禁止默认成当前版本。
- `castInputSnapshot` 保存四种起课方式的规范化输入、实际使用的时刻/UTC offset、参数、已解析的随机/报数时支及无法精确重放的原因；不得保存问题正文或从结果盘反推输入。
- 新盘必须写当前版本和 snapshot。手动四柱使用自动月将但没有对应 civil time 等已知不足，应保留输入并标记不可精确重放，不得伪装 complete。
- `DaLiuRenAnalysisReport` 增加 `analysisRuleSetVersion`、`sourcePanRuleSetVersion`、`compatibilityStatus`；分析器解释旧盘时必须保留版本未知/不兼容状态。
- 共享六爻模型不得因大六壬元数据产生行为或序列化回归。大六壬专属类型不下沉到 shared，除非存在已验证的跨系统语义。
- 所有字段 additive；本任务不删除旧 JSON 键、不迁移数据库、不修改月将、天将、三传、神煞或裁决算法。

## Acceptance Criteria

- [x] typed 规则引用拒绝非法 `ruleId`、空版本和不合法的古籍证据组合。
- [x] 每个现有大六壬分析标签与课格生产分支都有稳定 rule ID；同一规则仅改中文词后 ID 不变。
- [x] 新 `DaLiuRenResult` JSON round-trip 保留版本、snapshot 与 `recastFromId`；旧 JSON fixture 无需迁移即可读取并明确为 `legacyUnknown`。
- [x] 时间、报数、电脑随机、手动四柱四种起课均保存规范化 snapshot；实际随机/报数时支可回读，缺失条件列入 `missingFields`。
- [x] 新盘写当前版本；旧盘、当前盘和未知未来版本分别得到确定的 analysis compatibility 状态。
- [x] 分析报告声明自身版本和来源盘版本，且不把 legacy 盘静默标成 current。
- [x] C00 中的 C/D 规则不能由 runtime ref 冒充 A/B；project heuristic 与 classic rule 可机器区分。
- [x] Freezed/JSON 生成物同步，定向测试、共享分析模型回归、`flutter analyze` 与全量 `flutter test` 通过。

## Out Of Scope

- 不在本任务实现历史列表警示、重排按钮或关联保存流程；这些属于 C15/C16。
- 不在本任务修正月将交节、天将坐标、神煞或分析裁决；只为后续变化建立版本边界。
- 不把完整 C00 原文/短引复制进每张结果；运行时只保存稳定引用与 catalog version。
