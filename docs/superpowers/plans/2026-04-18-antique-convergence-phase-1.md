# 仿古风收敛实施计划 Phase 1（Plan D1）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 执行修订 spec §4 中的 Phase A（文档契约纠偏）、Phase B（边界清理）、Phase E（测试门禁重构）——低风险高见效的第一段收敛。Phase C（视觉债务清理）+ Phase D（Theme/字体稳定）留给 Plan D2。

**Architecture:** 先做代码边界清理（删 orphan / 死抽象 / 伪统一），再把文档对齐到最终代码事实，最后加静态门禁防止回退。不改视觉、不动 token 结构、不碰 Theme 集成策略。

**Tech Stack:** Flutter 3.38, antique design system（Plan A-C2 已落地）。

**Spec 来源:** `docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md`（修订版 commit `538900f`）

**前置事实**（scout 已核实）：
- `lib/presentation/screens/result/result_screen.dart` 已 orphan，无任何 import / 调用
- `buildSystemCard()` 在 `DivinationUIFactory` 接口声明 + 两工厂 override 了，但**全仓无调用方**
- `UnifiedCastScreen` 只有 1 个调用点：`liuyao_ui_factory.dart:28 return const UnifiedCastScreen()`
- `_LiuYaoResultScreenWithAI` 独立于 top-level `ResultScreen`（通过 question_section / extended_info_section / diagram_comparison_row / special_relation_section 共享，而非通过 `ResultScreen` 间接依赖）
- 当前 golden 只有 DLR 起课页 1 张
- CI 在 `.github/workflows/flutter_ci.yml`

---

## 文件结构总览

### 将删除
- `lib/presentation/screens/result/result_screen.dart`（orphan）
- `lib/presentation/screens/cast/unified_cast_screen.dart`（移到六爻系统内部）
- `lib/presentation/screens/cast/` 目录如果迁移后变空则一并删

### 将修改
- `lib/presentation/divination_ui_registry.dart`：接口移除 `buildSystemCard()`
- `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`：删除 `buildSystemCard()` 实现
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`：
  - 删除 `buildSystemCard()` 实现
  - 把 `buildCastScreen` 返回改为内部私有 widget
  - 把 `UnifiedCastScreen` 的代码/逻辑迁进来（作为私有类 `_LiuYaoCastScreen`）

### 将新增
- `.github/workflows/flutter_ci.yml` 补一个 `hardcoded-color-audit` step（或单独一个 workflow）
- `docs/UI设计指导.md` 局部更新（承认事实 + chromeless 能力 + token 门禁）
- `CLAUDE.md` 补一行 chromeless 能力

### 测试
- `test/presentation/divination_ui_registry_test.dart`（如存在）：删掉针对 `buildSystemCard()` 的断言
- 无需新增测试（边界清理类任务，测试覆盖由现有 283 测试兜底）

---

## Phase B — 边界清理（先做，代码事实先对齐）

### Task 1: 删除 orphan `ResultScreen`

**Files:**
- Delete: `lib/presentation/screens/result/result_screen.dart`

- [ ] **Step 1: 最终确认无引用**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && grep -rn "result_screen\|ResultScreen" lib/ test/ 2>/dev/null`

Expected: 只命中文件自身的 `class ResultScreen` 定义、或者仅存在于 `divination_ui_registry.dart` 文档注释里的示例代码。若命中真实 import 语句或 `ResultScreen()` 构造器调用，报告 BLOCKED。

- [ ] **Step 2: 删除文件**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && rm lib/presentation/screens/result/result_screen.dart`

检查 `lib/presentation/screens/result/` 是否变空：`ls lib/presentation/screens/result/`。空的话顺手删目录：`rmdir lib/presentation/screens/result/`。

- [ ] **Step 3: 清理 registry 文档注释里对 `ResultScreen` 的示例引用**

Edit `lib/presentation/divination_ui_registry.dart`：把 docstring 里
```
///     return LiuYaoResultScreen(result: result as LiuYaoResult);
```
这样的示例 class name 保留即可（文档注释无害），但如果有直接写 `ResultScreen` 的示例，改成系统工厂的私有类名（如 `_LiuYaoResultScreenWithAI`）。

- [ ] **Step 4: 编译 + 测试**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

Expected: No issues; 283 tests pass.

- [ ] **Step 5: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add -A lib/presentation/screens/result/ lib/presentation/divination_ui_registry.dart
git commit -m "refactor: remove orphan ResultScreen and clean up registry docstring

ResultScreen at lib/presentation/screens/result/result_screen.dart
became unreachable after Plan B migrated LiuYao result rendering
into _LiuYaoResultScreenWithAI inside liuyao_ui_factory.dart.
Per convergence spec §3.3.2, removing dead abstraction.

buildSystemCard docstring example updated to reference the
factory-private class naming convention used since Plan A."
```

---

### Task 2: 从 DivinationUIFactory 接口移除 `buildSystemCard()`

**Files:**
- Modify: `lib/presentation/divination_ui_registry.dart`（删接口默认实现）
- Modify: `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`（删 override）
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`（删 override）

- [ ] **Step 1: 最后确认 `buildSystemCard` 真的无调用方**

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && grep -rn "buildSystemCard" lib/ test/ 2>/dev/null`

Expected: 只命中接口声明 + 两工厂的 override。若命中 `factory.buildSystemCard()` 调用点或 test 断言，报告 BLOCKED 供人评估。

- [ ] **Step 2: 删除接口声明**

Edit `lib/presentation/divination_ui_registry.dart`，删除：

```dart
  /// 构建系统介绍卡片（可选）
  ///
  /// 用于在主页显示该术数系统的介绍卡片。
  /// 如果返回 null，将使用默认的卡片样式。
  ///
  /// 返回系统介绍卡片 Widget，或 null 使用默认样式
  Widget? buildSystemCard() => null;
```

（包括上方 docstring 和默认返回 null 的实现）

- [ ] **Step 3: 删除六爻工厂 override**

Edit `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`，从 `Widget? buildSystemCard() {` 开始到对应 `}` 结束，整块删除。

- [ ] **Step 4: 删除大六壬工厂 override**

Edit `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`，同上整块删除 `buildSystemCard()` 实现。

- [ ] **Step 5: 检查是否留下未使用的 helper**

两工厂的 `buildSystemCard` 实现可能调用过 `_buildTag` 等 helper。若该 helper 只被 `buildSystemCard` 调用，也一并删除。

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && grep -n "_buildTag" lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

如果某个 helper 其他地方还在用，留着；如果只 dead code，删除。

- [ ] **Step 6: 编译 + 测试**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

Expected: No issues; 283 tests pass. 若有测试断言 `buildSystemCard` 行为，同步删除。

- [ ] **Step 7: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/divination_ui_registry.dart \
        lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart \
        lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
git commit -m "refactor: drop buildSystemCard() from DivinationUIFactory

Dead abstraction: declared in interface and overridden by both
liuyao and daliuren factories, but never called anywhere in the
codebase. Home Bento grid already renders via the shared
DivinationSystemCard widget using system metadata (name/icon/
color) rather than factory-returned cards.

Per convergence spec §3.3.3, removing the concept from the
interface; escape-hatch semantics can be revisited if a concrete
use case appears."
```

---

### Task 3: 把 `UnifiedCastScreen` 内部私有化到六爻系统

**目的**：`UnifiedCastScreen` 实际只服务六爻，名字却在 `lib/presentation/screens/cast/` 下占 platform-level 位置，产生"平台级统一起卦页"的错觉。按修订 spec §3.3.1 + Q2（内部私有），把文件迁进六爻 UI 工厂所在目录，类名变私有。

**Files:**
- Modify: `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`（把 UnifiedCastScreen 的内容变成私有类 `_LiuYaoCastScreen` 迁进来）
- Delete: `lib/presentation/screens/cast/unified_cast_screen.dart`
- Delete: `lib/presentation/screens/cast/` 若变空一并删

- [ ] **Step 1: 读两份文件了解结构**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
cat lib/presentation/screens/cast/unified_cast_screen.dart
sed -n '1,50p' lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
```

记录：
- `UnifiedCastScreen` 的完整实现（class `UnifiedCastScreen` + `_UnifiedCastScreenState`）
- 它的 imports 列表
- 六爻工厂目前如何引用它（line 8 import + line 28 return）

- [ ] **Step 2: 复制 UnifiedCastScreen 内容到六爻工厂文件末尾**

从 `lib/presentation/screens/cast/unified_cast_screen.dart` 复制**整个文件的 class 定义部分**（不含顶部 imports，只要 `class UnifiedCastScreen extends StatefulWidget` 和 `class _UnifiedCastScreenState extends State<UnifiedCastScreen>` 两个类的完整代码），追加到 `liuyao_ui_factory.dart` 末尾最后一个 `}` 之后。

对复制进来的代码做如下机械重命名（**仅改名，不改逻辑**）：

| 原标识 | 新标识 | 位置 |
|---|---|---|
| `class UnifiedCastScreen` | `class _LiuYaoCastScreen` | 类声明（加下划线变私有） |
| `const UnifiedCastScreen({super.key})` | `const _LiuYaoCastScreen()` | 构造器（私有类不对外暴露 key） |
| `State<UnifiedCastScreen> createState()` | `State<_LiuYaoCastScreen> createState()` | createState 返回类型 |
| `=> _UnifiedCastScreenState()` | `=> _LiuYaoCastScreenState()` | createState 返回值 |
| `class _UnifiedCastScreenState extends State<UnifiedCastScreen>` | `class _LiuYaoCastScreenState extends State<_LiuYaoCastScreen>` | State 类声明 |

在新追加的 `_LiuYaoCastScreen` 类上方加 docstring：

```dart
/// 六爻起卦页面（内部私有）
///
/// 此前作为 platform-level `UnifiedCastScreen` 存在。
/// 收敛 spec §3.3.1 明确该 widget 实际只服务六爻，
/// 已迁至六爻 UI 工厂内部为文件私有类。
```

State 类内部的所有字段、生命周期方法、`_handleCast` / `_buildXxx` helper、build() 返回内容等——**全部保持原样**，不动一个字符。

若原 `UnifiedCastScreen` 类声明了任何 `static const routeName` 之类的静态成员（因为是否存在需现场确认），根据调用方：
- 若 `routeName` 未被任何地方引用，直接删除
- 若被引用，在调用点改为具体字符串（私有类不应暴露 routeName）

- [ ] **Step 3: 合并 imports**

原 `unified_cast_screen.dart` 有些 imports 可能 `liuyao_ui_factory.dart` 没有。把两份 imports 合并，去重，排序。

常见需要新加的 imports：
- provider（如 `_UnifiedCastScreenState` 使用 `context.read<LiuYaoViewModel>`）
- shared_preferences（若原文件用了）
- 其他六爻特定服务

- [ ] **Step 4: 修改工厂 `buildCastScreen` 返回**

```dart
@override
Widget buildCastScreen(CastMethod method) {
  return const _LiuYaoCastScreen();
}
```

删除顶部 `import '../../../presentation/screens/cast/unified_cast_screen.dart';`。

- [ ] **Step 5: 编译 + 测试，确认迁移正确**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -3
```

Expected: analyze clean; 283 tests pass.

若 analyze 报 "UnifiedCastScreen is undefined"，说明还有 stale 引用——用 grep 找：
```bash
grep -rn "UnifiedCastScreen" lib/ test/
```
每个点改为 `_LiuYaoCastScreen` 或移除。

- [ ] **Step 6: 删除旧文件**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
rm lib/presentation/screens/cast/unified_cast_screen.dart
```

`lib/presentation/screens/cast/` 下是否还有其他文件？看：`ls lib/presentation/screens/cast/`。
- 若变空：`rmdir lib/presentation/screens/cast/`（并在后续 commit 里标注"清空目录同时删除"）
- 若有其他文件：留目录

- [ ] **Step 7: 最终验证**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rn "UnifiedCastScreen\|unified_cast_screen" lib/ test/ 2>/dev/null
```
Expected: 0 结果。

```bash
flutter analyze && flutter test 2>&1 | tail -3
```
Expected: clean; 283 tests pass.

- [ ] **Step 8: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add -A lib/divination_systems/liuyao/ui/ lib/presentation/screens/cast/
git commit -m "refactor(liuyao): internalize UnifiedCastScreen as _LiuYaoCastScreen

Per convergence spec §3.3.1, UnifiedCastScreen was a misleading
platform-level name for what was always 六爻-specific cast UI.
Moved into liuyao_ui_factory.dart as a file-private class named
_LiuYaoCastScreen, following the same pattern as
_LiuYaoResultScreenWithAI and DLR's _DaLiuRenCastScreen.

No behavior change; purely scope narrowing."
```

---

### Task 4: Phase B 中间验证

目的：三次边界清理（Task 1/2/3）全部落地后，抓一遍全局 sanity，确保没有遗漏的 dangling 引用、未删的 import、破碎的测试。

- [ ] **Step 1: 全局 grep 检查无遗漏**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rn "UnifiedCastScreen\|unified_cast_screen" lib/ test/ 2>/dev/null
grep -rn "buildSystemCard" lib/ test/ 2>/dev/null
grep -rn "import.*result_screen\|ResultScreen(" lib/ test/ 2>/dev/null | grep -v divination_ui_registry
```

Expected: 0 结果。`divination_ui_registry.dart` 的文档注释里可能还有"LiuYaoResultScreen"字样作为示例，这是文档描述不是 API 引用，允许存在。

- [ ] **Step 2: flutter analyze + test**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -5
```

Expected: analyze clean; 全量 283 tests pass.

- [ ] **Step 3: 确认目录结构**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
ls lib/presentation/screens/
find lib/divination_systems/liuyao/ -type f -name "*.dart"
```

期望：
- `lib/presentation/screens/` 下不再有 `/result/` 和（可能）`/cast/` 子目录
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart` 变大了（吸收了 UnifiedCastScreen 内容，~620 行）

- [ ] **Step 4: 无需 commit**（Task 1/2/3 的 commit 已覆盖全部代码变动）

---

## Phase A — 文档契约纠偏（代码事实已定后做）

### Task 5: 更新 `docs/UI设计指导.md`

目的：修订 spec 已是新权威（commit 538900f），指导文档也要同步，消除"文档说一套、代码跑另一套"。

**Files:**
- Modify: `docs/UI设计指导.md`

- [ ] **Step 1: 读当前文档了解结构**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
wc -l docs/UI设计指导.md
grep -nE "^#+ " docs/UI设计指导.md
```

目标：了解有多少章、每章是什么，避免破坏原结构。

- [ ] **Step 2: 顶部 preamble 扩充**

当前文档顶部已有 Plan A+B+C1+C2 的演进声明，补充：

```markdown
> **2026-04-18 更新**：完成 antique 体系 → 收敛方案（revised spec）更新；
> 当前权威 spec 见 `docs/superpowers/specs/2026-04-17-unified-antique-ui-design.md`。
>
> 本文档只记录"设计意图层"，不再包含"待建设清单"——
> 实际组件库状态以 `lib/presentation/widgets/antique/` 为准。
```

- [ ] **Step 3: 在"组件库引用"一节加 chromeless/body-only 说明**

在 antique 组件 10 件套表格之后补一段：

```markdown
#### chromeless/body-only 能力（正式支持）

`AntiqueScaffold` 只应出现在**顶层页面壳**。当一个页面需要被**嵌入**到另一个页面（如 `HistoryListScreen` 被嵌入到 `HomeScreen` 的历史 tab），该嵌入目标必须支持 chromeless 模式——即**返回 body-only 内容**，不包含自己的 `AntiqueScaffold` / `AntiqueAppBar` 外壳。

已采用此模式的例子：
- `HistoryListScreen(chromeless: true)` —— 当作为 home tab 1 的 body 使用时不带外壳

规则：当一个页面组件可能在多种上下文（独立路由 / 嵌入 tab / 嵌入 dialog）中被使用时，默认应提供 `chromeless` 构造参数。
```

- [ ] **Step 4: 在文档尾部（或适当章节）加"token 单一来源"规则**

```markdown
## Token 单一来源

所有视觉 token 的权威位置：

| 维度 | 权威文件 |
|---|---|
| 颜色 | `lib/core/theme/app_colors.dart` |
| 字体样式 | `lib/core/theme/app_text_styles.dart` |
| 形状 / 间距 / 阴影 / 渐变 | `lib/core/theme/antique_tokens.dart` |

**禁止**在其他位置引入第二套别名（如 `zhushaHong` 之类），**禁止**在页面或 UI 工厂内硬编码通用色字面量。
领域色（六亲 / 五行 / 铜钱面等）允许保留 inline 但必须带 `//` 注释说明用途。
```

- [ ] **Step 5: 取消"大六壬迁移 pixel diff = 0"门禁表述**

如文档里提到 pixel diff = 0 作为硬门禁，改为：

```markdown
代表性页面的 golden 用于**视觉不回退**检查，但不把"全局 pixel diff = 0"作为跨 Flutter 小版本 / 字体渲染差异的硬标准。
```

（若原文无此表述，跳过这步。）

- [ ] **Step 6: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add docs/UI设计指导.md
git commit -m "docs(ui-guide): sync with revised convergence spec

- preamble adds 2026-04-18 update pointer to revised spec
- add chromeless/body-only as formally-supported pattern
- add Token single-source-of-truth section  
- relax pixel-diff=0 language where present"
```

---

### Task 6: CLAUDE.md 补 chromeless/body-only 能力说明

**Files:**
- Modify: `CLAUDE.md`（项目级）

- [ ] **Step 1: 在"Presentation 层"或"Development Guidelines"区域加一段**

编辑 `CLAUDE.md`，在 Development Guidelines 列表里（找 "UI Widgets: Should be 'dumb'..." 附近）补一项：

```markdown
- **Chromeless / body-only**: Any screen that might be embedded into another screen (tab body / dialog / bottom sheet) must provide a `chromeless` constructor parameter. When `chromeless: true`, the screen should return body-only content without wrapping itself in `AntiqueScaffold` / `AntiqueAppBar`. Reference implementation: `HistoryListScreen(chromeless: true)` used by `HomeScreen` tab 1.
```

- [ ] **Step 2: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add CLAUDE.md
git commit -m "docs(claude): add chromeless/body-only as formal UI pattern"
```

---

## Phase E — 测试门禁重构

### Task 7: 加 CI 静态审计 step 禁新增硬编码色

目的：Plan C1 把 widget 残留 hex 从 63 降到 33（全部是有注释的域色）。为防止未来回退，CI 加一个 grep-based audit——检测新提交里 `lib/presentation/` 和 `lib/divination_systems/*/ui/` 下新增的无注释 `Color(0xFFXXXXXX)` 字面量。

**Files:**
- Create: `tool/audit_hardcoded_colors.sh`（或 `.bat`，看 CI runner）
- Modify: `.github/workflows/flutter_ci.yml`

- [ ] **Step 1: 检查 CI runner 平台**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -A2 "runs-on" .github/workflows/flutter_ci.yml
```

记录 runner 平台（通常是 `ubuntu-latest`）。后续脚本用 bash。

- [ ] **Step 2: 创建审计脚本**

Create `tool/audit_hardcoded_colors.sh`：

```bash
#!/usr/bin/env bash
#
# 检查 lib/presentation/ 和 lib/divination_systems/*/ui/ 下
# 是否存在无注释的硬编码 Color(0xFFXXXXXX) 字面量。
#
# 允许：同行或上方 1 行内有 // 注释的 Color 字面量（域色/语义色）
# 禁止：新增的无注释 Color 字面量
#
# 运行方式：tool/audit_hardcoded_colors.sh
# 退出码：有未注释硬编码返回 1，否则 0

set -euo pipefail

TARGETS=(
  "lib/presentation"
  "lib/divination_systems"
)

VIOLATIONS=0

for dir in "${TARGETS[@]}"; do
  # 找所有 Color(0xFFXXXXXX) 行（Color 全长含 alpha 8 位 hex 也算）
  while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    lineno=$(echo "$line" | cut -d: -f2)
    # 跳过 antique/ 目录（token 组件自身引用 AppColors，不会命中 0xFF 字面量，但保险跳过）
    if [[ "$file" == *"/widgets/antique/"* ]]; then
      continue
    fi
    # 检查该行本身或上一行是否有 // 注释
    if grep -q "//" <(sed -n "${lineno}p" "$file") || \
       (( lineno > 1 )) && grep -q "//" <(sed -n "$((lineno-1))p" "$file"); then
      continue  # 有注释，放行
    fi
    echo "ERROR: unannotated hardcoded color at $file:$lineno"
    echo "  $(sed -n "${lineno}p" "$file" | sed 's/^/    /')"
    VIOLATIONS=$((VIOLATIONS+1))
  done < <(grep -rn -E 'Color\(0x[0-9A-Fa-f]{8}\)' "$dir" 2>/dev/null || true)
done

if (( VIOLATIONS > 0 )); then
  echo ""
  echo "Found $VIOLATIONS unannotated hardcoded Color literal(s)."
  echo "Use AppColors.* tokens, or add a // comment explaining why this domain-specific color is retained inline."
  exit 1
fi

echo "OK: no unannotated hardcoded Color literals."
exit 0
```

Make executable: `chmod +x tool/audit_hardcoded_colors.sh`

- [ ] **Step 3: 本地验证脚本能跑通当前代码（应该 pass 因为 Plan C1 残留都有注释）**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
bash tool/audit_hardcoded_colors.sh
```

Expected: `OK: no unannotated hardcoded Color literals.` 退出 0。

若报 violation，说明 Plan C1 遗漏了几处——记下来当场修掉（加 `//` 注释或换成 AppColors），再跑一遍直到 pass。

- [ ] **Step 4: 在 CI workflow 里挂入**

Edit `.github/workflows/flutter_ci.yml`，在现有 `flutter analyze` step 之后追加：

```yaml
      - name: Audit hardcoded colors
        run: bash tool/audit_hardcoded_colors.sh
```

（注意缩进要对齐）

- [ ] **Step 5: 本地再跑一次验证 yml 没坏**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
# YAML 语法检查（若本地有 yamllint）
yamllint .github/workflows/flutter_ci.yml || echo "(yamllint not installed, skip)"

# 如果装了 act (nektos/act) 可以本地跑 workflow 验证：
# act -j analyze
```

YAML 缩进正确、脚本本地能跑、analyze step 仍通过——OK。

- [ ] **Step 6: Commit**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add tool/audit_hardcoded_colors.sh .github/workflows/flutter_ci.yml
git commit -m "ci: add hardcoded color audit to flutter_ci

Per convergence spec §4.5 (Phase E), gate against regression:
new unannotated Color(0xFFXXXXXX) literals in lib/presentation/
and lib/divination_systems/*/ui/ fail CI.

Allowed:
- AppColors.* / AppTextStyles.* tokens (no literal)
- inline literal with // comment explaining domain semantics
  (六亲色 / 五行色 / 铜钱面 / 阴阳爻线蓝 等)

Currently 33 annotated domain-color literals exist in
presentation widgets (per Plan C1 verification) and will not
trigger this check."
```

---

### Task 8: 最终全量验证

- [ ] **Step 1: 跑所有测试**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter test 2>&1 | tail -3
```

Expected: 283 tests pass.

- [ ] **Step 2: flutter analyze 全项目**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: 本地跑审计脚本**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
bash tool/audit_hardcoded_colors.sh
```

Expected: OK.

- [ ] **Step 4: Plan D1 所有 commits 清单**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git log --oneline <plan-d1-base>..HEAD
```

（`<plan-d1-base>` = 538900f 即 revised spec commit 的 SHA）

Expected: 6-8 个 commits，覆盖全部 Task 1-7 的交付。

- [ ] **Step 5: 提交 Plan D1 的 plan 文档本身（如果之前没提交）**

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git status
# 若 plan 文档尚未提交
git add docs/superpowers/plans/2026-04-18-antique-convergence-phase-1.md
git commit -m "docs(plan): Plan D1 - convergence Phase A/B/E"
```

- [ ] **Step 6: 无需单独 verification commit**（所有 Phase 结束验证已嵌入各 task 内部）

---

## 完成标志

1. ✅ `lib/presentation/screens/result/result_screen.dart` 已删除
2. ✅ `lib/presentation/screens/cast/unified_cast_screen.dart` 已删除，内容迁入 `liuyao_ui_factory.dart` 作为 `_LiuYaoCastScreen` 私有类
3. ✅ `DivinationUIFactory` 接口移除 `buildSystemCard()`，两个工厂的 override 同步删除
4. ✅ `docs/UI设计指导.md` 补 chromeless/body-only 正式支持声明 + token 单一来源规则
5. ✅ `CLAUDE.md` 补 chromeless 开发约定
6. ✅ `tool/audit_hardcoded_colors.sh` 就位，CI 挂接
7. ✅ `flutter analyze` 0 issues
8. ✅ `flutter test` 283 tests 全过
9. ✅ `bash tool/audit_hardcoded_colors.sh` exit 0

---

## 范围外（留给 Plan D2）

- **Phase C 视觉债务**：`divination_systems/*/ui/` 内残留的原生 `Card`/`TextField`/`TextStyle`，非 antique 控件替换
- **Phase D Theme/字体**：`ThemeData` 承接 token 作为兜底层 + 字体资产入 pubspec 或改口文档
- **暗黑模式** Plan C3（之前已搁置）
- **新术数系统实现**（小六壬 / 梅花易数）
- **深度 a11y**（focus order / keyboard traversal）
