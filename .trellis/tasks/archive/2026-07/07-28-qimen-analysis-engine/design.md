# 奇门遁甲规则分析引擎设计

## 1. 边界与数据流

```text
QimenResult (pan schema v1, persisted and already validated)
  -> QimenAnalysisInputGuard (shape/schema check only)
  -> QimenFocusResolver (locate existing indicators)
  -> Qimen fact evaluators (read-only derived facts)
  -> QimenConflictResolver (explicit precedence, retain suppressed facts)
  -> QimenVerdictService (ordered table, first match)
  -> QimenYingQiService (conditions/facts -> candidates)
  -> QimenAnalysisReport (derived, versioned, serializable, not persisted)
  -> UI / QimenAnalysisProjection -> AI formatter (next child task)
```

The analysis package may import Qimen result/model types and shared five-element, stem/branch, polarity, and verdict value objects. It must not import Qimen time, ju, earth/heaven plate, duty, door, deity, hidden-stem, or marker placement services. Relation checks such as “door element restrains palace element” are analysis rules; changing an entity's palace is pan calculation and forbidden here.

## 2. Hard Dependency Contract

Implementation starts only after `07-28-qimen-pan-engine` is completed and archived. At kickoff, record its commit and confirm the final names rather than assuming this draft's names. The required semantic inputs are:

- `QimenResult.schemaVersion`, stable result ID, pan params, temporal context, ju info, and nine typed palaces.
- Each palace's fixed number/metadata, primary and hosted earth/heaven stems, primary and hosted stars, door, deity, hidden stem, void branches, horse flag, and pan markers.
- Result-level day/hour pillars, xun shou and hidden instrument, duty star/door and their palaces, kong-wang branches, horse branch/palace, and derivation steps.
- Frozen pan-engine JSON fixtures whose full nine-palace content has already passed sourced golden tests.

`QimenAnalysisInputGuard` verifies supported schema and required values but never repairs them. A missing hosted field is valid only when the selected pan convention says none should exist. Any model mismatch discovered at kickoff returns the task to planning before analysis code is written.

## 3. Proposed File Boundary

```text
lib/domain/services/qimen/analysis/
  qimen_analyzer.dart
  qimen_analysis_input_guard.dart
  qimen_focus_resolver.dart
  qimen_conflict_resolver.dart
  qimen_verdict_service.dart
  qimen_ying_qi_service.dart
  facts/
    qimen_star_door_state_service.dart
    qimen_constraint_fact_service.dart
    qimen_structure_fact_service.dart
    qimen_stem_response_service.dart
    qimen_formation_service.dart
  models/
    qimen_analysis_models.dart
    qimen_rule_models.dart
    qimen_ying_qi_models.dart
  rules/
    qimen_rule_catalog.dart
    qimen_source_catalog.dart
    qimen_focus_catalog.dart
    qimen_verdict_table.dart

test/unit/services/qimen/analysis/
  fixtures/
  *_test.dart
  qimen_analysis_golden_test.dart
```

Small files may be combined when the responsibility remains obvious. The rule/source catalog, conflict policy, and verdict table each have exactly one owner; evaluators must not duplicate table literals or source strings.

## 4. Versioned Models

All serialized enums expose stable `id` / `fromId`; generated default `enum.name` is not a wire contract.

### 4.1 Versions and status

- Analysis schema: integer `1`, governing `QimenAnalysisReport` JSON shape.
- Rule set ID: `qimen-shijia-zhuanpan-analysis`.
- Initial immutable version: `v1`; a registry resolves an explicit version and a single `current` alias.
- `QimenAnalysisStatus`: `complete`, `unsupportedPanSchema`, `invalidPanFacts`.
- `analyze(result, ruleSetVersion: current)` is deterministic. Tests can request an older registered version; changing rule meaning creates a new version instead of mutating v1.

### 4.2 Evidence and rule definitions

`QimenSourceRef`:

- `sourceId`, `kind` (`classicalText`, `modernReference`, `publishedCase`, `externalCrossCheck`, `projectConvention`).
- `title`, `editionOrRevision`, `locator` (chapter/page or stable URL+commit), optional short quotation/claim summary, `accessedOn` where relevant, and adjudication note.

`QimenRuleDefinition`:

- Stable `ruleId`, family/category, introduced rule-set version, display term, fact role, conflict tier, supported scopes, source IDs, and evaluator ID.
- Optional explicit `resolvesRuleIds` / `suppressedByRuleIds`; there is no numeric weight.
- Catalog validation fails on duplicate/unknown IDs, absent evidence, circular conflict pairs, or a decision-capable project convention without an adjudication note.

### 4.3 Facts, focus, and trace

`QimenFact` contains:

- Stable occurrence ID (`ruleId` plus deterministic target key), `ruleId`, rule-set version, category, `Polarity`, and semantic role (`support`, `inhibit`, `suspend`, `neutral`).
- Scope (`global`, `palace`, `focusRelation`), sorted related palace numbers and focus role IDs.
- Human-readable reason plus structured input references (`QimenResult` field path + normalized value), source IDs, and producing trace-step ID.
- Conflict tier (`decisive`, `conditional`, `corroborating`, `contextual`). The enum is precedence only, never a score.

`QimenFocus` contains a stable role ID, indicator kind/value, existing palace number, primary/secondary designation, reason, rule ID, and source IDs. A focus can reference an entity hosted into another palace without erasing its original/hosted distinction.

`QimenTraceStep` contains sequence, stage (`input`, `focus`, `fact`, `conflict`, `verdict`, `yingQi`), rule ID, evaluation status (`matched`, `notMatched`, `notApplicable`, `suppressed`), input refs, output occurrence IDs, source IDs, and explanation. Full traces retain non-matches for audit; UI/AI projection may select matched/suppressed steps without changing the report.

`QimenConflictResolution` records policy ID, contenders, optional winner, suppressed occurrence IDs, and reason. Suppressed facts remain in `facts` and trace.

### 4.4 Verdict, YingQi, and report

Reuse shared `Polarity`, `VerdictTrend`, `VerdictEffect`, `VerdictFactor`, `VerdictCondition`, and `VerdictJudgment` where their semantics fit. Qimen-specific audit data remains alongside them:

- `QimenVerdictResult`: shared judgment, matched decision-row ID, participating fact IDs, conflict-resolution IDs, and source IDs.
- `QimenYingQiCandidate`: candidate ID, rule ID, trigger kind (`stem`, `branch`, `solarTerm`, `conditionRelease`), normalized trigger value, `YingQiScale`, semantic order band, reason, related fact/condition IDs, and source IDs. This separate type is required because shared `YingQiCandidate` assumes a branch and cannot represent all Qimen triggers without a breaking cross-system change.
- `QimenAnalysisReport`: analysis schema, rule-set ID/version, input pan schema/result ID, status, focus list, facts, conflicts, verdict, candidates, and trace.

The report implements stable `toJson` / `fromJson` for snapshots and downstream projections. It is still derived data and is never placed inside `QimenResult` or repository records.

## 5. Focus Resolution

Day stem (`self`) and hour stem (`matter`) are always the two primary roles. Category rules add secondary indicators already present in the pan:

| Category | Secondary indicators in v1 | Boundary |
|---|---|---|
| `general` | duty star, duty door | context only |
| `career` | Open Door, duty star | cannot replace self/matter |
| `wealth` | Life Door, Wu instrument | cannot infer an amount |
| `relationship` | Yi, Geng, Liu He | gender-neutral pair; no unstated sex role |
| `health` | Tian Rui, Tian Xin/Yi | disease and treatment indicators kept separate |
| `study` | Tian Fu, Jing Door, Ding | secondary evidence only |
| `travel` | Open Door, horse | horse is activation context |
| `litigation` | Jing Door, Geng, duty door | no legal-outcome guarantee |

Every row is a versioned focus rule. Where a direct source does not uniquely prescribe the mapping, it is marked `projectConvention` and documented as “本项目约定（奇门分析 v1）”. Multiple occurrences follow an explicit hosted/primary resolution rule; unresolved ambiguity produces an input/focus trace and conservative verdict rather than choosing the first list item.

## 6. Fact Rule Catalog v1

### 6.1 State and constraint facts

- `QimenStarDoorStateService`: nine-star and eight-door seasonal/palace state tables. It reads persisted month/solar-term facts and palace metadata; the table and source exist once in the rule catalog.
- `QimenConstraintFactService`: door pressure, six-instrument punishment, Qi/Yi entering tomb, palace/indicator void, and horse activation. Main and hosted stems/stars are evaluated as distinct occurrences.
- A rule that only describes a condition is tagged `suspend` or `contextual`; polarity alone does not make it a verdict blocker.

### 6.2 Structural facts

`QimenStructureFactService` identifies star/door pan Fu Yin and Fan Yin separately, plus their combined form, and evaluates Five-Not-Meeting-Time from persisted day/hour pillars. It must not reconstruct pillars. Exact variants and whether they are decisive, conditional, or contextual are stated in the catalog rather than hidden in service branches.

### 6.3 Stem responses and formations

- `QimenStemResponseService` owns the complete heaven-stem/earth-stem response table used by v1. Each table row has its own rule ID and evidence; primary and hosted pairs produce separate fact occurrences.
- `QimenFormationService` owns source-locked Three-Wonders auspicious formations, the nine Dun formations, and common adverse formations. The initial adverse catalog must explicitly decide at least: 青龙逃走、白虎猖狂、朱雀投江、螣蛇夭矫、荧入太白、太白入荧、大格、小格、刑格、飞宫格、伏宫格、天网四张. Exact formulas are admitted only after source-catalog and fixture validation.
- A named formation not present in the v1 catalog is not inferred from text or emitted as a free-form tag.

The shipped `三奇得使` predicate is catalog-owned and directional: heaven/earth
stem pairs are exactly `乙+己`, `乙+辛`, `丙+戊`, `丙+庚`, `丁+壬`, and
`丁+癸`. Primary and hosted pairs are evaluated as separate occurrences.

The nine Dun predicates are likewise catalog data rather than evaluator branches:

| Rule | Exact v1 predicate |
|---|---|
| 天遁 | 天盘丙 + 地盘丁 + 生门 |
| 地遁 | 天盘乙 + 地盘己 + 开门 |
| 人遁 | 天盘丁 + 休门 + 太阴 |
| 风遁 | 天盘乙 + 开/休/生门 + 巽四宫 |
| 云遁 | 天盘乙 + 地盘辛 + 开/休/生门 |
| 龙遁 | 天盘乙 + 休门 + 坎一宫 |
| 虎遁 | 天盘乙 + 地盘辛 + 休门 + 艮八宫 |
| 神遁 | 天盘丙 + 生门 + 九天 |
| 鬼遁 | 天盘乙 + 杜门 + 九地 |

The admitted human-Dun variant is `丁+休门+太阴`; the alternate witness
using a lower `丙` component remains source metadata and is not OR-ed into the v1
predicate. Dragon, tiger, and ghost Dun are evaluated independently, so sharing
`天盘乙` never makes one imply another.

## 7. Conflict Policy and Ordered Verdict

### 7.1 Conflict precedence

Conflict resolution is lexicographic and declarative:

1. Input/schema integrity precedes all interpretation.
2. An explicit paired resolver (rescue, suppression, or incompatibility) in the catalog applies before general precedence.
3. A fact attached to `self` or `matter` precedes an otherwise equal secondary/global fact; primary versus hosted status remains explicit.
4. Conflict tier order is `decisive -> conditional -> corroborating -> contextual`.
5. Opposed facts at the same target and tier with no resolver remain unresolved; neither is deleted and the verdict table receives an explicit conflict flag.

This policy never sums, averages, counts, or converts source quality into outcome weight.

### 7.2 v1 decision table

`QimenVerdictService` builds a typed adjudication context from resolved facts and evaluates these rows in order:

| Row ID | Predicate | Result |
|---|---|---|
| `QMV1-D00` | unsupported/invalid input or no unique primary focus | 趋势不明 |
| `QMV1-D10` | decisive blocker on self/matter, and its catalog rule has no active explicit rescue | 难成 |
| `QMV1-D20` | one or more decisive/conditional conditions on self/matter have a source-defined release path | 待条件 |
| `QMV1-D30` | category-specific adverse convergence rule matches self + matter (or the category's named primary pair), with no higher rescue | 难成 |
| `QMV1-D40` | category-specific favorable convergence rule matches and there is no unresolved decisive/conditional opposition | 可成 |
| `QMV1-D50` | decisive support and inhibition remain in unresolved conflict | 趋势不明 |
| `QMV1-D60` | only corroborating/contextual facts, or no decision-capable rule | 趋势不明 |

“Convergence” is itself a catalog rule naming the exact required facts and targets, not a threshold over a count. Conditions are generated before the table and linked to the facts that created them. The final factor list follows reasoning order: focus -> participating facts -> conflict/rescue -> conditions -> matched decision row.

## 8. YingQi Rules

v1 candidates are symbolic observation windows. Admitted families are:

- filling/releasing a void branch;
- clashing/opening a source-defined tomb or constrained state;
- horse activation tied to the relevant focus;
- moving a Fu-Yin state or reaching a Fan-Yin transition, only where a source rule specifies the trigger;
- a stem, branch, duty indicator, or solar-term arrival explicitly named by a matched rule.

The service receives the verdict conditions and matched facts; it cannot inspect raw time to invent another path. Candidate order uses semantic bands (`conditionRelease`, `focusActivation`, `contextWindow`) followed by rule ID and trigger key. Deduplication key is `(scale, triggerKind, triggerValue, targetFocus)`; merging unions fact/condition/source IDs in stable order. A candidate with no upstream fact/condition or source is invalid.

## 9. Provenance and Golden Policy

The source hierarchy governs admission, not auspiciousness:

1. A cited classical/primary text or a published worked case with identifiable edition and locator.
2. A cited modern reference that states its adopted school/convention.
3. An external implementation used only to cross-check a formula or pan snapshot.
4. A project convention used for deterministic product behavior and labeled as such.

Disputed rules require either two independent references that agree, or one traceable reference plus an explicit project adjudication explaining the chosen variant. External code alone cannot authorize a decision-capable rule.

Typed golden cases contain: case ID/title, source nature, full citation, pan fixture ID and pan-engine commit/schema, question category, manual adjudication note, expected focus roles, matched fact rule IDs, conflict outcomes, decision-row ID/trend/conditions, YingQi rule IDs/triggers, rule-set version, and coverage tags.

The final source-backed matrix has 14 cases. `QM-G16` preserves the published
promotion example and its favorable convergence, but its persisted `matter`
focus lies in the 辰巳-void 巽四 palace; frozen first-match ordering therefore
returns `QMV1-D20`, not `QMV1-D40`. `QM-G17` is explicitly a classical-formula
witness (not a historical worked pan): 坎一 `戊+丙` and 巽四 `乙+己`
lock 青龙返首 and 三奇得使, while its complete pan has favorable
convergence without a higher condition and therefore supplies the source-backed
`QMV1-D40` / `可成` trend.

The suite has two intentionally separate populations:

- At least 12 source-backed end-to-end interpretation cases from at least two independent published/public sources.
- Explicitly labeled synthetic chapter/table/boundary cases used to cover every rule, non-match, decision row, conflict path, and question category.

Meta-tests validate source distribution and coverage floors. A software snapshot is accepted only when two independent implementations agree or the fixture includes a documented manual derivation against a cited rule.

## 10. Serialization, History, and AI Projection

- `QimenAnalysisReport` JSON is a deterministic diagnostic/export wire format with `schemaVersion=1`; all IDs are stable and lists use canonical ordering.
- Report round-trip uses actual `jsonEncode` -> `jsonDecode` -> `fromJson`, followed by deep equality. Unknown additive fields may be ignored within a supported schema; unknown schema versions return an explicit compatibility error.
- Repository records keep only the pan-engine `QimenResult`. On reopen, `QimenSystem.resultFromJson()` restores the exact pan, then the analyzer runs. Rule upgrades therefore affect derived analysis by design without rewriting history.
- Rule-set registry keeps released versions addressable. The product normally selects `current`; golden tests pin explicit versions, and rollback changes the current alias instead of modifying stored records.
- `QimenAnalysisProjection` is a lossless program-produced subset for the later formatter. It includes policy IDs such as `calculationOwner=program`, `mayRecalculatePan=false`, and `mayOverrideVerdict=false`, along with pan field references, facts, verdict, conditions, candidates, sources, and versions. It contains no request for AI to derive placements.

## 11. Determinism and Failure Behavior

- No service reads current time, locale, device zone, random state, persistence, UI state, or network.
- Canonical ordering: focus role order, fact conflict tier/category/rule ID/target, conflict policy/rule ID, decision factors in reasoning order, candidates by semantic band/rule ID/trigger, trace by sequence.
- Unsupported pan schema or invalid pan facts yield a diagnostic report with no normal facts/candidates, a stable error code, and the `QMV1-D00` judgment. Deserializing an unsupported analysis-report schema raises a typed compatibility exception. Both paths name the exact missing/invalid field and supported versions; UI fallback belongs to the product-integration child.
- Unknown rule/source IDs fail fast in development and fixtures. Production selection can only use registered released rule sets.

## 12. Test Architecture

- Catalog tests: unique IDs, valid source references, conflict graph sanity, complete enum ID round-trips, no forbidden scoring fields.
- Evaluator tests: every rule has positive and negative cases; finite tables (stem responses, states, focus mappings) are exhaustively compared with independent expected tables.
- Focus/conflict/verdict tests: all eight categories, hosted/multiple indicators, each policy branch, each decision row, uniqueness of first match, and invariance under irrelevant extra facts.
- YingQi tests: every generator and non-generator, condition linkage, structural dedupe, merged evidence, stable ordering, and no outcome guarantee wording.
- Analyzer tests: frozen pan-engine JSON -> full report, no pan-service dependency, determinism, invalid/unsupported input, and trace integrity.
- Golden tests: sourced whole-analysis matrix plus synthetic rule coverage, with meta-tests preventing missing provenance or reduced coverage.
- Wire/history tests: real report JSON deep round-trip; persisted Qimen result contains no analysis; repository/resultFromJson reopen followed by reanalysis; explicit old/current rule-version selection.
- Regression: shared verdict models, LiuYao, and Daliuren tests remain green.

## 13. Trade-offs and Rollback

- A Qimen-specific YingQi model adds a small adapter cost in the next UI task, but avoids weakening the shared branch-only model or making a breaking change to existing systems.
- Full trace and source metadata make reports larger, but reports are derived and not stored in the database. The AI projection may omit non-matches while retaining all matched/conflict evidence.
- Conservative fallbacks yield more “趋势不明” than a score-based engine. This is intentional: only explicit convergence rules may produce a decisive result.
- The analysis module is not registered in the product during this child task. A bad rule release is rolled back by restoring the previous current rule-set alias or reverting this child commit; no pan or database migration is required.
