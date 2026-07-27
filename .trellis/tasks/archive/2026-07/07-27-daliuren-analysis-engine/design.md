# 设计：大六壬分析引擎

规则性质说明：排盘层（子任务 1）是古籍锁定口径；本层（断课）古籍无唯一决策表，以下规则为**本项目约定**（自洽、保守、可演进），spec 沉淀时如实标注。

## 1. 共享模型提升

新建 `lib/domain/services/shared/analysis/models/`：

- `polarity.dart`：`Polarity`（从六爻 `analysis_tag.dart` 移出；枚举值不变）。
- `verdict_models.dart`：`YingQiScale`、`VerdictTrend`、`VerdictEffect`、`VerdictFactor`、`VerdictCondition`、`VerdictJudgment`、`YingQiCandidate`（从六爻 `analysis_report.dart` 移出；字段一律原样，freezed 重新生成）。

六爻原文件改为定义剩余类 + `export` 迁出者（`analysis_tag.dart` export polarity；`analysis_report.dart` export verdict_models），消费方 import 零改动。运行 build_runner 再生成。

## 2. 大六壬分析模型（`lib/domain/services/daliuren/analysis/models/`）

全部为派生数据，仅 `@freezed`（无 json），不落库。

```dart
enum DlrTagCategory { keGe('课体课格'), ganZhi('干支主客'), chuan('三传结构'),
                      tianJiang('天将'), shenSha('神煞'), kongWang('空亡') }

class DlrAnalysisTag {          // 对齐六爻 YaoAnalysisTag 字段风格
  String term;                  // "元首" "干上克身" "传归生身" "发用落空" …
  DlrTagCategory category;
  Polarity polarity;            // 共享
  int priority;                 // 越小越先展示
  String reason;                // 人话理由（含地支/位置）
  List<String> relatedPositions;// 关联位置标签："干上" "支上" "初传" "中传" "末传" "第N课"
}

class KeGeInfo {                // 课格定性
  String keTypeName;            // 九宗门名（贼克/比用/…）
  String geName;                // 传统格名（元首/重审/知一/…）
  Polarity polarity;
  String reason;                // 基调一句话
}

class DaLiuRenAnalysisReport {
  KeGeInfo keGe;
  List<DlrAnalysisTag> ganZhiTags;                    // 干支主客（含干上/支上空亡）
  Map<ChuanPosition, List<DlrAnalysisTag>> chuanTags; // 每传标签
  List<DlrAnalysisTag> juTags;                        // 课局级（递生递克/传归/三合局/伏吟迟滞…）
  List<YingQiCandidate>? yingQi;                      // 共享模型
  VerdictJudgment? judgment;                          // 共享模型
  String? verdictSummary;
  // helper: topTagsForChuan(ChuanPosition, {count})
}
```

## 3. 事实层服务（`lib/domain/services/daliuren/analysis/`，纯静态函数）

### 3.1 KeGeService — 课格定性

由 `SanChuan.keType` + `SiKe` + 日干刚柔重推格名（不解析 keTypeExplanation 文本）：

| keType | 判据 | 格名 | polarity | 基调 |
|--------|------|------|----------|------|
| zeiKe | 有下贼上 | 重审 | neutral | 事从卑下而起，先难后易，审慎则吉 |
| zeiKe | 仅上克下 | 元首 | ji | 尊临卑、事顺理正 |
| biYong | — | 知一 | neutral | 事在同类，择亲近者而就 |
| sheHai | — | 涉害 | xiong | 历涉艰难，事迟滞乃成 |
| yaoKe | 二三四课上神克日干 | 蒿矢 | neutral | 克自远来，虚惊多实害少 |
| yaoKe | 日干克上神 | 弹射 | neutral | 我克在远，事轻微 |
| maoXing | 刚日 | 虎视 | xiong | 事多惊疑，防伺伏之患 |
| maoXing | 柔日 | 冬蛇掩目 | xiong | 暗昧不明，事宜静守 |
| bieZe | — | 别责 | neutral | 事不专一，别有所托 |
| baZhuan | — | 八专 | neutral | 干支同体，事涉同谋或内外不分 |
| fuYin | 有克 | 不虞 | xiong | 静中生变，防不虞之事 |
| fuYin | 无克刚日 | 自任 | neutral | 伏而不动，宜守不宜进 |
| fuYin | 无克柔日 | 自信 | neutral | 伏而自省，事迟 |
| fanYin | 四课无克 | 井栏射 | neutral | 动极思迁，去而复来 |
| fanYin | 有克 | 反吟 | xiong | 反复动荡，事多往返 |

### 3.2 GanZhiZhuKeService — 干支主客

日干为人（我），日支为事（彼/事体）。以五行论：

- 干上神生日干 → "干上生身"（ji）；克日干 → "干上克身"（xiong）；日干克干上神 → "身制干上"（neutral）；日干生干上神 → "身泄于上"（neutral）；比 → "干上比助"（neutral 偏 ji 措辞）。
- 支上神对日支同理："事得生扶"（ji）/"事体受制"（xiong）/等。
- 干上神或支上神落旬空 → kongWang 类标签"干上空亡/支上空亡"（xiong，reason 注明待填实）。
- relatedPositions 标 "干上"/"支上"。

### 3.3 ChuanAnalysisService — 三传结构

每传标签（挂 chuanTags）：

- 传空亡（Chuan.isKongWang）：初传→"发用落空"（xiong，事起无力）；中传→"中传落空"（过程有断）；末传→"末传落空"（xiong，结果易虚）。
- 天将吉凶（挂对应传）：吉将 = 贵人、六合、青龙、太常、太阴、天后；凶将 = 腾蛇、朱雀、勾陈、天空、白虎、玄武。term 如"初传乘青龙"，polarity 按将，reason 用 ShenJiang.description。
- 初传克日干 → "发用克身"（xiong）；初传生日干 → "发用生身"（ji）。

课局级标签（挂 juTags）：

- 初生中且中生末 → "递生传进"（ji，事渐顺成）；初克中且中克末 → "递克传退"（xiong）。
- 末传生日干或与日干寄宫支六合 → "传归生身"（ji，终得其济）；末传克日干 → "传归克身"（xiong，事终不利）。
- 三传构成三合局 → "三传合局"（neutral，事体牵连成局，注明合成何局）。

### 3.4 ShenShaChuanService — 神煞落传

对 `DaLiuRenResult` 的神煞列表：神煞地支命中三传之支时挂标签到对应传（category shenSha，polarity 按神煞吉凶类型）；重点措辞：驿马临初传 → "驿马发用"（事动而速）。其余神煞用通用措辞"X临Y传"。读取现有 `ShenSha` 模型字段实现，不改神煞服务。

## 4. 裁决层 DaLiuRenVerdictService

输入：KeGeInfo + ganZhiTags + chuanTags + juTags + 三传空亡状态。产出共享 `VerdictJudgment`。**决策表首行命中**，不加权：

```
悬置条件收集（先于决策表）：
  初传空 → VerdictCondition("待发用填实", branch=初传支)
  末传空 → VerdictCondition("待归宿填实", branch=末传支)
  中传空 → 不单独成悬置（只留标签）

决策表（自上而下首行命中）：
1. 初传空 且 末传空                          → 难成（"首尾俱空，事难成实"，hasRescue=false）
2. 传归克身 且 干上克身                      → 难成（"内外交攻"）
3. 递克传退 且 课格凶                        → 难成
4. 传归生身 且 无悬置                        → 可成（课格涉害/重审时 nuance="先难后成"）
5. 传归生身 且 有悬置                        → 待条件
6. 递生传进 且 无悬置 且 无克身标签           → 可成
7. 有悬置                                    → 待条件
8. 传归克身 或 发用克身                      → 难成
9. 课格 ji 且 无任何 xiong 标签              → 可成
10. 其余                                     → 趋势不明
```

- factors：把命中行及参与判断的标签逐条转 `VerdictFactor`（effect：扶=fu/抑=yi/悬=suspend；source 统一 "本项目约定（大六壬断课 v1）"，课格行 source "《大六壬指南》课体章（基调）"）。
- summary 模板："课体{keTypeName}（{geName}），断曰：{trend}。{nuance？}{条件清单}。"

## 5. 应期层 DaLiuRenYingQiService

产出 `List<YingQiCandidate>`（scale 全为 ri，v1）：

| 候选 | branch | priority | 条件 |
|------|--------|----------|------|
| 待填实之空亡传支值日 | 该传支 | 1 | 存在空亡悬置（与 VerdictCondition.branch 衔接） |
| 发用之期（初传支值日） | 初传支 | 2 | 恒有 |
| 归宿之期（末传支值日） | 末传支 | 3 | 恒有；与初传同支时去重 |
| 驿马临传，马支值日 | 马支 | 2 | 神煞驿马命中三传 |
| 伏吟冲动之期（初传冲支值日） | 冲支 | 2 | 课体伏吟 |

## 6. 入口 DaLiuRenAnalyzer

`static DaLiuRenAnalysisReport analyze(DaLiuRenResult result)`：从 result 取 siKe/sanChuan/kongWang/shenSha/日干支，依次调 3.1→3.4、4、5 组装报告。运行时派生，任何路径不得写库。日干/寄宫等基础数据复用 `DaLiuRenConstants`（子任务 1 修正后的口径）。

## 7. 测试

- KeGeService：用子任务 1 的 13 黄金盘面逐一断言格名与 polarity（K→元首、B→重审、A→知一、C→涉害、D→弹射、D2→蒿矢、E→冬蛇掩目、G→别责、F→八专、H1→自任、H2→自信、I→反吟、J→井栏射）。
- VerdictService：决策表 1~10 行各构造一个最小输入命中测试（构造标签/空亡状态直调，不必全盘）。
- 干支主客/三传结构/应期：各 3~5 个方向性用例。
- Analyzer：对黄金例 K（戊子日元首）与 H2（丁亥伏吟）全链冒烟，断言报告各区非空、verdictSummary 含格名。
- 全量 `flutter test` 通过，六爻零回归。
