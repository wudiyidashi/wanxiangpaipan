# 实施清单：毕法赋百法

## 前置 Gate

- [ ] 卷十一至十二 100 法的题名、序号、影印页、短引和采用解释已核定。
- [ ] 规则契约和 `DaLiuRenFactSet` 稳定；神煞、三传及所需课经事实已可用。
- [ ] 课经子任务提供的 closed predicate AST 可复用，或已明确无需复制的共享位置。

## Step 1：目录与条件编译

- [ ] 定义/扩展 bifa schema、fact keys 和组合关系。
- [ ] 录入恰好 100 法并通过唯一性、引用、证据和可执行性校验。
- [ ] 生成强类型规则目录及 catalog version。
- [ ] 校验 requires/overrides/excludes 图无环且引用存在。

## Step 2：百法 evaluator

- [ ] 实现全部规则评估和原子 fact trace。
- [ ] 区分 false、missing fact、版本不兼容和命中。
- [ ] 实现多命中组合、显式覆盖/互斥和 suppressed trace。
- [ ] 输出稳定、与源 JSON 排列无关的顺序。

## Step 3：测试

- [ ] 100 法逐条正例/反例 table test。
- [ ] 单点事实变更或 mutation 敏感性检查。
- [ ] 外部完整盘多法共现 fixture。
- [ ] 互斥、覆盖、requires、缺事实、旧盘和 JSON contract 测试。

## Step 4：接入与规范

- [ ] analyzer 经典规则区域接入 `BiFaReport`。
- [ ] formatter 输出 ruleId、依据、证据、版本和冲突，不输出伪总分。
- [ ] 更新 domain spec 和父能力矩阵。

## 验证

```powershell
dart run tool/daliuren_classics/validate.dart --catalog bifa
flutter analyze lib/domain/services/daliuren lib/ai/output/formatters/daliuren_formatter.dart
flutter test test/unit/services/daliuren/classics/bifa
flutter test test/unit/services/daliuren/analysis
```

## 回滚点

- schema/目录、evaluator、接入分别提交。
- 证据或 predicate 有争议时禁用单法并保留 sourceRef；不得用 first-match 临时替代完整命中集。

