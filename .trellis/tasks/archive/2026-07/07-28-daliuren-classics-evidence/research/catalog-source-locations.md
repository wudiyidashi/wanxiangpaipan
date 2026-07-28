# Research: Catalog Source Locations

- Query: Locate the 64 KeJing catalog entries and 100 BiFa rules in stable Internet Archive scans, reconcile local transcripts with physical volumes, and record availability limits for Duanan/Cunyan.
- Scope: mixed
- Date: 2026-07-28

## Findings

### Evidence policy used here

This document records the first-pass location audit. Its `V/C` and `T/C` table cells preserve the status of that pass. The companion `kejing-independent-review.md` and `bifa-independent-review.md` subsequently re-opened all 64 KeJing and 100 BiFa loci, supplied short quotations, and recorded corrections and variants. The registry may therefore treat both catalog identity/locus layers as B; typed conditions, priority, fixtures, and execution remain unapproved.

- `V/C`: the heading or opening text was visually located in a rendered scan during this pass; independent re-check and quotation are still pending.
- `T/C`: an exact candidate leaf was obtained from fixed-transcript alignment plus adjacent scan content, but the heading itself was not independently confirmed.
- No KeJing or BiFa row is implementation-approved; BiFa 76 remains disputed because the same bottom text has an internal `害/祸` wording variant.

### Stable scan sources and pagination

All listed Internet Archive records credit `浙江大学图书馆`. Accessed 2026-07-28 through `https://archive.org/metadata/<identifier>`.

| Physical volume | IA title | Identifier | Remote PDF | Local alias | PDF pages / scan leaves |
|---|---|---|---|---|---:|
| 4-5 | 六壬大全·卷四~卷五 | `06054171.cn` | `06054171.cn.pdf` | `tmp/pdfs/daliuren/liuren-04-05.pdf` | 184 |
| 6 | 六壬大全·卷六 | `06054172.cn` | `06054172.cn.pdf` | `tmp/pdfs/daliuren/liuren-06.pdf` | 154 |
| 7 | 六壬大全·卷七 | `06054173.cn` | `06054173.cn.pdf` | `tmp/pdfs/daliuren/liuren-07.pdf` | 144 |
| 8 | 六壬大全·卷八 | `06054174.cn` | `06054174.cn.pdf` | `tmp/pdfs/daliuren/liuren-08.pdf` | 148 |
| 9 | 六壬大全·卷九 | `06054175.cn` | `06054175.cn.pdf` | `tmp/pdfs/daliuren/liuren-09.pdf` | 152 |
| 10 | 六壬大全·卷十 | `06054176.cn` | `06054176.cn.pdf` | `tmp/pdfs/daliuren/liuren-10.pdf` | 132 |
| 11-12 | 六壬大全·卷十一~卷十二 | `06054177.cn` | `06054177.cn.pdf` | `tmp/pdfs/daliuren/liuren-11-12.pdf` | not needed for these catalogs |
| Guide | 大六壬指南 | `20210924_20210924_0416` | `大六壬指南.pdf` | `tmp/pdfs/daliuren/guide.pdf` | separately cataloged source |

For volumes 4-10, `pdfinfo` page count, DjVu `<OBJECT>` count, scandata `<pageData><page>` count, and scan leaf count agree. Consequently `pdfPage == scanLeaf` for every locus below. `printedLeaf` was not independently established and must remain null. Physical volume 5 begins at combined PDF/scan leaf 35.

### Corrected transcript-to-scan alignment

The local fixed-transcript file number is not a safe physical-volume locator at the boundaries:

| Transcript | Catalog content | Physical scan placement |
|---|---|---|
| `liuren-07-transcript.md` | KeJing 1-16 | volume 5, combined PDF leaves 35-179 |
| `liuren-08-transcript.md` | KeJing 17-30 | volume 6, leaves 3-85 |
| `liuren-09-transcript.md` | KeJing 31-52 | items 31-35 remain in volume 6; items 36-52 are in volume 7 |
| `liuren-10-transcript.md` | KeJing 53-64 | volume 8 |
| `liuren-11-transcript.md` | BiFa opening index and rules 1-50 | volume 9; index begins leaf 3, detailed rule 1 begins on candidate leaf 9 |
| `liuren-12-transcript.md` | BiFa rules 51-100 | volume 10; rule 51 begins leaf 3 |

### 64 KeJing loci

`Page/leaf` is the physical PDF page and equal scan leaf. The status column records this report's first pass; current page/name corrections and independent B-level catalog review are recorded in `kejing-independent-review.md`.

| # | Canonical name | Physical vol. | IA identifier | Local PDF | Page/leaf | Status |
|---:|---|---:|---|---|---:|---|
| 1 | 元首 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 35 | V/C |
| 2 | 重审 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 49 | V/C |
| 3 | 知一 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 57 | V/C |
| 4 | 涉害 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 64 | V/C |
| 5 | 遥克 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 81 | V/C |
| 6 | 昴星 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 93 | V/C |
| 7 | 别责 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 104 | V/C |
| 8 | 八专 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 109 | V/C |
| 9 | 伏吟 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 120 | V/C |
| 10 | 返吟 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 136 | V/C |
| 11 | 三光 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 147 | V/C |
| 12 | 三阳 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 154 | V/C |
| 13 | 三奇 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 160 | V/C |
| 14 | 六仪 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 170 | V/C |
| 15 | 时泰 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 176 | V/C |
| 16 | 龙德 | 5 | `06054171.cn` | `liuren-04-05.pdf` | 179 | V/C |
| 17 | 官爵 | 6 | `06054172.cn` | `liuren-06.pdf` | 3 | V/C |
| 18 | 富贵 | 6 | `06054172.cn` | `liuren-06.pdf` | 9 | V/C |
| 19 | 轩盖 | 6 | `06054172.cn` | `liuren-06.pdf` | 16 | V/C |
| 20 | 铸印 | 6 | `06054172.cn` | `liuren-06.pdf` | 21 | V/C |
| 21 | 斫轮 | 6 | `06054172.cn` | `liuren-06.pdf` | 27 | V/C |
| 22 | 引从 | 6 | `06054172.cn` | `liuren-06.pdf` | 35 | V/C |
| 23 | 亨通 | 6 | `06054172.cn` | `liuren-06.pdf` | 38 | V/C |
| 24 | 繁昌 | 6 | `06054172.cn` | `liuren-06.pdf` | 43 | V/C |
| 25 | 荣华 | 6 | `06054172.cn` | `liuren-06.pdf` | 53 | V/C |
| 26 | 德庆 | 6 | `06054172.cn` | `liuren-06.pdf` | 59 | V/C |
| 27 | 合欢 | 6 | `06054172.cn` | `liuren-06.pdf` | 62 | V/C |
| 28 | 和美 | 6 | `06054172.cn` | `liuren-06.pdf` | 68 | V/C |
| 29 | 斩关 | 6 | `06054172.cn` | `liuren-06.pdf` | 73 | V/C |
| 30 | 闭口 | 6 | `06054172.cn` | `liuren-06.pdf` | 85 | V/C |
| 31 | 游子 | 6 | `06054172.cn` | `liuren-06.pdf` | 105 | V/C |
| 32 | 三交 | 6 | `06054172.cn` | `liuren-06.pdf` | 113 | V/C |
| 33 | 赘婿 | 6 | `06054172.cn` | `liuren-06.pdf` | 132 | V/C |
| 34 | 冲破 | 6 | `06054172.cn` | `liuren-06.pdf` | 140 | V/C |
| 35 | 淫泆 | 6 | `06054172.cn` | `liuren-06.pdf` | 146 | V/C |
| 36 | 无淫 | 7 | `06054173.cn` | `liuren-07.pdf` | 3 | V/C |
| 37 | 解离 | 7 | `06054173.cn` | `liuren-07.pdf` | 12 | V/C |
| 38 | 度厄 | 7 | `06054173.cn` | `liuren-07.pdf` | 28 | V/C |
| 39 | 无禄绝嗣 | 7 | `06054173.cn` | `liuren-07.pdf` | 31 | V/C |
| 40 | 迍福 | 7 | `06054173.cn` | `liuren-07.pdf` | 41 | V/C |
| 41 | 侵害 | 7 | `06054173.cn` | `liuren-07.pdf` | 48 | V/C |
| 42 | 刑伤 | 7 | `06054173.cn` | `liuren-07.pdf` | 51 | V/C |
| 43 | 二烦 | 7 | `06054173.cn` | `liuren-07.pdf` | 56 | V/C |
| 44 | 天祸 | 7 | `06054173.cn` | `liuren-07.pdf` | 76 | V/C |
| 45 | 天狱 | 7 | `06054173.cn` | `liuren-07.pdf` | 85 | V/C |
| 46 | 天寇 | 7 | `06054173.cn` | `liuren-07.pdf` | 94 | V/C |
| 47 | 天网 | 7 | `06054173.cn` | `liuren-07.pdf` | 101 | V/C |
| 48 | 魄化 | 7 | `06054173.cn` | `liuren-07.pdf` | 108 | V/C |
| 49 | 三阴 | 7 | `06054173.cn` | `liuren-07.pdf` | 117 | V/C |
| 50 | 龙战 | 7 | `06054173.cn` | `liuren-07.pdf` | 122 | V/C |
| 51 | 死奇 | 7 | `06054173.cn` | `liuren-07.pdf` | 131 | V/C |
| 52 | 灾厄 | 7 | `06054173.cn` | `liuren-07.pdf` | 139 | V/C |
| 53 | 殃咎 | 8 | `06054174.cn` | `liuren-08.pdf` | 3 | V/C |
| 54 | 九丑 | 8 | `06054174.cn` | `liuren-08.pdf` | 9 | V/C |
| 55 | 鬼墓 | 8 | `06054174.cn` | `liuren-08.pdf` | 15 | V/C |
| 56 | 励德 | 8 | `06054174.cn` | `liuren-08.pdf` | 28 | V/C |
| 57 | 盘珠 | 8 | `06054174.cn` | `liuren-08.pdf` | 40 | V/C |
| 58 | 全局 | 8 | `06054174.cn` | `liuren-08.pdf` | 44 | V/C |
| 59 | 玄胎 | 8 | `06054174.cn` | `liuren-08.pdf` | 68 | V/C |
| 60 | 连珠 | 8 | `06054174.cn` | `liuren-08.pdf` | 78 | V/C |
| 61 | 间传 | 8 | `06054174.cn` | `liuren-08.pdf` | 83 | V/C |
| 62 | 六纯 | 8 | `06054174.cn` | `liuren-08.pdf` | 94 | V/C |
| 63 | 杂状 | 8 | `06054174.cn` | `liuren-08.pdf` | 100 | V/C |
| 64 | 物类 | 8 | `06054174.cn` | `liuren-08.pdf` | 102 | V/C |

### 100 BiFa loci

`Page/leaf` is again both PDF page and scan leaf. Rules 1-50 are in physical volume 9; rules 51-100 are in volume 10. Rule 52 is normalized to the ordinal sequence despite the fixed index's duplicate `第五十三法` label.

| # | Canonical rule name | Physical vol. | IA identifier | Local PDF | Page/leaf | Status |
|---:|---|---:|---|---|---:|---|
| 1 | 前后引从升迁吉 | 9 | `06054175.cn` | `liuren-09.pdf` | 9 | T/C |
| 2 | 首尾相见始终宜 | 9 | `06054175.cn` | `liuren-09.pdf` | 14 | V/C |
| 3 | 帘幕贵人高甲第 | 9 | `06054175.cn` | `liuren-09.pdf` | 17 | V/C |
| 4 | 催官使者赴官期 | 9 | `06054175.cn` | `liuren-09.pdf` | 21 | V/C |
| 5 | 六阳数足须公用 | 9 | `06054175.cn` | `liuren-09.pdf` | 23 | V/C |
| 6 | 六阴相继尽昏迷 | 9 | `06054175.cn` | `liuren-09.pdf` | 25 | V/C |
| 7 | 旺禄临身徒妄作 | 9 | `06054175.cn` | `liuren-09.pdf` | 27 | V/C |
| 8 | 权摄不正禄临支 | 9 | `06054175.cn` | `liuren-09.pdf` | 31 | V/C |
| 9 | 避难逃生须弃旧 | 9 | `06054175.cn` | `liuren-09.pdf` | 33 | V/C |
| 10 | 朽木难雕别作为 | 9 | `06054175.cn` | `liuren-09.pdf` | 38 | V/C |
| 11 | 众鬼虽彰全不畏 | 9 | `06054175.cn` | `liuren-09.pdf` | 38 | T/C (shared-leaf boundary) |
| 12 | 虽忧狐假虎威仪 | 9 | `06054175.cn` | `liuren-09.pdf` | 44 | V/C |
| 13 | 鬼贼当时无畏忌 | 9 | `06054175.cn` | `liuren-09.pdf` | 45 | V/C |
| 14 | 传财太旺反财亏 | 9 | `06054175.cn` | `liuren-09.pdf` | 46 | V/C |
| 15 | 脱上逢脱防虚诈 | 9 | `06054175.cn` | `liuren-09.pdf` | 47 | V/C |
| 16 | 空上乘空事莫追 | 9 | `06054175.cn` | `liuren-09.pdf` | 50 | V/C |
| 17 | 进茹空亡宜退步 | 9 | `06054175.cn` | `liuren-09.pdf` | 52 | V/C |
| 18 | 踏脚空亡进用宜 | 9 | `06054175.cn` | `liuren-09.pdf` | 54 | V/C |
| 19 | 胎财生气妻怀孕 | 9 | `06054175.cn` | `liuren-09.pdf` | 55 | V/C |
| 20 | 胎财死气损胎推 | 9 | `06054175.cn` | `liuren-09.pdf` | 66 | V/C |
| 21 | 交车相合交关利 | 9 | `06054175.cn` | `liuren-09.pdf` | 66 | V/C |
| 22 | 上下皆合两心齐 | 9 | `06054175.cn` | `liuren-09.pdf` | 71 | V/C |
| 23 | 彼求我事支传干 | 9 | `06054175.cn` | `liuren-09.pdf` | 76 | V/C |
| 24 | 我求彼事干传支 | 9 | `06054175.cn` | `liuren-09.pdf` | 76 | V/C |
| 25 | 金日逢丁凶祸动 | 9 | `06054175.cn` | `liuren-09.pdf` | 77 | V/C |
| 26 | 水日逢丁财动之 | 9 | `06054175.cn` | `liuren-09.pdf` | 85 | V/C |
| 27 | 传财化鬼财休觅 | 9 | `06054175.cn` | `liuren-09.pdf` | 89 | V/C |
| 28 | 传鬼化财钱险危 | 9 | `06054175.cn` | `liuren-09.pdf` | 94 | V/C |
| 29 | 眷属丰盈居狭宅 | 9 | `06054175.cn` | `liuren-09.pdf` | 98 | V/C |
| 30 | 屋宅宽广致人衰 | 9 | `06054175.cn` | `liuren-09.pdf` | 100 | V/C |
| 31 | 三传递生人举荐 | 9 | `06054175.cn` | `liuren-09.pdf` | 102 | V/C |
| 32 | 三传互克众人欺 | 9 | `06054175.cn` | `liuren-09.pdf` | 105 | V/C |
| 33 | 有始无终难变易 | 9 | `06054175.cn` | `liuren-09.pdf` | 108 | V/C |
| 34 | 苦去甘来乐里悲 | 9 | `06054175.cn` | `liuren-09.pdf` | 111 | V/C |
| 35 | 人宅受脱俱招盗 | 9 | `06054175.cn` | `liuren-09.pdf` | 116 | V/C |
| 36 | 干支皆败事倾颓 | 9 | `06054175.cn` | `liuren-09.pdf` | 119 | V/C |
| 37 | 末助初兮三等讼 | 9 | `06054175.cn` | `liuren-09.pdf` | 121 | V/C |
| 38 | 闭口卦体两般推 | 9 | `06054175.cn` | `liuren-09.pdf` | 124 | V/C |
| 39 | 太阳照武宜擒贼 | 9 | `06054175.cn` | `liuren-09.pdf` | 131 | V/C |
| 40 | 后合占婚岂用媒 | 9 | `06054175.cn` | `liuren-09.pdf` | 135 | V/C |
| 41 | 富贵干支逢禄马 | 9 | `06054175.cn` | `liuren-09.pdf` | 136 | V/C |
| 42 | 尊崇传内遇三奇 | 9 | `06054175.cn` | `liuren-09.pdf` | 137 | V/C |
| 43 | 害贵讼直作曲断 | 9 | `06054175.cn` | `liuren-09.pdf` | 139 | V/C |
| 44 | 课传俱贵转无依 | 9 | `06054175.cn` | `liuren-09.pdf` | 140 | V/C |
| 45 | 昼夜贵加求两贵 | 9 | `06054175.cn` | `liuren-09.pdf` | 142 | V/C |
| 46 | 贵人差迭事参差 | 9 | `06054175.cn` | `liuren-09.pdf` | 144 | V/C |
| 47 | 贵虽在狱宜临干 | 9 | `06054175.cn` | `liuren-09.pdf` | 145 | V/C |
| 48 | 鬼乘天乙乃神祗 | 9 | `06054175.cn` | `liuren-09.pdf` | 146 | V/C |
| 49 | 两贵受克难干贵 | 9 | `06054175.cn` | `liuren-09.pdf` | 147 | V/C |
| 50 | 二贵皆空虚喜期 | 9 | `06054175.cn` | `liuren-09.pdf` | 150 | V/C |
| 51 | 魁度天门关隔定 | 10 | `06054176.cn` | `liuren-10.pdf` | 3 | V/C |
| 52 | 罡塞鬼户任谋为 | 10 | `06054176.cn` | `liuren-10.pdf` | 4 | V/C |
| 53 | 两蛇夹墓凶难免 | 10 | `06054176.cn` | `liuren-10.pdf` | 7 | V/C |
| 54 | 虎视逢虎力难施 | 10 | `06054176.cn` | `liuren-10.pdf` | 10 | V/C |
| 55 | 所谋多拙逢网罗 | 10 | `06054176.cn` | `liuren-10.pdf` | 12 | V/C |
| 56 | 天网自裹己招非 | 10 | `06054176.cn` | `liuren-10.pdf` | 14 | V/C |
| 57 | 费有余而得不足 | 10 | `06054176.cn` | `liuren-10.pdf` | 16 | V/C |
| 58 | 用破身心无所归 | 10 | `06054176.cn` | `liuren-10.pdf` | 18 | V/C |
| 59 | 华盖覆日人昏晦 | 10 | `06054176.cn` | `liuren-10.pdf` | 19 | V/C |
| 60 | 太阳射宅屋光辉 | 10 | `06054176.cn` | `liuren-10.pdf` | 20 | V/C |
| 61 | 干乘墓虎无占病 | 10 | `06054176.cn` | `liuren-10.pdf` | 22 | V/C |
| 62 | 支乘墓虎有伏尸 | 10 | `06054176.cn` | `liuren-10.pdf` | 23 | V/C |
| 63 | 彼此全伤防两损 | 10 | `06054176.cn` | `liuren-10.pdf` | 26 | V/C |
| 64 | 夫妇芜淫各有私 | 10 | `06054176.cn` | `liuren-10.pdf` | 27 | V/C |
| 65 | 干墓并关人宅废 | 10 | `06054176.cn` | `liuren-10.pdf` | 29 | V/C |
| 66 | 支坟财并旅程稽 | 10 | `06054176.cn` | `liuren-10.pdf` | 30 | V/C |
| 67 | 受虎克神为病症 | 10 | `06054176.cn` | `liuren-10.pdf` | 30 | V/C |
| 68 | 制鬼之位乃良医 | 10 | `06054176.cn` | `liuren-10.pdf` | 41 | V/C |
| 69 | 虎乘遁鬼殃非浅 | 10 | `06054176.cn` | `liuren-10.pdf` | 44 | V/C |
| 70 | 鬼临三四讼灾随 | 10 | `06054176.cn` | `liuren-10.pdf` | 46 | V/C |
| 71 | 病符克宅全家患 | 10 | `06054176.cn` | `liuren-10.pdf` | 48 | V/C |
| 72 | 丧吊全逢挂缟衣 | 10 | `06054176.cn` | `liuren-10.pdf` | 49 | V/C |
| 73 | 前后逼迫难进退 | 10 | `06054176.cn` | `liuren-10.pdf` | 54 | V/C |
| 74 | 空空如也事休追 | 10 | `06054176.cn` | `liuren-10.pdf` | 57 | V/C |
| 75 | 宾主不投刑在上 | 10 | `06054176.cn` | `liuren-10.pdf` | 58 | V/C |
| 76 | 彼此猜忌害相随 | 10 | `06054176.cn` | `liuren-10.pdf` | 65 | V/C |
| 77 | 互生俱生凡事益 | 10 | `06054176.cn` | `liuren-10.pdf` | 68 | V/C |
| 78 | 互旺皆旺坐谋宜 | 10 | `06054176.cn` | `liuren-10.pdf` | 72 | V/C |
| 79 | 干支值绝凡谋决 | 10 | `06054176.cn` | `liuren-10.pdf` | 74 | V/C |
| 80 | 人宅皆死各衰羸 | 10 | `06054176.cn` | `liuren-10.pdf` | 76 | V/C |
| 81 | 传墓入墓分憎爱 | 10 | `06054176.cn` | `liuren-10.pdf` | 78 | V/C |
| 82 | 不行传者考初时 | 10 | `06054176.cn` | `liuren-10.pdf` | 80 | V/C |
| 83 | 万事喜忻三六合 | 10 | `06054176.cn` | `liuren-10.pdf` | 82 | V/C |
| 84 | 合中犯杀蜜中砒 | 10 | `06054176.cn` | `liuren-10.pdf` | 85 | V/C |
| 85 | 初遭夹克不由己 | 10 | `06054176.cn` | `liuren-10.pdf` | 87 | V/C |
| 86 | 将逢内战所谋危 | 10 | `06054176.cn` | `liuren-10.pdf` | 89 | V/C |
| 87 | 人宅坐墓甘招晦 | 10 | `06054176.cn` | `liuren-10.pdf` | 92 | V/C |
| 88 | 干支乘墓各昏迷 | 10 | `06054176.cn` | `liuren-10.pdf` | 94 | V/C |
| 89 | 任信丁马须言动 | 10 | `06054176.cn` | `liuren-10.pdf` | 97 | V/C |
| 90 | 来去俱空岂动宜 | 10 | `06054176.cn` | `liuren-10.pdf` | 100 | V/C |
| 91 | 虎临干鬼凶速速 | 10 | `06054176.cn` | `liuren-10.pdf` | 103 | V/C |
| 92 | 龙加生气吉迟迟 | 10 | `06054176.cn` | `liuren-10.pdf` | 107 | V/C |
| 93 | 妄用三传灾福异 | 10 | `06054176.cn` | `liuren-10.pdf` | 109 | V/C |
| 94 | 喜惧空亡乃妙机 | 10 | `06054176.cn` | `liuren-10.pdf` | 110 | V/C |
| 95 | 六爻现卦防其克 | 10 | `06054176.cn` | `liuren-10.pdf` | 115 | V/C |
| 96 | 旬内空亡逐类推 | 10 | `06054176.cn` | `liuren-10.pdf` | 124 | V/C |
| 97 | 所筮不入仍凭类 | 10 | `06054176.cn` | `liuren-10.pdf` | 128 | V/C |
| 98 | 非占现类勿言之 | 10 | `06054176.cn` | `liuren-10.pdf` | 128 | V/C |
| 99 | 常问不应逢吉象 | 10 | `06054176.cn` | `liuren-10.pdf` | 129 | V/C |
| 100 | 已灾凶逃返无疑 | 10 | `06054176.cn` | `liuren-10.pdf` | 130 | V/C |

### Duanan and Cunyan availability ceiling

- The CTP wiki entries for 《六壬断案》 and 《六壬存验》 state `版本暂缺`; they are fixed web transcriptions only and remain evidence C, locator-only.
- Internet Archive exact-title searches found no usable page-image scan for either work.
- NDL surfaced only the 2012 print 《大六壬断案疏正》, ISBN `9787801789174`; no online page images were available for verification.
- Local Duanan transcription identifies `邵彦和先生大六壬断案分编`, compiled by `古歙槐塘程铨爱圅氏辑`, with 216 cases assembled from five textual witnesses. This remains a transcription locator, not a scan source.
- No local Cunyan transcript or page-level scan was found. Its case registry must remain unresolved and non-executable.

### Files found

- `.trellis/workflow.md` - Trellis workflow and research-role constraints.
- `.trellis/tasks/07-28-daliuren-classics-evidence/prd.md` - evidence-level and locator-only acceptance rules.
- `.trellis/tasks/07-28-daliuren-classics-evidence/design.md` - source locus schema and independent-review workflow.
- `.trellis/spec/domain/index.md` - project routing index for the Daliuren domain specifications.
- `.trellis/spec/domain/daliuren-analysis-engine.md` - downstream distinction between classical-source claims and project-defined analysis conventions.
- `tmp/pdfs/daliuren/liuren-04-05.pdf` through `liuren-10.pdf` - local aliases of the IA scans used above.
- `tmp/pdfs/daliuren/ocr/06054171.cn` through `06054176.cn` - IA DjVu XML/text and scandata used for count/alignment checks only.
- `tmp/pdfs/daliuren/transcripts/liuren-07-transcript.md` through `liuren-10-transcript.md` - fixed KeJing transcriptions used only to find candidate headings.
- `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md` - BiFa index and rules 1-50; `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md:55` and `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md:57` expose the duplicate `第五十三法` index label.
- `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md` - BiFa rules 51-100; `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md:3`, `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md:7`, and `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md:15` preserve the sequential rules 51-53 and canonical rule 52 `罡塞鬼户任谋为`.
- `tmp/pdfs/daliuren/transcripts/duanan-book.md`, `duanan-yuan.md`, `duanan-heng.md`, `duanan-li.md`, `duanan-zhen.md` - fixed Duanan transcription witnesses, locator-only.

### Code/data patterns and related specs

- Source loci keep `pdfPage`, `scanLeaf`, and `printedLeaf` separate, while OCR/fixed transcripts remain secondary locators: `.trellis/tasks/07-28-daliuren-classics-evidence/design.md:46`.
- `locatorOnly` and `executableApproved` are independent states: `.trellis/tasks/07-28-daliuren-classics-evidence/design.md:57`.
- OCR/transcript evidence cannot become A/B or deterministic implementation input without returning to a scan: `.trellis/tasks/07-28-daliuren-classics-evidence/prd.md:18`.
- Exact family cardinalities are KeJing 64 and BiFa 100: `.trellis/tasks/07-28-daliuren-classics-evidence/prd.md:19`, `.trellis/tasks/07-28-daliuren-classics-evidence/prd.md:20`, `.trellis/tasks/07-28-daliuren-classics-evidence/design.md:87`, and `.trellis/tasks/07-28-daliuren-classics-evidence/prd.md:30`.
- A locator becomes independently reviewable only after a second view checks the locus, transcription, and interpretation: `.trellis/tasks/07-28-daliuren-classics-evidence/design.md:99`.
- The downstream analysis spec explicitly separates classical-source claims from project-defined interpretation: `.trellis/spec/domain/daliuren-analysis-engine.md:7`.
- The BiFa opening index mislabels rule 52 as another rule 53 at `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md:55`; the next rule is also labeled 53 at `tmp/pdfs/daliuren/transcripts/liuren-11-transcript.md:57`. The detailed volume-10 transcript restores the sequence at `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md:3`, `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md:7`, and `tmp/pdfs/daliuren/transcripts/liuren-12-transcript.md:15`.

### External references

- Internet Archive metadata API: `https://archive.org/metadata/<identifier>` for `06054171.cn` through `06054176.cn`; records identify the contributing library as `浙江大学图书馆` and the PDF filenames listed above. Accessed 2026-07-28.
- Chinese Text Project title pages for 《六壬断案》 and 《六壬存验》 report `版本暂缺`; treated only as fixed-transcript discovery surfaces. Accessed 2026-07-28.
- National Diet Library bibliographic search surfaced the 2012 print 《大六壬断案疏正》, ISBN `9787801789174`, but no reviewable online page images. Accessed 2026-07-28.
- Independent KeJing page/name/quotation review: `.trellis/tasks/07-28-daliuren-classics-evidence/research/kejing-independent-review.md`.
- Independent BiFa page/name/quotation review: `.trellis/tasks/07-28-daliuren-classics-evidence/research/bifa-independent-review.md`.

### Validation snapshot

- Markdown table parsing found 64/64 KeJing rows and 100/100 BiFa rows, sequential ordinals, 64 and 100 unique canonical names, no missing page-level locator, and no unexpected status.
- Boundary assertions passed: KeJing 31-35 are volume 6, 36-52 volume 7, 53-64 volume 8; BiFa 1-50 are volume 9 and 51-100 volume 10.
- First-pass locator coverage was 164/164 (100%): 162 visual `V/C` rows and 2 transcript-boundary `T/C` rows. After the companion reviews, current catalog-identity coverage is KeJing B 64/64 and BiFa B 100/100 (99 adopted, 1 disputed); A evidence and executable approvals remain 0.
- `pdfinfo` returned 184, 154, 144, 148, 152, and 132 pages for the six PDFs in identifier order `06054171.cn` through `06054176.cn`.
- XML parsing returned the same counts for both DjVu `<OBJECT>` and scandata `<page>` nodes for all six identifiers: 184, 154, 144, 148, 152, and 132.

### Reproduction method

- Metadata: `https://archive.org/metadata/<identifier>`.
- PDF page count: `pdfinfo tmp/pdfs/daliuren/<file>.pdf`.
- Scan count: compare `*_djvu.xml` `<OBJECT>` count with `*_scandata.xml` page count.
- Candidate location: fixed transcript plus OCR token index (locator-only).
- Visual check: `pdftoppm -f <page> -l <page> -r 300 -png -singlefile <pdf> <output>`, followed by direct inspection of the PNG.

## Caveats / Not Found

- KeJing and BiFa catalog identity/locus layers completed independent review in their companion reports; this does not approve typed conditions, priority, fixtures, or execution.
- The first-pass `T/C` boundary candidates for BiFa 1 and 11 were resolved by the independent review. The table keeps its historical first-pass status; the registry and companion report are authoritative.
- Several BiFa rules share one physical leaf; duplicate page numbers are intentional, not catalog duplication.
- Simplified canonical names normalize traditional scan glyphs. Exact quotations, title corrections and the BiFa 76 internal variant are recorded in the companion reviews.
- `printedLeaf` is unresolved for all rows; do not copy PDF page numbers into that field.
- No page-image basis was found for Duanan or Cunyan, so neither can supply an A/B external fixture in the current task state.
