# Research: Liuyao AI Prompt and Real-Model Evaluation Path

- Query: Audit the complete Liuyao AI path (formatter, prompt templates and assembly, model service/provider, settings/custom templates, tests, and evaluation utilities); identify the correct change points, compatibility risks, and a reproducible baseline-vs-candidate real-model evaluation design without exposing credentials.
- Scope: internal + local dependency inspection
- Date: 2026-08-01

## Findings

### Executive conclusion

The final request path is:

```text
LiuYaoResult + decrypted question
  -> LiuYaoStructuredFormatter.format()
  -> LiuYaoAnalyzer.analyze()
  -> formatter.render() as one large structuredOutput string
  -> PromptAssembler (active system template + active analysis template)
  -> CastSnapshot (freezes both prompts and model name)
  -> OpenAICompatibleProvider.chatStream()/chat()
  -> chat.completions [system, user]
```

The highest-value change is not prompt wording alone. `AnalysisReport.judgment` already contains the exact program-owned trend, conditions, ordered factors, reasons, effects, and classical-source labels, but the Liuyao formatter currently discards nearly all of that structure before the prompt reaches the model. The formatter only emits per-line tags, selected-yongshen position, short timing labels, and a one-line verdict summary (`lib/ai/output/formatters/liuyao_formatter.dart:133-174`). By contrast, the shared judgment model contains the richer evidence chain (`lib/domain/services/shared/analysis/models/verdict_models.dart:37-86`). Prompt optimization should therefore be ordered as:

1. expose the complete deterministic analysis projection and source policy;
2. make the immutable program-owned contract survive custom templates;
3. update all Liuyao prompt variants;
4. evaluate baseline versus candidate with the same structured input and request parameters.

Changing only `BuiltInTemplates.liuYaoAnalysisPrompt` will not satisfy the task: active custom templates bypass it, brief mode can replace it, existing conversations retain frozen old prompts, and missing structured evidence still forces the model to guess.

### Files found

| File | Role |
|---|---|
| `lib/ai/output/formatters/liuyao_formatter.dart` | Converts `LiuYaoResult` plus `LiuYaoAnalyzer` output into the text inserted into the model prompt. |
| `lib/domain/services/liuyao/analysis/liuyao_analyzer.dart` | Single deterministic Liuyao analysis entry point; builds tags, yongshen chain, timing candidates, and judgment. |
| `lib/domain/services/liuyao/analysis/models/analysis_report.dart` | Defines the report fields available to the formatter, including the full `judgment`. |
| `lib/domain/services/shared/analysis/models/verdict_models.dart` | Defines trend, condition, factor/effect/source, summary, and timing-candidate contracts. |
| `lib/domain/services/liuyao/analysis/verdict_service.dart` | Produces the ordered evidence chain and classical-source labels consumed by `VerdictJudgment`. |
| `lib/ai/template/builtin_templates.dart` | Holds the active built-in Liuyao system, comprehensive, brief, and unused question templates. |
| `lib/ai/template/template_engine.dart` | Renders the small Handlebars-like syntax and performs limited syntax validation. |
| `lib/ai/template/prompt_template.dart` | Template model and the system/analysis/question/summary type IDs. |
| `lib/ai/service/prompt_assembler.dart` | Fetches active system/analysis templates, builds context, and produces the final two messages. |
| `lib/ai/config/ai_config_manager.dart` | Synchronizes built-ins into Drift, preserves active choices, and loads/saves custom templates and provider profiles. |
| `lib/data/database/daos/ai_config_dao.dart` | Enforces one selected template per `(systemType, templateType)` when `setActiveTemplate` is used. |
| `lib/presentation/screens/settings/prompt_template_settings_viewmodel.dart` | Saves edited template text without invoking template validation. |
| `lib/presentation/screens/settings/prompt_template_settings_screen.dart` | Displays and edits templates; currently has no create/activate/delete controls. |
| `lib/ai/service/ai_analysis_service.dart` | Product-facing API; delegates initial analysis to the conversation service. |
| `lib/ai/service/ai_conversation_service.dart` | Freezes the assembled prompt, sends initial and follow-up chat requests, and persists conversations. |
| `lib/ai/service/chat_request_builder.dart` | Replays the frozen prompt and initial response as anchors for follow-up requests. |
| `lib/ai/providers/openai_compatible_provider.dart` | Sends OpenAI-compatible Chat Completions requests with model, temperature, and max completion tokens. |
| `lib/ai/config/ai_provider_profile.dart` | Provider profile fields and secret-free JSON serialization contract. |
| `lib/ai/model/cast_snapshot.dart` | Persisted prompt/model snapshot used to keep a conversation stable. |
| `lib/presentation/divination/divination_result_page.dart` | Loads the encrypted question and passes it into `AIAnalysisWidget`. |
| `lib/presentation/widgets/ai_analysis_widget.dart` | Starts analysis and can preview/copy the exact assembled prompt. |
| `test/unit/services/liuyao/analysis/verdict_golden_test.dart` | Forty-plus deterministic cases, including at least 26 original-book cases and 14 explicit rule-validation cases. |
| `test/unit/ai/output/formatters/liuyao_formatter_test.dart` | Only direct Liuyao formatter test; currently checks one changed-line rendering detail. |
| `test/unit/ai/service/prompt_assembler_test.dart` | Tests assembly using a fake Meihua result/formatter, not the real Liuyao end-to-end prompt. |
| `test/unit/ai/template/builtin_templates_test.dart` | String-presence and template-syntax checks for the built-ins. |
| `test/unit/ai/service/ai_conversation_service_test.dart` | Tests stream lifecycle and snapshot storage with a mocked assembler/provider. |
| `tool/daliuren_classics/` | Existing classical-evidence validator pattern, but for Daliuren only. |
| `tool/qimen_analysis/generate_analysis_goldens.dart` | Existing deterministic golden generator pattern, but no model evaluation. |
| `devtools_options.yaml` | Standard Flutter DevTools options file; current schema contains no AI connection or model fields. |

### 1. Data lost before the model call

`LiuYaoStructuredFormatter.format()` creates the generic `StructuredDivinationOutput` (`lib/ai/output/formatters/liuyao_formatter.dart:21-29`). Its `coreData` contains only names, moving-line positions/count, special type, shi/ying positions, and liushen (`lib/ai/output/formatters/liuyao_formatter.dart:45-57`). It does not expose:

- selected yongshen identity and branch/element;
- duplicate yongshen, yuan-shen, ji-shen, chou-shen, and xian-shen positions;
- `judgment.trend` and `judgment.nuance` as explicit fields;
- each `VerdictCondition`'s branch, reason, and `hasRescue` value;
- ordered `VerdictFactor` entries (`rule`, `effect`, `reason`, `source`);
- timing candidate branch, scale, reason, and priority;
- analysis/rule/source schema versions or a calculation ownership policy.

Those values already exist. `AnalysisReport` carries `yongShenTags`, `yingQi`, `verdictSummary`, and `judgment` (`lib/domain/services/liuyao/analysis/models/analysis_report.dart:44-64`). `VerdictJudgment` contains trend, nuance, conditions, ordered factors, and summary (`lib/domain/services/shared/analysis/models/verdict_models.dart:69-86`), while every factor includes a human reason and source label (`lib/domain/services/shared/analysis/models/verdict_models.dart:37-50`). Timing candidates similarly contain branch, scale, reason, and priority (`lib/domain/services/shared/analysis/models/verdict_models.dart:89-101`).

The formatter instead reduces them to:

- each line as `term(reason)` (`lib/ai/output/formatters/liuyao_formatter.dart:151-160`);
- yongshen position only (`lib/ai/output/formatters/liuyao_formatter.dart:162-167`);
- timing `label` values only (`lib/ai/output/formatters/liuyao_formatter.dart:168-170`);
- one `verdictSummary` line (`lib/ai/output/formatters/liuyao_formatter.dart:171-173`).

This is a concrete prompt-quality defect: the model is asked to explain evidence and cite tradition after the program has thrown away the evidence chain and most source information.

Recommended contract: mirror the projection pattern already used by Qimen. Qimen serializes schema/rule-set identifiers, full timing candidates, sources, and explicit policy flags (`lib/ai/output/formatters/qimen_formatter.dart:62-120`), then renders facts with rule/source IDs (`lib/ai/output/formatters/qimen_formatter.dart:241-251`), exact verdict/conditions (`lib/ai/output/formatters/qimen_formatter.dart:256-278`), source records, and ownership policy (`lib/ai/output/formatters/qimen_formatter.dart:295-310`). Liuyao should receive an equivalent versioned projection rather than another ad hoc prose block.

At minimum, `_formatAnalysis` should render all currently available judgment fields. For the requested classical system, a proper source catalog with stable `sourceId`, title, edition, locator, claim/paraphrase, evidence level, and rule IDs is preferable to the current free-text source strings. `VerdictService` maps categories to broad chapter labels (`lib/domain/services/liuyao/analysis/verdict_service.dart:51-62`) and attaches those labels to factors (`lib/domain/services/liuyao/analysis/verdict_service.dart:77-86`), but those labels are not edition/page-level citations and must not be presented as verified verbatim quotations.

### 2. Current prompt behavior and correct change points

The active Liuyao system template defines role, broad analysis order, and a program-data agreement (`lib/ai/template/builtin_templates.dart:13-58`). The comprehensive template asks for eight prose sections (`lib/ai/template/builtin_templates.dart:61-117`). Its current weaknesses are:

- it asks for general expert interpretation before defining an evidence hierarchy;
- it does not require a single explicit program verdict field, a fact-to-conclusion evidence chain, or condition-by-condition reconciliation;
- it permits a disagreement with the program summary (`builtin_templates.dart:52`) even though the deterministic verdict is intended to be authoritative; no bounded override protocol exists;
- it asks for classical expertise but supplies no source whitelist, so a model can invent quotations or locators;
- it asks the model to determine yongshen when there is a question (`builtin_templates.dart:91-94`) even when selection should be program/user-owned;
- it asks for liushen interpretation without explicitly making liushen lower-priority supporting evidence;
- the brief template has none of the program-ownership, source, or timing constraints (`builtin_templates.dart:120-140`).

The separate `liuYaoQuestionPrompt` contains a simplistic question-to-yongshen map (`lib/ai/template/builtin_templates.dart:142-163`) but is never loaded by `PromptAssembler`. Repository-wide usage is only its definition and registration in `getAll()` (`lib/ai/template/builtin_templates.dart:639-657`). Editing that template cannot change actual model behavior.

`PromptAssembler` only loads `system` and `analysis` templates (`lib/ai/service/prompt_assembler.dart:87-95`), renders them with the formatter output (`lib/ai/service/prompt_assembler.dart:97-125`), and passes generic context plus `coreData` (`lib/ai/service/prompt_assembler.dart:128-163`). Therefore:

- Change the final user-facing instructions in `BuiltInTemplates.liuYaoAnalysisPrompt` and `liuYaoBriefPrompt`.
- Put non-overridable calculation/source policy either in the structured projection or in an immutable system prefix assembled by `PromptAssembler`; do not rely solely on the replaceable built-in system template.
- Additive top-level `coreData` variables are backward compatible. The current engine only supports a variable or one property level (`{{x}}` / `{{x.y}}`) and simple loops (`lib/ai/template/template_engine.dart:14-33`, `113-139`), so deeply nested fields should normally be rendered inside `structuredOutput`, not addressed directly from custom template syntax.
- Unknown template variables silently render as empty (`lib/ai/template/template_engine.dart:113-124`). Syntax validation checks block counts but not whether variables exist in the assembly context (`lib/ai/template/template_engine.dart:175-217`).

Suggested candidate prompt policy, after the projection exists:

1. Treat supplied pan facts, selected yongshen, program verdict, conditions, and timing candidates as authoritative; never recalculate or replace them.
2. If yongshen is not selected, do not issue a definitive trend or timing. Explain the missing prerequisite and provide a clearly labeled yongshen-selection suggestion only.
3. Analyze in fixed order: question scope -> yongshen/shi-ying -> day/month strength -> moving/change forces -> yuan/ji/chou/fu-shen chain -> suspended conditions -> matched verdict -> timing windows -> low-priority liushen imagery -> bounded advice.
4. Resolve conflicts according to the program-provided factor order and matched decision row; never count positive/negative tags.
5. Cite only source records supplied in the projection. Use paraphrase unless a verified excerpt is supplied. Never invent original text, chapter, page, edition, or historical outcome.
6. Distinguish `program fact`, `classical rule paraphrase`, `synthesis`, and `uncertainty/advice` in the output.
7. Restate the exact four-value trend and all unresolved conditions. Timing is a candidate release/observation window, not a guarantee.

### 3. Yongshen boundary

The user-selected yongshen fields are persisted in `LiuYaoResult` (`lib/divination_systems/liuyao/liuyao_result.dart:27-31`) and the controller recomputes the report after selection (`lib/divination_systems/liuyao/viewmodels/liuyao_analysis_controller.dart:34-46`, `109-115`). When no yongshen is selected, the formatter tells the model to suggest one (`lib/ai/output/formatters/liuyao_formatter.dart:162-165`). This creates two materially different modes that the final prompt must make explicit:

- **selected mode**: model must use the selected program/user yongshen and its full deterministic chain;
- **unselected mode**: model may propose a candidate based on the question, but must not fabricate the absent `judgment`/timing output or present a final verdict as program-owned.

A later deterministic question-category/yongshen resolver would be stronger than prompt-only selection, but it is not present in the audited path. The unused question template is not a substitute.

### 4. Assembly, provider, and request parameters

The result page decrypts the stored question and passes it to `AIAnalysisWidget` (`lib/presentation/divination/divination_result_page.dart:42-51`, `78-87`). The widget calls `AIAnalysisService.analyze` (`lib/presentation/widgets/ai_analysis_widget.dart:368-380`). Although that API accepts `analysisType`, `useStreaming`, and `customVariables`, its own comments state they are retained but ignored, and it forwards only `result` and `question` (`lib/ai/service/ai_analysis_service.dart:106-127`). Consequences:

- normal product calls always assemble the default `comprehensive` context;
- `includeAdvice` is consequently always true for the active comprehensive template;
- `customInstructions` in the system template cannot be supplied through this product API;
- `useStreaming: true/false` does not control the provider path.

`AIConversationService.startConversation` assembles the prompt, freezes it with the current model name, and sends exactly `[system, user]` (`lib/ai/service/ai_conversation_service.dart:73-131`). Follow-ups replay the frozen system prompt, cast prompt, and first assistant result before a twelve-message sliding window (`lib/ai/service/chat_request_builder.dart:5-44`). The snapshot is explicitly intended to keep prompts stable (`lib/ai/model/cast_snapshot.dart:6-14`). This is good conversation compatibility, but means prompt upgrades do not change an existing conversation until the user starts/regenerates the analysis.

The provider uses the configured model, temperature, and maximum completion tokens (`lib/ai/providers/openai_compatible_provider.dart:215-229`, `270-278`). Product defaults are temperature `0.7` and max output `4096` (`lib/ai/providers/openai_compatible_provider.dart:26-38`; `lib/ai/config/ai_provider_profile.dart:17-31`). `ChatRequest` exposes only optional temperature and max tokens (`lib/ai/llm_provider.dart:230-242`), and initial analysis does not override either. This is unsuitable for exact evaluation repeatability unless an opt-in evaluator explicitly fixes the parameters.

The locked dependency is `openai_dart 4.2.0` (`pubspec.lock:579-586`). Its installed `ChatCompletionCreateRequest` API supports `seed` and `responseFormat`, and describes same-seed output as similar, not identical. The app adapter currently does not pass either. Because generic OpenAI-compatible endpoints vary, evaluation should capability-detect/fallback rather than assume `seed` support.

### 5. Template persistence and backward compatibility risks

Built-in templates are synchronized into the database on startup. The code overwrites built-in definitions when source content changes, while preserving the selected template per `(systemType, templateType)` (`lib/ai/config/ai_config_manager.dart:166-223`). Historical duplicate-active states are repaired (`lib/ai/config/ai_config_manager.dart:225-244`). Active custom templates are deliberately preferred and preserved across initialization (`lib/ai/config/ai_config_manager.dart:252-263`; covered by `test/unit/ai/config/ai_config_manager_test.dart:169-210`).

Compatibility implications:

- Updating built-in source changes future prompts for users whose active choice is that built-in.
- Users with an active custom system or analysis template will not inherit new safety, classical-source, ordering, or output rules.
- Adding the richer `structuredOutput` text affects custom templates that embed `{{structuredOutput}}`; additive context fields do not break older templates.
- Existing `CastSnapshot` values and persisted responses remain on the old prompt by design.
- The brief template can be activated in the same `analysis` scope and must be updated if critical guarantees are required.
- A renamed built-in ID would create a second template rather than upgrade the current one; retain `builtin_liuyao_system` and `builtin_liuyao_analysis` IDs.
- Tightening the system policy through an immutable prefix changes custom-template behavior. That is appropriate for fact/citation integrity but should be documented as a policy change and tested.
- Template editor `canSave` checks only a nonempty name (`lib/presentation/screens/settings/prompt_template_settings_viewmodel.dart:139-140`) and saves content without calling `PromptTemplateEngine.validate` (`:142-174`). A typo or malformed block can silently degrade prompts.
- The settings screen shows a lock icon for built-ins but still opens the same writable editor (`lib/presentation/screens/settings/prompt_template_settings_screen.dart:184-220`, `247-318`). Those edits are subsequently overwritten by built-in initialization. This behavior is confusing but need not be expanded unless this task touches settings UX.
- The settings screen exposes neither creation nor activation actions, despite manager APIs existing. Any pre-existing/imported custom selection still matters to compatibility.

### 6. Existing automated coverage and gaps

Current useful coverage:

- built-in tests assert a few policy phrases, output sections, and syntactic renderability (`test/unit/ai/template/builtin_templates_test.dart:6-63`, `95-123`);
- prompt assembly tests cover active-template selection and context injection, but use a fake Meihua result/formatter (`test/unit/ai/service/prompt_assembler_test.dart:54-125`, `157-230`);
- conversation tests verify prompt snapshot values and stream lifecycle with mocks (`test/unit/ai/service/ai_conversation_service_test.dart:133-182`);
- the Liuyao formatter has only one direct test, for the changed line's complete Najia text (`test/unit/ai/output/formatters/liuyao_formatter_test.dart:7-23`);
- the deterministic verdict goldens define case question, pan inputs, yongshen, source chapter/pages, adjudication, expected trend/conditions/factors/timing (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:21-75`) and execute through the real analyzer (`:895-907`). They require at least 26 original-book cases and 14 explicitly labeled rule-validation cases (`:910-930`) and assert expected judgments (`:968-995`).

Missing tests recommended for implementation:

1. A real Liuyao formatter contract test that asserts explicit trend/nuance, every condition field, factor/effect/reason/source, complete yongshen chain, and full timing fields.
2. A real Liuyao `PromptAssembler` end-to-end fixture using active built-ins, both selected and unselected yongshen, and an actual question.
3. Prompt contract tests for immutable program ownership, no tag counting, source whitelist/no fabricated quotation, condition/timing boundaries, and fixed analysis order in comprehensive and brief modes.
4. Custom-template compatibility tests proving additive projection data remains available and the immutable policy cannot be removed by an active custom template.
5. Snapshot compatibility tests showing an old conversation retains its old prompt while a regenerated conversation receives the candidate prompt.
6. Template-editor validation tests if the task changes settings behavior.
7. Evaluation-runner tests for missing configuration, secret redaction, deterministic case selection, request-parameter capture, retry/resume, and output artifact schema.

There is no existing real-model prompt evaluator. `tool/` contains a Daliuren evidence validator and a Qimen deterministic golden generator only. Real model evaluation must be added as an explicit opt-in tool, not as a normal unit/CI test.

### 7. Reproducible baseline-vs-candidate evaluation protocol

#### Dataset

Use a versioned reusable fixture manifest derived from, not parsed out of, the private `_GoldenCase` declarations. Keep three labels separate:

- **original-book outcome cases**: eligible for outcome/adjudication comparison;
- **rule-validation cases**: eligible only for rule/evidence consistency checks;
- **holdout original-book cases**: never used while drafting the candidate prompt.

The current golden suite already provides enough metadata and the required source-nature distinction (`test/unit/services/liuyao/analysis/verdict_golden_test.dart:72-83`, `910-964`). Do not leak `adjudication`, expected trend, expected factors, timing, or recorded outcome into the model input except insofar as the production program itself deterministically emits its judgment. The baseline and candidate must receive byte-identical structured pan input; only prompt-template/policy versions may differ.

Because production intentionally supplies the program verdict, this experiment measures **faithfulness, completeness, non-hallucination, question relevance, and explanatory agreement with verified cases**. It does not independently prove predictive accuracy. Original outcomes can be used to check whether the explanation contradicts the recorded adjudication, not to claim empirical forecasting accuracy.

#### Paired request controls

For every `(caseId, repetition)`:

- same provider endpoint and exact model identifier;
- same structured-output version and case input;
- same maximum completion tokens;
- temperature `0` or the endpoint's documented minimum;
- same seed when supported; record that support is absent when rejected;
- same response format and stop settings;
- alternating/randomized baseline-candidate request order to reduce transient service drift;
- at least 3 repetitions when seed is unavailable or the provider is nondeterministic;
- retry only transport/rate-limit failures, preserving the logical run ID.

Use the non-streaming request path for evaluation so token usage and latency are captured in one response. Record hashes of system prompt, user prompt, structured input, candidate version, and fixture manifest. Also record model ID, temperature, max tokens, seed/capability, timestamp, latency, total tokens, and package/evaluator version. Never record headers, API keys, raw config maps, or exception objects before redaction.

#### Scoring

Use hard gates before any subjective score:

- exact program trend is stated and not contradicted;
- all unresolved conditions are preserved, including `hasRescue=false` boundaries;
- no pan fact, yongshen identity, moving line, timing branch, or source locator is invented;
- no timing candidate is promoted to a guaranteed event;
- every cited classical claim resolves to a supplied source record;
- no fabricated verbatim quotation appears.

Then score a locked rubric, for example 0-2 per dimension:

- evidence-chain coverage (key supporting and suppressing factors);
- conflict-resolution fidelity (factor order / matched decision logic);
- question-specific synthesis;
- source fidelity and appropriate paraphrase;
- timing/condition explanation;
- uncertainty and actionable-boundary quality;
- clarity and non-repetition.

Prefer deterministic assertions for hard facts. For prose quality, use blinded pairwise review (candidate labels hidden), either human review or a separately fixed judge model at temperature 0 with the rubric and reference facts. Store per-dimension scores and reasons, not only a total. Acceptance should require no hard-gate regression, no new high-severity hallucination, and candidate aggregate/holdout scores not below baseline.

#### Artifact layout

A safe opt-in evaluator could emit:

```text
tool/liuyao_ai_eval/
  run.dart                 # reads config only at runtime
  fixtures.json            # non-secret case inputs and references
  rubric.json              # versioned scoring contract
  README.md                # invocation and redaction rules

.trellis/tasks/.../research/eval/
  manifest.json            # hashes + non-secret model/request metadata
  baseline/*.json          # prompt/input/output/score; no credentials
  candidate/*.json
  comparison.md
```

The runner should fail closed if required fields are absent, reject output paths outside the intended evaluation directory, scrub known credential values before any write, and scan artifacts for the credential value and authorization-header patterns before reporting success.

### 8. `devtools_options.yaml` audit and secret handling

The file was inspected only for schema keys and size/shape. At the time of this audit it has exactly three top-level keys: `description`, `documentation`, and `extensions` (`devtools_options.yaml:1-3`). It contains no detected `apiKey`, `model`, `baseUrl`, token, or secret fields, so there is no non-secret model metadata to report and no real-model call can currently be configured from it.

This file is also not excluded by `.gitignore`; the repository ignore rules cover build/platform artifacts and selected secret formats but do not cover `devtools_options.yaml` or generic YAML secrets (`.gitignore:1-12`, `101-111`). It is a standard Flutter DevTools configuration file, so using it as a credential store creates both accidental-commit risk and schema ambiguity.

Recommended secret precedence for the evaluator:

1. environment variables or a credential value supplied by the process environment;
2. a dedicated local evaluation config that is explicitly gitignored;
3. only if the user deliberately retains the current location, a namespaced schema parsed at runtime with strict redaction and a repository secret-leak guard.

Do not import the evaluation credential into application Drift preferences, `SecureStorage`, snapshots, task documents, logs, test expectations, command lines, or generated reports. The evaluator should display only whether a credential is present, never its prefix/suffix/length/hash unless the user explicitly needs key-identity diagnostics.

## External References

- `openai_dart` package version 4.2.0, locked in `pubspec.lock:579-586`.
- Installed `openai_dart 4.2.0` API: `ChatCompletionCreateRequest` supports `temperature`, `maxCompletionTokens`, `responseFormat`, and optional `seed`; its documentation promises similar rather than identical same-seed output.
- No provider-specific external model documentation was consulted because the current local configuration exposes no provider/model metadata. OpenAI-compatible behavior must not be assumed identical across endpoints.

## Related Specs

- `.trellis/spec/domain/liuyao-analysis-engine.md`: locks《增删卜易》as the conflict-resolution baseline, makes the verdict a first-match classification table rather than a score, distinguishes conditions/timing, and requires at least forty documented goldens.
- `docs/architecture/divination-systems/liuyao.md:143-176`: documents the pan calculation chain and analysis boundaries, including no tag-count verdict and no timing guarantee.
- `.trellis/tasks/08-01-liuyao-classics-analysis-prompt/prd.md`: R3 requires program-owned deterministic facts, R4 requires ordering/evidence/conflict/source constraints, and R5 requires a secret-safe real-model baseline comparison.

## Caveats / Not Found

- No API credential or model configuration is currently present in `devtools_options.yaml`; real-model evaluation is blocked until a valid runtime configuration exists.
- No existing Liuyao real-model evaluation utility, prompt fixture manifest, judge rubric, or sanitized evaluation artifact format was found.
- The current classical source strings are broad free-text chapter labels, not a verified source catalog with stable IDs, edition/locator metadata, and approved excerpts. Prompt wording alone cannot make exact citations reliable.
- The forty-plus golden cases are private constants embedded in a test file. An evaluator should consume a shared, versioned fixture manifest rather than scraping Dart source or duplicating cases without a consistency test.
- Seed and structured response support exist in the locked client package but are not exposed by the app's `ChatRequest`/provider adapter, and a generic compatible endpoint may reject them.
- No network call was attempted because the requested configuration was absent and this research role is read-only outside the task research directory.
