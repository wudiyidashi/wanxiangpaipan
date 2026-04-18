# 仿古风页面迁移实施计划（Plan B）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Plan A 落地的 `lib/presentation/widgets/antique/` 组件库应用到剩余 8 个页面 + 1 个 UI 工厂，让全应用视觉统一到仿古风。

**Architecture:** 逐页替换 `Scaffold` → `AntiqueScaffold`、`AppBar` → `AntiqueAppBar`、`Card`/自定义容器 → `AntiqueCard`、`ElevatedButton` → `AntiqueButton`、`TextField` → `AntiqueTextField`、`DropdownButton` → `AntiqueDropdown`。同时把硬编码色值替换为 `AppColors.*` token。六爻 UI 工厂比照 Plan A 大六壬迁移模式重构。

**Tech Stack:** Flutter 3.38.5, Dart 3+, Plan A 建成的 antique/ 组件库。

**Spec 来源:** `docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md` §4.1 改造矩阵。

**Plan A 前置:** `docs/superpowers/plans/2026-04-17-antique-design-system-foundation.md`（已完成，commit `4eacbed` 及之前）。

---

## 范围与顺序

### 改造矩阵（按优先级排序）

| # | 文件 | 行数 | 优先级 | 主要改造点 |
|---|---|---|---|---|
| T1 | `cast_method_screen.dart` | 12 | P2（删除） | 确认废弃，直接删除 |
| T2 | `result_screen.dart` | 108 | P0 | Scaffold → AntiqueScaffold |
| T3 | `liuyao_ui_factory.dart` | 311 | P0 | 比照 Plan A DLR 迁移：Card → AntiqueCard、色值 token 化、Scaffold 替换 |
| T4 | `unified_cast_screen.dart` | 400 | P0 | 12 个硬编码色 → token，Scaffold → AntiqueScaffold，dropdown → AntiqueDropdown |
| T5 | `home_screen.dart` | 339 | P0 | 主 Scaffold → AntiqueScaffold（带水印字），Bento 卡片 → AntiqueCard |
| T6 | `history_list_screen.dart` | 326 | P1 | Scaffold → AntiqueScaffold，列表项 → AntiqueCard |
| T7 | `settings_screen.dart` | 149 | P1 | Scaffold + ListTile 布局整体换皮 |
| T8 | `ai_settings_screen.dart` | 682 | P1 | 主页 + 嵌套 `_TemplateEditorScreen` 都要改，4 个 Card + 14 个 TextStyle |
| T9 | `test_screen.dart` | 154 | P2 | 简单换皮 |
| T10 | `docs/UI设计指导.md` | — | 文档 | 按 spec §6 更新为仿古风 |
| T11 | 全量验证 | — | QA | flutter test + 模拟器走查全流程 |

### 执行顺序原则

1. **先 P0 核心流**（T1-T5），确保主流程（首页→起卦→结果）视觉统一
2. **再 P1 外围**（T6-T8）
3. **最后 P2 + 文档 + 验证**（T9-T11）
4. 每个任务独立可合并，失败不影响其他任务

---

## 通用迁移模式

每个页面迁移任务共用以下替换规则：

### 结构性替换

| 原结构 | 替换为 |
|---|---|
| `Scaffold(appBar: AppBar(title: Text('X'), ...), body: ...)` | `AntiqueScaffold(appBar: const AntiqueAppBar(title: 'X'), body: ...)` |
| `Scaffold(body: Stack([gradient Container, body]))` | `AntiqueScaffold(body: ...)`（antique 自带渐变） |
| `Card(child: ...)` | `AntiqueCard(child: ...)` |
| `Container(decoration: BoxDecoration(border, radius), child: ...)` — 卡片用途 | `AntiqueCard(child: ...)` |
| `ElevatedButton(onPressed: ..., child: Text('X'))` | `AntiqueButton(label: 'X', onPressed: ..., fullWidth: ?)` |
| `TextField(...)` | `AntiqueTextField(controller, hint, maxLines, ...)` |
| `DropdownButton<T>(value, items, onChanged)` | `AntiqueDropdown<T>(value, items: [...AntiqueDropdownItem...], onChanged)` |
| `Divider()` 或分割用途的 `Container(height: 1)` | `const AntiqueDivider()` |

### Section 标题替换

任何 `Text('X', style: bold + large + color)` 作为节标题的 → `AntiqueSectionTitle(title: 'X')`

### 色值替换（全局 find/replace）

对每个迁移文件执行 `grep -nE 'Color\(0xFF[0-9A-Fa-f]{6}\)' <file>` 找到所有硬编码色，对应替换：

| 硬编码 | 替换为 |
|---|---|
| `Color(0xFFC94A4A)` | `AppColors.zhusha` |
| `Color(0xFFE07070)` | `AppColors.zhushaLight` |
| `Color(0xFFB23A3A)` | `AppColors.zhushaDeep` |
| `Color(0xFF8B2020)` | `AppColors.errorDeep` |
| `Color(0xFFD4B896)` | `AppColors.danjin` |
| `Color(0xFFB79452)` | `AppColors.danjinDeep` |
| `Color(0xFF2C2C2C)` | `AppColors.xuanse` |
| `Color(0xFF8B7355)` | `AppColors.guhe` |
| `Color(0xFFA0937E)` | `AppColors.qianhe` |
| `Color(0xFFF7F7F5)` | `AppColors.xiangse` |
| `Color(0xFFF0EDE8)` | `AppColors.xiangseDeep` |
| `Color(0xFF3A6EA5)` | `AppColors.biyongBlue` |
| `Color(0xFF4A7C59)` | `AppColors.jishenGreen` |
| 其他颜色（页面专用语义色） | 评估后：要么保留内联 + 注释说明，要么在 `AppColors` 加 token |

### Import 添加

每个迁移文件顶部需要（按需）：

```dart
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/antique/antique.dart';
```

---

## Task 1: 删除 cast_method_screen.dart

**背景:** Survey 确认此文件是 12 行的纯 passthrough（只返回 `const UnifiedCastScreen()`），且 router 中无引用。

**Files:**
- Delete: `lib/presentation/screens/cast/cast_method_screen.dart`

- [ ] **Step 1: 最后确认无引用**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && grep -rn "cast_method_screen\|CastMethodScreen" lib/ test/ 2>/dev/null`
Expected: 无引用。如果有引用，报告 BLOCKED。

- [ ] **Step 2: 删除文件**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && rm lib/presentation/screens/cast/cast_method_screen.dart`

- [ ] **Step 3: 编译验证**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: 跑测试确保无破坏**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && flutter test`
Expected: All 264 tests pass.

- [ ] **Step 5: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add -A lib/presentation/screens/cast/
git commit -m "chore: remove deprecated cast_method_screen (replaced by UnifiedCastScreen)"
```

---

## Task 2: result_screen.dart 迁移

**背景:** 108 行，六爻专用。主要改动：`Scaffold+AppBar` → `AntiqueScaffold+AntiqueAppBar`。其余子组件（QuestionSection, DiagramComparisonRow 等）暂不动，由 T3 在 LiuYaoUIFactory 内部处理。

**Files:**
- Modify: `lib/presentation/screens/result/result_screen.dart`

- [ ] **Step 1: 读文件确认当前结构**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && cat lib/presentation/screens/result/result_screen.dart`

识别 `Scaffold`、`AppBar`、任何硬编码色或 Card。

- [ ] **Step 2: 应用迁移**

找到 `return Scaffold(` 替换为 `return AntiqueScaffold(`。
找到 `appBar: AppBar(` 替换为 `appBar: const AntiqueAppBar(`，并把 `title: Text('...')` 改为 `title: '...'`，删除 `centerTitle: true`（antique 默认居中）。
如果有 `backgroundColor: ...` 直接删除（antique 自带渐变）。
如果有 Stack + gradient Container 的嵌套，整个 Stack 可以删除，用 AntiqueScaffold 替代。

在顶部 imports 加：
```dart
import '../../widgets/antique/antique.dart';
```

- [ ] **Step 3: 替换硬编码色（如有）**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && grep -n 'Color(0xFF' lib/presentation/screens/result/result_screen.dart`

按"通用迁移模式 / 色值替换"规则替换所有匹配。

- [ ] **Step 4: 编译和测试**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && flutter analyze lib/presentation/screens/result/result_screen.dart && flutter test`
Expected: No issues, all tests pass.

- [ ] **Step 5: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/result/result_screen.dart
git commit -m "refactor(result): migrate result screen to antique scaffold"
```

---

## Task 3: liuyao_ui_factory.dart 迁移

**背景:** 311 行。结构和 Plan A 迁移过的 `daliuren_ui_factory.dart` 类似：包含 `_LiuYaoResultScreenWithAI` 私有 Scaffold wrapper、`buildHistoryCard` 返回 `Card`、`buildSystemCard` 返回 intro Card。2 个 Card、7 个 TextStyle、1 个 Color literal、1 个 withOpacity。

迁移模式参照 Plan A Task 16（DLR）。

**Files:**
- Modify: `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`

- [ ] **Step 1: 读文件，识别所有迁移点**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && cat lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart | head -320`

并跑：
```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Scaffold|AppBar|\bCard\b|ElevatedButton|TextField|DropdownButton|Color\(0xFF' lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
```

记录每个匹配的行号和上下文，形成改造清单。

- [ ] **Step 2: 添加 imports**

在文件顶部 imports 区域添加：
```dart
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/antique/antique.dart';
```

- [ ] **Step 3: 替换 `_LiuYaoResultScreenWithAI` 的 Scaffold**

在 `_LiuYaoResultScreenWithAI.build` 内：

找到 `return Scaffold(appBar: AppBar(title: Text('...'), ...), body: ...)` 替换为：
```dart
return AntiqueScaffold(
  appBar: const AntiqueAppBar(title: '<原标题文本>'),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: <原 body 内容>,
    ),
  ),
);
```

如果原 body 已经是 SingleChildScrollView 或 ListView，保留不重复包装。

- [ ] **Step 4: 替换 `buildHistoryCard` 内的 Card**

找到 `return Card(...)` 替换为 `return AntiqueCard(onTap: ..., child: ...)`。历史卡片一般可点击，把点击回调传给 `onTap`（原 `InkWell/GestureDetector` 包装可删除，AntiqueCard 自带按压反馈）。

如果有 `Theme.of(context).textTheme.*` 或硬编码 TextStyle 作为标题，替换为 `AntiqueSectionTitle(title: ...)` 或 `Text(..., style: AppTextStyles.antiqueTitle)`。

- [ ] **Step 5: 替换 `buildSystemCard` 内的 intro Card**

同 Step 4 模式。

- [ ] **Step 6: 替换硬编码色和 TextStyle**

按"通用迁移模式 / 色值替换"规则替换所有 `Color(0xFFXXXXXX)`。

对内联 `TextStyle(...)`，判断用途：
- 标题级 → `AppTextStyles.antiqueTitle`
- 节标题 → `AppTextStyles.antiqueSection`
- 正文 → `AppTextStyles.antiqueBody`
- 标签 → `AppTextStyles.antiqueLabel`

- [ ] **Step 7: 验证**

Run: 
```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Color\(0xFF[0-9A-Fa-f]{6}\)' lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
```
Expected: 0 matches。

Run:
```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/divination_systems/liuyao/
flutter test
```
Expected: analyze 绿，测试全通过。

- [ ] **Step 8: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
git commit -m "refactor(liuyao): migrate liuyao UI factory to antique components"
```

---

## Task 4: unified_cast_screen.dart 迁移

**背景:** 400 行，12 个硬编码 `Color(0xFFXXXXXX)` literal，2 个 `withOpacity`，6 个硬编码 TextStyle。结构：LinearGradient + Stack 背景、switch-based cast section 切换、TextField + DropdownButton 表单。

**Files:**
- Modify: `lib/presentation/screens/cast/unified_cast_screen.dart`

- [ ] **Step 1: 识别所有迁移点**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Scaffold|AppBar|Stack|gradient|\bCard\b|ElevatedButton|TextField|DropdownButton|Color\(0xFF|withOpacity' lib/presentation/screens/cast/unified_cast_screen.dart
```

- [ ] **Step 2: 添加 imports**

```dart
import '../../widgets/antique/antique.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
```

- [ ] **Step 3: 替换主 Scaffold + Stack 背景**

找到外层 `Scaffold(body: Stack([Container(decoration: BoxDecoration(gradient: LinearGradient(...))), ...]))` 结构，替换为：

```dart
return AntiqueScaffold(
  showCompass: true,  // 起卦页罗盘底
  appBar: const AntiqueAppBar(title: '<原标题>'),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: <原 Column 内容>,
    ),
  ),
);
```

整个 Stack 和 gradient Container 删除，AntiqueScaffold 自带。如果原来有 `Center(child: CompassBackground())` 也删除（AntiqueScaffold 的 showCompass 会自动加）。

- [ ] **Step 4: 替换问题输入 TextField**

找到占问输入的 `Container + TextField` 结构，替换为：

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('占问事项', style: AppTextStyles.antiqueLabel),
    const SizedBox(height: 6),
    AntiqueTextField(
      controller: <原 controller>,
      hint: '<原 hintText>',
      maxLines: 2,
      minLines: 1,
    ),
  ],
)
```

- [ ] **Step 5: 替换起卦方式 Dropdown**

找到起卦方式选择的 `Container + DropdownButton<CastMethod>` 结构，替换为：

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('起卦方式', style: AppTextStyles.antiqueLabel),
    const SizedBox(height: 6),
    AntiqueDropdown<CastMethod>(
      value: <原 _selectedMethod>,
      items: <原 items 列表>.map((method) => AntiqueDropdownItem<CastMethod>(
        value: method,
        label: <原 label 计算>,
      )).toList(),
      onChanged: <原 onChanged>,
    ),
  ],
)
```

- [ ] **Step 6: 替换起卦按钮**

找到起卦/确认 `ElevatedButton` 或自定义 GestureDetector 按钮，替换为：

```dart
AntiqueButton(
  label: <原 label>,
  onPressed: <原 onPressed>,
  variant: AntiqueButtonVariant.primary,
  fullWidth: true,
),
```

如果原按钮有 loading spinner 逻辑（`_isLoading ? CircularProgressIndicator : Text`），简化为 `label: _isLoading ? '起卦中...' : '起卦'` + `onPressed: _isLoading ? null : _handleCast`。

- [ ] **Step 7: 替换硬编码色**

按"通用迁移模式 / 色值替换"规则替换全部 12 个 `Color(0xFFXXXXXX)`。

- [ ] **Step 8: 替换硬编码 TextStyle**

6 个 inline TextStyle，按用途映射：
- 大标题 → `AppTextStyles.antiqueTitle`
- 节标题 → `AppTextStyles.antiqueSection`
- 正文 → `AppTextStyles.antiqueBody`
- 标签/提示 → `AppTextStyles.antiqueLabel`

- [ ] **Step 9: 验证**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Color\(0xFF[0-9A-Fa-f]{6}\)' lib/presentation/screens/cast/unified_cast_screen.dart
```
Expected: 0 matches。

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/cast/
flutter test
```
Expected: 绿。

- [ ] **Step 10: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/cast/unified_cast_screen.dart
git commit -m "refactor(cast): migrate unified cast screen to antique components"
```

---

## Task 5: home_screen.dart 迁移

**背景:** 339 行，使用 `AnimatedSwitcher` + StatefulWidget 管理 4 个 tab (Home, History, Calendar, Profile)，所以有 3 个 Scaffold + 3 个 AppBar。主首页区包含 GridView (Bento 卡片) + 底部导航条。5 个硬编码 TextStyle，0 个 Color literal（已用 AppColors.*）。

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: 识别所有迁移点**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Scaffold|AppBar|\bCard\b|TextStyle\(|Color\(0xFF|withOpacity' lib/presentation/screens/home/home_screen.dart
```

- [ ] **Step 2: 添加 imports**

```dart
import '../../widgets/antique/antique.dart';
```

- [ ] **Step 3: 替换每个 Scaffold 实例**

识别每个 `Scaffold(appBar: AppBar(...), body: ...)`：
- 主首页 Scaffold：`AntiqueScaffold(appBar: const AntiqueAppBar(title: '万象排盘'), watermarkChar: '<当前年支字>', body: ..., bottomNavigationBar: ...)`
- 其他 tab 页 Scaffold：按各自场景决定是否需要 watermark/compass

**水印字获取：** 从 `TianGanDiZhiService`（或 `LunarService`）拿当前年支字。大致代码：
```dart
final yearZhi = Lunar.fromDate(DateTime.now()).getYearZhi(); // "辰"
```

如果 `TianGanDiZhiService` 已封装，调用对应方法。

- [ ] **Step 4: 替换每个 AppBar**

`AppBar(title: Text('X'), actions: [...], centerTitle: true)` → `AntiqueAppBar(title: 'X', actions: [...])`

删除 `centerTitle`（antique 默认 true）和 `backgroundColor`（antique 透明）。

- [ ] **Step 5: 替换 Bento 网格卡片**

术数矩阵的每个术数卡片（调用 `DivinationSystemCard` 或类似）内部如果使用 `Container(decoration: BoxDecoration(...)) + GestureDetector`，判断：
- 如果卡片有点击：`AntiqueCard(onTap: ..., child: ...)` 包装
- 如果 `DivinationSystemCard` 本身是独立组件，改它的内部实现（单独任务），此处不动

**侦测:** 查 `lib/presentation/widgets/divination_system_card.dart`（如存在），如果它用 `Container` + 手工装饰，把它 repurpose 为 `AntiqueCard` 包装。这是共享组件，仅一次改动即可影响所有卡片。

- [ ] **Step 6: 替换 TextStyle**

5 个硬编码 TextStyle，按用途映射到 `AppTextStyles.antique*`。

- [ ] **Step 7: 底部导航**

如果 `BottomNavigationBar` 用的是 Material 默认 + 自定义 theme（`app_theme.dart` 已配置 xiangseLight 背景 + dailan 主色），可以暂时不动，Plan B 的目标是页面结构仿古化，导航栏微调可放 Plan C。

但如果有自定义 60px 高的 custom 导航栏（指导文档 §4 提及），确认其颜色/选中态走 `AppColors` token。

- [ ] **Step 8: 验证**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/home/
flutter test
```
Expected: 绿。

- [ ] **Step 9: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/home/home_screen.dart
git commit -m "refactor(home): migrate home screen to antique scaffold with year-zhi watermark"
```

---

## Task 6: history_list_screen.dart 迁移

**背景:** 326 行。3 Scaffold + 1 AppBar。使用 `DivinationUIRegistry.buildHistoryCard(record)` 委托给每个系统的 UI 工厂渲染卡片（六爻、大六壬各自提供），只有 fallback 路径用 Material `Card`。3 个硬编码 TextStyle。

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart`

- [ ] **Step 1: 识别迁移点**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Scaffold|AppBar|\bCard\b|TextStyle\(|Color\(0xFF' lib/presentation/screens/history/history_list_screen.dart
```

- [ ] **Step 2: 添加 imports + 替换主 Scaffold**

```dart
import '../../widgets/antique/antique.dart';
```

主 `Scaffold(appBar: AppBar(title: Text('历史记录')), body: ListView.builder(...))` → `AntiqueScaffold(appBar: const AntiqueAppBar(title: '历史记录'), body: ListView.builder(...))`

- [ ] **Step 3: 迁移 pop-up menu / nested Scaffolds**

如有 `showDialog(Scaffold(...))` 或 `Navigator.push(MaterialPageRoute(Scaffold(...)))` 嵌套结构，各自 Scaffold → AntiqueScaffold。

- [ ] **Step 4: 替换 fallback `_buildDefaultCard`**

找到 `_buildDefaultCard(record)` 方法内的 `Card(child: ...)` 替换为 `AntiqueCard(onTap: ..., child: ...)`。

注意：这是 fallback 路径——六爻/大六壬走各自 UI 工厂的 `buildHistoryCard`（T3 处理六爻的）；这里只管没匹配工厂时的兜底。

- [ ] **Step 5: 替换 TextStyle**

3 个硬编码 TextStyle → `AppTextStyles.antique*`。

- [ ] **Step 6: 空态 UI**

如果有空状态（无历史记录时的提示），考虑加 `AntiqueWatermark(char: '空')` 或类似轻装饰。如果原来只是一个 Text，保留即可，加装饰非必要。

- [ ] **Step 7: 验证 + Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "refactor(history): migrate history list to antique scaffold and cards"
```

---

## Task 7: settings_screen.dart 迁移

**背景:** 149 行。最简单：Scaffold + AppBar + ListTile 列表。1 个 `Theme.of(context).textTheme.titleSmall`。无硬编码色。

**Files:**
- Modify: `lib/presentation/screens/settings/settings_screen.dart`

- [ ] **Step 1: 替换 Scaffold + AppBar**

```dart
import '../../widgets/antique/antique.dart';
```

`Scaffold(appBar: AppBar(title: Text('设置')), body: ListView(children: [...ListTile...]))` → `AntiqueScaffold(appBar: const AntiqueAppBar(title: '设置'), body: ListView(children: [...]))`

- [ ] **Step 2: ListTile → AntiqueCard 改造**

每个 `ListTile(title: Text('X'), leading: Icon(...), trailing: Icon(Icons.chevron_right), onTap: ...)` 替换为：

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  child: AntiqueCard(
    onTap: onTap,
    child: Row(
      children: [
        Icon(iconData, color: AppColors.zhusha, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTextStyles.antiqueBody),
        ),
        Icon(Icons.chevron_right, color: AppColors.guhe, size: 20),
      ],
    ),
  ),
)
```

考虑提取一个局部 helper `_buildSettingItem(IconData icon, String title, VoidCallback onTap)` 减少重复。

- [ ] **Step 3: 分组标题**

如果有分组标题（如"一般"、"AI 设置"等），替换为 `Padding + AntiqueSectionTitle(title: 'X')`。

- [ ] **Step 4: 验证 + Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/settings/
flutter test
git add lib/presentation/screens/settings/settings_screen.dart
git commit -m "refactor(settings): migrate settings screen to antique components"
```

---

## Task 8: ai_settings_screen.dart 迁移

**背景:** 682 行。最复杂的页面：4 个 Card、14 个硬编码 TextStyle、4 个 withOpacity、嵌套的 `_TemplateEditorScreen`。表单验证、下拉、模型 fetch 等交互逻辑。

**Files:**
- Modify: `lib/presentation/screens/settings/ai_settings_screen.dart`

鉴于复杂度，拆成 3 个子步骤：

### 8A: 主 AI Settings 页面

- [ ] **Step 1: 识别所有迁移点**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE 'Scaffold|AppBar|\bCard\b|TextField|DropdownButton|ElevatedButton|TextStyle\(|Color\(0xFF|withOpacity' lib/presentation/screens/settings/ai_settings_screen.dart
```

- [ ] **Step 2: 添加 imports + 替换主 Scaffold**

```dart
import '../../widgets/antique/antique.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
```

- [ ] **Step 3: 替换 4 个 Card**

每个 `Card(elevation: ..., child: Padding(padding, child: Column(...)))` → `AntiqueCard(child: Column(...))`。删除 elevation 和 padding（AntiqueCard 默认 padding 16）。

- [ ] **Step 4: 替换表单 TextField**

每个 `TextField(controller, decoration: InputDecoration(labelText, ...))` → 
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('<labelText>', style: AppTextStyles.antiqueLabel),
    const SizedBox(height: 6),
    AntiqueTextField(
      controller: <controller>,
      hint: '<hintText>',
      maxLines: <如有>,
    ),
  ],
)
```

- [ ] **Step 5: 替换 DropdownButton（模型选择器）**

参照 T4 Step 5 模式，转为 `AntiqueDropdown<String>` 结构。

- [ ] **Step 6: 替换按钮（保存/测试/刷新模型等）**

每个 `ElevatedButton` → `AntiqueButton(variant: primary)`；次要按钮用 `variant: ghost`；删除按钮用 `variant: danger`。

- [ ] **Step 7: 替换 14 个 TextStyle**

按用途映射。

- [ ] **Step 8: 验证主页面**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/settings/
flutter test
```

### 8B: 嵌套 `_TemplateEditorScreen`

- [ ] **Step 9: 识别 `_TemplateEditorScreen` 边界**

这是同文件内的另一个 StatefulWidget，有自己的 Scaffold。

- [ ] **Step 10: 替换其 Scaffold + AppBar**

```dart
return AntiqueScaffold(
  appBar: AntiqueAppBar(
    title: <原 title>,
    actions: [<保存/取消 action>],
  ),
  body: <原 body>,
);
```

- [ ] **Step 11: 替换内部 TextField (prompt 模板编辑器)**

通常是 multi-line `TextField`：
```dart
AntiqueTextField(
  controller: <controller>,
  hint: '请输入提示词模板...',
  maxLines: null,  // 或具体数值
  minLines: 10,
)
```

注意：`AntiqueTextField` 当前的 `maxLines: int` 参数不接受 `null`。如果需要无限行，**需要先扩展 `AntiqueTextField`** 允许 `int?` 类型的 maxLines。

**处理路径（先扩展组件）：**

```dart
// antique_text_field.dart
class AntiqueTextField extends StatelessWidget {
  const AntiqueTextField({
    // ...
    this.maxLines = 1,  // 改为 this.maxLines = 1 保留默认但接受 null
    // 改为 int? maxLines
  });
  
  final int? maxLines;  // 改为可空
  // ...
}
```

这是 Plan B 需要的真实组件扩展——先加扩展 commit，再用。

### 8C: Commit 8A + 8B

- [ ] **Step 12: 扩展 AntiqueTextField 支持 maxLines: null**

Edit `lib/presentation/widgets/antique/antique_text_field.dart`:
- `this.maxLines = 1` 保留
- 类型从 `final int maxLines` 改为 `final int? maxLines`

对应测试如无崩溃保持不变；如果需要补一个 `maxLines: null` 测试，加一个 widget test。

Commit:
```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/widgets/antique/antique_text_field.dart test/presentation/widgets/antique/antique_text_field_test.dart
git commit -m "feat(antique): allow null maxLines on AntiqueTextField for multiline editors"
```

- [ ] **Step 13: Commit AI settings 主页 + 嵌套编辑器迁移**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/settings/ai_settings_screen.dart
git commit -m "refactor(ai-settings): migrate AI settings and template editor to antique components"
```

---

## Task 9: test_screen.dart 迁移

**背景:** 154 行。dev 调试工具，未上架。1 Scaffold + 1 AppBar + Container（边框 only）+ 1 硬编码 TextStyle。低优先级。

**Files:**
- Modify: `lib/presentation/screens/test/test_screen.dart`

- [ ] **Step 1: Scaffold + AppBar 替换**

```dart
import '../../widgets/antique/antique.dart';

// Scaffold → AntiqueScaffold
// AppBar → AntiqueAppBar(title: '测试')
```

- [ ] **Step 2: 边框 Container → AntiqueCard**

存放输出的带边框 Container → `AntiqueCard(child: ...)`。

- [ ] **Step 3: 测试按钮**

如果有若干 ElevatedButton 触发测试，每个 → `AntiqueButton`。

- [ ] **Step 4: 验证 + Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test
git add lib/presentation/screens/test/test_screen.dart
git commit -m "refactor(test): migrate dev test screen to antique scaffold"
```

---

## Task 10: 更新 docs/UI设计指导.md

**背景:** Spec §6 要求把旧的"新中式极简"指导文档替换为仿古风规范，与实际代码同步。

**Files:**
- Modify: `docs/UI设计指导.md`

- [ ] **Step 1: 读原文档**

Run: `cat docs/UI设计指导.md`

- [ ] **Step 2: 重写对应章节**

按以下结构更新（保留文档整体目录，只改内容）：

**1. 设计主题**：
- 原：新中式极简 + 科技秩序感
- 新：仿古风（书房/案头隐喻）+ 现代秩序感

**2. 色彩体系**：

列出完整 9+4=13 个 token：
```
zhusha           #C94A4A — 朱砂红（主强调、按钮、章印）
zhushaLight      #E07070 — 浅朱砂（按钮渐变浅端）
zhushaDeep       #B23A3A — 深朱砂（危险按钮渐变起色）
errorDeep        #8B2020 — 栗色（错误/警告深色）
danjin           #D4B896 — 淡金（边框、分割线）
danjinDeep       #B79452 — 深淡金（罗盘环、印章边）
guhe             #8B7355 — 古褐（次要文字、标签）
xuanse           #2C2C2C — 玄色（正文）
qianhe           #A0937E — 浅褐（placeholder）
xiangse          #F7F7F5 — 缃色（背景顶）
xiangseDeep      #F0EDE8 — 缃色深（背景底）
biyongBlue       #3A6EA5 — 比用蓝（大六壬课型指示）
jishenGreen      #4A7C59 — 吉神绿（神煞吉神标识）
```

**3. 字体**：
- 原："标题思源宋体，数字正文 Roboto/PingFang SC"
- 新：全量思源宋体（Noto Serif SC）。决策原因：仿古调性整体性优先，以预留可读性回退（§7 风险预案）。

**4. 组件库引用**：新增章节，列出 `lib/presentation/widgets/antique/` 的 10 个组件及各自用途：

| 组件 | 用途 | 典型场景 |
|---|---|---|
| AntiqueScaffold | 页面骨架（缃色渐变 + 可选罗盘/水印） | 所有页面根 |
| AntiqueAppBar | 透明 AppBar + 底部淡金分割线 | 所有 AppBar |
| AntiqueCard | 半透明白卡 + 淡金边 | 替代 Material Card |
| AntiqueSectionTitle | 朱砂衬线节标题 | 每个 section 头 |
| AntiqueDivider | 淡金细分割线 | section 间分割 |
| AntiqueButton | primary/ghost/danger 胶囊按钮 | 所有 ElevatedButton |
| AntiqueTextField | 半透明白底 + 淡金边输入框 | 所有 TextField |
| AntiqueDropdown | 淡金边 + 朱砂箭头下拉 | 所有 DropdownButton |
| AntiqueTag | 低透明色块标签 | 分类/状态标签 |
| AntiqueWatermark | 小印章水印 | 历史/设置等轻装饰 |

**5. 其余章节**（布局分布、具体 UI 描述、微动效、总结）保留原文思路，只把色板引用更新到新 token 名。

- [ ] **Step 3: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add docs/UI设计指导.md
git commit -m "docs(ui-guide): update design guide from 新中式极简 to 仿古风

Align with Plan A+B implementation: new 13-token palette,
full-serif typography, reference to antique component library."
```

---

## Task 11: 全量验证

**背景:** 9 个文件迁移后，需要验证主线流程无回归。

- [ ] **Step 1: 跑完整测试套件**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter test 2>&1 | tail -5
```
Expected: 264 tests (或更多，如果 Plan B 加了新测试) 全通过。

- [ ] **Step 2: flutter analyze 全项目**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: 全文件硬编码色扫描（确保没漏）**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rnE 'Color\(0xFF[0-9A-Fa-f]{6}\)' lib/presentation/ lib/divination_systems/liuyao/ 2>/dev/null
```
Expected: 0 matches（或只有领域色 DLR TransmissionCircle 等有意保留的）。

**注意扫描范围包含 `lib/presentation/widgets/`** —— `DiagramComparisonRow`、`YaoDisplay`、`GuaCard` 等被 `result_screen.dart` 和六爻工厂调用的内容 widget 可能仍有硬编码样式。每个匹配：
- 若是页面无关的纯视觉色，加 AppColors token 并替换
- 若是系统专属语义色（如六亲颜色），评估加 token 还是保留内联+注释
- 若是 `AppColors.*` 已有的色但硬编码了（e.g. `Color(0xFFC94A4A)` 而不是 `AppColors.zhusha`），直接换 token

如果有残留，逐个评估并修复；修复 commit 单独一条，不要和别的混。

- [ ] **Step 4: 模拟器手工走查**

> **前置:** 用户已开好模拟器（memory feedback_emulator.md），直接 `flutter run`。

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && flutter run`

走完整流程：
- [ ] 首页：缃色渐变、水印字（今年年支）、Bento 卡片按压反馈正常
- [ ] 选择系统（六爻/大六壬）→ 统一起卦页：罗盘底、起卦方式下拉、问题输入框、起卦按钮
- [ ] 起卦 → 结果页：所有 section 用 AntiqueCard、标题 AntiqueSectionTitle、滑动顺畅
- [ ] 历史记录列表：每条卡片仿古样式，点击按压反馈
- [ ] 设置页：列表项仿古卡片
- [ ] AI 设置页：表单、下拉、按钮全仿古
- [ ] AI 模板编辑：多行文本框正常，保存/取消按钮正常

主观验证：风格连贯，无 Material 默认样式泄漏，无颜色突兀。

- [ ] **Step 5: 最终 commit（如有修补）**

如果手工走查发现问题并修复，按常规 commit。如果无问题，跳过。

---

## 完成标志

1. ✅ `lib/presentation/screens/` 下 8 个文件都改用 `AntiqueScaffold`/`AntiqueAppBar` 等组件，无遗漏 Material `Scaffold`/`AppBar` 直接使用
2. ✅ `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart` 完成对标 Plan A DLR 迁移
3. ✅ `cast_method_screen.dart` 已删除
4. ✅ 所有硬编码 `Color(0xFFXXXXXX)` 字面量替换为 `AppColors.*` token（少数有意保留的领域色例外，需注释说明）
5. ✅ 所有硬编码 `TextStyle(...)` 作为标题/节标题/正文/标签用途时，替换为 `AppTextStyles.antique*`
6. ✅ `docs/UI设计指导.md` 与 spec §6 一致
7. ✅ `flutter analyze` 无 issue
8. ✅ `flutter test` 全通过
9. ✅ 模拟器手工走查主线流程视觉一致、无回归

---

## 范围外（留给 Plan C/未来）

- 暗黑模式（spec §9）
- 卡片 staggered 载入动画、呼吸动效
- HapticFeedback 接入
- 紫微斗数、奇门遁甲 UI 工厂实现
- 全量 golden test 覆盖（P0 页面逐页 golden）
- 无障碍（a11y）Semantics 统一加护
- `DivinationUIFactory` 架构泛化让 `result_screen.dart` 真正通用（目前仍六爻专用）
- 未使用的 `AppColors.accentGradient/cardGradient/primaryGradient` 清理（Plan A 评审员 M1 标记）
