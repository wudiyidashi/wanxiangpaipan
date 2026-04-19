# 小六壬系统说明

**系统类型**：`DivinationType.xiaoLiuRen`  
**状态**：Disabled / Core Cast Contract Landed  
**当前权威实现**：

- `lib/divination_systems/xiaoliuren/xiaoliuren_system.dart`
- `lib/divination_systems/xiaoliuren/models/xiaoliuren_result.dart`

---

## 1. 文档定位

本文件不是概念说明，而是小六壬当前唯一有效的开发契约。

后续 UI、历史记录、AI formatter、仓储序列化，都必须以这里定义的：

1. 起课方式
2. 输入 payload
3. 结果字段
4. 六宫 / 九宫边界

为准，不允许再在展示层临时发明另一套字段或口径。

---

## 2. 系统定位

小六壬第一版固定定位为：

1. 轻量速断系统
2. 以“三段取数、顺推落宫”为核心
3. 结果重点是推算链与最终落宫
4. 不伪装成大盘式系统

因此当前输出重点必须是：

1. 起课来源
2. 三段数字
3. 三次落宫
4. 最终落宫
5. 固定宫义

---

## 3. 当前代码状态

当前实现事实如下：

- `isEnabled = false`
- `cast()` 已实现 `time / reportNumber / characterStroke`
- `validateInput()` 已按三种方式严格收敛
- `XiaoLiuRenResult` 已使用正式结果模型
- `XiaoLiuRenSource` 已统一为三段输入源结构
- `palaceMode` 已入结果对象
- 当前已实现 `六宫 / 九宫`
- UI 工厂与 AI formatter 仍未接入

---

## 4. 盘式边界

### 4.1 当前实现盘式

当前底层允许：

- `XiaoLiuRenPalaceMode.sixPalaces`
- `XiaoLiuRenPalaceMode.ninePalaces`

六宫版：

1. 大安
2. 留连
3. 速喜
4. 赤口
5. 小吉
6. 空亡

### 4.2 九宫状态

九宫版当前采用你确认的规则：

1. 九神顺序固定为：`大安 -> 留连 -> 速喜 -> 赤口 -> 小吉 -> 空亡 -> 病符 -> 桃花 -> 天德`
2. 顺推规则与六宫完全同构
3. 唯一变化是循环长度从 `6` 变为 `9`

九宫九神如下：

1. 大安
2. 留连
3. 速喜
4. 赤口
5. 小吉
6. 空亡
7. 病符
8. 桃花
9. 天德

### 4.3 九宫公式

九宫与六宫同样采用：

1. 起点记 `1`
2. 第一段从 `大安` 起
3. 第二段从第一落宫起
4. 第三段从第二落宫起

公式：

- `firstIndex = ((firstNumber - 1) % 9) + 1`
- `secondIndex = ((firstIndex - 1) + (secondNumber - 1)) % 9 + 1`
- `thirdIndex = ((secondIndex - 1) + (thirdNumber - 1)) % 9 + 1`

当前工程结论：

- 结果对象输出真实 `palaceMode`
- 未传 `palaceMode` 时默认 `sixPalaces`
- 传 `palaceMode = ninePalaces` 时走九宫

---

## 5. 第一版必须支持的起课方式

| 方式 | `CastMethod` | 当前状态 | 底层输入形态 |
|---|---|---|---|
| 时间起 | `time` | 已实现 | 由 `castTime` 推农历月、日、时支 |
| 报数起 | `reportNumber` | 已实现 | 三个数字 |
| 汉字笔画起 | `characterStroke` | 已实现 | 三段笔画数 |

### 5.1 当前明确不做的事

1. 不再保留旧 `manual`
2. 不接受同一个 `CastMethod` 下多种 payload 形态
3. 不自动把汉字转笔画
4. `objectSound` 暂不纳入小六壬第一版
5. 不做九宫兼容流派分支

---

## 6. 六宫固定规则

### 6.1 六宫顺序

| 序号 | 宫位 | 吉凶 | 关键词 | 五行 | 方位 |
|---|---|---|---|---|---|
| 1 | 大安 | 吉 | 诸事安稳 | 木 | 东方 |
| 2 | 留连 | 凶 | 迟滞反复 | 水 | 北方 |
| 3 | 速喜 | 吉 | 喜信速来 | 火 | 南方 |
| 4 | 赤口 | 凶 | 口舌是非 | 金 | 西方 |
| 5 | 小吉 | 吉 | 小成可望 | 木 | 东方 |
| 6 | 空亡 | 凶 | 事易落空 | 土 | 中央 |

### 6.2 时间起的时支序数

| 地支 | 数 |
|---|---|
| 子 | 1 |
| 丑 | 2 |
| 寅 | 3 |
| 卯 | 4 |
| 辰 | 5 |
| 巳 | 6 |
| 午 | 7 |
| 未 | 8 |
| 申 | 9 |
| 酉 | 10 |
| 戌 | 11 |
| 亥 | 12 |

### 6.3 推算铁则

小六壬当前统一使用一套规则：

1. 大安起第一段
2. 第一段结果上起第二段
3. 第二段结果上起第三段
4. 各段统一“起点记 1”
5. 宫位循环按 6 取余

这套规则对当前三种起课方式全部生效；六宫与九宫只改循环长度与宫序，不改顺推逻辑。

---

## 7. 输入契约

### 7.1 `time`

```dart
{}
```

说明：

1. 只接受空输入
2. 使用 `castTime`
3. 取农历月数、农历日数、时支序数
4. 闰月按 `abs(lunarMonth)` 处理

若要显式指定九宫，可传：

```dart
{
  'palaceMode': 'ninePalaces',
}
```

### 7.2 `reportNumber`

```dart
{
  'firstNumber': 4,
  'secondNumber': 18,
  'thirdNumber': 7,
  'palaceMode': 'ninePalaces', // optional
}
```

约束：

1. 只能包含这三个字段
2. 三个字段都必须为正整数
3. 允许额外附带 `palaceMode`
4. 不允许其他字段

说明：

1. 第一数从大安起
2. 第二数从第一落宫起
3. 第三数从第二落宫起

### 7.3 `characterStroke`

```dart
{
  'firstStroke': 8,
  'secondStroke': 11,
  'thirdStroke': 6,
  'palaceMode': 'ninePalaces', // optional
}
```

约束：

1. 只能包含这三个字段
2. 三个字段都必须为正整数
3. 允许额外附带 `palaceMode`
4. 不允许其他字段

说明：

1. 当前底层**不负责**汉字转笔画
2. UI 或上层服务必须先把输入文本拆成三段笔画数，再调用 `cast()`
3. 三段笔画的业务语义由上层定义，例如首字 / 次字 / 末字，或三词段

### 7.4 `validateInput()` 目标行为

当前必须严格保证：

1. `time`：只接受空输入
2. `time`：可额外附带 `palaceMode`
3. `reportNumber`：只接受 `firstNumber + secondNumber + thirdNumber`，可额外附带 `palaceMode`
4. `characterStroke`：只接受 `firstStroke + secondStroke + thirdStroke`，可额外附带 `palaceMode`

不得：

1. 无条件返回 `true`
2. 静默补默认值
3. 忽略多余字段
4. 继续兼容旧 `manual`
5. 提前暴露 `objectSound`

---

## 8. 排盘主链

### 8.1 第一段

- 以第一段数值从 `大安` 起算

公式：

- `firstIndex = ((firstNumber - 1) % 6) + 1`

### 8.2 第二段

- 从第一段落宫起第二段

公式：

- `secondIndex = ((firstIndex - 1) + (secondNumber - 1)) % 6 + 1`

### 8.3 第三段

- 从第二段落宫起第三段

公式：

- `thirdIndex = ((secondIndex - 1) + (thirdNumber - 1)) % 6 + 1`

### 8.4 最终落宫

当前固定为：

- `finalPosition = thirdPosition`

### 8.5 盘式选择

当前盘式选择规则固定为：

1. 未传 `palaceMode`：默认 `sixPalaces`
2. 传 `palaceMode = sixPalaces`：使用六宫
3. 传 `palaceMode = ninePalaces`：使用九宫

---

## 9. 结果对象契约

小六壬结果对象当前至少必须具备：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 记录唯一标识 |
| `castTime` | `DateTime` | 起课时间 |
| `castMethod` | `CastMethod` | 起课方式 |
| `systemType` | `DivinationType.xiaoLiuRen` | 系统类型 |
| `lunarInfo` | `LunarInfo` | 农历上下文 |
| `palaceMode` | `XiaoLiuRenPalaceMode` | 盘式，支持 `sixPalaces / ninePalaces` |
| `source` | `XiaoLiuRenSource` | 输入源与推算痕迹 |
| `monthPosition` | `XiaoLiuRenPosition` | 第一段落宫 |
| `dayPosition` | `XiaoLiuRenPosition` | 第二段落宫 |
| `hourPosition` | `XiaoLiuRenPosition` | 第三段落宫 |
| `finalPosition` | `XiaoLiuRenPosition` | 最终落宫 |
| `judgement` | `String` | 一句话断语 |
| `detail` | `String` | 完整推算说明 |
| `questionId` | `String` | 加密问事引用位 |
| `detailId` | `String` | 加密详情引用位 |
| `interpretationId` | `String` | 加密解读引用位 |

### 9.1 `XiaoLiuRenSource`

必须包含：

1. `methodLabel`
2. `firstNumber`
3. `secondNumber`
4. `thirdNumber`
5. `firstLabel`
6. `secondLabel`
7. `thirdLabel`
8. `hourZhi`
9. `usesLunarDate`
10. `rule`
11. `note`

说明：

- `first / second / third` 是统一底层字段，不再按旧 `month/day/hour` 命名
- 时间起只是把三段标签分别写成 `月数 / 日数 / 时数`
- 其他起课方式按自身语义写成 `数一 / 数二 / 数三`、`首字笔画 / 次字笔画 / 末字笔画`、`象数一 / 象数二 / 象数三`

### 9.2 `XiaoLiuRenPosition`

必须包含：

1. `index`
2. `name`
3. `fortune`
4. `keyword`
5. `description`
6. `wuXing`
7. `direction`

---

## 10. 摘要与断语规则

### 10.1 `getSummary()`

固定格式：

- `宫位名 · 关键词`

示例：

- `大安 · 诸事安稳`
- `速喜 · 喜信速来`
- `赤口 · 口舌是非`

### 10.2 `judgement`

当前按最终落宫固定输出一句话，不做 AI 风格变体。

例如：

- 大安：`大安，主诸事安稳，宜守正稳进。`
- 留连：`留连，主迟滞反复，宜缓不宜急。`
- 速喜：`速喜，主喜信速来，利推进与回音。`
- 赤口：`赤口，主口舌是非，宜谨言慎行。`
- 小吉：`小吉，主小成可望，利人和与渐进。`
- 空亡：`空亡，主事易落空，宜暂缓定论。`

### 10.3 `detail`

必须同时保留：

1. 规则说明
2. 第一段输入与落宫
3. 第二段输入与推算结果
4. 第三段输入与推算结果
5. 最终落宫与基础宫义

---

## 11. 结果页与历史页预留规范

虽然当前 UI 未启用，但启用时必须按以下结构接入。

### 11.1 结果页

结果页至少要显示：

1. 占问事项
2. 时间上下文
3. 起课方式
4. 盘式
5. 三段输入
6. 三段落宫
7. 最终落宫
8. 宫义说明

### 11.2 历史卡片

历史卡片最低必须展示：

1. 占问事项
2. 起课时间
3. `getSummary()`
4. 系统类型 badge
5. 起课方式 badge

---

## 12. 固定样例

### 12.1 时间起

起课时间：`2026-04-19 09:22`

推算：

1. 农历月数 `3` -> `速喜`
2. 日数 `3` 从 `速喜` 推 -> `小吉`
3. 时支 `巳`，时数 `6` 从 `小吉` 推 -> `赤口`

结果：

- `finalPosition = 赤口`
- `summary = 赤口 · 口舌是非`

### 12.2 报数起

输入：

```dart
{
  'firstNumber': 4,
  'secondNumber': 18,
  'thirdNumber': 7,
}
```

推算：

1. `4` -> `赤口`
2. `18` 从 `赤口` 推 -> `速喜`
3. `7` 从 `速喜` 推 -> `速喜`

结果：

- `summary = 速喜 · 喜信速来`

### 12.3 时间起九宫样例

输入：

```dart
{
  'palaceMode': 'ninePalaces',
}
```

起课时间：`2026-04-19 09:22`

推算：

1. 农历月数 `3` -> `速喜`
2. 日数 `3` 从 `速喜` 推 -> `小吉`
3. 时支 `巳`，时数 `6` 从 `小吉` 推 -> `大安`

结果：

- `finalPosition = 大安`
- `summary = 大安 · 诸事安稳`

---

## 13. 变更要求

后续若要继续推进小六壬，必须先写文档再改代码，尤其是：

1. 启用 UI
2. 接入 AI formatter
3. 引入九宫完整算法
4. 引入自动笔画换算
5. 引入物象 / 声音到数值的正式映射规则

在这些规则未固化前，不得以“先做个兼容版”名义绕开当前契约。
