# 奇门首次发布纠偏与最终验收证据

## 1. 不改写历史的发布时间线

| Commit | 事实 |
|---|---|
| `7d226a690fa411ca1fe74f021c0fa54dca875f2c` | 冻结 schema-1 排盘引擎。 |
| `a83647e65befa69eb4d972b843ec343b020e3332` | 形成分析内部候选；当时 `QimenSystem.isEnabled=false`，bootstrap 无 Qimen 注册，且无包含它的 tag 或远端分支。 |
| `8bbe6e4e40598a8608452670442156a7ae6618d2` | 归档分析任务。 |
| `4016ffc1d35a56cf4e5775982a11ac54bb3c2b8b` | 在大六壬归档提交中混入 Qimen 来源审计和归档证据修订；不冒充独立 Qimen 代码提交。 |
| `8138c6e008a198562bc829f129aff0f8416353d8` | 提交最终分析校正并首次同时启用 Qimen system、UI、Provider、formatter 和入口；固定为 analysis v1 首次发布基线。 |

`a83647e` 不存在用户可消费的已发布分析版本，分析报告也不持久化，因此本纠偏不
伪造错误旧版本。`8138c6e` 后若改变规则谓词、来源裁定、冲突、裁决或应期语义，
仍必须新增规则版本。

## 2. `8138c6e` 的 18 个 analysis slice

生产路径（8）：

1. `lib/domain/services/qimen/analysis/facts/qimen_formation_service.dart`
2. `lib/domain/services/qimen/analysis/facts/qimen_relation_fact_service.dart`
3. `lib/domain/services/qimen/analysis/models/qimen_analysis_models.dart`
4. `lib/domain/services/qimen/analysis/models/qimen_analysis_projection.dart`
5. `lib/domain/services/qimen/analysis/qimen_analysis_input_guard.dart`
6. `lib/domain/services/qimen/analysis/qimen_analyzer.dart`
7. `lib/domain/services/qimen/analysis/qimen_verdict_service.dart`
8. `lib/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart`

测试与 fixture 路径（10）：

1. `test/unit/services/qimen/analysis/fixtures/qimen_analysis_goldens.json`
2. `test/unit/services/qimen/analysis/helpers/qimen_rule_coverage_manifest.dart`
3. `test/unit/services/qimen/analysis/qimen_analysis_golden_test.dart`
4. `test/unit/services/qimen/analysis/qimen_analysis_input_guard_test.dart`
5. `test/unit/services/qimen/analysis/qimen_analyzer_test.dart`
6. `test/unit/services/qimen/analysis/qimen_catalog_test.dart`
7. `test/unit/services/qimen/analysis/qimen_conflict_verdict_test.dart`
8. `test/unit/services/qimen/analysis/qimen_fact_evaluators_test.dart`
9. `test/unit/services/qimen/analysis/qimen_rule_coverage_test.dart`
10. `test/unit/services/qimen/analysis/qimen_ying_qi_service_test.dart`

同一提交还同步了生成工具
`tool/qimen_analysis/generate_analysis_goldens.dart`；它不计入上述 8+10 产品/测试
slice。最终 fixture 包含 19 个 case，SHA-256 为
`D575DC31D56C8F6585D365CB42212F36C56FD37D3C97A22DD288BEF9ADE73E2E`。
`8138c6e` 状态的聚焦 analysis 套件为 123 项；本纠偏新增九遁逐条件回归后的当前
数量以本文件第 5 节的新运行结果为准。

## 3. 产品 A1..A14 重新映射

| 验收 | 最终证据 |
|---|---|
| A1 / A1-R | 原 A1 在归档 PRD 中保留为失败；本任务 spec、时间线、18 路径和 D575 哈希建立首次 enabled v1 替代基线。 |
| A2 | `registry_bootstrap_test.dart`；`qimen_app_provider_test.dart` 从真实首页 Qimen 卡片经 registry 到 `QimenCastScreen`。 |
| A3 | `qimen_cast_screen_test.dart` 覆盖 `-180/180`、茅山和 picker 实际 castTime；`qimen_viewmodel_test.dart` 锁定 payload allowlist。 |
| A4 | `qimen_system_test.dart` 独立拒绝未知 term/dun/yuan 与 `0/10`；`qimen_cast_screen_test.dart` 覆盖合法手动流程及 saving 重复点击。 |
| A5 | `qimen_cast_screen_test.dart` 锁定 cast/save/navigation 次序、两阶段卸载和保存失败；`qimen_viewmodel_test.dart` 锁定加密占问。 |
| A6 | `qimen_result_screen_test.dart` 覆盖 320/390/600、横屏、大字、洛书顺序和九宫详情。 |
| A7 | `qimen_result_screen_test.dart` 与 analysis 套件覆盖裁决、条件、事实、来源、冲突和应期；评分术语搜索见第 4 节。 |
| A8 | `qimen_result_screen_test.dart` 覆盖损坏/未来 schema、无唯一焦点和 current/显式 `v1`；`qimen_analyzer_test.dart` 覆盖 wire 边界。 |
| A9 | `qimen_repository_roundtrip_test.dart` 与 Qimen UI/history 测试覆盖 JSON/Drift 往返和 registry 重开。 |
| A10 | `qimen_data_management_integration_test.dart` 与 `data_management_screen_test.dart` 覆盖统计、导入导出和隔离清理。 |
| A11 | `qimen_formatter_test.dart`、`builtin_templates_test.dart` 和结果页 AI 降级测试锁定程序唯一计算方策略。 |
| A12 | `qimen_asset_test.dart` 解码并在真实三列目标尺寸渲染位图；同目录 provenance 文件记录生成来源。 |
| A13 | `divination_system_test.dart`、registry 测试和第 4 节三项架构搜索。 |
| A14 | 第 5 节记录格式、分析、目标 Qimen、analyze、全量测试和 Trellis validate 的本次实际结果。 |

父任务验收分别由 A2/A3/A4/A5 证明起局保存闭环，A6/A7 证明盘面与本地分析，
A9/A10 证明历史与数据管理，A11 证明 AI 与无配置降级，A13/A14 证明全仓质量门。

## 4. 架构审计

以下搜索只检查生产 Qimen UI/formatter 或全仓枚举消费点；测试文案和分析规则自身
的合法 `ruleSetVersion`/`score` 字段不作为误报：

```powershell
rg -n "DivinationType\\.|DivinationType.values" lib test
rg -n "score|rating|percent|percentage|weighted|标签数量|百分|星级|加权" lib/divination_systems/qimen lib/ai/output/formatters/qimen_formatter.dart
rg -n "Qimen(Time|Ju|Earth|Heaven|Duty|Door|Deity|Hidden|Marker).*Service" lib/divination_systems/qimen/ui lib/ai/output/formatters/qimen_formatter.dart
```

第二、三项的生产命中必须为零；第一项逐一复核所有 `DivinationType` 分支。

## 5. 本次验证结果

所有会受共享大六壬未完成代码影响的 Flutter 门禁均在隔离工作树
`C:\Users\15852\AppData\Local\Temp\wanxiang-qimen-release-audit-codex`
执行；该工作树只装配本任务的 Qimen source/test diff。

| 门禁 | 本次结果 |
|---|---|
| 格式 | 10 个本任务 Dart source/test 路径执行 `dart format --output=none --set-exit-if-changed`，零改动。移除测试假系统的未使用可选参数后再次检查，零改动。 |
| 聚焦边界 | `qimen_system_test.dart` + `qimen_analysis_input_guard_test.dart` + `qimen_fact_evaluators_test.dart`：32 项通过。 |
| 起局状态机 | `qimen_cast_screen_test.dart`：17 项通过。 |
| 分析套件 | `flutter test test/unit/services/qimen/analysis`：124 项通过。 |
| 结果页与首页 | `qimen_result_screen_test.dart` + `qimen_app_provider_test.dart`：11 项通过。 |
| 全部 Qimen 目标 | `flutter test test/widget/qimen test/unit/services/qimen test/unit/divination_systems/qimen`：202 项通过。 |
| 代码生成 | `dart run build_runner build --delete-conflicting-outputs`：成功，913 个 output；生成差异只存在于临时工作树，不进入本任务 diff。 |
| 静态分析 | 隔离工作树与最终共享工作树分别执行 `flutter analyze --no-pub`，均为 `No issues found`。 |
| 全量测试 | `flutter test`：1,207 项通过；仅输出既有 Drift multiple-database warning。 |
| 架构搜索 | `DivinationType` 生产 switch/列表逐一包含 `qiMen`；评分术语与 Qimen UI/formatter 排盘 service 搜索均零命中。 |
| diff | 全共享树 `git diff --check` 与本任务显式路径 `git diff --check -- <owned paths>` 均通过。 |
| Trellis | `task.py validate 07-28-qimen-release-audit` 与 `task.py validate 07-28-qimen-module` 均通过。 |

共享工作树早期曾被并行未完成的
`lib/divination_systems/daliuren/models/tianpan.dart` 手写 `copyWith` 与 Freezed
生成接口冲突阻塞；最终复核时该并行修改已稳定，共享树 analyzer 也通过。为避免把
中途外部状态误归因于 Qimen，全部 Qimen 目标和 1,207 项全量测试仍以隔离工作树
结果为验收依据；本任务未修改、回滚或暂存任何 Daliuren 路径。

## 6. 发布与工作树边界

本 implement 子代理未 stage、commit、archive 或修改 release notes。最终 staging 必须
使用 Qimen 纠偏显式白名单，并再次确认不包含 `.trellis/tasks/07-28-daliuren-*`、
`lib/**/daliuren/**`、`test/**/daliuren/**` 或 `tmp/**`。
