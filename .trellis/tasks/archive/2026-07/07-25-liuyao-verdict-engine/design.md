# 设计：六爻裁决层

## 1. 总体结构

新增一个纯函数服务 `VerdictService`，位于 `lib/domain/services/liuyao/analysis/verdict_service.dart`，
在 `LiuYaoAnalyzer.analyze()` 中于应期计算之后调用：

```
输入:  用神爻(Yao) + 用神标签(List<YaoAnalysisTag>) + YongShenChain
      + 全卦 yaoTags + Gua/changingGua + LunarInfo + 应期候选
输出:  VerdictJudgment { trend, nuance, conditions, factors, summary }
```

数据流不变：Analyzer 仍是唯一入口，`_buildVerdict` 被 `VerdictService.judge()` 取代，
`verdictSummary` 改由 `judgment.summary` 填充（字段保留，向后兼容 UI）。

## 2. 模型（analysis_report.dart 扩展）

```dart
enum VerdictTrend { keCheng('可成'), nanCheng('难成'),
                    daiTiaoJian('待条件'), buMing('趋势不明') }

@freezed VerdictFactor {
  String rule;        // 规则名，如 "日月生扶" "忌神独发"
  String effect;      // fu(扶) / yi(抑) / suspend(悬置) / neutral
  String reason;      // 人话理由（含爻位/地支）
  String source;      // 经文依据，如 "《增删卜易·生克章》"
}

@freezed VerdictCondition {
  String label;       // "待出空" "待冲开墓库" ...
  String? branch;     // 关联地支（衔接应期候选）
  String reason;
  bool hasRescue;     // 是否存在解救路径（如真空无救 = false）
}

@freezed VerdictJudgment {
  VerdictTrend trend;
  String? nuance;               // "先难后成" "成而迟滞" 等
  List<VerdictCondition> conditions;
  List<VerdictFactor> factors;  // 推理链，按裁决顺序
  String summary;               // 生成的总览文案
}
```

`AnalysisReport` 新增可空字段 `VerdictJudgment? judgment`（派生数据不落库，无迁移问题）。

## 3. 裁决算法（四步顺序求值，非加权求和）

### Step 1 受力归集（按层级）

从用神标签（term 字符串匹配，同 YingQiService 模式）归集为分层受力记录：

| 层级 | 扶（+） | 抑（−） | 来源标签 |
|-----|--------|--------|---------|
| L1 日月 | 临月建/临日辰/月生/日生/旺相 | 月克/日克/休/囚/死 | wangShuai 类 |
| L2 动爻 | 动爻生/动爻扶/贪合忘克/贪生忘克 | 动爻克 | shengKe 类（贪合忘生记 −，失去生源） |
| L3 暗动 | 暗动爻生 | 暗动爻克 | special/heChong 类含"暗动"关联 |
| L4 变爻 | 回头生/化进神/化合（《六合章》称化扶） | 回头克/化退神 | dongBian 类 |

遮蔽规则不在裁决层重新实现——事实层已把"贪合忘生""贪合忘克"等结论算好，
裁决层只做归集与解释（每条归集记录生成一个 VerdictFactor）。

**净强弱判定**（分类而非打分）：
- 重抑集 = L1 抑（月克/日克/囚/死/日破/冲散）∪ L4 重抑（回头克/化退神）∪ 伏受制（飞克伏/伏神受制）
- `strong`：L1 有扶 且 重抑集为空。**动爻克不入重抑集**——它即忌神动，由 Step 3 的 jiActive 修正处理，避免双重计数
- `weak`：重抑集非空 且 全层无任何扶
- `mixed`：其余（含全中性无扶无抑，进入决策表兜底）
- '休' 记中性因素，不计扶抑

### Step 2 悬置状态 → 条件集

以下标签不参与强弱判定，直接生成 VerdictCondition（与应期候选按 branch 衔接）：

| 标签 | 条件 | hasRescue 判据 |
|-----|------|---------------|
| 旬空(假空) | 待出空/冲空填实 | true |
| 真空 | 待出空 | strong 时 true；weak 时 false（真空到底） |
| 月破 | 待出月/填实 | 非 weak 时 true |
| 入日墓/月墓/动墓/化墓 | 待冲开墓库 | true |
| 合住/合绊 | 待冲开 | true |
| 伏藏（用神为伏神） | 待出伏（值日/冲飞） | 飞不克伏时 true |
| 化空/化破 | 待变爻填实/出月 | true |
| 临绝/化绝 | 待长生/生扶 | 有元神动或日月生时 true |

### Step 3 元/忌神修正（标签驱动，不依赖 chain 选位）

活跃性直接从用神位标签判定，天然吸收事实层的遮蔽结论（贪合忘生/贪合忘克/贪生忘克
会替换掉动爻生/动爻克标签，故无需二次判遮蔽）：

- `yuanActive`：用神位存在 `动爻生` 或 `连续相生`，或某暗动爻五行生用神
- `jiActive`：用神位存在 `动爻克` 或 `连续相克`，或某暗动爻五行克用神；
  但若攻击爻（relatedYao）自身带 回头克/化退神/冲散 → 忌神受制，jiActive=false，记因素"忌神受制"
- 忌神动而元神亦动，只有标签已证明 `连续相生` / `贪生忘克` 时，才由元神优先，
  jiActive 不构成降级，nuance="忌化为助"；元神仅暗动而忌神明动、未形成接续相生时，仍以忌神为先。
- 元神/忌神静而不空 → 不参与（静不作用）

### Step 4 裁决决策表（首行命中）

领域复核前置规则（2026-07-25，优先于强弱分支）：

| # | 守卫条件 | trend | nuance | 原书复核 |
|---|---------|-------|--------|---------|
| P1 | 用神自身回头克，且无 L1 日月扶 | 难成 | 克处无生 | 《进退章》师之明夷，校对本第56页 |
| P2 | 用神自身回头生、无活跃忌神，且无条件或只有次级合绊条件 | 可成 | 先难后成 | 《五行相生章》复之震，校对本第24页 |

`回头生` 不覆盖旬空、月破、化空破墓绝等实质悬置条件；这些条件仍进入常规决策表。

| # | 守卫条件 | trend | nuance |
|---|---------|-------|--------|
| 1 | weak 且存在 hasRescue=false 的条件 | 难成 | 空破墓绝，到底无救 |
| 2 | weak 且 yuanTakesPriority | 待条件 | 先难后成（无忌神，或已有连续相生/贪生忘克证据） |
| 3 | weak 且 jiActive | 难成 | 克处无生 |
| 4 | weak | 难成 | 衰而无助 |
| 5 | strong 且条件集空 且 !jiActive | 可成 | 应期取值日/生旺 |
| 6 | strong 且条件集非空 | 待条件 | 成而有待（列条件） |
| 7 | strong 且 jiActive | 待条件 | 吉中有阻 |
| 8 | mixed 且 yuanTakesPriority | 待条件 | 先难后成 |
| 9 | mixed 且 jiActive | 难成 | 抑重于扶 |
| 10 | mixed 且条件集非空且皆可解 | 待条件 | 待解除后再断（如月破待出月） |
| 11 | mixed 且 L1 有扶 | 待条件 | 先难后成（克处逢生） |
| 12 | mixed | 趋势不明 | 扶抑并见，须参断者裁 |

> 领域复核补充（2026-07-25）：动爻与本位变爻六合是“化合”，原书称“化扶”，
> 属 L4 扶助而非合绊，不生成“待冲开”；动爻被日月或他爻合住/合绊仍按悬置处理。

每次命中记录为最后一个 VerdictFactor（rule=表行名，source=对应章节）。
表行守卫按序判定、首行命中即出，保证确定性与可测试性。

### summary 生成

`用神{六亲}{地支}{五行}，{trend.name}{nuance 有则附}；{条件集前2项}；
应期候选仅表示条件触发窗口，不单独决定事情成败{应期前2项}`。

## 4. 关键取舍

- **消费标签 vs 重算事实**：消费标签。事实层已单测锁定，重算会造成双源真相；
  代价是依赖 term 字符串——与 YingQiService 现状一致，术语变更时两处同改（spec 已要求改口径须同步单测）。
- **分类裁决 vs 加权打分**：分类 + 决策表。spec 明令禁止按标签数量判吉凶；
  决策表每行可单测、可标注经文出处，打分权重则无法审计。
- **首行命中 vs 多规则合成**：首行命中。守卫互斥性由行序保证，简单且结果唯一；
  多规则合成需要冲突消解策略，MVP 不引入。
- **伏神取用**：Step 1 输入改用 `selectedYongShenTags`（Analyzer 已按伏神自身重算），
  另加飞伏关系因素（飞来生伏=扶 / 飞来克伏=抑且伏藏条件 hasRescue=false）。

## 5. 兼容与回滚

- 未选用神：`judgment == null`，报告其余字段 bit 级不变（回归测试锁定）。
- UI 只读 `verdictSummary` 的现有代码无需改动即兼容；总览卡增量展示 trend/conditions。
- 回滚：Analyzer 中一处调用点还原为 `_buildVerdict` 即可，模型字段可空无迁移。

## 6. 黄金断例测试设计

`test/unit/services/liuyao/analysis/verdict_golden_test.dart`：
每例 = {描述, 出处/依据, 月日干支, 卦（六爻纳甲+动静）, 用神位, 期望 trend, 期望条件}。
领域复核后共 40 例（26 个原书占例 + 14 个明确标注的“章法校验例”）。每例均记录问事、
月日、卦与动爻、取用、依据章节、校对本印刷页码、预期趋势，以及相关条件/因素/应期地支。

覆盖矩阵设有不可静默降低的数量下限：旺衰/日月生克 10、真空假空 6、月破 5、
入墓/出墓 3、合住/合绊/化合 3、回头生克 7、化进退 12、化空破墓绝 8、
元神/忌神/仇神 9、飞伏/出伏 4、应期条件联动 18。

本轮扩展直接发现并修正五处裁决偏差：复之震回头生、否之讼克处逢生、师之明夷回头克优先、
临之泰非接续元忌并见、日冲飞神后伏神得出。先按原书裁定夹具，再修改引擎，并以服务级回归锁定。
