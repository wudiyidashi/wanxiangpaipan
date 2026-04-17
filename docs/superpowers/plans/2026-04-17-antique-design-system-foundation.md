# 仿古风设计体系 — 基础设施实施计划（Plan A）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 `lib/presentation/widgets/antique/` 共享组件库（10 原子组件 + tokens），并把大六壬（Da Liu Ren）的内联仿古样式完全迁移到新组件，作为后续 8 个页面统一改造的基础设施。

**Architecture:** 在 `lib/core/theme/` 新增 4 个颜色 token 与 5 个 antique text style，新建 `AntiqueTokens` 类集中圆角/间距/边框；新建 `lib/presentation/widgets/antique/` 目录抽 10 个无状态原子 Widget；最后改造 `daliuren_ui_factory.dart` 用新组件替换内联实现，golden test 验证 pixel 级一致。

**Tech Stack:** Flutter 3.24+, Dart 3+, flutter_test, golden_toolkit (or built-in `matchesGoldenFile`)。

**Spec 来源:** `docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md`

**范围:** 本计划仅覆盖 spec 的 Phase 1 + Phase 2。Phase 3+4（其他 8 个页面应用）由后续 Plan B 处理。

---

## 文件结构

**新建：**
- `lib/core/theme/antique_tokens.dart` — 圆角/间距/边框宽度/按钮阴影常量
- `lib/presentation/widgets/antique/antique_scaffold.dart`
- `lib/presentation/widgets/antique/antique_app_bar.dart`
- `lib/presentation/widgets/antique/antique_card.dart`
- `lib/presentation/widgets/antique/antique_section_title.dart`
- `lib/presentation/widgets/antique/antique_divider.dart`
- `lib/presentation/widgets/antique/antique_button.dart`
- `lib/presentation/widgets/antique/antique_text_field.dart`
- `lib/presentation/widgets/antique/antique_dropdown.dart`
- `lib/presentation/widgets/antique/antique_tag.dart`
- `lib/presentation/widgets/antique/antique_watermark.dart`
- `lib/presentation/widgets/antique/antique.dart` — barrel export
- 对应 `test/presentation/widgets/antique/*_test.dart` 11 个测试文件

**修改：**
- `lib/core/theme/app_colors.dart` — 添加 4 个新 token
- `lib/core/theme/app_text_styles.dart` — 添加 5 个 antique 样式
- `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart` — 替换内联样式为新组件、硬编码色为 token

---

## Phase 1：Tokens 设置

### Task 1：扩展 AppColors

**Files:**
- Modify: `lib/core/theme/app_colors.dart` — 在 `// ==================== 扩展色彩 ====================` 区段下新增 4 个常量

- [ ] **Step 1: 添加新颜色常量**

在 `lib/core/theme/app_colors.dart` 中找到 `static const Color gutong = Color(0xFF8B6914);` 这一行（第 43 行附近），紧随其后插入：

```dart
  /// 深淡金 - 罗盘环、印章边、强调边框（仿古风）
  static const Color danjinDeep = Color(0xFFB79452);

  /// 古褐 - 次要文字、标签（仿古风）
  static const Color guhe = Color(0xFF8B7355);

  /// 浅褐 - placeholder、禁用态文字（仿古风）
  static const Color qianhe = Color(0xFFA0937E);

  /// 缃色深 - 背景渐变底端（仿古风）
  static const Color xiangseDeep = Color(0xFFF0EDE8);
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/core/theme/app_colors.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat(theme): add antique color tokens (danjinDeep/guhe/qianhe/xiangseDeep)"
```

---

### Task 2：扩展 AppTextStyles

**Files:**
- Modify: `lib/core/theme/app_text_styles.dart` — 文件末尾添加 antique 区段

- [ ] **Step 1: 在文件末尾（最后一个 `}` 之前）添加 antique text styles**

```dart
  // ==================== 仿古风样式 ====================

  /// 仿古风主标题
  static const TextStyle antiqueTitle = TextStyle(
    fontFamily: fontFamilySong,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: AppColors.xuanse,
    height: 1.4,
  );

  /// 仿古风节标题（朱砂色）
  static const TextStyle antiqueSection = TextStyle(
    fontFamily: fontFamilySong,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    color: AppColors.zhusha,
    height: 1.4,
  );

  /// 仿古风正文
  static const TextStyle antiqueBody = TextStyle(
    fontFamily: fontFamilySong,
    fontSize: 13,
    color: AppColors.xuanse,
    height: 1.6,
  );

  /// 仿古风标签（古褐色）
  static const TextStyle antiqueLabel = TextStyle(
    fontFamily: fontFamilySong,
    fontSize: 11,
    letterSpacing: 1,
    color: AppColors.guhe,
    height: 1.4,
  );

  /// 仿古风按钮文字
  static const TextStyle antiqueButton = TextStyle(
    fontFamily: fontFamilySong,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: Colors.white,
  );
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/core/theme/app_text_styles.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_text_styles.dart
git commit -m "feat(theme): add 5 antique text styles (title/section/body/label/button)"
```

---

### Task 3：创建 AntiqueTokens

**Files:**
- Create: `lib/core/theme/antique_tokens.dart`

- [ ] **Step 1: 创建文件并写入完整内容**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 仿古风非颜色非字体的视觉常量集合
///
/// 集中管理圆角、间距、边框宽度、按钮阴影。
/// 颜色见 [AppColors]，字体样式见 [AppTextStyles]。
class AntiqueTokens {
  AntiqueTokens._();

  // ==================== 圆角 ====================

  /// 卡片圆角
  static const double radiusCard = 8;

  /// 输入框圆角（与卡片一致）
  static const double radiusInput = 8;

  /// 按钮（胶囊）圆角
  static const double radiusButton = 26;

  /// 标签（Tag）圆角
  static const double radiusTag = 12;

  // ==================== 边框 ====================

  /// 细边（分割线、卡片边）
  static const double borderWidthThin = 0.5;

  /// 标准边（输入框、按钮边）
  static const double borderWidthBase = 1.0;

  // ==================== 间距 ====================

  /// 紧凑间距（元素内）
  static const double gapTight = 8;

  /// 基础间距（元素间）
  static const double gapBase = 12;

  /// 节间距（section 之间）
  static const double gapSection = 16;

  // ==================== 阴影 ====================

  /// 主按钮阴影（朱砂色，模拟印章按下感）
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x4DC94A4A),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // ==================== 背景 ====================

  /// 仿古风页面背景渐变（缃色 → 缃色深）
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.xiangse, AppColors.xiangseDeep],
  );

  /// 主按钮渐变（朱砂 → 浅朱砂）
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [AppColors.zhusha, AppColors.zhushaLight],
  );
}
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/core/theme/antique_tokens.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/antique_tokens.dart
git commit -m "feat(theme): add AntiqueTokens for radii/spacing/borders/shadows"
```

---

## Phase 2：原子组件库

每个组件遵循同一模式：
1. 写 widget test
2. 跑测试看失败
3. 实现组件
4. 跑测试看通过
5. 提交

### Task 4：AntiqueCard

**Files:**
- Create: `lib/presentation/widgets/antique/antique_card.dart`
- Test: `test/presentation/widgets/antique/antique_card_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/core/theme/antique_tokens.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_card.dart';

void main() {
  group('AntiqueCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueCard(child: Text('hello')),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('uses default 16px padding on inner Container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueCard(child: SizedBox.shrink()),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueCard),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.padding, const EdgeInsets.all(16));
    });

    testWidgets('uses card radius from AntiqueTokens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueCard(child: Text('x'))),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueCard),
          matching: find.byType(Container),
        ).first,
      );
      final deco = container.decoration as BoxDecoration;
      expect(
        deco.borderRadius,
        BorderRadius.circular(AntiqueTokens.radiusCard),
      );
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueCard(
              onTap: () => tapped = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AntiqueCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_card_test.dart`
Expected: 失败 — `Target of URI doesn't exist: ...antique_card.dart`

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风卡片容器：半透明白底 + 淡金边框 + 8px 圆角，无阴影。
///
/// 替代页面中的 [Card] 与自定义 [Container]，统一卡片视觉。
/// 当 [onTap] 非空时，自带按压缩放反馈（Scale 0.98）。
class AntiqueCard extends StatefulWidget {
  const AntiqueCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<AntiqueCard> createState() => _AntiqueCardState();
}

class _AntiqueCardState extends State<AntiqueCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          border: Border.all(
            color: AppColors.danjin.withOpacity(0.5),
            width: AntiqueTokens.borderWidthBase,
          ),
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_card_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_card.dart test/presentation/widgets/antique/antique_card_test.dart
git commit -m "feat(antique): add AntiqueCard component with press scale"
```

---

### Task 5：AntiqueSectionTitle

**Files:**
- Create: `lib/presentation/widgets/antique/antique_section_title.dart`
- Test: `test/presentation/widgets/antique/antique_section_title_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_section_title_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/core/theme/app_colors.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_section_title.dart';

void main() {
  group('AntiqueSectionTitle', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueSectionTitle(title: '四课')),
        ),
      );
      expect(find.text('四课'), findsOneWidget);
    });

    testWidgets('title uses zhusha color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueSectionTitle(title: '四课')),
        ),
      );
      final text = tester.widget<Text>(find.text('四课'));
      expect(text.style?.color, AppColors.zhusha);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueSectionTitle(title: '四课', subtitle: '本课基础'),
          ),
        ),
      );
      expect(find.text('本课基础'), findsOneWidget);
    });

    testWidgets('shows trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueSectionTitle(
              title: '历史',
              trailing: Icon(Icons.more_horiz, key: Key('trailing')),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('trailing')), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_section_title_test.dart`
Expected: 失败 — `Target of URI doesn't exist`

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_section_title.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

/// 仿古风节标题：朱砂色衬线 + 可选副标题 + 可选右侧 trailing。
class AntiqueSectionTitle extends StatelessWidget {
  const AntiqueSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.antiqueSection),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTextStyles.antiqueLabel),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_section_title_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_section_title.dart test/presentation/widgets/antique/antique_section_title_test.dart
git commit -m "feat(antique): add AntiqueSectionTitle component"
```

---

### Task 6：AntiqueDivider

**Files:**
- Create: `lib/presentation/widgets/antique/antique_divider.dart`
- Test: `test/presentation/widgets/antique/antique_divider_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_divider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/core/theme/app_colors.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_divider.dart';

void main() {
  testWidgets('AntiqueDivider uses danjin color with 0.5 opacity',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AntiqueDivider())),
    );
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.color, AppColors.danjin.withOpacity(0.5));
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_divider_test.dart`
Expected: 失败 — `Target of URI doesn't exist`

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_divider.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风分割线：淡金 0.5 透明度，0.5px 厚度。
class AntiqueDivider extends StatelessWidget {
  const AntiqueDivider({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.danjin.withOpacity(0.5),
      thickness: AntiqueTokens.borderWidthThin,
      height: height,
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_divider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_divider.dart test/presentation/widgets/antique/antique_divider_test.dart
git commit -m "feat(antique): add AntiqueDivider component"
```

---

### Task 7：AntiqueButton

**Files:**
- Create: `lib/presentation/widgets/antique/antique_button.dart`
- Test: `test/presentation/widgets/antique/antique_button_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_button.dart';

void main() {
  group('AntiqueButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(label: '起卦', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('起卦'), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(
              label: '起卦',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AntiqueButton));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('disables tap when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueButton(label: '起卦', onPressed: null),
          ),
        ),
      );
      // Should still render but the gesture detector ignores taps.
      expect(find.text('起卦'), findsOneWidget);
    });

    testWidgets('ghost variant has no fill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueButton(
              label: '取消',
              variant: AntiqueButtonVariant.ghost,
              onPressed: () {},
            ),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueButton),
          matching: find.byType(Container),
        ).first,
      );
      final deco = container.decoration as BoxDecoration;
      expect(deco.gradient, isNull);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_button_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_button.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/antique_tokens.dart';

enum AntiqueButtonVariant { primary, ghost, danger }

/// 仿古风按钮：朱砂渐变胶囊（primary）/ 透明朱砂边（ghost）/ 朱砂深变体（danger）。
class AntiqueButton extends StatelessWidget {
  const AntiqueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AntiqueButtonVariant.primary,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AntiqueButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final isGhost = variant == AntiqueButtonVariant.ghost;
    final fillGradient = isGhost
        ? null
        : (variant == AntiqueButtonVariant.danger
            ? const LinearGradient(
                colors: [Color(0xFFB23A3A), AppColors.zhusha],
              )
            : AntiqueTokens.buttonGradient);

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: fillGradient,
            color: isGhost ? Colors.transparent : null,
            border: isGhost
                ? Border.all(
                    color: AppColors.zhusha,
                    width: AntiqueTokens.borderWidthBase,
                  )
                : null,
            borderRadius: BorderRadius.circular(AntiqueTokens.radiusButton),
            boxShadow: isGhost ? null : const [AntiqueTokens.buttonShadow],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isGhost ? AppColors.zhusha : Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.antiqueButton.copyWith(
                  color: isGhost ? AppColors.zhusha : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_button_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_button.dart test/presentation/widgets/antique/antique_button_test.dart
git commit -m "feat(antique): add AntiqueButton with primary/ghost/danger variants"
```

---

### Task 8：AntiqueAppBar

**Files:**
- Create: `lib/presentation/widgets/antique/antique_app_bar.dart`
- Test: `test/presentation/widgets/antique/antique_app_bar_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_app_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_app_bar.dart';

void main() {
  group('AntiqueAppBar', () {
    testWidgets('renders title centered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AntiqueAppBar(title: '大六壬起课'),
            body: SizedBox(),
          ),
        ),
      );
      expect(find.text('大六壬起课'), findsOneWidget);
    });

    testWidgets('has transparent background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AntiqueAppBar(title: 'X'),
            body: SizedBox(),
          ),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AntiqueAppBar(
              title: 'X',
              actions: [
                IconButton(
                  key: const Key('settings'),
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      expect(find.byKey(const Key('settings')), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_app_bar_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_app_bar.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'antique_divider.dart';

/// 仿古风 AppBar：透明底 + 衬线居中标题 + 底部 0.5px 淡金分隔线。
class AntiqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AntiqueAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(
        title,
        style: AppTextStyles.antiqueTitle.copyWith(color: AppColors.xuanse),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: AntiqueDivider(height: 1),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_app_bar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_app_bar.dart test/presentation/widgets/antique/antique_app_bar_test.dart
git commit -m "feat(antique): add AntiqueAppBar with transparent bg and divider"
```

---

### Task 9：AntiqueScaffold

**Files:**
- Create: `lib/presentation/widgets/antique/antique_scaffold.dart`
- Test: `test/presentation/widgets/antique/antique_scaffold_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/cast/compass_background.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_scaffold.dart';

void main() {
  group('AntiqueScaffold', () {
    testWidgets('renders body', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(body: Text('hi')),
        ),
      );
      expect(find.text('hi'), findsOneWidget);
    });

    testWidgets('does not show compass by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AntiqueScaffold(body: SizedBox())),
      );
      expect(find.byType(CompassBackground), findsNothing);
    });

    testWidgets('shows compass when showCompass is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(showCompass: true, body: SizedBox()),
        ),
      );
      expect(find.byType(CompassBackground), findsOneWidget);
    });

    testWidgets('shows watermark char when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AntiqueScaffold(watermarkChar: '辰', body: SizedBox()),
        ),
      );
      expect(find.text('辰'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_scaffold_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_scaffold.dart
import 'package:flutter/material.dart';
import '../../../core/theme/antique_tokens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cast/compass_background.dart';

/// 仿古风页面骨架：缃色渐变背景 + 可选罗盘装饰 + 可选大字水印。
///
/// 替代所有 [Scaffold]，统一页面背景与装饰层。
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
  final bool showCompass;
  final String? watermarkChar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // 1. 缃色渐变背景
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AntiqueTokens.pageGradient),
            ),
          ),
          // 2. 大字水印（如果提供）
          if (watermarkChar != null)
            Positioned(
              right: -40,
              bottom: 80,
              child: IgnorePointer(
                child: Text(
                  watermarkChar!,
                  style: AppTextStyles.decorText,
                ),
              ),
            ),
          // 3. 罗盘装饰（居中，如果启用）
          if (showCompass)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CompassBackground()),
              ),
            ),
          // 4. 主内容
          Positioned.fill(child: body),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_scaffold_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_scaffold.dart test/presentation/widgets/antique/antique_scaffold_test.dart
git commit -m "feat(antique): add AntiqueScaffold with gradient/compass/watermark layers"
```

---

### Task 10：AntiqueTextField

**Files:**
- Create: `lib/presentation/widgets/antique/antique_text_field.dart`
- Test: `test/presentation/widgets/antique/antique_text_field_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_text_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_text_field.dart';

void main() {
  group('AntiqueTextField', () {
    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(hint: '请输入'),
          ),
        ),
      );
      expect(find.text('请输入'), findsOneWidget);
    });

    testWidgets('forwards onChanged events', (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(onChanged: (v) => captured = v),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '甲');
      expect(captured, '甲');
    });

    testWidgets('respects maxLines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTextField(maxLines: 3),
          ),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.maxLines, 3);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_text_field_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_text_field.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风文本输入框：半透明白底 + 淡金边 + 8px 圆角。
class AntiqueTextField extends StatelessWidget {
  const AntiqueTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(
          color: AppColors.danjin,
          width: AntiqueTokens.borderWidthBase,
        ),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.xuanse,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.qianhe,
            fontSize: 13,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_text_field_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_text_field.dart test/presentation/widgets/antique/antique_text_field_test.dart
git commit -m "feat(antique): add AntiqueTextField component"
```

---

### Task 11：AntiqueDropdown

**Files:**
- Create: `lib/presentation/widgets/antique/antique_dropdown.dart`
- Test: `test/presentation/widgets/antique/antique_dropdown_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_dropdown_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_dropdown.dart';

void main() {
  group('AntiqueDropdown', () {
    testWidgets('renders selected value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueDropdown<String>(
              value: 'time',
              items: const [
                AntiqueDropdownItem(value: 'time', label: '时间起课'),
                AntiqueDropdownItem(value: 'manual', label: '指定起课'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('时间起课'), findsOneWidget);
    });

    testWidgets('forwards selection change', (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueDropdown<String>(
              value: 'time',
              items: const [
                AntiqueDropdownItem(value: 'time', label: '时间起课'),
                AntiqueDropdownItem(value: 'manual', label: '指定起课'),
              ],
              onChanged: (v) => captured = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AntiqueDropdown<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('指定起课').last);
      await tester.pumpAndSettle();
      expect(captured, 'manual');
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_dropdown_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_dropdown.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风下拉选项数据。
class AntiqueDropdownItem<T> {
  const AntiqueDropdownItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// 仿古风下拉选择器：半透明白底 + 淡金边 + 朱砂下拉箭头。
class AntiqueDropdown<T> extends StatelessWidget {
  const AntiqueDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<AntiqueDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(
          color: AppColors.danjin,
          width: AntiqueTokens.borderWidthBase,
        ),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.zhusha),
          style: const TextStyle(
            color: AppColors.xuanse,
            fontSize: 13,
          ),
          dropdownColor: AppColors.xiangseLight,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item.value,
                    child: Text(item.label),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_dropdown_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_dropdown.dart test/presentation/widgets/antique/antique_dropdown_test.dart
git commit -m "feat(antique): add AntiqueDropdown component"
```

---

### Task 12：AntiqueTag

**Files:**
- Create: `lib/presentation/widgets/antique/antique_tag.dart`
- Test: `test/presentation/widgets/antique/antique_tag_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_tag_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_tag.dart';

void main() {
  group('AntiqueTag', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTag(label: '六爻'),
          ),
        ),
      );
      expect(find.text('六爻'), findsOneWidget);
    });

    testWidgets('uses custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueTag(label: '初传', color: Color(0xFF3A6EA5)),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AntiqueTag),
          matching: find.byType(Container),
        ).first,
      );
      final deco = container.decoration as BoxDecoration;
      expect((deco.border as Border).top.color,
          const Color(0xFF3A6EA5).withOpacity(0.3));
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_tag_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_tag.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风标签：低透明色块 + 对应色边框。
///
/// 默认色为朱砂；传入 [color] 可自定义（如六亲、五行、神将等领域色）。
class AntiqueTag extends StatelessWidget {
  const AntiqueTag({
    super.key,
    required this.label,
    this.color = AppColors.zhusha,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: AntiqueTokens.borderWidthBase,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.antiqueLabel.copyWith(color: color),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_tag_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_tag.dart test/presentation/widgets/antique/antique_tag_test.dart
git commit -m "feat(antique): add AntiqueTag with customizable color"
```

---

### Task 13：AntiqueWatermark

**Files:**
- Create: `lib/presentation/widgets/antique/antique_watermark.dart`
- Test: `test/presentation/widgets/antique/antique_watermark_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/widgets/antique/antique_watermark_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/presentation/widgets/antique/antique_watermark.dart';

void main() {
  group('AntiqueWatermark', () {
    testWidgets('renders character', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueWatermark(char: '占')),
        ),
      );
      expect(find.text('占'), findsOneWidget);
    });

    testWidgets('uses default size 96', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueWatermark(char: '占')),
        ),
      );
      final text = tester.widget<Text>(find.text('占'));
      expect(text.style?.fontSize, 96);
    });
  });
}
```

- [ ] **Step 2: 跑测试看失败**

Run: `flutter test test/presentation/widgets/antique/antique_watermark_test.dart`
Expected: 失败 — URI not found

- [ ] **Step 3: 实现组件**

```dart
// lib/presentation/widgets/antique/antique_watermark.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 仿古风小印章水印：用于历史/设置页等不需要大字水印的场景。
///
/// 与 [AppTextStyles.decorText]（200px 大字）区别：本组件默认 96px，
/// 适合作为局部装饰而非整页水印。
class AntiqueWatermark extends StatelessWidget {
  const AntiqueWatermark({
    super.key,
    required this.char,
    this.size = 96,
  });

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Text(
        char,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamilySong,
          fontSize: size,
          fontWeight: FontWeight.w100,
          color: AppColors.danjin.withOpacity(0.15),
          height: 1,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试看通过**

Run: `flutter test test/presentation/widgets/antique/antique_watermark_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/antique/antique_watermark.dart test/presentation/widgets/antique/antique_watermark_test.dart
git commit -m "feat(antique): add AntiqueWatermark for small seal-style decoration"
```

---

### Task 14：Barrel export

**Files:**
- Create: `lib/presentation/widgets/antique/antique.dart`

- [ ] **Step 1: 创建 barrel 文件**

```dart
// lib/presentation/widgets/antique/antique.dart
//
// Barrel export for the antique design system component library.
// Import this single file to access all antique widgets.

export 'antique_app_bar.dart';
export 'antique_button.dart';
export 'antique_card.dart';
export 'antique_divider.dart';
export 'antique_dropdown.dart';
export 'antique_scaffold.dart';
export 'antique_section_title.dart';
export 'antique_tag.dart';
export 'antique_text_field.dart';
export 'antique_watermark.dart';
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/presentation/widgets/antique/`
Expected: `No issues found!`

- [ ] **Step 3: 运行所有 antique 测试**

Run: `flutter test test/presentation/widgets/antique/`
Expected: All 10 component test files pass.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/antique/antique.dart
git commit -m "feat(antique): add barrel export for antique component library"
```

---

## Phase 2：大六壬迁移到新组件

### Task 15：建立大六壬 golden test 基线

**目的：** 在迁移前先抓取大六壬起课页和结果页的当前 golden 图，作为迁移后回归对比的基准。pixel diff = 0 才算迁移成功。

**Files:**
- Create: `test/divination_systems/daliuren/daliuren_golden_test.dart`
- Create: `test/divination_systems/daliuren/goldens/` 目录（自动生成）

- [ ] **Step 1: 写 golden 抓取测试**

```dart
// test/divination_systems/daliuren/daliuren_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiangpaipan/core/theme/app_theme.dart';
import 'package:wanxiangpaipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiangpaipan/divination_systems/daliuren/ui/daliuren_ui_factory.dart';
import 'package:wanxiangpaipan/domain/divination_system.dart';

void main() {
  group('DaLiuRen golden', () {
    testWidgets('cast screen baseline', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final factory = DaLiuRenUIFactory();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: factory.buildCastScreen(CastMethod.time),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/daliuren_cast.png'),
      );
    });

    // Result screen golden requires constructing a fixed DaLiuRenResult.
    // If fixture too complex, leave as TODO and rely on cast screen + manual QA.
  });
}
```

- [ ] **Step 2: 生成 golden 基线（首次）**

Run: `flutter test --update-goldens test/divination_systems/daliuren/daliuren_golden_test.dart`
Expected: 生成 `test/divination_systems/daliuren/goldens/daliuren_cast.png`，测试通过。

- [ ] **Step 3: 验证测试在不更新模式下通过**

Run: `flutter test test/divination_systems/daliuren/daliuren_golden_test.dart`
Expected: PASS（pixel diff = 0）

- [ ] **Step 4: Commit**

```bash
git add test/divination_systems/daliuren/
git commit -m "test(daliuren): add golden baseline for cast screen pre-migration"
```

---

### Task 16：替换 daliuren_ui_factory.dart 内联样式为 antique 组件

**Files:**
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

**目标替换清单：**

| 内联代码（行号参考） | 替换为 |
|---|---|
| L778–781 颜色常量 `_zhuShaRed` `_danJin` `_textDark` `_textMuted` | 删除，全文用 `AppColors.zhusha` / `AppColors.danjin` / `AppColors.xuanse` / `AppColors.guhe` |
| L727–767 `_buildCastButton` | `AntiqueButton(label: '起课', onPressed: ..., variant: AntiqueButtonVariant.primary, fullWidth: true)` |
| L847–857 `_buildAntiqueCard` | `AntiqueCard(child: ...)` |
| L860–870 `_buildSectionTitle` | `AntiqueSectionTitle(title: ...)` |
| L872–875 `_buildAntiqueDivider` | `AntiqueDivider()` |
| L383–410 内联 question 输入框 | `AntiqueTextField(controller: ..., hint: '请输入您想占问的事项...', maxLines: 2)` |
| L320–366 `Scaffold` + 渐变背景 + `Center(child: CompassBackground())` | `AntiqueScaffold(showCompass: true, appBar: AntiqueAppBar(title: '大六壬起课'), body: ...)` |
| L786–801 结果页 `Scaffold` + 渐变 | `AntiqueScaffold(appBar: AntiqueAppBar(title: '大六壬排盘结果'), body: ...)` |

**注意：**
- `TransmissionCircle`（三传圆徽，约 L1058–1105）**保留**，不上浮。但其内部的 `Color(0xFFC94A4A)`、`Color(0xFFE07070)` 替换为 `AppColors.zhusha`、`AppColors.zhushaLight`。
- 所有 `Color(0xFFC94A4A)` → `AppColors.zhusha`
- 所有 `Color(0xFFE07070)` → `AppColors.zhushaLight`
- 所有 `Color(0xFFD4B896)` → `AppColors.danjin`
- 所有 `Color(0xFF2C2C2C)` → `AppColors.xuanse`
- 所有 `Color(0xFF8B7355)` → `AppColors.guhe`
- 所有 `Color(0xFFA0937E)` → `AppColors.qianhe`
- 所有 `Color(0xFFF7F7F5)` → `AppColors.xiangse`
- 所有 `Color(0xFFF0EDE8)` → `AppColors.xiangseDeep`
- 所有 `Color(0xFFB79452)` → `AppColors.danjinDeep`

- [ ] **Step 1: 添加 imports**

在文件顶部 imports 区段（L1-11 附近），添加：

```dart
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/antique/antique.dart';
```

- [ ] **Step 2: 删除 `_DaLiuRenResultScreen` 内的颜色常量（L778–781）**

```dart
// 删除以下 4 行：
static const _zhuShaRed = Color(0xFFC94A4A);
static const _danJin = Color(0xFFD4B896);
static const _textDark = Color(0xFF2C2C2C);
static const _textMuted = Color(0xFF8B7355);
```

之后用编辑器全局查找替换（仅在本文件内）：
- `_zhuShaRed` → `AppColors.zhusha`
- `_danJin` → `AppColors.danjin`
- `_textDark` → `AppColors.xuanse`
- `_textMuted` → `AppColors.guhe`

`_DaLiuRenCastScreen` 类内（L260–769）若有同名常量也照办。如果只用了内联 `Color(0xFFXXXXXX)`，按 Task 16 注意区段全局替换。

- [ ] **Step 3: 替换 `_buildAntiqueCard` 调用方为 `AntiqueCard`**

在 `_DaLiuRenResultScreen` 内查找所有 `_buildAntiqueCard(child: ...)` 调用，原地替换为 `AntiqueCard(child: ...)`。然后删除 `_buildAntiqueCard` 方法定义本身（L847–857）。

- [ ] **Step 4: 替换 `_buildSectionTitle` 调用方为 `AntiqueSectionTitle`**

查找所有 `_buildSectionTitle('xxx')` 替换为 `AntiqueSectionTitle(title: 'xxx')`，然后删除 `_buildSectionTitle` 方法定义（L860–870）。

- [ ] **Step 5: 替换 `_buildAntiqueDivider` 调用方为 `AntiqueDivider`**

查找所有 `_buildAntiqueDivider()` 替换为 `const AntiqueDivider()`，然后删除 `_buildAntiqueDivider` 方法定义（L872–875）。

- [ ] **Step 6: 替换 `_buildCastButton` 为 `AntiqueButton`**

在 `_DaLiuRenCastScreen` 的 `_buildCastSection` 内（约 L720），把 `_buildCastButton()` 调用替换为：

```dart
AntiqueButton(
  label: _isLoading ? '起课中...' : '起课',
  onPressed: _isLoading ? null : _handleCast,
  variant: AntiqueButtonVariant.primary,
  fullWidth: true,
),
```

然后删除 `_buildCastButton` 方法定义（L727–768）。

> Loading 态：`AntiqueButton` 当前不内置 spinner。若希望保留旋转指示，可在按钮 onPressed 为 null 时另起 `Stack` 叠 CircularProgressIndicator，或本任务先去掉 spinner 视觉（按钮 `onPressed: null` + label 改"起课中..."）。Phase 3 结果页改造时若需要 spinner 再扩展 `AntiqueButton.loading` 字段。

- [ ] **Step 7: 替换 question 输入框为 `AntiqueTextField`**

把 `_buildQuestionSection` 内部（L370–411）的 `Container + TextField` 整体替换为：

```dart
Widget _buildQuestionSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('占问事项', style: AppTextStyles.antiqueLabel),
      const SizedBox(height: 6),
      AntiqueTextField(
        controller: _questionController,
        hint: '请输入您想占问的事项...',
        maxLines: 2,
        minLines: 1,
      ),
    ],
  );
}
```

记得在 imports 加入 `import '../../../core/theme/app_text_styles.dart';`。

- [ ] **Step 8: 替换 cast 页 `Scaffold` 为 `AntiqueScaffold`**

`_DaLiuRenCastScreen.build` 方法（L322–367）整体改写：

```dart
@override
Widget build(BuildContext context) {
  return AntiqueScaffold(
    showCompass: true,
    appBar: const AntiqueAppBar(title: '大六壬起课'),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionSection(),
            const SizedBox(height: 16),
            _buildMethodSelector(),
            const SizedBox(height: 16),
            const AntiqueDivider(),
            const SizedBox(height: 20),
            _buildCastSection(),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 9: 替换 result 页 `Scaffold` 为 `AntiqueScaffold`**

`_DaLiuRenResultScreen.build` 方法（L784–844）整体改写：

```dart
@override
Widget build(BuildContext context) {
  return AntiqueScaffold(
    appBar: const AntiqueAppBar(title: '大六壬排盘结果'),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExtendedInfoSection(
              castTime: result.castTime,
              lunarInfo: result.lunarInfo,
              liuShen: const [],
            ),
            const SizedBox(height: 16),
            _buildSiKeSection(),
            const SizedBox(height: 16),
            _buildSanChuanSection(),
            const SizedBox(height: 16),
            _buildTianPanSection(),
            const SizedBox(height: 16),
            _buildShenJiangSection(),
            const SizedBox(height: 16),
            _buildShenShaSection(),
            const SizedBox(height: 16),
            AIAnalysisWidget(result: result),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 10: 验证全文无残留硬编码颜色与已删方法**

Run: `grep -nE "Color\(0xFF(C94A4A|E07070|D4B896|2C2C2C|8B7355|A0937E|F7F7F5|F0EDE8|B79452)\)" lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`
Expected: 仅 `TransmissionCircle` 内部仍可能存在 `0xFFC94A4A` 与 `0xFFE07070`（保留组件本地）。其余应为 0 行。

Run: `grep -nE "_buildAntiqueCard|_buildSectionTitle|_buildAntiqueDivider|_buildCastButton" lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`
Expected: 0 行。

- [ ] **Step 11: 编译验证**

Run: `flutter analyze lib/divination_systems/daliuren/`
Expected: `No issues found!`

- [ ] **Step 12: Commit（迁移完成，golden 验证前）**

```bash
git add lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
git commit -m "refactor(daliuren): migrate inline antique styles to shared antique components"
```

---

### Task 17：Golden 回归验证

**目的：** 验证 Task 16 的迁移没有产生任何 pixel-level 视觉变化。

**Files:**
- Read-only: `test/divination_systems/daliuren/daliuren_golden_test.dart`（Task 15 创建）

- [ ] **Step 1: 跑 golden 测试，分析差异**

Run: `flutter test test/divination_systems/daliuren/daliuren_golden_test.dart`

**预期：FAIL（差异主要来自字体）。** 迁移会把原本无 `fontFamily` 的文字（节标题、按钮、标签等）改为 `Noto Serif SC` 衬线字体，这是 spec 第 1.2 节"全量衬线"的故意结果。

操作：
1. 跑 `flutter test --update-goldens test/divination_systems/daliuren/daliuren_golden_test.dart` 生成新 golden
2. 用 `git diff` 查看新旧 png 的元数据差异（不能直接 diff 像素，需要图像查看器肉眼对比）
3. **接受标准**：
   - ✅ 字体从无衬线变为 Noto Serif SC（预期）
   - ✅ 颜色完全一致（token 与原硬编码值是相同 hex）
   - ✅ 圆角/边框/间距完全一致（值未变）
   - ❌ 任何卡片/section 错位、按钮形变、罗盘消失 → 回到 Task 16 排查
4. 接受后保留新 golden，作为后续改造的回归基准

- [ ] **Step 2: 手工目视验证（模拟器）**

> **前置：** 用户已预先开好模拟器（按 memory `feedback_emulator.md`，直接 `flutter run` 即可，不要 launch 新模拟器）。

Run: `flutter run`

进入 App → 选择"大六壬" → 进入起课页。检查：
- [ ] 背景缃色渐变正常
- [ ] 罗盘居中可见
- [ ] AppBar 透明、标题居中、底部有淡金细线
- [ ] "占问事项"输入框淡金边、半透明白底
- [ ] "起课方式"下拉淡金边
- [ ] 起课按钮朱砂渐变胶囊、有阴影
- [ ] 切换起课方式（时间/报数/指定/随机）UI 切换正常
- [ ] 实际起一卦，进入结果页，四课/三传/天盘/神将/神煞各 section 视觉与迁移前一致

- [ ] **Step 3: 运行全量测试套件确保未破坏其他功能**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Commit（如有 golden 更新）**

如果 Step 1 接受了新 golden：
```bash
git add test/divination_systems/daliuren/goldens/
git commit -m "test(daliuren): update golden after migration to antique components"
```

如果无变化，跳过 commit。

---

## 完成标志

执行完 Task 1–17 后，应满足：

1. ✅ `lib/core/theme/app_colors.dart` 含 4 个新 token（`danjinDeep`, `guhe`, `qianhe`, `xiangseDeep`）
2. ✅ `lib/core/theme/app_text_styles.dart` 含 5 个 antique text styles
3. ✅ `lib/core/theme/antique_tokens.dart` 存在并导出 7 个常量 + 2 个渐变
4. ✅ `lib/presentation/widgets/antique/` 含 10 组件 + 1 barrel + 10 测试
5. ✅ `flutter test test/presentation/widgets/antique/` 全绿
6. ✅ `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart` 无 `_buildAntiqueCard` / `_buildSectionTitle` / `_buildAntiqueDivider` / `_buildCastButton` 私有方法
7. ✅ 大六壬 UI 工厂文件（除 `TransmissionCircle` 外）无硬编码 `Color(0xFFXXXXXX)` 字面量
8. ✅ `daliuren_golden_test.dart` 通过，pixel diff = 0（或人工接受新基线）
9. ✅ 模拟器肉眼验证大六壬起课/结果两页视觉与迁移前一致
10. ✅ `flutter test` 全套件绿

---

## 后续

执行完 Plan A 后启动 **Plan B**：把 antique 组件库应用到剩余 8 个页面（首页、统一起卦、结果、历史、设置、AI 设置、cast_method、test）。Plan B 在 Plan A 落地、组件 API 经过 DLR 真实使用验证后再写，可针对发现的不足调整组件 API（避免一次性锁死所有页面）。

Plan B 的 spec 来源仍是 `docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md` 的 §4.1 改造矩阵。
