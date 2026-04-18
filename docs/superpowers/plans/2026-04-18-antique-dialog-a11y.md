# AntiqueDialog + A11y 实施计划（Plan C2）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补齐仿古风组件库两块缺失：
1. 新增 `AntiqueDialog` 组件，替换现有 2 处 Material 对话框
2. 给 10 个 antique 原子组件补 `Semantics` 无障碍标签

**Architecture:** TDD 新建 `AntiqueDialog` + `showAntiqueDialog` helper → 迁移 2 处 caller → 逐组件加 Semantics wrapper + widget test 验证 a11y 树。

**Tech Stack:** Flutter 3.38.5, antique design system（Plan A/B/C1 就绪）。

**前置:** Plan A / B / C1 已落地、`main` 同步到 origin（commit `0a91501`）。

---

## 范围

### 新增
- `lib/presentation/widgets/antique/antique_dialog.dart` — 组件 + `showAntiqueDialog()` helper
- `test/presentation/widgets/antique/antique_dialog_test.dart`

### 迁移
- `lib/presentation/screens/history/history_list_screen.dart:105-116` — 删除确认 `AlertDialog`
- `lib/presentation/screens/settings/settings_screen.dart:177-185` — `showAboutDialog`（**评估后决定**：默认行为复杂、替换收益低，可保留不动；若简单可替换则替换）

### Semantics 补护（10 组件）
- `antique_app_bar.dart` — 标题 `header: true`
- `antique_button.dart` — `button: true, enabled: !disabled, label: label`
- `antique_card.dart` — 有 `onTap` 时 `button: true`，无 `onTap` 时透明
- `antique_dropdown.dart` — `enabled: true, label: selected label`（下拉选择的语义）
- `antique_section_title.dart` — `header: true`
- `antique_tag.dart` — `label: text`
- `antique_text_field.dart` — 底层 `TextField` 已有 a11y，可能只需 `excludeSemantics` 包装避免重复；或 forward `semanticsLabel`
- `antique_watermark.dart` — `excludeSemantics: true`（装饰性，不应读）
- `antique_divider.dart` — 无需（已是 `Divider`，Flutter 自带）
- `antique_scaffold.dart` — 无需（外壳，转发给 child）

### barrel export
- `antique.dart` 加 `antique_dialog.dart` export

---

## Task 1: 设计并实现 AntiqueDialog 组件

**Files:**
- Create: `lib/presentation/widgets/antique/antique_dialog.dart`
- Test: `test/presentation/widgets/antique/antique_dialog_test.dart`

TDD 严格：先测 → 看失败 → 实现 → 看通过 → commit。

### API 设计

```dart
class AntiqueDialog extends StatelessWidget {
  const AntiqueDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
}

Future<T?> showAntiqueDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget> actions = const [],
  bool barrierDismissible = true,
});
```

### 视觉规格

- 外层 `Dialog(backgroundColor: transparent, ...)` 包一个定制 Container
- 容器：`Colors.white.withOpacity(0.95)` 底 + `AppColors.danjin` 1px 边 + 12px 圆角（比 AntiqueCard 的 8px 稍大，强调弹出层质感）
- 内边距：20px 四周
- 标题区：顶部 `AntiqueSectionTitle(title: ...)` + 下方 `AntiqueDivider()`
- 内容区：中间 `content` widget（caller 传入）
- 操作区：底部 `Row(mainAxisAlignment: .end, children: actions)`，各 action 之间 `SizedBox(width: 8)`
- 最大宽度：`MediaQuery.size.width * 0.85`，最小 280，最大 480

### Step 1: 写失败测试

```dart
// test/presentation/widgets/antique/antique_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_dialog.dart';

void main() {
  group('AntiqueDialog', () {
    testWidgets('renders title and content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueDialog(
              title: '确认删除',
              content: Text('删除后无法恢复'),
            ),
          ),
        ),
      );
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('删除后无法恢复'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueDialog(
              title: 'X',
              content: const SizedBox(),
              actions: [
                TextButton(
                  key: const Key('cancel'),
                  onPressed: () {},
                  child: const Text('取消'),
                ),
                TextButton(
                  key: const Key('confirm'),
                  onPressed: () {},
                  child: const Text('确认'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('cancel')), findsOneWidget);
      expect(find.byKey(const Key('confirm')), findsOneWidget);
    });

    testWidgets('showAntiqueDialog returns value from popped action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showAntiqueDialog<bool>(
                    context: context,
                    title: '确认',
                    content: const Text('ok?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('是'),
                      ),
                    ],
                  );
                  expect(result, true);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('确认'), findsOneWidget);
      await tester.tap(find.text('是'));
      await tester.pumpAndSettle();
      // The expectation inside onPressed runs after this
    });
  });
}
```

### Step 2: 跑测试看失败

Run: `flutter test test/presentation/widgets/antique/antique_dialog_test.dart`
Expected: fail — `Target of URI doesn't exist`.

### Step 3: 实现组件

```dart
// lib/presentation/widgets/antique/antique_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';
import 'antique_divider.dart';
import 'antique_section_title.dart';

/// 仿古风对话框：半透明白底 + 淡金边 + 朱砂标题。
class AntiqueDialog extends StatelessWidget {
  const AntiqueDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final clampedWidth = width.clamp(280.0, 480.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: clampedWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: Border.all(
            color: AppColors.danjin,
            width: AntiqueTokens.borderWidthBase,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AntiqueSectionTitle(title: title),
            const AntiqueDivider(),
            const SizedBox(height: 12),
            content,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 便利函数：展示 AntiqueDialog 并等待返回值。
Future<T?> showAntiqueDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget> actions = const [],
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AntiqueDialog(
      title: title,
      content: content,
      actions: actions,
    ),
  );
}
```

### Step 4: 跑测试看通过

Run: `flutter test test/presentation/widgets/antique/antique_dialog_test.dart`
Expected: all 3 tests pass.

### Step 5: 加入 barrel

Edit `lib/presentation/widgets/antique/antique.dart`，添加：

```dart
export 'antique_dialog.dart';
```

### Step 6: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/widgets/antique/antique_dialog.dart lib/presentation/widgets/antique/antique.dart test/presentation/widgets/antique/antique_dialog_test.dart
git commit -m "feat(antique): add AntiqueDialog component with showAntiqueDialog helper"
```

---

## Task 2: 迁移 history 页删除确认对话框

**Files:**
- Modify: `lib/presentation/screens/history/history_list_screen.dart:105-116`

### Step 1: 读原代码确认结构

Run: `sed -n '100,120p' lib/presentation/screens/history/history_list_screen.dart`

应该看到类似：
```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('确认删除'),
    content: const Text('...'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
    ],
  ),
);
```

### Step 2: 替换为 showAntiqueDialog

```dart
final confirmed = await showAntiqueDialog<bool>(
  context: context,
  title: '确认删除',
  content: const Text('<原 content 文本>', style: AppTextStyles.antiqueBody),
  actions: [
    AntiqueButton(
      label: '取消',
      variant: AntiqueButtonVariant.ghost,
      onPressed: () => Navigator.pop(context, false),
    ),
    AntiqueButton(
      label: '删除',
      variant: AntiqueButtonVariant.danger,
      onPressed: () => Navigator.pop(context, true),
    ),
  ],
);
```

注意：`AntiqueButton` 默认 `fullWidth: false`，适合 dialog 内。danger 变体用于"删除"动作。

### Step 3: 验证 imports

顶部 imports 应已包含 `antique/antique.dart` 和 `app_text_styles.dart`（Plan B 迁移时加的）。如果没有，加上。

### Step 4: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/history/
flutter test 2>&1 | tail -3
```

Expected: No issues; all tests pass.

### Step 5: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/history/history_list_screen.dart
git commit -m "refactor(history): migrate delete confirmation to AntiqueDialog"
```

---

## Task 3: 评估并处理 settings about dialog

**Files:**
- Modify: `lib/presentation/screens/settings/settings_screen.dart:177-185`（可选）

### Step 1: 读当前实现

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
sed -n '170,195p' lib/presentation/screens/settings/settings_screen.dart
```

`showAboutDialog` 是 Flutter 内置，展示 app 名称、版本、legal 按钮（显示 license），默认 Material 样式。

### Step 2: 评估路径

**A. 保留 `showAboutDialog`**：它自带 `applicationLegalese` 和 license 页，用户习惯 Material 样式，替换收益低。

**B. 替换为 `showAntiqueDialog`**：视觉一致，但丢失 license 入口（除非手动加）。

**选 A**：保留不动，只在 dialog 弹出前注入 `applicationIcon` 如已有仿古风 logo。这步不强制，观察即可。

**选 B 情况下的代码**：
```dart
await showAntiqueDialog<void>(
  context: context,
  title: '关于',
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('万象排盘', style: AppTextStyles.antiqueTitle),
      Text('v$version', style: AppTextStyles.antiqueLabel),
      const SizedBox(height: 8),
      Text('多术数系统平台', style: AppTextStyles.antiqueBody),
    ],
  ),
  actions: [
    AntiqueButton(
      label: '关闭',
      variant: AntiqueButtonVariant.ghost,
      onPressed: () => Navigator.pop(context),
    ),
  ],
);
```

### Step 3: 决策

**默认选 A**（保留），**除非** implementer 判断替换非常简单且不丢 license 功能。

如果选 A，跳过 Step 4/5，本 Task 标记为 DONE_WITH_CONCERNS，说明"保留 showAboutDialog 以保留 license 入口"。

如果选 B，应用替换 + verify + commit:

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/settings/settings_screen.dart
git commit -m "refactor(settings): migrate about dialog to AntiqueDialog"
```

---

## Task 4: 给 10 个 antique 组件补 Semantics

**Files:**
- Modify: 每个 `lib/presentation/widgets/antique/antique_*.dart`
- Modify: 对应的 `test/presentation/widgets/antique/antique_*_test.dart`

### 规则总览

| 组件 | Semantics 属性 | 传入来源 |
|---|---|---|
| AntiqueAppBar | `header: true` wrap 标题 | 组件内 hardcoded |
| AntiqueButton | `button: true, enabled: !disabled, label: label` | 组件内，用 `label` 属性 |
| AntiqueCard | `button: true, label: semanticsLabel` 仅当 `onTap != null` | 新增可选 `semanticsLabel` 属性 |
| AntiqueDropdown | `button: true, label: 'Dropdown: $selectedLabel'` | 组件内，根据当前 value 算 |
| AntiqueSectionTitle | `header: true` wrap title | 组件内 |
| AntiqueTag | `label: text` | 组件内 |
| AntiqueTextField | 透传 Flutter 内置（TextField 自带 a11y），加 `semanticsLabel` 可选属性转发到 TextField | 新增可选 `semanticsLabel` 属性 |
| AntiqueWatermark | `excludeSemantics: true` 包装 | 组件内强制 |
| AntiqueDialog | `namesRoute: true, scopesRoute: true, explicitChildNodes: true` 外包装 | 组件内 |
| AntiqueDivider | 不需要 | Flutter Divider 自身 OK |
| AntiqueScaffold | 不需要 | 外壳，子组件各自负责 |

### Step 1: 修改 AntiqueAppBar

包 title 在 `Semantics(header: true, child: Text(...))`.

```dart
title: Semantics(
  header: true,
  child: Text(
    title,
    style: AppTextStyles.antiqueTitle.copyWith(color: AppColors.xuanse),
  ),
),
```

### Step 2: 修改 AntiqueButton

最外层用 `Semantics(button: true, enabled: !disabled, label: label)` 替代/包装 GestureDetector：

```dart
return Semantics(
  button: true,
  enabled: !disabled,
  label: label,
  excludeSemantics: true, // 避免内部 Text 再被读一次
  child: GestureDetector(
    onTap: disabled ? null : onPressed,
    child: Opacity(...),
  ),
);
```

### Step 3: 修改 AntiqueCard

添加可选 `semanticsLabel` 属性：

```dart
class AntiqueCard extends StatefulWidget {
  const AntiqueCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  ...
}
```

build 里，当 `onTap != null`，包 `Semantics(button: true, label: semanticsLabel, child: ...)`；否则透传。

### Step 4: 修改 AntiqueDropdown

build 里用 `Semantics(button: true, label: 'Dropdown: $currentLabel', child: ...)` 包外层 Container：

```dart
final currentLabel = items
    .firstWhere((item) => item.value == value, orElse: () => items.first)
    .label;

return Semantics(
  button: true,
  label: '下拉选择: $currentLabel',
  excludeSemantics: true,
  child: Container(...),
);
```

### Step 5: 修改 AntiqueSectionTitle

包 title Text：

```dart
Text(title, style: AppTextStyles.antiqueSection),
```

改为：

```dart
Semantics(
  header: true,
  child: Text(title, style: AppTextStyles.antiqueSection),
),
```

### Step 6: 修改 AntiqueTag

最外层 Container 包 `Semantics(label: label, child: Container(...))`。

### Step 7: 修改 AntiqueTextField

添加可选 `semanticsLabel` 属性，转发到内层 TextField（TextField 支持 `decoration: InputDecoration(labelText: ...)`，或者更准确用 `Semantics` 包）：

```dart
class AntiqueTextField extends StatelessWidget {
  const AntiqueTextField({
    super.key,
    ...
    this.semanticsLabel,
  });

  final String? semanticsLabel;
  ...

  @override
  Widget build(BuildContext context) {
    final field = Container(...); // 原实现
    if (semanticsLabel == null) return field;
    return Semantics(
      label: semanticsLabel,
      textField: true,
      child: field,
    );
  }
}
```

### Step 8: 修改 AntiqueWatermark

最外层 `ExcludeSemantics(child: IgnorePointer(child: Text(...)))`。装饰性字符不应被读屏器读出。

### Step 9: 修改 AntiqueDialog

build 返回的 `Dialog` 外包 `Semantics(namesRoute: true, scopesRoute: true, explicitChildNodes: true, label: title, child: Dialog(...))`，让读屏器把 dialog 识别为独立 route，正确焦点管理。

### Step 10: 为每个组件测试补 Semantics 断言

对每个 `test/presentation/widgets/antique/antique_*_test.dart` 增加测试，使用 `SemanticsTester`：

```dart
import 'package:flutter/semantics.dart';

testWidgets('button variant has button semantics', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AntiqueButton(label: '起卦', onPressed: () {}),
      ),
    ),
  );

  expect(
    tester.getSemantics(find.byType(AntiqueButton)),
    matchesSemantics(
      isButton: true,
      isEnabled: true,
      label: '起卦',
      hasTapAction: true,
    ),
  );

  handle.dispose();
});
```

为每个修改过 Semantics 的组件加类似的测试。至少覆盖：
- AntiqueButton: isButton + label
- AntiqueCard with onTap: isButton
- AntiqueCard without onTap: 无 isButton（或 label 为 child 的文本）
- AntiqueSectionTitle: isHeader
- AntiqueAppBar title: isHeader
- AntiqueTag: label == text
- AntiqueWatermark: 不产生 semantics label（ExcludeSemantics 生效）

### Step 11: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -5
```

Expected: 0 issues; all tests pass（应会增加 7-10 个新测试，总数从 269 上升）。

### Step 12: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/widgets/antique/ test/presentation/widgets/antique/
git commit -m "feat(antique): add Semantics wrappers for a11y to 9 components

- AntiqueButton/Card/Dropdown: isButton + label
- AntiqueSectionTitle/AppBar title: isHeader
- AntiqueTag: label
- AntiqueWatermark: ExcludeSemantics (decorative)
- AntiqueDialog: scopesRoute + namesRoute
- AntiqueCard/TextField: new optional semanticsLabel parameter
- AntiqueDivider: no change (Flutter Divider OK)
- AntiqueScaffold: no change (shell passes through)"
```

---

## Task 5: 全量验证

- [ ] **Step 1: analyze + test**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -5
```

Expected: 0 issues; 275+ tests pass（269 baseline + 3 dialog + 7 semantics）。

- [ ] **Step 2: Semantics 树快速抽检**

挑 2 个核心页（起卦页、结果页）写 debug 脚本（或临时 test）dump semantics 树：

```dart
testWidgets('cast screen semantics tree', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(...); // render unified cast screen
  await tester.pumpAndSettle();

  final dump = tester.binding.rootPipelineOwner.semanticsOwner!
      .rootSemanticsNode!.toStringDeep();
  print(dump);
  // Inspect manually; confirm no "unknown" leaves, all buttons have labels.
  handle.dispose();
});
```

**仅用于开发期观察，不作为持续测试保留**。检查完可删。

如果 dump 看起来有问题（裸 button 没 label、header 没 level），返回 Task 4 修。

- [ ] **Step 3: 模拟器手工走查 a11y（用户侧）**

> 前置：用户在 iOS 模拟器开 VoiceOver（Settings → Accessibility → VoiceOver）或 Android 模拟器开 TalkBack。
> 跑 `flutter run`，过首页 → 起卦 → 结果 → 历史 → 设置。
> 耳听：每个可点击元素都应读"Button, [label]"；每个标题应被识别为 header。

自动化过了再跑手工。

---

## 完成标志

1. ✅ `lib/presentation/widgets/antique/antique_dialog.dart` 存在、3 测试通过
2. ✅ `showAntiqueDialog()` helper 就绪
3. ✅ `history_list_screen.dart` 删除确认改用 `AntiqueDialog`
4. ✅ 9 个 antique 组件加上 `Semantics`（AntiqueDivider + AntiqueScaffold 可不动）
5. ✅ 每个 Semantics 改动配套 widget test 断言
6. ✅ `flutter analyze` 0 issues
7. ✅ `flutter test` 全过
8. ✅ 用户模拟器开读屏器手工验证主线可用

---

## 范围外（留给未来）

- `showAboutDialog` 如保留则不动；若替换留给 Plan C3 的 token 重构时顺手
- 深度 a11y（focus order、keyboard traversal）单开 plan
- 自定义 Talkback/VoiceOver 手势
- 暗黑模式 —— Plan C3
- Token 缺口补齐（中间灰度、暖纸色、大号 display 字号） —— 跟 Plan C3 一起做更合适
