# 奇门遁甲规则分析引擎执行计划

## 0. Hard Dependency Gate

- [x] 0.1 Confirm `07-28-qimen-pan-engine` has passed its checks, is committed, completed, and archived. Frozen dependency: work commit `7d226a6`, `QimenResult.currentSchemaVersion=1`, archived under `.trellis/tasks/archive/2026-07/07-28-qimen-pan-engine/`.
- [x] 0.2 Record the pan-engine commit, `QimenResult.schemaVersion`, final model paths/field names, stable enum IDs, and frozen golden fixture paths in this task's implementation evidence.
- [x] 0.3 Run the pan-engine target tests and validate complete nested JSON equality before consuming any fixture.
- [x] 0.4 Compare the delivered pan contract with this PRD/design. If fields, schema, hosting semantics, or golden outputs differ materially, revise the three planning artifacts and return to the user review gate before implementation.

This dependency is hard: mocks, copied palace maps, or a locally invented temporary `QimenResult` do not satisfy it.

### Dependency Evidence (2026-07-28)

- Frozen pan implementation: `7d226a690fa411ca1fe74f021c0fa54dca875f2c`.
- Input schema: `QimenResult.currentSchemaVersion == 1` in
  `lib/divination_systems/qimen/models/qimen_result.dart`.
- Frozen typed inputs: `qimen_result.dart`, `qimen_palace.dart`,
  `qimen_pan_params.dart`, `qimen_temporal_context.dart`, `qimen_ju_info.dart`,
  and stable IDs in `qimen_enums.dart`.
- Hosted facts remain separate in `hostedEarthStem`, `hostedHeavenStem`, and
  `hostedStar`; no analysis-side placement compatibility is required.
- Frozen source fixture:
  `test/unit/services/qimen/fixtures/qimen_golden_fixtures.dart`.
- Revalidated with `flutter test test/unit/services/qimen
  test/unit/divination_systems/qimen
  test/unit/data/repositories/qimen_repository_roundtrip_test.dart`: 36 tests
  passed, including complete nested result JSON and repository round-trip.
- The delivered pan contract matches the reviewed PRD/design. Analysis can
  read all required fields directly and must not import a pan-stage service.

## 1. Freeze Rule and Evidence Contracts First

- [x] 1.1 Read the domain index, LiuYao/Daliuren analysis specs, shared thinking guides, parent Qimen research, final pan-engine design/spec, and its sourced fixtures.
- [x] 1.2 Create the typed source catalog with stable IDs and complete citation/adjudication fields.
- [x] 1.3 Create the v1 rule catalog skeleton for focus, state, constraints, structure, stem responses, auspicious/adverse formations, conflicts, verdict rows, and YingQi.
- [x] 1.4 Build the coverage manifest mapping every rule ID to source IDs, positive/negative tests, decision/conflict use, and golden coverage tags. Catalog validation must fail while any required cell is empty.
- [x] 1.5 Curate at least 12 source-backed end-to-end cases from at least two independent published/public sources; mark synthetic chapter/table/boundary cases separately. Do not use one external implementation snapshot as the sole authority.

Review gate: source/catalog/fixture metadata and the exact v1 formulas are reviewed before evaluator implementation. Ambiguous formulas stay excluded or contextual; they are not guessed in code.

## 2. Add Versioned Models and Wire Tests

- [x] 2.1 Add stable-ID enums and immutable models for source refs, rule definitions, focus, facts, input refs, trace, conflicts, Qimen verdict wrapper, Qimen YingQi candidates, and the analysis report.
- [x] 2.2 Reuse shared polarity/verdict value objects where compatible; keep Qimen's non-branch triggers in a Qimen-specific YingQi model rather than breaking existing consumers.
- [x] 2.3 Implement the immutable rule-set registry with explicit v1 and current selection. Released v1 behavior must not be mutated in place.
- [x] 2.4 Implement report JSON codecs with stable IDs and canonical ordering; add real JSON wire round-trip, unknown-schema, and unknown-ID tests.
- [x] 2.5 Add forbidden-contract tests or static assertions preventing score, percent, star-rating, weighted-total, and tag-count threshold fields.

Rollback point: models/catalog only. No analyzer is exposed until their wire and validation tests pass.

## 3. Implement Input Guard and Focus Resolver

- [x] 3.1 Implement schema/shape validation over the frozen `QimenResult`; return explicit unsupported/invalid behavior without recalculating the pan.
- [x] 3.2 Implement day-stem self and hour-stem matter location from existing palace fields, including primary/hosted provenance.
- [x] 3.3 Implement all eight versioned category focus rows and source/project-convention labels.
- [x] 3.4 Cover missing, duplicate, hosted, center-palace, and multi-indicator cases with table tests; ambiguous primary focus must choose the conservative path.
- [x] 3.5 Add an architecture check that the analysis package imports no Qimen placement/ju/time service.

## 4. Implement Fact Evaluators Table-First

- [x] 4.1 Implement nine-star/eight-door state facts from one source-locked table and persisted temporal/palace fields.
- [x] 4.2 Implement door pressure, six-instrument punishment, Qi/Yi tomb, void, and horse facts, preserving main versus hosted occurrences.
- [x] 4.3 Implement star/door Fu Yin/Fan Yin and Five-Not-Meeting-Time from persisted facts only.
- [x] 4.4 Implement the complete v1 heaven/earth stem-response table with exhaustive independent expected-table tests.
- [x] 4.5 Implement source-admitted Three-Wonders formations, nine Dun, and the locked adverse-formation catalog.
- [x] 4.6 For every rule, add positive and negative tests asserting rule ID, role/tier, palace/focus links, input refs, evidence refs, and trace status.

Review gate: the fact layer emits no overall verdict and does not suppress facts. Its output must be identical when irrelevant display text changes.

## 5. Implement Conflict Resolution and Verdict

- [x] 5.1 Implement the declarative precedence policy: integrity -> explicit pair resolver -> focus specificity -> tier -> unresolved same-tier conflict.
- [x] 5.2 Preserve every contender and record winner/suppressed IDs plus the policy and reason; never delete losing evidence.
- [x] 5.3 Build typed conditions only from source-defined release paths. Do not convert every adverse fact into an automatic negative result.
- [x] 5.4 Implement `QMV1-D00` through `QMV1-D60` in fixed first-match order and return the matched row ID with shared four-value judgment.
- [x] 5.5 Add one isolated test per row and per conflict policy, overlap tests proving only the first row wins, and metamorphic tests proving unrelated extra tags do not change the verdict.
- [x] 5.6 Search for arithmetic scoring, label counts, percent/rating terminology, or sorting by auspiciousness totals and remove any such path.

Rollback point: if a golden adjudication disagrees, correct the source adjudication/catalog/design first, then the expected fixture, then code. Never patch row order solely to make one fixture green.

## 6. Implement YingQi Candidates

- [x] 6.1 Implement admitted condition-release, primary-focus horse activation, and solar-term triggers; retain disputed Fu-Yin/Fan-Yin and stem-arrival predicates as explicit `notApplicable` trace entries.
- [x] 6.2 Require each candidate to link to upstream fact/condition IDs and source IDs; orphan candidates are validation errors.
- [x] 6.3 Implement structural deduplication and stable evidence merging with semantic order bands, not numeric auspiciousness/confidence scores.
- [x] 6.4 Add positive, negative, dedupe, ordering, and conflicting-trigger tests; all summaries state that candidates are observation windows and do not decide success.

## 7. Assemble Analyzer, History Contract, and Projection

- [x] 7.1 Implement the pure orchestration order: guard -> focus -> facts -> conflicts -> verdict -> YingQi -> report/trace.
- [x] 7.2 Run the analyzer against frozen pan-engine JSON fixtures and assert full normalized report snapshots and repeat-run determinism.
- [x] 7.3 Prove report JSON deep round-trip while keeping `QimenResult.toJson()` and repository payload free of analysis fields.
- [x] 7.4 Add history reopen coverage: deserialize persisted pan schema v1, reanalyze under an explicit/current rule version, and handle unsupported future schemas without a crash or silent fallback.
- [x] 7.5 Add `QimenAnalysisProjection` for the next child task, including program ownership and no-recalculation/no-override policy fields. Do not implement an AI formatter or call AI in this task.

## 8. Golden, Documentation, and Regression Gate

- [x] 8.1 Complete the sourced + synthetic golden matrix and meta-tests for source distribution, yin/yang Dun, all rule families, all question categories, all four trends, every decision row, and every conflict/YingQi rule.
- [x] 8.2 Add `.trellis/spec/domain/qimen-analysis-engine.md` with the shipped rule/version/source/conflict/history contracts and update the Qimen system architecture document only where this child owns the analysis contract.
- [x] 8.3 Run code generation and format only owned source/test paths.
- [x] 8.4 Run target analysis tests, pan-to-analysis integration tests, report/history wire tests, shared model regressions, `flutter analyze`, and the full suite.
- [x] 8.5 Dispatch `trellis-check` for source accuracy, spec compliance, no-scoring/no-recalculation architecture, cross-layer serialization, and test completeness. Fix findings and repeat the complete gate.
- [x] 8.6 Update release notes/specs as required by the finish workflow, commit and archive this child independently, then allow `07-28-qimen-product-integration` to consume the frozen report/projection contract. Work commit: `a83647e`.

### Final Verification Evidence (2026-07-28)

- `dart run build_runner build --delete-conflicting-outputs`: completed; no tracked generated-file drift.
- `flutter test test/unit/services/qimen/analysis`: 105 passed.
- Whole-pan golden suite: 38 passed; 17 cases (12 source-backed + 5 explicit synthetic) and stable SHA-256 `9DE7FAA2A9247AB6C4071E2D86BD51440FC0BD9BDF46DDCE96F09FB37BFC14A4`.
- `flutter analyze`: no issues found.
- Qimen-scoped `dart analyze` recheck after unrelated concurrent Daliuren edits: no issues found.
- `flutter test`: 1,021 passed across the complete repository.
- `python ./.trellis/scripts/task.py validate 07-28-qimen-analysis-engine`: all context manifests valid.
- Architecture searches found no pan-stage service imports or calls in production analysis code; scoring terms occur only in explicit prohibition tests/explanations.

## Validation Commands

Final paths must be adjusted to the actual pan-engine delivery rather than allowing nonexistent paths to pass silently.

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format lib/domain/services/qimen/analysis test/unit/services/qimen/analysis
flutter analyze
flutter test test/unit/services/qimen/analysis
flutter test test/unit/services/qimen/analysis/qimen_analysis_golden_test.dart
flutter test test/unit/divination_systems/qimen
flutter test test/unit/data/repositories/qimen_repository_roundtrip_test.dart
flutter test test/unit/services/liuyao/analysis test/unit/services/daliuren/analysis
flutter test
python ./.trellis/scripts/task.py validate 07-28-qimen-analysis-engine
```

Additional audit searches:

```powershell
rg -n "score|rating|percent|percentage|weighted|tagCount|标签数量|百分|星级|加权" lib/domain/services/qimen/analysis test/unit/services/qimen/analysis
rg -n "qimen_(time|ju|earth_plate|duty|heaven_plate|door|deity|hidden_stem|marker)_service" lib/domain/services/qimen/analysis
rg -n '"analysis"' lib/divination_systems/qimen test/unit/data/repositories/qimen_repository_roundtrip_test.dart
```

The first two searches are expected to find only explicit prohibition tests/comments or no production matches; any production logic match is a failed gate.

## Risk and Rollback

- Highest risk is false certainty from disputed traditional rules. Mitigation: source admission gate, explicit project-convention labels, immutable rule versions, conservative fallback, and sourced golden adjudication before code.
- Pan-model drift can invalidate every fact. Mitigation: hard dependency, pinned commit/schema/fixtures, no temporary copied model, and an architecture import check.
- Shared verdict changes could regress LiuYao/Daliuren. Prefer Qimen wrappers; any necessary additive shared-model change requires all existing analysis tests and generated-code review.
- Full trace may increase memory/AI payload size. Keep the complete report in memory only and project a matched/conflict subset for AI without dropping provenance.
- Roll back by restoring the previous current rule version or reverting this isolated child commit. Since reports are not persisted and the product is not registered here, no database or historical-data rollback is required.
