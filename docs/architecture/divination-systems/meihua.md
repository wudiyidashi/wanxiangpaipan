# 梅花易数系统说明

**系统类型**：`DivinationType.meiHua`  
**状态**：Disabled / Placeholder  
**当前权威实现**：

- `lib/divination_systems/meihua/meihua_system.dart`
- `lib/divination_systems/meihua/models/meihua_result.dart`

---

## 1. 文档定位

梅花易数当前尚未启用，代码里只有骨架和 placeholder 结果对象。

因此本文件定义的是**启用前必须满足的正式契约**，而不是对当前占位实现的美化说明。

---

## 2. 当前代码状态

当前实现事实如下：

- `isEnabled = false`
- `cast()` 直接抛 `UnimplementedError`
- `validateInput()` 直接返回 `true`
- `MeiHuaResult` 仍是 placeholder
- `getSummary()` 仍返回“未实现”
- 没有 UI 工厂实现

代码注释里提到“物象起卦”，但当前 `supportedMethods` 并不包含对应方法，因此它不是当前对外契约的一部分。

---

## 3. 目标排盘方法

| 方法 | `CastMethod` | 状态 | 说明 |
|---|---|---|---|
| 时间起卦 | `time` | 目标支持 | 基于时间推上卦、下卦、动爻 |
| 数字起卦 | `number` | 目标支持 | 输入上下卦数 |
| 手动输入 | `manual` | 目标支持 | 直接指定上下卦和动爻 |

说明：

- 当前对外不开放“物象起卦”
- 若未来要开放物象起卦，必须先扩展方法表达层，再补本文档

---

## 4. 目标输入契约

### `time`

```dart
{}
```

说明：

- 依赖 `castTime`
- 系统负责从时间推导上卦、下卦、动爻

### `number`

```dart
{
  'upperNumber': 12,
  'lowerNumber': 8,
}
```

约束：

- 两个字段都必须为 `int`

说明：

- 不建议继续使用单一 `number` 字段
- 单一 `number` 容易把“上卦、下卦、动爻来源”压扁成模糊协议

### `manual`

```dart
{
  'upperTrigram': '乾',
  'lowerTrigram': '巽',
  'movingLine': 3,
}
```

约束：

- `upperTrigram` 必须为合法八卦
- `lowerTrigram` 必须为合法八卦
- `movingLine` 必须在 `1..6`

---

## 5. 目标排盘计算流程

梅花易数启用后，排盘流程必须明确为：

1. 先确定上卦、下卦、动爻
2. 计算本卦
3. 推导变卦
4. 计算互卦
5. 判断体卦、用卦
6. 分析五行生克关系
7. 输出占断结果

这意味着：

- 输入阶段解决“怎么起卦”
- 结果阶段必须同时表达“卦象结构”和“体用关系”

---

## 6. 目标结果对象契约

梅花易数结果启用前，至少必须具备以下字段：

| 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `id` | `String` | 是 | 记录唯一标识 |
| `castTime` | `DateTime` | 是 | 起卦时间 |
| `castMethod` | `CastMethod` | 是 | 起卦方式 |
| `systemType` | `DivinationType.meiHua` | 是 | 系统类型 |
| `lunarInfo` | `LunarInfo` | 是 | 农历上下文 |
| `benGua` | model or `String` | 是 | 本卦 |
| `bianGua` | model or `String` | 是 | 变卦 |
| `huGua` | model or `String` | 是 | 互卦 |
| `tiGua` | model or `String` | 是 | 体卦 |
| `yongGua` | model or `String` | 是 | 用卦 |
| `movingLine` | `int` | 是 | 动爻 |
| `wuXingRelation` | `String` | 是 | 体用五行关系 |
| `judgement` | `String` | 是 | 结果判断 |
| `questionId` | `String` | 是 | 加密问事引用 |
| `detailId` | `String` | 是 | 加密详情引用 |
| `interpretationId` | `String` | 是 | 加密解读引用 |

不满足这些字段，不得启用。

---

## 7. 目标结果页显示规范

梅花易数启用后，结果页必须按以下顺序展示：

1. 占问事宜
2. 扩展信息
3. 卦象总览
4. 体用关系
5. 动爻与变卦
6. 五行生克
7. 占断
8. AI 分析

### 各区块必须显示的要素

#### 占问事宜

- 用户输入的问题

#### 扩展信息

- 起卦时间
- 干支
- 月建、日建

#### 卦象总览

- 本卦
- 变卦
- 互卦

#### 体用关系

- 体卦
- 用卦
- 体用判断结论

#### 动爻与变卦

- 动爻位置
- 动爻如何导出变卦

#### 五行生克

- 体卦五行
- 用卦五行
- 生、克、比和结论

#### 占断

- 结构化判断
- 简洁文字解释

---

## 8. 目标历史卡片规范

梅花易数历史卡片必须采用 5 层结构：

1. 占问事项
2. 时间
3. 结果摘要
4. 系统类型 badge
5. 起卦方式 badge

摘要最低要求：

- `山火贲 → 山天大畜`

若空间允许，推荐使用：

- `山火贲 → 山天大畜 · 体生用`

不允许：

- 只显示“梅花易数”
- 只显示“未实现”
- 只显示本卦，不显示变卦

---

## 9. 启用门槛

以下条件全部满足之前，梅花易数不得启用：

1. `cast()` 不再抛 `UnimplementedError`
2. `validateInput()` 按本文件严格校验
3. 结果对象替换 placeholder
4. `getSummary()` 输出真实业务结果
5. UI 工厂实现起卦页、结果页、历史卡片
6. `toJson()` / `fromJson()` 可逆
7. 单元测试覆盖时间起卦、数字起卦、手动输入
