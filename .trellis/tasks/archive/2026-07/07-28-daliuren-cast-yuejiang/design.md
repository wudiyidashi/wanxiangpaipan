# 设计：大六壬月将与起课时间合同

## 1. Boundary And Data Flow

```text
DateTime instant + sourceUtcOffsetMinutes
  -> DLR civil wall coordinate -> typed calendar pillars
  -> Beijing UTC+8 wall coordinate -> lunar.getPrevQi(false)
  -> term Solar fields -> UTC instant -> month-general table
  -> typed month-general resolution + project rule provenance
  -> TianPan/System pipeline
  -> DaLiuRenResult + UTC replay snapshot
```

`lunar` 只接收人为构造的 UTC `DateTime` 作为“墙上坐标容器”，其 `isUtc` 不代表该墙上时间本身处于 UTC。所有从 `Solar` 返回的节气字段均按北京墙上时间解释，再减 480 分钟还原为绝对时刻。

## 2. Time Coordinates

设 `instantUtc = input.toUtc()`：

```text
wallAtOffset(instant, offset)
  = DateTime.utc(fieldsOf(instantUtc + offset minutes))

beijingWall = wallAtOffset(instantUtc, 480)
civilWall   = wallAtOffset(instantUtc, sourceUtcOffsetMinutes)
termInstant = DateTime.utc(fieldsOf(termSolar)) - 480 minutes
```

- 月将 resolver 只比较 `instantUtc` 与 `termInstant`，区间为 `[termInstant, nextTermInstant)`。
- `getPrevQi(false)` 的 `false` 必须显式书写；禁止 `getCurrentQi()`、whole-day 模式和月建 fallback。
- source offset 显式值优先；缺省仅在命令入口捕获一次 `castTime.timeZoneOffset.inMinutes`。范围 `[-840, 840]`。
- calendar-backed manual 必须显式提供 offset，不能借用设备当前 offset。
- 所有 wire instant 使用 `toUtc().toIso8601String()`；wall coordinate 不是绝对时刻，不作为独立 wire instant 保存。

## 3. Calendar Pillar Contract

新增 `DlrCivilTime`、`DlrPillars` 和大六壬专属 calendar resolver，避免改写共享 `LunarService` 或依赖奇门专属服务。`DlrCivilTime` 至少持久化 `instantUtc` 与 `sourceUtcOffsetMinutes`；fixed offset 与 manual mode 属于起课命令事实，不塞入混合规则/展示偏好的 `DaLiuRenPanParams`：

- 年柱：在 `beijingWall` 上调用 `getYearInGanZhiExact()`，以同一绝对时刻的精确立春边界切换。
- 月柱/月建：在 `beijingWall` 上调用 `getMonthInGanZhiExact()` / `getMonthZhiExact()`，以同一绝对时刻的精确节边界切换；不得把依赖的北京节气墙上时刻直接与其他 offset 的墙上字段比较。
- 日柱：项目固定民用午夜换日，使用 `civilWall` 的 `getDayInGanZhi()`。
- 时支：civil wall 对应双小时；时干从同一结果日干按五鼠遁重算，避免 23 时日干/时干口径分裂。
- `LunarInfo` 的所有四柱、月建、空亡和时柱从这一解析结果组装，自动、报数、电脑和 calendar-backed manual 不再各自调用不同的 `lunar` 路径。

以上为 `dlr.project.pan.*` 项目历法契约，不声称来自古籍。若未来引入子初换日、真太阳时或另一历法库，必须发布新 pan 版本。

## 4. Typed Resolution And Provenance

新增可 JSON round-trip 的 typed month-general resolution，字段至少包括：

```dart
enum DlrMonthGeneralResolutionMode { zhongQi, manualOverride }

class DlrMonthGeneralResolution {
  String yueJiang;
  DlrMonthGeneralResolutionMode mode;
  String? effectiveZhongQi;
  DateTime? effectiveZhongQiInstantUtc;
  String calendarEngineVersion;   // lunar/1.7.8
  String algorithmVersion;        // daliuren-yuejiang-fixed-beijing-v1
  DlrRuleRef executionRuleRef;    // dlr.project.pan.*
  List<String> classicAttributionRuleIds;
}
```

- 自动模式的 attribution 为 `pan.001`、`pan.002`，但执行 ref 必须是 project kind；不得把未批准 classic ref 当执行规则。
- 手动 override 没有中气名称/时刻，使用独立 project rule ID，并记录空 attribution 或明确的“用户输入”来源。
- 结果模型 additive 保存 resolution；旧 JSON 缺字段时为 `null`，不得伪造推导来源。
- `DlrRuleRef.projectPan()` 固定 project kind、D 级和 pan rule-set version；调用方不得用 `DlrRuleRef.project()` 的 analysis 默认版本构造盘面执行规则。

## 5. Manual Command Contract

### 5.1 Raw pillars

输入四柱 + `monthGeneralMode=manual` + `manualMonthGeneral`：

1. 四柱各自属于六十甲子。
2. 月干必须符合年干与月支的五虎遁关系。
3. 时干必须符合日干与时支的五鼠遁关系。
4. 不读取 `castTime` 派生四柱或月将。
5. snapshot 标记 `manualInputMode=rawPillars`、`calendarValidated=false`；因显式输入充分，replay status 为 complete。

raw 模式不尝试由四柱反推出唯一公历时刻，也不虚假声称已校历。

### 5.2 Calendar-backed pillars

输入四柱 + `monthGeneralMode=auto` + `manualCivilDateTime` + explicit offset：

1. `manualCivilDateTime` 解析为绝对时刻并标准化 UTC。
2. 用第 3 节同一 resolver 派生年/月/日/时柱与月将。
3. 四个调用方输入柱逐项全等才继续；错误需指出不一致字段。
4. snapshot 保存 civil instant、offset、四柱和 `manualInputMode=calendarBacked`。
5. 操作 `castTime` 只作为记录创建上下文，不参与盘面事实。

缺显式月将且缺完整 calendar-backed 条件时，`validateInput` 与 `cast` 都失败。两种路径不再产生新的 incomplete manual snapshot。

## 6. Other Cast Methods

- time：resolver 派生完整 calendar context。
- reportNumber/computer：复用 time context，只替换 `resolvedShiZhi`；`resolvedHourGanZhi` 从该日干重新计算。
- computer 的 seed/随机源仍按 C01 保持 incomplete，C02 不扩大为随机可复现任务。
- manual override 与自动 resolution 都传给天盘编排；`TianPanService` 的双射与非法输入强化留给 C03。

## 7. Version And Compatibility

- `DlrRuleSetVersions.panCurrent` 升为 `daliuren-pan/2.0.0`。
- 保留具名 `panV1` 常量，测试和兼容判断不得用临时字符串猜旧版本。
- `castInputSchema` 升为 `2.0.0`；capture 内统一把 `castTime` 存为 UTC。
- `DaLiuRenResult` additive 保存 `DlrCivilTime?`；其 `instantUtc` 统一 UTC wire。顶层 `castTime` 是跨系统/数据库既有字段，本任务不静默迁移或改义，也禁止把它继续作为新盘历法事实来源。
- v1 snapshot 仍按原 schema 反序列化，不要求迁移。若 v1 `castTime` 字符串没有 `Z`/offset 后缀，按其词法墙上字段减去 `utcOffsetMinutes` 重建 instant；禁止 `DateTime.parse()` 使用恢复机器本地时区。带显式 zone 的字符串按 zone 正常解析。
- v1 pan 与 v2 current 精确不等，compatibility 为 `versionMismatch`。
- 无 pan/version/snapshot 的旧 JSON 仍为 `legacyUnknown`；未来版本原样保留。
- 不修改 `daliuren-classics/1.0.0`。目录说明勘误须由独立证据版本发布处理。

## 8. Persistence And Display

- Drift 已把完整结果保存在 JSON `resultData`，C02 不做 schema migration；增加 current/v1/legacy 的 repository round-trip。
- 备份导入/导出同样以结果 JSON 为契约，验证 source offset、typed resolution 和旧字段不丢失。
- `DaLiuRenResultScreen` 从新 civil-time context（snapshot 仅作兼容后备）还原来源民用墙上显示；旧无 offset 记录维持 legacy/unknown 表示。
- 共享 `ExtendedInfoSection` 当前会从传入 `castTime` 重新计算农历和中气。DLR 结果页必须传入正确的 source wall coordinate 或改为消费持久化 facts；不得对 UTC wire 二次按设备本地时区推导。
- 起课页预览调用同一 DLR calendar resolver，不再直接 `Lunar.fromDate(_timeCastTime)`；预览与最终产盘必须逐项一致。
- `DaLiuRenStructuredFormatter` 不再 `Lunar.fromDate(result.castTime)`。四柱/月建/solar term 取持久化 `LunarInfo`，民用时刻取 `DlrCivilTime`，月将及中气 provenance 取 typed resolution；raw 手工盘输出 unknown/null solar term。
- malformed DLR record 被 repository 略过的既有策略不在 C02 改动，留给 C15 历史盘任务。

## 9. Test Design

- `yue_jiang_service_test.dart`：2022 十二中气 `t-1/t/t+1`、清明节边界、同 instant 三 offset、非法/失败无 fallback、typed provenance。
- calendar resolver tests：精确立春/节边界、午夜换日、offset 墙上时间、日干/时干一致性。
- `daliuren_system_test.dart`：四种入口共享月将；raw/calendar-backed 成功与错误矩阵；ViewModel 命令合同；snapshot 白名单。
- result/version tests：v2 round-trip、UTC wire、C01 v1 complete/incomplete、legacy/future compatibility。
- UI/widget tests：同一 civil-time context 在不同 device zone 假设下仍显示保存的来源民用时间和持久化月将信息；legacy `castTime` 不参与新 facts 重算。
- formatter tests：raw/calendar-backed/automatic 三种模式均只输出持久化 facts，改变 legacy `castTime` 不改变四柱、中气和月将结构化值。
- repository/backup tests：current/v1/legacy JSON round-trip，无数据库迁移。
- 测试预期来自 `lunar 1.7.8` 自带 `JieQi_test.dart` 的冻结时间表和 C00 影印页月将表，不从生产 resolver 反向生成。

## 10. Rollback

- 产品代码、模型、生成物、测试和版本常量作为一个 C02 提交回滚。
- 回滚不得把已经写出的 v2 结果误判为 v1 current；旧客户端可忽略 additive resolution 字段。
- 若依赖库边界与冻结 fixture 不符，停止发布并显式失败；不得恢复 whole-day fallback。
