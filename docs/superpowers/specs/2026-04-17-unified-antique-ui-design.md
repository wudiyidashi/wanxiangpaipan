# 全应用统一仿古风 UI 设计规范

**日期**：2026-04-17
**作者**：Kai Yueh（与 Claude 协作）
**状态**：Draft（待用户审阅）
**Spec 类型**：UI 设计统一 + 组件库抽取
**项目**：万象排盘 多术数系统平台（Flutter）

---

## 1. 背景与目标

### 1.1 现状

项目当前 UI 风格分裂为三层：

| 层 | 代表页面 | 风格 |
|----|---------|------|
| 仿古风（最新） | 大六壬起课页、结果页 | 罗盘底、朱砂 #C94A4A、淡金 #D4B896、衬线、半透明白卡 |
| 过渡风 | 统一起卦页 `unified_cast_screen.dart` | 半透明卡 + 淡金边，部分仿古元素 |
| Material 默认 | 首页、六爻结果页、历史、设置、AI 设置 | 几乎裸的 Material，无仿古特征 |

最近三次提交（`d928f6e`, `2221610`, `73c03b6`）已为大六壬完整建立仿古风视觉，但**所有样式硬编码在 `daliuren_ui_factory.dart` 单文件内**，未抽出共享组件，无法复用到其他页面。

### 1.2 目标

1. **统一所有页面**到仿古风（朱砂 + 淡金 + 缃色 + 衬线 + 半透明白卡 + 罗盘/水印装饰）
2. 把大六壬内联样式**下沉为共享组件库** `lib/presentation/widgets/antique/`（10 个原子组件），未来新增术数系统（紫微斗数、奇门遁甲）开箱即用
3. 设计令牌全部**命名化**：颜色、字体、圆角、间距、边框宽度，消除魔法值
4. 同步更新 `docs/UI设计指导.md`，承认项目从"新中式极简"演进到"仿古风"，作为单一权威设计文档

### 1.3 非目标（明确排除）

- 暗黑模式（"墨色夜间模式"，需另起 spec）
- 卡片 staggered 载入动画、呼吸动效（指导文档 §5 提及，本次不实施）
- 触感反馈接入（HapticFeedback）
- 紫微斗数、奇门遁甲等未来术数系统的 UI 实现
- 后端、数据层、领域逻辑改造（本次纯 UI/视觉）

---

## 2. 设计令牌（Design Tokens）

### 2.1 色板（扩展 `AppColors`）

新增 9 个命名颜色 token，所有仿古风页面与组件**只能引用 token，不得硬编码**：

| Token | Hex | 用途 |
|---|---|---|
| `zhushaHong`   | `#C94A4A` | 朱砂红：主按钮、强调、节标题、章印 |
| `zhushaLight`  | `#E07070` | 浅朱砂：按钮渐变浅端、装饰渐变 |
| `danjin`       | `#D4B896` | 淡金：边框、分割线、输入框边、Tag 边 |
| `danjinDeep`   | `#B79452` | 深淡金：罗盘环、印章边、强调边框 |
| `guhe`         | `#8B7355` | 古褐：次要文字、标签、说明文 |
| `xuanse`       | `#2C2C2C` | 玄色：正文、主标题 |
| `qianhe`       | `#A0937E` | 浅褐：placeholder、禁用态文字 |
| `xiangseLight` | `#F7F7F5` | 缃色：背景渐变顶端 |
| `xiangseDeep`  | `#F0EDE8` | 缃色深：背景渐变底端 |

**全局规则**：
- 页面背景统一 `xiangseLight → xiangseDeep` 自上而下线性渐变
- 卡片底色 `Colors.white.withOpacity(0.6)`
- 边框/分割线 `danjin.withOpacity(0.5)`
- 主按钮渐变 `zhushaHong → zhushaLight`
- 错误/警告语义色复用 `zhushaHong` 的深变体，**禁止**引入栗色 `#8B2020`（破坏调性）

### 2.2 字体（扩展 `AppTextStyles`）

仿古风全量使用衬线字体 `Noto Serif SC`。新增 5 个 antique text styles：

```dart
static const antiqueTitle    = TextStyle(fontFamily: 'Noto Serif SC', fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.xuanse);
static const antiqueSection  = TextStyle(fontFamily: 'Noto Serif SC', fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.zhushaHong);
static const antiqueBody     = TextStyle(fontFamily: 'Noto Serif SC', fontSize: 13, color: AppColors.xuanse);
static const antiqueLabel    = TextStyle(fontFamily: 'Noto Serif SC', fontSize: 11, letterSpacing: 1, color: AppColors.guhe);
static const antiqueButton   = TextStyle(fontFamily: 'Noto Serif SC', fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white);
```

### 2.3 形状与间距（新增 `AntiqueTokens`）

新建 `lib/core/theme/antique_tokens.dart`，集中管理非颜色非字体的视觉常量：

```dart
class AntiqueTokens {
  // 圆角
  static const double radiusCard       = 8;
  static const double radiusButton     = 26; // 胶囊
  static const double radiusInput      = 8;
  static const double radiusTag        = 12;

  // 边框
  static const double borderWidthThin  = 0.5;
  static const double borderWidthBase  = 1.0;

  // 间距
  static const double gapTight         = 8;
  static const double gapBase          = 12;
  static const double gapSection       = 16;

  // 阴影（按钮专用）
  static const BoxShadow buttonShadow  = BoxShadow(
    color: Color(0x4DC94A4A),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}
```

**关键规则**：
- 卡片**无阴影**，靠 `danjin` 边框营造"案头纸张"质感
- 按钮**有阴影**（`zhushaHong @ 0.3, blur 12, offset 0,4`）
- 圆角统一 8px（卡片/输入），按钮唯一例外用 26px 胶囊

### 2.4 装饰层

| 装饰 | 复用现有/新建 | 适用场景 |
|---|---|---|
| `CompassBackground` | 现有 `widgets/cast/compass_background.dart` | 起卦页、结果页中心装饰 |
| `BackgroundDecor`（大字水印） | 现有 `widgets/home/background_decor.dart` | 首页（年支字）、结果页（日干支） |
| `AntiqueWatermark`（小印章） | **新建** | 历史页、设置页可选轻装饰 |

---

## 3. 共享组件库

新建 `lib/presentation/widgets/antique/`，抽取 10 个原子组件 + 1 个 barrel 导出。

### 3.1 目录结构

```
lib/presentation/widgets/antique/
├── antique.dart                # barrel export
├── antique_scaffold.dart       # 页面骨架
├── antique_app_bar.dart        # 透明 AppBar
├── antique_card.dart           # 半透明白卡
├── antique_section_title.dart  # 朱砂节标题
├── antique_divider.dart        # 淡金分割线
├── antique_button.dart         # 朱砂渐变胶囊按钮
├── antique_text_field.dart     # 半透明白底输入框
├── antique_dropdown.dart       # 风格化下拉
├── antique_tag.dart            # 色块标签
└── antique_watermark.dart      # 小印章水印
```

### 3.2 组件 API

#### `AntiqueScaffold`

替代所有 `Scaffold`，统一背景渐变与可选装饰。

```dart
class AntiqueScaffold extends StatelessWidget {
  const AntiqueScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.showCompass = false,
    this.watermarkChar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool showCompass;       // 中心罗盘底
  final String? watermarkChar;  // 大字水印（如"辰"）
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
}
```

#### `AntiqueAppBar`

```dart
class AntiqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AntiqueAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });
  // 透明底、衬线居中标题、底部 0.5px 淡金分隔线
}
```

#### `AntiqueCard`

```dart
class AntiqueCard extends StatelessWidget {
  const AntiqueCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  // 白@0.6 + 1px 淡金边 + 8px 圆角；onTap 时内置 Scale 0.98 按压
}
```

#### `AntiqueSectionTitle`

```dart
class AntiqueSectionTitle extends StatelessWidget {
  const AntiqueSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  // 朱砂衬线、letterSpacing 1，可带古褐副标题与右侧 trailing
}
```

#### `AntiqueButton`

```dart
enum AntiqueButtonVariant { primary, ghost, danger }

class AntiqueButton extends StatelessWidget {
  const AntiqueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AntiqueButtonVariant.primary,
    this.fullWidth = false,
  });
  // primary：朱砂渐变 + 阴影
  // ghost：透明底 + 朱砂边 + 朱砂文字
  // danger：朱砂深变体（不引入栗色）
}
```

#### 其余组件

`AntiqueDivider` / `AntiqueTextField` / `AntiqueDropdown` / `AntiqueTag` / `AntiqueWatermark` 均遵循相同范式：**封装样式、暴露内容**，签名见各自源文件，本 spec 不展开。

### 3.3 大六壬内联代码迁移

`daliuren_ui_factory.dart` 当前内联的私有 build 方法须全部替换：

| 内联方法 | 替换为 | 行号参考 |
|---|---|---|
| `_buildAntiqueCard` | `AntiqueCard` | L847–857 |
| `_buildSectionTitle` | `AntiqueSectionTitle` | L860–870 |
| `_buildAntiqueDivider` | `AntiqueDivider` | L872–875 |
| `_buildCastButton` | `AntiqueButton(variant: primary)` | L727–767 |
| 内联下拉/输入框样式 | `AntiqueDropdown` / `AntiqueTextField` | L383–688 散落 |
| 硬编码颜色（`Color(0xFFC94A4A)` 等） | `AppColors.zhushaHong` 等 token | 全文 |

**保留在大六壬本地**：`TransmissionCircle`（三传圆徽）—— 带明显领域语义（地支单字 + 朱砂渐变背景），不上浮到通用组件库。

### 3.4 Theme 集成策略

`app_theme.dart` 内的 `ElevatedButtonTheme`、`CardTheme`、`InputDecorationTheme`、`AppBarTheme` **保持现状**——antique 组件自带样式不依赖 theme，避免双重样式系统冲突。

`colorScheme.primary` 改为 `AppColors.zhushaHong`，给少数未封装的原生控件（如 `Switch`、`Checkbox` 默认色）兜底。

---

## 4. 页面改造路线

### 4.1 改造矩阵

| 文件 | 优先级 | 当前风格 | 改造关键点 |
|---|---|---|---|
| `home_screen.dart` | P0 | 接近仿古，未走 token | `AntiqueScaffold(watermarkChar: 年支字)` + Bento 卡用 `AntiqueCard` + 系统纹理半透明背景 |
| `unified_cast_screen.dart` | P0 | 过渡风 | `AntiqueScaffold(showCompass: true)` + 起卦方式 `AntiqueDropdown`/`AntiqueTag` + `AntiqueButton(primary)` |
| `result_screen.dart` | P0 | Material 默认 | `AntiqueScaffold(watermarkChar: 日干支)` + 全部 section 包 `AntiqueCard` + 六爻 UI 工厂同步改造 |
| `history_list_screen.dart` | P1 | Material 默认 | 列表项改 `AntiqueCard(onTap)` + 系统标签 `AntiqueTag` + 空态印章插图 |
| `settings_screen.dart` | P1 | Material 默认 | 分组标题 `AntiqueSectionTitle` + 每项 `AntiqueCard` 平铺 |
| `ai_settings_screen.dart` | P1 | Material 默认 | 同上 + 表单用 `AntiqueTextField` / `AntiqueDropdown` |
| `cast_method_screen.dart` | P2 | 已被 `unified_cast_screen` 替代？ | **先确认是否仍被路由引用**：未引用则删除；引用则同改造 |
| `test_screen.dart` | P2 | dev 用 | 顺手换 `AntiqueScaffold` |

### 4.2 六爻 UI 工厂联动改造

`lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart` 是结果页内容的提供者，必须同步仿古化：

- 卦象表（六爻、纳甲、六亲、六神、空亡）：每张表包 `AntiqueCard`，节标题 `AntiqueSectionTitle`
- `YaoDisplay`、`GuaCard` widget 内部硬编码颜色全部走 token
- 变卦展示区与本卦区视觉对称，中间用 `AntiqueDivider` 分割

### 4.3 实施分阶段

```
Phase 1：基础设施（无视觉变化）
  ├─ 扩展 AppColors / AppTextStyles
  ├─ 新建 AntiqueTokens
  ├─ 新建 antique/ 10 组件 + barrel
  └─ widget test + golden test 基线

Phase 2：大六壬内部迁移（无视觉变化，验证组件库）
  ├─ daliuren_ui_factory.dart 替换内联样式为新组件
  ├─ 替换硬编码色值为 token
  └─ Golden 回归：迁移前后 pixel diff = 0

Phase 3：核心流（P0）
  ├─ 首页
  ├─ 统一起卦页
  ├─ 结果页
  └─ 六爻 UI 工厂

Phase 4：外围页（P1/P2）
  ├─ 历史
  ├─ 设置 / AI 设置
  ├─ 处理 cast_method_screen（删除或迁移）
  └─ 测试页
```

**Phase 2 是安全锚点**：大六壬当前视觉已是目标，迁移后若 golden 不变，证明组件库设计正确。

---

## 5. 测试策略

### 5.1 单元 / Widget 测试

- `antique/` 每个组件配套 widget test，覆盖率 ≥ 80%
- 测试内容：属性传递、回调触发、变体渲染、边界态（空字符串、null trailing）

### 5.2 Golden Test

- 每个 antique 组件抓 golden 基线图
- §4.1 矩阵中 8 个改造页面各抓首屏 golden
- Phase 2 大六壬起课页、结果页 golden 对比作为**关键回归门禁**

### 5.3 手工验证

- 在用户预先开好的模拟器上跑完整流程：首页 → 选系统 → 起卦 → 查看结果 → 历史 → 设置
- 主观确认风格一致性、字体回退、罗盘/水印是否影响可读性

---

## 6. 文档同步

`docs/UI设计指导.md` 须同步更新（用户已选择"保留仿古风、更新指导文档"路线）：

| 章节 | 当前内容 | 更新后 |
|---|---|---|
| 设计主题 | 新中式极简 + 科技秩序感 | **仿古风（书房/案头隐喻）+ 现代秩序感** |
| 色彩体系 | 缃色 + 黛蓝 + 朱砂 + 低饱和金 | 9 色 token 完整列出（§2.1） |
| 字体 | 标题思源宋体，正文 Roboto/PingFang SC | **全量思源宋体**。决策原因：仿古风以视觉调性整体性优先于小号正文易读性；若实测 11–13px 衬线可读性显著下降，按 §7 风险预案降级正文为 PingFang SC（标题/装饰仍衬线） |
| 新增章节 | — | "共享组件库引用"，链接到 `lib/presentation/widgets/antique/` |

---

## 7. 风险与回滚

| 风险 | 缓解 |
|---|---|
| 大六壬迁移引入回归 | Phase 2 golden 门禁，pixel diff = 0 才合并 |
| 衬线字体在小号正文（11–13px）可读性下降 | golden + 真机肉眼审；若严重退回，正文降级 PingFang SC（仅正文/数字，标题与装饰仍衬线） |
| 抽出的组件 API 不够灵活，后续新页面用不了 | Phase 2 大六壬迁移时即暴露问题；保留 escape hatch（每个组件支持 `child` 自由插入） |
| 迁移期间分支长 | 按 Phase 切 PR，每 Phase 独立可合并 |

---

## 8. 验收标准

1. `lib/presentation/widgets/antique/` 10 组件全部就位，单测覆盖 ≥ 80%
2. `AppColors` / `AppTextStyles` / `AntiqueTokens` 含 §2 全部 token
3. `daliuren_ui_factory.dart` 无硬编码颜色字面量、无内联 antique 样式
4. §4.1 矩阵中 8 个目标页面所有 `Scaffold` / `AppBar` / `Card` / 主按钮均改为 antique 组件（`cast_method_screen` 若确认废弃则删除，不计入）
5. 六爻 UI 工厂结果展示走 antique 风格
6. `docs/UI设计指导.md` 与本 spec 一致
7. 全量 golden test 绿
8. 模拟器手工跑完整流程，主观风格一致

---

## 9. 后续工作（不在本 spec 范围）

- 暗黑模式（墨色 #1A1A1A 底 + token 色板暗色变体）
- 卡片 staggered 载入动画、真太阳时图标心跳呼吸
- HapticFeedback 接入卡片点击 / 起卦按钮
- 紫微斗数、奇门遁甲 UI 工厂落地（直接复用 antique 组件库）
