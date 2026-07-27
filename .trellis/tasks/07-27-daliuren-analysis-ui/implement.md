# 实施清单：大六壬可视化分析与AI接入

设计依据：本任务 design.md。分析层契约见 `.trellis/spec/domain/daliuren-analysis-engine.md`（只读）。

## Step 1 YingQiCard 提升共享

- [ ] 移动至 `lib/presentation/widgets/ying_qi_card.dart`，import 指向共享 verdict_models；原路径 export 转发。
- [ ] 跑六爻 widget/golden 测试确认零回归后再继续。

## Step 2 新组件

- [ ] `DaLiuRenKeGeCard`（design §2.1）。
- [ ] `DaLiuRenSanChuanSection` 注入 report 徽标 + 行点击（§2.2，向后兼容无 report 调用）。
- [ ] `DlrChuanDetailSheet`（§2.2）。
- [ ] `DaLiuRenPanDiskDialog` + painter + 入口 section（§2.4）。

## Step 3 结果页装配

- [ ] `daliuren_result_screen.dart` 按 design §1 顺序装配；build 内派生 report。

## Step 4 AI formatter

- [ ] 读 liuyao_formatter analysis section 风格后，为 daliuren_formatter 增加 analysis section 与 coreData 增补（§3）；不删不改既有字段。

## Step 5 测试与验证

- [ ] design §4 全部测试。
- [ ] `flutter analyze` 零告警。
- [ ] `flutter test` 全量通过（重点确认六爻 widget/golden 零回归）。

## 验证命令

```bash
flutter analyze
flutter test test/unit/services/daliuren/ test/unit/ai/
flutter test
```

## 回滚点

单 commit，`git revert` 可整体回滚；无 schema/存储变更。

## 明确不做

- 不接应期日历到大六壬（后续任务）；不做生克弦线之外的关系图；不改六爻结果页与分析层/排盘层逻辑；不动 3 个六爻遗留未提交改动；不做 git commit（主会话统一提交）。
