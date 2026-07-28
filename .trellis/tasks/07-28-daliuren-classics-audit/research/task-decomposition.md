# Research: 大六壬完整审校任务拆分与依赖图

- Query: 将“大六壬完整性与古籍对照审校”的一次性完整交付范围拆成可独立规划、实现、验证和归档的 Trellis 子任务；明确依赖顺序、文件责任边界、逐子任务验收、父任务集成门禁及 implement/check 上下文。
- Scope: internal
- Date: 2026-07-28

## Findings

### 1. 结论

建议保留现有 `07-28-daliuren-classics-audit` 为父任务，新建 **17 个直接子任务**，按“证据与契约 -> 基础盘事实 -> 扩展事实与知识规则 -> 传统裁决与应期 -> 历史/UI/AI -> 父任务总验收”推进。

本范围不适合按 `domain / UI / AI` 三层横切。月将、天将、神煞、本命、类神等每一项都必须有自己的来源条目、独立预期值和服务测试；横切会让一个错误规则同时散落在多个孩子中，也无法独立判断某个知识体系是否完成。推荐的孩子以**可验收能力**为边界，最后再设一个 UI/AI 汇总孩子。

父任务当前仍为 `planning`。批量创建孩子时应使用 `--no-start`，不能因为树已建立就启动父任务。每个孩子完成 `prd.md`、`design.md`、`implement.md`、context 配置和人工评审后，才单独 `task.py start <child>`。父任务只在所有孩子归档后进入最终集成阶段，负责完整性矩阵、跨孩子验收和最终审校报告；它不应承接孩子遗漏的规则实现。

### 2. 拆分原则

1. **证据先于规则。** 所有声称“古籍规则”的实现先有影印页定位、采用口径和独立课例；OCR/转录只能检索，不能直接升级为已验证依据。
2. **先冻结可数范围。** “完整神煞”“六十四课经”“毕法百法”“类神/占类”“传统应期”必须先形成有限清单，不能用模糊完成度验收。
3. **结构先于消费者。** 稳定 `ruleId`、证据元数据、规则版本、 typed position/context 等契约先落地，后续规则不得再以中文展示词作为执行键。
4. **盘面事实先于断课。** 月将、天盘、四课、天将、三传、神煞、遁干旺相、本命行年全部稳定后，才能冻结六十四课经、毕法百法、类神和综合裁决。
5. **独立预期不复写生产算法。** fixture 应保存由影印页/人工复盘得到的输入和预期；从生产表或生产 registry 动态生成预期仍属循环测试。
6. **兼容是显式工作流。** 新记录盖版本戳，未带版本的旧记录明确标为 legacy；任何重排都生成关联的新记录，不覆盖历史快照。
7. **依赖写进孩子。** 下列边必须同时写入对应孩子的 `prd.md` 和 `implement.md`，不能靠父任务 children 顺序暗示。

### 3. Files Found

- `.trellis/tasks/07-28-daliuren-classics-audit/prd.md` - 父目标、一次性交付范围、证据与跨层验收要求。
- `.trellis/tasks/07-28-daliuren-classics-audit/research/analysis-crosslayer-audit.md` - 当前分析、UI、AI、历史契约缺陷和测试缺口。
- `.trellis/tasks/07-28-daliuren-classics-audit/research/core-pan-audit.md` - 月将、天盘、四课、天将、神煞、九宗门的规则与测试审计。
- `.trellis/tasks/07-28-daliuren-classics-audit/research/classics-source-inventory.md` - 可访问底本、固定转录和证据等级建议。
- `.trellis/tasks/07-28-daliuren-classics-audit/research/capability-matrix.md` - 并发完成的全能力现状/目标/验证矩阵；逐孩子 PRD 应引用对应行。
- `.trellis/spec/domain/daliuren-pan-engine.md` - 当前排盘口径；反吟日数、主底本表述和历史兼容条款需后续纠偏。
- `.trellis/spec/domain/daliuren-analysis-engine.md` - 当前 v1 分析契约；含待复核的六合优先和十行首中裁决。
- `.trellis/spec/domain/index.md` - Domain 纯函数与共享/系统专属服务边界。
- `.trellis/spec/frontend/index.md` - frontend spec 索引；其具体规范目前多数仍是模板。
- `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/` - 已完成父子任务树的本项目先例。
- `lib/domain/services/daliuren/` - 当前排盘与分析服务责任区。
- `lib/divination_systems/daliuren/` - 参数、持久化结果、编排、viewmodel 和 UI 责任区。
- `lib/ai/output/formatters/daliuren_formatter.dart` - 机器可读与人类可读 AI 输出契约。
- `test/unit/services/daliuren/`, `test/unit/divination_systems/daliuren/`, `test/widget/daliuren/` - 当前主要回归面。

### 4. 子任务总表

| ID | 推荐 slug | 交付边界 | 优先级 | 硬依赖 |
|---|---|---|---|---|
| C00 | `daliuren-evidence-registry` | 底本、页码、规则目录、异文决策、独立课例和完成度口径 | P0 | 无 |
| C01 | `daliuren-rule-provenance` | 稳定规则标识、证据/来源类型、pan/analysis 版本和 replay 输入契约 | P0 | C00 |
| C02 | `daliuren-cast-yuejiang` | 精确交节月将、手动四柱输入、时区和可重排输入 | P0 | C01 |
| C03 | `daliuren-pan-sike-contracts` | 十二支双射天盘、四课服务不变量、非法输入和静默兜底清理 | P0 | C02 |
| C04 | `daliuren-shenjiang-coordinates` | 贵人选择、落地宫、实际顺逆、天盘乘将/地盘落将双坐标 | P0 | C00, C03 |
| C05 | `daliuren-jiuzongmen-cases` | 九宗门全部阴阳/决胜分支和外部古例验证 | P0 | C00, C03, C04 |
| C06 | `daliuren-shensha-complete` | typed 起例/位置模型和核定底本下的有限完整神煞集 | P0 | C00, C02, C05 |
| C07 | `daliuren-chuan-derived-facts` | 三传旬遁干、旺相休囚、日干关系等派生事实 | P1 | C02, C05 |
| C08 | `daliuren-benming-xingnian` | 足量个人输入、本命、行年、序列化和差异化结果 | P1 | C00, C02 |
| C09 | `daliuren-analysis-contract-v2` | 现有分析 typed 化、冲突/优先级、无解语义和报告单一真相 | P0 | C01, C05, C06, C07 |
| C10 | `daliuren-kejing-64` | 六十四课经的 64 个稳定规则及正反/边界课例 | P1 | C00, C06, C07, C09 |
| C11 | `daliuren-bifa-100` | 毕法百法的 100 个稳定规则及交叠/互斥课例 | P1 | C00, C06, C07, C09 |
| C12 | `daliuren-class-spirit` | 有限占类 taxonomy、类神选取、显式覆盖与问题上下文 | P1 | C00, C06, C08, C09 |
| C13 | `daliuren-traditional-judgment` | 汇总课经/毕法/类神/本命的传统断课与冲突降级 | P0 | C08, C10, C11, C12 |
| C14 | `daliuren-timing-calendar` | 传统应期尺度、实际日期窗口、去重和应期日历接入 | P1 | C02, C13 |
| C15 | `daliuren-legacy-recast` | 旧盘版本提示、可重排判定、关联新记录且原记录不可变 | P0 | C01, C02, C13, C14 |
| C16 | `daliuren-ui-ai-contract` | 全能力结果页/AI structured output、来源展示、历史提示和文档 | P0 | C06, C08, C13, C14, C15 |

#### 与并发父设计草案的对照

本文件校验期间，父任务并发生成了 `design.md` / `implement.md`，其中规划了 10 个较粗的交付轨道。两套范围没有功能冲突，但 10 轨道中的 5 个把前后依赖或可独立验收能力合在了同一任务。建议把 10 项保留为 roadmap 分组，把下表拆分项作为真实 implementation children；或者直接用本报告的 17 个直接孩子替换父设计表。不要同时创建两套重复任务。

| 父设计 10 轨道 | 本报告实现任务 | 拆分理由 |
|---|---|---|
| `daliuren-classics-evidence` | C00 | 一一对应，仅统一 slug 即可。 |
| `daliuren-rule-contract-history` | C01 + C15 | 版本/元数据是所有规则前置；真正的 replay eligibility 和关联重排必须等最终规则与应期稳定，不能在 Phase 1 提前验收。 |
| `daliuren-pan-foundation` | C02 + C03 + C04 | 月将/输入、TianPan/SiKe 不变量、神将双坐标各有独立 oracle 和不同失败面；合并会形成一个横跨 system/model/service/UI 的超大 P0。 |
| `daliuren-shensha-system` | C06 | 一一对应。 |
| `daliuren-sanchuan-enrichment` | C05 + C07 | 九宗门选择正确性与遁干/旺相派生字段互不构成同一验收结论。 |
| `daliuren-kejing` | C10 | 一一对应。 |
| `daliuren-bifa` | C11 | 一一对应。 |
| `daliuren-leishen-mingnian` | C08 + C12 | 本命/行年是个人时序事实；占类/类神是问题语境，所需输入、来源和降级完全不同。 |
| `daliuren-judgment-yingqi` | C09 + C13 + C14 | 先修当前分析契约，再叠传统综合裁决，最后解析日期/接日历；三者不能用同一 ready gate。 |
| `daliuren-crosslayer-integration` | C16 + 父门禁 | UI/AI 是实现孩子；完整矩阵、跨孩子古例和最终报告仍归父任务，历史重排已移到 C15。 |

若主会话坚持 10 个顶层分组，应为上述可拆项创建二级孩子，并让粗分组只做验收父节点；不得把“一个 PRD 内分几个 phase”当作独立归档和依赖控制的替代品。

### 5. 依赖图与推荐执行波次

```text
C00 evidence
  -> C01 provenance
       -> C02 cast/yuejiang
            -> C03 pan/sike -> C04 shenjiang -> C05 jiuzongmen
            -> C08 benming/xingnian
                 C05 -> C06 shensha
                 C05 -> C07 chuan facts
  C01 + C05 + C06 + C07 -> C09 analysis contract v2
  C00 + C06 + C07 + C09 -> C10 kejing 64
  C00 + C06 + C07 + C09 -> C11 bifa 100
  C00 + C06 + C08 + C09 -> C12 class spirit
  C08 + C10 + C11 + C12 -> C13 traditional judgment
  C02 + C13 -> C14 timing/calendar
  C01 + C02 + C13 + C14 -> C15 legacy/recast
  C06 + C08 + C13 + C14 + C15 -> C16 UI/AI
  C00...C16 -> parent integration gate
```

在独立 worktree 中，C08 可在 C03-C05 期间并行；C06/C07 可在 C05 后并行；C10/C11/C12 可在各自依赖完成后并行。本工作区是共享目录，且这些任务会共同改动 Freezed 生成物、`daliuren_system.dart`、`san_chuan_service.dart`、analysis models 或 formatter，默认应按 `C00 -> ... -> C16` 串行执行，除非每个并行孩子有独立 worktree 和合并顺序。

### 6. 子任务定义

#### C00 `daliuren-evidence-registry`

**目标**：在任何古法实现前，建立可机审和可人工复核的证据注册表，并把“一次性完整”变成有限清单。

**责任范围**：新增按规则族分文件的证据目录、来源目录、异文决策记录和独立课例 fixture 约定；不改产品算法。每条至少含 `ruleId`、名称、规则族、适用条件、优先级、底本/馆藏标识、卷次、影印页与页码体系、短引文、解释、异文、采用口径、证据等级、预期代码位置、fixture ID 和状态。规则族文件分开，后续孩子只维护自己的文件，避免多人编辑一个总表。

**必须冻结的有限清单**：月将、天地盘、四课、贵人/十二天将、九宗门、旬空/遁干、旺相、神煞、本命/行年、类神/占类、六十四课经 64 项、毕法 100 项、传统裁决和应期。特别要把“完整神煞”落实为核定底本中的逐项清单和明确排除项。

**独立验收**：所有采用源都能定位到影印页；C/D 证据不得标为“已验证古法”；64 与 100 的 ID 数量可自动校验；外部课例 fixture 不读取生产 registry 生成预期；贵人表、昼夜边界、顺逆法和重大异文已有采用决策。未满足这些条件时，C04/C06/C10/C11/C13 不得开始。

#### C01 `daliuren-rule-provenance`

**目标**：建立所有后续规则共用的稳定身份、证据和版本契约，但不改变盘面计算结果。

**责任范围**：typed `ruleId/sourceRef/evidenceLevel/ruleSetVersion`；pan 与 analysis 版本；可重放输入快照；所有现有 `DlrAnalysisTag`、神煞、课经、毕法、类神、factor、condition、timing rule 的统一身份策略；Freezed/JSON 的 additive 默认。展示名称不可参与规则分支。

**推荐历史策略**：新盘写 `panRuleSetVersion` 和可重放输入，运行时报告写 `analysisRuleSetVersion`；无版本 JSON 读为 `legacyUnknown`，默认不得无提示套用现行传统裁决。只有原始时间、时区、起课方式和参数足以无歧义重建时才允许用户显式重排；重排保存为关联新记录，旧快照永不覆盖。C15 完成具体 UI/数据流程。

**独立验收**：当前 JSON round-trip 不丢字段；至少一份无版本旧 JSON fixture 能读取且被识别；展示词改名不改变 rule identity；共享裁决模型的六爻消费方零回归；build_runner 和全量测试通过。

#### C02 `daliuren-cast-yuejiang`

**目标**：修复会整体转盘的月将边界，并使自动/手动起课输入足以复算。

**责任范围**：`yue_jiang_service.dart`、`tianpan_service.dart` 的日期入口、`daliuren_system.dart`、`pan_params.dart`、viewmodel/cast UI 以及相关 tests。明确本地时间与时区；精确比较交节时刻；手动四柱若选自动月将，必须同时提供对应 civil time/timezone，否则要求显式月将；修复 `castByManual()` 无效默认；校验四柱之间的合法联动，不能只逐柱检查六十甲子。

**独立验收**：至少一个核定中气在前一秒/交节时刻/后一秒三例；跨时区约定有测试；手动便捷 API 默认可用；不存在用“当前操作时间”替代手动四柱对应时间；新盘保存足够 replay 输入，旧 JSON 仍可读取。

#### C03 `daliuren-pan-sike-contracts`

**目标**：让天盘与四课公开服务在非法/缺失输入上明确失败，消除伪伏吟和静默同支。

**责任范围**：`tianpan_service.dart`、`si_ke_service.dart`、天盘/四课模型注释与 service tests；天盘 map 必须是十二个合法地支的一一映射，`getDiZhiIndex == -1`、缺键、空 map、部分同位 map 不得产出看似合法结果。乘神的缺省处理只定义接口，不在这里实现 C04 的坐标规则。

**独立验收**：月将/时支非法、缺键、重复值、空 map、部分 map 都有失败测试；完整伏吟/反吟才可判真；四课一至四课上下神与克向语义测试完整；`Ke`/`SiKe` 注释和真实公式一致；无“查不到就返回输入支”的行为。

#### C04 `daliuren-shenjiang-coordinates`

**目标**：重建贵人和十二天将坐标契约，使服务、四课、三传和圆盘消费同一组明确事实。

**责任范围**：`shen_jiang_config.dart`、`shen_jiang_service.dart`、常量表、system 编排、SiKe/SanChuan 的乘神查询、圆盘位置读取及 service/integration/widget tests。至少分开：昼夜所选贵人支、贵人所临地盘宫、实际顺逆、`天盘支 -> 神将`、`地盘宫 -> 神将`。不得用 `isYangGui` 同时表达昼夜与顺逆，也不得查无配置时伪造贵人。

**独立验收**：昼贵/夜贵分别落顺区/逆区的四类交叉盘；每例同时断言贵人支、落宫、实际方向、两张映射、四课乘将、三传乘将和圆盘位置；说明文案与真实方向一致；采用底本和可配置异文来自 C00。

#### C05 `daliuren-jiuzongmen-cases`

**目标**：用影印页规则和独立课例锁定九宗门全部实现分支，而不是继续把 13 个内部位移盘当作古法证明。

**责任范围**：`san_chuan_service.dart`、必要的 SiKe/常量、九宗门 fixture/tests 和 pan spec。覆盖比用转涉害、涉害深度/孟/仲/最终刚柔、遥克多候选及课序、昴星刚柔、别责刚柔、八专阴阳及有克、伏吟有克和两级自刑退路、反吟有克与无克六日。

**独立验收**：每个可达分支有可失败用例；丁/己/辛之丑未六日参数化；至少一张核定外部完整盘贯穿四课三传；测试 helper 不复制生产决胜算法；现有 13 例继续作为内部结构回归但明确标 C 级；spec 的四日错误和底本说明同步修正。

#### C06 `daliuren-shensha-complete`

**目标**：在 typed 起例和 typed 位置上实现 C00 冻结的神煞清单，修复公式、数据丢失和落传错误。

**责任范围**：`shen_sha.dart`、`shen_sha_service.dart`、system 上下文、`shen_sha_chuan_service.dart`、神煞 UI/formatter 的事实完整性以及 tests。位置不能再一律叫 `diZhi`，需能表达天干、地支、干支日、卦位/其他宫位；起例上下文明确年/月/季/日干/日支/时。先修月德、天医、丧门、吊客等已确认项，再按 C00 清单扩充；未核页规则不得输出确定性标签。

**独立验收**：C00 清单逐条有正例及关键反例；年煞确实使用年支；干神不会与传支错误比较；neutral 项在领域、结果页和 AI raw facts 中均不丢失；神煞落传有独立测试；列表数量来自清单而不是“30+”注释。

#### C07 `daliuren-chuan-derived-facts`

**目标**：填充现有空字段并建立三传可供后续规则消费的完整派生事实。

**责任范围**：`chuan.dart`、SanChuan 构造、新的旬遁干/旺衰/关系纯函数服务和 service tests。明确日柱/时柱旬遁模式如何影响每传遁干，明确旺相休囚的月令口径，以及每传对日干的五行/六亲关系；不在本任务做裁决或 UI 结论。

**独立验收**：`tianGan`、强弱状态和 `relationToRiGan` 不再为空；日旬/时旬各有表驱动矩阵；十二支/五态边界覆盖；来源条目可追到 C00；JSON additive 兼容；结果页“遁干”不再把旬首/空亡冒充每传遁干。

#### C08 `daliuren-benming-xingnian`

**目标**：把当前 inert 的 `birthYear` 替换为足量、可解释的本命/行年输入和事实。

**责任范围**：个人上下文模型、PanParams 兼容字段、cast UI/system、纯函数服务、结果事实和 tests。C00 必须先确定采用法所需的性别、年龄算法、出生年柱/精确出生日期、立春或岁首边界、所占年份等输入；不能从一个公历年份静默猜出权威本命。

**独立验收**：足量输入能稳定得到本命与行年；改变性别/年龄/本命等有效输入会改变对应派生事实；缺少关键输入时明确“不计算/待补”，不伪造；旧 `birthYear` JSON 可读取并标注精度限制；UI 不再声称填写一个年份就完成本命占。

#### C09 `daliuren-analysis-contract-v2`

**目标**：先把现有 v1 分析变成可审计、可组合、无跨层矛盾的规则层，再叠加 64/100 等知识。

**责任范围**：analysis models、fact services、`daliuren_verdict_service.dart`、`daliuren_ying_qi_service.dart`、analyzer 及当前 UI/formatter contract tests。执行逻辑只能用 C01 typed ID；报告中 judgment/summary、空亡真相等不得双写。重新核定“六合覆盖克身”和十行首中优先级；将古籍事实与项目 heuristic 分开。

**独立验收**：显示词修改不影响裁决；所有 v1 producer-to-consumer ID 有集成测试；`传归生身 + 发用克身`、递生与空亡、悬置与凶将等冲突矩阵明确；“初末俱空”在 verdict/timing/UI/AI 不再同时出现“无解”和“可填实”；full-list priority 与 badge 一致；factor/source/evidence/version 保留到 structured report。

#### C10 `daliuren-kejing-64`

**目标**：实现 C00 冻结的六十四课经规则集，形成 typed、可重叠、可追源的 rule hits。

**责任范围**：独立 `kejing` 模型/registry/evaluator、64 条分文件或数据表、tests 和对应证据映射；只产出规则命中与解释，不直接决定最终吉凶。

**独立验收**：恰好 64 个稳定 ID；每项有影印页和采用解释；每项至少一个正向 fixture，并为容易误命中的项提供反例/边界；重叠、互斥和显示顺序有显式策略；评估器不解析中文展示文本，tests 不从生产 predicates 生成预期。

#### C11 `daliuren-bifa-100`

**目标**：实现 C00 冻结的毕法百法规则集，为综合断课提供来源明确的规则命中。

**责任范围**：独立 `bifa` 模型/registry/evaluator、100 条规则、tests 和证据映射；与 C10 共用 C01 元数据接口但不共用中文 key。

**独立验收**：恰好 100 个稳定 ID；逐项有影印页、适用条件和正向 fixture；高冲突/高影响条目有负向和组合用例；能同时报告多个命中且不因列表顺序改变事实；不在本任务硬编码最终 verdict 首中表。

#### C12 `daliuren-class-spirit`

**目标**：建立有限占类 taxonomy、类神候选/选取规则和显式用户覆盖，使同一盘在不同事类下产生不同分析上下文。

**责任范围**：question category/class spirit typed models、选择服务、analyzer context、cast/question UI 输入和 tests。不得依靠自由文本关键词静默猜唯一类神；自动建议须可解释、可覆盖，并保留“通用/未指定”降级。

**独立验收**：C00 taxonomy 每类都有来源和 fixture；相同盘面切换类别会改变类神链而不改变盘面；显式覆盖优先级、无候选/多候选、缺少本命信息等降级有测试；question 传入 formatter 但未选类神时不会伪称已按占类裁决。

#### C13 `daliuren-traditional-judgment`

**目标**：在稳定事实之上汇总课经、毕法、类神、本命/行年，形成来源透明的传统断课 v2。

**责任范围**：综合 evaluator、冲突与优先级、factors/conditions、保守降级和 analyzer orchestration。传统规则、项目启发式和纯展示文案必须分层；无法由底本支持的四值趋势应保留 unknown/conditional，不得包装为唯一古法。

**独立验收**：C10-C12 的 typed hits 全部保留来源进入报告；相反证据可同时出现并有明确 adjudication；优先级不依赖 service 调用/列表顺序；古籍规则与 project-v2 heuristic 可机器区分；至少一组《大六壬断案》或《六壬存验》外部课例只由输入事实复算，命中链与原断对照但不声称现实预测有效。

#### C14 `daliuren-timing-calendar`

**目标**：把分支日候选升级为有尺度、有条件、可落实际日期的传统应期，并接入已有应期日历。

**责任范围**：应期输入（事体缓急/日月年尺度）、typed timing rules、候选去重/排序、日期 resolver、`CalendarGuaContext` 适配、结果页导航和 unit/widget tests。应期只表示条件窗口，不能单独翻转 verdict。

**独立验收**：每类候选有来源/规则 ID；同支不同理由的合并策略确定；无解 condition 不产生“解救”候选；日/月/年尺度和时区边界有测试；结果页出现可用“应期日历”入口；日历标记与 formatter 日期一致；长标签/小屏不溢出。

#### C15 `daliuren-legacy-recast`

**目标**：完整实现 C01 的历史策略，避免旧错误盘被当前分析器当成现行事实。

**责任范围**：repository/result restore、历史卡/结果页警告、replay eligibility、重排命令和关联记录字段、legacy fixtures/tests。不得覆盖原记录；不能无歧义重建的手动盘只允许查看并提示。

**独立验收**：无版本、旧 pan 版本、当前版本三类 fixture 可区分；legacy 默认不显示无标记的 v2 权威裁决；足量输入可创建带 parent/original link 的新记录；原 JSON/hash/时间不变；不足量输入按钮禁用并说明原因；repo save/read round-trip 覆盖。

#### C16 `daliuren-ui-ai-contract`

**目标**：把所有已稳定能力一次接入结果页、历史摘要和 AI structured output，并清理当前已确认的呈现缺陷与陈旧文档。

**责任范围**：Daliuren result components、history summary/card、AI formatter/default prompt、必要的 responsive widgets、`docs/architecture/divination-systems/daliuren.md` 与 cross-layer tests。structured output 必须分别提供 `yueJiang`/`yueJian`，并提供 schema/ruleset 版本、typed facts、因素、条件、来源和证据等级；“返吟”统一为“反吟”。

**独立验收**：neutral 神煞、64 课经、毕法、类神、本命行年、三传遁干旺相、裁决、应期和 legacy 状态均有可见/可访问路径；机器字段不靠 rendered text；UI/AI 对同一条件、排序和版本状态一致；formatter exact-schema 测试、widget interaction/responsive 测试和历史卡测试通过；架构文档不再保留“三传占位/固定错盘”等旧描述。

### 7. 父任务最终集成门禁

父任务在 C00-C16 全部检查并归档后，才承担以下直接工作。若需要新增跨层测试或修改产品代码，应先新建修复孩子，不能在父任务里悄悄吸收。

1. 将完整性矩阵逐项更新为 `已验证正确 / 已修复 / 未实现 / 有争议或明确不采用`，每项链接规则登记、代码、fixture 和测试。
2. 自动核对 64 课经 ID 数量、毕法 100 ID 数量、C00 神煞/类神清单覆盖率，以及所有生产 rule ID 都有证据条目。
3. 至少选择两张核定外部完整盘，贯穿起课输入 -> 月将 -> 天地盘 -> 天将 -> 四课三传 -> 神煞/扩展事实 -> 传统分析 -> 应期 -> UI -> AI -> 保存/恢复；预期不能由生产算法生成。
4. 运行 targeted tests、`flutter analyze`、全量 `flutter test`、生成物一致性检查；共享模型/日历改动必须确认非大六壬系统零回归。
5. 复核 UI 与 AI 不把 project heuristic 标成古法，不把争议口径标成唯一规则，不把未验证神煞输出为确定事实。
6. 复核父 PRD 已冻结的保守历史策略在 C15/C16 中完整落地，发布最终审校报告和剩余争议表；只有全部一次性交付项完成才可归档父任务。

### 8. 父 PRD 在建子任务前应补的验收条款

并发更新后的父 PRD 已补上历史版本与重排验收，但仍能在下列传统知识交付缺失时表面通过。规划主会话应先把这些加入父 PRD，再创建/启动孩子：

- [ ] 规则登记中恰有 64 个课经规则和 100 个毕法规则，全部有稳定 ID、影印页、采用解释和独立 fixture。
- [ ] “完整神煞”已冻结为有限清单，清单每项要么实现并验证，要么明确排除且说明理由；不得用当前 15 项或“30+”代替。
- [ ] 有限占类 taxonomy 全覆盖，类神可解释、可覆盖、可降级，且相同盘不同占类的分析差异有测试。
- [ ] 本命/行年所需输入、岁首/年龄/性别口径明确并实现；不再存在可填写但不生效的 `birthYear`。
- [ ] 三传 `tianGan`、强弱和日干关系全部有值或显式 unknown，日旬/时旬模式均有独立测试。
- [ ] 父任务两张以上外部完整盘通过 domain/UI/AI/history 全链验收，且全量非大六壬回归通过。

### 9. 创建和启动协议

建议用下列形态创建，所有命令都带 `--no-start`，slug 不带 `07-28-` 前缀：

```powershell
python ./.trellis/scripts/task.py create "大六壬古籍证据登记与完整规则目录" --slug daliuren-evidence-registry --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬规则来源与版本契约" --slug daliuren-rule-provenance --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬月将与起课输入正确性" --slug daliuren-cast-yuejiang --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬天盘与四课服务契约" --slug daliuren-pan-sike-contracts --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬贵人与十二天将坐标重构" --slug daliuren-shenjiang-coordinates --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬九宗门完整分支与古例" --slug daliuren-jiuzongmen-cases --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬完整神煞与 typed 起例" --slug daliuren-shensha-complete --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬三传遁干旺相派生事实" --slug daliuren-chuan-derived-facts --priority P1 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬本命与行年" --slug daliuren-benming-xingnian --priority P1 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬分析规则契约 v2" --slug daliuren-analysis-contract-v2 --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬六十四课经规则引擎" --slug daliuren-kejing-64 --priority P1 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬毕法百法规则引擎" --slug daliuren-bifa-100 --priority P1 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬占类与类神" --slug daliuren-class-spirit --priority P1 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬传统断课综合裁决" --slug daliuren-traditional-judgment --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬传统应期与日历" --slug daliuren-timing-calendar --priority P1 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬历史盘识别与关联重排" --slug daliuren-legacy-recast --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
python ./.trellis/scripts/task.py create "大六壬结果页与 AI 完整契约" --slug daliuren-ui-ai-contract --priority P0 --parent .trellis/tasks/07-28-daliuren-classics-audit --no-start
```

每个孩子都是复杂任务，必须在 `task.py start` 前具备：完成的 `prd.md`、`design.md`、`implement.md`；在 PRD/implement 中逐字写明依赖 ID/slug 和“依赖未归档不得开始”；至少一个 real implement context 和 check context；`task.py validate <child>` 通过。只启动当前准备实施的孩子，不按树顺序启动父任务。

### 10. Context Manifest 建议

JSONL 只放 spec/research，不放 `lib/**`、`test/**` 或待修改文件。所有孩子的 implement/check 都应加入：

- `.trellis/tasks/07-28-daliuren-classics-audit/prd.md` - 一次性交付与父级约束。
- `.trellis/tasks/07-28-daliuren-classics-audit/research/task-decomposition.md` - 边界、依赖与父验收。
- `.trellis/tasks/07-28-daliuren-classics-audit/research/capability-matrix.md` - 每项能力的现状、目标、实现边界和验证方式。

按孩子追加如下真实条目：

| 子任务 | implement/check 均应加载 |
|---|---|
| C00 | `research/classics-source-inventory.md`, `research/core-pan-audit.md`, `.trellis/spec/domain/index.md` |
| C01 | `research/analysis-crosslayer-audit.md`, `research/core-pan-audit.md`, `.trellis/spec/domain/index.md`, `daliuren-pan-engine.md`, `daliuren-analysis-engine.md` |
| C02-C05 | `research/core-pan-audit.md`, `research/classics-source-inventory.md`, `.trellis/spec/domain/index.md`, `daliuren-pan-engine.md` |
| C06 | 三份 research，`.trellis/spec/domain/index.md`, 两份 Daliuren spec |
| C07 | `research/core-pan-audit.md`, `research/analysis-crosslayer-audit.md`, 两份 Daliuren spec |
| C08 | 三份 research，`.trellis/spec/domain/index.md`, 两份 Daliuren spec |
| C09 | `research/analysis-crosslayer-audit.md`, `research/core-pan-audit.md`, 两份 Daliuren spec |
| C10-C13 | 三份 research，`.trellis/spec/domain/index.md`, 两份 Daliuren spec |
| C14 | `research/analysis-crosslayer-audit.md`, `research/classics-source-inventory.md`, `daliuren-analysis-engine.md`, `.trellis/spec/frontend/index.md`, `state-management.md`, `quality-guidelines.md` |
| C15 | `research/analysis-crosslayer-audit.md`, 两份 Daliuren spec，`.trellis/spec/frontend/index.md`, `state-management.md` |
| C16 | 三份 research，两份 Daliuren spec，`.trellis/spec/frontend/index.md`, `component-guidelines.md`, `quality-guidelines.md`, `type-safety.md` |

C01 完成后，所有后续孩子再把其新建的规则元数据规范加入 context；C00/C01 输出路径在文件实际存在后才能调用 `add-context`，因为命令会拒绝不存在的路径。C10-C14 还必须加载自己规则族的 C00 证据文件。建议命令形态：

```powershell
python ./.trellis/scripts/task.py add-context <child> implement <existing-spec-or-research-path> "实现所需规则与证据契约"
python ./.trellis/scripts/task.py add-context <child> check <existing-spec-or-research-path> "复核来源、边界与验收"
python ./.trellis/scripts/task.py validate <child>
```

check context 不能只放通用 frontend 模板。古法孩子的 checker 必须看到对应影印页登记和 fixture 说明；C16 checker 必须同时看到 domain 证据与 cross-layer audit，才能发现“领域正确但 UI/AI 丢字段”的回归。

### 11. 验证策略

每个孩子先跑自己的 service/model/widget 定向测试，再跑所有受影响包的 Quality Check；修改 Freezed/JSON 的孩子运行 build_runner 并检查生成物；C01、C14、C15 涉及共享模型/日历/存储，必须全量测试。任何规则修复都至少有一个先失败后通过的 regression，不能只更新 snapshot 迎合新输出。

父门禁的最低命令集合为：

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/unit/services/daliuren test/unit/divination_systems/daliuren test/unit/ai/output/formatters/daliuren_formatter_test.dart test/widget/daliuren
flutter test
```

另应提供 C00 registry/fixture 的专用校验测试，用于检查 ID 唯一、64/100 数量、sourceRef 存在、生产 rule ID 全覆盖和未验证规则不会进入确定性输出。

## External References

- Internet Archive `20210924_20210924_0416` - 《大六壬指南》影印 PDF；断课主依据候选，需核版本和影印页。
- Internet Archive `06054168.cn` 至 `06054177.cn` - 《钦定四库全书·六壬大全》十二卷十册；父 PRD 已选为起例、神将、神煞、六十四课经和毕法赋主底本。
- Internet Archive `20210924_20210924_0419` - 《校正大六壬指南详解》；仅作检索和释义交叉参考。
- Internet Archive `20260504_20260504_1528` - 《御定六壬直指》；版本真伪与文件质量未复核，只能作为待登记候选。
- `youngzs/xuanxue` commit `aa7bc942602d2d88ef94778a726c0d19a4d286ff` - 《六壬大全》卷一起例/提要固定转录；证据等级 C，不能替代影印页。
- `mahavivo/scripta-sinica` commit `d2a447941d43fd5ac35b35194dcb0a68d4275aa7` - 《六壬存验》固定转录；用于定位贵人落宫定顺逆和外部课例，仍需回页核验。
- Dart package `lunar` 1.7.8 - 当前项目锁定版本；C02 需以实际 API 时间粒度和时区行为设计月将边界测试。

## Related Specs

- `.trellis/spec/domain/index.md` - Domain 服务纯函数与目录边界。
- `.trellis/spec/domain/daliuren-pan-engine.md` - 当前基础排盘合同；须由 C02-C05 随证据修正。
- `.trellis/spec/domain/daliuren-analysis-engine.md` - 当前 v1 分析合同；须由 C09/C13 演进并保留证据层级。
- `.trellis/spec/frontend/index.md` - frontend spec 路由；当前多为模板，不能单独充当 UI 实施细则。
- `.trellis/workflow.md` - 复杂任务、父子树、context 配置、逐孩子启动和父级集成责任。

## Caveats / Not Found

- 当前尚无已完成的影印页级规则登记，也没有可直接验收的 64/100/完整神煞清单；因此 C10/C11/C06 的具体条目不能在本拆分报告中宣称已核定。C00 是真实的实施前置门禁，不是可跳过的文档任务。
- 父 PRD 已选《六壬大全》为神将主底本，但当前仍没有影印页级的贵人表、昼夜边界和顺逆法规则条目；C00 必须把这些细项明确冻结，不能由 C04 实现者临场选择。
- `birthYear` 单字段很可能不足以实现所选本命/行年法。性别、年龄算法、出生年柱/日期和岁首边界必须在 C08 设计评审前决定，不能以静默近似满足验收。
- 手动四柱没有对应 civil time/timezone 时，自动月将不可复算；C02 必须要求补输入或显式月将，不应继续使用操作时刻。
- frontend spec 的 component/state/quality/type 文件目前大多是占位模板；C14-C16 仍需以现有 Daliuren、共享应期日历和 antique 组件代码为实际模式，并在完成后用 `trellis-update-spec` 沉淀新增约定。
- 本研究只设计任务边界，没有创建子任务、修改父 PRD/spec/product code、读取任何 `implement.jsonl`/`check.jsonl`，也没有运行 git 操作。
