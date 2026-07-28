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

- `flutter analyze`：通过。
- 大六壬结果、规则契约、排盘、分析与 widget 定向测试：130 项通过。
- AI formatter 与大六壬 widget：15 项通过。
- 六爻共享回归：229 项通过。
- 大六壬代码、测试和规范范围 `flutter analyze`：无问题。
- 独立 `trellis-check` 补齐 classic `executableApproved` 门禁、project-pan 命名域与非法 JSON 失败测试。
- 干净隔离 worktree 仅叠加 C01 后：build_runner 成功，`flutter analyze` 通过，`flutter test` 1050 项全部通过。
- 主工作区全量测试仅受并行奇门 UI 未完成改动影响；隔离门禁证明 C01 本身无全量回归。

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
