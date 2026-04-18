# 全应用仿古风 UI 收敛方案（修订版）

**原始草案日期**：2026-04-17  
**修订日期**：2026-04-18  
**作者**：Kai Yueh / Codex 修订  
**状态**：Revised Draft（作为当前事实校正后的收敛方案）  
**Spec 类型**：Design System 收敛 + UI 运行时边界纠偏  
**项目**：万象排盘 多术数系统平台（Flutter）

> 本文档已不再把 2026-04-17 的内容视为“待从零实施的设计草案”。
>
> 当前仓库中，`antique/` 组件库、核心 token、首页/历史/六爻起卦页/多套结果页已经部分或大幅落地。  
> 因此本文档的职责变更为：
>
> 1. 校正旧方案与当前代码事实的偏差
> 2. 明确过去架构中的设计缺陷与冗余设计
> 3. 给出面向当前代码库的最优收敛方向

---

## 1. 修订原因

### 1.1 当前事实

当前仓库已经具备以下基础，不应再被描述为“未来目标”：

- `lib/presentation/widgets/antique/` 已存在完整组件集：
  - `AntiqueScaffold`
  - `AntiqueAppBar`
  - `AntiqueCard`
  - `AntiqueSectionTitle`
  - `AntiqueDivider`
  - `AntiqueButton`
  - `AntiqueTextField`
  - `AntiqueDropdown`
  - `AntiqueTag`
  - `AntiqueWatermark`
  - `AntiqueDialog`
- `AppColors`、`AppTextStyles`、`AntiqueTokens` 已存在并被实际引用
- 首页、历史页、六爻起卦页、六爻结果页、大六壬结果页已经使用了 antique 体系
- 运行时 UI 分发主干不是“页面列表逐个换皮”，而是：
  - `DivinationUIFactory`
  - `DivinationUIRegistry`
  - 各术数系统自己的 cast/result/history card 渲染
- 历史页已存在 `chromeless` 内嵌模式，说明页面壳与内容区已经分层，不应继续使用“所有页面一刀切替换 Scaffold”的粗粒度描述

### 1.2 修订目标

本次修订后的目标不再是“创建仿古风体系”，而是“收敛现有体系并清理错误抽象”：

1. 让文档与当前代码事实一致，停止产生“文档说一套、代码跑另一套”的双轨描述
2. 把设计系统的单一真相收敛到：
   - `AppColors`
   - `AppTextStyles`
   - `AntiqueTokens`
   - `lib/presentation/widgets/antique/`
3. 把 UI 运行时边界收敛到：
   - 跨系统壳层：`AntiqueScaffold`、主页、历史总表、设置页
   - 系统专属界面：各系统 `DivinationUIFactory`
4. 明确哪些历史设计属于伪统一、重复抽象或过度设计，并逐步废弃

### 1.3 非目标

本方案不覆盖以下内容：

- 暗黑模式
- 路由策略调整
- 数据层 / Repository / Domain 逻辑重构
- 新术数系统功能实现
- 动效增强、触感反馈
- 纯视觉审美推翻式重做

---

## 2. 过去方案中的设计缺陷与冗余设计

本节不是追责，而是明确哪些旧决策已经证明不适合作为继续演进的基础。

### 2.1 缺陷一：把“历史草案”继续当作“当前实施方案”

旧版文档仍然把以下事项描述为未来工作：

- antique 组件库待创建
- 首页 / 历史 / 结果页待迁移
- 大六壬样式待下沉

这在当前代码库里已经不成立。继续沿用旧描述，会导致：

- 重复迁移
- 错误评估完成度
- 产生无意义的二次设计讨论

**修正决策**：

- 本文件从今天起只描述“当前事实 + 收敛动作”
- 不再用“从零建设 antique 体系”的口径描述现状

### 2.2 缺陷二：页面中心化描述，脱离实际运行时边界

旧方案把问题表述成“逐页改造页面样式”，但当前运行时主干并不是页面静态清单，而是：

- 主页通过注册表展示系统入口
- 结果页和历史卡片通过 `DivinationUIFactory` 分发
- 不同术数系统天然拥有不同的输入方式和结果结构

继续使用“页面中心化迁移”会误导后续设计，把平台级约束压到系统级页面中。

**修正决策**：

- 以后所有 UI 方案默认以“共享 Design System + 系统 UI 工厂边界”为主视角
- 页面改造只是收敛动作，不再是架构中心

### 2.3 缺陷三：伪统一命名，制造错误抽象

当前最典型的问题有两个：

1. `UnifiedCastScreen` 实际只服务六爻
2. `presentation/screens/result/result_screen.dart` 并不是运行时唯一结果页，真实主路径已经分散在各系统 UI factory 中

这类命名会造成一种错觉：好像平台已经拥有真正跨系统统一的 cast/result 页面。实际上并没有。

**这属于典型的伪统一设计。**

它的问题是：

- 名字比抽象更大
- 平台层承担了本应属于系统层的概念
- 后续新增术数时，很容易被迫去“套”一个并不适配的伪统一页面

**修正决策**：

- 最优方向不是继续扩大“统一页面”
- 最优方向是承认系统差异，把统一层收敛到：
  - 壳层
  - token
  - primitive components
  - 共享 section widgets

### 2.4 缺陷四：并行存在的重复渲染入口

当前存在数个重复或半重复入口：

- 通用 `ResultScreen`
- 六爻 UI factory 内部结果页
- 大六壬 UI factory 内部结果页
- `DivinationUIFactory.buildSystemCard()`
- 首页自己使用的 `DivinationSystemCard`

其中有些入口已经不是主路径，却仍然保留在接口或文件结构中，增加理解成本。

**冗余设计判断**：

- 如果一个入口不是运行时主干，就不能继续被描述为一等抽象
- 如果系统卡片的运行时主路径是统一 `DivinationSystemCard`，则 `buildSystemCard()` 不应继续被当成主干能力宣传

**修正决策**：

- 通用 `ResultScreen` 降级为 legacy 适配层，最终可删除
- `buildSystemCard()` 降级为非主线路扩展点；若长期不用，应从接口中移除

### 2.5 缺陷五：Theme 与 antique 组件形成平行体系

旧方案提出“antique 组件不依赖 Theme，Theme 保持现状”，这在早期是务实选择，但作为长期方案有明显问题：

- 原生 `Card` / `TextField` / `PopupMenuButton` / `TextButton` 仍会出现
- 如果 Theme 不承接 token，这些原生控件就会持续漂移
- 设计系统会被拆成两套：
  - antique 组件内部样式
  - Theme 默认样式

**这属于隐藏式冗余设计。**

**修正决策**：

- `ThemeData` 必须承接 token 作为兜底
- antique 组件可以覆盖高保真视觉，但不能脱离 theme 语义体系独立生长

### 2.6 缺陷六：token 命名与代码现实不一致

旧方案中使用了 `zhushaHong` 等命名，但当前代码中的真实 token 命名是：

- `zhusha`
- `zhushaLight`
- `zhushaDeep`
- `danjin`
- `danjinDeep`
- `guhe`
- `qianhe`
- `xuanse`
- `xiangse`
- `xiangseDeep`

文档继续发明第二套命名，只会造成：

- 文档和代码互相翻译
- 设计评审成本上升
- 开发者在“该改哪一个 token”上反复确认

**修正决策**：

- 当前代码中的 token 名即为权威命名
- 除非仓库真的统一重命名，否则文档不得使用另一套别名

### 2.7 缺陷七：字体策略没有交付契约

旧方案要求全量 `Noto Serif SC`，这是视觉方向，不是交付事实。

当前问题在于：

- 代码中引用了该字体名
- 但 `pubspec.yaml` 没有对应 `fonts:` 声明
- 文档却把它写成可验收事实

这会导致：

- 真机与 golden 基线不稳定
- 不同平台回退到不同系统字体
- “样式不一致”问题无法归因

**修正决策**：

- 字体策略必须有交付契约
- 要么把字体资产真正纳入 `pubspec.yaml`
- 要么把文档改成“优先 serif fallback，不作为严格验收项”

### 2.8 缺陷八：测试门禁过度理想化

旧方案把“大六壬迁移前后 pixel diff = 0”写成关键门禁，这在真实 UI 收敛中过于理想：

- 字体抗锯齿会变
- Flutter 小版本会影响绘制
- 部分 Material 内部布局在平台间有细微差异

**修正决策**：

- Golden 测试继续保留
- 但门禁应改为“代表性页面 + 关键视觉不回退”
- 不把全局 `pixel diff = 0` 作为跨阶段通用规则

### 2.9 缺陷九：对 `Scaffold` 替换策略表述过粗

“替代所有 `Scaffold`”这类说法在今天已经不准确，因为当前存在：

- 顶层页面壳
- 被嵌入到主页 tab 内的内容页
- 可复用的 body-only 内容区域

历史页的 `chromeless` 已证明：不是所有场景都应该包一层完整页面骨架。

**修正决策**：

- `AntiqueScaffold` 只要求用于顶层页面壳
- 内容复用场景必须允许 body-only / chromeless 变体

---

## 3. 最优收敛后的目标架构

### 3.1 单一真相来源

UI 设计系统的唯一权威来源应为：

| 维度 | 权威位置 | 说明 |
|---|---|---|
| 颜色 token | `lib/core/theme/app_colors.dart` | 所有通用色、语义色、系统色统一登记 |
| 字体样式 | `lib/core/theme/app_text_styles.dart` | 标题、正文、标签、按钮、装饰文字 |
| 形状/间距 token | `lib/core/theme/antique_tokens.dart` | 圆角、边框、间距、阴影、渐变 |
| 原子组件 | `lib/presentation/widgets/antique/` | 仿古风 primitive components |
| 共享区块 | `lib/presentation/widgets/` | 问题区、扩展信息区、卦象区等跨系统 section |

以后不得再引入第三套来源，例如：

- 页面私有硬编码颜色系统
- 某个 UI factory 自己维护的“半套 token”
- 文档里再写一套别名 token

### 3.2 UI 运行时边界

最优方案不是“所有系统共用一套统一页面”，而是“统一壳层 + 系统差异下沉”。

| 边界 | 归属 | 规则 |
|---|---|---|
| 页面骨架、背景、水印、统一导航 | 平台层 | 使用 `AntiqueScaffold` / `AntiqueAppBar` |
| 按钮、卡片、输入框、分隔线等 primitive | Design System | 使用 antique 组件 |
| 占问区、扩展信息区、AI 分析区等共享 section | 平台共享 widgets | 跨系统可复用，但不负责系统特定数据结构 |
| 起卦页 / 结果页 / 历史卡片的系统特定结构 | 各系统 `DivinationUIFactory` | 系统自己负责 |
| 具体系统的领域可视化部件 | 各系统本地 | 如三传圆徽、特殊表格、术数专属徽章 |

### 3.3 命名与抽象收敛

#### 3.3.1 `UnifiedCastScreen`

当前应视为**六爻专用遗留命名**。

最优方向：

- 代码层重命名为 `LiuYaoCastScreen`
- 如果短期不改文件名，则在文档与代码注释里明确标记为 legacy name
- 不再把它宣传为平台级“统一起卦页”

#### 3.3.2 `ResultScreen`

当前通用 `presentation/screens/result/result_screen.dart` 不应继续被描述为唯一结果页。

最优方向：

- 各系统结果页归属各自 UI factory
- 平台层只保留共享 section widgets
- `ResultScreen` 若无主路径引用，转为 legacy adapter，最终删除

#### 3.3.3 `buildSystemCard()`

当前首页主路径使用的是统一 `DivinationSystemCard`，而不是 factory 返回的 system card。

最优方向：

- `DivinationSystemCard` 继续作为默认主路径
- `buildSystemCard()` 只在确有必要时作为 escape hatch
- 若长期无调用，应从 `DivinationUIFactory` 接口移除，减少冗余抽象

### 3.4 Theme 策略

修订后的原则如下：

1. `ThemeData` 不是废弃层，而是**兜底层**
2. antique 组件是**高保真封装层**
3. 两者必须共享相同 token 语义

具体要求：

- `colorScheme`、`TextTheme`、`InputDecorationTheme`、`CardTheme`、`PopupMenuTheme` 至少承接 antique token 的基础色与字重
- antique 组件允许覆盖细节视觉，但不得与 theme 语义反向偏离
- 所有未封装原生控件应先从 theme 获得接近 antique 的默认表现

### 3.5 字体策略

修订后的字体方案分两步：

#### P0：交付契约成立

- 若继续坚持“全量 `Noto Serif SC`”：
  - 必须把字体资产纳入仓库
  - 必须在 `pubspec.yaml` 声明 `fonts:`

#### P1：可读性回退规则

- 标题、装饰、节标题优先 serif
- 若 11px-13px 正文与数字实测可读性不足：
  - 正文可回退系统 sans
  - 标题与装饰保留 serif

也就是说，字体策略必须区分：

- 视觉方向
- 交付事实
- 回退条件

---

## 4. 收敛实施方案

### 4.1 Phase A：文档与契约纠偏

目标：先停止误导，再继续演进。

工作内容：

1. 把本文档改为当前事实版本
2. 同步 `docs/UI设计指导.md`
3. 在相关代码注释中标记 legacy 抽象：
   - `UnifiedCastScreen`
   - `ResultScreen`
4. 明确 `chromeless` / body-only 页面复用属于正式支持能力

### 4.2 Phase B：边界清理

目标：去掉伪统一和重复入口。

工作内容：

1. `UnifiedCastScreen` 更名为 `LiuYaoCastScreen`
2. 清理或降级通用 `ResultScreen`
3. 审核 `DivinationUIFactory` 接口，决定是否保留 `buildSystemCard()`
4. 把“系统专属页面由 UI factory 负责”写成硬规则

### 4.3 Phase C：视觉债务清理

目标：把当前残留的样式漂移收敛到同一套系统。

重点清理对象：

- `divination_systems/*/ui/` 内残留的原生 `Card`、`TextField`、`TextStyle`
- 原生控件未走 token 的颜色字面量
- 系统专属色未在 `AppColors` 声明而直接写死
- 设置页 / AI 设置页 / 主页局部控件的半手工 antique 风格

规则：

- 能抽到 antique primitive 的，抽到 antique
- 只在确有术数语义时，保留系统本地组件
- 所有颜色必须来自 `AppColors`

### 4.4 Phase D：Theme 与字体稳定化

目标：把“看起来像 antique”变成“系统级稳定可交付”。

工作内容：

1. 为原生控件补全 token 化 theme
2. 补足字体资产与 `pubspec.yaml` 配置，或下调文档承诺
3. 明确正文 serif fallback 规则

### 4.5 Phase E：测试与门禁重构

目标：让测试真正服务于收敛，而不是制造伪失败。

工作内容：

1. antique 组件维持 widget test
2. golden 只覆盖代表性页面和关键路径：
   - 首页
   - 六爻起卦页
   - 六爻结果页
   - 大六壬结果页
   - 历史页
   - 设置页 / AI 设置页
3. 取消“所有迁移都必须 pixel diff = 0”的表述
4. 增加静态审计规则：
   - `presentation/`
   - `divination_systems/*/ui/`
   中新增代码不得出现新的通用色字面量

---

## 5. 设计规则

### 5.1 Token 规则

- 使用当前代码中的真实命名：
  - `zhusha`
  - `zhushaLight`
  - `zhushaDeep`
  - `danjin`
  - `danjinDeep`
  - `guhe`
  - `qianhe`
  - `xuanse`
  - `xiangse`
  - `xiangseDeep`
- 文档不得再引入 `zhushaHong` 之类别名
- 新增颜色一律先进入 `AppColors`，再进入 UI

### 5.2 组件规则

- 顶层页面默认使用 `AntiqueScaffold`
- 嵌入式内容必须允许 chromeless / body-only 复用
- 原生 `Card` / `TextField` / `ElevatedButton` 若出现在业务 UI 中，必须有明确理由
- 新的共享视觉样式先考虑落入 antique 组件库，而不是页面私有 helper

### 5.3 系统本地组件规则

以下类型允许保留在术数系统本地，不要求上浮：

- 直接映射术数语义的图形部件
- 专属表格结构
- 专属徽章、宫位、传递关系图

判断标准：

- 如果一个组件脱离当前术数系统就失去意义，它就不应该硬塞进 antique 库

### 5.4 文档规则

今后的 UI spec 必须遵守：

1. 先写当前事实
2. 再写问题
3. 再写收敛动作
4. 不得把已实现内容重复写成“待创建能力”

---

## 6. 验收标准

以下条件同时满足，才算本方案收敛完成：

1. 本文档与当前代码事实一致，不再把 antique 基础设施描述为待建设能力
2. `DivinationUIFactory` 被明确为系统专属 cast/result/history card 的唯一主干分发点
3. `UnifiedCastScreen` 被重命名，或被正式标记为六爻专用 legacy name
4. 通用 `ResultScreen` 不再作为主路径抽象宣传；若保留，必须明确为 legacy adapter
5. `buildSystemCard()` 若无真实调用，已移除或被标记为非主线路扩展点
6. 顶层页面使用 `AntiqueScaffold`，嵌入式页面保留 chromeless / body-only 支持
7. 所有通用视觉 token 以 `AppColors`、`AppTextStyles`、`AntiqueTokens` 为单一真相来源
8. `ThemeData` 已承接 antique token 的兜底语义，而不是与 antique 组件平行漂移
9. 字体策略具备交付契约：
   - 要么 `pubspec.yaml` 声明真实字体资产
   - 要么文档不再把全量 serif 写成严格验收项
10. 代表性页面 golden 与 widget tests 通过，且测试门禁不再依赖全局 `pixel diff = 0`

---

## 7. 结论

最优方案不是继续追求“所有系统塞进统一页面”的表面统一，而是：

- 统一 design system
- 统一壳层语言
- 统一 token 与 fallback theme
- 保留系统差异
- 删除伪统一命名
- 清理重复入口

换句话说，平台层应该统一“怎么长得像万象排盘”，而不是统一“所有术数必须长成同一种页面结构”。

这才是当前代码库最稳、最清晰、也最容易继续扩展的方向。
