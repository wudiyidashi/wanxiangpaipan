# 奇门遁甲排盘与历法引擎执行计划

- [x] 1. 阅读 domain index、跨层/复用指南、系统接口合同与父任务规则研究。
- [x] 2. 先新增来源化黄金 fixture 与常量/参数合同测试，锁定失败基线。
- [x] 3. 新增 `DivinationType.qiMen`、稳定 enum converters、参数与结果子模型，运行代码生成。
- [x] 4. 实现 `QimenTimeService`。
- [x] 4.1 覆盖当地/北京/真太阳时、NOAA v1 校正与 offset 保存。
- [x] 4.2 覆盖 Exact/Exact2 换日和午夜口径时干重算。
- [x] 4.3 覆盖精确交节前/当刻/后一秒。
- [x] 5. 实现公共局数表和四种 strategy（拆补、茅山、置闰、manual adapter）。
- [x] 5.1 先通过拆补全节气/三元表测试。
- [x] 5.2 再通过茅山 60 时辰边界测试。
- [x] 5.3 最后通过置闰前/闰中/二至后来源化黄金测试；失败不得回退。
- [x] 6. 按流水线逐个实现地盘、值符值使、天盘九星、八门、八神、寄宫、暗干和标记服务，每步提交目标测试证据。
- [x] 7. 实现 `QimenSystem` 两种输入校验、编排、summary 与严格 fromJson。
- [x] 8. 完成 JSON 深比较和内存仓储往返测试。
- [x] 9. 新增/更新 `docs/architecture/divination-systems/qimen.md`、系统索引、接口合同与 `.trellis/spec/domain/qimen-pan-engine.md`。
- [x] 10. 运行代码生成、格式化、目标测试、`flutter analyze` 和全量 `flutter test`。全量 909 项执行中唯一失败为并行大六壬资料库缺少 `rules/shensha.json`，奇门与共享目标无失败。
- [x] 11. 完成规则来源、架构、数据流、许可与回归独立审校；修复置闰、跨时区、值使中五、天禽寄随及黄金盘问题后重复质量门。
- [ ] 12. 更新 spec/发布说明，提交并归档本子任务，再启动分析子任务。

## Validation

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format lib/divination_systems/qimen lib/domain/services/qimen test/unit/services/qimen test/unit/divination_systems/qimen
flutter analyze
flutter test test/unit/services/qimen
flutter test test/unit/divination_systems/qimen
flutter test test/unit/data/repositories/qimen_repository_roundtrip_test.dart
flutter test
python ./.trellis/scripts/task.py validate 07-28-qimen-pan-engine
```

## Risk And Rollback

- 风险最高的是置闰、23 时换日和中五落宫；各自完成黄金门后才进入下一阶段。
- 若外部案例互相冲突，记录来源和逐项推演，修订本任务 design/spec 后再改测试，禁止为了通过某个软件快照临时分支。
- 本子任务不注册系统；整项提交可独立回滚而不影响用户入口。
