# C02 月将与历法输入证据

## Evidence Separation

| 内容 | 依据 | 结论 |
|---|---|---|
| 月将随中气 | `dlr.rule.pan.001.month-general-by-zhongqi`，《大六壬指南》PDF 6 | B 级 attribution，`executableApproved=false` |
| 十二中气/月将表 | `dlr.rule.pan.002.month-general-table`，《大六壬指南》PDF 6 | B 级 attribution，`executableApproved=false` |
| 月将加时顺布天盘 | `dlr.rule.pan.003.heaven-plate-rotation` | B 级且已批准执行，但天盘不属于 C02 修改范围 |
| 秒级边界、UTC、offset | `lunar 1.7.8` API 与项目时间合同 | 现代项目规则，必须使用 `dlr.project.pan.*` |

《指南》影印页支持“雨水亥、春分戌、谷雨酉……冬至丑、大寒子”和“月将加占时”，不提供现代历法库、秒级交节、时区或 DST 定义。禁止把下面的工程时间合同表述为古籍原法。

## Confirmed Defect

`YueJiangService.getYueJiangByDateTime()` 先调用 `getCurrentQi()`。`lunar 1.7.8` 的该 API 只比较年月日，因此 `2022-04-20 09:00:00 +08` 会提前命中谷雨；实际谷雨为 `10:24:18 +08`，此前仍应使用春分/戌将。

`Solar.fromDate()` 只读取 `DateTime` 的年月日时分秒字段。Dart 对带任意 offset 的解析可归一到 UTC，故直接把 DateTime 传给依赖会把“绝对时刻”和“墙上坐标”混为一谈。

## Frozen Dependency Oracle

`lunar-1.7.8/test/JieQi_test.dart` 冻结了 2022 北京墙上时间，包括：

| 中气 | 北京墙上时刻 | 新月将 |
|---|---|---|
| 大寒 | 2022-01-20 10:39:06 | 子 |
| 雨水 | 2022-02-19 00:43:01 | 亥 |
| 春分 | 2022-03-20 23:33:26 | 戌 |
| 谷雨 | 2022-04-20 10:24:18 | 酉 |
| 小满 | 2022-05-21 09:22:36 | 申 |
| 夏至 | 2022-06-21 17:13:51 | 未 |
| 大暑 | 2022-07-23 04:07:00 | 午 |
| 处暑 | 2022-08-23 11:16:11 | 巳 |
| 秋分 | 2022-09-23 09:03:43 | 辰 |
| 霜降 | 2022-10-23 18:35:43 | 卯 |
| 小雪 | 2022-11-22 16:20:30 | 寅 |

依赖表的后一冬至通过 `DONG_ZHI` 键取得；实现测试应先把其明确时间写入 fixture，再做十二组 `t-1/t/t+1`，不能在断言内调用生产 resolver 生成预期。

清明为节而非中气：`2022-04-05 03:20:14 +08` 前、当、后都应保留春分/戌将。

## Implementable Contract

- 输入 DateTime 表示 absolute instant。
- 中气按固定北京 UTC+8 墙上坐标查询，Solar 节气字段再减 480 分钟还原 UTC。
- equality 激活新中气，区间为 `[termInstant, nextTermInstant)`。
- 来源 offset 仅用于民用四柱与显示；同一 instant 的月将与来源 offset 无关。
- raw 手工四柱必须显式月将并标记未校历；calendar-backed 手工四柱必须携带 instant/offset 并与统一 resolver 完全一致。
- 不支持 IANA zone、历史 DST、经度或真太阳时。

## Compatibility Notes

- C01 `daliuren-pan/1.0.0` 已发布；行为修正必须新版本。
- 新 civil-time/snapshot instant 使用 UTC wire；顶层 result `castTime` 保持 legacy 角色，旧 v1 与 incomplete manual JSON 继续读取。
- C01 v1 snapshot 对本地 `DateTime.toIso8601String()` 可能没有 zone 后缀，但同时保存了 `utcOffsetMinutes`。恢复时必须用词法墙上字段和该 offset 重建 instant，不能依赖当前机器时区。
- 结果页现有共享 extended-info 会用 `castTime` 重新计算农历/中气；UTC 化后必须改为来源墙上显示及 typed facts，否则会制造新的跨时区错盘展示。
- `DaLiuRenStructuredFormatter` 同样从 `result.castTime` 现场构造 Lunar；raw 手工盘会混入操作时刻 facts，C02 必须改为持久化四柱/中气/月将来源。
- C00 `pan.002` 解释中“尚未逐项回到影印页”与独立 PDF 6 复核结论存在措辞漂移；由于 catalog 版本不可原地改义，C02 只登记，不修改 `daliuren-classics/1.0.0`。

## Primary Repository References

- `assets/data/daliuren/classics/rules/pan.json`
- `.trellis/tasks/archive/2026-07/07-28-daliuren-classics-evidence/research/guide-foundation-cases-independent-review.md`
- `.trellis/tasks/archive/2026-07/07-28-daliuren-classics-evidence/research/core-source-locations.md`
- `.trellis/tasks/07-28-daliuren-classics-audit/research/core-pan-audit.md`
- `.trellis/tasks/07-28-daliuren-classics-audit/research/capability-matrix.md`
- `.trellis/spec/domain/daliuren-pan-engine.md`
- `.trellis/spec/domain/daliuren-rule-contract.md`
