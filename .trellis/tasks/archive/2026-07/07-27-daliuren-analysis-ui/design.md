# 设计：大六壬可视化分析与AI接入

## 1. 结果页装配（`daliuren_result_screen.dart`）

build 内一次派生：`final report = DaLiuRenAnalyzer.analyze(result);`（纯函数、廉价，无需 controller/缓存）。sections 顺序调整为：

```
ExtendedInfoSection
DaLiuRenPanParamsSection
DaLiuRenKeGeCard(report)              ← 新增
上/下（四课、三传，三传 section 注入 report 徽标与点击回调）
DaLiuRenPanDiskEntrySection           ← 新增（按钮开圆盘图对话框）
DaLiuRenTianPanSection
DaLiuRenShenJiangSection
DaLiuRenShenShaSection
YingQiCard(report.yingQi)             ← 新增（共享组件）
```

## 2. 新组件（`lib/divination_systems/daliuren/ui/widgets/`）

### 2.1 DaLiuRenKeGeCard

AntiqueCard，标题"课体断诀"。内容自上而下：

- 首行：`{geName}`大字 + `{keTypeName}课`小字 + polarity 徽标（吉=zhusha 系、凶=qinghui/墨系、中性=huise，对齐六爻标签配色习惯，具体色值参考六爻结果页标签徽标实现）。
- 基调一句（keGe.reason）。
- 干支主客标签行：ganZhiTags 以小徽标 Wrap 展示（term + polarity 色）。
- 分隔线后 verdictSummary 文案。
- conditions 非空时："未决条件" chips（label，hasRescue=false 时加"无解"标记）。
- 底部 `ExpansionTile`（antique 风格）"推理链"：factors 逐条 `rule｜reason｜source`，effect 用 扶/抑/悬/中 前缀。
- judgment 为 null 时只展示格名+基调+干支主客行。

### 2.2 三传徽标与详析弹层

- `DaLiuRenSanChuanSection` 增加可选参数 `report` 与行点击：每传行尾 Wrap 展示 `report.topTagsForChuan(position, count: 2)` 徽标（term，polarity 色）；无 report 时行为不变（向后兼容其他调用点）。
- `DlrChuanDetailSheet`：showModalBottomSheet（antique 风格，参考六爻 `yao_detail_sheet.dart` 的分组样式），标题"{初/中/末}传 {支}（{六亲}·乘{天将}）"，正文按 DlrTagCategory 分组列出该传全部标签（term + reason）；另附课局级标签（juTags）区块"课局"。
- a11y：徽标与弹层条目加 Semantics 标签（对齐六爻实现习惯）。

### 2.3 YingQiCard 提升共享

- 移动 `lib/divination_systems/liuyao/ui/widgets/ying_qi_card.dart` → `lib/presentation/widgets/ying_qi_card.dart`；import 改指共享 `verdict_models.dart`（或经由原 export 路径，取直接共享路径）。
- 原路径文件改为 `export '../../../../presentation/widgets/ying_qi_card.dart';`，六爻消费方零改动。
- 大六壬使用：`YingQiCard(candidates: report.yingQi ?? const [])`；`onViewCalendar` 传 null（应期日历接入大六壬为后续任务，不在本任务）。

### 2.4 天地盘圆盘图

- `DaLiuRenPanDiskDialog` + `_PanDiskPainter extends CustomPainter`：
  - 三同心环、十二等分（子在正下方、顺时针丑寅…，即传统盘式；每宫 30°）。
  - 内环：地盘十二支（固定），日支宫与日干寄宫底色高亮（不同色、图例说明）。
  - 中环：天盘十二支（按 result.tianPan 映射），三传之支文字加重＋描边高亮（初/中/末 分别标注小字）。
  - 外环：十二天将名（取 result.shenJiangConfig 每宫乘将），吉将/凶将用色区分（集合与分析层一致：吉＝贵人六合青龙太常太阴天后）。
  - 弦线：初传宫→中传宫→末传宫两段带箭头弧线（danjin 色）。
  - 尺寸自适应 Dialog 宽度，文字用 antique 文本样式；配底部图例行。
- 入口：`DaLiuRenPanDiskEntrySection`——AntiqueCard 内 OutlinedButton.icon "天地盘圆盘图"，onPressed showDialog。
- Painter 逻辑保持纯绘制：宫位角度换算等工具函数放同文件顶层，便于单测（角度换算函数可单独 unit test）。

## 3. AI formatter（`lib/ai/output/formatters/daliuren_formatter.dart`）

- 先读 `liuyao_formatter.dart` 的 analysis section 实现风格（客观规则分析、分级列出、不下断语的措辞约定）。
- format 时调 `DaLiuRenAnalyzer.analyze(result)`，新增 section `analysis`（排在现有 sections 之后）：
  - 课格：`课体{keTypeName}，格局{geName}（{polarity}）：{reason}`
  - 干支主客：逐条 `term：reason`
  - 三传：按 初/中/末 逐传列标签 `term（reason）`；课局标签单独小节
  - 裁决：verdictSummary + 未决条件逐条
  - 应期：candidates 逐条 `label：reason`
- coreData 增补：`keGeName`、`verdictTrend`（judgment?.trend.name）。
- 保持既有 sections/coreData 字段不删不改（模板兼容）。

## 4. 测试

- Widget（`test/widget/daliuren/`，参考既有 widget 测试组织方式；如该目录不存在则按项目现有 widget 测试路径约定放置）：
  - KeGeCard：给定构造 report，断言格名、polarity 徽标、条件 chip、推理链展开后 factor 文案。
  - 三传徽标：注入 report 后传行出现 top 标签；点击弹层出现分类分组与课局区块。
  - YingQiCard 共享：大六壬结果页 pump 后出现"应期推算"标题；六爻侧原 widget 测试零改动通过。
  - 圆盘图：点击入口出现 Dialog；painter 角度换算函数 unit test（子宫在正下方、每宫 30°、天盘映射正确）。
- Formatter 单测：黄金例 K（戊子日元首）构造 result，断言 analysis section 含"元首""断曰"与应期条目；coreData 含 keGeName。
- 全量 `flutter test` + `flutter analyze`。
