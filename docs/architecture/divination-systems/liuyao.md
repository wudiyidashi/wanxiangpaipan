# 六爻系统说明

**系统类型**：`DivinationType.liuYao`  
**状态**：Enabled  
**当前权威实现**：

- `lib/divination_systems/liuyao/liuyao_system.dart`
- `lib/divination_systems/liuyao/liuyao_result.dart`
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`
- `lib/presentation/widgets/liuyao_table_widget.dart`

---

## 1. 系统定位

六爻系统用于根据爻数生成本卦、变卦，并结合六神、世应、六亲等要素进行展示与解读。

它是当前四个系统里契约最完整、UI 最完整的一个，因此后续其它术数的接入应参考六爻的分层方式，而不是复制早期临时实现。

---

## 2. 支持的排盘方法

| 方法 | `CastMethod` | 状态 | 说明 |
|---|---|---|---|
| 钱币卦 | `coin` | 已实现 | 系统随机生成六次投币结果 |
| 爻名卦 | `manual` | 已实现 | 手动输入爻数或手动输入铜钱结果 |
| 数字卦 | `number` | 已实现 | 输入一个整数起卦 |
| 报数卦 | `reportNumber` | 已实现 | 输入上卦数、下卦数、动爻数 |
| 时间卦 | `time` | 已实现 | 依据 `castTime` 起卦 |
| 电脑卦 | `computer` | 已实现 | 系统随机起卦 |

---

## 3. 输入契约

### 3.1 通用要求

- `castTime` 可以为空；为空时系统使用当前时间。
- `manual` 模式必须显式提供 `manualMode`。
- 不允许再回到“看到某个字段就猜输入模式”的旧设计。

### 3.2 各方法 payload

#### `coin`

```dart
{}
```

说明：

- 不需要额外字段
- 爻数由 `QiGuaService.coinCast()` 生成

#### `time`

```dart
{}
```

说明：

- 不需要额外字段
- 卦象由 `QiGuaService.timeCast(castTime)` 生成

#### `manual`

六爻 `manual` 当前是一个方法名下的两种显式模式。

模式 A：直接提供爻数

```dart
{
  'manualMode': 'yaoNumbers',
  'yaoNumbers': <int>[6, 7, 8, 9, 8, 7],
}
```

约束：

- `manualMode` 必须为 `'yaoNumbers'`
- `yaoNumbers` 长度必须为 6
- 每个值必须在 `6..9`

模式 B：提供六次铜钱输入

```dart
{
  'manualMode': 'coinInputs',
  'coinInputs': <List<CoinFace>>[
    [CoinFace.front, CoinFace.back, CoinFace.back],
    ...
  ],
}
```

约束：

- `manualMode` 必须为 `'coinInputs'`
- 外层长度必须为 6
- 每组必须恰好 3 枚铜钱

#### `number`

```dart
{
  'number': 123,
}
```

约束：

- `number` 必须为 `int`

#### `reportNumber`

```dart
{
  'upperNum': 3,
  'lowerNum': 7,
  'movingNum': 5,
}
```

约束：

- 三个字段都必须为 `int`

#### `computer`

```dart
{}
```

说明：

- 不需要额外字段
- 爻数由 `QiGuaService.computerCast()` 生成

---

## 4. 排盘计算流程

所有六爻方法最终收敛为同一条计算链：

1. 先根据起卦方式生成六个爻数
2. 通过 `LunarService.getLunarInfo()` 计算农历信息
3. 通过 `GuaCalculator.calculateGua()` 生成本卦
4. 通过 `GuaCalculator.generateChangingGua()` 生成变卦
5. 通过 `LiuShenService.calculateLiuShen()` 生成六神
6. 组装 `LiuYaoResult`

这意味着：

- 起卦方式只是“爻数来源”不同
- 结果展示层不应按不同方式分裂成不同结果结构

---

## 5. 结果对象契约

六爻结果必须至少包含以下字段：

| 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `id` | `String` | 是 | 记录唯一标识 |
| `castTime` | `DateTime` | 是 | 起卦时间 |
| `castMethod` | `CastMethod` | 是 | 起卦方式 |
| `systemType` | `DivinationType.liuYao` | 是 | 系统类型 |
| `lunarInfo` | `LunarInfo` | 是 | 农历上下文 |
| `mainGua` | `Gua` | 是 | 本卦 |
| `changingGua` | `Gua?` | 否 | 变卦 |
| `liuShen` | `List<String>` | 是 | 六神 |
| `questionId` | `String` | 是 | 加密问事引用 |
| `detailId` | `String` | 是 | 加密详情引用 |
| `interpretationId` | `String` | 是 | 加密解读引用 |

补充要求：

- `toJson()` / `fromJson()` 必须可逆
- `systemType` 通过 getter 固定为 `liuYao`
- `getSummary()` 必须在有变卦时输出 `本卦 → 变卦`

---

## 6. 结果页显示规范

### 6.1 区块顺序

六爻结果页必须按以下顺序展示：

1. 占问事宜
2. 扩展信息
3. 本卦 / 变卦对照
4. 卦象特性
5. AI 分析

### 6.2 各区块必须显示的要素

#### 占问事宜

- 用户输入的问题文本
- 无内容时可以不显示整个区块

#### 扩展信息

- 阳历起卦时间
- 农历月日
- 年月日时干支
- 空亡
- 月建、日建

#### 本卦 / 变卦对照

表头必须显示：

- 区块标题：本卦 / 变卦
- 八宫
- 卦名
- 特殊卦类型 badge（若存在）
- 紧凑卦符

表体必须显示：

- 本卦侧：六神、六亲地支、世应
- 中间列：动爻标记
- 变卦侧：六亲地支
- 顺序按上爻到初爻展示

说明：

- `LiuYaoTableWidget` 已经定义了这张表的当前标准结构
- 后续若新增伏神显示，必须作为明确字段接入，而不是在 UI 层临时推导

#### 卦象特性

仅在存在特殊卦类型时显示：

- 特性名称
- 对应解释文案

#### AI 分析

- 基于当前结果对象与问事文本生成分析
- AI 区块不是替代结构化排盘的主展示层

---

## 7. 历史卡片规范

六爻历史卡片必须采用 5 层结构：

1. 占问事项
2. 时间
3. 结果摘要
4. 系统类型 badge
5. 起卦方式 badge

摘要格式要求：

- 无变卦：`天雷无妄`
- 有变卦：`天雷无妄 → 天风姤`

不允许：

- 只显示系统名称
- 只显示“六爻”
- 丢掉变卦信息

---

## 8. 当前实现缺陷与约束

以下问题必须被明确识别，不能被误当成正式契约：

1. 起卦页里“钱币卦”当前仍经由爻数列表路径落到 ViewModel 便捷方法，这属于实现细节，不应反向定义六爻契约。
2. `manual` 下同时存在两种模式是现实需求，不是允许继续模糊输入的理由；所有调用方必须显式传 `manualMode`。
3. 伏神目前未真正接入结果模型，因此不属于当前 P0 显示要素。

---

## 9. 后续改动准则

后续如果改六爻系统，必须同步修改本文件的场景：

- 增减起卦方式
- 调整 `manual` 模式 payload
- 调整 `LiuYaoResult` 字段
- 修改结果页区块顺序
- 修改历史摘要格式
