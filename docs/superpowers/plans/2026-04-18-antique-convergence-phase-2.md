# 仿古风收敛实施计划 Phase 2（Plan D2）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 执行修订 spec §4 中的 Phase C（视觉债务清理 = TextStyle token 化）+ Phase D（Theme/字体稳定化）——完成仿古风体系的最后一段收敛。Plan D1 已落 Phase A+B+E。

**Architecture:** 三个独立方向并行推进：字体降级（5 分钟文档改口）→ inline TextStyle 清理（daliuren 26 处 + ai_settings 5 处 + 零星）→ `app_theme.dart` 把 Material 默认控件主色从 `dailan` 统一到 `zhusha`，Card/Input/Dialog 等 theme 条目对齐 antique token。

**Tech Stack:** Flutter 3.38, antique design system（Plan A-D1 已落地）。

**Spec 来源:** `docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md`（修订版，commit `538900f`）

**前置决策**（用户确认）：
- 字体选 **B 降级方案**——保留 `Noto Serif SC` 作为 preference，不打包字体资产；文档改口明确"serif fallback"策略。
- Theme 重构按 spec §2.5 要求：`ThemeData` 承接 antique token 作为兜底层，不再与 antique 平行。

**前置事实**（scout 已核实）：
- `divination_systems/*/ui/` 下 0 处原生 `Card/TextField/ElevatedButton` 残留（Plan A-D1 已清）
- inline TextStyle 残留：daliuren 26 处、ai_settings 5 处、其他零星
- `pubspec.yaml` 无 `fonts:` 配置，仓库无 TTF/OTF
- `app_theme.dart` 所有 Material theme 条目当前走 `AppColors.dailan`（黛蓝）而非 antique `zhusha`（朱砂）

---

## 执行顺序理由

1. **字体降级先做**：改动最小（只动 `AppTextStyles` 的 `fontFamily` 策略 + 若干文档），不影响后续任务
2. **TextStyle 清理中间**：文件面大但每处改动机械，不依赖 Theme
3. **Theme 重构最后**：破坏性最大——影响所有原生控件视觉。完成后需要全量回归走查

---

## Task 1: 字体降级——承诺改口

**Goal:** 当前 `AppTextStyles` 里 `fontFamily: 'Noto Serif SC'` 是纯字符串，Flutter 找不到就 fallback 到系统字体但不可预测。把策略从"声明即承诺"改为"serif fallback 链"，文档同步改口。

**Files:**
- Modify: `lib/core/theme/app_text_styles.dart`
- Modify: `docs/UI设计指导.md`（字体章节）
- Modify: `CLAUDE.md`（项目级，如提及字体）
- Modify: `README.md`（如技术栈 / Phase 路线提及）

### Step 1: 改造 `AppTextStyles` 的 fontFamily 策略

编辑 `lib/core/theme/app_text_styles.dart`，找到当前的：

```dart
/// 宋体字体族（标题、干支）
static const String fontFamilySong = 'Noto Serif SC';
```

保留这个 const，但在其下方追加 fallback 列表常量，并更新 docstring 说明"非严格承诺"：

```dart
/// 宋体字体族（偏好）
///
/// **注意**：项目未打包字体资产，此处 'Noto Serif SC' 是首选名称。
/// 实际渲染时 Flutter 会按 [fontFamilyFallback] 顺序查找，最终
/// 回退到平台系统字体（iOS 苹方 / macOS PingFang / Android Source Han Serif 等）。
/// 视觉允许细微跨平台差异，交付契约不要求 pixel-level 一致。
static const String fontFamilySong = 'Noto Serif SC';

/// 仿古风 serif 回退链：首选 Noto Serif SC，未安装时回退到通用 serif 族
static const List<String> fontFamilyFallback = ['Noto Serif SC', 'serif'];
```

然后遍历文件内所有使用 `fontFamily: fontFamilySong` 的 TextStyle 定义（antique* 系列），在每一处加 `fontFamilyFallback: fontFamilyFallback`。例：

```dart
// Before
static const TextStyle antiqueTitle = TextStyle(
  fontFamily: fontFamilySong,
  fontSize: 18,
  ...
);

// After
static const TextStyle antiqueTitle = TextStyle(
  fontFamily: fontFamilySong,
  fontFamilyFallback: fontFamilyFallback,
  fontSize: 18,
  ...
);
```

对 5 个 antique styles（antiqueTitle/Section/Body/Label/Button）全部加。其他原 material 风格的 TextStyle（displayLarge / bodyMedium 等）不用加——它们本来就不声明 fontFamily，靠 theme 默认回退，改动非 goal。

### Step 2: 更新 `docs/UI设计指导.md` 字体章节

找文档里讲字体的那节（搜 `Noto Serif SC` 或"字体"），替换相关表述。

**原文大意**：「全量思源宋体（Noto Serif SC），若实测 11-13px 衬线可读性显著下降，降级正文为 PingFang SC」

**改为**：

```markdown
#### 字体策略

- **首选**：Noto Serif SC（思源宋体）
- **交付契约**：项目未打包字体资产。`AppTextStyles.antique*` 通过 `fontFamilyFallback: ['Noto Serif SC', 'serif']` 声明回退链。实际渲染依平台已安装字体决定。
- **接受细微跨平台差异**：iOS 苹方、macOS PingFang、Android Source Han Serif / Noto 中文系列均可正常承接视觉调性。不追求 pixel-level 一致。
- **不打包原因**：Noto Serif SC 简中全量约 30-40MB、subset 约 6-10MB，对免费工具类 App 的安装包体积影响显著；收益（精确字体）不匹配本产品定位。
- **未来触发打包**：若发版后收到明确的"字体缺失导致可读性问题"反馈，再评估打包 subset 方案。
```

### Step 3: 更新 `CLAUDE.md` 和 `README.md` 字体相关提及

搜项目级 CLAUDE.md 和 README.md：
```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -n "Noto Serif\|思源宋体\|全量衬线\|全量serif" CLAUDE.md README.md
```

如有发现"全量 Noto Serif SC"或类似强承诺表述，改为"serif 首选，未打包字体资产"一类弱表述。若无发现，跳过。

### Step 4: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

Expected: analyze clean, 283 tests pass。（字体 fallback 加进来对 widget test 无影响——widget test 不渲染真字符，只检查 TextStyle 属性）

### Step 5: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/core/theme/app_text_styles.dart docs/UI设计指导.md CLAUDE.md README.md
git commit -m "docs+refactor(theme): downgrade font commitment to serif-fallback

Per revised spec §2.7 + user decision: do not bundle Noto Serif SC
font assets. AppTextStyles.antique* now declares fontFamilyFallback:
['Noto Serif SC', 'serif'] so Flutter gracefully falls back to the
platform's installed serif font (PingFang on iOS, Source Han Serif
on Android, etc.).

Documentation updates:
- UI设计指导.md font section: 'full serif' claim → 'serif fallback'
  with platform-variance acceptance
- CLAUDE.md / README.md: any hard font commitment relaxed

Trade-off accepted: slight cross-platform rendering differences in
exchange for not bloating APK/IPA by 6-40MB. Revisit if user
feedback indicates readability problems."
```

---

## Task 2: `daliuren_ui_factory.dart` TextStyle 清理（26 处）

**Goal:** 把工厂内 26 处 inline `TextStyle(...)` 按用途映射到 `AppTextStyles.antique*`（+ `copyWith` 微调），消除视觉债务。

**Files:**
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

### 映射规则（标准）

| 原 inline 用途特征 | 替换 |
|---|---|
| bold 18pt+（标题） | `AppTextStyles.antiqueTitle` |
| bold 15pt accent 色（section 标题） | `AppTextStyles.antiqueSection`（或用 `AntiqueSectionTitle` widget） |
| 13-14pt 正文 | `AppTextStyles.antiqueBody` |
| 11-12pt muted（label/caption） | `AppTextStyles.antiqueLabel` |
| 16pt bold white（按钮） | `AppTextStyles.antiqueButton` |
| 特殊色（比用蓝 / 吉神绿 / 六亲色） | 保留 inline + 加 `// 域色` 注释 |

### Step 1: 盘点 26 处 TextStyle 位置与用途

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nC2 "TextStyle(" lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
```

对每一处记录：所在方法（`buildHistoryCard` / `_buildSiKeSection` 等）+ 语义（标题/正文/label/badge）+ 色值是否域色。

### Step 2: 逐处替换

对每一处：
- 若属通用角色（标题/正文/label/按钮），直接换成对应 `AppTextStyles.antique*`，不加其他修饰
- 若需要保留某个特殊属性（如 `height: 1.4` 或特殊色），用 `.copyWith(...)`：

```dart
// 例
style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.biyongBlue),
```

- 若色值完全是域色（如八宫色、六亲色），TextStyle 整体保留 inline，但**同行或上一行**加 `// 域色：...` 注释（为了 Phase E 的 `audit_hardcoded_colors.sh` 只检 `Color(0x...)` 字面量，对 TextStyle 无关；但保留注释是良好习惯）

### Step 3: 确认没破坏结构

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -c "TextStyle(" lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
```

剩余数量应 ≤ 域色保留那几处（实测后记下，合理即可）。

### Step 4: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/divination_systems/daliuren/
flutter test 2>&1 | tail -3
```

Expected: analyze clean, 283 tests pass。

**若 DLR 起课页 golden fail**：迁移引入了字体大小/weight 差异。对照 `AppTextStyles.antique*` 的实际 size/weight，判断：
- 差异可接受（比如从 `fontSize: 13` 改成 antiqueBody 的 13pt 但多了 `height: 1.6`，视觉轻微变化）→ `flutter test --update-goldens ...` 重基线
- 差异不可接受（一栏内容挤爆/省略）→ 回退该处改动或用 `copyWith(fontSize: ..., height: null)` 微调

### Step 5: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
git commit -m "refactor(daliuren): migrate 26 inline TextStyles to AppTextStyles.antique*

Per revised spec §4.3 Phase C, all generic-role TextStyles
(title/section/body/label/button) in daliuren UI factory now
reference the tokenized antique styles. Domain-specific colors
(八宫/六亲/吉神/比用) retained as inline Styles with .copyWith()
or explanatory comments.

No behavior change; visual changes are limited to normalization
of height / letterSpacing to match antique baseline."
```

---

## Task 3: `ai_settings_screen.dart` TextStyle 清理（5 处）

**Goal:** 清理 Plan C2 遗留的 5 处 inline TextStyle。位置已知：L224 / L295 / L348 / L460 / L603。

**Files:**
- Modify: `lib/presentation/screens/settings/ai_settings_screen.dart`

### Step 1: 读原文每处位置

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
sed -n '220,230p;290,300p;340,355p;455,465p;600,610p' lib/presentation/screens/settings/ai_settings_screen.dart
```

识别每处语义。基于 Plan C2 review 的已知信息：
- L224: `TextStyle(fontSize: 12)` —— ActionChip label
- L295: `TextStyle(color: Colors.grey, fontSize: 13)` —— 某处说明文字
- L348: `TextStyle(color: isSuccess ? Colors.green : Colors.red)` —— validation status color（**语义色，保留**）
- L460: `TextStyle(color: Colors.green, fontSize: 11)` —— "使用中" status（**语义色，保留**）
- L603: `TextStyle(fontSize: 13, fontFamily: 'monospace', ...)` —— prompt preview（**domain：代码/模板展示需要 monospace，保留**）

### Step 2: 按规则替换

- L224 → `AppTextStyles.antiqueLabel.copyWith(fontSize: 12)`（保留 fontSize 覆盖）
- L295 → `AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe, fontSize: 13)`（灰色归 guhe）
- L348 → **保留 inline** + 加注释 `// 语义状态色：validation 成功/失败`
- L460 → **保留 inline** + 加注释 `// 语义状态色：使用中/未使用`
- L603 → **保留 inline** + 加注释 `// monospace：模板代码预览`

### Step 3: 验证 + Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/presentation/screens/settings/
flutter test 2>&1 | tail -3
```

Expected: clean + pass。

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/screens/settings/ai_settings_screen.dart
git commit -m "refactor(ai-settings): migrate remaining TextStyles to antique tokens

L224/L295 generic roles → AppTextStyles.antique* with copyWith.
L348/L460/L603 retained inline as semantic-status or domain
(monospace code preview) with explanatory comments."
```

---

## Task 4: 全项目 TextStyle 残留清扫

**Goal:** Task 2/3 处理已知大块。全项目扫其他角落，确认没遗漏。

### Step 1: 扫全部非 antique TextStyle

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rn "TextStyle(" lib/ 2>/dev/null | grep -v "widgets/antique/" | grep -v ".freezed.dart" | grep -v ".g.dart" > /tmp/textstyle_residues.txt 2>/dev/null || grep -rn "TextStyle(" lib/ 2>/dev/null | grep -v "widgets/antique/" | grep -v ".freezed.dart" | grep -v ".g.dart"
wc -l /tmp/textstyle_residues.txt 2>/dev/null || true
cat /tmp/textstyle_residues.txt 2>/dev/null || true
```

（也可直接在终端看结果，不写文件也行。）

### Step 2: 按文件归类

预期看到：
- `lib/presentation/widgets/` 下各内容组件：Plan C1 已处理 90%，可能还有个别零星
- `lib/presentation/screens/home/` / `lib/presentation/screens/history/` / `lib/presentation/screens/settings/`：Plan B / C2 之后应该很少
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`：Plan B / C2 已处理 80%，可能还有个别零星
- `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`：已由 Task 2 处理

对每处剩余：
- 判断是否 generic role → 换 AppTextStyles.antique*
- 否则加 `//` 注释说明

### Step 3: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

Expected: clean + 283 pass。

### Step 4: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add -u lib/
# 在 commit message body 里具体写出每个改动的文件 + 做法。
# 模板：
#   refactor: sweep remaining inline TextStyles to antique tokens
#
#   Cleanup residues found by full-project grep after Task 2/3:
#   - <path/to/file.dart>:<line> - <换 token 还是加注释>
#   - <path/to/another.dart>:<line> - <处理方式>
#
#   All generic-role TextStyles now use AppTextStyles.antique*.
#   Domain/semantic TextStyles retained inline with annotation.
git commit  # 编辑器打开填写具体 message
```

（如果 Step 2 没找到任何遗漏，跳过 Task 4 不 commit。）

---

## Task 5: `app_theme.dart` Theme 重构——Material 默认控件对齐 antique

**Goal:** 把所有 Material ThemeData 条目的 primary 色从 `AppColors.dailan` 统一到 `AppColors.zhusha`，让原生 `Switch/Checkbox/TabBar/默认 ripple` 等未封装控件也呈现仿古风调。同时把 `cardTheme / inputDecorationTheme / dialogTheme / chipTheme` 等条目的视觉属性对齐 antique 默认（半透明白底 + 淡金边 + 无 elevation 等）。

**这是 Plan D2 破坏性最大的改动——影响所有原生 Material 控件视觉。**

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

### 重构前事实

当前 theme 体系（约 40 处 dailan 引用）：
- `colorScheme.primary: AppColors.dailan` —— 主色
- `elevatedButtonTheme.backgroundColor: dailan` —— 原生按钮
- `textButtonTheme.foregroundColor: dailan`
- `inputDecorationTheme.focusedBorder.color: dailan`
- `bottomNavigationBarTheme.selectedItemColor: dailan`
- `progressIndicatorTheme.color: dailan`
- `chipTheme.selectedColor: dailan @ 0.15`
- `splashColor: dailan @ 0.1`
- `highlightColor: dailan @ 0.05`

### Step 1: 逐 theme 条目改写

用以下映射逐项改写（**保持整个文件结构，只改色值**）：

**A. colorScheme**（line 20-33）

```dart
colorScheme: const ColorScheme.light(
  primary: AppColors.zhusha,               // was dailan
  onPrimary: Colors.white,
  primaryContainer: AppColors.zhushaLight, // was dailanLight
  secondary: AppColors.danjinDeep,         // was zhusha（次强调色，用淡金深色）
  onSecondary: Colors.white,
  secondaryContainer: AppColors.danjin,
  surface: AppColors.xiangse,
  onSurface: AppColors.xuanse,
  surfaceContainerHighest: AppColors.xiangseLight,
  error: AppColors.errorDeep,              // was AppColors.error（更仿古的深红）
  onError: Colors.white,
  outline: AppColors.danjin,               // was divider（浅灰 → 淡金）
),
```

**B. appBarTheme**（line 39-59）——保留现状即可（已经是透明/xuanse 等 antique 友好色），只需把 titleTextStyle 的 letterSpacing 保持一致。

**C. cardTheme**（line 62-70）

```dart
cardTheme: CardThemeData(
  color: Colors.white.withOpacity(0.6),    // 对齐 AntiqueCard，was xiangseLight
  elevation: 0,                            // 对齐 AntiqueCard，was 2
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),  // was 12
    side: BorderSide(
      color: AppColors.danjin.withOpacity(0.5),
      width: AntiqueTokens.borderWidthBase,
    ),
  ),
  margin: const EdgeInsets.all(8),
),
```

（需要新加 import `import 'antique_tokens.dart';`）

**D. elevatedButtonTheme**（line 73-89）

```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.zhusha,              // was dailan
    foregroundColor: Colors.white,
    elevation: 2,
    shadowColor: AppColors.zhusha.withOpacity(0.3), // was dailan
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AntiqueTokens.radiusButton),  // was 8
    ),
    textStyle: AppTextStyles.antiqueButton.copyWith(letterSpacing: 1),
  ),
),
```

**E. textButtonTheme**（line 92-101）

```dart
textButtonTheme: TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.zhusha,              // was dailan
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
),
```

**F. inputDecorationTheme**（line 111-135）

```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: Colors.white.withOpacity(0.6),        // 对齐 AntiqueTextField
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),  // was 8
    borderSide: const BorderSide(color: AppColors.danjin),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
    borderSide: const BorderSide(color: AppColors.danjin),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
    borderSide: const BorderSide(color: AppColors.zhusha, width: 2),  // was dailan
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
    borderSide: const BorderSide(color: AppColors.errorDeep),         // was error
  ),
  hintStyle: AppTextStyles.antiqueBody.copyWith(color: AppColors.qianhe),
),
```

**G. dividerTheme**（line 138-142）——保留现状，或改为 `danjin.withOpacity(0.5)` 对齐 AntiqueDivider。倾向改：

```dart
dividerTheme: DividerThemeData(
  color: AppColors.danjin.withOpacity(0.5),       // was divider
  thickness: AntiqueTokens.borderWidthThin,
  space: 1,
),
```

**H. bottomNavigationBarTheme**（line 145-153）

```dart
bottomNavigationBarTheme: const BottomNavigationBarThemeData(
  backgroundColor: AppColors.xiangseLight,
  selectedItemColor: AppColors.zhusha,             // was dailan
  unselectedItemColor: AppColors.guhe,             // was huiseLight
  type: BottomNavigationBarType.fixed,
  elevation: 8,
  selectedLabelStyle: AppTextStyles.antiqueLabel,  // was navLabel
  unselectedLabelStyle: AppTextStyles.antiqueLabel,
),
```

**I. dialogTheme**（line 175-184）——对齐 AntiqueDialog：

```dart
dialogTheme: DialogThemeData(
  backgroundColor: Colors.white.withOpacity(0.95),  // was xiangseLight
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: AppColors.danjin,
      width: AntiqueTokens.borderWidthBase,
    ),
  ),
  titleTextStyle: AppTextStyles.antiqueSection,
  contentTextStyle: AppTextStyles.antiqueBody,
),
```

**J. snackBarTheme**（line 186-194）—— 保留现状。当前 backgroundColor 是 xuanse（黑灰），内容白字——仿古也能吃。

**K. progressIndicatorTheme**（line 197-200）

```dart
progressIndicatorTheme: ProgressIndicatorThemeData(
  color: AppColors.zhusha,                        // was dailan
  circularTrackColor: AppColors.danjin.withOpacity(0.3),
),
```

**L. chipTheme**（line 203-213）

```dart
chipTheme: ChipThemeData(
  backgroundColor: AppColors.xiangseLight,
  selectedColor: AppColors.zhusha.withOpacity(0.15),   // was dailan
  disabledColor: AppColors.divider,
  labelStyle: AppTextStyles.antiqueLabel,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
    side: BorderSide(color: AppColors.danjin.withOpacity(0.5)),
  ),
),
```

**M. listTileTheme**（line 216-221）—— 保留现状，或把 iconColor 改 `guhe`：

```dart
listTileTheme: const ListTileThemeData(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  titleTextStyle: AppTextStyles.antiqueBody,      // was titleSmall
  subtitleTextStyle: AppTextStyles.antiqueLabel,  // was bodySmall
  iconColor: AppColors.guhe,                      // was huise
),
```

**N. floatingActionButtonTheme**（line 224-229）—— 已经是 zhusha，保持不变。

**O. splashColor / highlightColor**（line 233-234）

```dart
splashColor: AppColors.zhusha.withOpacity(0.1),     // was dailan
highlightColor: AppColors.zhusha.withOpacity(0.05), // was dailan
```

### Step 2: 增加所需 import

文件顶部 imports 确认包含：
```dart
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'antique_tokens.dart';  // 新增，因为用到了 AntiqueTokens.radiusCard 等
```

### Step 3: 验证不破坏现有 antique 组件

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

Expected: analyze clean, 全部 antique widget tests 通过。

**可能的 regression**：
- antique widget tests 测的是组件自身 decoration 属性，不吃 theme，所以应该全绿
- DLR 起课页 golden 可能失败——因为其中某些 InputDecoration / ElevatedButton 可能通过 theme 间接染色了。若 golden fail，先 inspect diff，judge 是否可接受（应该是）再 `--update-goldens` 重基线

### Step 4: 审计脚本确认

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
bash tool/audit_hardcoded_colors.sh
```

Expected: `OK`。theme 文件不在 audit 范围（它在 `lib/core/theme/`，脚本只扫 `presentation/` 和 `divination_systems/`），所以 theme 改动不影响 audit。

### Step 5: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/core/theme/app_theme.dart
git commit -m "refactor(theme): align Material ThemeData with antique tokens

Per revised spec §2.5 + §4.4, ThemeData now承接 antique token
as fallback layer instead of running parallel to antique
components.

Primary color:
- colorScheme.primary: dailan → zhusha
- All Material defaults (ElevatedButton / TextButton / Input
  focused border / BottomNavigationBar selectedItem /
  ProgressIndicator / Chip selected / splash / highlight) now
  use zhusha instead of dailan

Shape/border alignment to antique:
- CardTheme: white@0.6 + danjin border + 0 elevation + 8px radius
- InputDecorationTheme: white@0.6 + danjin border + focused zhusha
- DialogTheme: white@0.95 + danjin border + 12px radius
- ChipTheme: xiangseLight + zhusha selected + danjin stroke

TextStyles in theme now reference AppTextStyles.antique* where
applicable (title / body / label on ListTile / Chip / BottomNav).

Native Material controls without antique wrappers (Switch,
Checkbox, TabBar, default Ripple) will now render in antique
palette rather than black+dailan."
```

---

## Task 6: Plan D2 全量验证 + 回归走查清单

### Step 1: 全量自动化验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -5
bash tool/audit_hardcoded_colors.sh
```

Expected:
- analyze: No issues found
- test: 283/283 pass（或 golden 重基线后仍 pass）
- audit: OK

### Step 2: 列出需要用户手工走查的点

整理 Plan D2 受影响的视觉点，供用户在模拟器手工检查：

**Theme 重构可能影响的点**（Task 5）：
- 首页 bottom nav selected 色（蓝 → 朱砂）
- 任何未封装的 `CircularProgressIndicator` / `LinearProgressIndicator`
- 任何 `Switch` / `Checkbox`（如 AI 设置可能有 toggle）
- 点击页面任何位置时的 ripple/splash 色
- 历史页 AlertDialog 仍用 showAboutDialog 的 Flutter 内置样式（不受影响）

**TextStyle 清理可能影响**（Task 2/3）：
- 大六壬起课页各处文字 height / letterSpacing 可能微调
- AI 设置页若干标签 height / letterSpacing 可能微调

**不影响**：
- 所有已封装 antique 组件（AntiqueCard/Button/TextField 等）——它们自己带样式，不吃 theme
- 首页 _buildAppBar 的 Row 结构（Plan B 保留的自定义 AppBar）
- 水印字、罗盘

### Step 3: 列出 Plan D2 所有 commits 清单

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git log --oneline <plan-d2-base>..HEAD
```

（`<plan-d2-base>` = 38470d0，即 Plan D1 合并后的 main HEAD）

Expected: 4-6 个 commits 覆盖 Task 1-5。

### Step 4: 提交 Plan D2 文档（如未提交）

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add docs/superpowers/plans/2026-04-18-antique-convergence-phase-2.md
git commit -m "docs(plan): Plan D2 - convergence Phase C+D"
```

---

## 完成标志

1. ✅ `AppTextStyles.antique*` 声明了 `fontFamilyFallback`；字体承诺在 UI设计指导.md 明确降级为 serif-fallback
2. ✅ `daliuren_ui_factory.dart` 26 处 TextStyle 按规则归档（通用 → token，域色 → 注释保留）
3. ✅ `ai_settings_screen.dart` 5 处 TextStyle 按规则归档
4. ✅ 全项目扫剩余 TextStyle 残留已清理或注释
5. ✅ `app_theme.dart` 所有 Material theme 条目对齐 antique（主色 zhusha、Card/Input/Dialog 对齐）
6. ✅ `flutter analyze` clean
7. ✅ `flutter test` 全部过（含 golden 如有重基线）
8. ✅ `bash tool/audit_hardcoded_colors.sh` 退出 0

---

## 范围外（留给未来）

- **暗黑模式** Plan C3（之前被搁置，修订 spec §1.3 明确非目标）
- **新术数系统**（小六壬 / 梅花易数 / 紫微斗数 / 奇门遁甲）
- **真字体打包**——若未来用户反馈字体缺失导致可读性问题再评估
- **卡片 staggered 载入动画、呼吸动效、HapticFeedback**——spec §1.3 明确非目标
- **深度 a11y**（focus order、keyboard traversal）
