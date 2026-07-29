# 实施计划：大六壬贵人与十二天将坐标重构

## Preconditions

- C00 证据目录已归档，C03 天盘/四课合同已归档。
- 实现前阅读 `prd.md`、`design.md`、本任务三份 research，以及 domain/frontend/cross-layer 规范。
- 工作区现有 `assets/images/screen_card/qimen_background.png` 和 `tmp/` 不属于本任务，不读取为实现依据、不修改、不提交。

## Phase 1: Evidence And Version Contracts

- [x] 修正 `sources.json`、`rules/shenjiang.json`、`variants.json` 的《直指》PDF 18/19 locator、二审人、B/adopted 状态和版本限制。
- [x] 合并 direction variant 的“逐支六区”和“天门地户原则”，采用 `landing-palace-six-zones`，保留“昼顺夜逆近不用”为非采用旧说。
- [x] 将 006 拆清古籍坐标事实与 project 双-map 契约；002/003 和完整算法 execution gate 保持未批准。
- [x] 同步 `tool/daliuren_classics/_seed_registry.dart`，运行 seed 生成并确认无手写漂移。
- [x] 修正归档 `noble-direction-independent-recheck.md` 中“六区仍为推导”的过时结论，以追加更正保留审计历史。
- [x] 将 evidence catalog 升到下一未占用版本，并更新版本测试/文档。

Gate:

```powershell
dart run tool/daliuren_classics/_seed_registry.dart
dart run tool/daliuren_classics/validate.dart
dart analyze tool/daliuren_classics test/tool/daliuren_classics
flutter test test/tool/daliuren_classics
```

## Phase 2: Model And Wire

- [x] 新增 `ShenJiangDirection` 及无歧义 position/config 字段、两个具名 resolver、project execution rule ID 和 classic attributions。
- [x] 实现 release 模式生效的完整性校验、防御性快照和 `validateAgainstTianPan`。
- [x] 实现 result-aware legacy config migration；v4 old-shape 拒绝，v3/legacy old-shape read-old/write-new。
- [x] 将 `DlrRuleSetVersions.panCurrent` 升为 v4，具名保留 panV3；更新 codegen 产物。
- [x] 为 current model、JSON malformed、外部可变集合、版本/shape 矩阵补单测。

Gate:

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/divination_systems/daliuren/daliuren_result_versioning_test.dart
flutter test test/unit/divination_systems/daliuren/dlr_rule_contract_test.dart
```

Rollback point: 若旧 v3 fixture 不能无损迁移，停止服务算法修改，先修正 migration；不得通过放宽 current 不变量绕过。

## Phase 3: Placement Service And Consumers

- [x] 收紧贵人表 helper：非法日干失败；自动昼夜非法时支失败；移除夜间双反转和独立 reverse order 的执行用途。
- [x] 实现 `selected heaven -> inverse landing -> six-zone direction -> fixed order` 唯一算法。
- [x] 拒绝新盘 `jiaDayAlt`，保留历史解码标签；从起课 UI 移除无依据的单干选项。
- [x] `DaLiuRenSystem` 的四课和三传统一按 heaven resolver；三传神将依赖改 required 并删除贵人 fallback。
- [x] ViewModel 拆分 heaven/earth 查询；圆盘切到 earth resolver。
- [x] 新增独立服务测试与昼/夜 x 顺/逆四类固定预期，同时更新三张《指南》系统 oracle 和三传相关测试。

Gate:

```powershell
flutter test test/unit/services/daliuren/shen_jiang_service_test.dart
flutter test test/unit/services/daliuren/si_ke_service_test.dart
flutter test test/unit/services/daliuren/san_chuan_service_test.dart
flutter test test/unit/divination_systems/daliuren/daliuren_system_test.dart
```

## Phase 4: Presentation, Persistence And Docs

- [x] 结果页显示所选天盘贵人支、所临地宫和实际方向；十二将位置显示“乘支/临宫”。
- [x] formatter human text 与 `coreData` 改为 `heavenBranch/earthPalace`，四课/三传乘将对齐同一 config。
- [x] 圆盘补天将地宫断言，结果区补长文本/窄屏或现有布局范围内的 widget 回归。
- [x] repository round-trip 和 data-management backup/import 增加真实 v3 old config，断言零 skipped、旧四课三传不变、重存为 new shape。
- [x] 修正 `docs/architecture/divination-systems/daliuren.md`、`docs/architecture/divination-system-interface.md` 中旧 wire、昼夜顺逆和 `jiaDayAlt` 描述。

Gate:

```powershell
flutter test test/unit/data/repositories/daliuren_repository_roundtrip_test.dart
flutter test test/unit/domain/services/daliuren_data_management_integration_test.dart
flutter test test/unit/ai/output/formatters/daliuren_formatter_test.dart
flutter test test/widget/daliuren
```

## Phase 5: Full Check

- [x] 运行 catalog seed/validator，确认生成文件同步且 002/003 未越权。
- [x] 搜索旧含混 API、`昼课顺布/夜课逆布`、新盘 `jiaDayAlt` 和三传贵人 fallback，逐个确认只剩合法历史兼容引用。
- [x] 运行格式化、全量 analyze、大六壬定向测试与全量测试。
- [x] 对照 PRD 验收每一条 current/legacy/cross-layer contract，并由 trellis-check 复核及自修。

## Verification Outcome

- `build_runner`、catalog seed/validator、`flutter analyze`、C04 定向服务/模型/仓储/备份/formatter/widget 测试均通过；最终检查收紧公开构造/copyWith 后，最后一轮定向门禁为 274 项通过。
- 全量 `flutter test` 为 1260 项通过、1 项失败。唯一失败是 `test/widget/qimen/qimen_asset_test.dart` 对用户既有修改 `assets/images/screen_card/qimen_background.png` 的宽度断言（期望 1024、实际 576）；该文件不属于 C04，未回退、未修复、不会提交。

```powershell
dart format lib test tool/daliuren_classics
dart run tool/daliuren_classics/validate.dart
flutter analyze
flutter test test/tool/daliuren_classics
flutter test test/unit/services/daliuren
flutter test test/unit/divination_systems/daliuren
flutter test test/unit/data/repositories/daliuren_repository_roundtrip_test.dart
flutter test test/unit/domain/services/daliuren_data_management_integration_test.dart
flutter test test/unit/ai/output/formatters/daliuren_formatter_test.dart
flutter test test/widget/daliuren
flutter test
```

## Risky Files And Review Points

- `shen_jiang_config.dart` / generated files：current wire 与旧盘读取的主边界。
- `daliuren_result.dart`：必须知道父级版本后再迁移 nested config，不能让低层 parser 猜版本。
- `san_chuan_service.dart`：删除 fallback 后所有测试/调用者必须显式供给神将事实。
- `daliuren_formatter.dart`：机器 schema 与 human text 同时变更，不能只修展示。
- evidence seed/generated JSON：只改一侧会被 seed 或 validator 覆盖。
