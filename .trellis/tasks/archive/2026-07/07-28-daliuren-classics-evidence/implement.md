# 实施清单：古籍证据库与外部课例

## Step 1：固定底本

- [x] 核验《六壬大全》十二卷各册 identifier、文件、卷次和 scan/PDF 页映射。
- [x] 核验《大六壬指南》版本信息、文件和页码体系。
- [x] 寻找并登记可核验的《大六壬断案》影印版本；馆藏检索未定位影印本，现有文本明确保持 C/pendingScan。
- [x] 为《六壬存验》固定转录检索可核影印底本；未定位逐页底本，三个课例明确保持 C/pendingScan。
- [x] 登记《壬归》《六壬粹言》《大六壬探原》等补缺候选及使用限制；未找到稳定影印 source 的候选不进入 A/B。

## Step 2：schema 与 validator

- [x] 建立 source/rule/variant/case JSON schema 和目录约定。
- [x] 实现 `validate.dart` 的 shape、引用、数量、证据和 fixture 校验。
- [x] 为关键失败路径建立 validator 单测；当前定向套件 24/24 通过。
- [x] 生成 evidence coverage 报告，区分 approved/pending/excluded/disputed。

## Step 3：基础盘证据

- [x] 登记并核页月将、天地盘、四课、贵人、昼夜、落宫顺逆和九宗门的当前证据上限；未二审项保持 C/pending。
- [x] 冻结会改变盘面的贵人/天将异文为 unresolved/non-configurable，禁止候选表进入默认算法。
- [x] 核定反吟无克丁己辛丑未六日依据，并以《指南》涉害古例补足第二个九宗门分支。
- [x] 登记旬空、遁干、旺相、六亲/关系的有限规则 ID；C/D 条目留待 C07 核页后批准执行。

## Step 4：有限知识清单

- [x] 按底本冻结 238 项神煞清单、起例维度和 3 个明确排除项；233 adopted、2 disputed，全部不可执行。
- [x] 核页并登记恰好 64 个课经条目；64 项均为 B/adopted，全部不可执行。
- [x] 核页并登记恰好 100 个毕法条目；99 adopted、1 disputed，全部不可执行。
- [x] 冻结 18 项占类/类神 taxonomy 与 8 项本命行年输入清单；当前均保持 C/locator-only，交 C08/C12 核页。
- [x] 冻结《指南》9 项传统断课与 8 项应期有限清单；当前均保持 C/locator-only，交 C13/C14 核页。

## Step 5：外部完整课例

- [x] 登记《断案》《存验》四张 locator-only C 课例；因无影印本不提升，并以三张《指南》影印课例满足 B 级完整外例门槛。
- [x] 独立复盘三张《指南》课例的可核事实、假设与 unknown，均声明未调用生产代码。
- [x] 三张 B 级课例覆盖月将/天盘/四课、重审与涉害两个九宗门分支、六亲及课经；年命/应期等未覆盖层明确不计完成。
- [x] 父能力矩阵将内部 13 位移盘定为 C 级结构回归，不作为外部古籍课例。

## Step 6：审校与交接

- [x] 对当前 A/B 条目登记独立第二 reviewer；validator 强制 reviewer 身份去重。
- [x] 运行全目录 validator，确认 238/64/100、引用、fixture 和 evidence gate。
- [x] 输出覆盖报告和未决异文表。
- [x] 更新父能力矩阵；后续子任务按所属家族消费 registry、coverage 与独立复核报告，C/D 条目不得直接实现。

## 当前状态（2026-07-28）

- 神煞在首次正式冻结前按后出的逐页全页清点从 236 重建为 238：在喝散后加入独立的禁神、孤神，原 ordinal 103 及以后整体顺移 2；关神/时煞异文引用同步迁移到 182/188。
- `孤神` 仅作为 PDF 36 正文题名；逐月表固定转录的 `孤神 -> 孤辰` 校正被限制在 monthly-grid normalization，二者另以 unresolved variant 明确阻塞静默合并。
- 当前固定门禁为 `shensha=238`、`kejing=64`、`bifa=100`。三族可执行批准均为 0；目录采用不等于 typed 条件或产品算法获批。
- 全库共 474 条规则、471 条非排除规则、5 条可执行批准规则；这 5 条均在 pan，不来自神煞、课经或毕法。
- 外例共 7 张：三张《指南》为 B/approved，四张《断案》《存验》为 C/locator-only；B 级课例已覆盖重审和涉害两个九宗门分支。
- C00 的完成只冻结证据目录、状态与门禁，不代表全部规则可执行。神将/九宗门、派生事实、年命、类神、传统裁决与应期的 C/D 条目分别由 C04-C14 核页并批准。

## 验证

```powershell
dart run tool/daliuren_classics/_seed_registry.dart
dart run tool/daliuren_classics/validate.dart
dart analyze tool/daliuren_classics test/tool/daliuren_classics
flutter test test/tool/daliuren_classics
git diff --check
```

## 回滚点

- schema/validator、sources、基础规则、64/100、外部 cases 分开提交。
- 不执行产品算法改动，因此证据争议可回滚单个 family 文件而不影响现有排盘。
