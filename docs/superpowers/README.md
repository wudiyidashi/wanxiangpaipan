# Superpowers 工程归档索引

本目录存放项目重大工程任务的 **spec（设计规格）** 与 **plan（实施计划）**，按时间倒序记录。

所有 spec / plan 都是一次性文档——落地后不再维护。当前代码状态以 `main` 分支为准；文档记录了"当时是这样决定的"。

---

## 2026-04 历史记录页体验优化

### Specs

- [`specs/2026-04-18-history-screen-design.md`](specs/2026-04-18-history-screen-design.md) — 历史记录页整体信息架构、状态页、检索能力与 `chromeless` 约束（框架）
- [`specs/2026-04-18-history-card-visual-design.md`](specs/2026-04-18-history-card-visual-design.md) — 历史记录卡片视觉规格（美学方向、背景图水印、5 层 typography、共享组件骨架）

### Plans

- **Plan E1 — 历史页升级 Phase 1**（[`plans/2026-04-18-history-screen-phase-1.md`](plans/2026-04-18-history-screen-phase-1.md)）
  - 搜索 / 排序 / 时间分组 / 统一筛选状态条 / 四类状态页
  - 状态：✅ 已落地（commit `df62c9d`）
  - Bug fix 联动：DLR 不保存记录 → 统一 5 层卡片骨架（commits `29c5687` / `a92fd95`）

主题：从"记录列表工具"升级为"跨术数历史检索与回顾中心"。视觉设计 spec 的实现 plan 待后续拆。

---

## 2026-04 仿古风设计体系（Antique UI System）

- **Spec**: [`specs/2026-04-17-unified-antique-ui-design.md`](specs/2026-04-17-unified-antique-ui-design.md) — 全应用统一仿古风的设计规范（色板/字体/组件/装饰/迁移路径）

### 四个顺序落地的 plan

1. **Plan A — 基础设施** ([`plans/2026-04-17-antique-design-system-foundation.md`](plans/2026-04-17-antique-design-system-foundation.md))
   - 扩展 `AppColors` / `AppTextStyles`，新增 `AntiqueTokens`
   - 建成 `lib/presentation/widgets/antique/` 共享组件库（10 原子组件 + barrel）
   - 大六壬 UI 工厂迁移到新组件（作为回归锚点）
   - 状态：✅ 已落地

2. **Plan B — 页面迁移** ([`plans/2026-04-18-antique-screen-migration.md`](plans/2026-04-18-antique-screen-migration.md))
   - 9 个页面 + 六爻 UI 工厂应用 antique 组件库
   - `AntiqueTextField` 扩展 6 个参数（maxLines 可空、obscureText、expands 等）
   - `AntiqueScaffold` SafeArea 修复（解决 `extendBodyBehindAppBar` 顶部留白 bug）
   - `HistoryListScreen` 引入 `chromeless` 模式
   - 状态：✅ 已落地

3. **Plan C1 — widget 残留清理** ([`plans/2026-04-18-antique-widget-cleanup.md`](plans/2026-04-18-antique-widget-cleanup.md))
   - `lib/presentation/widgets/` 下 18 个内容组件色值/字体 token 化
   - 残留硬编码色 63 → 33（全部是有注释的域色：阴阳爻线色、铜钱面色、六亲六神指示色等）
   - 结果页 3 个 section（Card→AntiqueCard + AntiqueSectionTitle）
   - 状态：✅ 已落地

4. **Plan C2 — AntiqueDialog + a11y** ([`plans/2026-04-18-antique-dialog-a11y.md`](plans/2026-04-18-antique-dialog-a11y.md))
   - 新增 `AntiqueDialog` 组件 + `showAntiqueDialog()` helper
   - 迁移历史页删除确认对话框
   - 9 个 antique 组件加上 Semantics 标签（button/header/label/excludeSemantics）
   - 11 个新 a11y widget test
   - 状态：✅ 已落地

### 范围外、已明确打入"未来工作"

- **Plan C3（暗黑模式）**：墨色主题 + 整套 token 暗色变体 + 主题切换 UI。未启动
- **token 缺口补齐**：中间灰度 / 暖纸色 / 大号 display 字号（Plan C1 末尾识别出的 gaps，留给 Plan C3 或单独 plan）
- 卡片 staggered 载入动画、呼吸动效、HapticFeedback
- 紫微斗数、奇门遁甲 UI 工厂

---

## 2026-03 六爻起卦页重设计

- **Spec**: [`specs/2026-03-30-liuyao-cast-page-redesign.md`](specs/2026-03-30-liuyao-cast-page-redesign.md)
- **Plan**: [`plans/2026-03-30-liuyao-cast-page-redesign.md`](plans/2026-03-30-liuyao-cast-page-redesign.md)
- 产出：统一起卦页 `UnifiedCastScreen` 的第一版（后被 Plan B 进一步仿古风迁移）
- 状态：✅ 已落地

---

## 2026-04-14 大六壬仿古风独立重设计

- **Plan**: [`plans/2026-04-14-daliuren-antique-ui-redesign.md`](plans/2026-04-14-daliuren-antique-ui-redesign.md)
- 产出：大六壬起课页 + 结果页首版仿古风 UI（硬编码在 `daliuren_ui_factory.dart` 内部）
- Plan A 后来把这些硬编码样式下沉到共享 antique 组件库
- 状态：✅ 已落地（但样式已被 Plan A 迁移到共享组件）

---

## 如何阅读这些文档

- 要理解**当前**代码为什么长这样 → 看最新 plan
- 要理解**历史决策**（为什么选 A 不选 B） → 看对应 spec 的"取舍"/"风险"部分
- 要给自己参考**迁移模式**（下次搬运类似工作） → 看 plan 里的 "通用迁移规则" 表

**不要**把这些文档当作 living docs——它们是历史快照，不会随代码演进更新。当前事实永远以 `main` 分支代码 + `README.md` + `CLAUDE.md` 为准。
