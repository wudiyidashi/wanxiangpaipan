# 大六壬月将与起课输入正确性

## Goal

修复会整体旋转盘面的月将交节错误，建立不依赖设备时区和操作时刻的历法输入合同，并让时间、报数、电脑、原始手工四柱和历法校验手工四柱都保存足量、诚实且可重放的输入与来源。

## Dependencies

- C00 证据目录已发布 `daliuren-classics/1.0.0`；本任务只消费已登记条目，不原地改写目录语义。
- C01 规则、盘面版本与重放快照契约已归档；本任务必须使用 `dlr.project.pan.*` 表达现代历法行为，并升级已发布的 pan/snapshot 版本。
- 本任务是 C03 天盘/四课不变量、C06 神煞、C07 三传派生事实及 C15 历史重排的硬前置。

## Background And Confirmed Facts

- `YueJiangService.getYueJiangByDateTime()` 先调用只按年月日命中的 `getCurrentQi()`，在中气日交节前提前换将；2022 谷雨边界为北京时间 `2022-04-20 10:24:18`。
- `lunar 1.7.8` 的 `Solar.fromDate()` 读取 `DateTime` 墙上字段，不保留任意 offset 的绝对时刻语义；直接删除 `getCurrentQi()` 仍不能保证跨时区一致。
- C00 的 `dlr.rule.pan.001.month-general-by-zhongqi` 与 `dlr.rule.pan.002.month-general-table` 为 B 级但 `executableApproved=false`。古籍可支持“随中气取将”和十二月将表的 attribution，不能证明秒级交节、UTC、固定 offset 或依赖库行为。
- 《大六壬指南》影印 PDF 6 核到十二中气/月将表和“月将加占时”；现代时间坐标必须单列为项目历法合同。
- 当前手工四柱自动月将错误地读取操作 `castTime`；ViewModel 默认选择手动月将却不提供月将；四柱只逐柱验证，未验证年月、日时干支联动。
- C01 已发布 `daliuren-pan/1.0.0` 和 snapshot `1.0.0`。修正后的新盘不得继续冒用这两个版本。

## Requirements

### R1 精确月将解析

- 把输入 `DateTime` 当作绝对时刻；先转 UTC，再转换成固定 UTC+08:00 的北京历书墙上坐标调用 `lunar 1.7.8`。
- 自动月将只取 `getPrevQi(false)` 返回的最近已发生中气，使用半开区间 `[termInstant, nextTermInstant)`；恰等于交节时刻立即启用新月将。
- 节不换将。清明、立夏等节的前、当、后一秒均保持其前一中气所定月将。
- 解析失败必须显式失败，不得退回月建或当前操作时间。

### R2 固定 offset 的民用四柱

- 新起课输入保存 `sourceUtcOffsetMinutes`；合法范围为 `[-840, 840]`。未显式提供时仅可从当前 `castTime` 的实际 offset 捕获一次，之后不得重新读取设备时区。
- 年/月柱与月建按同一绝对时刻的北京历书坐标及精确立春/节边界派生；日柱、时柱按来源 offset 的民用墙上时间派生，日柱采用项目固定的民用午夜换日口径，时柱以该日干和民用时支一致重算。
- 月将始终按同一绝对时刻的北京历书坐标解析，与来源 offset 无关。项目不声称支持 IANA 时区、历史 DST 或真太阳时。

### R3 有类型的解析与来源

- 月将服务返回 typed resolution，至少包含月将、中气名、中气绝对时刻、解析模式、calendar engine/version、项目算法版本和执行 rule ref。
- 自动解析执行身份使用稳定 `dlr.project.pan.*`；`pan.001`/`pan.002` 仅作为非执行古籍 attribution，不能设置 `executableApproved=true`。
- 手动月将也保存显式 override 的来源状态，不把手动值伪装成历法推导值。
- `DlrRuleRef` 提供 project-pan 专用构造入口，避免调用方误用默认 analysis 规则集版本。

### R4 两种手工四柱模式

- `rawPillars`：四柱逐柱合法，并校验年干到月干、日干到时干的联动；必须显式提供月将。该模式可重放但标记“未校历”，且排盘不得读取操作时刻派生月将或四柱。
- `calendarBacked`：必须提供 `manualCivilDateTime` 绝对时刻和 `sourceUtcOffsetMinutes`，由与自动起课相同的历法解析器派生四柱/月将；调用方提供的四柱必须逐项完全一致，否则拒绝。
- 缺少显式月将且也缺少完整民用时刻路径时，在产盘前拒绝，不再生成 `incomplete` 新盘。

### R5 四种起课入口

- 时间、报数和电脑起课共用同一时间上下文；报数/电脑只覆盖实际时支及由日干重算的时柱，不得改变月将边界。
- 修复 `DaLiuRenViewModel.castByManual()` 的无效默认组合，使公开便捷 API 无法在缺月将/民用时刻时组装非法命令。
- 屏幕现有“指定干支”路径继续使用 raw 模式并显式选择月将；本任务不新增真太阳时或时区数据库界面。

### R6 版本、快照与兼容

- 新行为发布新的 `daliuren-pan` 版本和 snapshot schema；新 snapshot 的绝对时刻统一 UTC 序列化，同时独立保存 source offset。
- 新结果 additive 保存权威 `DlrCivilTime(instantUtc, sourceUtcOffsetMinutes)`；顶层 legacy `castTime` 保持既有角色，结果页须以权威 civil time 还原民用显示并消费 typed resolution，不得继续从 legacy 字段重新计算农历/中气。
- 起课页时间预览、结果页和 DLR formatter/AI `coreData` 必须消费同一持久化 calendar facts。raw 手工盘的 `solarTerm` 为 unknown/null，不得借用操作时刻或 formatter 现场重算。
- snapshot 只保存重放输入白名单和实际解析值，不保存问题正文或派生整盘；calendar-backed 手工模式保存民用时刻与 offset，raw 模式保存显式月将和未校历状态。
- C01 `1.0.0`、旧 incomplete/manual JSON、无版本 JSON及未来版本均继续可读；C01 v1 无 zone 后缀时间必须结合快照中的 offset 确定性重建，不能依赖恢复机器时区；旧 pan 版本不得被静默视为 current。
- DLR Drift `resultData`、备份导入/导出对新旧 JSON 均保持往返；本任务不改变数据库 schema，也不扩大 malformed-record 处理策略。

### R7 分层与范围

- 传统月将表、现代历法契约和展示文案保持分离；测试或现有代码不得反证古法。
- 不顺手修改 C03 天盘 map、C04 天将坐标、C06 神煞或 C09 分析裁决。

## Acceptance Criteria

- [x] `2022-04-20 10:24:17 +08` 解析为春分/戌，`10:24:18` 与 `10:24:19` 解析为谷雨/酉。
- [x] 同一绝对时刻 `2022-04-20T02:24:18Z` 以 `+08:00`、UTC、`+05:30` 来源表示时，月将均为谷雨/酉。
- [x] 2022 全部十二中气均覆盖 `t-1s/t/t+1s`；旧将仅在 `t-1s`，新将在 `t` 生效。
- [x] 2022 清明 `03:20:14 +08` 前、当、后一秒均为春分/戌，证明节不换将。
- [x] 自动时间、报数、电脑路径在相同绝对时刻使用同一月将；resolver 失败无月建 fallback。
- [x] raw 手工四柱缺显式月将被拒绝；显式月将路径不随操作 `castTime` 改变，且年月/日时干支联动错误被拒绝。
- [x] calendar-backed 手工四柱与自动派生四柱完全一致时成功，任一柱、民用时刻或 offset 不一致时失败。
- [x] ViewModel 手工便捷 API 的类型/必填参数使默认调用不再产生无效 `manual + null month general` 组合。
- [x] typed resolution 区分项目执行规则与非执行古籍 attribution，并保存 `lunar/1.7.8` 和项目算法版本。
- [x] 新盘写新 pan/snapshot 版本，snapshot 时间为 UTC；source offset、手工模式及输入白名单 JSON round-trip 不丢失。
- [x] 新结果的 `DlrCivilTime.instantUtc` wire 为 UTC；顶层 legacy `castTime` 不被静默迁移，结果页按保存的 source offset 显示民用时刻并使用 typed resolution，不因设备时区变化重算出不同农历/月将。
- [x] 起课预览、结果页、人类可读 formatter 与 AI `coreData` 的四柱、民用时间、中气和月将来自同一结果 facts；raw 手工盘不出现操作时刻的 `solarTerm`。
- [x] C01 v1、legacy missing fields、future pan version 和旧 incomplete/manual snapshot 均可读取并得到正确 compatibility；v1 zone-less 时间在不同时区机器上恢复为同一 instant。
- [x] 当前/legacy DLR 结果通过 Drift 与备份导入/导出 round-trip，无数据库迁移。
- [x] build_runner 无漂移；大六壬定向、六爻共享回归、`flutter analyze` 与全量 `flutter test` 通过。

## Out Of Scope

- IANA 时区、历史夏令时、经度与真太阳时。
- C00 `pan.002` 说明文字的版本化勘误；不得原地修改已发布 `daliuren-classics/1.0.0`。
- 天盘双射/非法 map、贵人顺逆、神煞、九宗门、传统断课、UI 历史重排。
- 以 raw 四柱反推出唯一公历时刻；raw 模式只做可证明的干支联动校验并诚实标记未校历。
