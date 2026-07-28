# Research: Daliuren analysis and presentation cross-layer audit

- Query: Audit `lib/domain/services/daliuren/analysis`, its models/tests, the Daliuren result UI, viewmodel/system integration, and AI formatter; map implemented, partial, and missing capabilities; identify correctness risks, cross-layer contract gaps, and weak or tautological tests; distinguish confirmed defects from hypotheses.
- Scope: internal
- Date: 2026-07-28

## Findings

The repository has a real end-to-end v1 pipeline rather than a placeholder: a newly cast `DaLiuRenResult` is built from the pan services, analyzed at runtime into a `DaLiuRenAnalysisReport`, displayed in the result page, and independently formatted for AI (`lib/divination_systems/daliuren/daliuren_system.dart:159-195`, `lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:17-78`, `lib/divination_systems/daliuren/ui/daliuren_result_screen.dart:24-60`, `lib/ai/output/formatters/daliuren_formatter.dart:27-41`). The system/UI/AI registries also register the three entry points (`lib/divination_systems/registry_bootstrap.dart:93-108`, `lib/ai/ai_bootstrap.dart:139-147`).

That pipeline is complete only against the archived 07-27 **project v1** contract. The project spec explicitly says the verdict table and tag wording are project conventions rather than a unique classical rule set (`.trellis/spec/domain/daliuren-analysis-engine.md:5-8`). It is not yet a question-specific or complete traditional judgment system: the archived parent task itself leaves class-spirit selection, calendar integration, and verdict v2 pending (`.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/prd.md:21-25`).

The highest-confidence current defects are:

1. machine-readable AI `overview.yueJiang` is overwritten by `yueJian`;
2. a dual-void verdict says both conditions have no rescue while the timing layer still presents their fill-real dates as trigger windows;
3. neutral shen-sha are computed but omitted from the main UI and raw AI shen-sha section;
4. `DaLiuRenViewModel.castByManual()` has an invalid default parameter combination;
5. the visible birth-year input is parsed and persisted but has no effect anywhere;
6. the AI system prompt calls `fanYin` “返吟” while every domain surface calls it “反吟”.

## Files Found

- `.trellis/spec/domain/daliuren-analysis-engine.md` - authoritative v1 analysis architecture, evidence-strength statement, UI/AI contracts.
- `.trellis/spec/domain/daliuren-pan-engine.md` - upstream pan facts and frozen historical JSON contract.
- `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-engine/{prd,design,implement}.md` - exact fact services, ten-row verdict table, timing table, and intended tests.
- `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-ui/{prd,design,implement}.md` - result-page, detail-sheet, timing-card, disk, and formatter contracts.
- `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/prd.md` - integration sign-off and explicitly deferred work.
- `.trellis/tasks/archive/2026-07/07-27-daliuren-sanchuan-fix/{prd,design,implement}.md` - upstream corrections and synthetic golden-pan provenance.
- `lib/domain/services/daliuren/analysis/` - v1 fact, verdict, timing, and orchestration services.
- `lib/divination_systems/daliuren/models/` - persisted pan/result contract and non-populated transmission fields.
- `lib/divination_systems/daliuren/{daliuren_system.dart,viewmodels/daliuren_viewmodel.dart}` - casting, JSON restoration, and viewmodel conveniences.
- `lib/divination_systems/daliuren/ui/` - result assembly, analysis card, transmission details, shen-sha, and pan disk.
- `lib/ai/output/formatters/daliuren_formatter.dart` and `lib/ai/template/builtin_templates.dart` - AI data and prompt contract.
- `test/unit/services/daliuren/analysis/`, `test/widget/daliuren/`, `test/unit/ai/output/formatters/daliuren_formatter_test.dart` - current analysis, presentation, and formatter coverage.

## Implemented Capability Matrix

| Capability | Status | Evidence | Boundary / limitation |
|---|---|---|---|
| Runtime-only derived report | Implemented | Report is `@freezed` without JSON and documented as non-persisted (`lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart:55-84`); analyzer assembles it without repository access (`lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:17-78`). | Historical pan facts are not recomputed; see history risk below. |
| 15 ke-ge names over the nine methods | Implemented to v1 table | Structured switch covers `zeiKe` through `fanYin` and distinguishes 元首/重审, 蒿矢/弹射, 虎视/冬蛇掩目, 自任/自信/不虞, 井栏射/反吟 (`lib/domain/services/daliuren/analysis/ke_ge_service.dart:25-136`). | Polarity/reasons are project conventions, not independently classical-verified (`.trellis/spec/domain/daliuren-analysis-engine.md:5-8`). |
| Gan/zhi host-guest five-state tags plus void | Implemented | Both five-element switches and two void tags are emitted (`lib/domain/services/daliuren/analysis/gan_zhi_zhu_ke_service.dart:23-140`). | Only gan-top/day-gan and zhi-top/day-zhi are interpreted; other four-lesson structure is left as raw pan data. |
| Per-transmission void, commander, and initial-to-day-master tags | Implemented | `analyzeChuanTags` adds all three categories (`lib/domain/services/daliuren/analysis/chuan_analysis_service.dart:25-104`). | Middle/final relations are not symmetrically represented as transmission tags; final relation is only a ju tag. |
| Ju-level progressive/regressive generation/overcoming, final return, triple combination | Implemented | `analyzeJuTags` covers these four families (`lib/domain/services/daliuren/analysis/chuan_analysis_service.dart:107-187`). | No structured rule id or evidence source is carried by a tag (`lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart:27-36`). |
| Shen-sha landing on transmissions | Implemented | Every produced shen-sha is matched against each transmission; YiMa at the initial transmission gets special wording (`lib/domain/services/daliuren/analysis/shen_sha_chuan_service.dart:15-53`). | No dedicated unit test exists; the only production-path exercise is analyzer integration (`lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:41-48`). |
| Ten-row first-match verdict | Implemented to archived design | Conditions are collected first, then an ordered `if/else` implements rows 1-10 (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:38-114`). | Row interactions and conflicting evidence are not tested; term strings are control keys. |
| Five timing candidate families | Implemented to v1 table | Fill-real, initial, final, YiMa, and FuYin candidates are generated and priority-sorted (`lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart:25-87`). | Branch windows only; no actual dates/calendar and no complete deduplication. |
| Result-page analysis | Implemented | One report is derived in `build`, then used by the ke-ge card, transmission badges/details, and timing card (`lib/divination_systems/daliuren/ui/daliuren_result_screen.dart:24-60`). | No controller/cache is intentional per spec (`.trellis/spec/domain/daliuren-analysis-engine.md:29-32`). |
| UI reasoning/source disclosure | Partially implemented | Verdict factors and sources appear in the expandable reasoning chain (`lib/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart:114-205`); transmission reasons appear in the detail sheet (`lib/divination_systems/daliuren/ui/widgets/dlr_chuan_detail_sheet.dart:83-96,129-159`). | Most gan/zhi badges have no sighted-user path to their reason; the card renders only the badge term (`lib/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart:55-64`, `lib/divination_systems/daliuren/ui/widgets/dlr_tag_badge.dart:35-56`). |
| AI structured formatter and grounded default prompt | Implemented | Formatter derives the same report and appends `analysis` (`lib/ai/output/formatters/daliuren_formatter.dart:27-38,130-177`); default prompt tells AI not to redo pan rules (`lib/ai/template/builtin_templates.dart:207-210,241-266`). | Analysis facts are predominantly a rendered string; factors/sources and evidence grades are not exposed structurally. |
| Question-specific class spirit / category judgment | Missing | Analyzer accepts only `DaLiuRenResult` (`lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:17`); formatter passes the question to output metadata but not to analyzer (`lib/ai/output/formatters/daliuren_formatter.dart:27-40`). | Explicitly deferred as “类神（按占类取用）选择交互与裁决联动” (`.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/prd.md:23-25`). |
| Actual-date timing/calendar | Missing | Result page passes no calendar callback (`lib/divination_systems/daliuren/ui/daliuren_result_screen.dart:59`), so shared card hides the calendar action (`lib/presentation/widgets/ying_qi_card.dart:29-41`). | Explicitly deferred (`.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/prd.md:21-24`). |

## Confirmed Defects And Contract Gaps

### D1. AI core data overwrites month general with month branch

**Confirmed defect.** `_buildCoreData().overview` writes the literal key `yueJiang` first as `${result.tianPan.yueJiang}将` and then writes `yueJiang` again with `result.lunarInfo.yueJian`; the second entry wins, and there is no `yueJian` key (`lib/ai/output/formatters/daliuren_formatter.dart:67-91`). The human-readable overview is independently generated and correct (`lib/ai/output/formatters/daliuren_formatter.dart:242-271`), which masks the defect. The formatter test checks the rendered month-general line but only checks `xunShou` fields in `coreData.overview`, not `yueJiang/yueJian` (`test/unit/ai/output/formatters/daliuren_formatter_test.dart:112-119,167-181`).

Impact: default templates use `structuredOutput`, so their visible prompt remains correct; structured consumers or custom templates reading `overview.yueJiang` receive the month branch under a misleading key.

### D2. “No rescue” conditions still generate rescue-like timing candidates

**Confirmed semantic contradiction.** `VerdictCondition.hasRescue == false` explicitly means a true, unresolved condition (`lib/domain/services/shared/analysis/models/verdict_models.dart:53-66`). When both initial and final transmissions are void, the verdict converts both conditions to `hasRescue: false` (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:73-78`). The timing service nevertheless converts every condition with a branch into a priority-1 “值日填实” candidate and never checks `hasRescue` (`lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart:25-38`).

The contradiction reaches both user surfaces: the card labels the conditions “无解” (`lib/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart:89-110`) while the result page still renders the timing candidates (`lib/divination_systems/daliuren/ui/daliuren_result_screen.dart:52-59`); AI output says “无解救路径” and then lists the fill-real candidates (`lib/ai/output/formatters/daliuren_formatter.dart:218-237`). Existing tests separately lock the no-rescue verdict and a normal fill-real candidate, but never run the dual-void analyzer path (`test/unit/services/daliuren/analysis/daliuren_verdict_service_test.dart:64-72`, `test/unit/services/daliuren/analysis/daliuren_ying_qi_service_test.dart:57-68`).

Planning decision required: either suppress condition-derived timing candidates when `hasRescue == false`, or rename/redefine `hasRescue` so the UI does not claim “无解”.

### D3. Neutral shen-sha are silently lost from main UI and raw AI output

**Confirmed presentation/data-loss defect.** The model exposes neutral shen-sha (`lib/divination_systems/daliuren/models/shen_sha.dart:71-73`), and the service always computes 华盖、将星、天罗、地网 as neutral (`lib/domain/services/daliuren/shen_sha_service.dart:170-218`). The result shen-sha section renders only `jiShen` and `xiongShen` (`lib/divination_systems/daliuren/ui/daliuren_result_sections.dart:355-419`), and `_formatShenSha` emits only those same two lists (`lib/ai/output/formatters/daliuren_formatter.dart:327-331`).

A neutral shen-sha is visible only indirectly if its branch happens to equal a transmission branch, because `ShenShaChuanService` then creates a neutral detail tag (`lib/domain/services/daliuren/analysis/shen_sha_chuan_service.dart:25-49`). Otherwise it disappears from both primary presentations.

### D4. `DaLiuRenViewModel.castByManual()` has an unusable default

**Confirmed integration defect.** The viewmodel defaults manual casting to `DaLiuRenPanParams(monthGeneralMode: manual)` but supplies no `manualMonthGeneral` (`lib/divination_systems/daliuren/viewmodels/daliuren_viewmodel.dart:90-114`). System validation rejects exactly that combination (`lib/divination_systems/daliuren/daliuren_system.dart:374-385`), so a caller using the public convenience method with only its four required pillars enters the error state rather than casting.

The system test passes an explicit manual month general (`test/unit/divination_systems/daliuren/daliuren_system_test.dart:177-194`); the viewmodel test covers only `castByTime` (`test/unit/viewmodels/divination_system_viewmodels_test.dart:103-130`). There is no test of the viewmodel method's advertised default behavior.

### D5. Birth year is a visible but inert input

**Confirmed feature/UX contract gap.** The cast UI labels the field “生年” and tells users “本命占可填” (`lib/divination_systems/daliuren/ui/daliuren_cast_pan_params_section.dart:171-178`). `DaLiuRenPanParams` stores it (`lib/divination_systems/daliuren/models/pan_params.dart:67-78`), and the system parser preserves it (`lib/divination_systems/daliuren/daliuren_system.dart:396-406`). No pan service, analyzer, result UI, or formatter consumes it; repository-wide search found only the input/controller, model, and parser references.

Impact: two casts differing only by birth year produce identical pan, analysis, UI (apart from hidden serialized params), and AI data. This should either become 本命/行年 analysis input or be removed/explicitly marked “stored only/not yet used”. No test references `birthYear`.

### D6. “旬遁干” is only partially implemented

**Confirmed incomplete data path.** The parameter offers day/hour “旬遁干” modes (`lib/divination_systems/daliuren/models/pan_params.dart:52-64,102-105`), but the system uses the mode only to choose which pillar supplies `kongWang` (`lib/divination_systems/daliuren/daliuren_system.dart:478-485`). `Chuan` declares `tianGan`, `isWangXiang`, and `relationToRiGan` (`lib/divination_systems/daliuren/models/chuan.dart:43-53`), yet `_createChuan` populates none of them (`lib/domain/services/daliuren/san_chuan_service.dart:613-656`); repository-wide search found no other producer.

The result row labelled “遁干” consequently displays only the selected xun head and void branches (`lib/divination_systems/daliuren/ui/daliuren_result_screen.dart:72-78`, `lib/divination_systems/daliuren/ui/daliuren_result_sections.dart:37-41`). The default AI prompt nevertheless advertises day-master strength/use-spirit analysis (`lib/ai/template/builtin_templates.dart:188-195`) and asks for every transmission's relationship to the day stem (`lib/ai/template/builtin_templates.dart:249-255`). Today the AI must derive those missing facts itself from raw branches.

### D7. Priority is honored for top badges but not for full presentations

**Confirmed contract inconsistency.** The tag model says lower priority is shown first, and `topTagsForChuan` explicitly sorts (`lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart:22-35,86-92`). Gan/zhi analysis appends ordinary relation tags before later priority-1 void tags (`lib/domain/services/daliuren/analysis/gan_zhi_zhu_ke_service.dart:23-119,121-140`), while the card and AI formatter iterate that unsorted list (`lib/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart:55-64`, `lib/ai/output/formatters/daliuren_formatter.dart:195-200`).

Full transmission detail groups by enum category and iterates insertion order, not priority (`lib/divination_systems/daliuren/ui/widgets/dlr_chuan_detail_sheet.dart:45-48,87-96`); AI transmission text also uses insertion order (`lib/ai/output/formatters/daliuren_formatter.dart:202-209`). Only inline top badges receive the documented ordering. No test asserts full-list ordering; the helper test checks only its own sorted result (`test/unit/services/daliuren/analysis/daliuren_analyzer_test.dart:133-147`).

### D8. AI prompt has a domain-name typo

**Confirmed user-visible text defect.** The Daliuren system prompt lists “返吟” (`lib/ai/template/builtin_templates.dart:180-188`), while the domain enum and ke-ge report consistently use “反吟” (`lib/divination_systems/daliuren/daliuren_constants.dart:40-47`, `lib/domain/services/daliuren/analysis/ke_ge_service.dart:122-135`). Template tests check the surrounding grounding terms but not the nine-method vocabulary (`test/unit/ai/template/builtin_templates_test.dart:24-40`).

## Structural Risks (Confirmed Design, Latent Failure)

### R1. Human-readable terms are executable rule identifiers

`DlrAnalysisTag` has no stable rule id; only display `term` (`lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart:27-36`). Verdict logic converts terms to a set and branches on exact Chinese strings such as `传归克身`, `发用克身`, and `递生传进` (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:31-65`). YiMa special handling also tests `shenSha.name == '驿马'` in both tag and timing services (`lib/domain/services/daliuren/analysis/shen_sha_chuan_service.dart:35-40`, `lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart:60-70`).

This is a confirmed fragile contract, not an observed wrong result: a copy edit can silently change verdict/timing behavior. The verdict tests reproduce the same literals in their fixture helper (`test/unit/services/daliuren/analysis/daliuren_verdict_service_test.dart:8-16`) rather than exercising producer-to-consumer identifiers.

### R2. Report invariants allow duplicate or divergent truth

The analyzer always supplies both `judgment` and `verdictSummary: judgment.summary` (`lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:50-77`), but the report model makes both nullable and independent (`lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart:76-83`). The card only shows `verdictSummary` while the formatter falls back to `judgment.summary` (`lib/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart:66-74`, `lib/ai/output/formatters/daliuren_formatter.dart:218-220`). Current analyzer output is consistent; alternate constructors/tests can create cross-surface divergence.

Similarly, void truth exists both in `LunarInfo.kongWang` and persisted `Chuan.isKongWang`: gan/zhi tags read the former, while conditions read the latter (`lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:18-29,56-60`). New system casts populate both from one list (`lib/divination_systems/daliuren/daliuren_system.dart:124-131,167-173`), but the analyzer does not validate restored or manually built results.

### R3. Evidence grade is lost before AI interpretation

The spec distinguishes locked pan rules from project-v1 judgment rules (`.trellis/spec/domain/daliuren-analysis-engine.md:5-8`). `VerdictFactor` can carry a source (`lib/domain/services/shared/analysis/models/verdict_models.dart:37-50`), and the UI exposes it (`lib/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart:188-198`). The AI analysis renderer omits factors and sources entirely, outputting only tags, summary, conditions, and timing (`lib/ai/output/formatters/daliuren_formatter.dart:181-239`), while the system prompt calls both pan data and the analysis section the factual base (`lib/ai/template/builtin_templates.dart:207-210`).

The AI therefore cannot tell which statements are classical pan facts and which are project heuristics. For this audit's evidence-oriented goal, a structured `ruleId/source/evidenceLevel/version` contract is more important than adding more prose.

### R4. Old persisted pans have no rule provenance

`DaLiuRenResult` contains pan data and parameters but no engine/rule version (`lib/divination_systems/daliuren/models/daliuren_result.dart:25-67`), and restoration simply deserializes the stored object (`lib/divination_systems/daliuren/daliuren_system.dart:325-328`). The 07-27 fix explicitly changed previously wrong stored semantics and declined history migration (`.trellis/tasks/archive/2026-07/07-27-daliuren-sanchuan-fix/prd.md:7-15,27-31`). The runtime analyzer then trusts the stored `SiKe` flags and `SanChuan`, e.g. using `siKe.hasZeiKe` to choose 重审 versus 元首 (`lib/domain/services/daliuren/analysis/ke_ge_service.dart:25-40`).

**Hypothesis dependent on user data:** if pre-fix Daliuren records exist, current UI/AI will analyze their stale pan as though it were current-rule output. Current JSON tests only round-trip current objects (`test/unit/divination_systems/daliuren/daliuren_system_test.dart:287-299,331-351`); there is no legacy fixture or warning/provenance path.

## Classical-Correctness Hypotheses Requiring Evidence

These are **not confirmed defects** because the current spec intentionally defines them as project v1 rules.

### H1. Liu-he can override an actually hostile final transmission

`analyzeJuTags` classifies the final transmission as `传归生身` when either it generates the day stem **or** it liu-he-combines with the day stem's lodging palace; only the `else if` afterward can classify it as `传归克身` (`lib/domain/services/daliuren/analysis/chuan_analysis_service.dart:147-170`). With the locked lodging/liu-he tables, 乙 lodges at 辰 and 辰合酉, while 庚 lodges at 申 and 申合巳 (`lib/divination_systems/daliuren/daliuren_constants.dart:111-121,295-303`). 酉金克乙木 and 巳火克庚金, yet the current ordering labels both positive.

The existing liu-he test uses 丙/申, a non-conflicting case (`test/unit/services/daliuren/analysis/chuan_analysis_service_test.dart:145-153`). Classical review should decide whether combination truly dominates overcoming, whether both tags should coexist, or whether contextual transformation/seasonal strength is required.

### H2. First-match precedence can suppress strong contrary evidence

The table returns `可成` for `传归生身` before checking `发用克身` (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:87-107`). It also returns `可成` for `递生传进` when none of only three “克身” terms is present, even if other xiong tags such as a bad commander or middle-transmission void exist (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:57-65,96-102`). These outcomes implement the archived table exactly (`.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-engine/design.md:111-121`).

Whether those precedence choices are acceptable is a domain decision, not a code bug. However, they are high-impact because they change `可成/难成`, and there are no pairwise/conflict tests; all row tests use isolated minimal inputs (`test/unit/services/daliuren/analysis/daliuren_verdict_service_test.dart:63-155`).

### H3. Commander polarity and all verdict wording remain heuristic

All six commanders not in the fixed good set are unconditionally xiong (`lib/domain/services/daliuren/analysis/chuan_analysis_service.dart:15-23,66-75`), and that polarity can affect verdict row 9 (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:64-65,108-110`). This is spec-compliant (`.trellis/spec/domain/daliuren-analysis-engine.md:22-25`) but not independently verified here against context-sensitive classical rules.

## Missing Or Partial Analysis Knowledge

- **Class spirit / occupation category:** missing end to end; analysis is identical for every question (`lib/domain/services/daliuren/analysis/daliuren_analyzer.dart:17`, `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/prd.md:23-25`).
- **Birth fate/year and 行年:** the UI accepts birth year but it is inert (`lib/divination_systems/daliuren/ui/daliuren_cast_pan_params_section.dart:171-178`, `lib/divination_systems/daliuren/daliuren_system.dart:396-406`).
- **Transmission dun-gan, seasonal strength, and complete day-master relations:** fields exist but are never populated (`lib/divination_systems/daliuren/models/chuan.dart:43-53`, `lib/domain/services/daliuren/san_chuan_service.dart:649-656`).
- **Four-lesson interpretation:** formatter exposes raw upper/lower spirit and relation (`lib/ai/output/formatters/daliuren_formatter.dart:293-308`), but the fact report only interprets first/third lesson tops as host/guest (`lib/domain/services/daliuren/analysis/gan_zhi_zhu_ke_service.dart:20-21`).
- **Actual dates and urgency scale:** all Daliuren candidates are branch-day windows (`lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart:6-19`); the UI itself warns that day/month/year depends on urgency but provides no input or resolver (`lib/presentation/widgets/ying_qi_card.dart:48-55`).
- **Structured AI analysis/provenance:** only `keGeName` and `verdictTrend` are added as scalar core data (`lib/ai/output/formatters/daliuren_formatter.dart:109-118`); tags, conditions, factors, sources, and timing are text inside the `analysis` section (`lib/ai/output/formatters/daliuren_formatter.dart:185-239`).
- **History summary:** `DaLiuRenResult.getSummary()` shows only method and three branches, not ge name or verdict (`lib/divination_systems/daliuren/models/daliuren_result.dart:78-85`), and the UI factory uses the generic history card (`lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart:31-33`).

## Test Audit

### What current tests establish

- Ke-ge mapping exercises the 13 synthetic upstream golden pans, plus constructed 虎视/不虞 cases (`test/unit/services/daliuren/analysis/ke_ge_service_test.dart:79-165`).
- The ten verdict rows each have at least one direct unit test (`test/unit/services/daliuren/analysis/daliuren_verdict_service_test.dart:63-155`).
- Chuan structure tests cover void, one good commander, initial generate/overcome, progressive/regressive chains, final return, and triple combination (`test/unit/services/daliuren/analysis/chuan_analysis_service_test.dart:45-164`).
- Two analyzer smoke tests run upstream pan services through the report (`test/unit/services/daliuren/analysis/daliuren_analyzer_test.dart:83-130`).
- Widget tests cover the ke-ge card, conditions, factor expansion, transmission badges/detail sheet, a 360dp transmission layout, result assembly, and disk dialog (`test/widget/daliuren/daliuren_analysis_ui_test.dart:106-268`).
- Formatter tests cover a full rendered pan and one 元首 analysis case (`test/unit/ai/output/formatters/daliuren_formatter_test.dart:83-181`).

Verification run on 2026-07-28:

```text
flutter analyze lib/ai/output/formatters/daliuren_formatter.dart
  No issues found.

flutter test test/unit/services/daliuren/analysis \
  test/unit/ai/output/formatters/daliuren_formatter_test.dart \
  test/widget/daliuren/daliuren_analysis_ui_test.dart
  62 tests passed.
```

Passing analysis does not detect the duplicate map key in D1.

### Weak, circular, or missing coverage

1. **Verdict tests are locally tautological at the cross-service boundary.** Their helper creates tags from the exact Chinese `term` supplied by each test (`test/unit/services/daliuren/analysis/daliuren_verdict_service_test.dart:8-16`), then calls the string-driven verdict service. They prove table order for those literals, not that fact services emit compatible identities.
2. **Analyzer tests are smoke-level.** They assert non-empty regions and summary substrings but not exact trend, conditions, factor sources, shen-sha propagation, or timing branches (`test/unit/services/daliuren/analysis/daliuren_analyzer_test.dart:83-130`). They would not catch D2.
3. **No verdict interaction matrix.** There are no tests combining earlier and later rows, such as `传归生身 + 发用克身`, `递生传进 + 中传空`, or suspension plus a stronger adverse rule (`test/unit/services/daliuren/analysis/daliuren_verdict_service_test.dart:63-155`).
4. **No dedicated `ShenShaChuanService` test.** Repository search found no test importing that service; analyzer smoke merely ensures each transmission has some tag, which is already guaranteed by commander tags (`test/unit/services/daliuren/analysis/daliuren_analyzer_test.dart:94-100`).
5. **Incomplete five-state coverage.** Gan/zhi tests cover selected generate/overcome cases and void, but do not lock both sides' `woSheng`, `woKe`, and `biHe` mappings as a full matrix (`test/unit/services/daliuren/analysis/gan_zhi_zhu_ke_service_test.dart:37-97`).
6. **Commander set coverage is one-sided.** The chuan test asserts 青龙 as good but does not enumerate all six good and six bad commanders (`test/unit/services/daliuren/analysis/chuan_analysis_service_test.dart:71-83`).
7. **The “golden” evidence is internal and synthetic.** Ke-ge tests build circular-shift maps and call the production pan services (`test/unit/services/daliuren/analysis/ke_ge_service_test.dart:13-33`); their oracle is the archived hand-derived design, not a cited published classical case. They are useful regression tests but do not establish classical correctness.
8. **Formatter assertions privilege rendered text.** They do not assert the full core-data schema, neutral shen-sha, factors/sources, dual-void consistency, or hour-xun fallback (`test/unit/ai/output/formatters/daliuren_formatter_test.dart:141-181`). D1 therefore passes.
9. **Widget tests omit neutral shen-sha, priority ordering, long timing pills, birth-year visibility/effect, and dual-void cross-card consistency.** Result assembly only checks that three section titles/entries exist (`test/widget/daliuren/daliuren_analysis_ui_test.dart:238-267`).
10. **Viewmodel/system/history gaps:** viewmodel tests cover only time casting and saving (`test/unit/viewmodels/divination_system_viewmodels_test.dart:103-130`); there is no manual-default test, birth-year differential test, or legacy pre-07-27 JSON fixture. Current JSON tests serialize and immediately deserialize the same schema (`test/unit/divination_systems/daliuren/daliuren_system_test.dart:287-299,331-351`).

## Planning Recommendations

### P0: Repair existing contracts before expanding classics

1. Split `overview.yueJiang` and `overview.yueJian`, then add an exact core-data schema assertion (`lib/ai/output/formatters/daliuren_formatter.dart:67-91`).
2. Decide the meaning of `hasRescue == false` and make verdict, timing, UI, and AI agree; add a dual-void analyzer + widget + formatter test (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:73-78`, `lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart:25-38`).
3. Fix `castByManual`'s default by either using automatic month general or requiring a valid manual month general, and test via the viewmodel (`lib/divination_systems/daliuren/viewmodels/daliuren_viewmodel.dart:90-114`).
4. Render neutral shen-sha in UI and AI, with explicit ordering/labels (`lib/divination_systems/daliuren/ui/daliuren_result_sections.dart:355-419`, `lib/ai/output/formatters/daliuren_formatter.dart:327-331`).

### P1: Make rule contracts auditable

1. Add stable `ruleId`/typed facts; verdicts and timing must not branch on display strings (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:31-65`).
2. Add report metadata such as analysis rule version and evidence level; expose factors/sources in structured AI core data (`.trellis/spec/domain/daliuren-analysis-engine.md:5-8`, `lib/ai/output/formatters/daliuren_formatter.dart:109-118`).
3. Add conflict/precedence tests and classical adjudication for H1/H2 before changing the ten-row table (`lib/domain/services/daliuren/analysis/daliuren_verdict_service.dart:67-114`).
4. Establish a history policy: preserve-and-label old pan version, recast when enough original inputs exist, or warn that pre-fix results use legacy facts (`lib/divination_systems/daliuren/models/daliuren_result.dart:25-67`).
5. Apply one ordering policy to badges, detail sheets, and AI; test priority independently of producer insertion order (`lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart:86-92`).

### P2: Expand useful analysis in independently verifiable slices

1. Class-spirit/question category plus birth-year/行年 interaction; either implement birth year here or remove the current promise (`.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-suite/prd.md:23-25`, `lib/divination_systems/daliuren/ui/daliuren_cast_pan_params_section.dart:171-178`).
2. Transmission dun-gan, strength, and complete stem/branch relations, using the existing dormant model fields only after their semantics are specified (`lib/divination_systems/daliuren/models/chuan.dart:43-53`).
3. Calendar resolver and urgency/scale selection as a separate feature over stable `YingQiCandidate` semantics (`lib/presentation/widgets/ying_qi_card.dart:29-55`).
4. Replace synthetic-only evidence with cited classical cases for every behavior that claims classical authority; retain synthetic exhaustive matrices for algorithm boundaries (`.trellis/tasks/07-28-daliuren-classics-audit/prd.md:17-32`).

## External References

No external sources were used in this code-contract audit. The archived documents cite 《大六壬指南》 at a high level, but they do not provide edition/page-level primary-source evidence for the v1 polarity table, liu-he precedence, commander polarity, verdict table, or timing rules (`.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-engine/design.md:1-4,50-141`). Those items remain for the classics/evidence workstream and must not be upgraded from “project convention” to “verified classical rule” based on this report.

## Related Specs

- `.trellis/spec/domain/daliuren-analysis-engine.md:1-34` - v1 fact/verdict/timing/UI/AI contract.
- `.trellis/spec/domain/daliuren-pan-engine.md:1-36` - upstream pan facts, golden cases, and JSON compatibility.
- `.trellis/tasks/07-28-daliuren-classics-audit/prd.md:15-33` - completeness matrix, evidence, compatibility, and cross-layer acceptance criteria.
- `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-engine/design.md:50-148` - exact v1 rules and intended tests.
- `.trellis/tasks/archive/2026-07/07-27-daliuren-analysis-ui/design.md:3-76` - presentation and formatter design.

## Caveats / Not Found

- No independent classical edition/page or externally published lesson was verified in this sub-audit; H1-H3 are hypotheses, not defect findings.
- No product code, specs, task PRD/design/implement artifacts, or git state were modified.
- No dedicated test for `ShenShaChuanService`, no birth-year effect test, no `DaLiuRenViewModel.castByManual` default test, no verdict conflict matrix, and no legacy pre-07-27 result fixture were found.
- Relevant targeted tests pass, so the defects above are primarily unasserted semantic/schema gaps rather than current red tests.
