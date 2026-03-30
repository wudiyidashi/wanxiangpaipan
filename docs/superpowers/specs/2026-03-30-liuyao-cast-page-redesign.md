# 六爻起卦页合并重设计

## 背景

当前六爻流程需要 3 次页面跳转：主页 → 起卦方式选择 → 起卦操作 → 结果页。"起卦方式选择"作为独立页面是多余的，需要合并到起卦页中，减少跳转。

## 目标

将导航流程从 `主页 → 方式选择 → 起卦 → 结果` 简化为 `主页 → 起卦 → 结果`（2 次跳转）。

## 设计决策

| 决策项 | 结论 |
|--------|------|
| 方式选择交互 | DropdownButton 下拉选择 |
| 默认选中方式 | 记住上次选择（SharedPreferences） |
| 摇钱动画 | 去掉，点击直接计算跳转 |
| 问题输入位置 | 页面顶部，所有方式共享 |
| 起卦触发方式 | 点击按钮 |

## 视觉设计

### 设计理念

新中式极简（Neo-Chinese Minimalist）+ 禅意美学。大量留白，提取传统神韵用现代设计语言重构。

### 配色方案

| 颜色 | 色值 | 用途 |
|------|------|------|
| 黛蓝 | #2B4570 | 文字、标题 |
| 朱红 | #C84B31 | 起卦按钮 |
| 哑金 | #B79452 | 分隔线、装饰、下拉箭头 |
| 米白 | #F7F7F5 | 宣纸纹理背景 |
| 辅助文字 | #8B7355 | 标签文字 |
| 占位文字 | #A0937E | 输入框提示 |

### 字体

宋体 Serif 系列（Songti SC / SimSun），标签使用 letter-spacing 增加古典间距。

### 页面布局（从上到下）

页面标题由 AppBar 承担，页面内无重复标题。

1. **占问事项**（TextInput）
   - 标签：哑金色小字，letter-spacing
   - 输入框：半透明白底 `rgba(255,255,255,0.6)`，哑金细边框，圆角 8px
   - 提示文字："请输入您想占问的事项..."

2. **起卦方式**（DropdownButton）
   - 同样式输入框外观
   - 下拉箭头使用哑金色
   - 上次选择通过 SharedPreferences 持久化

3. **哑金分隔线**
   - `rgba(183,148,82,0.25)` 细线

4. **操作区**（随方式动态切换）
   - 见下方各方式详细说明

5. **底部爻线占位符**（仅摇钱法和时间起卦显示）
   - 6 条水墨渐隐风格线条，暗示卦象生成位置
   - 下方淡色标注"卦象"

### 背景装饰

- 宣纸纹理渐变：`linear-gradient(135deg, #F7F7F5, #F0EDE8)`
- 淡金罗盘同心圆：2-3 个同心圆，`rgba(183,148,82, 0.07~0.15)` 边框

### 起卦按钮

- 朱红渐变：`linear-gradient(135deg, #C84B31, #A63A24)`
- 白色宋体文字"起卦"，letter-spacing: 3px
- 圆角 24px，带投影 `box-shadow: 0 3px 10px rgba(200,75,49,0.3)`

## 三种起卦方式的操作区

### 摇钱法

- 三枚铜钱视觉元素（居中展示，带轻微旋转角度和阴影）
- "起卦"按钮
- 点击后直接调用 `viewModel.castByCoin()` 并跳转结果页

### 时间起卦

- 显示"当前时辰"标签
- 农历干支日期（大字黛蓝色）
- 公历日期和时辰（小字辅助色）
- "起卦"按钮
- 点击后直接调用 `viewModel.castByTime()` 并跳转结果页

### 手动输入

- 起卦时间选择器（日期 + 时间，一行排列）
- 六爻输入：6 个下拉选择框，**从上到下单列排列**（初爻 → 六爻）
- "起卦"按钮
- 点击后调用 `viewModel.castByManualYaoNumbers()` 并跳转结果页

## 代码变更

### 新增

- `lib/presentation/screens/cast/unified_cast_screen.dart` — 合并后的起卦页面
  - 包含问题输入、方式下拉、动态操作区
  - 使用 SharedPreferences 记忆上次选择的方式

### 修改

- `lib/presentation/widgets/divination_system_card.dart` — 导航目标改为直接 push UnifiedCastScreen
- `lib/main.dart` — 移除 `/method-selector` 路由
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart` — `buildCastScreen` 返回 UnifiedCastScreen

### 删除

- `lib/presentation/screens/home/method_selector_screen.dart` — 不再需要

### 不变

- `lib/presentation/screens/result/result_screen.dart` — 结果页保持不变
- `lib/divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart` — ViewModel 接口不变
- 所有业务逻辑和数据层不受影响
