# Qimen Analysis Source Audit

Audit date: 2026-07-28

## Admission Policy

- Public-domain texts authorize named facts and worked-example expectations.
- A classical statement does not by itself authorize the product's four-value
  aggregate verdict. Verdict rows and question-focus mappings remain labeled
  `projectConvention`.
- Where two texts disagree, v1 either records the adopted formula and the
  alternate reading, or keeps the rule contextual. It must not silently pick a
  variant inside an evaluator.
- Wikisource transcription is a discoverable public locator, not a critical
  edition. Rule metadata must say this and keep a fixed revision URL.
- Examples with only a day-stem pair such as `甲己日` are source-backed rule
  examples, not exact historical pan goldens. Any completed schema-v1 pan made
  from them must disclose the chosen representative day pillar and manual
  adjudication.

## Fixed Public Sources

| Source ID | Work and scope | Fixed public locator |
|---|---|---|
| `QMS-CLASSIC-TONGZONG` | 《奇门遁甲统宗》: 钓叟歌、三遁、击刑、入墓、五不遇、伏反吟、十干格与实例 | https://zh.wikisource.org/w/index.php?title=%E5%A5%87%E9%96%80%E9%81%81%E7%94%B2%E7%B5%B1%E5%AE%97&oldid=1378608 |
| `QMS-CLASSIC-YANYI` | 程道生《遁甲演义》: exact formation formulas and worked ju/day/hour examples | https://zh.wikisource.org/w/index.php?title=%E9%81%81%E7%94%B2%E6%BC%94%E7%BE%A9&oldid=2082234 |
| `QMS-CLASSIC-YUANLING` | 《奇门遁甲元灵经》: worked wealth, study, career, lost-person, lost-property, visit and military examples | https://zh.wikisource.org/w/index.php?title=%E5%A5%87%E9%96%80%E9%81%81%E7%94%B2%E5%85%83%E9%9D%88%E7%B6%93&oldid=1378607 |
| `QMS-CLASSIC-BAOJIAN` | 《奇门宝鉴御定》: 三奇游六仪、九星旺相与玉女守门交叉核验 | https://zh.wikisource.org/w/index.php?title=%E5%A5%87%E9%97%A8%E5%AE%9D%E9%89%B4%E5%BE%A1%E5%AE%9A&oldid=2353651 |
| `QMS-CLASSIC-TUSHU-707` | 《古今图书集成》艺术典卷七百七: 门迫、三遁、三奇入墓、五不遇、诸凶格及专题占断 | https://zh.wikisource.org/w/index.php?title=%E6%AC%BD%E5%AE%9A%E5%8F%A4%E4%BB%8A%E5%9C%96%E6%9B%B8%E9%9B%86%E6%88%90%2F%E5%8D%9A%E7%89%A9%E5%BD%99%E7%B7%A8%2F%E8%97%9D%E8%A1%93%E5%85%B8%2F%E7%AC%AC707%E5%8D%B7&oldid=1942670 |

Accessed on 2026-07-28. The first three works count as the two-or-more
independent public source requirement; the 图书集成 transcription is supporting
cross-check evidence and may reproduce earlier material.

## Admitted Formula Cross-Checks

| Family | v1 formula supported by the fixed texts | Boundary |
|---|---|---|
| 九星旺相休囚废 | 《遁甲演义》明载“与我同行即为相，我生之月诚为旺，废于父母休于财，囚于鬼”。以星为“我”：同五行=相，星生月令=旺，月令生星=废，星克月令=休，月令克星=囚。 | 不能套用八门余气顺序，也不能把“废”改写成“死”。月令按持久化月柱支：寅卯木、巳午火、申酉金、亥子水、辰未戌丑土。 |
| 八门旺相休囚废 | 《奇门遁甲统宗》载“当时者为旺，我生者为相，我克者为休，克我者为囚，生我者为废”。以月令为“我”：同五行=旺，月令生门=相，月令克门=休，门克月令=囚，门生月令=废。 | 这是季令余气；门宫比和/生克与门迫是另外两组事实，不能用门宫关系冒充八门旺衰。 |
| 门迫 | Door element restrains its palace element. 卷707 explicitly gives 开门临震/巽、休门临离、生门临坎 as adverse examples. | A palace restraining its door is not this rule. Seasonal state is a separate fact. |
| 六仪击刑 | The xun hidden instrument is punished in its named palace: 戊/震, 己/坤, 庚/艮, 辛/离, 壬/巽, 癸/巽. | Evaluate the persisted `xunHiddenStem` occurrence; hosted facts remain separate. |
| 三奇入墓 | 乙临坤二、丙临乾六、丁临艮八. | Some passages also describe stem/hour tomb language. v1 keeps palace formation and time-stem condition as distinct facts. |
| 三遁 | 天遁=丙+生门+丁, 地遁=乙+开门+己, 人遁=丁+休门+太阴/丙 as stated by the selected passage. | Text witnesses differ on the lower component of 人遁; v1 must record its adopted witness and alternate, not merge them. |
| 五不遇时 | Hour stem restrains day stem in the fixed pairs beginning 甲日庚时、乙日辛时、丙日壬时、丁日癸时、戊日甲时 and their cycle continuation. | Uses persisted day/hour pillars only. It is not every generic stem restraint. |
| 伏吟/反吟 | Same star/door returns to its origin is 伏吟; opposing palace is 反吟. Star and door facts are recorded separately before any combined fact. | Never infer by parsing derivation display text. |
| Four adverse pairs | 乙+辛 青龙逃走, 辛+乙 白虎猖狂, 丁+癸 朱雀投江/入江, 癸+丁 螣蛇夭矫. | Preserve witness spelling as source metadata; stable rule IDs do not change with display wording. |
| Fire/metal pairs | 丙+庚 荧入太白, 庚+丙 太白入荧. | Direction is heaven stem over earth stem. |
| 庚格 families | 庚+癸 大格, 庚+壬 小格, 庚+己 刑格; day stem and duty interactions have separate 飞干/伏干/飞宫/伏宫 rules. | Do not collapse all 庚 combinations into one adverse tag. |
| 天网四张 | 癸 related to the hour/duty formation per the admitted witness, with low/high palace affecting traditional release language. | Because readings vary, v1 may keep it conditional/contextual unless the exact predicate is source-locked. |

Additional formula corrections locked by the same witnesses:

- `乙`奇/仪入墓 is 坤二 (`未`墓), not 乾六. The remaining adopted
  palace table is 丙戊->乾六, 丁己庚->艮八, 辛壬->巽四, 癸->坤二.
- `庚加值符` and `值符加庚` use the persisted `xunHiddenStem`, not the
  calendar day stem. The former is 天乙伏宫, the latter is 天乙飞宫.
  `庚加日干`/`日干加庚` are separate 伏干/飞干 relations.
- “天网四张时加癸” is an hour-stem/duty condition. A generic `癸加癸`
  heaven/earth pair is not an equivalent predicate.

## Source-Backed End-to-End Case Seeds

These are candidate sourced cases for the typed golden manifest. Each frozen
fixture must contain a complete, fixed-ID schema-v1 `QimenResult` JSON object;
the analysis test restores it through `QimenResult.fromJson` and must never
call `QimenSystem.cast` or a pan-stage service.

| Case ID | Public worked example | Expected source assertion |
|---|---|---|
| `QM-G01` | 《遁甲演义》阳遁一局甲子时 | Star/door 伏吟; conservative delay context. |
| `QM-G02` | 《遁甲演义》大寒上元阳遁三局，甲己日丙寅时 | 庚加己刑格. |
| `QM-G03` | 《遁甲演义》小满上元阳遁五局，丙辛日戊戌时 | 丙加庚，荧入太白. |
| `QM-G04` | 《遁甲演义》清明上元阳遁四局，甲己日壬申时 | 庚加丙，太白入荧. |
| `QM-G05` | 《遁甲演义》小满上元阳遁五局，甲申日壬申时 | 庚临日干，天乙伏干格. |
| `QM-G06` | 《遁甲演义》小满上元阳遁五局，甲己日庚午时 | 日干临庚，飞干格. |
| `QM-G07` | 《遁甲演义》立春下元阳遁二局，甲己日壬申时 | 庚临值符，天乙伏宫格. |
| `QM-G08` | 《遁甲演义》春分中元阳遁九局，甲己日庚午时 | 值符临庚，天乙飞宫格. |
| `QM-G09` | 《遁甲演义》阴遁四局，丙辛日庚寅时 | 丙奇临乾，三奇入墓. |
| `QM-G10` | 《奇门遁甲元灵经》惊蛰中元阳遁七局，丁壬日壬寅时，占财 | 生门体克天蓬用但门囚且辛加壬，财有而所得微；not a simple favorable verdict. |
| `QM-G11` | 《奇门遁甲元灵经》立秋上元阴遁二局，甲己日壬申时，占财 | 时干、甲子戊、生门同兑内盘，source says gain is quick. |
| `QM-G12` | 《奇门遁甲元灵经》大寒中元阳遁九局，乙庚日庚辰时，占走失人口 | 时干与六合都在内盘，坎宫潜藏，source says not lost. |
| `QM-G13` | 《奇门遁甲元灵经》大暑中元阴遁一局，戊癸日壬戌时，占失物 | 甲子戊在震、无玄武、非空，east/卯 window and 击刑 damage. |
| `QM-G14` | 《奇门遁甲元灵经》清明上元阳遁四局，乙庚日丙子时，占援兵 | 天英生天禽、庚受克；source says援兵有声势、守方无虞. |
| `QM-G15` | 《奇门遁甲元灵经》秋分中元阴遁一局，丁亥日乙巳时，占文章 | 天辅与丁在艮，source assigns the lower successful rank; use as study-category source evidence. |
| `QM-G16` | 《奇门遁甲元灵经》六己年大寒上元阳遁三局，丙申日乙未时，占升迁 | 开门在兑得相、奇合、太岁天辅来生，source says主升无疑. |

At least 12 of these may be admitted after the completed pan JSON is manually
checked against the cited formula. The catalog must not claim that a modern
representative year/month pillar is part of the classical example when the
source omits it.

## Implementation Hazards Found During Audit

1. `QimenResult` exposes a static schema version, not a per-instance field.
   `analyze(QimenResult)` cannot observe a future pan schema. Future-schema
   diagnostics therefore belong at a raw JSON/reopen boundary or require an
   explicit raw-input analyzer entrypoint; tests must not fake this through a
   current typed result.
2. The existing public pan fixture contains cast inputs and partial expected
   palace fields, not a full fixed result JSON. Analysis goldens need a new
   complete schema-v1 fixture with a fixed result ID. Recasting in the test
   would violate the read-only analysis boundary and introduce random UUIDs.
3. Classical strength tables and some 人遁/天网 wordings differ. Source
   quality may determine rule admission, but it must never become a numeric
   confidence or auspiciousness weight.
