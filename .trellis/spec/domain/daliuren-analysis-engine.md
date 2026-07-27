# 大六壬断课分析引擎规范

架构与六爻分析引擎同构：**事实层（客观标签）→ 裁决层（四值决策表）**，全部派生数据运行时重算、永不落库。排盘口径见 `daliuren-pan-engine.md`（分析层只读依赖，不得反向修改排盘层）。

## 证据强度声明

- 排盘层为古籍锁定口径；**本层决策表与标签措辞为"本项目约定（大六壬断课 v1）"**——古籍无唯一断课决策表，规则以自洽、保守为原则，允许演进。课格基调 source 标《大六壬指南》课体章，其余 factor source 标"本项目约定（大六壬断课 v1）"。
- 修改决策表/课格表须同步更新任务 design（archive/2026-07/07-27-daliuren-analysis-engine）与对应测试。

## 共享模型（`lib/domain/services/shared/analysis/models/`）

- `Polarity`、`YingQiScale`、`VerdictTrend/Effect/Factor/Condition/Judgment`、`YingQiCandidate` 为跨术数系统共享；六爻原路径 export 转发，消费方 import 不变。
- 六爻专属模型（`TagCategory`/`YaoAnalysisTag`/`AnalysisReport`/`YongShenChain`）**不共享**——共享会引发穷举 switch 连锁改动；新系统各自定义标签模型（大六壬为 `DlrAnalysisTag` + `DlrTagCategory`）。

## 分析层结构（`lib/domain/services/daliuren/analysis/`）

- 入口：`DaLiuRenAnalyzer.analyze(DaLiuRenResult) → DaLiuRenAnalysisReport`。
- 事实层：`KeGeService`（九宗门→15 格名定性表）、`GanZhiZhuKeService`（干为人/支为事，五行五态+空亡）、`ChuanAnalysisService`（传级：空亡/天将吉凶/发用生克身；课局级：递生递克/传归/三合局）、`ShenShaChuanService`（神煞命中传支，驿马发用特殊措辞）。
- 裁决层：`DaLiuRenVerdictService`——悬置收集（初空/末空成 `VerdictCondition`、中空仅标签）先于决策表；**十行决策表首行命中，禁止加权打分**。
- 应期层：`DaLiuRenYingQiService`——五类日尺度候选（填实 p1、发用 p2、归宿 p3、驿马 p2、伏吟冲动 p2），`VerdictCondition.branch` 与应期候选按地支衔接。

## 关键约定

- 天将吉凶集合：吉＝贵人、六合、青龙、太常、太阴、天后；凶＝腾蛇、朱雀、勾陈、天空、白虎、玄武。
- 传归生身判定含"末传支与日干寄宫支六合"路径（寄宫用六壬寄宫表，非禄位）。
- 课格重推自结构化字段（keType + SiKe 克方向 + 刚柔日），**禁止解析 `keTypeExplanation` 文本**。
- 课格测试必须复用排盘层 13 黄金课例盘面直调构造（`test/unit/services/daliuren/analysis/`），保证两层口径联动。

## 可视化与 AI 接入约定

- 结果页在 build 内一次派生 `DaLiuRenAnalyzer.analyze(result)`，无控制器、不落库；三传 section 的 `report` 参数必须保持可选（起卦预览等调用点无 report）。
- `YingQiCard` 为共享组件（`lib/presentation/widgets/ying_qi_card.dart`）；六爻旧路径仅 export 转发，新系统直接 import 共享路径。
- 标签配色以 `lib/presentation/widgets/yao_tag_badge.dart` 为权威（吉=jishenGreen、凶=zhusha、中=huise）；圆盘图子宫在正下方、顺时针、每宫 30°，颜色一律用 AppColors token。
- AI formatter 的 `analysis` section 只能增字段不得删改既有 sections/coreData（模板兼容）；措辞遵循"程序按既定规则标注、不下断语"。
