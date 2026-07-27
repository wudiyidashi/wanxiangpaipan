# 大六壬排盘完善与分析引擎（父任务）

## Goal

修复九宗门三传正确性，建立断课分析层与可视化，对齐六爻分析引擎架构。

## 任务地图（全部完成）

| 子任务 | 交付 | 提交 |
|--------|------|------|
| 07-27-daliuren-sanchuan-fix | 寄宫改六壬口径、下贼上优先、九宗门补全（涉害深度/遥克/昴星/别责/八专/伏吟刑传/反吟驿马）、13 黄金课例、spec daliuren-pan-engine.md | e72d17d |
| 07-27-daliuren-analysis-engine | Verdict/YingQi 模型提升共享层、15 格名定性、事实层五服务、十行决策表、应期候选、spec daliuren-analysis-engine.md | 7effd44 |
| 07-27-daliuren-analysis-ui | 课格断诀卡、三传徽标与详析弹层、YingQiCard 共享复用、天地盘圆盘图、AI formatter analysis section | c50c1c2 |

## 跨子任务验收（集成复核结论）

- [x] 排盘→分析→UI/AI 全链联动：课格测试复用排盘黄金盘面；formatter 黄金例 K 走排盘服务直调
- [x] 六爻侧零回归（模型迁移与 YingQiCard 提升均 export 转发）
- [x] 全量 flutter test 844 通过、analyze 零告警

## 后续待办（不阻塞本父任务）

- 应期日历接入大六壬（onViewCalendar 目前为 null）
- 大六壬类神（按占类取用）选择交互与裁决联动
- 断课决策表 v2（结合实占反馈演进，spec 已标注证据强度）
