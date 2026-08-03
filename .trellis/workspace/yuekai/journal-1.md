# Journal - yuekai (Part 1)

> AI development session journal
> Started: 2026-07-22

---



## Session 1: 六爻断卦分析引擎与三层展示（含应期日历联动）

**Date**: 2026-07-22
**Task**: 六爻断卦分析引擎与三层展示（含应期日历联动）
**Branch**: `main`

### Summary

实现六爻断卦分析层：11 个纯函数服务+LiuYaoAnalyzer（规则以增删卜易为基准，刑害按卜筮正宗低权重补充），覆盖旺衰/空亡/墓绝/合冲刑害/动变/生克/六亲/伏神/特殊作用/卦变/应期约 80 概念。用神由用户结果页自由点选（含伏神取用/用神两现），LiuYaoResult 增可空 yongShenPosition 持久化，AnalysisReport 派生不落库。UI 三层递进：总览卡/爻行徽标+详析 Sheet/术语词典 80 条。应期日历：CalendarGuaContext 经 /calendar 路由传入，月视图应冲合空角标+与本卦区块，无上下文时与原版一致。AI 提示词注入引擎判定段。顺带落库前会话遗留的六合卦表修正。新增 160 测试全量 645 绿，trellis-check 通过，模拟器实机冒烟通过。规范沉淀至 .trellis/spec/domain/liuyao-analysis-engine.md

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `489c3a1` | (see git log) |
| `a5e381f` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 2: 六爻生克关系连线图弹窗

**Date**: 2026-07-22
**Task**: 六爻生克关系连线图弹窗
**Branch**: `main`

### Summary

以弹窗简化示意图实现生克关系可视化（上一任务排除项）：buildRelationEdges 纯函数从 AnalysisReport 提取边（生克扶有向/合冲刑害墓无向归一去重/日月边），CustomPainter 固定坐标绘制（六爻纵列+月建日辰节点，生扶绿实线/克冲朱砂虚线箭头/合金弧，lane 错开+术语标注+图例+空态）。结果页表格上方入口，不依赖用神。引擎表格数据层零改动。新增 8 测试全量 653 绿，实机验证通过。轻量任务（PRD-only），验证由自动测试+实机截图覆盖，未派独立 check 代理。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `f2aecce` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 3: 六爻卦名卦起卦 + 关系图大画布迭代

**Date**: 2026-07-22
**Task**: 六爻卦名卦起卦 + 关系图大画布迭代
**Branch**: `main`

### Summary

关系图七轮迭代：弹窗简化示意图、变爻列+贪合降噪、分类显隐 chips、地支化气具体标注（卯戌合化火）、标签碰撞避让沿线滑动、字号 9→11、InteractiveViewer 大画布(780宽)拖动缩放、本卦变卦列间距 22→76 修复化变标签遮盖。新增卦名卦起卦方式：自定月建日干支+选本卦变卦录入卦例，动爻由两卦阴阳差异反推，LunarInfo 按用户月日覆盖（空亡由日干支推）；修复枚举新值未跑 build_runner 导致序列化崩溃。全量 666 测试绿，需变大过卦例实机端到端验证。期间处理模拟器存储满（经用户确认删除三个旧开发应用）与 GMS 清数据导致的 Keystore 挂起（重启模拟器解决），模拟器旧排盘记录因完全卸载丢失。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `f2aecce` | (see git log) |
| `30e1818` | (see git log) |
| `f9bc82f` | (see git log) |
| `ada4c98` | (see git log) |
| `581564b` | (see git log) |
| `10ef95d` | (see git log) |
| `32ff3a8` | (see git log) |
| `61b9a4d` | (see git log) |
| `17bfaea` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 4: 六爻裁决层：受力求值+决策表+40例黄金断例

**Date**: 2026-07-25
**Task**: 六爻裁决层：受力求值+决策表+40例黄金断例
**Branch**: `main`

### Summary

实现 VerdictService 裁决层：四步求值（受力归集/元忌活跃性/悬置转条件/决策表首行命中）输出趋势+条件集+推理链，AnalysisReport 新增 judgment 字段（派生不落库），取用神卡展示断曰徽标。领域复核扩黄金断例至 40 例（29 原书占例+11 章法校验例）并修正五处裁决偏差：回头克优先、回头生直断、化合论化扶、元神优先需接续证据、克处逢生。spec 口径表同步裁决层规则。758 测试全绿。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `91591d7` | (see git log) |
| `6c7b16d` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 5: 奇门排盘与历法引擎

**Date**: 2026-07-28
**Task**: 奇门排盘与历法引擎
**Branch**: `main`

### Summary

完成时家转盘奇门时间归一化、拆补/茅山/置闰、九宫流水线、公开黄金盘、JSON 与仓储往返；修复跨时区交节、置闰周期、值使中五和天禽寄随规则。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `06c9f56` | (see git log) |
| `7d226a6` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 6: 奇门遁甲分析引擎

**Date**: 2026-07-28
**Task**: 奇门遁甲分析引擎
**Branch**: `main`

### Summary

完成来源化奇门事实、冲突裁决、应期、历史复算与AI投影，105项分析测试及1021项全仓测试通过。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `a83647e` | (see git log) |
| `2234996` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 7: 大六壬 C01 规则来源与版本契约

**Date**: 2026-07-28
**Task**: 大六壬 C01 规则来源与版本契约
**Branch**: `main`

### Summary

建立稳定规则身份、古籍执行批准门禁、排盘与分析版本、历史兼容状态及四种起课输入快照；完成定向与共享回归。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `2c48089` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 8: 大六壬月将与起课时间合同

**Date**: 2026-07-28
**Task**: 大六壬月将与起课时间合同
**Branch**: `main`

### Summary

完成精确中气月将、固定 offset 民用四柱、raw/calendar-backed 手工输入、v2 重放兼容及跨层展示持久化；独立复核后 analyze 与 1194 项全量测试通过。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `0b3ab8b` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 9: 完成奇门遁甲产品闭环与发布纠偏

**Date**: 2026-07-28
**Task**: 完成奇门遁甲产品闭环与发布纠偏
**Branch**: `main`

### Summary

完成首次启用 v1 基线纠偏，补齐起局边界、异步状态机、首页入口与规则诊断回归；隔离验证 202 项奇门目标和 1,207 项全量测试后归档纠偏子任务与奇门父任务。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `be1e432` | (see git log) |
| `41e99fe` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 10: 大六壬天盘与四课严格合同

**Date**: 2026-07-28
**Task**: 大六壬天盘与四课严格合同
**Branch**: `main`

### Summary

完成天盘固定循环双射、四课严格构造与三传入口校验；以三张《大六壬指南》独立手排课例锁定四课，发布 pan v3，并通过 1227 项全量测试与静态分析。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `d065317` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 11: 修复奇门甲日 AI 分析与中文展示

**Date**: 2026-07-29
**Task**: 修复奇门甲日 AI 分析与中文展示
**Branch**: `main`

### Summary

发布奇门分析 v2，从持久化日柱确定性解析甲日自身焦点，保留显式 v1 兼容门禁；集中中文化结果审计字段，并以 fake provider 验证 AI 完整调用链。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `8f94d53` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 12: 大六壬神将坐标重构落盘 + 奇门卡片背景简化

**Date**: 2026-07-29
**Task**: 大六壬神将坐标重构落盘 + 奇门卡片背景简化
**Branch**: `main`

### Summary

提交 C04 贵人/十二天将坐标重构（昼夜选贵、反查落宫、落宫定顺逆、天盘支/地盘宫双坐标、缺乘将显式失败）。奇门首页卡片背景由 3.5MB 全彩摆拍换为 300KB 单色宣纸水印（九宫格+八卦环），修复其资产守卫测试（尺寸 576x660、水印加深过对比度门槛）。tmp/ 加入 gitignore。全量 1274 tests 通过、analyze 零告警。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `0aa92df` | (see git log) |
| `1d50068` | (see git log) |
| `3f72060` | (see git log) |
| `dcdd3f0` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 13: 六爻古籍分析体系与 v1.6.0 发布

**Date**: 2026-08-02
**Task**: 六爻古籍分析体系与 v1.6.0 发布
**Branch**: `main`

### Summary

建立六爻古籍规则目录、稳定规则身份、有向作用、用神裁决与条件驱动应期；统一 AI 投影和不可移除提示词边界，冻结 canonical-v2-r5 并如实保留 AC9 凭据阻塞；完成来源 UI、日历联动、全量 1335 测试、v1.6.0 标签及 MuMu 1.6.0 冒烟。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `dea7978` | (see git log) |
| `b45409d` | (see git log) |
| `dea890d` | (see git log) |
| `e97d94b` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 14: 六爻提示词本地评测与凭据隔离

**Date**: 2026-08-02
**Task**: 六爻提示词本地评测与凭据隔离
**Branch**: `main`

### Summary

使用忽略的本地 calibration 探针复用 canonical-v2-r6 冻结请求，完成 3 个案例、5 组成对盲评：候选 21 项提升、14 项持平、0 回退，候选硬门禁 5/5 通过；确认正式评测器 90 秒阈值和 judge schema 歧义不适配当前模型。提交并推送 key.txt 与固定评测输出路径的精确忽略规则，凭据与本地工件未进入 Git。

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `f81461a` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 15: 六爻真实案例提示词校准与 v1.6.1 发布

**Date**: 2026-08-03
**Task**: 六爻真实案例提示词校准与 v1.6.1 发布
**Branch**: `main`

### Summary

完成六爻历法来源、v3 阶段裁决、生产提示词 1.1.20、本地真实模型校准及 v1.6.1 发布

### Main Changes

- Detailed change bullets were not supplied; see the summary above.

### Git Commits

| Hash | Message |
|------|---------|
| `0cf21b7` | (see git log) |
| `62014bd` | (see git log) |
| `557f159` | (see git log) |
| `59c3af3` | (see git log) |

### Testing

- Validation was not recorded for this session.

### Status

[OK] **Completed**

### Next Steps

- None - task complete
