# 大六壬可视化分析与AI接入

## Goal

把分析引擎（DaLiuRenAnalysisReport）呈现到结果页（对齐六爻"标签徽标→详析弹层→裁决卡→应期卡"的成熟模式），补大六壬特有的天地盘圆盘可视化，并让 AI 解卦拿到结构化分析结论。

## Requirements

- R1 结果页接入 `DaLiuRenAnalyzer.analyze(result)`（build 时派生，纯函数，无控制器/无状态管理新增）。
- R2 课格断诀卡：格名+课体+基调（polarity 配色）+ verdictSummary + 未决条件 chips + 可展开的推理链（factors）+ 干支主客标签行。
- R3 三传区行内标签徽标（每传 top 2~3，按 priority）；点传行弹出详析弹层（该传全部标签按分类展示）。
- R4 应期卡：`YingQiCard` 从六爻 ui/widgets 提升为共享组件（`lib/presentation/widgets/`），六爻原路径 export 转发零改动；大六壬直接复用。
- R5 天地盘圆盘图：CustomPainter 三环（内地盘/中天盘/外天将），高亮三传之支与日干寄宫、日支宫，三传 初→中→末 弦线箭头；入口按钮开对话框展示。
- R6 AI 接入：`daliuren_formatter.dart` 新增 analysis section（课格/干支主客/传级标签/课局标签/裁决摘要与条件/应期），风格对齐 `liuyao_formatter.dart` 的 analysis section。
- R7 Widget 测试（课格卡渲染、传行徽标与弹层、应期卡复用、圆盘图冒烟）与 formatter 单测。

## Constraints

- UI 全部使用 antique 组件与既有色 token；交互与文案风格对齐六爻结果页。
- 不改分析层/排盘层逻辑；发现规则问题上报不自修。
- 不改六爻结果页行为（YingQiCard 提升后六爻侧仅 import 转发，零视觉/行为变化）。
- 分析数据不落库；AI formatter 只读报告。
- 不动工作区 3 个六爻遗留未提交改动。

## Acceptance Criteria

- [ ] 大六壬结果页出现：课格断诀卡、三传徽标+详析弹层、应期卡、圆盘图入口，antique 风格一致。
- [ ] 六爻全量测试（含 golden/widget）零回归。
- [ ] daliuren formatter 输出含 analysis section，单测锁定关键字段。
- [ ] `flutter analyze` 零告警；`flutter test` 全量通过。
