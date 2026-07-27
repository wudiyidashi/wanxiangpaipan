# 大六壬分析引擎（共享模型+事实层+裁决层）

## Goal

在修正后的排盘引擎之上建立大六壬断课分析层，复用六爻已验证的"事实层标签 → 裁决层四值"架构；把可跨系统复用的裁决/应期模型提升到共享层。

## Requirements

- R1 共享模型提升：`Polarity`、`YingQiScale`、`VerdictTrend/Effect/Factor/Condition/Judgment`、`YingQiCandidate` 从六爻 analysis models 迁至 `lib/domain/services/shared/analysis/models/`；六爻原路径以 `export` 保持零消费方改动。`TagCategory`/`YaoAnalysisTag`/`AnalysisReport`/`YongShenChain` **不迁移**（六爻专属，迁移会引发穷举 switch 连锁改动）。
- R2 大六壬自有标签模型与报告模型（派生数据、不落库），字段与分类见 design.md。
- R3 事实层纯函数服务：课格定性、干支主客、三传结构、天将吉凶、神煞落传、空亡落传。
- R4 裁决层：决策表首行命中产出 `VerdictJudgment`（复用共享模型），不做加权打分。
- R5 应期层：产出 `List<YingQiCandidate>`（日尺度为主）。
- R6 统一入口 `DaLiuRenAnalyzer.analyze(DaLiuRenResult)`，运行时派生、永不落库。
- R7 单元测试：课格覆盖九宗门全部格名（用子任务 1 黄金课例盘面）；裁决决策表逐行命中测试；analyzer 集成冒烟。

## Constraints

- 断课层规则的古籍确定性低于排盘层：决策表与标签措辞按 design.md 锁定为"本项目约定"，spec 中如实标注证据强度，不冒充古籍唯一口径。
- 六爻侧行为零变化：模型迁移后全量六爻测试必须原样通过；不修改六爻任何逻辑/UI。
- 本任务不做 UI 与 AI formatter 接入（子任务 3 范围）。
- 不动工作区 3 个六爻遗留未提交改动。

## Acceptance Criteria

- [ ] 共享模型落位，六爻消费方零改动（仅 build_runner 再生成），全量测试通过。
- [ ] 九宗门 → 格名映射全覆盖且有测试（元首/重审/知一/涉害/蒿矢/弹射/虎视/冬蛇掩目/别责/八专/自任/自信/不虞/井栏射/反吟）。
- [ ] 裁决决策表每行至少一个命中测试；conditions 与应期候选按地支衔接。
- [ ] `flutter analyze` 零告警；`flutter test` 全量通过。
