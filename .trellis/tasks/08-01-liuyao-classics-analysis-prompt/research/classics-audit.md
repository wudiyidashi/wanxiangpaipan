# Research: 六爻古籍材料与规则来源审计

- Query: 审计仓库文档、资产、历史任务、Git 历史、fixture 与测试中已有的六爻古籍材料、引文、占例和领域决策；确认可核来源、证据缺口，以及系统化分析应覆盖的规则族。
- Scope: internal
- Date: 2026-08-01

## Findings

### 1. 结论摘要

1. 六爻域内明确具名并承担规则依据的古籍只有《增删卜易》和《卜筮正宗》。前者被定为主裁决基准，后者只补充三刑、相害；见 `.trellis/spec/domain/liuyao-analysis-engine.md:6`、`:10`。
2. 仓库没有六爻古籍底本、扫描件、电子文本、source registry 或 `assets/data/liuyao/classics/`。当前所有“古籍依据”都是代码注释、规格转述、术语释义和测试元数据。全库文件与 Git 对象历史中也未发现《增删卜易》或《卜筮正宗》的 PDF/EPUB/TXT/HTML 底本。
3. 最强的本地案例证据是 `verdict_golden_test.dart` 的 40 例：当前锁定为 26 个“原书占例”和 14 个“章法校验例”，带章节名及《增删卜易（校对：中国男儿）》印刷页 21-62 的定位；见 `test/unit/services/liuyao/analysis/verdict_golden_test.dart:18`、`:72`、`:910`。这些仍是转述和 locator，不是可回看底本的逐字证据。
4. 现有分析能力已经覆盖主要状态规则，但证据合同不足：`YaoAnalysisTag` 没有稳定规则 ID、规则版本、来源引用或冲突 trace（`analysis_tag.dart:9`）；术语词典也只有定义/条件/含义三个字段（`term_glossary.dart:1`）。
5. 四值裁决、`strong/weak/mixed` 分类、L1/L2/L4 分层和首行命中决策表是项目为了确定性而形成的综合裁决机制；本地没有古籍原文证明整张软件决策表。当前却把最终命中行统一标成“《增删卜易》断法总论”（`verdict_service.dart:174`、`:230`），应拆为“古籍规则证据”和“项目综合裁决”两层。
6. AI 当前拿不到已有的 `VerdictFactor.source`。formatter 只输出卦/爻标签、用神位置、应期和摘要（`liuyao_formatter.dart:142`-`:173`），没有输出 `judgment.factors`；因此提示词即使要求古籍引用，也没有足够的结构化来源可引用。

### 2. 审计方法与证据边界

- 用 `rg` 检索全库古籍名、书名号、原文/占例/页码/来源等标记，并逐一查看六爻 domain、formatter、prompt 和 tests。
- 用 `rg --files` 与扩展名过滤检查 `assets/`、`docs/`、`tmp/` 及工作树中的 PDF/EPUB/MOBI/TXT/HTML；没有发现六爻原典文件。未读取任何凭据文件。
- 用 `git log -S`、`git log --name-only`、`git rev-list --objects --all` 检查历史上是否曾提交相关底本。古籍名首次随代码/任务文档进入历史，没有底本或独立研究材料随同进入。
- 本审计没有调用外部网页，也没有据常识补写作者、年代、版本或原文。下述“原书占例”只表示仓库自己的分类。

### 3. Files found

| 文件 | 本地作用 |
|---|---|
| `.trellis/spec/domain/liuyao-analysis-engine.md` | 当前六爻分析权威口径；锁定主/补充古籍、核心规则、裁决与测试构成。 |
| `.trellis/tasks/archive/2026-07/07-22-liuyao-analysis-engine/{prd.md,design.md,implement.md}` | 第一阶段分析引擎范围和“《增删》主干、《卜筮》低权重补充”的原始任务决策。 |
| `.trellis/tasks/archive/2026-07/07-25-liuyao-verdict-engine/{prd.md,design.md,implement.md}` | 四值裁决、力量层级、悬置转条件、40 例 review gate 和已知转述风险。 |
| `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart` | 当前唯一编排入口及确定性阶段顺序。 |
| `lib/domain/services/liuyao/analysis/models/analysis_tag.dart` | 十类标签合同；当前无 rule/source/version 字段。 |
| `lib/domain/services/liuyao/analysis/models/term_glossary.dart` | 约百个术语/别名的定义、成立条件、吉凶含义；只有词典级总括出处。 |
| `lib/domain/services/liuyao/analysis/verdict_service.dart` | 受力、元忌活跃性、悬置条件和四值首行命中裁决；含书名/章节字符串。 |
| `lib/domain/services/liuyao/analysis/ying_qi_service.dart` | 旬空、月破、墓、合、动静、化变等应期候选。 |
| `test/unit/services/liuyao/analysis/verdict_golden_test.dart` | 40 个本地黄金断例，当前最细的章节/页码 locator。 |
| `test/unit/services/liuyao/analysis/*_test.dart` | 各规则正反例，但多数是项目构造 fixture，不是外部古籍案例。 |
| `lib/ai/output/formatters/liuyao_formatter.dart` | AI 实际看到的六爻结构化文本；当前未投影来源链。 |
| `lib/ai/template/builtin_templates.dart` | 当前分析顺序、用神问题映射、六神解释和输出结构。 |
| `docs/architecture/divination-systems/liuyao.md` | 排盘事实与少量分析边界；没有古籍书目或页级来源。 |
| `.trellis/tasks/archive/2026-07/07-28-qimen-analysis-engine/prd.md` | 后续项目已明确记录：六爻/六壬标签缺稳定 ID、完整来源、冲突和全链 trace，不能照搬该不足（`:15`-`:17`）。 |
| `assets/data/daliuren/classics/schema/{source.schema.json,rule.schema.json}` | 同仓库可复用的证据治理先例：source、页码映射、短引、reviewer、证据等级、adopted/executable 状态。 |
| `lib/domain/services/qimen/analysis/rules/qimen_source_catalog.dart` | 同仓库另一先例：稳定 source ID、资料种类、版本/revision、locator、访问日期、摘义和项目裁定。 |

### 4. 古籍与相关名目清单

| 名目 | 仓库中的角色 | 精确本地锚点 | 当前可信边界 |
|---|---|---|---|
| 《增删卜易》 | 六爻事实规则及裁决的主基准 | spec `liuyao-analysis-engine.md:6`-`:24`；各 service 文件头；`verdict_service.dart:51`-`:61`；40 例 `verdict_golden_test.dart:83`-`:879` | 只有书名、归一化章节名、转述和单一校对本页码。没有版次、出版信息、文件 hash、URL、访问日期、卷页映射、短引或复核者。若沿用仓库 A-D 门禁，只能先按 locator-only 管理，不能直接视为可执行古籍证明。 |
| 《增删卜易（校对：中国男儿）》 | 40 例使用的唯一具名“校对本” | `verdict_golden_test.dart:72`-`:75`；唯一全库命中 | 没有任何书目元数据或可访问定位；“印刷页”无法从仓库独立复核。名称只存在于测试描述 getter。 |
| 《卜筮正宗》 | 三刑、相害的补充依据，低优先级且不参与主判 | spec `liuyao-analysis-engine.md:10`、`:22`；`he_chong_service.dart:7`-`:13`；`dizhi_relations.dart:3`-`:5`；`term_glossary.dart:176`-`:185` | 仅书名级 attribution；没有章节、页码、短引、版本和外部占例。行为测试存在，但不能反向证明古籍来源。 |
| “京房易学” | AI system prompt 对纳甲体系的谱系标签 | `lib/ai/template/builtin_templates.dart:25`-`:31` | 不是具名版本或可核文献，不应作为引用输出。 |
| “周易/周易理论” | 产品描述与 AI 角色文案 | `liuyao_system.dart:39`；`builtin_templates.dart:23` | 泛称，不是本仓库的规则 source。 |
| 《月将章》《旬空章》《六合章》《进退章》等 | 章节 locator 或项目归一化章节标签 | `verdict_golden_test.dart` 的 `sourceChapter`；`verdict_service.dart:51`-`:61` | 不是独立书目。部分 service 使用“合冲章/动变章/卦变章/断法总论”等宽泛归类，仓库未证明这些字符串与所称校对本目录逐字一致。 |

全库六爻范围内没有发现《黄金策》《千金赋》《易隐》《易冒》《火珠林》《断易天机》《卜筮全书》《易林补遗》等其他具名书目的引用或本地材料。此结论只说明“仓库未发现”，不评价其领域价值。

### 5. 《增删卜易》40 例库存

#### 5.1 数据结构与构成

- `_GoldenCase` 保存 `nature/question/yueJian/riGanZhi/hexagram/movingLines/numbers/position/yongShen/sourceChapter/printedPages/adjudication/expected*`，见 `verdict_golden_test.dart:21`-`:70`。
- 当前来源构成由测试锁定为至少 26 个原书占例和 14 个章法校验例，且总数必须等于全部案例；见 `verdict_golden_test.dart:910`-`:922`。
- 具体分类为：
  - 原书占例：ID 7、9、11-34，共 26。
  - 章法校验例：ID 1-6、8、10、35-40，共 14。
- 页码 locator 覆盖该校对本印刷页 21-62。章节/定位覆盖：月将、日辰、旬空、月破、六合、五行相生、五行相克、克处逢生、进退、生旺墓绝、随鬼入墓、飞伏神、用神/元神/忌神/仇神、动变生克冲合、各门类应期总注等。
- 原书例分布明显集中：ID 20-32 共 13 例全部来自“进退章”，占 26 个原书例的一半。飞伏、完整三刑/相害、问题分类/取用、六神象意等没有原书占例覆盖。
- `adjudication` 是项目中文转述，有些包含“后蒙恩免死”“未迁而午月遭河决”“满载而归”等结果叙述（例如 `verdict_golden_test.dart:304`-`:316`、`:361`-`:373`、`:400`-`:412`），但没有 `shortQuote`/原文/影印页证据字段，不能称为逐字引文。

#### 5.2 测试实际证明什么

- 运行输入只消费 `numbers/yueJian/riGanZhi/position/isFuShen`；`hexagram/movingLines/yongShen/sourceChapter/printedPages/adjudication` 不参与引擎输入，见 `verdict_golden_test.dart:895`-`:907`。
- 元数据测试只检查这些字符串非空，不核对：
  - 描述卦名是否等于 `GuaCalculator` 算出的卦名；
  - 描述动爻是否等于 `numbers`；
  - 取用文字是否等于选中爻；
  - 章节/页码是否真实存在；
  - `adjudication` 是否为原书原断。
  见 `verdict_golden_test.dart:932`-`:963`。
- 黄金断言只验证程序的 trend、可选 nuance、条件、factor 名和应期地支是否命中本地期望，见 `verdict_golden_test.dart:968`-`:994`。它证明“当前程序与当前夹具一致”，不独立证明古籍转述正确或现实预测准确。
- 各服务 fixture 通过生产 `GuaCalculator` 生成盘（`analysis_fixtures.dart:9`-`:14`），不是与生产代码独立的手工冻结盘面 oracle。
- 推理链来源测试只要求每个 `source` 字符串包含“《增删卜易》”（`verdict_service_test.dart:320`-`:326`）；错误章节、错误页码或把项目裁决冒充古籍仍可能通过。

#### 5.3 Git 历史

- `489c3a1`：首次引入 11 个分析 service、词典、formatter 分析段和大量单测。
- `91591d7`：引入四值裁决与首版黄金断例。
- `6c7b16d`：一次性扩为 40 例并修正五处裁决偏差；同一提交没有新增古籍 source 文件或独立 research artifact。
- `f97e41d`：把当前来源构成和连续编号变成测试门禁，权威口径改为 26+14。
- `6c7b16d` 的 commit message 和 `.trellis/workspace/yuekai/journal-1.md:118`-`:126` 仍写“29 原书 + 11 校验”，与当前测试/spec 的 26+14 不一致。当前应以 `f97e41d` 后的测试与 `.trellis/spec/domain/liuyao-analysis-engine.md:47` 为准，并把历史文案视为已过期记录。

### 6. 已实现规则族与来源状态

| 分析阶段/规则族 | 当前实现 | 本地锚点 | 来源状态 |
|---|---|---|---|
| 排盘事实归一化 | 月日、空亡、本变卦、八宫、纳甲、六亲、世应、六神 | `docs/architecture/divination-systems/liuyao.md:143`-`:168`；`liuyao_formatter.dart:32`-`:57` | 属程序输入/排盘合同；当前没有逐规则古籍 source。 |
| 日月旺衰 | 临月/日建、月破、月/日生克扶、旺相休囚死 | `wang_shuai_service.dart:20`-`:30` | 仅书名级《增删》总括。 |
| 空亡 | 旬空、真空、假空、冲空，填实/出空交给应期 | `kong_wang_service.dart:8`-`:14` | 有《增删》转述，无章节页级 source。 |
| 墓绝/十二长生 | 日/月/动墓、出墓、临绝；化墓/绝由动变处理 | `mu_jue_service.dart:8`-`:13`；`chang_sheng_table.dart:27` | 有书名级 source；表口径无逐条证据。 |
| 合冲刑害/三合 | 合住、合起、合绊、冲开、相冲、三合/半合、刑害 | `he_chong_service.dart:7`-`:14` | 主体归《增删》；刑害归《卜筮》。分类级 source 无法表达同一 category 中的不同书目。 |
| 动静与化变 | 暗动、日破/冲散/催动、独发独静、进退、回头生克、化空破墓绝合冲 | `dong_bian_service.dart:10`-`:18` | 《增删》书名级；“化合=化扶”等有页码占例但无原文。 |
| 爻间生克与遮蔽 | 动生/克/扶、贪生忘克、贪合忘生克、连续生克 | `sheng_ke_service.dart:8`-`:14` | 《增删》转述；无稳定 rule/source。 |
| 用神角色链 | 用神、元神、忌神、仇神、闲神、两现、伏神取用 | `liu_qin_deduce_service.dart:7`-`:12`、`:44`-`:106` | 基础关系有总括，具体“同六亲动爻优先、再低爻位”的 tie-break 没有 source，应先视为项目口径。 |
| 飞伏 | 飞生/克伏、伏生/克飞、得出、受制 | `fu_shen_relation_service.dart:9`-`:14` | 只有《增删》转述；黄金覆盖均为章法校验例，无原书例。 |
| 日月太岁特殊作用 | 日合、月合、太岁入爻 | `special_service.dart:7`-`:13` | category source 统一映射为“日辰章”，不能精确覆盖太岁等不同规则。 |
| 卦级变化 | 六冲/六合/游魂/归魂、变六合/六冲、伏吟反吟 | `gua_change_service.dart:5`-`:9`、`:16`-`:58` | 只有书名级 source；“主成/主散”等含义没有页级依据，也没有进入程序裁决的显式冲突规则。 |
| 条件与应期 | 空、破、墓、合、静动、进神、化空破墓等触发窗口 | `ying_qi_service.dart:9`-`:14`、`:44`-`:105` | 多条规则共用书名级说明；每个候选没有 source/rule ID。 |
| 综合裁决 | 日月 > 动爻 > 暗动 > 变爻；强弱三分；元忌活跃；悬置转条件；四值首行命中 | `verdict_service.dart:10`-`:18`、`:22`-`:62`、`:115`-`:234` | 古籍规则与项目算法混在一起。最终行被统一署为《增删》“断法总论”，证据不足。 |

### 7. 既有领域决策（后续不能静默推翻）

- 流派分歧以《增删卜易》为主，《卜筮正宗》刑害只作低优先级参考，不参与主判：`liuyao-analysis-engine.md:6`-`:24`。
- 近义术语归并，不为“化扶/冲起/冲实/冲脱”重复建立主标签：`liuyao-analysis-engine.md:25`。
- 动爻和本位变爻的生克、合冲关系可并存；变爻不跨位作用本卦其他爻。该段明确含“用户口径”，不能整体冒充古籍原文：`liuyao-analysis-engine.md:27`。
- 先判用神状态/趋势，再生成空破合墓等解除条件；不能按标签数判吉凶，伏神取用必须分析伏神自身：`liuyao-analysis-engine.md:29`。
- 裁决是分类决策表，不是加权打分；四值为可成/难成/待条件/趋势不明：`liuyao-analysis-engine.md:31`-`:47`。
- 分析报告运行时派生、不落库：`liuyao-analysis-engine.md:49`-`:61`。
- 上一任务明确把“问事类别自动取用、象法/外应/神煞参与裁决、term 枚举化”排除在范围外：`.trellis/tasks/archive/2026-07/07-25-liuyao-verdict-engine/prd.md:47`-`:52`。本任务若纳入，必须作为新范围显式设计和验收。

### 8. 系统化分析应覆盖的核心规则族

下表把“现有服务族”和“当前仍由 AI 猜测或没有来源合同的族”合并为一条固定顺序。它是仓库证据推导出的工程覆盖建议，不声称是某部古籍的原文目录。

| 顺序 | 规则族 | 程序应提供的确定性输出 | 当前状态/缺口 |
|---:|---|---|---|
| 0 | 输入完整性与盘面事实 | 起卦方式、年月日时/月建日辰/空亡、本变卦、动爻、八宫、纳甲、六亲、世应、六神、伏神；字段来源和排盘版本 | 排盘已有，分析报告无输入版本/字段引用；黄金例也未冻结独立盘面 oracle。 |
| 1 | 问事归类与取用 | 问事 category、人物角色、主用神/辅用神、世应角色、两现取舍、伏神取用、无法唯一取用的保守状态 | 程序仍要求用户点选；AI 只凭六条简化映射取用（`builtin_templates.dart:142`-`:162`）。需来源化类别表，并把项目 tie-break 分开标注。 |
| 2 | 用神根基与日月旺衰 | 月令等级、月破、日辰生克扶冲、太岁等，区分事实与解释 | 已实现；需逐规则 source ID、locator 和适用边界。 |
| 3 | 空亡、墓绝和其他悬置状态 | 真/假空、冲空、日/月/动/变墓、绝、已有解除与无救状态 | 已实现；需按条件而非静态吉凶输出，并为每个解除规则关联 source。 |
| 4 | 动静与化变 | 明动/暗动/日破/冲散、独发独静、回头生克、进退、化空破墓绝合冲及并存关系 | 已实现；需把用户/项目口径与古籍依据拆开。 |
| 5 | 爻间作用与遮蔽 | 生克扶、合冲、三合/半合、贪生/贪合、连续作用、刑害及被合/被制后的有效性 | 已实现；需要显式冲突/压制 trace，尤其刑害的第二书目来源。 |
| 6 | 用神体系与飞伏 | 元神、忌神、仇神、闲神活跃性，飞伏生克、出伏、受制 | 已实现基础链；取用和多候选策略仍不完整，飞伏缺原书案例。 |
| 7 | 卦级、世应与六神辅助层 | 六冲六合/游魂归魂/伏吟反吟、世应双方关系、六神与神煞象意；明确是主判、辅助还是仅描述 | 卦级标签存在；世应/六神主要交给 AI。日神煞表无古籍 source（`liuyao_shen_sha_service.dart:3`-`:19`），上一任务又明确不让神煞参与裁决。 |
| 8 | 问事类别专属规则 | 财、官、婚恋、疾病、考试、行人、诉讼、子嗣等各自的主辅角色、成立/失败条件和禁用边界 | 40 例问题多样但没有稳定 category taxonomy、类别规则目录或覆盖门禁。当前 prompt 的几条映射不能充当完整规则库。 |
| 9 | 证据冲突与综合裁决 | active/suppressed facts、胜出规则、古籍证据、项目裁决行、四值结论、未决条件 | 已有首行决策表但无稳定行 ID/版本/冲突 trace，且项目综合逻辑被笼统署为古籍。 |
| 10 | 应期与尺度 | 条件来源、日/月/年尺度、触发支、解除何种状态、与结论的边界 | 已有候选，但每项无 rule/source/condition ID；年尺度实现与原书例覆盖有限。 |
| 11 | 输出证据链与风险边界 | 主结论、支持/反证、未决条件、应期、使用的 source、直接引文或转述类型、项目采用说明 | 当前 AI 只收到标签和摘要，收不到 factors/source；没有禁止伪造原文/页码的结构化 guard。 |

### 9. 主要 provenance / reliability gaps

1. **无 source registry**：书名、版本、馆藏/URL、revision、访问日期、页码体系和 rights/limitations 均未登记。
2. **无逐规则 ID 与版本**：`YaoAnalysisTag` 只有 `term/category/polarity/priority/reason/relatedYao`（`analysis_tag.dart:31`-`:40`）；术语改名会直接影响裁决和应期字符串消费。
3. **无逐条短引和引文类型**：不能区分逐字原文、现代校对、项目转述、章法推演和软件约定。
4. **类别级 source 过粗**：`verdict_service.dart:51`-`:62` 以 `TagCategory` 映射章节，无法表达一类中不同规则来自不同书，也无法表达异文或多来源。
5. **项目裁决冒充古籍风险**：四值、强弱三分类、L1/L2/L4、首行命中是明确的软件收敛设计（verdict task design `:135`-`:142`），应有 `projectConvention` source，而非统一写“断法总论”。
6. **单一底本/无独立复核**：40 例只引用一个未登记的校对本；没有第二版本、公开 locator 或 reviewer 记录。
7. **黄金测试元数据弱约束**：只查非空，不查盘面描述/页码/原断与实际输入一致，也没有 unknown 字段或证据等级。
8. **源例覆盖不均**：一半原书例集中在进退章；《卜筮正宗》、飞伏、六神、问事取用、刑害没有页级原书例。
9. **AI 来源链丢失**：`VerdictFactor` 虽有 `source`（`verdict_models.dart:37`-`:50`），formatter 没有投影 factors；prompt 无法可靠引用。
10. **自由解释面过大**：prompt 要求 AI 解释卦名基本含义、世应和六神（`builtin_templates.dart:83`-`:111`），但这些解释没有结构化规则或来源，容易生成不可核古籍说法。
11. **历史记录有漂移**：29+11 与 26+14 的记录不一致，证明来源元数据也需要 validator 和单一事实源。
12. **现实结果不是当前验收**：原书结果转述只能用于历史文本对照和规则一致性，不能证明现实预测准确率；当前 task PRD 也明确排除用单次输出证明客观预测准确率。

### 10. 建议的最小证据合同

仓库已经有可直接参照的合同，不需要重新发明：

- `assets/data/daliuren/classics/schema/source.schema.json:20`-`:81` 定义远程文件和扫描/印刷/PDF 页码映射。
- `assets/data/daliuren/classics/schema/rule.schema.json:52`-`:84` 定义 `sourceRef`、定位、`shortQuote` 和 reviewer；`:86`-`:166` 定义稳定 rule ID、采用状态、证据等级、locator-only、可执行批准、fixture 和目标代码域。
- `qimen_source_catalog.dart:15`-`:80` 区分古籍、公开占例和项目约定，并记录版本/revision、locator、摘义、裁定说明和访问日期。

六爻最少应登记：

`sourceId`、资料种类、题名、版本/校对者/出版或固定 revision、可访问 locator、页码映射、访问日期、限制；以及每条 `ruleId` 的规则族、适用条件、优先级、`sourceRefs`、必要短引、释义、采用/排除/争议状态、证据等级、是否可执行、项目裁定、正反 fixture ID。

对 40 例另需：稳定 `caseId`、`caseKind=original|ruleValidation|syntheticBoundary`、source/页码、原文短引或明确 `paraphrase`、原始已知输入、unknown 字段、人工盘面、项目取用裁定、期望事实/规则/结论/应期、reviewer。生产 `GuaCalculator` 可复算盘，但不能成为唯一 oracle。

### 11. AI 提示词可安全使用的来源边界

在 source registry 和底本复核完成前，提示词应遵守以下限制：

- 不要求或允许模型背诵、补写古籍原文；没有 `shortQuote` 就只能称“项目转述/采用口径”。
- 不让模型自行给出书名、章节、页码。只能引用输入中提供的稳定 source ID 和 locator。
- 明确区分“原书占例转述”“章法校验例”“项目裁决规则”，不能把后三者写成原书实占或逐字古法。
- AI 只解释程序传入的 active facts、suppressed facts、裁决行和应期条件；不得重排、重算或用自由联想覆盖程序结论。
- 六神、卦义、世应象意、神煞等没有来源化事实时，只能标成辅助解释或省略，不能成为决定性反转依据。
- 应期必须关联具体未决条件和 source/rule ID，并继续声明它是观察/解除窗口，不保证事件发生或自动转吉。
- 若 source 缺失、冲突未裁定或取用不唯一，输出“证据不足/趋势不明”，不得伪造确定结论。

### 12. Related specs and prior decisions

- `.trellis/spec/domain/liuyao-analysis-engine.md`：当前六爻行为真相源。
- `.trellis/spec/guides/cross-layer-thinking-guide.md`：本任务会跨 domain report、formatter、prompt、UI/test，来源字段必须端到端保留。
- `.trellis/tasks/archive/2026-07/07-28-qimen-analysis-engine/prd.md:27`-`:39`、`:68`-`:78`：稳定规则/来源、冲突、AI 边界和版本化的成熟要求。
- `.trellis/tasks/archive/2026-07/07-28-daliuren-classics-evidence/prd.md:14`-`:25`：影印页、locator-only、证据等级和“不以 OCR/当前代码自证”的成熟门禁。

### 13. External references

本研究未使用外部网页、在线古籍或出版物。没有可在此阶段可靠登记的外部版本信息或逐字引文；外部底本检索与页级复核应作为单独研究项完成并落盘，不能由本地书名字符串推断。

## Caveats / Not Found

- 未发现六爻古籍原典、扫描件、OCR、书目清单、source manifest、rule manifest、variant registry 或证据 validator。
- 未发现《卜筮正宗》的章节/页码/短引或任何页级 fixture。
- 未发现能证明《增删卜易（校对：中国男儿）》具体版本身份的本地元数据。
- 未发现 40 例的独立人工复核记录、第二 reviewer 或第二版本交叉校验。
- 未发现逐条规则的未命中/不适用 trace、异文记录、稳定决策行 ID 或分析规则版本。
- 未发现 AI 输出中实际呈现古籍 source/factor 的 formatter 测试。
- 本研究没有执行测试，以避免研究角色在指定 research 目录外产生构建写入；结论来自静态代码、任务文件和 Git 历史审计。
