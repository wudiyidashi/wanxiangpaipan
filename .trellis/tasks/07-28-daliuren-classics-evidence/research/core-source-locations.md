# Research: Core source locations and first-pass scan audit

- Query: Locate page-level primary-source evidence for the core Da Liu Ren plate rules, identify transcript-to-scan mapping hazards, and record the implementation areas affected by the evidence.
- Scope: mixed
- Date: 2026-07-28

## Findings

### Evidence policy used in this report

Only the following statuses are used:

- `scanVerified (first pass; B-candidate pending independent recheck)`: the cited scan page was visually inspected during this research pass. It is not final A/B approval because the task design requires a second independent page, quotation, and interpretation review.
- `locator-only`: OCR or a fixed transcript supplies a search lead, but the statement has not been matched to the cited scan page.
- `unresolved`: no positive, adopted, scan-backed authority has been established, or a conflict prevents an implementation decision.

OCR and fixed transcripts are locators only. They cannot promote a rule to A/B evidence. No rule in this report is finally approved for deterministic implementation.

### Files found

| Path | Description |
| --- | --- |
| `tmp/pdfs/daliuren/liuren-01.pdf` | Siku/Universal Library scan containing volume 1; core initiation methods, Shen Sha tables, and noble/general material were inspected here. |
| `tmp/pdfs/daliuren/liuren-02.pdf` | Siku series volume 2 container. |
| `tmp/pdfs/daliuren/liuren-03.pdf` | Siku series volume 3 container. |
| `tmp/pdfs/daliuren/liuren-04-05.pdf` | Siku series combined volumes 4-5 container. |
| `tmp/pdfs/daliuren/liuren-06.pdf` | Siku series volume 6 container. |
| `tmp/pdfs/daliuren/liuren-07.pdf` | Siku series volume 7 container; the `三陰課` locus was inspected here. |
| `tmp/pdfs/daliuren/liuren-08.pdf` | Siku series volume 8 container. |
| `tmp/pdfs/daliuren/liuren-09.pdf` | Siku series volume 9 container. |
| `tmp/pdfs/daliuren/liuren-10.pdf` | Siku series volume 10 container. |
| `tmp/pdfs/daliuren/liuren-11-12.pdf` | Siku series combined volumes 11-12 container. |
| `tmp/pdfs/daliuren/guide.pdf` | Internet Archive image-container PDF of `大六壬指南`; its opening rule page was inspected. |
| `tmp/pdfs/daliuren/ocr/*/*_scandata.xml` | Archive pagination metadata used to check scan-leaf/PDF-page mappings. |
| `tmp/pdfs/daliuren/ocr/*/*_djvu.xml` and `*_djvu.txt` | Archive OCR used only to locate possible pages. |
| `tmp/pdfs/daliuren/transcripts/liuren-01-transcript.md` | Fixed-commit volume-1 transcript; it aligns with the inspected opening pages but remains `locator-only`. |
| `tmp/pdfs/daliuren/transcripts/liuren-07-transcript.md` | Fixed-commit transcript labelled volume 7; its contents do not align directly with the Siku volume-7 PDF. |
| `tmp/pdfs/daliuren/transcripts/liuren-10-transcript.md` | Fixed-commit transcript containing a six-relations/strength locator at lines 771-773. |
| `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md` | Fixed-commit transcript labelled volume 11; its contents do not align directly with the Siku volumes 11-12 PDF. |
| `.trellis/tasks/07-28-daliuren-classics-evidence/research/render/` | Temporary page renders used for first-pass visual inspection; not evidence-registry artifacts. |
| `.trellis/tasks/07-28-daliuren-classics-evidence/research/v06-ocr.jsonl` through `v10-ocr.jsonl` and `v45-ocr.jsonl` | Locally generated OCR search indexes; locator-only and not suitable for quotation authority. |

### Source registry and pagination

#### `欽定四庫全書・子部・六壬大全`

The Internet Archive items identify the collection as `universallibrary`, with Zhejiang University Library as contributor, CADAL as sponsor, and 600 ppi scanning. The remote PDF for each item is `<identifier>.pdf`. The local PDF page number equals the Archive scan-leaf/object ordinal; both are one-based.

| Local PDF | IA identifier | Internal volume | PDF pages / scan leaves | Remote PDF |
| --- | --- | ---: | ---: | --- |
| `liuren-01.pdf` | `06054168.cn` | 1 | 112 | `06054168.cn.pdf` |
| `liuren-02.pdf` | `06054169.cn` | 2 | 134 | `06054169.cn.pdf` |
| `liuren-03.pdf` | `06054170.cn` | 3 | 134 | `06054170.cn.pdf` |
| `liuren-04-05.pdf` | `06054171.cn` | 4-5 | 184 | `06054171.cn.pdf` |
| `liuren-06.pdf` | `06054172.cn` | 6 | 154 | `06054172.cn.pdf` |
| `liuren-07.pdf` | `06054173.cn` | 7 | 144 | `06054173.cn.pdf` |
| `liuren-08.pdf` | `06054174.cn` | 8 | 148 | `06054174.cn.pdf` |
| `liuren-09.pdf` | `06054175.cn` | 9 | 152 | `06054175.cn.pdf` |
| `liuren-10.pdf` | `06054176.cn` | 10 | 132 | `06054176.cn.pdf` |
| `liuren-11-12.pdf` | `06054177.cn` | 11-12 | 210 | `06054177.cn.pdf` |

Stable item URL pattern: `https://archive.org/details/<identifier>`. Accessed 2026-07-28.

In volume 1:

- PDF page 2 gives the internal title `欽定四庫全書・子部・六壬大全卷一`.
- PDF pages 3-9 contain `提要`, including `六壬大全十二卷不著撰人名氏`.
- PDF page 11 is printed folio 1a, page 12 is 1b, and subsequent pages continue by half-leaf. Thus page 26 is folio 8b, page 99 is 45a, and page 100 is 45b.

These title and pagination observations are `scanVerified (first pass; B-candidate pending independent recheck)`.

#### `大六壬指南`

| Field | Value |
| --- | --- |
| Local file | `tmp/pdfs/daliuren/guide.pdf` |
| IA identifier | `20210924_20210924_0416` |
| Remote file | `大六壬指南.pdf` |
| PDF pages | 83 |
| Mapping | Archive scan leaf is zero-based; `PDF page = scan leaf + 1` |
| Printed mapping | Printed page 1 is PDF page 6; for the numbered body, `printed page = PDF page - 5` |
| Stable item URL | `https://archive.org/details/20210924_20210924_0416` |
| Accessed | 2026-07-28 |

PDF page 2 visibly states `[明]陳公獻先生手著`, `[清]程翔雲先生鑑定`, `中國數術學研究社`, and `于鴻編輯/校訂`. Those title-page statements are `scanVerified (first pass; B-candidate pending independent recheck)`. Internet Archive metadata does not supply creator, publication date, or publisher, so the edition date and full bibliographic identity remain `unresolved`.

The scan ends around printed page 78 even though the contents refer through printed page 84. Whether leaves are missing or the contents describe a larger exemplar is `unresolved`.

### Critical transcript-to-scan mismatch

The fixed transcript filenames cannot be mapped to the Siku PDFs by volume number alone:

- `tmp/pdfs/daliuren/transcripts/liuren-07-transcript.md:1-5` labels the file volume 7 and begins `元首課`; `liuren-07.pdf` PDF page 3 visibly begins `無淫課`.
- `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md:1-5` labels the file volume 11 and begins `畢法賦`; `liuren-11-12.pdf` PDF page 3 visibly begins `十二宮分野上`.
- The volume-1 transcript aligns with the inspected volume-1 opening pages, but it is still `locator-only` because transcript line numbers are not scan loci.

Status: `scanVerified (first pass; B-candidate pending independent recheck)` for the two negative page comparisons. Consequence: volume 7, 10, and 11 transcript lines must be matched by visible text to a scan page before any rule citation is promoted. A filename or transcript heading is not a page mapping.

### Core rule loci

| Rule family | Scan locus | First-pass observation | Status | Implementation consequence |
| --- | --- | --- | --- | --- |
| Month general | `guide.pdf`, PDF 6, printed 1, scan leaf 5 | The page lists the twelve principal-term mappings: 雨水亥、春分戌、谷雨酉、小滿申、夏至未、大暑午、處暑巳、秋分辰、霜降卯、小雪寅、冬至丑、大寒子. | `scanVerified (first pass; B-candidate pending independent recheck)` | Supports the constant mapping, not the modern calendar library, timezone behavior, or fallback paths. |
| Heaven and earth plates | `guide.pdf`, PDF 6, printed 1, scan leaf 5 | `月將加占時之上`; `每以此值月之將而加來人所占之正時上順布十二宮辰即天盤也`; the fixed branch coordinates end `即地盤也`. | `scanVerified (first pass; B-candidate pending independent recheck)` | Supports month-general-over-hour and a fixed earth plate. |
| Four lessons | `guide.pdf`, PDF 6, printed 1, scan leaf 5 | `視陰陽為四課之分`, followed by all four lesson constructions. | `scanVerified (first pass; B-candidate pending independent recheck)` | Supports the four-lesson structure after an independent transcription check. |
| Nine methods, opening | `guide.pdf`, PDF 6-7, printed 1-2, scan leaves 5-6 | Page 6 says `四課既具須求三傳` and begins 贼克、比用、涉害; page 7 visibly continues the methods. | `scanVerified (first pass; B-candidate pending independent recheck)` for the section location; exact page-7 transcription and full dispatch priority are `unresolved`. | Do not infer the service's complete branch priority merely from section order. |
| Stem lodging and methods 1-2 | `liuren-01.pdf`, PDF 11, folio 1a | Ten-stem lodging, 贼克, and the start of 比用. | `scanVerified (first pass; B-candidate pending independent recheck)` | Candidate authority for lodging and the first two initiation methods. |
| Methods 2-4 | `liuren-01.pdf`, PDF 12, folio 1b | 比用, 涉害, and 遥克. | `scanVerified (first pass; B-candidate pending independent recheck)` | Candidate authority for those method definitions. |
| Methods 4-6 | `liuren-01.pdf`, PDF 13, folio 2a | 遥克, 昴星, and 别责. | `scanVerified (first pass; B-candidate pending independent recheck)` | Candidate authority for those method definitions. |
| Methods 6-8 | `liuren-01.pdf`, PDF 14, folio 2b | 别责, 八专, and 伏吟. | `scanVerified (first pass; B-candidate pending independent recheck)` | Candidate authority for those method definitions. |
| Methods 8-9 | `liuren-01.pdf`, PDF 15, folio 3a | 伏吟 and 返吟. | `scanVerified (first pass; B-candidate pending independent recheck)` | Candidate authority for the final two method definitions. |
| Twelve generals sequence | `liuren-01.pdf`, PDF 100-111, folios 45b-51a | The visible sequence is 貴人、螣蛇、朱雀、六合、勾陳、青龍、天空、白虎、太常、玄武、太陰、天后. | `scanVerified (first pass; B-candidate pending independent recheck)` | Supports the names and canonical sequence only; it does not establish selection, landing, or direction. |
| Reverse-running property | `liuren-07.pdf`, PDF 117, folio 58a | `三陰課` begins and states `凡天乙逆行日辰在後...`. | `scanVerified (first pass; B-candidate pending independent recheck)` | Confirms that `天乙逆行` is a meaningful property, but does not state how direction is selected. |

### FanYin no-overcoming days

`liuren-01.pdf`, PDF 15 / folio 3a visibly reads:

> 返吟有尅亦為用，無尅別有井欄名。若知六日該無尅，丑未同干丁己辛。

The wording identifies six stem-branch combinations: 丁丑、己丑、辛丑、丁未、己未、辛未. The quotation and its six-day reading are `scanVerified (first pass; B-candidate pending independent recheck)`.

The current spec at `.trellis/spec/domain/daliuren-pan-engine.md:29` lists only 丁丑、己丑、丁未、己未, omitting both 辛 days. Until the quotation and interpretation receive the required independent review, the implementation decision is `unresolved`; do not silently freeze either the four-day or six-day list. `SanChuanService` currently applies the no-overcoming FanYin branch structurally at `lib/domain/services/daliuren/san_chuan_service.dart:548-574` without an explicit day whitelist, so tests must determine whether the omitted 辛 days are reachable and handled correctly rather than relying only on the prose spec.

### Shen Sha inventory boundary

The following volume-1 boundaries were visually located:

| Locus | Visible heading/content | Status |
| --- | --- | --- |
| `liuren-01.pdf`, PDF 26, folio 8b | `神煞`, then `歲神煞` | `scanVerified (first pass; B-candidate pending independent recheck)` |
| PDF 30, folio 10b | `十天干神煞` | `scanVerified (first pass; B-candidate pending independent recheck)` |
| PDF 32, folio 11b | `十二地支神煞` | `scanVerified (first pass; B-candidate pending independent recheck)` |
| PDF 34-38 | Seasonal/month tables | `scanVerified (first pass; B-candidate pending independent recheck)` |
| PDF 39, folio 15a | `逐月神煞` | `scanVerified (first pass; B-candidate pending independent recheck)` |
| PDF 56, folio 23b | Final monthly table in this run | `scanVerified (first pass; B-candidate pending independent recheck)` |
| PDF 57, folio 24a | Separate `總鈐 / 德煞 / 德` material | `scanVerified (first pass; B-candidate pending independent recheck)` |

Candidate finite inventory boundary: PDF pages 26-56 inclusive. Page 57 begins a distinct section and later incidental mentions should not be counted as inventory entries. The boundary is a B-candidate; the complete item-by-item inventory, derivation dimensions, and adoption/exclusion decisions remain `unresolved` until they are transcribed from the scans and independently checked.

### Noble person and general placement

`liuren-01.pdf`, PDF 99 / folio 45a contains `先天貴神圖`. PDF 100 / folio 45b explicitly comments:

> 此貴神晝順行夜逆行...其說甚有理而近不用。

This negative statement is `scanVerified (first pass; B-candidate pending independent recheck)`. It means the displayed day-forward/night-reverse view is explicitly described as not used in the source and must not be treated as positive authority for current behavior.

No positive scan-backed authority was found for any of the following:

| Question | Status | Required before promotion |
| --- | --- | --- |
| Adopted ten-stem day/night noble-person table | `unresolved` | A visible adopted table or verse in a reliable scan, with edition and page locus. |
| Day/night boundary, including whether 卯-申 is day | `unresolved` | A positive rule locus defining the boundary. |
| Direction selected from the noble person's earth-palace landing | `unresolved` | A positive rule locus plus examples that distinguish heavenly noble branch from its landing palace. |
| Full relation among chosen noble branch, inverse heaven-plate landing, and general direction | `unresolved` | A scan-backed algorithm and independently recomputed fixtures. |

Locator leads, none of which may establish the rule:

- `tmp/pdfs/daliuren/transcripts/liuren-07-transcript.md:1267-1271`: `天乙貴人左行正理` and the example `天乙子臨亥順行` (`locator-only`).
- `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md:621-623`: `貴人順治格` and `貴人逆治格` (`locator-only`).
- Fixed `六壬存验` transcript at `六壬存验-清-吴师青.txt:L329`: selected heavenly noble landing in 亥子丑寅卯辰 goes forward and landing in 巳午未申酉戌 goes reverse (`locator-only`); no matching scan was found.
- IA candidate `20260504_20260504_1528`, `御定六壬直指`, is described by its uploader as a 1662 manuscript, but provenance is weak and OCR is unusable. It remains `unresolved` and cannot fill this gap.

### Other core gaps

| Topic | Best lead | Status | Note |
| --- | --- | --- | --- |
| 旺相休囚死 | `tmp/pdfs/daliuren/transcripts/liuren-07-transcript.md:89-91` | `locator-only` | The transcript provides seasonal mappings, but its file-level volume mapping is unreliable. |
| Six relations and strength use | `tmp/pdfs/daliuren/transcripts/liuren-10-transcript.md:771-773` | `locator-only` | The passage discusses 五行六親 and 旺相休囚; it has not been matched to a scan. |
| 旬空 | No dedicated scan-verified definition located | `unresolved` | Existing app behavior cannot self-authorize the classic rule. |
| 遁干 | No dedicated scan-verified definition located | `unresolved` | Existing fixtures or transcriptions remain secondary evidence. |

### Code patterns and impacts

| Code locus | Current pattern | Evidence impact |
| --- | --- | --- |
| `lib/divination_systems/daliuren/daliuren_constants.dart:203-220` | Defines a ten-stem two-position noble table and calls entries day/night nobles. | `unresolved`; no positive adopted scan locus was found for this exact table/order. |
| `lib/divination_systems/daliuren/daliuren_constants.dart:305-335` | Stores both forward and reversed general lists. | The general names/forward sequence are a B-candidate; the direction-selection contract is `unresolved`. |
| `lib/divination_systems/daliuren/daliuren_constants.dart:416-429` | Falls back to `['丑','未']` for an unknown stem and supports an alternate 甲-day swap. | Both fallback authority and the alternate-verse behavior are `unresolved`. |
| `lib/domain/services/daliuren/shen_jiang_service.dart:28-44` | Treats 卯-申 as day and equates day/night directly with forward/reverse placement. | This matches the explicitly disused view's description rather than a located adopted rule; do not promote it. |
| `lib/domain/services/daliuren/shen_jiang_service.dart:46-74` | Uses the selected noble branch directly as an earth index; it does not first invert `tianPanMap` to find the earth palace on which that heavenly branch lands. It also reverses both the list and the earth-step direction at night. | Landing and direction are `unresolved`; the two reversals can cancel in the final relative sequence and need explicit coordinate tests. |
| `lib/domain/services/daliuren/yue_jiang_service.dart:12-24` | Encodes the twelve principal-term mappings. | Direct B-candidate match to `guide.pdf` PDF 6. |
| `lib/domain/services/daliuren/yue_jiang_service.dart:75-98` and `:101-156` | Resolves the most recent principal term and supplies month/term fallbacks. | Only the mapping is scan-backed here; calendar-library boundaries and fallback semantics remain outside this source finding. |
| `lib/domain/services/daliuren/tianpan_service.dart:24-46` | Places month general over the hour and walks the twelve branches. | Direct B-candidate match to `guide.pdf` PDF 6. |
| `lib/domain/services/daliuren/si_ke_service.dart:30-47` | Builds all four lessons from stem lodging, day branch, and repeated heaven-plate lookup. | Direct B-candidate match to the opening rule pages, pending independent transcription review. |
| `lib/domain/services/daliuren/san_chuan_service.dart:23-34` and `:92-132` | Implements a fixed dispatch order for the nine methods. | The method sections are located, but the complete priority semantics are not yet independently verified. |
| `lib/domain/services/daliuren/san_chuan_service.dart:548-574` | Implements FanYin with and without overcoming. | The six-day quotation conflicts with the four-day spec; behavior remains `unresolved` pending recheck and reachability tests. |
| `lib/domain/services/daliuren/shen_sha_service.dart:18-218` | Emits 15 named items: 5 auspicious, 6 inauspicious, and 4 neutral. | The classic candidate inventory spans PDF 26-56 and is much broader; this service must not be described as a complete classic inventory. |
| `lib/domain/services/daliuren/shen_sha_service.dart:223-352` | Mixes month-branch, day-branch, fixed-position, and other derivations; 天德/月德 can return stems through the branch-valued `diZhi` field. | Full derivations are `unresolved`; the stem/branch value-domain mismatch should be corrected only in an implementation task backed by the itemized inventory. |

### External references

- Internet Archive Siku series: `https://archive.org/details/06054168.cn` through `https://archive.org/details/06054177.cn`; item metadata and scandata accessed 2026-07-28.
- Internet Archive `大六壬指南`: `https://archive.org/details/20210924_20210924_0416`; item metadata, PDF, and scandata accessed 2026-07-28.
- Fixed `六壬大全` transcript: youngzs/xuanxue commit `aa7bc942602d2d88ef94778a726c0d19a4d286ff`; `locator-only`.
- Fixed `六壬存验` transcript: mahavivo/scripta-sinica commit `d2a447941d43fd5ac35b35194dcb0a68d4275aa7`; `locator-only`.
- Internet Archive candidate `御定六壬直指`: `https://archive.org/details/20260504_20260504_1528`; `unresolved` due to provenance and legibility.

### Related specs and task contracts

- `.trellis/spec/domain/daliuren-pan-engine.md:1-30`: current plate and nine-method contract; line 29 contains the four-day FanYin statement that conflicts with the scan-verified six-day candidate.
- `.trellis/spec/domain/daliuren-analysis-engine.md:5-9`: distinguishes classic evidence claims from project conventions; analysis behavior cannot upgrade weak source evidence.
- `.trellis/tasks/07-28-daliuren-classics-evidence/prd.md`: requires every executable rule to have at least B-level page evidence and forbids OCR/current-code self-confirmation.
- `.trellis/tasks/07-28-daliuren-classics-evidence/design.md`: requires a second independent visual review before A/B promotion.

## Caveats / Not Found

- No final A/B rule approval is made here. Every visually inspected positive locus remains `scanVerified (first pass; B-candidate pending independent recheck)`.
- The adopted noble-person table, day/night boundary, landing-palace direction rule, and full placement algorithm remain `unresolved`. The only directly relevant Siku diagram found is explicitly described as `近不用`.
- The FanYin scan supports a six-day candidate including 辛丑 and 辛未, but the implementation decision remains `unresolved` until an independent recheck and structural tests settle the conflict with the current four-day spec.
- No scan-verified dedicated definitions were found for 旬空 or 遁干. 旺相休囚死 and six-relations material remain `locator-only`.
- The candidate Shen Sha inventory boundary is PDF 26-56; its item count, names, derivation dimensions, and exclusions have not yet been transcribed and independently checked.
- `大六壬指南` publication date and precise edition remain `unresolved`, and its scan appears to stop before the last pages named in its contents.
- Fixed transcript volume labels are not reliable proxies for Siku scan volumes. Direct transcript-line-to-PDF-page mapping is prohibited without visual text matching.
- No matching scan was found for the fixed `六壬存验` direction passage. `大六壬断案` and `六壬存验` therefore remain unsuitable for A/B case or rule evidence in this task.
