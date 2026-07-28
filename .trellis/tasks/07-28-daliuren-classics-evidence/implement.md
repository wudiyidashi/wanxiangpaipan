# 实施清单：古籍证据库与外部课例

## Step 1：固定底本

- [ ] 核验《六壬大全》十二卷各册 identifier、文件、卷次和 scan/PDF 页映射。
- [ ] 核验《大六壬指南》版本信息、文件和页码体系。
- [ ] 寻找并登记可核验的《大六壬断案》影印版本；找不到时不得把转录提升为 A/B。
- [ ] 为《六壬存验》固定转录定位匹配可核影印底本。
- [ ] 登记《壬归》《六壬粹言》《大六壬探原》等补缺候选及使用限制。

## Step 2：schema 与 validator

- [ ] 建立 source/rule/variant/case JSON schema 和目录约定。
- [ ] 实现 `validate.dart` 的 shape、引用、数量、证据和 fixture 校验。
- [ ] 为每类失败写 validator 单测或固定失败 fixture。
- [ ] 生成 evidence coverage 报告，区分 approved/pending/excluded/disputed。

## Step 3：基础盘证据

- [ ] 核页月将、天地盘、四课、贵人、昼夜、落宫顺逆和九宗门。
- [ ] 冻结会改变盘面的贵人/天将异文决策。
- [ ] 核定反吟无克丁己辛丑未六日及九宗门分支依据。
- [ ] 登记旬空、遁干、旺相、六亲/关系规则。

## Step 4：有限知识清单

- [ ] 按底本冻结完整神煞清单、起例维度和明确排除项。
- [ ] 核页并登记恰好 64 个课经条目。
- [ ] 核页并登记恰好 100 个毕法条目。
- [ ] 冻结占类 taxonomy、类神、本命/行年所需输入和采用法。
- [ ] 冻结《指南》传统断课与应期的有限规则清单。

## Step 5：外部完整课例

- [ ] 从《断案》《存验》登记至少两张输入足够、可复算的完整课例。
- [ ] 独立复盘预期事实，记录假设和 unknown，不调用生产代码。
- [ ] 覆盖月将/天将、至少两个九宗门分支、神煞/经典规则、占类或年命及应期中的可核层。
- [ ] 将内部 13 位移盘降级标为 C 级结构回归，不作为外例。

## Step 6：审校与交接

- [ ] 对所有 A/B 条目做第二次页码、短引和解释复核。
- [ ] 运行全目录 validator，确认 64/100、引用、fixture 和 evidence gate。
- [ ] 输出覆盖报告和未决异文表。
- [ ] 更新父能力矩阵，并将各规则族文件加入后续子任务 context。

## 验证

```powershell
dart run tool/daliuren_classics/validate.dart
dart test test/tool/daliuren_classics
git diff --check
```

若 validator 采用 Flutter test 而非 Dart test，实施时统一命令并更新本文件。

## 回滚点

- schema/validator、sources、基础规则、64/100、外部 cases 分开提交。
- 不执行产品算法改动，因此证据争议可回滚单个 family 文件而不影响现有排盘。

