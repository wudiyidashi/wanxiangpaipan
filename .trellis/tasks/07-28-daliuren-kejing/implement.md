# 实施清单：六十四课经

## 前置 Gate

- [ ] 证据目录已核定卷七至卷十的 64 个题名、ordinal、影印页和短引文。
- [ ] 规则契约、盘面版本和 `DaLiuRenFactSet` 已由前置子任务稳定。
- [ ] 九宗门、遁干、旺相等课经所需事实均有 typed 字段；缺项先回前置任务处理。

## Step 1：目录 schema 与生成

- [ ] 定义 kejing JSON schema 和封闭 predicate 节点。
- [ ] 录入并校验恰好 64 条规则，拒绝占位、重复和无页码条目。
- [ ] 扩展生成器，产出强类型目录和稳定版本常量。
- [ ] 增加生成同步、关系环和悬空 fact path 检查。

## Step 2：领域模型与 evaluator

- [ ] 实现 `KeJingResult` / `KeJingReport` 及兼容状态。
- [ ] 实现原子条件和布尔组合 evaluator，记录 fact trace。
- [ ] 实现主次/互斥裁决与稳定排序。
- [ ] 将报告接入大六壬 analyzer 的经典规则区域，不改基础盘算法。

## Step 3：验证资料与测试

- [ ] 为 64 条规则逐条增加正例和反例 fixture。
- [ ] 增加多命中、互斥、稳定排序、缺事实、旧盘版本测试。
- [ ] 确认 expected fixture 不调用生产 evaluator 或生产排盘算法生成。
- [ ] 增加 JSON/report projection contract test。

## Step 4：基础输出与文档

- [ ] formatter 输出结构化课经命中、证据和版本，不让 LLM 补算。
- [ ] 更新大六壬 domain spec，记录目录和 evaluator 边界。
- [ ] 更新父能力矩阵中 64 课经的状态和剩余风险。

## 验证

```powershell
dart run tool/daliuren_classics/validate.dart --catalog kejing
flutter analyze lib/domain/services/daliuren lib/ai/output/formatters/daliuren_formatter.dart
flutter test test/unit/services/daliuren/classics/kejing
flutter test test/unit/ai/output/formatters/daliuren_formatter_test.dart
```

命令路径由证据子任务最终锁定；若不同必须同步更新，不得跳过目录校验。

## 回滚点

- 目录/生成器一个提交，evaluator/测试一个提交，formatter/spec 一个提交。
- 条目证据争议只禁用对应 ruleId 并升级 catalog version，不改写已有 ID 语义。

