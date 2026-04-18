# Widget 残留清理实施计划（Plan C1）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `lib/presentation/widgets/` 下 20 个内容组件里的 63 个硬编码 hex + ~100 个内联 `TextStyle` 换成 `AppColors.*` token 和 `AppTextStyles.antique*`，延伸 Plan A/B 的仿古风至全部 widget 层。

**Architecture:** 纯机械化重构 —— 按既定色值 / 字体映射表逐文件替换，不改 API、不改结构、不改行为。每个 widget 作为独立 commit。

**Tech Stack:** Flutter 3.38.5, antique design system（Plan A/B 已就绪）。

**前置:** Plan A（`docs/superpowers/plans/2026-04-17-antique-design-system-foundation.md`）+ Plan B（`docs/superpowers/plans/2026-04-18-antique-screen-migration.md`）已完成。

---

## 范围

### 目标文件（20 个）

按残留密度（hex + TextStyle 计数）排序：

| # | 文件 | 残留数 | 分组 |
|---|---|---|---|
| 1 | `widgets/cast/yao_name_cast_section.dart` | 18 | A (cast) |
| 2 | `widgets/liuyao_table_widget.dart` | 13 | C (liuyao) |
| 3 | `widgets/cast/manual_cast_section.dart` | 13 | A (cast) |
| 4 | `widgets/cast/coin_cast_section.dart` | 13 | A (cast) |
| 5 | `widgets/cast/report_number_cast_section.dart` | 10 | A (cast) |
| 6 | `widgets/ai_analysis_widget.dart` | 10 | D (AI) |
| 7 | `widgets/home/time_engine_card.dart` | 9 | B (home) |
| 8 | `widgets/divination_system_card.dart` | 9 | E (system card) |
| 9 | `widgets/home/quick_history_bar.dart` | 8 | B (home) |
| 10 | `widgets/cast/number_cast_section.dart` | 8 | A (cast) |
| 11 | `widgets/gua_display.dart` | 7 | C (liuyao) |
| 12 | `widgets/question_section.dart` | 6 | F (sections) |
| 13 | `widgets/cast/time_cast_section.dart` | 6 | A (cast) |
| 14 | `widgets/cast/computer_cast_section.dart` | 5 | A (cast) |
| 15 | `widgets/cast/cast_button.dart` | 4 | A (cast) |
| 16 | `widgets/special_relation_section.dart` | 3 | F (sections) |
| 17 | `widgets/home/background_decor.dart` | 2 | B (home) |
| 18 | `widgets/extended_info_section.dart` | 2 | F (sections) |
| 19 | `widgets/cast/yao_line_placeholder.dart` | 2 | A (cast) |
| 20 | `widgets/home/app_bottom_nav_bar.dart` | 1 | B (home) |

### 不在范围

- `lib/presentation/widgets/antique/` — Plan A 已建、不动
- `lib/presentation/widgets/cast/compass_background.dart` — 已走 `AppColors.danjinDeep`，无残留

---

## 通用迁移规则

### 色值映射表

| 硬编码 | Token |
|---|---|
| `0xFFC94A4A` | `AppColors.zhusha` |
| `0xFFE07070` | `AppColors.zhushaLight` |
| `0xFFB23A3A` | `AppColors.zhushaDeep` |
| `0xFF8B2020` | `AppColors.errorDeep` |
| `0xFFD4B896` | `AppColors.danjin` |
| `0xFFB79452` | `AppColors.danjinDeep` |
| `0xFF2C2C2C` | `AppColors.xuanse` |
| `0xFF8B7355` | `AppColors.guhe` |
| `0xFFA0937E` | `AppColors.qianhe` |
| `0xFFF7F7F5` | `AppColors.xiangse` |
| `0xFFF0EDE8` | `AppColors.xiangseDeep` |
| `0xFF3A6EA5` | `AppColors.biyongBlue` |
| `0xFF4A7C59` | `AppColors.jishenGreen` |

**不在表里的 hex** —— 3 种处理路径：

1. **Domain 语义色**（六亲/五行/八宫/神煞专属）——保留内联，加 `//` 注释说明用途
2. **Material 调色板色**（`Colors.blue`/`Colors.green`/`Colors.grey[XXX]` 作状态指示）——保留内联，加注释
3. **应该是 token 但没在表里** —— 停下报告 BLOCKED，等评估是否新增 token

### TextStyle 映射

按角色（不按色值）判断：

| 原 TextStyle 用途 | 替换 |
|---|---|
| 大标题（18pt+ bold） | `AppTextStyles.antiqueTitle` |
| 节标题（15pt bold，朱砂色） | `AppTextStyles.antiqueSection`，或用 `AntiqueSectionTitle` widget |
| 正文（13-14pt） | `AppTextStyles.antiqueBody` |
| 标签/小字（11-12pt muted） | `AppTextStyles.antiqueLabel` |
| 按钮文字（16pt bold white） | `AppTextStyles.antiqueButton`（如果按钮本身没迁到 `AntiqueButton`） |

如果原 TextStyle 带特殊色（如 `Colors.grey[600]`），替换后用 `.copyWith(color: AppColors.guhe)` 或其他对应 token。

### 结构性替换（若遇到）

若发现 widget 内部有：
- `Card(child: ...)` → `AntiqueCard(child: ...)`
- `Container(decoration: BoxDecoration(color: white opacity, border: danjin, radius: 8))` 作卡片用 → `AntiqueCard(child: ...)`
- `TextField` / `DropdownButton` / `ElevatedButton` → 对应 antique 组件

大部分内容 widget 是渲染型，结构性替换不会很多。如有不确定的，保留原结构，只做色值/字体替换。

---

## 执行分组

分 6 组，每组一个 implementer dispatch（subagent-driven-development）：

### 分组清单

| 分组 | 文件列表 | 文件数 | 总残留 |
|---|---|---|---|
| **A: cast sections** | yao_name / manual / coin / report_number / number / time / computer / cast_button / yao_line_placeholder | 9 | 79 |
| **B: home widgets** | time_engine_card / quick_history_bar / background_decor / app_bottom_nav_bar | 4 | 20 |
| **C: liuyao display** | liuyao_table_widget / gua_display | 2 | 20 |
| **D: AI 分析** | ai_analysis_widget | 1 | 10 |
| **E: 系统卡片** | divination_system_card | 1 | 9 |
| **F: 结果页 sections** | question_section / extended_info_section / special_relation_section | 3 | 11 |

一组 = 一个 subagent = 一个 commit。Commit message 模板：

```
refactor(widgets/<group>): migrate <group> widgets to antique tokens

Replace hardcoded hex literals with AppColors tokens and inline
TextStyles with AppTextStyles.antique* per Plan C1 mapping.
Files: <list>.
```

---

## Task 1: 分组 A — Cast sections

**Files:**
- Modify: `lib/presentation/widgets/cast/yao_name_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/manual_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/coin_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/report_number_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/number_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/time_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/computer_cast_section.dart`
- Modify: `lib/presentation/widgets/cast/cast_button.dart`
- Modify: `lib/presentation/widgets/cast/yao_line_placeholder.dart`

- [ ] **Step 1: 逐文件 inventory + imports**

对每个文件跑：
```bash
grep -nE 'Color\(0xFF[0-9A-Fa-f]{6}\)|TextStyle\(' <file>
```

在每个文件顶部（如未存在）添加：
```dart
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
```

（注意：`lib/presentation/widgets/cast/` 下的文件是 3 层深，从 `lib/` 计算 import 相对路径。）

- [ ] **Step 2: 按映射表替换**

对每个文件应用"通用迁移规则"的色值映射表和 TextStyle 映射。不在表里的 hex 按 domain/Material/unknown 三类处理。

- [ ] **Step 3: 验证**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
for f in lib/presentation/widgets/cast/yao_name_cast_section.dart lib/presentation/widgets/cast/manual_cast_section.dart lib/presentation/widgets/cast/coin_cast_section.dart lib/presentation/widgets/cast/report_number_cast_section.dart lib/presentation/widgets/cast/number_cast_section.dart lib/presentation/widgets/cast/time_cast_section.dart lib/presentation/widgets/cast/computer_cast_section.dart lib/presentation/widgets/cast/cast_button.dart lib/presentation/widgets/cast/yao_line_placeholder.dart; do
  echo "--- $f ---"
  grep -cE 'Color\(0xFF[0-9A-Fa-f]{6}\)' "$f" || true
done
```

每个文件期望 0（或少量有注释的 domain 色）。

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/widgets/cast/
flutter test 2>&1 | tail -3
```

期望：analyze 绿、测试全过。

- [ ] **Step 4: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/widgets/cast/
git commit -m "refactor(widgets/cast): migrate cast section widgets to antique tokens

Replace hardcoded hex literals with AppColors tokens and inline
TextStyles with AppTextStyles.antique* per Plan C1 mapping.
Files: yao_name, manual, coin, report_number, number, time,
computer, cast_button, yao_line_placeholder."
```

---

## Task 2: 分组 B — Home widgets

**Files:**
- Modify: `lib/presentation/widgets/home/time_engine_card.dart`
- Modify: `lib/presentation/widgets/home/quick_history_bar.dart`
- Modify: `lib/presentation/widgets/home/background_decor.dart`
- Modify: `lib/presentation/widgets/home/app_bottom_nav_bar.dart`

- [ ] **Step 1: Inventory + imports**

对每个文件：
```bash
grep -nE 'Color\(0xFF[0-9A-Fa-f]{6}\)|TextStyle\(' <file>
```

顶部添加：
```dart
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
```

- [ ] **Step 2: 按映射表替换**

同 Task 1 规则。

**特别注意 `background_decor.dart`**：这是首页大字水印，颜色可能是 domain 色（深褐/浅灰），保留 inline 加注释或者改用 `AppColors.danjin.withOpacity(...)`。判断。

**特别注意 `app_bottom_nav_bar.dart`**：底部导航的选中/未选中色可能用到了 Material theme。确认不破坏 `app_theme.dart` 里的 `bottomNavigationBarTheme`。

- [ ] **Step 3: 验证**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/widgets/home/
flutter test 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/home/
git commit -m "refactor(widgets/home): migrate home widgets to antique tokens

Replace hardcoded hex literals with AppColors tokens and inline
TextStyles with AppTextStyles.antique* per Plan C1 mapping.
Files: time_engine_card, quick_history_bar, background_decor,
app_bottom_nav_bar."
```

---

## Task 3: 分组 C — Liuyao display widgets

**Files:**
- Modify: `lib/presentation/widgets/liuyao_table_widget.dart`
- Modify: `lib/presentation/widgets/gua_display.dart`

- [ ] **Step 1: Inventory + imports**

这两个文件在 `widgets/` 根级（2 层深）：
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
```

- [ ] **Step 2: 按映射表替换**

**特别注意**：六爻显示组件里会有**六亲色**（父母/兄弟/子孙/妻财/官鬼）和**五行色**（金木水火土）。这些是 domain 语义色，**不在本次迁移范围**——保留 inline 加注释说明用途。只处理结构色（背景、边框、标题文字颜色等）。

如果遇到"应该是 token 但表里没有"的情况，**停下报告 BLOCKED**，不要强行映射。

- [ ] **Step 3: 验证**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/widgets/
flutter test 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/liuyao_table_widget.dart lib/presentation/widgets/gua_display.dart
git commit -m "refactor(widgets/liuyao-display): migrate liuyao table and gua display to antique tokens

Replace structural hex literals with AppColors tokens. Domain-specific
colors (六亲/五行/八宫) retained inline with comments — deferred to
a future semantic-color pass."
```

---

## Task 4: 分组 D — AI Analysis widget

**Files:**
- Modify: `lib/presentation/widgets/ai_analysis_widget.dart`

- [ ] **Step 1: Inventory + imports**

```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
```

- [ ] **Step 2: 按映射表替换**

10 处残留混合 hex + TextStyle。常规替换。

**可能遇到**：AI 分析结果展示区可能用了 `Card` 或 `Container` 作卡片——如果是，考虑换 `AntiqueCard`（需要导入 `antique/antique.dart`）。判断。

- [ ] **Step 3: 验证 + Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/widgets/ai_analysis_widget.dart
flutter test 2>&1 | tail -3
git add lib/presentation/widgets/ai_analysis_widget.dart
git commit -m "refactor(widgets/ai-analysis): migrate AI analysis widget to antique tokens"
```

---

## Task 5: 分组 E — Divination system card

**Files:**
- Modify: `lib/presentation/widgets/divination_system_card.dart`

- [ ] **Step 1: Inventory + imports**

- [ ] **Step 2: 按映射表替换**

这是首页 Bento 网格每个术数系统的卡片。9 处残留。

**特别评估**：这个 widget 很可能用 `Container(decoration: BoxDecoration)` + `GestureDetector` 实现"可点击卡片"模式。如果是，考虑**结构性替换为 `AntiqueCard(onTap: ..., child: ...)`**——AntiqueCard 自带按压反馈（Scale 0.98），比自己实现干净。但如果 `DivinationSystemCard` 有特殊的渐变/图标布局，保留外壳只换色值。

**系统专属色**：每个术数系统有自己的主题色（在 `AppColors` 里：`liuyaoColor`、`meihuaColor`、`xiaoliurenColor`、`daliurenColor`）。如果 widget 通过参数或条件分支渲染不同系统的色——保留逻辑，不要硬换。

- [ ] **Step 3: 验证 + Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/widgets/divination_system_card.dart
flutter test 2>&1 | tail -3
git add lib/presentation/widgets/divination_system_card.dart
git commit -m "refactor(widgets): migrate divination_system_card to antique tokens"
```

---

## Task 6: 分组 F — Result page sections

**Files:**
- Modify: `lib/presentation/widgets/question_section.dart`
- Modify: `lib/presentation/widgets/extended_info_section.dart`
- Modify: `lib/presentation/widgets/special_relation_section.dart`

- [ ] **Step 1: Inventory + imports**

- [ ] **Step 2: 按映射表替换**

这三个是结果页主要 section。残留较少（6/2/3）。

**特别评估**：它们很可能已经在某种容器里（可能是普通 Container 或 Card）。如果是 Card/decorated Container 作 section 外壳——考虑**整体替换为 `AntiqueCard`**。如果已经是透明平铺（section 标题 + 内容），保留结构，加 `AntiqueSectionTitle` 作为标题。

- [ ] **Step 3: 验证 + Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/widgets/
flutter test 2>&1 | tail -3
git add lib/presentation/widgets/question_section.dart lib/presentation/widgets/extended_info_section.dart lib/presentation/widgets/special_relation_section.dart
git commit -m "refactor(widgets/sections): migrate result page sections to antique tokens"
```

---

## Task 7: 全量验证

- [ ] **Step 1: 所有 widget 文件的 hex 扫描**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rnE 'Color\(0xFF[0-9A-Fa-f]{6}\)' lib/presentation/widgets/ 2>/dev/null | grep -v "widgets/antique/"
```

期望：要么 0 匹配，要么剩下的都有 `//` 注释说明（domain 语义色、Material 调色板、未知待 token 化）。

- [ ] **Step 2: TextStyle 残留扫描**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rcE 'TextStyle\(' lib/presentation/widgets/ 2>/dev/null | grep -v "widgets/antique/" | grep -v ":0$"
```

期望：剩余的都是合理 copyWith 基于 antique 风格的 ones，或 domain 专属（六亲、五行、神煞）需要保留内联。

- [ ] **Step 3: analyze + test**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

期望：0 issue、269/269 过。

- [ ] **Step 4: 模拟器手工走查（用户侧）**

> 前置：用户已开模拟器。
> 跑 `flutter run`，过一遍主线：首页 → 起卦（每种方式都点一下）→ 结果页 → 历史 → 设置。
> 重点观察：
> - 首页 Bento 卡片按压反馈
> - 起卦页每种方式的 section 视觉（颜色/字体一致）
> - 结果页三个 section（占问/扩展信息/特殊关系）仿古一致
> - 六爻卦象表格（liuyao_table_widget）颜色层次清晰

自动化验证通过后才跑手工。

---

## 完成标志

1. ✅ 20 个 widget 文件无硬编码 `Color(0xFFXXXXXX)`（除 domain/Material 语义色带注释）
2. ✅ 所有内联 `TextStyle(` 均替换为 `AppTextStyles.antique*`（除 domain copyWith）
3. ✅ `flutter analyze` 0 issues
4. ✅ `flutter test` 269/269 通过
5. ✅ 用户模拟器手工走查确认无回归

---

## 范围外（留给后续 plan）

- `AntiqueDialog` 组件（替换 AlertDialog）——Plan C2
- a11y Semantics 统一加护——Plan C2
- 六亲/五行/神煞等 domain 语义色 token 化（需先设计 token 体系）——独立 plan
- 暗黑模式——Plan C3
- 卡片 staggered 载入动画、呼吸动效、HapticFeedback——独立 plan
