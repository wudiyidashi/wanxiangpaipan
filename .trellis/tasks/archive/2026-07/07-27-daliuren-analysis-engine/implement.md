# 实施清单：大六壬分析引擎

规则依据：本任务 design.md。排盘口径参照 `.trellis/spec/domain/daliuren-pan-engine.md`（不得改动排盘层逻辑）。

## Step 1 共享模型提升

- [ ] 新建 `lib/domain/services/shared/analysis/models/polarity.dart`、`verdict_models.dart`（design §1，字段原样迁移）。
- [ ] 六爻 `analysis_tag.dart`/`analysis_report.dart` 删除迁出类，追加 `export`；消费方 import 零改动。
- [ ] `dart run build_runner build --delete-conflicting-outputs` 再生成；跑六爻侧测试确认零回归。

## Step 2 大六壬分析模型

- [ ] `lib/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart`：DlrTagCategory、DlrAnalysisTag、KeGeInfo、DaLiuRenAnalysisReport（design §2）+ freezed 生成。

## Step 3 事实层服务（按 design §3 表格实现，纯静态）

- [ ] `ke_ge_service.dart`（§3.1 全表）
- [ ] `gan_zhi_zhu_ke_service.dart`（§3.2）
- [ ] `chuan_analysis_service.dart`（§3.3 传级+课局级）
- [ ] `shen_sha_chuan_service.dart`（§3.4；先读 ShenSha 模型实际字段）

## Step 4 裁决与应期

- [ ] `daliuren_verdict_service.dart`：决策表 §4 顺序照抄，首行命中；factors/summary 按模板。
- [ ] `daliuren_ying_qi_service.dart`：§5 候选表。

## Step 5 入口与测试

- [ ] `daliuren_analyzer.dart`（§6）。
- [ ] 测试按 design §7：`test/unit/services/daliuren/analysis/` 下分文件（ke_ge / verdict / analyzer 等）。
- [ ] `flutter analyze` 零告警；`flutter test` 全量通过。

## 验证命令

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/unit/services/daliuren/
flutter test
```

## 回滚点

单 commit；共享模型迁移与分析层同 commit（迁移单独无意义）。回滚 `git revert`。

## 明确不做

- 不改排盘层（constants/si_ke/san_chuan/shen_sha 服务逻辑）；不做 UI/AI 接入；不落库任何派生数据；不动六爻逻辑与 3 个遗留未提交改动。
