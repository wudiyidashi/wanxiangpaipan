# Qimen Product Integration Contract

This contract applies when changing Qimen cast/result UI, registry wiring,
history/data management, or AI presentation. The pan engine and analysis engine
remain the only calculation owners.

## 1. Scope / Trigger

- Trigger: changes under `lib/divination_systems/qimen/ui/` or
  `viewmodels/`, Qimen registry/provider wiring, history/data management, or
  `QimenStructuredFormatter` consumers.
- Read the domain `qimen-pan-engine.md` and `qimen-analysis-engine.md` first.
- UI code may format `QimenResult` and `QimenAnalysisProjection`; it must not
  import pan-stage services or infer rules from display strings.

## 2. Signatures

```dart
Future<bool> QimenViewModel.submitByTime({
  required DateTime castTime,
  required QimenPanParams params,
  String? question,
});

Future<bool> QimenViewModel.submitByManual({
  required String yearGanZhi,
  required String monthGanZhi,
  required String dayGanZhi,
  required String hourGanZhi,
  required String solarTerm,
  required QimenDun dun,
  required int juNumber,
  required QimenYuan yuan,
  required QimenPanParams params,
  DateTime? castTime,
  String? question,
});

Widget QimenUIFactory.buildCastScreen(CastMethod method);
Widget QimenUIFactory.buildResultScreen(DivinationResult result);
```

The UI factory accepts only `CastMethod.time` and `CastMethod.manual`, and the
result factory must reject every non-`QimenResult` value.

## 3. Contracts

- Submission order is `validate -> cast -> save -> registry navigation`.
  Navigation is allowed only after `submit*` returns `true` and `result` exists.
- A time payload includes `juMethod`. A manual payload has explicit pillars,
  term, dun, ju, and yuan; its nested `params` must not include `juMethod`.
- Never pass `QimenPanParams.toJson()` directly as the manual payload. Build the
  external payload allowlist explicitly.
- When leaving `trueSolar`, rebuild params with `longitude == null`; hidden
  longitude must not survive submission.
- Persist only `QimenResult` plus the encrypted question reference. Analysis is
  derived at render time and is never stored.
- Result section order is basis, duty, Luo Shu palaces, markers, verdict,
  facts/audit, timing, AI. Palace order is always
  `4-9-2 / 3-5-7 / 8-1-6`, regardless of input list order.
- AI is available only for a complete projection and a registered formatter.
  Missing service/provider/formatter or compatibility diagnostics must render a
  controlled unavailable state and expose no invocation command.
- AI policy is exact: program owns calculation; pan and analysis may not be
  recalculated; verdict may not be overridden.
- History uses stable IDs `qimen` and `time`/`manual`, restores only through
  `QimenSystem.resultFromJson()`, then routes through the UI registry.

## 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| Duplicate submit while casting/saving | Ignore the second submit; create one record |
| True solar longitude missing/non-finite/outside `[-180, 180]` | Inline error; no cast/save/navigation |
| Manual pillar is missing or outside the sexagenary cycle | Inline error; no silent current-time default |
| Save fails after a successful cast | Error state; remain on cast page |
| Widget unmounted after an await | Do not navigate or show a snackbar |
| Result is not `QimenResult` | Factory throws `ArgumentError` |
| Projection is non-complete | Show compatibility diagnostic; disable AI |
| Formatter/service/provider unavailable | Show controlled AI-unavailable card |
| One imported record has an unknown schema | Report and skip that record; preserve valid siblings |

## 5. Good / Base / Bad Cases

- Good: true-solar time cast with longitude is saved, reopened from history,
  renders the same nine palaces, and derives analysis again from the saved pan.
- Base: local-civil time cast omits longitude, produces a complete local result,
  and remains usable with no configured LLM provider.
- Bad: the screen hides a stale longitude but submits it; the formatter parses
  Chinese palace text; or a diagnostic projection is sent to an LLM.

## 6. Tests Required

- ViewModel: payload allowlists, manual `juMethod` exclusion, longitude clearing,
  duplicate lock, save failure, and encrypted question persistence.
- Widgets: both methods, inline validation, fixed section and Luo Shu order,
  all nine detail sheets, controlled diagnostics, and no overflow at 320/390/600
  logical pixels, landscape, and enlarged text.
- Persistence: real JSON/Drift round-trip, history reopen, per-system cleanup,
  mixed valid/corrupt import, and conversation/template backup.
- AI: formatter type check and policy, three built-in templates, stable
  `qimen` conversation ID with legacy-name read compatibility, and unavailable
  states for every missing dependency.
- Assets: decode the packaged bitmap and render it at the real three-column home
  cell size without missing-image or text-overflow errors.

## 7. Wrong vs Correct

```dart
// Wrong: leaks juMethod and any future internal field into manual input.
final input = {'params': params.toJson()};

// Correct: the ViewModel owns an explicit external allowlist.
final input = {
  'yearGanZhi': yearGanZhi,
  'monthGanZhi': monthGanZhi,
  'dayGanZhi': dayGanZhi,
  'hourGanZhi': hourGanZhi,
  'solarTerm': solarTerm,
  'dun': dun.id,
  'juNumber': juNumber,
  'yuan': yuan.id,
  'params': manualParamsWithoutJuMethod(params),
};
```

```dart
// Wrong: presentation creates a second verdict from labels or scores.
final verdict = positiveLabels.length > negativeLabels.length;

// Correct: presentation renders the program projection verbatim.
final verdict = projection.verdict;
```
