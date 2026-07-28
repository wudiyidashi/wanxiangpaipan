# 奇门遁甲界面与应用集成设计

## 1. 边界与依赖冻结

本子任务只负责产品装配。启动时读取并固定排盘、分析两个已归档子任务的提交和最终 spec；UI 不允许导入奇门时间、定局、地盘、天盘或事实 evaluator 来补算数据。

```text
Home/History
  -> DivinationUIRegistry
  -> QimenCastScreen
  -> QimenViewModel
  -> QimenSystem.cast (frozen pan contract)
  -> saveRecord (generic repository + encrypted question)
  -> QimenResultScreen
       -> QimenAnalyzer.analyze(result)
       -> QimenAnalysisProjection
       -> local UI / QimenStructuredFormatter -> AI
```

历史链路由 `systemType=qimen -> DivinationType.fromId -> registered QimenSystem.resultFromJson -> registered QimenUIFactory` 恢复。注册和 `isEnabled=true` 是最后一步，不是开发第一步。

## 2. 文件与所有权

新增或扩展：

```text
lib/divination_systems/qimen/
  viewmodels/qimen_viewmodel.dart
  ui/qimen_ui_factory.dart
  ui/qimen_cast_screen.dart
  ui/qimen_cast_sections.dart
  ui/qimen_result_screen.dart
  ui/qimen_result_sections.dart
  ui/widgets/qimen_nine_palace_grid.dart
  ui/widgets/qimen_palace_detail_sheet.dart
  ui/widgets/qimen_verdict_card.dart
  ui/widgets/qimen_fact_sections.dart

lib/ai/output/formatters/qimen_formatter.dart
assets/images/screen_card/qimen_background.png
```

允许按现有目录习惯合并很小的 widget 文件，但起局状态、九宫布局、宫位详情、分析展示和 formatter 不应塞进一个巨型页面。系统级算法文件只读。

必改集成点包括：

- `lib/divination_systems/registry_bootstrap.dart`：系统与 UI factory 同时注册。
- `lib/main.dart`：提供 `QimenSystem` 与依赖仓储的 `QimenViewModel`。
- `lib/presentation/widgets/divination_system_card.dart`、`history_record_card.dart`、`home_screen.dart`：名称、背景和颜色穷举。
- `lib/core/theme/app_colors.dart`：奇门系统色与必要语义 token。
- `lib/domain/services/data_management_service.dart` 及设置数据管理 UI：计数和清理。
- `lib/ai/ai_bootstrap.dart`、模板目录、`prompt_assembler.dart`、AI chat/settings 标签和会话生成模型。
- 系统/接口文档、索引、测试和生成文件。

实现前以 `rg "DivinationType\\." lib test` 生成最终清单；上面列举不是替代全仓搜索。

## 3. 注册、Provider 与发布门

- `QimenSystem.supportedMethods == [CastMethod.time, CastMethod.manual]`，首页默认选择 `time`。
- `QimenUIFactory` 严格检查传入结果为 `QimenResult`，构建起局页、结果页和通用历史卡片，并返回统一图标/颜色。
- Provider 对齐现有模式：`Provider<QimenSystem>` 加 `ChangeNotifierProxyProvider2<QimenSystem, DivinationRepository, QimenViewModel>`；ViewModel 重建时保留可安全保留的 UI 状态，不保留过期结果。
- bootstrap 测试先验证注册一致性，再把 `QimenSystem.isEnabled` 打开。任何 formatter、反序列化或 UI factory 缺失都使发布门失败。

## 4. ViewModel 与起局数据流

`QimenViewModel` 继承/复用通用 `DivinationViewModel<QimenResult>` 模式，暴露两个明确入口：

- `castByTime({required DateTime castTime, required QimenPanParams params})`
- `castByManual({required manual pillars/solar term/ju fields, required QimenPanParams params})`

页面负责输入状态和可读校验提示，ViewModel 负责构造冻结 payload、调用系统、公开 loading/error/result 并通过通用保存能力写仓储。系统层重复执行合同级校验，不能信任 UI。

提交状态机：

```text
idle -> validating -> casting -> saving -> navigating
           |            |          |
           +---------- error <-----+
```

只有 saving 完成后才取 `viewModel.result`，并调用 `DivinationUIRegistry().buildResultScreen(result)` 导航。所有 await 后检查 `mounted`；提交期间禁用主按钮。

## 5. 起局页交互

页面使用现有 `AntiqueScaffold` 和 cast form primitives，不另建表单设计系统。

- 顶部：占问输入、问事类型、`time/manual` 方式选择。
- 自动主区：日期、时间、“现在”命令、定局法和时间基准。
- 条件字段：`trueSolar` 才显示经度；其他模式清除提交 payload 中的 longitude，而不是保留隐藏脏值。
- 高级区：换日、寄宫、暗干。折叠标题同时显示当前口径摘要。
- 手动主区：四柱使用合法六十甲子选择器或成对干支控件但最终做六十甲子校验；节气、遁、局数、三元均显式输入。
- 最近方式只恢复仍在 `supportedMethods` 内的值；不自动提交旧输入。

错误定位到具体控件并保持用户输入。手动方式不使用 `Lunar.fromDate(now)` 的值作为静默业务默认；可以预填“当前历法建议值”，但必须标识为当前可编辑选择并随 payload 显式提交。

## 6. 结果页与九宫布局

`QimenResultScreen` 在一次 build 数据准备中读取结果并派生 report；昂贵的规范化可抽成基于 result ID/rule version 的不可变 memo，但不得写库或形成第二真相。

Section 顺序固定：

1. 时间、四柱、节气和时间校正摘要。
2. 定局、阴阳遁、局数、三元、旬首、值符值使和分歧口径。
3. `QimenNinePalaceGrid`。
4. 全局专业标记和值符值使关系。
5. `QimenVerdictCard`。
6. 焦点、宫位事实、格局、冲突与来源。
7. 应期候选。
8. 通用 AI 区域。

九宫 grid 接收已经按宫号建立的不可变 map，并由组件内部按 `[4,9,2,3,5,7,8,1,6]` 取值，禁止依赖输入 list 顺序。外层使用 `LayoutBuilder` 确定可用宽度、固定 3 列和稳定纵横约束；宫格内部为固定信息槽：宫标题、天地盘干、星/门/神、状态标记。长标签 wrap 或省略并在详情完整展示，hover/press/loading 不改变轨道尺寸。

中五宫保留原始干和天禽；寄宫目标以单独 hosted 槽显示。点击宫格通过 `showModalBottomSheet` 打开 `QimenPalaceDetailSheet`，按盘面事实、寄宫事实、标记、命中规则/来源分组。详情使用单层 section，不嵌套装饰卡片。

## 7. 分析、兼容与应期展示

`QimenVerdictCard` 显示四值趋势、裁决行和摘要；条件与因素按推理顺序展示，冲突记录标明胜出/压制规则。事实默认按 focus 和宫位分组，完整 trace/source 展开查看。

- UI 只接收 report/projection，不解析 reason 文本判断颜色或逻辑。
- polarity/trend 映射到现有语义颜色，同时附文字/图标。
- `unsupportedPanSchema` / `invalidPanFacts` 使用诊断区块，显示稳定错误和支持版本；九宫盘仍从已成功恢复的 result 展示。
- 应期适配 Qimen 特有的干、支、节气和条件解除触发；条目显示尺度、触发值、理由和“不保证发生”。不强行塞入只支持地支的共享组件。

## 8. 历史与数据管理

- 保存沿用通用记录表，外层 `systemType.id=qimen`、`castMethod.id=time/manual`，内层 result JSON 已由排盘任务冻结。
- `resultFromJson` 是唯一历史解码入口；历史 UI 不自行构造模型。
- 通用历史卡片使用 `getSummary()`，点击通过 registry 构建详情。仓储往返测试覆盖 question secure reference、完整九宫深比较和分析重新派生。
- 数据统计模型新增 `qimenCount` 或按最终现有合同的等价字段，所有总量、分项清理对话框和测试 fake 同步更新。
- 导入先通过稳定 ID 分发；单条错误按现有导入报告合同隔离，不能让其他合法系统记录丢失。

## 9. AI 合同

`QimenStructuredFormatter` 类型检查 `QimenResult`，获取分析子任务的 `QimenAnalysisProjection`，输出稳定 sections/coreData：

- `calculationBasis`：时间、定局、换日、寄宫、暗干、schema/rule version。
- `palaces`：九宫全部结构化事实，主/寄宫字段分开。
- `focusAndFacts`：焦点、命中与被压制事实、来源。
- `verdict`：命中行、四值趋势、条件和证据链。
- `timing`：结构化触发与观察窗口声明。
- `policy`：`calculationOwner=program`、`mayRecalculatePan=false`、`mayOverrideVerdict=false`。

prompt 只要求解释、组织和结合用户问题，不要求重排或补算。系统、综合、简要三类模板使用 formatter 字段；缺失 formatter/provider 时通用页面保持本地内容并给出受控 unavailable 状态。新增 enum 后更新 AI 会话 JSON 生成文件并做旧会话反序列化回归。

## 10. 视觉资源、响应式与可访问性

- 资源使用项目内 PNG 位图；生成时保留提示词/工具/日期或外部来源与许可记录。内容以真实洛书/罗盘/术数纸面元素为主，不用文字密集海报，确保卡片裁切后仍可识别。
- 奇门主色与现有四系统区分，并搭配项目已有中性色和吉凶语义色，避免整个页面只使用一个色相。
- 测试 320、390、600 logical px 及至少一个宽屏，覆盖 textScale 放大、长标签、九宫全部状态、键盘/屏幕阅读语义和弹层滚动。
- 图标优先使用项目已有 Material/Lucide 能力；陌生纯图标按钮提供 tooltip/semantics。

## 11. 测试矩阵

- Domain integration：enum stable ID/display/fromId、system/UI registry、bootstrap enabled-set 一致。
- ViewModel：两种方式 payload、错误、保存、加密占问与重复提交。
- Cast widgets：条件字段、全部枚举选项、非法输入、恢复最近方式、cast-save-navigate。
- Result widgets：洛书顺序、九宫完整字段、宫详情、诊断状态、事实/冲突/来源、应期、窄屏/大字体无 overflow。
- Persistence：真实 JSON wire、内存 Drift 保存/查询/筛选/最近/重开、导入导出、按系统清理隔离。
- AI：formatter section/coreData、三模板、prompt policy、bootstrap、旧/新会话 JSON 和无配置降级。
- Assets/theme：资源存在、可解码且非空白，卡片在目标尺寸可渲染；所有系统色 switch 穷举。
- Regression：现有术数注册、首页、历史、设置、AI、数据管理和全量测试。

## 12. 发布与回滚

先实现未注册的 UI/ViewModel/formatter 和目标测试，再接数据管理与全仓 enum 分支，最后同一变更中注册并启用。发布前搜索所有 `DivinationType`、`CastMethod` 和 system-count 假设。

若最终门失败，回滚注册、Provider、入口、AI 和数据管理集成，使 `qimen` 保持不可见；上游纯领域模块和已保存的稳定 JSON 不需要数据库回滚。不得只隐藏首页卡片却保留无法恢复的半注册状态。
