> **注:** 本文档在 2026-04-18 由 Plan A/B 的仿古风设计体系落地同步更新。
> 原先"新中式极简"风格的设计决策已演进为"仿古风"，
> 对应实现见 `lib/presentation/widgets/antique/` 与 `lib/core/theme/`。

> **2026-04-18 更新**：完成 antique 体系落地 → 收敛方案修订。
> 当前权威 spec 见 [docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md](superpowers/specs/2026-04-17-unified-antique-ui-design.md)。
>
> 本文档只记录"设计意图层"，不再包含"待建设清单"——
> 实际组件库状态以 `lib/presentation/widgets/antique/` 为准。

如何在一个统一的框架下，优雅地展示由于逻辑、复杂度完全不同的排盘界面（例如简单的"小六壬"与极其复杂的"大六壬"），同时为未来增加新术数（如紫微斗数、奇门遁甲）预留空间。针对**首页（起卦大厅）**的设计，这是用户进入应用的第一印象，也是分发流量的核心枢纽。

以下是关于首页的主题风格、元素构成、分布逻辑的详细设计方案：

1. 设计主题 (Theme)

核心关键词：**仿古风 (Antique)** + 现代秩序感

传统的排盘软件容易显得老气或杂乱（像贴满广告的电线杆），为了体现"平台化"和"专业感"，建议采用以下风格：

视觉隐喻： "书房"或"案头"。用户打开 App 就像铺开一张宣纸，准备进行演算。

### 1.3 色彩体系

所有仿古风页面与组件**只能引用 token，不得硬编码颜色**。完整 13 色板如下，Dart token 名称定义在 `lib/core/theme/app_colors.dart`：

| Token | Hex | 用途 |
|---|---|---|
| `zhusha` | `#C94A4A` | 朱砂红：主强调、按钮、章印 |
| `zhushaLight` | `#E07070` | 浅朱砂：按钮渐变浅端 |
| `zhushaDeep` | `#B23A3A` | 深朱砂：危险按钮渐变起色 |
| `errorDeep` | `#8B2020` | 栗色：错误/警告深色（SnackBar 错误背景） |
| `danjin` | `#D4B896` | 淡金：边框、分割线、输入框边 |
| `danjinDeep` | `#B79452` | 深淡金：罗盘环、印章边 |
| `guhe` | `#8B7355` | 古褐：次要文字、标签 |
| `xuanse` | `#2C2C2C` | 玄色：正文 |
| `qianhe` | `#A0937E` | 浅褐：placeholder |
| `xiangse` | `#F7F7F5` | 缃色：背景顶 |
| `xiangseDeep` | `#F0EDE8` | 缃色深：背景底 |
| `biyongBlue` | `#3A6EA5` | 比用蓝：大六壬课型指示 |
| `jishenGreen` | `#4A7C59` | 吉神绿：神煞吉神标识 |

全局规则：
- 页面背景统一 `xiangse → xiangseDeep` 自上而下线性渐变
- 卡片底色 `Colors.white.withOpacity(0.6)`
- 边框/分割线 `danjin.withOpacity(0.5)`
- 主按钮渐变 `zhusha → zhushaLight`

图标风格： 线性图标 + 局部色块点缀，避免过于具象的拟物风格，保持现代感。

### 1.5 字体

**全量思源宋体 (Noto Serif SC)**。决策原因：仿古调性整体性优先。若实测小号正文/数字（11–13px）易读性显著下降，按 §7 风险预案降级正文为 PingFang SC（标题与装饰仍衬线）。

新增 5 个 antique text styles，定义在 `lib/core/theme/app_text_styles.dart`：

| 样式名 | fontSize | fontWeight | 用途 |
|---|---|---|---|
| `antiqueTitle` | 18 | bold | 页面/卡片主标题 |
| `antiqueSection` | 15 | bold | 节标题（朱砂色） |
| `antiqueBody` | 13 | regular | 正文内容 |
| `antiqueLabel` | 11 | regular | 标签/说明（古褐色） |
| `antiqueButton` | 16 | bold | 按钮文字（白色） |

### 组件库引用

仿古风组件库位于 `lib/presentation/widgets/antique/`，共 10 个原子组件 + 1 个 barrel：

| 组件 | 用途 | 典型场景 |
|---|---|---|
| `AntiqueScaffold` | 页面骨架（缃色渐变 + 可选罗盘/水印） | 所有页面根 |
| `AntiqueAppBar` | 透明 AppBar + 底部淡金分割线 | 所有 AppBar |
| `AntiqueCard` | 半透明白卡 + 淡金边 | 替代 Material Card |
| `AntiqueSectionTitle` | 朱砂衬线节标题 | 每个 section 头 |
| `AntiqueDivider` | 淡金细分割线 | section 间分割 |
| `AntiqueButton` | primary/ghost/danger 胶囊按钮 | 所有 ElevatedButton |
| `AntiqueTextField` | 半透明白底 + 淡金边输入框 | 所有 TextField |
| `AntiqueDropdown` | 淡金边 + 朱砂箭头下拉 | 所有 DropdownButton |
| `AntiqueTag` | 低透明色块标签 | 分类/状态标签 |
| `AntiqueWatermark` | 小印章水印 | 历史/设置等轻装饰 |

通过 `import '../../widgets/antique/antique.dart';` 一次性引入全部。组件使用 `AntiqueTokens`（`lib/core/theme/antique_tokens.dart`）提供的圆角/间距/边框常量，以及 `AppColors` + `AppTextStyles` 提供的色板和字体。

#### chromeless / body-only 能力（正式支持）

`AntiqueScaffold` 只应出现在**顶层页面壳**。当一个页面需要被**嵌入**到另一个页面（如 `HistoryListScreen` 被嵌入到 `HomeScreen` 的历史 tab），该嵌入目标必须支持 chromeless 模式——即**返回 body-only 内容**，不包含自己的 `AntiqueScaffold` / `AntiqueAppBar` 外壳。

已采用此模式的例子：
- `HistoryListScreen(chromeless: true)`：当作为 home tab 1 的 body 使用时不带外壳

规则：当一个页面组件可能在多种上下文（独立路由 / 嵌入 tab / 嵌入 dialog）中被使用时，默认应提供 `chromeless` 构造参数。

2. 页面元素清单 (Elements)

首页不需要太多元素，6 个核心模块足以支撑逻辑，保持页面清爽：

全局状态栏 (Header)： 品牌/用户信息。

时空引擎卡片 (Time Engine)： 动态显示的干支历法。

核心功能网格 (The Grid)： 六爻、大六壬等入口。

扩展入口 (Extensions)： 添加新术数的"+"号。

最近记录条 (Quick History)： 快速回看上一个盘。

底部导航栏 (Tab Bar)： 全局导航。

3. 布局与分布 (Distribution)

采用垂直流式布局，从上到下遵循"天（时间）- 人（操作）- 地（记录）"的逻辑。

Top 区：天时 (25% 高度)

这是一个沉浸式的卡片区域。

左上角： 当前公历时间（大号字体，如 "14:30"），下方小字显示日期。

中间/背景： 动态展示当前的**"四柱八字"**（年、月、日、时）。

设计细节： 当时间跨越时辰（如从午时变未时），这里的干支文字可以有一个翻页或淡入淡出的动画，暗示时间的流动。

右上角： 真太阳时校准状态图标（显示一个小定位图标，提示"已校准"）。

Middle 区：术数矩阵 (55% 高度)

这是视觉重心，采用 2x2 网格 或 瀑布流卡片。

布局：

卡片 1：六爻（建议占据最大位置，或左上）。

视觉： 背景有淡淡的龟甲或铜钱纹理。

文字： 标题"六爻纳甲"，副标题"问事、决策"。

卡片 2：梅花易数

视觉： 背景梅花剪影。

文字： 标题"梅花易数"，副标题"占象、应期"。

卡片 3：小六壬

视觉： 掌诀手势图。

文字： 标题"小六壬"，副标题"速断、掌诀"。

卡片 4：大六壬

视觉： 式盘（天圆地方）线条图。

文字： 标题"大六壬"，副标题"人事、运筹"。

**卡片 5：更多/添加 (+) **

设计： 虚线边框，点击跳转插件市场。

Bottom 区：足迹 (20% 高度)



最近排盘 (Floating Pill)： 一个悬浮的胶囊状长条，显示"上次排盘：问事业... (六爻)"，点击直接恢复当时的盘面。

导航栏： 首页 | 历史 | 历法 | 我的。

4. 具体设计执行 Demo (UI 描述)

假设手机屏幕宽度为 100%：

【顶部背景层】

背景色：缃色 / `AppColors.xiangse`（`#F7F7F5`），自上而下渐变至缃色深 / `AppColors.xiangseDeep`（`#F0EDE8`）

元素 1： 巨大的淡灰色汉字"辰"字压在背景右侧（代表今年的年支或日支），作为装饰底纹（`AntiqueScaffold(watermarkChar: '辰')`）。

【信息层】

[第一行] 左侧显示用户头像（小圆圈），右侧显示"设置"齿轮。

[第二行 - 时间卡片]

使用 `AntiqueCard` 包裹，轻微 `danjin` 边框替代 Material 阴影。

内部分三列显示：

癸卯年 (竖排)

甲子月 (竖排)

丁丑日 (竖排)

右下角用朱砂（`AppColors.zhusha`）印章风格显示当前节气（如"冬至"）。

【功能层 - Grid View】

间距： 卡片之间保留 12px（`AntiqueTokens.gapBase`）间距，营造呼吸感。

六爻卡片设计（`AntiqueCard`）：

左上角：衬线粗体"六爻"（`antiqueTitle` 样式）。

右下角：一枚金色的铜钱 Icon（半透明切图）。

点击效果：卡片轻微下沉（Scale 0.98，`AntiqueCard.onTap` 内置）。

大六壬卡片设计（`AntiqueCard`）：

左上角：衬线粗体"大六壬"（`antiqueTitle` 样式）。

右下角：复杂的罗盘线条图（半透明）。

注意： 由于大六壬更"重"，卡片可叠加比用蓝（`AppColors.biyongBlue`）作为系统标识色，体现厚重感。

【底部层】

Tab Bar： 不用系统默认的，自定义高度 60px。

选中状态：图标变朱砂实心（`AppColors.zhusha`），下方出现一个小朱砂点。

未选中状态：古褐（`AppColors.guhe`）线性图标。

5. 交互微动效 (Micro-interactions)

为了提升高级感，首页需要加一点"动"的东西：

呼吸感： 顶部的"真太阳时"图标，可以像心跳一样极慢速地律动（Breathing），暗示时间在流逝。

卡片载入： 打开 APP 时，四个功能卡片不要同时出现，而是依次（staggered）上浮显示。

触感反馈： 点击任意一个术数卡片时，触发轻微的震动（Haptic Feedback），模拟"按下机关"的感觉。

（注：以上三项微动效在当前 Plan A/B 范围内**未实施**，留待后续迭代。）

总结

首页的设计核心是**"静中有动，繁中有序"**。

静： 留白多，颜色雅致（缃色 + 淡金 + 玄色，不引入高饱和度色块）。

动： 时间模块是活的。

繁： 支持多术数（六爻、大六壬、小六壬、梅花易数及未来系统）。

序： 通过 `AntiqueCard` 网格将不同复杂度的术数整齐排列，统一仿古调性。

## Token 单一来源

所有视觉 token 的权威位置：

| 维度 | 权威文件 |
|---|---|
| 颜色 | `lib/core/theme/app_colors.dart` |
| 字体样式 | `lib/core/theme/app_text_styles.dart` |
| 形状 / 间距 / 阴影 / 渐变 | `lib/core/theme/antique_tokens.dart` |

**禁止**在其他位置引入第二套别名（如 `zhushaHong` 之类），**禁止**在页面或 UI 工厂内硬编码通用色字面量。
领域色（六亲 / 五行 / 铜钱面 / 阴阳爻线蓝等）允许保留 inline 但必须带 `//` 注释说明用途。
