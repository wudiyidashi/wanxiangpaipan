# 大六壬月将与起课输入正确性执行计划

- [x] 1. 阅读 C00/C01 契约、父任务 C02 范围、domain/跨层/复用规范和本任务研究记录。
- [x] 2. 先建立失败测试：2022 十二中气三点边界、清明不换将、同 instant 多 offset、resolver 无 fallback。
- [x] 3. 新增 `DlrCivilTime`/`DlrPillars`/manual mode/月将 typed resolution、`DlrRuleRef.projectPan()`、稳定 IDs、JSON 与 provenance 验证。
- [x] 4. 实现固定 offset 墙上坐标、北京中气 resolver 和民用四柱 resolver；冻结 midnight 日界与精确年/月边界。
- [x] 5. 升级 `daliuren-pan/2.0.0` 与 snapshot `2.0.0`，让新 civil-time/snapshot instant 使用 UTC wire；保持顶层 legacy `castTime` 角色，确定性恢复 C01 v1 zone-less 时间并保留 legacy/future 读取。
- [x] 6. 重构 `DaLiuRenSystem` 让 time/report/computer 共用 calendar context，并只在报数/电脑路径覆盖时支/时柱。
- [x] 7. 实现 raw/calendar-backed manual 两条互斥路径、年月/日时联动与 mismatch 错误；禁止操作时刻 fallback。
- [x] 8. 修复 ViewModel 手工便捷 API、起课预览、指定干支命令组装、结果页 source-wall 显示和 DLR formatter；所有消费者只读同一 calendar facts，raw UI 仍显式选月将。
- [x] 8.1 增加 DLR Drift 与备份 current/v1/legacy round-trip；不做数据库迁移或 malformed-policy 扩张。
- [x] 9. 运行 build_runner、格式化及定向测试，检查生成物和旧 JSON round-trip。
- [x] 10. 更新 `.trellis/spec/domain/daliuren-pan-engine.md` 与 `daliuren-rule-contract.md`，明确古籍 attribution 与项目历法边界。
- [x] 11. 使用 `readme-release-updater` 更新用户可见发布说明，且只纳入 C02 影响。
- [x] 12. 独立 `trellis-check` 复核证据声明、跨时区、手工输入、版本兼容、共享六爻和全量门禁；修复后重复检查。
- [ ] 13. 显式暂存 C02 文件，提交、归档和记录 journal；确认奇门及 `tmp/` 从未进入提交。

## Validation

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format lib/domain/services/daliuren lib/divination_systems/daliuren test/unit/services/daliuren test/unit/divination_systems/daliuren
flutter test test/unit/services/daliuren/yue_jiang_service_test.dart
flutter test test/unit/divination_systems/daliuren/daliuren_system_test.dart test/unit/divination_systems/daliuren/daliuren_result_versioning_test.dart test/unit/divination_systems/daliuren/dlr_rule_contract_test.dart
flutter test test/unit/data/repositories/daliuren_repository_roundtrip_test.dart test/unit/domain/services/daliuren_data_management_integration_test.dart
flutter test test/unit/services/daliuren test/unit/divination_systems/daliuren test/unit/ai/output/formatters/daliuren_formatter_test.dart test/widget/daliuren
flutter test test/unit/services/liuyao test/unit/services/shared
flutter analyze
flutter test
python ./.trellis/scripts/task.py validate 07-28-daliuren-cast-yuejiang
git diff --check -- <explicit C02 paths>
```

## Completion Evidence

- 2022 十二中气、清明不换将、同 instant 多 offset、民用午夜日界及 typed provenance 均有冻结 fixture 和直接回归，不从生产 resolver 反向生成预期。
- 独立 `trellis-check` 修复并锁定三项契约缺口：空白 pan 版本必须 mismatch、`projectPan()` 只接受 pan ID、typed 月将拒绝 analysis 规则集与伪造/manual 古籍 attribution；复核后 focused suite `57/57` 通过。
- 大六壬服务、系统、formatter 与 widget 广域回归 `179/179` 通过；六爻和共享服务 `261/261` 通过。新增独立复核测试随后由全量门禁覆盖。
- 最终 `flutter analyze` 无问题，最终全量 `flutter test` 为 `1194/1194`；过滤后的 build_runner 成功且产物无漂移，仅报告 SDK 3.10 / analyzer 3.9 的依赖版本提示。
- current、C01 v1 与 legacy 的 Drift/备份 round-trip 均通过；无数据库迁移。显式 C02 `git diff --check` 无 whitespace error，只有仓库既有 LF/CRLF 提示。

## Risk And Rollback

- 最高风险是 `DateTime` offset 丢失、北京墙上坐标被误当 UTC instant、v1 被误标 current 和手工路径偷读操作时间；四类风险均需独立测试后才进入系统编排。
- C01 v1 无 zone 时间的恢复和新 civil-time 结果页显示必须先有回归，避免修正权威时间后把既有盘显示成错误时刻。
- 不修改共享奇门时间服务，避免并行奇门产品集成和 DLR 形成所有权冲突。
- 若发现日界或精确四柱需要新的产品口径，不以现有测试为依据擅自变更；回到本任务设计并重新走评审门。
- 所有 Git 操作使用显式 C02 路径；并行奇门文件与 `tmp/` 永不暂存、格式化或回滚。
