# 执行计划：六爻裁决层

前置：`task.py start` 之后才开始动代码。当前工作区有 11 个未提交路径（神煞服务等前序工作），
本任务不触碰这些文件；若需提交，先由用户处理前序变更。

## 步骤清单

### 1. 模型层
- [x] `analysis_report.dart` 新增 `VerdictTrend` / `VerdictFactor` / `VerdictCondition` / `VerdictJudgment`（freezed），`AnalysisReport` 加可空 `judgment` 字段
- [x] 运行 `dart run build_runner build --delete-conflicting-outputs`
- 验证：`flutter analyze` 无新告警

### 2. VerdictService（核心）
- [x] 新建 `verdict_service.dart`：Step1 受力归集 → Step2 悬置转条件 → Step3 元忌修正 → Step4 决策表（严格按 design.md 表实现，行序即优先级）
- [x] summary 文案生成
- [x] 单测 `verdict_service_test.dart`：决策表每行 ≥1 正例 + 1 反例；悬置状态每种 ≥1 例锁定"产条件不判凶"；伏神取用 1 例
- 验证：`flutter test test/unit/services/liuyao/analysis/`

### 3. Analyzer 接线
- [x] `liuyao_analyzer.dart`：删除 `_buildVerdict`，改调 `VerdictService.judge()`；`verdictSummary = judgment.summary`
- [x] 回归测试：未选用神时报告与改动前一致（补 1 例快照式断言）
- 验证：`flutter test test/unit/services/liuyao/`

### 4. 黄金断例
- [x] `verdict_golden_test.dart` + 夹具扩展（复用 `analysis_fixtures.dart`），≥8 例（清单见 design.md §6），每例注明依据章节
- [ ] **review gate：夹具期望值请用户领域复核**（正确性以用户裁定为准，引擎与夹具不一致时先怀疑夹具）
- 验证：`flutter test`

### 5. UI 最小接入
- [x] 结果页总览卡：趋势徽标（沿用 antique 组件极性配色）+ 条件集列表；`verdictSummary` 展示位不变
- [x] Widget 测试补充趋势/条件渲染断言
- 验证：`flutter test`；模拟器已由用户预开，直接 `flutter run` 人工确认总览卡

### 6. 收尾
- [x] `flutter analyze` + `flutter test` 全量
- [x] spec 更新：`liuyao-analysis-engine.md` 口径表补"裁决层"节（决策表、力量层级、悬置转条件约定）
- [x] Conventional Commit（feat(liuyao)），不夹带前序未提交文件

## 回滚点
- 每步一个逻辑提交粒度；任一步失败回退该步文件即可
- 全量回滚：Analyzer 调用点还原 `_buildVerdict`，删除新文件，模型字段可空无迁移

## 风险
- 断例期望值依赖对《增删卜易》的转述，可能有误 → 已设 review gate（步骤 4）
- term 字符串匹配漂移 → 单测用真实服务产出的标签驱动，不手写 term 常量副本
