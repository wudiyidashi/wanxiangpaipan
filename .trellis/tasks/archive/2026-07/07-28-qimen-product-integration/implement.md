# 奇门遁甲界面与应用集成执行计划

## 0. Hard Dependency Gate

- [x] 0.1 确认 `07-28-qimen-pan-engine` 与 `07-28-qimen-analysis-engine` 已通过检查、提交并归档；未满足时不得启动本任务。
- [x] 0.2 记录两项提交、最终 schema/enum ID、fixture、analyzer/projection API 与 specs，运行其目标测试。
- [x] 0.3 将上游实际合同与本任务 PRD/design 逐项对照；存在实质差异时回到规划和用户评审门，不在 UI 中兼容猜测。

启动证据（2026-07-28）：

- 排盘提交 `7d226a690fa411ca1fe74f021c0fa54dca875f2c`，任务已归档到
  `.trellis/tasks/archive/2026-07/07-28-qimen-pan-engine`；`QimenResult` schema 为 `1`，
  公开消费入口为 `QimenSystem.cast` / `validateInput` / `resultFromJson`。
- 分析提交 `a83647e65befa69eb4d972b843ec343b020e3332` 是禁用、未注册的内部候选，
  `8bbe6e4e40598a8608452670442156a7ae6618d2` 随后归档该任务；
  `4016ffc1d35a56cf4e5775982a11ac54bb3c2b8b` 在无关的大六壬归档提交中混入
  Qimen 来源/证据修订，`8138c6e008a198562bc829f129aff0f8416353d8` 才提交最终
  分析校正并首次启用完整产品。后者是 `qimen-shijia-zhuanpan-analysis/v1` 的
  发布基线；report/projection schema 均为 `1`，公开消费入口仍为
  `QimenAnalyzer.analyze` / `analyzePersisted` 与
  `QimenAnalysisProjection.fromReport`。
- `8138c6e` 基线分析黄金 fixture SHA-256：
  `D575DC31D56C8F6585D365CB42212F36C56FD37D3C97A22DD288BEF9ADE73E2E`。
- 排盘口径稳定 ID：定局 `chaiBu/maoShan/zhiRun/manual`，时间基准
  `localCivil/beijing/trueSolar`，换日 `ziInitial/midnight`，寄宫
  `kunTwo/yangEightYinTwo`，暗干
  `dutyDoorHourStem/doorOriginEarthStem`，阴阳遁 `yang/yin`，三元
  `upper/middle/lower`，问事
  `general/career/wealth/relationship/health/study/travel/litigation`。
- 产品规划与冻结合同逐项对照无实质差异；UI/formatter 只消费 pan/report/projection，
  不导入排盘阶段 service，不持久化分析，不改写裁决。

## 1. 清点集成面并建立失败基线

- [x] 1.1 阅读统一术数接口、跨层/复用指南、父任务 integration map、两个上游 design/spec 和相关测试先例。
- [x] 1.2 运行 `rg "DivinationType\\." lib test`、`rg "DivinationType.values" lib test`、`rg "systemType" lib/ai lib/presentation lib/domain/services`，保存所有穷举和硬编码列表清单。
- [x] 1.3 最终合同测试存在并通过；仓库没有保留可定位的失败运行，因此不能声明
  这些测试在实现前曾按预期失败，也不能把本项作为历史 test-first 证据。
- [x] 1.4 确认通用 Drift 表足够，不创建 migration；若发现存储合同不符，暂停并回到设计评审。

## 2. ViewModel 与起局页

- [x] 2.1 实现 `QimenViewModel` 两种类型化 cast 入口和通用保存桥接，覆盖 loading/error/result、加密占问与重复提交测试。
- [x] 2.2 实现 `QimenCastScreen` 基础结构、占问、问事类型、time/manual 方式和最近方式恢复。
- [x] 2.3 实现自动起局日期时间、三种定局、三种时间基准；真太阳时条件经度与边界校验先通过 widget/payload 测试。
- [x] 2.4 实现高级换日、寄宫、暗干控件及折叠摘要，确保隐藏字段不进入错误 payload。
- [x] 2.5 实现手动四柱、节气、阴阳遁、局数和三元；覆盖缺失、非法六十甲子、越界和合法提交。
- [x] 2.6 实现 cast -> save -> registry navigation 状态机；保存失败、unmounted 与连续点击测试通过后再进入结果页工作。

Rollback point：此阶段不注册系统，整组 UI/ViewModel 可撤销且不影响现有入口。

## 3. 九宫与结果页

- [x] 3.1 实现时间/口径、局数/值符值使结果 sections，全部读取 `QimenResult` 字段。
- [x] 3.2 实现固定洛书顺序的 `QimenNinePalaceGrid`，为宫格定义稳定 track 和 main/hosted 槽；添加九宫唯一与顺序测试。
- [x] 3.3 实现宫位详情 sheet，覆盖天地盘、星门神、暗干、寄宫、空亡/驿马、标记、规则和来源。
- [x] 3.4 在 320/390/600 logical px、宽屏、横竖屏和放大文字下运行 widget overflow 测试；修复任何重叠、裁切和点击区域问题。
- [x] 3.5 按冻结顺序装配 `QimenResultScreen`，确保九宫和全部 sections 在无分析/诊断状态下仍可展示。

## 4. 本地分析展示

- [x] 4.1 接入 analyzer 的显式/current 规则版本，结果页只派生一次 report，不落库。
- [x] 4.2 实现四值裁决、条件、因素、焦点、事实、冲突与来源展示；完整 trace 按需展开。
- [x] 4.3 实现 Qimen 特有应期触发适配及观察窗口声明，不破坏现有共享 YingQi 消费者。
- [x] 4.4 覆盖 complete、unsupported pan schema、invalid pan facts、无唯一焦点和规则版本切换 UI 测试。
- [x] 4.5 搜索并拒绝 percent/score/rating/星级/加权/标签计数表现，颜色之外保留文本和 semantics。

## 5. 历史、数据管理与资源

- [x] 5.1 实现 `QimenUIFactory` 的 cast/result/history 构建和严格结果类型检查，但暂不启用 bootstrap。
- [x] 5.2 完成内存 Drift 保存、最近记录、按系统查询、历史卡片和 registry 详情重开的全链测试，深比较九宫和参数。
- [x] 5.3 更新数据统计、总量、奇门独立清理、导出/导入和设置 UI；同步测试 fake 与隔离测试。
- [x] 5.4 新增奇门系统色和 `qimen_background.png`；记录生成/许可信息，验证图片可解码、非空白、目标裁切可辨识和资源声明。
- [x] 5.5 更新首页/最近记录/历史卡片所有名称、背景和颜色分支，验证第五个系统时的窄屏网格。

## 6. AI Formatter 与模板

- [x] 6.1 实现 `QimenStructuredFormatter`，只使用 result + analysis projection，输出 calculationBasis/palaces/focusAndFacts/verdict/timing/policy。
- [x] 6.2 添加 formatter 类型错误、完整字段、稳定顺序、来源和 no-recalculate/no-override policy 测试。
- [x] 6.3 注册奇门 formatter，新增系统/综合/简要模板，更新 prompt assembler、设置和聊天标签。
- [x] 6.4 补齐 AI 会话 enum JSON 代码生成和旧数据回归；无 provider/formatter/兼容诊断状态走受控降级。
- [x] 6.5 审查所有 prompt：只允许解释程序事实，不得要求 AI 重排、重算、补局或静默覆盖本地裁决。

## 7. 最后注册与全仓收敛

- [x] 7.1 更新 `DivinationType` 全部 stable ID/display/fromId/count 测试与每个穷举 switch；运行 analyzer 消除遗漏。
- [x] 7.2 在 `main.dart` 注册 Provider/ViewModel，在 bootstrap 同时注册 system/UI factory，并仅在全部目标测试通过后设置 enabled。
- [x] 7.3 验证首页入口 -> 起局 -> 保存 -> 结果 -> 宫详情 -> 本地分析/应期 -> AI -> 历史重开 -> 导出导入 -> 清理完整流程。
- [x] 7.4 更新 `docs/architecture/divination-systems/qimen.md`、系统索引、统一接口文档和受影响 specs，确保字段和页面顺序与实现一致。
- [x] 7.5 运行代码生成、格式化、目标测试、静态分析和全量测试；失败时撤销启用而不是发布半闭环。
- [x] 7.6 派发 `trellis-check` 检查跨层数据流、穷举分支、响应式 UI、AI 边界、资源和回归，修复后重复完整质量门。
- [x] 7.7 按 finish workflow 更新 release notes/spec、提交并归档本子任务，再由父任务进行最终集成复核。

## Validation Commands

最终测试路径按实际交付调整，但不得用不存在的路径假装通过。

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format lib/divination_systems/qimen lib/ai/output/formatters/qimen_formatter.dart test/unit/divination_systems/qimen test/widget/qimen
flutter analyze
flutter test test/unit/domain/divination_system_test.dart
flutter test test/unit/divination_systems/qimen
flutter test test/unit/viewmodels/divination_system_viewmodels_test.dart
flutter test test/unit/data/repositories/qimen_repository_roundtrip_test.dart
flutter test test/unit/domain/services/data_management_service_test.dart
flutter test test/presentation/screens/settings/data_management_screen_test.dart
flutter test test/unit/ai/output/formatters/qimen_formatter_test.dart
flutter test test/widget/qimen
flutter test
python ./.trellis/scripts/task.py validate 07-28-qimen-product-integration
```

Audit searches：

```powershell
rg -n "DivinationType\\.|DivinationType.values" lib test
rg -n "score|rating|percent|percentage|weighted|标签数量|百分|星级|加权" lib/divination_systems/qimen lib/ai/output/formatters/qimen_formatter.dart
rg -n "Qimen(Time|Ju|Earth|Heaven|Duty|Door|Deity|Hidden|Marker).*Service" lib/divination_systems/qimen/ui lib/ai/output/formatters/qimen_formatter.dart
```

生产 UI/formatter 中命中排盘 service 或数值评分逻辑即为失败。

## Completion Evidence

- `dart run build_runner build --delete-conflicting-outputs`、格式检查、
  `flutter analyze` 与 `git diff --check` 均通过。
- 奇门产品套件 227 项、AI/数据管理套件 96 项、全量 `flutter test`
  1,185 项通过；最终 `trellis-check` 未留未修复问题。
- 独立验证工作树只装配本任务白名单，不含 `tmp/` 或并行大六壬改动；
  `flutter pub get`、代码生成、格式检查与静态分析通过。
- `DivinationType` 穷举逐项复核；评分术语与 Qimen UI/formatter
  排盘阶段 service 导入审计均为零命中。
- Android 模拟器已人工验收首页入口、自动/手动起局、保存、九宫结果、
  宫位详情、本地裁决/应期、AI 降级、历史重开和数据管理主闭环。
- 背景资源 `assets/images/screen_card/qimen_background.png` 可解码且非空白，
  SHA-256 为
  `610B2A284B27D79E85A3C239E1A0976302E6D5B5900EB0777943219C705D7C7D`；
  生成提示词、工具与模型记录在同目录 provenance 文档中。

## Post-Archive Correction（2026-07-28）

- 原计划 2.6 的 cast/save 分阶段卸载与 saving 期间第二次点击，及 4.4 的无唯一
  焦点和显式规则版本选择，未保留原任务完成时的精确测试证据；由
  `07-28-qimen-release-audit` 补齐。
- 18 个分析生产/测试路径在 `8138c6e` 中与产品集成混合提交，真实路径、最终
  fixture 哈希和 A1..A14 映射见
  `.trellis/tasks/archive/2026-07/07-28-qimen-release-audit/research/release-evidence.md`。
- 本修订只前向纠正文档证据，不 amend/rebase 历史，也不把 `a83647e` 伪装为
  可选择的已发布旧版本。

## Risk And Rollback

- 最大集成风险是新增 enum 后遗漏穷举分支，导致编译失败或历史/AI 运行时缺口；以全仓搜索、analyzer、生成代码和注册表测试共同拦截。
- 九宫信息密度高；以固定槽位、详情分层、多个宽度和 text scale 测试控制，不通过时不能靠缩小字体掩盖。
- 历史恢复依赖系统与 UI 同时注册；最终启用必须原子完成。失败时整体撤销注册/入口/Provider/AI/数据管理改动，保留上游纯领域模块。
- formatter 误重算会产生第二真相；通过依赖审查、projection policy 和 prompt 合同测试阻断。
- 本任务不含数据库 migration；若实现中出现 migration 需求，立即停止并回到设计评审。
