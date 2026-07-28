# 大六壬天盘与四课服务契约执行计划

- [ ] 1. 读取父任务边界、C00 独立复核、C01/C02 版本合同、domain 规范和本任务 research/design。
- [ ] 2. 先新增失败测试：非法月将/时支、空/部分/非法键值/重复值/乱序 map、元数据锚点、原 map 后续突变、模型查询回退、伪伏吟/反吟和缺失乘神解析。
- [ ] 3. 实现可复用的天盘十二支固定循环位移校验并返回防御性只读副本；让排列、正反向查询、模型读取和 JSON 路径拒绝非法状态。
- [ ] 4. 将 `SiKeService` 改为合法六十甲子、严格 map 读取和必填 `ChengShenResolver`，解析不到时失败；增加既有 `SiKe` 的课序/链路/克向一致性验证，修正模型注释。
- [ ] 5. 在 `SanChuanService` 入口接入同一 map 与 `SiKe` 一致性校验并移除天盘链同支 fallback；不改九宗门算法和三传乘神坐标。
- [ ] 6. 迁移 `DaLiuRenSystem` 及五个测试调用方，显式提供乘神解析策略；用 `rg` 确认无遗漏。
- [ ] 7. 新增 12x12 固定顺布矩阵、完整伏反吟、`SiKe` 反篡改、五行关系及三张《大六壬指南》独立 fixture 的服务级测试；保持 13 个内部三传盘期望不变。
- [ ] 8. 新增 `panV2` 并发布 `daliuren-pan/3.0.0`；保持 snapshot v2 和 evidence catalog v1，补 v3/current、v2 mismatch、legacy/future 兼容测试。
- [ ] 9. 运行 build_runner、格式化、classic validator、定向与广域回归；确认模型 JSON 结构和生成物无漂移。
- [ ] 10. 更新 `.trellis/spec/domain/daliuren-pan-engine.md` 与 `daliuren-rule-contract.md`，记录双射、严格失败、resolver 和 pan v3 合同。
- [ ] 11. 使用 `readme-release-updater` 判断并记录用户可见的 C03 发布说明，只纳入大六壬影响。
- [ ] 12. 独立 `trellis-check` 复核古籍声明、map 不变量、C04/C05 边界、版本兼容、跨层调用和全量质量门禁；发现问题后修复并重复验证。
- [ ] 13. 只暂存 C03 明确文件，提交、归档并记录 journal；确认并行奇门目录及 `tmp/` 从未进入格式化、暂存或提交。

## Validation

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format lib/domain/services/daliuren lib/divination_systems/daliuren test/unit/services/daliuren test/unit/divination_systems/daliuren test/unit/ai/output/formatters/daliuren_formatter_test.dart test/widget/daliuren
flutter test test/unit/services/daliuren/tianpan_service_test.dart test/unit/services/daliuren/si_ke_service_test.dart test/unit/services/daliuren/san_chuan_service_test.dart
flutter test test/tool/daliuren_classics/validator_test.dart
flutter test test/unit/divination_systems/daliuren/dlr_rule_contract_test.dart test/unit/divination_systems/daliuren/daliuren_result_versioning_test.dart test/unit/divination_systems/daliuren/daliuren_system_test.dart
flutter test test/unit/services/daliuren test/unit/divination_systems/daliuren test/unit/ai/output/formatters/daliuren_formatter_test.dart test/widget/daliuren
flutter test test/unit/services/liuyao test/unit/services/shared
flutter analyze
flutter test
python ./.trellis/scripts/task.py validate 07-28-daliuren-pan-sike-contracts
git diff --check -- <explicit C03 paths>
```

## Review Gates

- 三张经典 fixture 的 expected facts 必须来自已批准独立手排记录，测试不得调用生产公式生成预期。
- `pan.004` 继续为 C/pending；C03 结果和文档不得声称寄宫已获 A/B 古籍批准。
- 任一空值分支若仍能产出同支、贵人、伏吟或反吟，视为阻断缺陷。
- 任意乱序双射、月将未加临时支或与 map 不一致的 `SiKe` 若能进入三传，同样视为阻断缺陷。
- 任何 C04 神将坐标或 C05 九宗门行为变化都必须移回对应子任务，不在 C03 顺手实现。
- v3 只改变 pan rule-set identity；snapshot/evidence/JSON schema 若出现变化，必须回到规划重新评审。

## Rollback Points

- 先提交/验证结构合同与失败测试，再迁移 resolver 和版本，便于定位 API 兼容问题。
- C03 最终作为一个产品提交回滚；不得单独回退版本常量却保留 v3 行为。
- 若历史 fixture 暴露 malformed map，只记录具体样本并交 C15 决定历史重排，不以恢复静默 fallback 兼容。
