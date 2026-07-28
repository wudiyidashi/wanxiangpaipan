# 实施清单：大六壬规则来源与版本契约

## Step 1：typed 元数据

- [x] 新建 `DlrRuleRef`、规则种类、证据等级、版本常量和稳定 ID 常量。
- [x] 为非法 ID、空版本、classic A/B 缺 source 建失败测试。
- [x] 将现有 `DlrAnalysisTag` 与 `KeGeInfo` 生产分支迁移到稳定 ruleRef，禁止中文执行键。

## Step 2：结果版本与重放快照

- [x] 新建 `DlrCastInputSnapshot`、replay status 与 JSON-safe 深复制/capture helper。
- [x] `DaLiuRenResult` additive 增加 pan/evidence version、snapshot 和 `recastFromId`。
- [x] 四种 cast 流程写入实际规范化输入；不改变现有盘面计算调用顺序或结果。
- [x] 为 manual auto-month-general、computer no-seed 等不足写 `incomplete/missingFields`。

## Step 3：分析版本

- [x] 报告增加 analysis/source-pan version 和 compatibility。
- [x] analyzer 统一解析 current、legacy unknown、future mismatch。
- [x] 更新 formatter/UI fixture 构造，保持现有可见文本和机器键不删改。

## Step 4：兼容与生成

- [x] 新旧 JSON round-trip、未来版本保留、输入 Map 深复制测试。
- [x] 运行 build_runner，同步 Freezed/JSON 生成物。
- [x] 验证六爻共享分析模型无行为回归。

## Completion Evidence

- `dart run build_runner build --delete-conflicting-outputs`：通过，未新增 working-tree drift。
- 大六壬 model/system/service/formatter/widget 定向测试：136 项通过。
- 六爻共享回归：229 项通过。
- `flutter analyze`：全仓通过。
- `flutter test`：全仓 1116 项通过。
- 独立 `trellis-check` 补齐 classic `executableApproved` 门禁、C00 manifest 同步测试、project-pan 命名域、精确版本匹配和非法 JSON 失败测试。
- `task.py validate`：implement/check 各 10 条，全部通过。
- C01 范围 `git diff --check`：通过。

## Verification

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/unit/divination_systems/daliuren
flutter test test/unit/services/daliuren
flutter test test/unit/services/liuyao
flutter test
git diff --check
```

## Dependency Gate

- C00 未归档：只允许完善本 PRD/design/implement/context，不得开始产品代码。
- C00 已归档且本任务 `task.py validate` 通过：才可 `task.py start`。

## Rollback Point

规则元数据、结果 JSON、snapshot capture、分析版本分步提交。不得用回滚删除已发布 JSON 字段；停止写入时仍保留兼容读取。
