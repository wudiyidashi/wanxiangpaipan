# 实施计划：六爻古籍证据链、分析契约与 AI 提示词优化

## 总体约束

- 保留 `LiuYaoAnalyzer.analyze()` 为唯一领域入口；分析报告继续运行时派生，不写入 `LiuYaoResult`、数据库或历史排盘 JSON。
- 固定流水线为：盘面输入 -> 用户取用/候选 -> 角色清单 -> 基础状态 -> 动变状态 -> 有向作用 -> 辅助证据 -> 冲突裁决 -> 四值结论 -> 未决条件 -> 应期观察窗 -> AI 投影。
- 用户已选用神是最高优先级事实，不自动改写；未选用神时只能给明确标注的候选建议，不生成伪造的程序裁决或应期。
- 《增删卜易》继续作为主干；《卜筮正宗》的三刑、六害在页级证据未完成前保持 `locatorOnly`、低优先级、非决定性。四值、强弱三分类、首行命中和软件冲突顺序必须标为项目约定。
- 规则身份、中文展示和古籍证据分离。迁移期间保留既有 `term`、UI 文案、formatter section key 和 built-in template ID；裁决及应期最终只消费稳定 ID。
- 每个语义修复先提交证据/项目裁定和黄金期望，再改生产实现；禁止针对单个案例写分支。
- 每个 Phase 是独立回滚单元。当前工作树中的未跟踪 `key.txt` 不属于本任务：不得读取、复制、散列、记录、暂存或提交。

## Phase 0：先建立评测工具并冻结基线

### 0.1 记录代码与测试基线

- 记录 `git status --short`，只识别本任务路径和无关脏文件，不打开潜在凭据文件。
- 在任何 domain、formatter、template 或 assembler 改动前运行全量静态检查和测试，保存非敏感版本、测试结果及 Git commit 到评测 manifest。
- 冻结当前真实 `LiuYaoResult -> LiuYaoStructuredFormatter -> PromptAssembler` 输出为 `legacy-e2e-diagnostic` 诊断集，并独立冻结当前 system/analysis/brief 模板原文与 SHA-256；不能手写“近似旧提示词”。最终公平 baseline 在 v2 projection 完成后，用冻结旧模板渲染与 candidate 字节相同的 canonical projection；`legacy-e2e-diagnostic` 不混入提示词因果结论。

### 0.2 建立单一 fixture、rubric 和离线门禁

- 新增显式 opt-in 的 `tool/liuyao_ai_eval/`。把现有 40 例迁到一个版本化 fixture manifest，黄金测试与 evaluator 共同读取，禁止解析 Dart 私有常量或复制第二份案例。
- fixture 使用正交字段 `caseKind=originalBook|ruleValidation` 与 `evaluationSplit=calibration|holdout`；所有 `ruleValidation` 必须为 `calibration`，`holdout` 只允许 `originalBook`。原书例继续与章法校验例分开计数。模型输入采用白名单，`adjudication`、记录结果和测试期望只进入评分 reference，不进入模型请求。
- 在 rubric 中先冻结硬门禁、0-2 分维度、重复改善判据和 holdout 开启规则，再生成任何模型结果。离线测试用已知 good/bad 输出证明每个硬门禁确实能失败。
- holdout 使用字面量 salt `liuyao-holdout-v1-2026-08-01`，按设计中的 UTF-8/hash 算法选出前 6 例；manifest 写死有序成员、selection hashes 和 cohort hash，validator 锁定 cardinality、成员和 calibration/holdout 分组统计。
- baseline 准备阶段只可查看 calibration 和 rule-validation 结果；holdout 请求可冻结但不得用于提示词迭代，candidate 冻结后才执行/揭示配对结果。首次揭示写不可覆盖 marker；同一 cohort 后续只能作为 regression set，不能再次满足 AC9。

### 0.3 凭据与产物安全合同

- 凭据仅从 `LIUYAO_AI_EVAL_API_KEY`、`LIUYAO_AI_EVAL_BASE_URL`、`LIUYAO_AI_EVAL_MODEL` 环境变量，可选 `LIUYAO_AI_EVAL_PROVIDER_LABEL`，或精确 gitignored 的 `tool/liuyao_ai_eval/eval.local.json` 读取；环境变量逐字段优先。本地 JSON 只允许 `apiKey/baseUrl/model/providerLabel`，未知 key、空必填值或非字符串值 fail closed。
- 在 `.gitignore` 增加精确的 `/tool/liuyao_ai_eval/eval.local.json` 规则；runner 启动时若本地配置未被 ignore、已被 Git 跟踪或权限范围异常，必须 fail closed。
- 不复用 `devtools_options.yaml`，不支持 `key.txt`，不把 key 放在命令行、Drift、SecureStorage、snapshot、fixture、测试期望或报告中。
- runner 只记录用户提供的非敏感 provider label、精确 model ID、温度、max tokens、seed 能力、延迟、token 用量及各类 hash；禁止记录 base URL、header、key、原始配置 Map 或完整异常对象。
- 写文件前先在内存中按已知凭据值和 `Authorization`/Bearer 模式清洗；写后执行 count-only 扫描。输出目录必须解析在本任务 `research/eval/` 下，越界即失败。

### 0.4 baseline 捕获与缺凭据分支

- 先生成并校验离线 baseline request set，再进行可选的真实 baseline 调用。真实调用固定非流式、温度 0（或端点最低值）、相同 max tokens/response format/stop；支持 seed 时固定 seed，不支持时至少 3 次并记录 capability fallback。
- `realModelStatus` 只允许 `ready|blockedMissingCredentials|blockedInvalidConfiguration|failedTransport|completed`。若凭据缺失，只允许记录 `blockedMissingCredentials` 和已经冻结的 request hashes；后续离线/domain 工作可继续，但 AC9 不得勾选，不能用 mock 输出冒充真实 baseline。
- 最终候选阶段会用冻结 baseline 与 candidate request sets 重新做交错顺序的 paired run；早期 standalone baseline 只用于基线留档，不替代最终配对比较。

新增 CLI 合同（实现后必须原样可执行）：

```powershell
flutter analyze
flutter test
dart run tool/liuyao_ai_eval/run.dart validate --run-id gate0-legacy-v1
dart run tool/liuyao_ai_eval/run.dart prepare --run-id gate0-legacy-v1 --variant legacy-e2e-diagnostic --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
dart run tool/liuyao_ai_eval/run.dart scan --run-id gate0-legacy-v1 --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
dart run tool/liuyao_ai_eval/run.dart model --run-id gate0-legacy-v1 --variant legacy-e2e-diagnostic --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval --repetitions 3 --confirm-real-model
```

 Gate 0：离线 validator/scorer 全绿；旧模板和 `legacy-e2e-diagnostic` prompt/input hash 已冻结且无敏感命中。缺凭据时明确保留 AC9 blocker；有凭据时可运行旧端到端诊断，但它不替代 Gate 6 的同 projection 配对。Gate 0 未完成前不得修改 prompt-visible 生产路径。

## Phase 1：来源目录、规则目录和稳定身份

### 1.1 版本化 source/rule catalog

- 建立 Liuyao 专属 typed source/rule catalog、稳定 ID 常量和 validator，复用仓库已有 Qimen/Daliuren 的版本、证据等级和项目规则分层，不复制其术数语义。
- source 至少保存：`sourceId`、资料类型、题名/版本、固定 revision 或 SHA-256、公开 locator、页码体系、证据类型、证据等级、采用状态、适用边界和项目裁定。生产数据中不得出现本机绝对路径。
- rule 至少保存：`ruleId`、规则族/阶段、主展示 term、alias、source refs、适用/压制边界、是否可执行、项目裁定、正反 fixture ID。alias 只解析到主 rule，不成为第二个可执行规则。
- 登记已核验《增删卜易》PDF 指纹及四组页级见证；直接引文仅限已经文本+渲染复核的短引。其余 evidence ref 明确为 `paraphrase`、`projectConvention` 或 `locatorOnly`；案例性质另由 case kind 表达。
- 登记《卜筮正宗》固定指纹和当前字体/渲染限制；三刑、六害不得因“有文件”升级为逐字引文或决定性规则。
- 为四值决策行、强弱三分类、首行命中、冲突顺序建立项目 source/rule ID；古籍谓词另行链接，不再使用笼统“《增删卜易》断法总论”代表整张软件表。

### 1.2 黄金矩阵成为可验证单一事实源

- 保持总数及来源构成门禁（40 例、26 原书占例、14 章法校验例），新增稳定 case ID、case kind、evaluation split、source/rule IDs、引用类型、unknown、review 状态和 fixture version。
- validator 交叉核对 `numbers` 算出的卦名/动爻、选择位置对应的用神、章节/页码/source ref、条件/因素/应期 ID，替换当前“字符串非空即可”的弱门禁。
- 原书结果转述只用于历史文本一致性和解释对照，不声明现实预测准确率。

### 1.3 执行身份迁移

- 为 analyzer 可产出的主 `YaoAnalysisTag`、裁决因素、命中决策行、条件和应期规则加入稳定 ID/source refs；Freezed/共享字段采用 additive default，其他术数消费方保持兼容。
- 迁移期保留中文 `term` 用于 UI；新执行引用只写稳定 ID，裁决和应期可从冻结 legacy map 兼容解析旧 term；待所有生产者覆盖后删除 legacy 执行分支。增加“只改展示 term 不改变裁决/应期”的回归。
- 报告增加 `analysisSchemaVersion`、`ruleSetId`、`ruleSetVersion` 和 source catalog version；projection 增加按固定顺序排列的 `analysisStages` 稳定 ID，并校验 trace 覆盖/顺序。未知版本受控失败/降级，不能默认为 current。
- `v1-compat` 保留显式可调用入口；对冻结的 report、condition、timing 和 formatter baseline 做全量输出等价测试，未通过不得把 `current` 指向 v2，也不得声称可一键回滚。

验证：

```powershell
dart run tool/liuyao_classics/validate.dart
dart analyze tool/liuyao_classics
dart analyze test/tool/liuyao_classics
flutter test test/tool/liuyao_classics
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/services/liuyao/analysis/liuyao_catalog_test.dart
flutter test test/unit/services/liuyao/analysis/verdict_golden_test.dart
flutter test test/unit/services/liuyao/analysis/
```

Gate 1：所有生产主 term、决策行、条件和应期规则唯一解析到合法 rule/source；project convention 不冒充古籍；`locatorOnly` 不可决定裁决；40 例元数据与盘面交叉校验全绿。未过 Gate 1 不进入行为修复。

## Phase 2：有向事实与 actor availability

- 新增有向作用 occurrence，至少记录 `occurrenceId`、`ruleId`、`from`、`to`、路径/步序、active/suppressed 状态、压制 rule/occurrence 和输入引用；连续相生/相克不能再给三爻贴同一个无方向执行标签。
- 只有直接指向用神，或有完整 active path 最终到达用神的扶/克，才进入用神受力和裁决。用神位于链首、链中、链尾分别建立正反例。
- 抽出一套对元神、忌神和其他作用 actor 对称使用的 availability 判定，覆盖回头克、化退、冲散、旬空/破、日合和月合绊；被压制 actor 仍保留 trace，但不得产生 active force。
- 角色清单保留所有用神/元神/忌神/仇神候选及选择/压制理由，不再只用“第一动爻，否则最低爻”代表全部 actor。用户选定用神仍不可覆盖。
- 世应、卦变、六神、神煞只进入 typed secondary evidence，并带低优先级/适用边界；不得借 polarity 或标签数量翻转用神中心裁决。
- 每个行为修复先在共享 fixture 中写证据/项目裁定和新期望，使测试先失败；确认期望后再改 service，禁止为黄金 ID 写个案条件。

验证：

```powershell
flutter test test/unit/services/liuyao/analysis/sheng_ke_service_test.dart
flutter test test/unit/services/liuyao/analysis/special_service_test.dart
flutter test test/unit/services/liuyao/analysis/dong_bian_service_test.dart
flutter test test/unit/services/liuyao/analysis/liu_qin_deduce_service_test.dart
flutter test test/unit/services/liuyao/analysis/verdict_service_test.dart
flutter test test/unit/services/liuyao/analysis/verdict_golden_test.dart
```

Gate 2：方向正反例、链首/中/尾、元忌对称受制、日/月合绊均通过；修改 display term 后行为不变；所有 semantic delta 都能回到 catalog/fixture 裁定。

## Phase 3：裁决先行、条件驱动应期

- 固定 analyzer 顺序：完整事实/冲突 -> 四值裁决及 ordered factors/matched decision row -> 完整未决条件 -> 应期。factor 顺序体现裁决层级，不再继承 UI priority。
- 为 factor、decision row、condition 增加稳定 ID 和 source refs；首行命中继续唯一，禁止 score、权重、百分比和标签计数。
- 修正伏神已经 `伏神得出` 却仍生成 `待出伏` 的因果矛盾；必须有“已得出不再待出伏”和“尚未得出仍保留待出伏”的成对 fixture。一并裁定真空等文案与 `hasRescue` 行为，使 catalog、词典和执行逻辑一致。
- `YingQiService` 只消费尚未解除且 `hasRescue=true` 的 condition；无救条件不生成暗示成功的通用候选。候选保留上游 condition/rule/occurrence IDs。
- 去重键命中同一时间窗口时稳定 union 全部上游引用和原因，不再只留一个 reason；保持现有 `YingQiScale.ri/yue` 以及日历只消费日尺度候选的兼容行为。
- 未选用神时 judgment/conditions/timing 均为空，只保留候选建议所需的盘面事实。

验证：

```powershell
flutter test test/unit/services/liuyao/analysis/verdict_service_test.dart
flutter test test/unit/services/liuyao/analysis/ying_qi_service_test.dart
flutter test test/unit/services/liuyao/analysis/liuyao_analyzer_test.dart
flutter test test/unit/services/liuyao/analysis/verdict_golden_test.dart
flutter test test/unit/divination_systems/liuyao/relation_edges_test.dart
flutter test test/unit/divination_systems/liuyao/liuyao_analysis_controller_test.dart
flutter test test/unit/services/shared test/unit/services/daliuren/analysis test/unit/services/qimen/analysis
```

Gate 3：完整裁决先于应期；无救条件零候选；一个候选解除多个条件时链接不丢失；40 例及日/月日历行为通过；其他术数共享模型零回归。

## Phase 4：版本化 AI 投影、不可替换 guard 与模板

### 4.1 单一 Liuyao projection

- 建立版本化 `LiuYaoAnalysisProjection`，由一次真实 `AnalysisReport` 构造；formatter、prompt 和 UI 不得各自重解释字符串。
- 完整投影：用神模式/用户 override/候选建议、全部角色、用神自身标签（含伏神自身事实）、有向作用和压制链、四值 trend/nuance、matched decision row、全部 factors/conditions、应期 scale/reason/upstream IDs、实际使用的 source records，以及 schema/rule/source-catalog versions 和固定 `analysisStages`。
- 固定 projection policy：`calculationOwner=program`、禁止重排/重算盘面和分析、禁止覆盖 verdict、禁止伪造原文/版本/页码、`mayInventTiming=false`、只能解释输入来源和应期 allowlist 观察窗。该 policy 和 canonical projection 对 baseline/candidate 字节相同；variant-specific `promptPolicyVersion` 只进入 assembly/snapshot/evaluation metadata。
- 保留既有 `analysis` section key 和可读文本；canonical projection 使用稳定字段/顺序，便于 hash、snapshot 和 evaluator 比较。

### 4.2 PromptAssembler 强制边界

- immutable guard 和 canonical projection 在 `PromptAssembler` 边界拼装，位于可替换 custom template 之外；active custom system/analysis template 即使省略变量或要求重算，也不能移除程序所有权和来源/应期边界。
- 保留 `builtin_liuyao_system`、`builtin_liuyao_analysis` 等既有 ID；同步更新 comprehensive 与 brief，固定输出顺序：问题与取用边界 -> 盘面/世应 -> 日月与状态 -> 动变/作用链 -> 裁决与反证 -> 未决条件 -> 应期 -> 古籍依据 -> 有边界建议。
- 修复真实 assembly 的 `hasChangingGua` 上下文，不再由模板测试手工注入掩盖；真实 Liuyao fixture 覆盖有/无变卦和有/无用神。
- 已有 `CastSnapshot` 的 system/user prompt 不原地改写；新建/重新生成对话使用新 prompt/projection version。若 snapshot 增加版本字段，必须 additive、旧值为 legacy/unknown，且不增加数据库 migration。

验证：

```powershell
flutter test test/unit/ai/output/formatters/liuyao_formatter_test.dart
flutter test test/unit/ai/service/prompt_assembler_test.dart
flutter test test/unit/ai/template/builtin_templates_test.dart
flutter test test/unit/ai/service/ai_conversation_service_test.dart
flutter test test/unit/ai/config/ai_config_manager_test.dart
```

Gate 4：真实 selected fixture 含完整事实/因素/条件/应期/来源/policy；unselected fixture 无伪裁决；comprehensive、brief、active custom 三路径均保留 guard；旧 conversation snapshot 字节不变，新会话带新版本。

## Phase 5：术语词典与最小 UI 接入

- `TermGlossary` 以主 `ruleId` 查 catalog，alias 先归一到主规则；不得在 widget 中复制来源或裁决逻辑。
- 现有词典弹窗增量显示：来源类型、书名或“项目约定”、章节/印刷页/locator、采用释义、证据等级和边界。
- 只有 `exactQuote` 可显示为逐字引文；`paraphrase`、`projectConvention`、`locatorOnly` 使用明确不同的标签/措辞。案例性质单独展示，任何模式都不展示绝对路径。
- 在现有结果/AI 区域以最小非重设计方式展示 analysis rule set 与 prompt version；长 locator、窄屏和无来源降级须有 widget 测试。

验证：

```powershell
flutter test test/widget/liuyao_analysis_ui_test.dart
flutter test test/unit/divination_systems/liuyao/liuyao_analysis_controller_test.dart
flutter test test/unit/services/liuyao/analysis/liuyao_catalog_test.dart
```

Gate 5：每个可见主 term 都能打开合法来源边界；绝对路径零展示；locator-only 不显示为引号原文；现有结果页布局和无用神状态无回归。

## Phase 6：冻结候选并执行真实 paired evaluation

### 6.1 候选冻结

- Gate 1-5 全绿后，用同一份 `ruleSetVersion=v2`、`projectionSchemaVersion=1` canonical projection 分别渲染 `canonical-v2-baseline` 与 `canonical-v2-candidate`。前者使用冻结旧模板且只在 evaluator 内跳过新 guard；后者使用新模板和新 guard。验证两者使用同一 fixture version、case order、完整 projection/input hash、模型和请求参数 hash。允许变化的只有 assembled system/user prompt、template IDs、prompt-policy metadata/hash；旧 formatter 的 `legacy-e2e-diagnostic` 只保留为单独诊断。
- 先在 calibration + rule-validation 上运行离线硬门禁；candidate 冻结并记录 hash 后才开启 holdout，禁止看 holdout 结果后继续改同一 candidate 而不升版本并重新完整评测。

### 6.2 配对调用与评分

- 对每个 `(caseId, repetition)` 按预生成交错/随机顺序调用冻结 baseline 和 candidate；两者使用同一 endpoint、精确 model、temperature、max tokens、seed capability、response format、stop 和 retry policy。
- 非流式调用；只重试 transport/rate-limit 失败且保留 logical run ID。无 seed/端点非确定时至少 3 次。
- 先运行确定性硬门禁：程序 trend 不被覆盖、所有条件不遗漏、盘面/用神不捏造、无应期承诺、引用只来自 projection source registry、无伪造逐字原文/页码。任一新增硬失败直接拒绝 candidate，不用主观总分掩盖。
- 再按冻结 rubric 做盲化 pairwise/分维度评分。judge 固定复用生成 endpoint/精确 model，temperature=0、max tokens=2048、JSON response、支持时 seed=271828；盲序由设计中的固定 salt/hash 决定。保留脱敏后的生成输出、judge 请求/响应和 blind mapping；malformed、缺 pair、重试耗尽或缺维度全部失败关闭。
- 聚合严格按 pair delta -> case 内 repetition 均值 -> cohort 内 case 不加权均值。七个维度在 `overall/originalBook/ruleValidation/holdout` 的每个单元格都不得退化；五个核心维度中至少一个同时满足 overall/holdout `>=0.20`、各自非平局胜率 `>=60%` 和每个改善 case 三次中至少两次同向。该规则只作启发式发布门禁，不作统计显著性声明。
- 产物写入前后都跑敏感扫描；比较报告只写非敏感元数据、逐维度分数/理由和 hash，不写 header/config/异常对象。

验证：

```powershell
dart run tool/liuyao_ai_eval/run.dart validate --run-id canonical-v2-r1
dart run tool/liuyao_ai_eval/run.dart prepare --run-id canonical-v2-r1 --variant canonical-v2-baseline --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
dart run tool/liuyao_ai_eval/run.dart prepare --run-id canonical-v2-r1 --variant canonical-v2-candidate --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
dart run tool/liuyao_ai_eval/run.dart compare-offline --run-id canonical-v2-r1 --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
dart run tool/liuyao_ai_eval/run.dart paired-model --run-id canonical-v2-r1 --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval --repetitions 3 --confirm-real-model
dart run tool/liuyao_ai_eval/run.dart compare --run-id canonical-v2-r1 --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
dart run tool/liuyao_ai_eval/run.dart scan --run-id canonical-v2-r1 --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
```

Gate 6：有有效凭据时，candidate 满足全部硬门禁、无维度退化且至少一项可重复改善，敏感扫描零命中。无凭据时只能标记 Gate 6/AC9 blocked，其他 green gate 不能代替它。

## Phase 7：文档同步与全量验证

- 更新 `.trellis/spec/domain/liuyao-analysis-engine.md`，锁定版本、稳定 ID、证据等级、阶段顺序、有向作用、actor availability、条件驱动应期、AI policy 和评测口径。
- 更新 `docs/architecture/divination-systems/liuyao.md`，删除伏神未集成等过期描述，并说明分析派生、不落库、旧对话冻结和版本可见性。
- 检查没有数据库 migration、没有历史盘批量重写、没有把分析报告加入 `LiuYaoResult` JSON；检查生成文件与模型一致。
- 最终按“validator -> codegen -> format -> 定向 domain -> AI -> UI -> 共享系统 -> analyze -> 全量 test -> secret/diff scan”执行，不以局部测试替代全量门禁。

最终命令：

```powershell
python ./.trellis/scripts/task.py validate .trellis/tasks/08-01-liuyao-classics-analysis-prompt
python ./.trellis/scripts/task.py list-context .trellis/tasks/08-01-liuyao-classics-analysis-prompt
dart run tool/liuyao_classics/validate.dart
dart run tool/liuyao_ai_eval/run.dart validate --run-id canonical-v2-r1
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib/domain/services/liuyao/analysis lib/ai/output/formatters/liuyao_formatter.dart lib/ai/service/prompt_assembler.dart lib/ai/template/builtin_templates.dart tool/liuyao_classics tool/liuyao_ai_eval test/unit/services/liuyao test/unit/ai test/widget/liuyao_analysis_ui_test.dart test/tool
dart analyze tool/liuyao_classics
dart analyze tool/liuyao_ai_eval
dart analyze test/tool/liuyao_classics
dart analyze test/tool/liuyao_ai_eval
flutter test test/tool/liuyao_classics test/tool/liuyao_ai_eval
flutter test test/unit/services/liuyao/analysis
flutter test test/unit/divination_systems/liuyao
flutter test test/unit/ai/output/formatters/liuyao_formatter_test.dart test/unit/ai/service/prompt_assembler_test.dart test/unit/ai/template/builtin_templates_test.dart test/unit/ai/service/ai_conversation_service_test.dart test/unit/ai/config/ai_config_manager_test.dart
flutter test test/widget/liuyao_analysis_ui_test.dart
flutter test test/unit/services/shared test/unit/services/daliuren/analysis test/unit/services/qimen/analysis
flutter analyze
flutter test
dart run tool/liuyao_ai_eval/run.dart scan --run-id canonical-v2-r1 --output .trellis/tasks/08-01-liuyao-classics-analysis-prompt/research/eval
git check-ignore -q tool/liuyao_ai_eval/eval.local.json
git diff --check
$tracked = @(git diff --name-only -- lib/data/database lib/divination_systems/liuyao/liuyao_result.dart)
$untracked = @(git ls-files --others --exclude-standard -- lib/data/database lib/divination_systems/liuyao/liuyao_result.dart)
if ($tracked.Count -or $untracked.Count) { Write-Error "Database/result immutability gate failed"; $tracked; $untracked; exit 1 }
```

Gate 7：catalog/evaluator validator、所有定向与共享回归、`flutter analyze`、全量 `flutter test`、敏感扫描和 diff 检查全绿；最后一条数据库/排盘结果检查预期无输出。文档与运行时版本/阶段/policy 完全一致，方可宣告 AC1-AC10 完成。

## 回滚点

| 回滚单元 | 保留内容 | 回滚动作/停止条件 |
|---|---|---|
| R0 评测基线 | 已冻结且通过扫描的 baseline request/hash、fixture/rubric | runner 不安全或 baseline 不可重现时停止产品改动；删除失败产物后修工具，绝不覆盖已发布 baseline hash |
| R1 证据与 catalog | 已核验 source、validator 和 evidence downgrade 记录 | rule 有争议时降级为 pending/non-executable，不删除可核来源；回滚 runtime 接线而非伪造更高证据 |
| R2 稳定 ID | catalog/alias 与兼容 decoder | ID 迁移失败时恢复 legacy consumer 调用点；不得回退为新 term 直接参与裁决 |
| R3 有向事实/裁决/应期 | Gate 1 的证据与身份层 | 按 service/analyzer 单一接线点回滚语义提交；先恢复黄金期望到上一已审版本，禁止留下半套顺序 |
| R4 projection/prompt | 稳定 domain report、catalog 与生产 immutable guard | 可回滚 projection renderer 和模板文案，但生产 assembler guard 必须保留；只有 evaluator 内的 canonical baseline 允许显式绕过。既有 snapshot 永不重写 |
| R5 UI | domain/projection/source catalog | 回滚 glossary/version 展示组件即可；不在 UI 加 fallback 规则计算 |
| R6 candidate evaluation | baseline、rubric、原始 candidate hash 和失败报告 | candidate 不达标则拒绝该版本并回到 R4；不得放宽硬门禁、重标 holdout 或删除失败样本来通过 |
