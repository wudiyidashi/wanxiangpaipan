# Research: Liuyao domain model and deterministic analysis pipeline audit

- Query: Audit the existing Liuyao domain model, deterministic analysis stages, data contracts, computed facts, gaps against a systematic traditional judgment flow, compatibility risks, tests, and documentation.
- Scope: internal
- Date: 2026-08-01

## Findings

### Executive summary

The repository already has a substantial deterministic Liuyao engine. It computes line-level calendar state, void/break/tomb/absolute states, line interactions, moving-line transformations, hidden-spirit relations, a selected-use-spirit chain, four-value verdict, and timing candidates. The analyzer is pure and derived at runtime, and 40 source-labelled golden cases protect the current verdict table.

The main limitation is not lack of terms. The system does not yet carry one stable evidence chain from input fact -> rule occurrence -> conflict/suppression -> verdict condition -> timing -> AI output. Localized `term` strings are used as rule identity; citations are broad free-form book/chapter labels; question classification and use-spirit selection remain outside the deterministic engine; and the AI formatter discards most of the structured verdict, conditions, factors, sources, and hidden-use-spirit facts. Several current rules also lose causal direction, which can change the verdict rather than merely reduce explainability.

The safest extension is additive: preserve persisted `LiuYaoResult` fields and current display terms, add a versioned runtime analysis/projection contract with stable rule/source/occurrence IDs, make use-spirit resolution an explicit stage with user override, derive timing from unresolved verdict conditions, and feed the complete typed projection to AI. Do not persist the derived analysis itself.

### Current end-to-end flow

```text
Cast method
  -> six yao numbers
  -> LunarInfo
  -> GuaCalculator: main gua / Na Jia / palace / Shi-Ying / six relatives
  -> changing gua
  -> six spirits
  -> persisted LiuYaoResult (+ optional user-selected use-spirit position)
  -> LiuYaoAnalyzer (runtime-only)
       1. per-line calendar/static state
       2. cross-line and moving-line facts
       3. gua-change facts
       4. optional selected-use-spirit chain
       5. timing candidates
       6. verdict decision table
  -> AnalysisReport
       -> UI cards / relation graph / calendar
       -> LiuYaoStructuredFormatter (recomputes report)
       -> rendered text section
       -> PromptAssembler + active templates
       -> frozen AI conversation snapshot
```

Anchors:

- Casting converges on lunar context, main gua, changing gua, six spirits, and `LiuYaoResult`: `lib/divination_systems/liuyao/liuyao_system.dart:56`, `lib/divination_systems/liuyao/liuyao_system.dart:121`, `lib/divination_systems/liuyao/liuyao_system.dart:141`, `lib/divination_systems/liuyao/liuyao_system.dart:150`.
- Canonical historical records have main/changing gua recomputed from stored yao numbers: `lib/divination_systems/liuyao/liuyao_system.dart:163`.
- The sole analysis entry point and exact service order are at `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:20`, `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:28`, and `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:39`.
- UI/controller analysis is runtime-derived; only the use-spirit choice is persisted: `lib/divination_systems/liuyao/viewmodels/liuyao_analysis_controller.dart:10`, `lib/divination_systems/liuyao/viewmodels/liuyao_analysis_controller.dart:34`, `lib/divination_systems/liuyao/viewmodels/liuyao_analysis_controller.dart:108`.
- The AI formatter independently recomputes the report: `lib/ai/output/formatters/liuyao_formatter.dart:132`.
- Prompt assembly selects persisted active system/analysis templates and renders a single text projection: `lib/ai/service/prompt_assembler.dart:76`, `lib/ai/service/prompt_assembler.dart:82`, `lib/ai/service/prompt_assembler.dart:88`, `lib/ai/service/prompt_assembler.dart:107`.
- AI follow-up context freezes the initial system/user prompts: `lib/ai/model/cast_snapshot.dart:6`.

### Current deterministic stages and computed facts

| Stage | Current computation | Output / consumer | Anchors |
|---|---|---|---|
| 0. Pan foundation | Six yao numbers; Na Jia stems/branches; five elements; six relatives; palace; Shi/Ying; special gua type; changing gua; calendar; six spirits | `LiuYaoResult` | `lib/divination_systems/liuyao/models/yao.dart:44`; `lib/divination_systems/liuyao/models/gua.dart:34`; `lib/divination_systems/liuyao/liuyao_result.dart:14`; `lib/domain/services/gua_calculator.dart:12`; `lib/domain/services/gua_calculator.dart:162` |
| 1. Day/month strength | Near month/day, month break, month/day generation or overcoming, same-element day support, and `旺相休囚死` | Per-line tags | `lib/domain/services/liuyao/analysis/wang_shuai_service.dart:20`, `lib/domain/services/liuyao/analysis/wang_shuai_service.dart:59` |
| 2. Void | `旬空`, true/false void, clash-to-activate void | Per-line tags | `lib/domain/services/liuyao/analysis/kong_wang_service.dart:8`, `lib/domain/services/liuyao/analysis/kong_wang_service.dart:17` |
| 3. Tomb/absolute | Day/month/moving tomb, released tomb, absolute state | Per-line tags | `lib/domain/services/liuyao/analysis/mu_jue_service.dart:8`, `lib/domain/services/liuyao/analysis/mu_jue_service.dart:16` |
| 4. Day/month special | Day join, month join, annual branch on line | Per-line tags | `lib/domain/services/liuyao/analysis/special_service.dart:7`, `lib/domain/services/liuyao/analysis/special_service.dart:16` |
| 5. Join/clash/configuration | Moving-to-line joins/clashes; opened join; three-combination, half-combination; low-priority punish/harm | Per-line relational tags | `lib/domain/services/liuyao/analysis/he_chong_service.dart:7`, `lib/domain/services/liuyao/analysis/he_chong_service.dart:17` |
| 6. Movement/transformation | Hidden movement, day break/scatter/acceleration, sole moving/still line, advance/retreat, return generation/overcoming, drain/outgoing overcome, transformed void/break/tomb/absolute/join/clash | Tags on the original moving line | `lib/domain/services/liuyao/analysis/dong_bian_service.dart:10`, `lib/domain/services/liuyao/analysis/dong_bian_service.dart:33`, `lib/domain/services/liuyao/analysis/dong_bian_service.dart:126` |
| 7. Dynamic generation/overcoming | Moving-line generation/overcoming/support, greed for joining/generation, three-line generation/overcoming chains | Tags on affected lines | `lib/domain/services/liuyao/analysis/sheng_ke_service.dart:8`, `lib/domain/services/liuyao/analysis/sheng_ke_service.dart:17` |
| 8. Hidden/flying spirit | Hidden-spirit calculation; flying-hidden generation/overcoming; hidden release/restraint | Tags attached to flying-line position; separate selected-hidden analysis when used | `lib/domain/services/fushen_service.dart:22`, `lib/domain/services/liuyao/analysis/fu_shen_relation_service.dart:9`, `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:67` |
| 9. Gua change | Six-clash/six-join/wandering/returning soul; change to join/clash; repetition/reversal | Gua-level tags | `lib/domain/services/liuyao/analysis/gua_change_service.dart:5`, `lib/domain/services/liuyao/analysis/gua_change_service.dart:13` |
| 10. Use-spirit chain | Given one selected position, infer duplicate use-spirit, one source spirit, one adverse spirit, one enemy spirit, and idle positions | `YongShenChain` plus role tags | `lib/domain/services/liuyao/analysis/liu_qin_deduce_service.dart:7`, `lib/domain/services/liuyao/analysis/liu_qin_deduce_service.dart:48`; `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:144` |
| 11. Timing | Tag-driven release/activation branches for void, break, tomb, join, absolute, advance, transformation, plus generic value/clash/join dates | `List<YingQiCandidate>` | `lib/domain/services/liuyao/analysis/ying_qi_service.dart:9`, `lib/domain/services/liuyao/analysis/ying_qi_service.dart:18` |
| 12. Verdict | Collect use-spirit forces; infer active source/adverse spirits; convert suspended states to conditions; first-match four-value decision table | `VerdictJudgment` | `lib/domain/services/liuyao/analysis/verdict_service.dart:13`, `lib/domain/services/liuyao/analysis/verdict_service.dart:64`, `lib/domain/services/liuyao/analysis/verdict_service.dart:174` |

### Current contracts

#### Persisted pan/result contract

`LiuYaoResult` persists pan data, lunar context, six spirits, encrypted-field references, and only two analysis-related user choices: `yongShenPosition` and `yongShenIsFuShen` (`lib/divination_systems/liuyao/liuyao_result.dart:14`, `lib/divination_systems/liuyao/liuyao_result.dart:23`, `lib/divination_systems/liuyao/liuyao_result.dart:27`). This matches the explicit derived-data-not-persisted convention in `.trellis/spec/domain/liuyao-analysis-engine.md`.

#### Rule occurrence contract

`YaoAnalysisTag` currently has only display term, broad category, context-free polarity, UI priority, reason text, and related line numbers (`lib/domain/services/liuyao/analysis/models/analysis_tag.dart:9`, `lib/domain/services/liuyao/analysis/models/analysis_tag.dart:31`). It has no stable rule ID, occurrence ID, source IDs, evidence grade, input references, analysis stage, applicability status, or suppression/conflict links.

`priority` is documented as display ordering (`lib/domain/services/liuyao/analysis/models/analysis_tag.dart:26`) but is easy to mistake for judgment precedence. The verdict does not consume priority; it consumes literal `term` strings (`lib/domain/services/liuyao/analysis/verdict_service.dart:22`, `lib/domain/services/liuyao/analysis/verdict_service.dart:74`).

#### Analysis report contract

`AnalysisReport` holds per-line tags, gua tags, optional use-spirit chain, a separate selected-use-spirit tag list, timing candidates, summary, and typed judgment (`lib/domain/services/liuyao/analysis/models/analysis_report.dart:37`). It is runtime-only and has no schema version, rule-set version, source-pan version, compatibility status, diagnostics, or trace.

The shared verdict types are a good typed foundation: four-value trend, force effect, unresolved condition with `hasRescue`, factor with source string, and scale-aware timing candidate (`lib/domain/services/shared/analysis/models/verdict_models.dart:15`, `lib/domain/services/shared/analysis/models/verdict_models.dart:37`, `lib/domain/services/shared/analysis/models/verdict_models.dart:53`, `lib/domain/services/shared/analysis/models/verdict_models.dart:69`, `lib/domain/services/shared/analysis/models/verdict_models.dart:89`). Their provenance links are still free text rather than IDs.

#### AI boundary contract

The generic AI boundary is `StructuredDivinationOutput`, but its sections are primarily formatted strings with optional untyped metadata (`lib/ai/output/structured_output.dart:20`, `lib/ai/output/structured_output.dart:95`). Liuyao's `analysis` section has no metadata and flattens the report into prose (`lib/ai/output/formatters/liuyao_formatter.dart:121`). Therefore the type-rich report exists inside the domain but not at the AI boundary.

### What already works well

- One pure analyzer entry point composes small services; rules remain independently testable (`lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:20`).
- Derived analysis is deliberately not persisted, so old pans can receive corrected rules without a database migration (`lib/domain/services/liuyao/analysis/models/analysis_report.dart:37`; `.trellis/spec/domain/liuyao-analysis-engine.md`).
- Moving-line transformation correctly allows coexisting relations such as transformed join plus return overcoming instead of collapsing to one label (`lib/domain/services/liuyao/analysis/dong_bian_service.dart:126`).
- The verdict is a first-match classification table rather than a tag-count score (`lib/domain/services/liuyao/analysis/verdict_service.dart:174`).
- Suspended states are represented as conditions instead of automatically treated as failure (`lib/domain/services/liuyao/analysis/verdict_service.dart:277`).
- Hidden use-spirit state is recomputed from the hidden line rather than copying the flying line (`lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:67`, `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:118`).
- Service-level tests cover many positive/negative boundaries, and the golden suite enforces at least 40 cases with at least 26 labelled original cases and 14 labelled rule-validation cases (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:78`, `test/unit/services/liuyao/analysis/verdict_golden_test.dart:910`).

### Critical gaps against a systematic judgment flow

#### P0. The AI does not receive the deterministic evidence chain that already exists

The formatter prints every flying-line tag as `term(reason)`, but only prints the selected use-spirit position, timing labels, and the short verdict summary (`lib/ai/output/formatters/liuyao_formatter.dart:151`, `lib/ai/output/formatters/liuyao_formatter.dart:162`). It does not print:

- `report.yongShenTags`, which is especially serious for hidden use-spirit selection because these are the hidden line's own strength/void/tomb facts;
- `judgment.trend` and `nuance` as typed fields;
- the complete `judgment.conditions` and their `hasRescue` values;
- `judgment.factors`, their effects, reasons, or source labels;
- use/source/adverse/enemy-spirit positions as a dedicated chain;
- gua-tag reasons, polarity, or provenance;
- timing candidate scale/priority as structured fields;
- rule-set/source versions or trace.

The summary itself truncates unresolved conditions and timing hints to two items (`lib/domain/services/liuyao/analysis/verdict_service.dart:374`). A pan can therefore have more conditions in the domain than the AI can see. The domain and UI may be correct while the final AI explanation invents a different rationale.

Required direction: create a Liuyao-specific typed AI projection from the already-computed `AnalysisReport`, then render that projection. Include every unresolved condition and factor, and explicitly distinguish selected-hidden-line facts from flying-line facts. Retain the existing `analysis` section key and human-readable terms for compatibility.

#### P0. Use-spirit resolution is not a deterministic stage

`LiuYaoAnalyzer.analyze()` accepts only a user-selected line position/hidden flag; it has no question, matter type, subject relation, sex/role, time horizon, or selection rationale (`lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:28`). Without a selection, judgment and timing are absent (`lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:54`, `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:59`).

The formatter then asks the model to suggest a use spirit (`lib/ai/output/formatters/liuyao_formatter.dart:162`), while the built-in analysis prompt asks the model to determine it again whenever a question exists (`lib/ai/template/builtin_templates.dart:91`). This creates two incompatible modes:

- selected use spirit: program has a verdict, but the model is still invited to reselect;
- no selected use spirit: the model must perform a key deterministic step from prose and may hallucinate hidden/multiple selection.

The separate built-in question template contains a short category mapping but is never consumed by `PromptAssembler`; only `system` and `analysis` templates are loaded (`lib/ai/template/builtin_templates.dart:142`; `lib/ai/service/prompt_assembler.dart:88`). Its health/travel mappings also conflate the represented person/thing with disease, medicine, or destination roles, so it should not simply be wired in as-is.

Required direction: add an explicit matter-context and use-spirit-resolution stage that outputs candidates, rule-backed rationale, ambiguity, and a selected candidate. Preserve the current user selection as the highest-priority explicit override and do not silently overwrite the persisted fields.

#### P0. Localized terms are acting as rule IDs

The verdict and timing services turn `yongShenTags` into `Set<String>` and branch on literal Chinese display terms (`lib/domain/services/liuyao/analysis/verdict_service.dart:74`; `lib/domain/services/liuyao/analysis/ying_qi_service.dart:24`). The spec explicitly warns that renaming a term requires synchronized consumer changes. This makes wording cleanup a semantic code change and prevents robust source/version tracking.

Required direction: introduce stable IDs such as `liuyao.rule.void.true` and retain `term` only as localized display text. During migration, produce both ID and term and test that changing display text does not alter verdict/timing.

#### P0. Provenance is broad, lossy, and sometimes structurally wrong

Rule services mostly cite books only in comments. `TermEntry` has definition/condition/implication but no source (`lib/domain/services/liuyao/analysis/models/term_glossary.dart:1`). Runtime factors obtain one source string from the broad tag category (`lib/domain/services/liuyao/analysis/verdict_service.dart:51`, `lib/domain/services/liuyao/analysis/verdict_service.dart:81`).

This cannot distinguish original text, project interpretation, and low-confidence supplement. It also conflicts with the engine's own policy: punish/harm are explicitly described as supplements from `《卜筮正宗》` (`lib/domain/services/liuyao/analysis/he_chong_service.dart:11`), while the entire `heChong` category maps to `《增删卜易》合冲章` (`lib/domain/services/liuyao/analysis/verdict_service.dart:55`). The current source test merely requires every factor string to contain `《增删卜易》`, which would reject a correctly attributed supplementary factor (`test/unit/services/liuyao/analysis/verdict_service_test.dart:320`).

The golden cases record edition label, chapter, and printed pages, but no exact quotation/source fingerprint is available to runtime analysis (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:72`).

Required direction: add an immutable source catalog with stable source IDs, edition/revision locator, exact quote or bounded excerpt, modern interpretation, evidence grade, adoption status, and caveats. Each rule references exact source IDs; project heuristics must be labelled as project rules and must not borrow classical attribution.

#### P0. Generation/overcoming chains lose direction and can alter verdicts

For a three-line chain `a -> b -> c`, `_analyzeChains` adds the same `连续相生` or `连续相克` term to all three members (`lib/domain/services/liuyao/analysis/sheng_ke_service.dart:138`, `lib/domain/services/liuyao/analysis/sheng_ke_service.dart:155`, `lib/domain/services/liuyao/analysis/sheng_ke_service.dart:175`). The tag records related positions but not edge direction or the selected line's role in the chain.

`VerdictService` treats any selected-use-spirit `连续相生` as an active source spirit and any `连续相克` as an active adverse spirit (`lib/domain/services/liuyao/analysis/verdict_service.dart:133`). Thus a use spirit that is feeding the chain can be misread as being fed by it, and a use spirit at the attacking head of an overcoming chain can be misread as the target.

Required direction: represent directed force occurrences (`from`, `to`, path/step order, active/suppressed state) and derive use-spirit factors only from edges whose target is the use spirit or whose directed path terminates at it.

#### P0. Actor activation/suppression is asymmetric

`jiActive` can be deactivated when every attacking moving line is itself restrained by return overcoming, retreat, or scatter (`lib/domain/services/liuyao/analysis/verdict_service.dart:137`). `yuanActive` has no equivalent check, so a restrained helper can still rescue the use spirit.

The generation/overcoming layer treats a moving line as joined only when joined to another line or the day (`lib/domain/services/liuyao/analysis/sheng_ke_service.dart:118`). It omits month join, although `SpecialService` marks month join of a moving line as binding (`lib/domain/services/liuyao/analysis/special_service.dart:19`), and the verdict treats a selected moving use spirit under month join as suspended (`lib/domain/services/liuyao/analysis/verdict_service.dart:329`). A month-bound helper or attacker can therefore still emit active `动爻生/克` facts.

Required direction: centralize actor availability (moving/hidden-moving, void/break/scatter, join, return restraint, advance/retreat) before force propagation, and use it symmetrically for helpers and attackers.

#### P0. Timing is parallel to, not derived from, verdict conditions

Timing is calculated before judgment (`lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:84`, `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:90`). `YingQiService` only receives the selected line, changed line, selected tags, and lunar context (`lib/domain/services/liuyao/analysis/ying_qi_service.dart:18`); it cannot see `VerdictCondition.hasRescue`, verdict trend, matter type, hidden/flying identity, or the final conflict outcome.

Consequences:

- hidden use-spirit timing cannot specifically calculate “clash the flying spirit” because flying-line identity is not an input;
- a hidden spirit already tagged `伏神得出` still receives an unresolved `待出伏` condition; only `hasRescue` changes (`lib/domain/services/liuyao/analysis/verdict_service.dart:361`; locked by `test/unit/services/liuyao/analysis/verdict_service_test.dart:252`);
- candidates are deduplicated by scale+branch by retaining only one reason, so one date that releases several conditions loses part of its evidence (`lib/domain/services/liuyao/analysis/ying_qi_service.dart:94`);
- generic value/clash/join candidates are generated even for unrescued/failure cases, leaving the prompt to explain why they do not imply success.

Required direction: judgment should output condition IDs and resolved/unresolved status first; timing should consume only eligible unresolved conditions and retain links to all conditions/rules a candidate may release. Matter-specific event timing can then be a later layer, separate from condition-release timing.

### Important completeness gaps

#### P1. Verdict semantics are question-agnostic

The verdict receives no matter context and always emits `可成/难成/待条件/趋势不明` (`lib/domain/services/shared/analysis/models/verdict_models.dart:15`; `lib/domain/services/liuyao/analysis/verdict_service.dart:64`). This is usable for “can it succeed?” but is not a complete semantic contract for illness, return/lost person, relationship, litigation, weather, pregnancy, or descriptive questions.

The golden suite itself includes illness and return questions but still asserts the same generic trend enum, showing that category-specific interpretation is currently outside the engine (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:204`, `test/unit/services/liuyao/analysis/verdict_golden_test.dart:381`).

Required direction: retain the four-value base trend, then add a matter-specific interpretation layer with explicit role mappings, target outcome, and unsupported/ambiguous status. The AI may verbalize this projection but should not invent category rules.

#### P1. Shi/Ying, gua-level facts, six spirits, and shen-sha are not part of verdict arbitration

`VerdictService` receives `mainGua` but uses it to find hidden-moving attackers/helpers; it does not consume Shi/Ying roles or gua-change tags. It receives neither six spirits nor daily shen-sha (`lib/domain/services/liuyao/analysis/verdict_service.dart:64`). Gua-level facts are computed separately (`lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:52`) and never passed into judgment.

The prompt nevertheless asks the model to analyze overall gua pattern, Shi/Ying, and six-spirit symbolism (`lib/ai/template/builtin_templates.dart:33`, `lib/ai/template/builtin_templates.dart:41`, `lib/ai/template/builtin_templates.dart:88`, `lib/ai/template/builtin_templates.dart:104`). This leaves the model to decide their weight and conflict with the deterministic use-spirit verdict.

Required direction: define them as typed secondary evidence with explicit precedence and category applicability. Do not allow generic six-join/six-clash or six-spirit symbolism to silently override the use-spirit verdict.

#### P1. Polarity is encoded as context-free good/bad

Strength and configuration services label facts such as `旺`, `动爻生`, `三合局`, six-join, and six-clash with intrinsic `ji/xiong` (`lib/domain/services/liuyao/analysis/wang_shuai_service.dart:7`; `lib/domain/services/liuyao/analysis/sheng_ke_service.dart:51`; `lib/domain/services/liuyao/analysis/he_chong_service.dart:162`; `lib/domain/services/liuyao/analysis/gua_change_service.dart:16`). The effect on the question depends on which actor is strengthened or constrained. A strong adverse spirit is not auspicious merely because “旺” has `ji` polarity.

The deterministic verdict mostly avoids counting these polarities, but the UI and AI receive them without actor-relative semantics. Replace or supplement intrinsic polarity with neutral fact direction plus contextual effect computed against a role/focus.

#### P1. Multiple actors are collapsed for display and explanation

`YongShenChain` stores only one source, one adverse, and one enemy-spirit position (`lib/domain/services/liuyao/analysis/models/analysis_report.dart:23`). `_findPosition` chooses the first moving occurrence, otherwise the lowest line (`lib/domain/services/liuyao/analysis/liu_qin_deduce_service.dart:98`). Other occurrences can still act through raw generation/overcoming facts but are not labelled as those roles in the chain/UI/prompt.

Use-spirit duplicates are listed, but selection has no rule-backed rationale; the analyzer simply accepts the user's line (`lib/domain/services/liuyao/analysis/liu_qin_deduce_service.dart:68`). A systematic flow needs candidate sets and explicit selection/suppression reasons rather than one representative position.

#### P1. Several semantic states are internally inconsistent

- `真空` is described as “到底无用” (`lib/domain/services/liuyao/analysis/kong_wang_service.dart:48`), yet its verdict condition says a filled date can bring a turn and may set `hasRescue=true` when strength is `mixed` (`lib/domain/services/liuyao/analysis/verdict_service.dart:292`). This may be a chosen interpretation, but the wording and executable behavior need one explicit source-backed contract.
- A hidden spirit already released remains an unresolved `待出伏` condition, noted above.
- Gua-level six-join is always `ji` with “主成”, while six-clash is neutral/xiong with “主散”; these broad statements lack question-category boundaries (`lib/domain/services/liuyao/analysis/gua_change_service.dart:16`).
- `AnalysisReport` comments say factors are in verdict order, but the initial factor order inherits UI tag priority rather than an explicit force-layer sequence (`lib/domain/services/shared/analysis/models/verdict_models.dart:81`; `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart:78`).

These should be resolved in the rule catalog before prompt tuning; prompt wording cannot repair contradictory executable semantics.

### AI prompt and projection defects that directly affect results

1. The system prompt allows the model to disagree with and replace the program verdict if it explains why (`lib/ai/template/builtin_templates.dart:49`). That conflicts with a deterministic “program computes, AI explains” boundary. Qimen's existing project contract demonstrates the stricter pattern (`mayOverrideVerdict=false`) in `lib/ai/template/builtin_templates.dart:545`.
2. The prompt asks for a clear, non-ambiguous conclusion (`lib/ai/template/builtin_templates.dart:39`) although `趋势不明` is a valid deterministic outcome. This encourages false certainty.
3. The analysis template asks the AI to determine the use spirit whenever a question exists, even if the user/program already selected one (`lib/ai/template/builtin_templates.dart:91`).
4. No prompt clause forbids fabricated classical quotations, source locations, pan facts, or unsupported timing. Only re-calculating some pan labels is discouraged (`lib/ai/template/builtin_templates.dart:49`).
5. The requested output has no evidence-chain/source section and no explicit conflict-resolution section (`lib/ai/template/builtin_templates.dart:83`).
6. `{{#if hasChangingGua}}` is used by the template (`lib/ai/template/builtin_templates.dart:85`), but Liuyao core data exposes `changingGuaName` and not `hasChangingGua` (`lib/ai/output/formatters/liuyao_formatter.dart:45`). The generic context only spreads existing core keys (`lib/ai/service/prompt_assembler.dart:143`), so the branch is false in real assembly. The template test manually injects `hasChangingGua`, masking the integration defect (`test/unit/ai/template/builtin_templates_test.dart:111`).
7. `TemporalInfo` supports hour pillar, but the Liuyao formatter does not populate it (`lib/ai/output/structured_output.dart:61`; `lib/ai/output/formatters/liuyao_formatter.dart:32`).
8. Active custom templates remain preferred over updated built-ins (`lib/ai/config/ai_config_manager.dart:252`). Updating built-ins therefore does not guarantee that existing users receive new safety/analysis instructions.
9. Existing conversations freeze the old prompt, model, and rendered pan (`lib/ai/model/cast_snapshot.dart:6`). A newly corrected derived report may be shown in UI while follow-up chat continues from an old report/prompt snapshot.

### Test coverage and gaps

#### Existing strengths

- Per-service suites cover the major tables and rule families under `test/unit/services/liuyao/analysis/`.
- Analyzer composition, UI selection/persistence, old JSON without use-spirit fields, relation graph, and timing UI have focused tests.
- The golden matrix records question, month/day, displayed hexagram/moving lines/use spirit, chapter/page, adjudication, expected trend, expected conditions/factors, and coverage domain (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:21`).
- Source nature is explicitly separated into original-book cases and rule-validation cases (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:18`).

#### Missing or weak gates

- Golden assertions use `containsAll` for conditions/factors/timing, so unexpected extra facts can pass (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:968`).
- Golden metadata strings (`hexagram`, `movingLines`, `yongShen`) are checked only for non-emptiness; they are not cross-checked against the computed `Gua`, moving positions, or selected line (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:932`). A transcription mismatch can remain green.
- No runtime test validates exact quotes, source IDs, edition revisions, evidence grades, or classic-vs-project attribution. The only factor-source assertion checks for the book title (`test/unit/services/liuyao/analysis/verdict_service_test.dart:320`).
- The Liuyao formatter has one test and only checks full Na Jia on a moving line (`test/unit/ai/output/formatters/liuyao_formatter_test.dart:8`). It does not test selected hidden use-spirit facts, complete judgment/condition/factor projection, citations, timing links, or rule versions.
- Built-in template tests are substring tests with hand-built variables rather than a real `LiuYaoResult -> formatter -> PromptAssembler` path (`test/unit/ai/template/builtin_templates_test.dart:53`).
- No test covers the direction of a continuous generation/overcoming chain relative to the selected use spirit.
- No test covers a source/helper that is itself return-overcome, retreated, scattered, or month-bound.
- No test covers invalid use-spirit position, misaligned changing gua, or malformed six-line contracts at the analyzer boundary.
- `TermGlossary` has no direct tests and no source completeness gate.
- The 40 golden cases test deterministic verdicts only; they do not test AI output quality or consistency with the evidence chain.

### Recommended target judgment stages

This is a structural target for planning; exact traditional rules and quotations must come from the separate classics audit.

1. **Input integrity and pan basis**: validate six-line ordering, changing-line alignment, calendar basis, cast method, and compatibility/rule-set versions.
2. **Matter context**: normalize the question into supported matter type, represented subject/object, relation to querent, desired outcome, and time horizon; emit ambiguous/unsupported status instead of guessing.
3. **Use-spirit resolution**: produce all visible/hidden candidates, user override, duplicate-selection rationale, Shi/Ying relevance, and missing/hidden conditions.
4. **Actor inventory**: retain all source/adverse/enemy/idle occurrences instead of one representative position.
5. **Base state**: month/day strength, void, break, tomb/absolute, and current availability for each relevant actor.
6. **Dynamic state**: moving/hidden-moving, transformation, advance/retreat, return effects, join/scatter, and actor suppression.
7. **Directed force graph**: generation/overcoming/support and join/clash paths with `from/to`, activation, suppression, and conflict links.
8. **Secondary evidence**: Shi/Ying, gua change, six spirits, and optional shen-sha, each with matter applicability and lower precedence.
9. **Conflict arbitration**: explicit precedence and first-match decision row, retaining supported, suppressed, and not-applicable occurrences.
10. **Base verdict plus matter interpretation**: four-value base trend, nuance, unresolved conditions, confidence/unsupported diagnostics, and category-specific wording.
11. **Timing**: derive condition-release candidates from unresolved rescuable conditions; separately derive event windows only where the matter rule authorizes them.
12. **AI projection**: immutable pan facts, selected focus, directed evidence chain, verdict, conditions, timing links, source catalog entries, and policy (`calculationOwner=program`, no override, no fabricated quote).

### Compatibility and migration risks

| Risk | Why it matters | Safe handling |
|---|---|---|
| Term rename changes behavior | Verdict/timing consume Chinese `term` strings | Add stable rule IDs first; dual-read IDs and legacy terms during transition; keep existing display terms |
| Rule fixes retroactively change old pans | Analysis is intentionally runtime-derived | Keep result storage unchanged, expose `analysisRuleSetVersion`, and show/report current analysis version |
| Old AI conversation disagrees with new UI | Conversation freezes old prompts while UI recomputes current report | Store/render analysis version in snapshot; require explicit reanalysis/reset to adopt new prompt/rules |
| Custom active templates bypass new policy | Custom templates are preferred to built-ins | Put non-overridable factual/policy guard at assembly boundary or explicitly version/migrate template capabilities; do not silently overwrite custom content |
| Auto use-spirit breaks user choice | Existing persisted position is a user-owned field | Treat explicit selection as override; store recommendations separately or derive at runtime |
| Expanded report breaks UI constructors/generated code | `AnalysisReport` and tags are Freezed models with many consumers | Prefer additive defaulted fields; regenerate code; keep category/term/priority fields until consumers migrate |
| Persisting analysis violates project convention | Rules are expected to evolve | Persist only user input/selection and optional immutable cast snapshot; keep analysis/projection derived |
| More AI evidence increases tokens | Current projection is compact text | Use a concise canonical projection, include only applicable rule/source excerpts, and measure prompt size in evaluation |
| Source corrections break current tests | One test assumes every factor says `增删卜易` | Replace title-substring checks with catalog-ID and evidence-grade checks |
| Timing redesign changes calendar markers | Calendar separately consumes day and month candidates | Preserve `YingQiScale` and current day/month behavior; add condition IDs without changing marker semantics first |

### Concrete implementation boundaries for the main task

- Keep pan computation and persisted `LiuYaoResult` backward compatible.
- Introduce a stable Liuyao rule/source catalog and typed occurrence/trace model before adding more rule terms.
- Fix force direction and actor-availability propagation before using more golden cases to tune verdict outcomes.
- Add matter/use-spirit resolution as a separate service; never bury selection in prompt prose.
- Make verdict conditions the upstream source for timing candidates.
- Build one analysis report per result and project it to UI/AI; avoid independent flattened reinterpretations.
- Add the complete analysis projection to `StructuredDivinationOutput` while retaining existing section keys/headings for custom-template compatibility.
- Make the system guard prohibit re-pan, rule recalculation, verdict override, fabricated quotes, and unsupported timing; allow AI only to explain and contextualize supplied facts.
- Baseline and optimized real-model evaluation should score fact fidelity, focus/use-spirit fidelity, verdict fidelity, condition/timing fidelity, citation fidelity, uncertainty discipline, and usefulness separately.

### Files found

- `.trellis/spec/domain/liuyao-analysis-engine.md` - Current locked Liuyao rule decisions, derived-data convention, verdict table, timing semantics, and test requirements.
- `.trellis/spec/domain/index.md` - Domain service purity and package ownership conventions.
- `.trellis/spec/guides/cross-layer-thinking-guide.md` - Typed boundary and single-owner payload guidance relevant to AI projection.
- `.trellis/spec/domain/qimen-analysis-engine.md` - Existing project precedent for versioned reports, stable rule/source IDs, evidence refs, trace, compatibility status, and AI policy.
- `.trellis/spec/domain/daliuren-rule-contract.md` - Existing project precedent separating rule identity, display term, evidence grade, source IDs, and rule-set versions.
- `lib/divination_systems/liuyao/liuyao_system.dart` - Cast input validation, pan construction, and historical result reconstruction.
- `lib/divination_systems/liuyao/liuyao_result.dart` - Persisted Liuyao result and user-selected use-spirit fields.
- `lib/divination_systems/liuyao/models/gua.dart` - Gua/palace/Shi-Ying/special-type contract.
- `lib/divination_systems/liuyao/models/yao.dart` - Per-line Na Jia, six-relative, five-element, movement, and Shi/Ying contract.
- `lib/domain/services/gua_calculator.dart` - Canonical pan and changing-gua calculation.
- `lib/domain/services/fushen_service.dart` - Hidden-spirit derivation from the palace pure gua.
- `lib/domain/services/liuyao/liuyao_shen_sha_service.dart` - Separate daily shen-sha facts, not currently part of analysis verdict/AI projection.
- `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart` - Sole deterministic analysis orchestrator.
- `lib/domain/services/liuyao/analysis/models/analysis_tag.dart` - Current display-term-based rule occurrence model.
- `lib/domain/services/liuyao/analysis/models/analysis_report.dart` - Runtime report, use-spirit chain, selected-use-spirit tags, timing, and verdict.
- `lib/domain/services/shared/analysis/models/verdict_models.dart` - Shared typed verdict, condition, factor, and timing candidate models.
- `lib/domain/services/liuyao/analysis/wang_shuai_service.dart` - Day/month strength facts.
- `lib/domain/services/liuyao/analysis/kong_wang_service.dart` - Void-state facts.
- `lib/domain/services/liuyao/analysis/mu_jue_service.dart` - Tomb/absolute-state facts.
- `lib/domain/services/liuyao/analysis/special_service.dart` - Day/month join and annual-branch facts.
- `lib/domain/services/liuyao/analysis/he_chong_service.dart` - Join/clash/configuration/punish/harm facts.
- `lib/domain/services/liuyao/analysis/dong_bian_service.dart` - Movement and transformation facts.
- `lib/domain/services/liuyao/analysis/sheng_ke_service.dart` - Moving-line force and chain facts.
- `lib/domain/services/liuyao/analysis/fu_shen_relation_service.dart` - Flying-hidden relations and release/restraint facts.
- `lib/domain/services/liuyao/analysis/liu_qin_deduce_service.dart` - Use/source/adverse/enemy/idle role inference.
- `lib/domain/services/liuyao/analysis/gua_change_service.dart` - Gua-level special/change facts.
- `lib/domain/services/liuyao/analysis/verdict_service.dart` - String-driven force collection, conditions, and first-match verdict table.
- `lib/domain/services/liuyao/analysis/ying_qi_service.dart` - Tag-driven timing candidates.
- `lib/domain/services/liuyao/analysis/models/term_glossary.dart` - Unsourced term definitions and implications.
- `lib/divination_systems/liuyao/viewmodels/liuyao_analysis_controller.dart` - UI analysis recomputation and use-spirit persistence.
- `lib/divination_systems/liuyao/ui/widgets/analysis_overview_card.dart` - UI use-spirit chain, verdict, and conditions.
- `lib/divination_systems/liuyao/ui/liuyao_result_screen.dart` - Result/UI/calendar integration.
- `lib/ai/output/formatters/liuyao_formatter.dart` - Liuyao-to-AI flattening boundary.
- `lib/ai/service/prompt_assembler.dart` - Active-template lookup and final prompt assembly.
- `lib/ai/template/builtin_templates.dart` - Current Liuyao system, analysis, brief, and unused question templates.
- `lib/ai/config/ai_config_manager.dart` - Built-in template refresh and custom active-template precedence.
- `lib/ai/model/cast_snapshot.dart` - Frozen prompt/model contract for AI conversations.
- `test/unit/services/liuyao/analysis/` - Unit suites for the deterministic services and verdict.
- `test/unit/services/liuyao/analysis/verdict_golden_test.dart` - Forty-case source-labelled verdict matrix.
- `test/unit/divination_systems/liuyao/liuyao_analysis_controller_test.dart` - Use-spirit persistence and old-JSON compatibility tests.
- `test/unit/ai/output/formatters/liuyao_formatter_test.dart` - Minimal Liuyao formatter test.
- `test/unit/ai/template/builtin_templates_test.dart` - Prompt substring/Handlebars tests.
- `docs/architecture/divination-systems/liuyao.md` - Pan/result/UI architecture; analysis section is partial and contains an outdated statement at line 309 that hidden spirits are not really integrated.

### Related specs

- `.trellis/spec/domain/liuyao-analysis-engine.md`
- `.trellis/spec/domain/index.md`
- `.trellis/spec/guides/cross-layer-thinking-guide.md`
- `.trellis/spec/guides/code-reuse-thinking-guide.md`
- `.trellis/spec/domain/qimen-analysis-engine.md` (project precedent, not a Liuyao rule source)
- `.trellis/spec/domain/daliuren-rule-contract.md` (project precedent, not a Liuyao rule source)

### External references

No external source was consulted for this code audit. The repository internally names `《增删卜易》` as the primary adjudication basis and `《卜筮正宗》` as a low-priority supplement, but the exact editions, quotations, page locators, and interpretation boundaries require the separate classics/source audit before implementation.

## Caveats / Not Found

- This was a static internal audit. Tests were not executed by this research agent.
- `devtools_options.yaml` was deliberately not opened; model credentials and provider configuration are outside this subtask and must never be copied into research, logs, snapshots, or commits.
- No standalone Liuyao source catalog, rule catalog, evidence-grade model, analysis rule-set version, trace model, or canonical structured AI projection was found.
- No end-to-end Liuyao test was found that assembles a real result and question into the final prompt and asserts complete verdict/evidence/source fidelity.
- No direct test of `TermGlossary` completeness or attribution was found.
- Exact traditional correctness of disputed rules was not re-adjudicated here; the findings identify code/data-flow gaps and internal inconsistencies. The classics audit should decide the final rule semantics.
