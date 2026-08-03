# 实施计划：六爻真实案例阶段裁决与提示词校准

## Phase 0：冻结基线、来源与安全门禁

- [x] 0.1 读取 domain/frontend spec、上一任务冻结身份和 v1.6.0 生产装配；确认工作树只含本任务规划文件。
- [x] 0.2 用 `2026-02-28 08:00`、爻数 `[8,8,6,7,8,6]` 冻结 unselected 与 selected-main-1 两份 v1.6.0 baseline request；generation 输入不含 outcome 或用户事后映射。
- [x] 0.3 运行 main-1/main-6/hidden-1 探针，冻结 current v2 的事实、作用、冲突、裁决和请求 hash。
- [x] 0.4 核验本地《增删卜易》中回头克/动变先后、六合、飞伏的可用页级证据；六神和卦名未找到可靠本地页证时固定为 D 级项目约定，不扩大引文权限。
- [x] 0.5 验证 `eval.local.json` ready、`key.txt`/local config/.tmp 均 ignored；只记录配置状态和非敏感模型元数据，不输出值。
- [x] 0.6 产品修改前完成两个场景各三次 baseline generation，工件只写 ignored local directory，并运行敏感扫描。

## Phase 1：历史卦日历来源

- [x] 1.1 给 `LiuYaoResult` 增加 additive calendar input mode 和旧 JSON 默认值，生成 Freezed/JSON 代码并补序列化回归。
- [x] 1.2 扩展卦名卦阳历 callback，将 `_solarTime` 传给父页/System；干支模式保留记录时间并写正确来源。
- [x] 1.3 `providedSolar` 校验 castTime/四柱；结果页编辑写 `userOverride`；projection/formatter 输出权威来源和一致性。
- [x] 1.4 增加 widget/system/controller 测试，锁定 2 月 28 日案例和旧 7 月错配不再发生。

## Phase 2：Rule-Set v3 与阶段作用

- [x] 2.1 新增 v3/current resolver、analysis schema 2 和 catalog version；先固定 v1/v2 字节与行为兼容测试。
- [x] 2.2 为 actor availability blocker 声明适用 phase；给 directed effect 增加 formation/early/later/final horizon，并保持 trace/source/occurrence 闭包。
- [x] 2.3 v3 中让本卦动爻前段作用与回头克/化退/化绝后段受制并存；锁定本案例卯木前段克世、后段受申回头克。
- [x] 2.4 加真正当下无效、前段有效后段受制、前后均有效等非本案例正反例；不得以 case ID、卦名或问题字符串分支。
- [x] 2.5 条件增加 dimension/scope；伏神父母的无释放路径只影响合同权属/持续性，不直接决定交易 formation。
- [x] 2.6 运行 40 例 validator/goldens，语义变化先更新共享 fixture 与来源说明；v2 compatibility 全绿。

## Phase 3：全爻投影与生命周期裁决

- [x] 3.1 projection schema 2 输出 calendar authority、完整 actorFacts、useSpiritOccurrences、世应关系、phase effects、权限和证据等级。
- [x] 3.2 分别评估初爻妻财与上爻另一现，保留上财旬空+假空、回头生+化绝、合绊+冲开的并存事实；不把另一现压成单条扶助。
- [x] 3.3 新增纯函数 question focus，覆盖租房的费用、合同权属、竞争/利益分流、争议、世应角色，不自动选择或持久化用神。
- [x] 3.4 新增六爻专属 lifecycle decision table，输出 formation/quality/continuity/persistence、稳定 row ID 和每维 evidence IDs。
- [x] 3.5 锁定本案例 selected-main-1 为 `willForm/adverse/unstable/entangled`，headline 为“事必成，成而受困；合非吉兆，是套”或固定等价文案。
- [x] 3.6 v3 六合/卦变六合改为 context-dependent 的黏合/牵绊/持续语义，scope 仅 formation/persistence；六神和卦名进入低权限 interpretive evidence。
- [x] 3.7 补 unselected、main-1/main-6/hidden-1、双六合有利/不利、世应、两现、假空及旧 schema/snapshot 回归。

## Phase 4：生产提示词与本地评测器

- [x] 4.1 升 immutable prompt policy 1.1，修改真实 system/comprehensive/brief 模板；自定义模板仍无法移除 guard/canonical projection。
- [x] 4.2 prompt 输出固定先 formation、再 quality/continuity/persistence，并要求每个判断引用 program evidence；禁止把签约等同全程顺利。
- [x] 4.3 加 real-world calibration fixture/adapter，严格隔离 generation input 与 outcome/user-retrospective reference。
- [x] 4.4 支持批准的 baseline/candidate schema 差异，同时锁定原始盘面、时间、问题、选择用神和请求参数身份。
- [x] 4.5 将 90 秒固定 timeout 改为有界本地配置并纳入 manifest；收紧 judge exact JSON contract 和 attempt 重试目录。
- [x] 4.6 为 abstain、四阶段保真、前后作用、全爻证据、六合 scope、假空、来源/应期幻觉增加 hard gates 和 evaluator 单测。

## Phase 5：真实模型调参与验证

- [x] 5.1 生成新的 candidate/run ID；unselected 与 selected-main-1 各运行至少三次 paired evaluation，失败只新增 attempt，不覆盖。
- [x] 5.2 回跑 golden.001/.007/.037 等既有 calibration 代表样本，检查 verdict/conditions/timing/source hard gates 无回退。
- [x] 5.3 若候选失败，只按盘面证据和 rubric 修改生产 prompt/投影并升 candidate ID；不得把 outcome、用户事后映射或 holdout 注入 generation。
- [x] 5.4 输出脱敏本地报告：逐次输出、四阶段、硬门禁、盲评、延迟/token、hash 和限制；敏感扫描零命中。

## Phase 6：质量、文档与小版本

- [x] 6.1 更新 domain/frontend spec、六爻架构文档、README 最新更新和日期发布说明，记录阶段动变、六合 scope、生命周期裁决及证据等级。
- [x] 6.2 运行定向测试、共享术数回归、`flutter analyze`、全量 `flutter test`、format、task validate、secret/diff/database gates。
- [x] 6.3 按“日历修复 -> v3/阶段裁决/投影 -> prompt/evaluator -> release”分批提交和推送；每次 Git 写入前执行 release-note skill 与敏感扫描。
- [x] 6.4 更新 `pubspec.yaml` 为 `1.6.1+2`，生成发布提交并 tag `v1.6.1`；验证 tag/remote 指向最终通过提交。

## Validation Commands

```powershell
python ./.trellis/scripts/task.py validate .trellis/tasks/08-02-liuyao-real-case-prompt-calibration
dart run .trellis/tasks/08-02-liuyao-real-case-prompt-calibration/research/actual_case_time_probe.dart
dart run .trellis/tasks/08-02-liuyao-real-case-prompt-calibration/research/actual_case_projection_probe.dart
dart run tool/liuyao_classics/validate.dart
dart analyze tool/liuyao_classics
dart analyze tool/liuyao_ai_eval
flutter test test/unit/services/lunar_service_test.dart test/unit/divination_systems/liuyao/liuyao_guaname_cast_test.dart test/unit/divination_systems/liuyao/liuyao_analysis_controller_test.dart
flutter test test/unit/services/liuyao/analysis
flutter test test/unit/ai/output/formatters/liuyao_formatter_test.dart test/unit/ai/service/prompt_assembler_test.dart test/unit/ai/template/builtin_templates_test.dart test/unit/ai/service/ai_conversation_service_test.dart
flutter test test/tool/liuyao_ai_eval
flutter test test/unit/services/shared test/unit/services/daliuren/analysis test/unit/services/qimen/analysis
flutter analyze
flutter test
git check-ignore -q key.txt
git check-ignore -q tool/liuyao_ai_eval/eval.local.json
git diff --check
```

## Risky Files And Gates

- `liuyao_result.dart` 与生成文件：只允许 additive default，不做数据库 migration。
- `actor_availability_service.dart` / `sheng_ke_service.dart`：v3 才启用阶段语义，v2 compatibility 和非本案例正反例必须先通过。
- `verdict_service.dart` 与 lifecycle service：共享四值不改义；生命周期使用六爻专属稳定 decision rows，每维必须回链 evidence IDs。
- `liuyao_catalog.dart` / `gua_change_service.dart`：六合是 scoped evidence，不是固定吉，也不能被完全删除；source grade 和 v2 冻结必须通过。
- `liuyao_analysis_projection.dart`：schema 2 exact keys、全爻 facts、两现、policy/source/occurrence closure 失败关闭。
- `builtin_templates.dart` / `prompt_assembler.dart`：真实 assembler、brief/custom/snapshot 全路径测试，不以未使用模板或字符串断言代替。
- evaluator：联网显式 opt-in；凭据不得作为 CLI 参数或 artifact 字段；outcome/reference 必须与 generation adapter 物理隔离。
