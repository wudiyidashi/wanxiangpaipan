# 《大六壬指南》涉害／顾祖课独立复核

- Reviewer: `c00_guide_shehai_review (Codex)`
- Review date: `2026-07-28`
- Method: 直接查看影印 PDF、题名页、scandata 与 PDF 44 盘式；OCR 仅用于定位；未调用任何生产排盘代码

## 结论

PDF 44 右上课例可作为一张非贼克完整外例。题时、四课、三传、六亲、天将及原书所标 `涉害／顾祖` 均可从同一影印页直接读取，并可手工闭环复核。建议登记为 `approved / B / locatorOnly=false`。B 级只批准本课的输入与正例输出，不因一张正例而批准涉害法、顾祖格或天将排布的完整充分必要条件。

## 底本与 locus

| 字段 | 核验值 |
|---|---|
| Source ID | `dlr.source.daliuren-zhinan-scan` |
| 题名页 | 《大六壬指南》，`中国古典未来学丛书`；`[明]陈公献先生手著`、`[清]程翔云先生鉴定`、`中国数术学研究社`、`于鸿编辑校订` |
| 馆藏件 | Internet Archive `20210924_20210924_0416` |
| 远端／本地文件 | `大六壬指南.pdf` / `tmp/pdfs/daliuren/guide.pdf` |
| 版本边界 | 中国数术学研究社编校影印本；题名页和 IA 元数据均未给可核刊年，PDF 的 2021 创建时间不是版本刊年；扫描似止于印本 78 页而目录列至 84 页，但不影响本页完整性 |
| 稳定定位 | 全册，PDF page `44`，zero-based scan leaf `43`，印本页 `39`，卷四 `仕宦`，右上课例 |
| 页码复核 | scandata 共 83 leaf，leaf 0 起且全部进入 PDF，故 `pdfPage = scanLeaf + 1`；本页左栏可见 `三十九` |

建议 `sourceRef`：`volume="全册"`、`scanLeaf=43`、`printedLeaf="39"`、`pdfPage=44`、`referenceKind="scan"`、`imageLabel=null`、`locator=null`。

## 原题与问题

影印页无标点原题可逐字读为：

> 戊辰年十一月庚寅日庚辰时徽州汪仙民邵无奇在京占少宗伯马廉庄能拜相否

规范化输入：

- 年柱 `戊辰`；月文 `十一月`；日柱 `庚寅`；时柱 `庚辰`。
- 问题：`少宗伯马廉庄能拜相否`。
- 人物上下文：题文字符明确包含 `徽州`、`汪仙民`、`邵无奇`、`在京`、`少宗伯`、`马廉庄`。最自然的断句是“徽州汪仙民、邵无奇在京占……”，但原页无顿号，两个问占者的分隔属于采用假设；`在京`也不能扩写为精确起课地点。
- 可用的原断短引：`马宗伯不但不能入拜，且不日还乡矣。` 原断只作古籍文本对照，不作现实预测正确性验收。

## 独立盘面复核

### 月将与天盘

原题未另写“寅将”。盘式显示天盘相对地盘退二位：庚寄申而申上见午，午上见辰，寅上见子，子上见戌；同时辰时之地盘辰上见寅。因此本课月将只能按本页盘式反推出 `寅`。这可批准本课的天盘旋转输入／输出一致性，不能批准现代历法交节、时区或“十一月必为寅将”。

### 四课

原盘从右向左列四课；天将原字分别为 `龙／六／后／玄`，按现有 fixture 规范展开：

| 课 | 下 | 上 | 天将 |
|---:|---|---|---|
| 1 | 庚 | 午 | 青龙 |
| 2 | 午 | 辰 | 六合 |
| 3 | 寅 | 子 | 天后 |
| 4 | 子 | 戌 | 玄武 |

### 三传、六亲、天将

原盘三列分别写 `鬼印财`、`午辰寅`、`龙六蛇`。按初、中、末自上而下及当前 schema 全称规范化为：

| 传 | 支 | 六亲 | 天将 |
|---|---|---|---|
| 初传 | 午 | 官鬼 | 青龙 |
| 中传 | 辰 | 父母 | 六合 |
| 末传 | 寅 | 妻财 | 螣蛇 |

六亲与庚金逐传核对一致：午火克金为官鬼，辰土生金为父母（原盘简称 `印`），庚金克寅木为妻财。

### 九宗门与课格

原书盘头直接标 `涉害`、`顾祖`，手排也闭环：

1. 四课只有午克庚、戌克子两项 `上克下`；候选午、戌与阳日庚俱比，不能由比用唯一取出。
2. 按当前锁定的“含临宫、不含本家，本气与寄干分别计害”口径，午加庚寄宫申回午本家，受亥水、寄壬、子水、丑寄癸四害；戌加子回戌本家，受寅木、寄甲、卯木、辰寄乙四害。
3. 同为四害时，午临申为孟，戌临子为仲，故取午发用；中、末依天盘为辰、寅。
4. `午 -> 辰 -> 寅` 为逆间传，正是顾祖格；当前结构化目录只有 `间传课` ID，未另设顾祖子格 ID。

本页不写“四害”数字，也不说明计数规则；上述数字是独立手排与现行合同的相符性检查。它使本例成为涉害同深后“孟胜仲”的强正例，但不能单独证明所有涉害计数边界或并列分支。

## Schema 与 fixture 对照

该课可直接沿用 `assets/data/daliuren/classics/cases/zhinan.json` 的结构：

- 候选 ID：`dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang`。
- `rawInput` 可用既有字段 `yearPillar/lunarMonthText/monthGeneral/dayPillar/hourPillar/civilDateTime/timezone/question/personContext`；为与现有《指南》fixture 一致，可把盘式反推的 `monthGeneral: "寅"` 同时写入 `rawInput` 与 `expectedFacts`，但必须在 `adoptedAssumptions` 声明其并非题文直书。
- `expectedFacts` 可完全沿用 `monthGeneral + fourLessons[] + transmissions[] + courseNames[]`；`courseNames` 应保存原页标签 `['涉害', '顾祖']`，不要把未印出的“间传”替换进去。
- 天将用全称 `青龙/六合/天后/玄武/螣蛇`，六亲将原字 `印` 规范化为 `父母`，与现有两张《指南》fixture 一致。
- `expectedDerivation.method="independentManual"`、`usesProductionCode=false`、reviewer/date 使用本报告署名与日期。

必须列入 `unresolvedFields` 或 `adoptedAssumptions`：`civilDateTime`、`timezone`、`solarTermInstant`、戊辰年的唯一公历映射、辰时内的精确时刻、月将并非题文直书、题文无标点导致的问占者分隔、版本刊年。不得从当前生产算法补齐这些字段。

## B/C 与能力覆盖建议

- **B eligible**：页级 locus、原题字符、四课、三传、六亲、各课传天将、原页 `涉害／顾祖` 标签、盘式反推的本课寅将，以及本课的涉害正例结果。建议整例 `approved / B / locatorOnly=false`。
- **仍为 C/unknown**：公历／中气边界、时区、全套月将历法选择、完整涉害算法及所有并列分支、顾祖格充分必要条件、昼夜贵人和十二天将完整落宫算法、题文人物标点。不得借本例提升这些规则的全局证据等级。
- **强覆盖**：`daliuren.pan.heavenPlate`、`daliuren.pan.fourLessons`、`daliuren.jiuzongmen.shehai`、`daliuren.derivedFacts.sixRelations`、`daliuren.kejing.004`（涉害正例）、`daliuren.kejing.061`（间传之顾祖正例）。对应 rule 可挂 `dlr.rule.pan.003.heaven-plate-rotation`、`dlr.rule.pan.005.first-lesson` 至 `dlr.rule.pan.008.fourth-lesson`、`dlr.rule.jiuzongmen.003.shehai`、`dlr.rule.derived-facts.005.six-relations`、`dlr.rule.kejing.004`、`dlr.rule.kejing.061`。
- **有限覆盖**：`daliuren.pan.monthGeneral` 只表示“本页盘式反推出寅”，不应据此把 `pan.001` 的现代中气选择或 `pan.002` 的整张月将表算作已测试。四课／三传天将可留作 expected facts，但在未完整抄出十二将盘和贵人方向前，不建议挂任一宽泛 `daliuren.shenjiang.*` rule ID。
