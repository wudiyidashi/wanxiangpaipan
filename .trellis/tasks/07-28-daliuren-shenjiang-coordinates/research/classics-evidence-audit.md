# C04 贵人与十二天将古籍影印审计

- Reviewer: `C04 independent scan audit`
- Date: `2026-07-28`
- Scope: 独立复核 C00 `dlr.rule.shenjiang.001-.006`；不修改产品代码

## New Direct Evidence

《御定六壬直指》卷上 `yuding-zhizhi-text.pdf`：

| PDF | Scan leaf | Printed leaf | Direct text and consequence |
|---:|---:|---|---|
| 18 | 17 | 七 | “正时自卯至申用昼贵，即阳贵；自酉至寅用夜贵，即阴贵。”直接支持昼夜边界。 |
| 19 | 18 | 八 | 承“贵人加”后写“于亥子丑寅卯辰六位则顺行，加于巳午未申酉戌六位则逆行。”直接支持完整六区，纠正 C00 报告中“仍为方位推导”的结论。 |
| 19 | 18 | 八 | “一贵人、二螣蛇、三朱雀、四六合、五勾陈、六青龙、七天空、八白虎、九太常、十玄武、十一太阴、十二天后。”直接支持完整线性将序。 |

《钦定四库全书·六壬大全》卷二：

- PDF 58：“以课之天盘起贵神”，并列贵人为主及前后诸将。
- PDF 59：“地盘一定顺逆之序”。
- PDF 62：以天门/地户区分顺治、逆治，并把十干昼夜取贵另列为一步。

两书相互支持：先按昼夜选天盘贵人支，再看该贵人所临地盘宫定顺逆。`landing-palace-six-zones` 与 `siku-heaven-earth-gate-direction` 是逐支明文和原则解释，不是互斥流派。

## Negative Evidence

《六壬大全》卷一 PDF 100 对先天贵神图“昼顺行、夜逆行”明言“其说甚有理，而近不用”。该页只能证明存在旧说，不能授权当前昼夜顺逆实现。

## Noble Table Conflict

《直指》PDF 18 的完整表与当前表在甲、乙、丙、辛、壬五干的阳/阴次序互换。当前 `jiaDayAlt` 只改甲日，既不代表该版本，也没有独立来源；不得继续作为“古籍异文”执行开关。

主底本固定转录仍有支持当前表的线索：`liuren-11-transcript.md:643,647,651` 与 `liuren-12-transcript.md:13,463-469`。这些必须回到对应影印页由不同 reviewer 二审，本任务不据转录裁决 002/003。

## Catalog Recommendation

- `dlr.source.yuding-liuren-zhizhi-candidate` 可升 `scanVerified`，但保持 supplement、版本真伪限制，不升 approved。
- 001、004、005 具备 B 直接证据；006 的“两个坐标职责”具备直接上下文，但两张 map 是项目契约。
- 002、003 保持 C/pending；不使用 `jiaDayAlt` 表示《直指》。
- direction variant 采用六区方法，并合并《直指》逐支明文与《大全》天门地户原则。
- 三张 approved《指南》例只覆盖昼贵：壬寅日癸卯时巳临卯顺、乙未日己卯时子临巳逆、庚寅日庚辰时丑临卯顺。缺夜贵顺/逆批准 fixture，完整算法保持 `executableApproved=false`。
- adopted/B/catalog 行为变化需提升 `daliuren-classics/1.0.0`。

