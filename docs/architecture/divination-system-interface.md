# 多术数系统输入输出契约

**版本**：2.0  
**修订日期**：2026-04-18  
**状态**：Current Contract  
**适用范围**：`DivinationSystem` / `DivinationResult` / `DivinationUIFactory` / 历史记录 / 仓储层

---

## 1. 文档目的

这份文档不再只是解释“接口长什么样”，而是明确：

1. 每个术数系统的 `cast()` 输入参数规范
2. 每个术数系统结果对象的最小输出面
3. 序列化、历史页摘要、UI factory 依赖的稳定契约
4. 当前实现中的设计缺陷与后续收敛方向

如果没有这份契约，系统会很快出现以下问题：

- 同一个 `CastMethod` 在不同系统里含义漂移
- `Map<String, dynamic>` 变成无约束黑盒
- 历史页无法做统一卡片骨架
- 仓储层和 UI 层需要靠猜字段名协作
- 新增术数系统时只能复制已有实现，无法按规范接入

系统级的落地说明已经拆分到：

- [`divination-systems/README.md`](divination-systems/README.md)
- [`divination-systems/liuyao.md`](divination-systems/liuyao.md)
- [`divination-systems/daliuren.md`](divination-systems/daliuren.md)
- [`divination-systems/xiaoliuren.md`](divination-systems/xiaoliuren.md)
- [`divination-systems/meihua.md`](divination-systems/meihua.md)

后续“某一个术数具体怎么起、怎么存、怎么显示”，以对应系统说明为准；本文件只保留跨系统统一契约。

---

## 2. 核心原则

### 2.1 输入契约按 `(systemType, castMethod)` 定义

`CastMethod` 只是一个能力标签，不代表全局统一 payload。

例如：

- 六爻的 `reportNumber` 是“三个数：上卦、下卦、动爻”
- 大六壬的 `reportNumber` 是“一个数映射地支”

因此，**输入规范永远由 `(DivinationType, CastMethod)` 共同决定**，不能只看 `castMethod`。

### 2.2 结果对象必须至少满足三类消费方

每个 `DivinationResult` 都必须同时满足：

1. **仓储层**：可完整序列化 / 反序列化
2. **历史页**：可生成稳定的一行结果摘要
3. **结果页**：能支撑本系统 UI factory 进行完整展示

### 2.3 `Map<String, dynamic>` 是实现边界，不是规范豁免

当前接口仍使用：

```dart
Future<DivinationResult> cast({
  required CastMethod method,
  required Map<String, dynamic> input,
  DateTime? castTime,
});
```

这只是代码形态，不代表调用方可以随意拼字段。

**所有字段名、类型、可选性，必须写清楚并稳定。**

### 2.4 存储层使用稳定 ID，不使用 enum `name`

外部存储、序列化、数据库持久化，应优先使用：

- `DivinationType.id`
- `CastMethod.id`

而不是 `enum.name`。

原因：

- `id` 是外部契约
- `name` 是实现细节
- 枚举重命名会直接破坏历史数据兼容性

当前代码中部分实现仍使用 `name`，这是需要收敛的旧债，不应继续扩散。

---

## 3. 通用输入输出契约

## 3.1 `DivinationSystem` 通用输入约束

所有系统都必须满足：

1. `method` 必须在 `supportedMethods` 中
2. `validateInput()` 必须与真实接受的 payload 完全一致
3. `cast()` 不得静默吞掉缺失的必填字段
4. `castTime` 为空时可默认当前时间，但不得覆盖显式传入值
5. `resultFromJson()` 必须能完整还原 `toJson()` 产物

## 3.2 `DivinationResult` 通用输出约束

所有结果对象至少必须具备以下基础字段：

| 字段 | 说明 |
|---|---|
| `id` | 记录唯一标识 |
| `castTime` | 起卦 / 起课时间 |
| `systemType` | 系统类型 |
| `castMethod` | 起卦方式 |
| `lunarInfo` | 农历上下文 |

除此之外，每个系统结果对象还必须满足：

1. `toJson()` 输出足以完整反序列化
2. `getSummary()` 返回历史页可用的一行摘要
3. 若支持加密问事信息，应保留 `questionId` / `detailId` / `interpretationId` 引用位

## 3.3 历史页最小输出面

为了支持跨术数统一历史卡片，所有系统必须至少能提供：

1. `systemType`
2. `castMethod`
3. `castTime`
4. `getSummary()`

推荐额外提供：

- 一个更适合历史页标题的问事摘要
- 一个更适合历史页副标题的系统特有摘要

当前代码里这两个“更适合历史页”的字段尚未统一建模，因此短期仍由：

- `getSummary()`
- UI factory 自己的历史卡片逻辑

共同承担。

---

## 4. 各系统输入规范

本节定义的是**当前权威调用规范**。

---

## 4.1 六爻 `LiuYaoSystem`

### 支持方式

- `coin`
- `manual`
- `number`
- `reportNumber`
- `time`
- `computer`

### 输入规范

#### `coin`

```dart
{}
```

说明：

- 不需要额外输入
- 爻数由系统随机生成

#### `time`

```dart
{}
```

说明：

- 不需要额外输入
- 计算依赖 `castTime`

#### `manual`

当前接受两种 payload 形态。

**形态 A：直接提供爻数**

```dart
{
  'yaoNumbers': <int>[6, 7, 8, 9, 8, 7],
}
```

约束：

- 长度必须为 6
- 每个值必须在 `6..9`

**形态 B：提供六次投币结果**

```dart
{
  'coinInputs': <List<CoinFace>>[
    [CoinFace.xxx, CoinFace.xxx, CoinFace.xxx],
    ... // 共 6 组
  ],
}
```

约束：

- 外层长度必须为 6
- 每组必须为 3 枚铜钱

**当前缺陷**：

- `manual` 同时承载两种完全不同输入形态

**收敛建议**：

- 后续为外部调用补 `manualMode`
- 或拆出更明确的输入适配层，避免 UI 侧靠字段猜模式

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

- 不需要额外输入
- 爻数由系统随机生成

### 输出规范

六爻结果对象必须包含：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 记录 ID |
| `castTime` | `DateTime` | 起卦时间 |
| `castMethod` | `CastMethod` | 起卦方式 |
| `systemType` | `DivinationType.liuYao` | 系统类型 |
| `lunarInfo` | `LunarInfo` | 农历信息 |
| `mainGua` | `Gua` | 本卦 |
| `changingGua` | `Gua?` | 变卦 |
| `liuShen` | `List<String>` | 六神 |
| `questionId` | `String` | 加密问事引用 |
| `detailId` | `String` | 加密详情引用 |
| `interpretationId` | `String` | 加密解读引用 |

### 摘要规范

当前实现：

- `getSummary() => mainGua.name`

当前缺陷：

- 对历史页来说信息不足
- 丢失“变卦”这一高价值摘要

推荐目标：

- 无变卦：`天雷无妄`
- 有变卦：`天雷无妄 → 天风姤`

---

## 4.2 大六壬 `DaLiuRenSystem`

### 支持方式

- `time`
- `reportNumber`
- `manual`
- `computer`

### 输入规范

#### `time`

```dart
{
  'params': {
    'birthYear': 1990,
    'monthGeneralMode': 'auto',
    'manualMonthGeneral': '戌',
    'dayNightMode': 'auto',
    'guiRenVerse': 'classic',
    'xunShouMode': 'day',
    'showSanChuanOnTop': true,
  }
}
```

说明：

- 核心输入依赖 `castTime`
- `params` 可省略；省略时必须采用系统默认正统参数
- `params` 的具体古法语义，以 [`divination-systems/daliuren.md`](divination-systems/daliuren.md) 为准

#### `reportNumber`

```dart
{
  'number': 7,
  'params': {
    'birthYear': 1990,
    'monthGeneralMode': 'auto',
    'manualMonthGeneral': '戌',
    'dayNightMode': 'auto',
    'guiRenVerse': 'classic',
    'xunShouMode': 'day',
    'showSanChuanOnTop': true,
  }
}
```

说明：

- 输入一个整数
- 系统把它映射为地支时支，再复用时间起课流程

约束：

- `number` 必须为 `int`
- `params` 可省略；省略时必须采用系统默认正统参数

#### `manual`

```dart
{
  'yearGanZhi': '丙午',
  'monthGanZhi': '壬辰',
  'dayGanZhi': '壬戌',
  'hourGanZhi': '辛亥',
  'params': {
    'birthYear': 1990,
    'monthGeneralMode': 'auto',
    'manualMonthGeneral': '戌',
    'dayNightMode': 'auto',
    'guiRenVerse': 'classic',
    'xunShouMode': 'day',
    'showSanChuanOnTop': true,
  }
}
```

约束：

- `yearGanZhi`、`monthGanZhi`、`dayGanZhi`、`hourGanZhi` 目标上都应为必填
- 四柱必须是合法干支组合
- `params` 可省略；省略时必须采用系统默认正统参数

当前实现中的问题：

- 代码里仍存在简化版 `riGan/riZhi/shiZhi/yueJian` 输入和调试型默认值
- 这类回退只允许作为开发期兜底，不属于正式契约

收敛要求：

- 未来 UI 层传入 `manual` 时应显式提供完整四柱
- 服务层不得在正式流程里静默拼装默认柱

#### `computer`

```dart
{
  'params': {
    'birthYear': 1990,
    'monthGeneralMode': 'auto',
    'manualMonthGeneral': '戌',
    'dayNightMode': 'auto',
    'guiRenVerse': 'classic',
    'xunShouMode': 'day',
    'showSanChuanOnTop': true,
  }
}
```

说明：

- 不需要额外业务输入
- 系统随机生成起课上下文后，再走同一条正统排盘链

### `params` 字段约束

为了避免 UI、服务层、历史迁移各自发明字段名，大六壬参数对象统一约定如下：

| 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `birthYear` | `int?` | 否 | 本命占扩展参数，时事占可空 |
| `monthGeneralMode` | `String` | 否 | `auto` 或 `manual` |
| `manualMonthGeneral` | `String?` | 否 | 仅 `monthGeneralMode = manual` 时有效，必须是合法地支 |
| `dayNightMode` | `String` | 否 | `auto`、`day`、`night` |
| `guiRenVerse` | `String` | 否 | `classic` 对应 `甲戊庚牛羊`，`jiaDayAlt` 对应 `甲羊戊庚牛` |
| `xunShouMode` | `String` | 否 | `day` 表示日柱旬遁干，`hour` 表示时柱旬遁干 |
| `showSanChuanOnTop` | `bool` | 否 | 纯显示选项，不参与算法 |

默认值要求：

- `monthGeneralMode = auto`
- `dayNightMode = auto`
- `guiRenVerse = classic`
- `xunShouMode = day`
- `showSanChuanOnTop = true`

### 输出规范

大六壬结果对象必须包含：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 记录 ID |
| `castTime` | `DateTime` | 起课时间 |
| `castMethod` | `CastMethod` | 起课方式 |
| `systemType` | `DivinationType.daLiuRen` | 系统类型 |
| `lunarInfo` | `LunarInfo` | 农历信息 |
| `tianPan` | `TianPan` | 天盘 |
| `siKe` | `SiKe` | 四课 |
| `sanChuan` | `SanChuan` | 三传 |
| `shenJiangConfig` | `ShenJiangConfig` | 十二神将 |
| `shenShaList` | `ShenShaList` | 神煞 |
| `questionId` | `String` | 加密问事引用 |
| `detailId` | `String` | 加密详情引用 |
| `interpretationId` | `String` | 加密解读引用 |

补充要求：

- `tianPan` 不能只保存月将摘要，必须足以表达完整 12 宫天地盘映射
- `siKe` 不能只保存简化的上下神，必须保留四课序、天将、六亲、上下生克关系
- `sanChuan` 不能只保存三个地支，必须保留课体名称和取传说明
- `shenJiangConfig` 不能只保存“贵人位置 + 顺逆方向”，必须足以表达完整 12 将落宫
- `toJson()` / `fromJson()` 必须能完整还原这些结构

### 摘要规范

当前实现：

- `getSummary() => '$keTypeName课 · 初传$chuChuan 中传$zhongChuan 末传$moChuan'`

这是当前推荐摘要，因为它至少表达了：

- 课体
- 完整三传链

标准格式：

- `涉害课 · 初传申 中传子 末传辰`

注意：

- 历史摘要允许简写
- 结果对象本身不允许只剩摘要，结构化盘面字段必须完整保留
- AI formatter 另有完整文本模板，标题固定为 `【大六壬完整结构化排盘】`

---

## 4.3 小六壬 `XiaoLiuRenSystem`

当前状态：

- `isEnabled = false`
- 核心排盘与结果对象已实现，但 UI 工厂与 AI formatter 尚未接入
- 当前已实现 `六宫 / 九宫`

当前仍未启用，因此这里保留系统级最小契约。

### 支持方式

- `time`
- `reportNumber`
- `characterStroke`

### 目标输入规范

#### `time`

```dart
{}
```

说明：

- 基于 `castTime` 推算农历月、农历日、时支
- 可选附带 `palaceMode: 'sixPalaces' | 'ninePalaces'`

#### `reportNumber`

```dart
{
  'firstNumber': 4,
  'secondNumber': 18,
  'thirdNumber': 7,
  'palaceMode': 'ninePalaces', // optional
}
```

约束：

- 必须包含三个数字字段
- 允许额外附带 `palaceMode`
- 三个字段都必须为正整数

说明：

- 三个数字分别作为三段起数

#### `characterStroke`

```dart
{
  'firstStroke': 8,
  'secondStroke': 11,
  'thirdStroke': 6,
  'palaceMode': 'ninePalaces', // optional
}
```

约束：

- 必须包含三个笔画字段
- 允许额外附带 `palaceMode`
- 三个字段都必须为正整数

说明：

- 当前底层直接接收三段笔画数
- 汉字到笔画数的转换必须由上层完成

### 目标输出规范

小六壬结果对象启用前，至少应具备：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 记录 ID |
| `castTime` | `DateTime` | 起卦时间 |
| `castMethod` | `CastMethod` | 起卦方式 |
| `systemType` | `DivinationType.xiaoLiuRen` | 系统类型 |
| `lunarInfo` | `LunarInfo` | 农历信息 |
| `palaceMode` | model | `sixPalaces / ninePalaces` |
| `source` | model | 三段输入源与推算痕迹 |
| `monthPosition` | model | 第一段落宫 |
| `dayPosition` | model | 第二段落宫 |
| `hourPosition` | model | 第三段落宫 |
| `finalPosition` | model | 最终落宫 |
| `judgement` | `String` | 占断结果 |
| `detail` | `String` | 结构化推算说明 |

### 摘要规范

最低要求：

- `大安 · 诸事安稳`
- `赤口 · 口舌是非`

历史页必须一眼看出“最终落宫是什么”。

---

## 4.4 梅花易数 `MeiHuaSystem`

当前状态：

- `isEnabled = false`
- 核心排盘与结果对象已实现，但 UI 工厂与 AI formatter 尚未接入

当前仍未启用，因此这里保留系统级最小契约。

### 支持方式

- `time`
- `number`
- `manual`

### 目标输入规范

#### `time`

```dart
{}
```

说明：

- 基于 `castTime` 起卦

#### `number`

```dart
{
  'upperNumber': 12,
  'lowerNumber': 8,
}
```

建议约束：

- 两个字段都必须为 `int`

说明：

- 不建议继续使用单一 `number` 字段，因为梅花易数数字起卦通常至少需要上下卦两个输入位

#### `manual`

```dart
{
  'upperTrigram': '乾',
  'lowerTrigram': '巽',
  'movingLine': 3,
}
```

建议约束：

- `upperTrigram`、`lowerTrigram` 必须为合法八卦
- `movingLine` 必须在 `1..6`

### 目标输出规范

梅花易数结果对象当前至少应具备：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 记录 ID |
| `castTime` | `DateTime` | 起卦时间 |
| `castMethod` | `CastMethod` | 起卦方式 |
| `systemType` | `DivinationType.meiHua` | 系统类型 |
| `lunarInfo` | `LunarInfo` | 农历信息 |
| `benGua` | `String` or model | 本卦 |
| `bianGua` | `String` or model | 变卦 |
| `huGua` | `String` or model | 互卦 |
| `tiGua` | `String` or model | 体卦 |
| `yongGua` | `String` or model | 用卦 |
| `movingLine` | `int` | 动爻 |
| `wuXingRelation` | `String` | 体用五行关系 |
| `judgement` | `String` | 占断结果 |

### 摘要规范

最低要求：

- `风火家人 → 风山渐`
- 若有体用信息，可扩展为：
  - `风火家人 → 风山渐 · 体生用`

---

## 5. 输出摘要规范

`getSummary()` 不是附属方法，它是跨系统统一历史页的最低契约。

从今天起要求如下：

### 5.1 必须是一行文本

- 不换行
- 不写长段解释
- 不包含调试信息

### 5.2 必须优先表达“结果核心”

推荐顺序：

1. 本次结果是什么
2. 若有变化关系，体现变化
3. 若有课体 / 体用 / 落宫，体现最关键一项

### 5.3 不得只返回系统名称或“未实现”

未实现系统在未启用前可以 placeholder。  
一旦启用，`getSummary()` 必须具备真实业务信息。

---

## 6. 当前设计缺陷

## 6.1 缺陷一：`CastMethod` 与 payload 没有被成文约束

当前代码里 payload 靠实现自己约定，文档未同步。

后果：

- UI 层必须读源码才知道该传什么
- 新人很容易把 `reportNumber` 当成全局同构输入

## 6.2 缺陷二：`manual` 被滥用为“多形态桶”

六爻 `manual` 既支持爻数，也支持铜钱输入。

这是现实需求，但如果不成文，会让外部调用无从判断。

## 6.3 缺陷三：摘要规范不一致

- 六爻当前摘要偏弱
- 大六壬摘要相对合格
- 未实现系统仍是 placeholder

这会直接影响历史页统一体验。

## 6.4 缺陷四：序列化仍混用 enum `name`

这对历史数据兼容性是不稳定的。

未来收敛方向必须是：

- 对外存储使用 `id`
- `name` 只留给运行时实现

---

## 7. 新增系统接入要求

以后任何新术数系统接入前，必须先补齐以下内容：

1. 写清楚每个 `supportedMethods` 的输入 schema
2. 写清楚结果对象的最小字段集
3. 明确 `getSummary()` 的历史摘要格式
4. 确保 `toJson()` / `fromJson()` 可逆
5. 明确哪些字段属于加密外置引用，哪些字段属于数据库常规 JSON
6. 若系统启用到 UI，必须有历史页可用的稳定摘要

不满足以上条件，不应进入“已启用”状态。

---

## 8. 与历史页的关系

历史页要做统一卡片骨架，前提不是页面层更复杂，而是各系统遵守稳定 I/O 契约。

历史页依赖本文件的最小输出面：

- `systemType`
- `castMethod`
- `castTime`
- `getSummary()`

未来如果历史页升级为：

- 页面层统一卡片外壳
- 系统层只提供摘要插槽

那么本文件就是那次重构的前置契约。

---

## 9. 结论

真正的“多术数统一架构”，不是只有一个抽象接口就够了。

如果输入输出契约不明确：

- `DivinationSystem` 只是表面统一
- `Map<String, dynamic>` 会不断侵蚀边界
- 历史页、仓储层、UI factory 都会被迫彼此猜测

因此，从今天起：

- 输入规范按 `(systemType, castMethod)` 成文
- 输出规范按“可存储、可摘要、可展示”三重目标定义
- 未实现系统也必须先定义目标契约，再启用

这才是多术数系统继续扩展时不失控的前提。
