# 奇门遁甲完整产品集成影响图

## 运行链路

```text
首页注册表
  -> QimenUIFactory.buildCastScreen
  -> QimenCastScreen / QimenViewModel
  -> QimenSystem.cast
  -> 时间上下文 -> 定局 -> 九宫排盘 -> QimenResult
  -> DivinationRepository.saveRecord
  -> Drift 通用记录 + SecureStorage 占问
  -> QimenResultScreen
  -> QimenAnalyzer 运行时派生
  -> QimenStructuredFormatter -> AI

历史页
  -> systemType=qimen
  -> DivinationType.fromId
  -> QimenSystem.resultFromJson
  -> QimenUIFactory.buildHistoryCard/buildResultScreen
```

## 现有契约

- `DivinationSystem` 要求元数据、启用状态、支持方式、输入校验、排盘与结果反序列化。
- `DivinationResult` 要求稳定 ID、时间、系统、方式、农历上下文、可逆 JSON 与一行摘要。
- `DivinationUIFactory` 负责起局页、结果页、历史卡片、图标与颜色。
- 通用 Drift 表通过 `systemType.id`、`castMethod.id` 与 `resultData` 保存新系统，无需数据库 schema migration。
- 读取历史时通过已注册系统的 `resultFromJson` 分发；未注册或反序列化失败的记录会被忽略，因此发布时系统、UI 与序列化必须同时就绪。
- `DivinationResultPage` 默认包含 AI 组件；奇门必须实现并注册 formatter，不能留下可点击但无 formatter 的运行时错误。

## 必建模块

- `lib/divination_systems/qimen/`
  - `qimen_system.dart`
  - `models/`：参数、时间上下文、定局、宫位、结果及稳定 ID 枚举
  - `viewmodels/qimen_viewmodel.dart`
  - `ui/`：factory、cast/result screens、九宫盘与详情/分析组件
- `lib/domain/services/qimen/`
  - 时间归一化、三种定局策略、地盘、值符值使、天盘九星、八门、八神、暗干、空亡驿马与标记
  - `analysis/`：事实标签、格局、裁决、应期与统一 analyzer
- `lib/ai/output/formatters/qimen_formatter.dart`
- `docs/architecture/divination-systems/qimen.md`
- `.trellis/spec/domain/qimen-pan-engine.md` 与 `qimen-analysis-engine.md`
- `assets/images/screen_card/qimen_background.png`

## 必改集成点

- `lib/domain/divination_system.dart`：新增稳定 `DivinationType.qiMen('奇门遁甲', 'qimen')`；复用 `CastMethod.time/manual`。
- `lib/divination_systems/registry_bootstrap.dart`：系统与 UI factory 同时注册。
- `lib/main.dart`：提供 `QimenSystem` 与 `QimenViewModel`。
- `lib/core/theme/app_colors.dart`：独立奇门系统色。
- `lib/presentation/widgets/divination_system_card.dart`：背景、名称、副标题与颜色穷举分支。
- `lib/presentation/screens/home/home_screen.dart`：最近记录系统名称分支。
- `lib/presentation/widgets/history_record_card.dart`：颜色、背景与摘要。
- `lib/domain/services/data_management_service.dart` 及设置界面：计数与按系统清理。
- `lib/presentation/widgets/ai_chat_sheet.dart`、提示词设置与相关穷举分支：奇门标签。
- `lib/ai/ai_bootstrap.dart`、`builtin_templates.dart`、`prompt_assembler.dart`：formatter 与模板注册。

## 设计约束

- `DivinationType` 新值会触发多个穷举 switch，必须用全仓 `rg "DivinationType\\."` 清点并由 analyzer 验证。
- 历史持久化必须使用 `qimen` 和现有 method ID，禁止 enum `name`。
- 排盘事实完整持久化；本地分析报告运行时重算、不落库。
- Qimen 未完成 UI、formatter、历史与数据管理接入前不得 `isEnabled=true` 或注册到发布入口。
- 首页网格由 registry 驱动；新增第五个系统后要验证 3 列布局在窄屏和大字体下不溢出。
- 九宫盘采用稳定 3x3 洛书布局与固定纵横比；单宫只显示可扫描摘要，点击打开完整详情，动态标签不得改变格子尺寸。

## 验证面

- enum ID/display/fromId 与注册表。
- 两种输入 payload 的合法/非法矩阵、显式 `castTime`、所有参数 ID。
- 排盘阶段服务、来源化黄金盘、完整 JSON 往返、仓储往返。
- analyzer 每条事实规则与决策表逐行命中。
- ViewModel 起局/保存/加密占问。
- 起局页、结果页、九宫窄屏无溢出、单宫详情、历史重开、数据管理计数/清理。
- formatter、内置模板、prompt assembler 与无 AI 配置降级。
- `dart run build_runner build --delete-conflicting-outputs`、`flutter analyze`、目标测试、全量 `flutter test`。

