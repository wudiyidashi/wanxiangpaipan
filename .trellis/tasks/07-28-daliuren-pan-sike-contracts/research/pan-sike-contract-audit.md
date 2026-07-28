# Research: 天盘与四课严格合同审计

- Task: `07-28-daliuren-pan-sike-contracts`
- Date: 2026-07-28
- Scope: 天盘 map、四课公式/乘神依赖、伏反吟入口、版本与经典 fixture；不实现 C04 坐标或 C05 九宗门。

## 1. Evidence Status

`assets/data/daliuren/classics/rules/pan.json` 已冻结以下执行边界：

| Rule | Evidence | Approved | C03 usage |
|---|---:|---:|---|
| `dlr.rule.pan.003.heaven-plate-rotation` | B | yes | 月将加占时，十二支固定顺布 |
| `dlr.rule.pan.004.stem-residences` | C | no | 只沿用项目既有表，不升级古籍声明 |
| `dlr.rule.pan.005.first-lesson` | B | yes | 干寄宫取上神，日干为下神 |
| `dlr.rule.pan.006.second-lesson` | B | yes | 第一课上神再取一重上神 |
| `dlr.rule.pan.007.third-lesson` | B | yes | 日支取上神 |
| `dlr.rule.pan.008.fourth-lesson` | B | yes | 第三课上神再取一重上神 |

页级依据为《大六壬指南》Internet Archive `20210924_20210924_0416`，PDF 6 / scan leaf 5 / 印本 1：“月将加占时之上……顺布十二宫辰即天盘也”。同页支持一至四课结构，但不批准现代历法或秒级交节行为。

三张 `assets/data/daliuren/classics/cases/zhinan.json` 课例均为 B 级 approved，`expectedDerivation.method=independentManual`、`usesProductionCode=false`：

| Case ID | Input | Expected lessons (lower/upper) |
|---|---|---|
| `dlr.case.zhinan.renyin-guimao-liu-tuizhai` | 壬寅日、癸卯时、巳将 | 壬/丑、丑/卯、寅/辰、辰/午 |
| `dlr.case.zhinan.yiwei-jimao-feng-yunsheng` | 乙未日、己卯时、戌将 | 乙/亥、亥/午、未/寅、寅/酉 |
| `dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang` | 庚寅日、庚辰时、寅将 | 庚/午、午/辰、寅/子、子/戌 |

## 2. Confirmed Defects

### D1. Invalid branches still create a plausible plate

`DaLiuRenConstants.getDiZhiIndex()` returns `-1` for an unknown branch. `TianPanService.arrangeTianPan()` uses both indexes without validation, so an invalid month general or hour branch still enters modular arithmetic and produces twelve legal-looking entries. This is an input-contract defect independent of any school tradition.

### D2. Missing map entries are fabricated as co-location

`TianPanService.getTianPanZhi()` and `TianPan.getTianPanZhi()` return the query branch when the key is absent; `TianPan.fullDisplay` does the same. `SiKeService.arrangeSiKe()` repeats `map[key] ?? key` for every lesson. Missing data therefore becomes a false same-branch fact rather than an error.

### D3. Empty/partial maps can become false fu-yin or fan-yin

`SiKeService.isFuYin()` and `isFanYin()` only loop over present entries. Empty maps pass vacuously; a partial identity/opposition map also passes. `SanChuanService` duplicates these private predicates and `_tianPan(map, zhi) ?? zhi`, so actual three-transmission derivation remains vulnerable unless its public entry is guarded.

### D4. Missing generals become authoritative `贵人`

`SiKeService._createKe()` initializes `chengShen` to `ShenJiang.guiRen`, then optionally overwrites it. Omitting config and a failed lookup are observationally identical to a genuine 贵人. Production orchestration passes a config, but direct public service calls and current test helpers do not.

`ShenJiangConfig` cannot be made the strict C03 interface without freezing its currently disputed coordinate meaning: its docs say earth-plate keys, while SiKe/SanChuan query it with heaven-plate branches. A required `heaven branch -> general?` resolver states the needed fact without choosing C04's implementation.

### D5. Model comments contradict the implementation

`Ke` describes the four lessons in the wrong order and calls every lower deity an earth branch even though lesson one uses a day stem. `SiKe` describes lesson two as the stem residence itself and lesson four as the day branch itself. Production formulas match the current domain spec; comments, not formulas, must change.

## 3. Call-Site Inventory

Production:

- `lib/divination_systems/daliuren/daliuren_system.dart`: creates TianPan, then ShenJiangConfig, then SiKe; can provide the required resolver without reordering the pipeline.

Direct test helpers:

- `test/unit/services/daliuren/san_chuan_service_test.dart`
- `test/unit/services/daliuren/analysis/daliuren_analyzer_test.dart`
- `test/unit/services/daliuren/analysis/ke_ge_service_test.dart`
- `test/unit/ai/output/formatters/daliuren_formatter_test.dart`
- `test/widget/daliuren/daliuren_analysis_ui_test.dart`

`TianPanService` public helpers have no other repository callers. `TianPan.getTianPanZhi()` is consumed by the pan disk widget. Keeping method names and reverse-query return type limits compatibility cost while removing silent fallback.

## 4. Contract Decision

The canonical invariant is set equality, not merely length:

```text
map.length == 12
map.keys == {子..亥}
map.values == {子..亥}
exists delta: P(B[i]) == B[(i + delta) mod 12] for every i
```

This detects empty, partial, unknown key, unknown value, duplicated value and non-cyclic permutations. Set equality alone is insufficient: most bijections are not the fixed forward rotation approved by `pan.003`. Validation returns an immutable defensive copy so later mutation cannot invalidate the proof.

For a complete `TianPan`, scalar facts add one anchor: `map[shiZhi] == yueJiang`. `yueJiangName` remains display metadata and is not used as an execution key.

The resolver contract is deliberately narrower than `ShenJiangConfig`:

```text
resolveChengShen(tianPanZhi) -> ShenJiang?
null -> StateError
```

C04 remains responsible for building that resolver from separately named heaven/earth coordinate facts. C03 does not validate the traditional correctness of the returned general.

At the SanChuan boundary, a valid map alone is insufficient because `SiKe` has a public constructor. The service must also verify lesson indices, the four-step upper/lower chain and derived five-element flags against the same map. It deliberately excludes `chengShen`, whose source is C04.

## 5. Version Assessment

`DlrRuleSetVersions` states “A behavior change requires a new value.” C03 changes public and persisted-pan behavior from accepting invalid inputs and fabricating facts to rejecting them. Recommended publication:

- preserve `panV1 = daliuren-pan/1.0.0`;
- add `panV2 = daliuren-pan/2.0.0`;
- set `panCurrent = daliuren-pan/3.0.0`;
- keep `castInputSchema = 2.0.0` and evidence catalog `1.0.0`.

Valid v2 and v3 plate values are expected to be identical. The version bump records validation semantics and keeps the user-selected conservative history rule: old results remain readable, but only exact current output is analyzed as current without an explicit compatibility decision.

## 6. Test Gaps And Planned Oracles

- No independent `tianpan_service_test.dart` or `si_ke_service_test.dart` exists.
- Current 13 “golden” SanChuan cases are internal rotation fixtures and call SiKe without a general config. They are useful structural regression, not classic proof.
- Required invalid matrices have no tests.
- Current relation tests cover only lower-controls-upper and upper-controls-lower; generate direct fixed cases for generation and equality semantics as well.
- Classic expectations come from the approved JSON/independent reviews, never from `arrangeTianPan()` or an equivalent test-side rotation implementation.

## 7. Scope Guard

- C03 may validate the SanChuan input map because otherwise false fu-yin survives the production path; it may not modify selection branches.
- C03 may require a general resolver for SiKe; it may not correct the current resolver's coordinates, direction, 贵人 table or SanChuan general mapping.
- C03 may document the existing stem residence as a project dependency; it may not promote `pan.004`.
- No evidence JSON content, Flutter UI, database schema, snapshot schema, qimen task or `tmp/` content is owned here.
