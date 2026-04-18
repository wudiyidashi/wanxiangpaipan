# 小六壬系统说明

**系统类型**：`DivinationType.xiaoLiuRen`  
**状态**：Disabled / Placeholder  
**当前权威实现**：

- `lib/divination_systems/xiaoliuren/xiaoliuren_system.dart`
- `lib/divination_systems/xiaoliuren/models/xiaoliuren_result.dart`

---

## 1. 文档定位

小六壬当前尚未启用，代码里只有骨架实现。

因此本文件必须同时表达两层信息：

1. 当前代码状态是什么
2. 真正允许启用前，必须满足什么输入、输出、展示契约

结论很简单：

- 当前骨架代码不能作为启用依据
- 本文件才是小六壬后续开发的目标基线

---

## 2. 当前代码状态

当前实现事实如下：

- `isEnabled = false`
- `cast()` 直接抛 `UnimplementedError`
- `validateInput()` 直接返回 `true`
- `XiaoLiuRenResult` 仍是 placeholder 结构
- `getSummary()` 仍返回“未实现”
- 没有 UI 工厂实现

以上行为都属于占位行为，不得当作业务契约。

---

## 3. 目标排盘方法

| 方法 | `CastMethod` | 状态 | 说明 |
|---|---|---|---|
| 时间起卦 | `time` | 目标支持 | 基于月、日、时推算 |
| 手动输入 | `manual` | 目标支持 | 手动指定推算条件 |

说明：

- 当前系统说明不开放 `number`、`reportNumber`、`computer`
- 如果未来要扩展方法，必须先修改本文件，再改代码

---

## 4. 目标输入契约

### `time`

```dart
{}
```

说明：

- 使用 `castTime` 作为月、日、时的来源

### `manual`

```dart
{
  'month': 4,
  'day': 18,
  'hourZhi': '午',
}
```

约束：

- `month` 必须为 `1..12`
- `day` 必须为 `1..31`
- `hourZhi` 必须为合法地支

说明：

- 小六壬手动模式的本质，是手动指定月、日、时推算条件
- 不允许把 `manual` 设计成无结构的自由输入

---

## 5. 目标排盘计算流程

小六壬启用后，排盘流程必须明确为：

1. 确定月推算位置
2. 从月位继续推到日位
3. 从日位继续推到时位
4. 得到最终落宫
5. 根据最终落宫输出占断

系统必须明确使用的六个位置：

- 大安
- 留连
- 速喜
- 赤口
- 小吉
- 空亡

不允许启用后再临时决定“到底怎么数”。

---

## 6. 目标结果对象契约

小六壬结果启用前，至少必须具备以下字段：

| 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `id` | `String` | 是 | 记录唯一标识 |
| `castTime` | `DateTime` | 是 | 起卦时间 |
| `castMethod` | `CastMethod` | 是 | 起卦方式 |
| `systemType` | `DivinationType.xiaoLiuRen` | 是 | 系统类型 |
| `lunarInfo` | `LunarInfo` | 是 | 农历上下文 |
| `monthPosition` | `String` | 是 | 月推算结果 |
| `dayPosition` | `String` | 是 | 日推算结果 |
| `hourPosition` | `String` | 是 | 时推算结果 |
| `finalPosition` | `String` | 是 | 最终落宫 |
| `judgement` | `String` | 是 | 结果判断 |
| `questionId` | `String` | 是 | 加密问事引用 |
| `detailId` | `String` | 是 | 加密详情引用 |
| `interpretationId` | `String` | 是 | 加密解读引用 |

不满足这些字段，不得启用。

---

## 7. 目标结果页显示规范

小六壬启用后，结果页必须按以下顺序展示：

1. 占问事宜
2. 扩展信息
3. 推算链
4. 最终落宫
5. 落宫解释
6. AI 分析

### 各区块必须显示的要素

#### 占问事宜

- 用户输入的问题

#### 扩展信息

- 起卦时间
- 干支
- 月建、日建

#### 推算链

- 月位
- 日位
- 时位
- 三步之间的推演顺序

#### 最终落宫

- 最终位置名称
- 对应吉凶判断
- 必要时显示颜色语义，但颜色不能替代文字

#### 落宫解释

- 最终位置的基础含义
- 对应常见事项提示

---

## 8. 目标历史卡片规范

小六壬历史卡片必须采用 5 层结构：

1. 占问事项
2. 时间
3. 结果摘要
4. 系统类型 badge
5. 起卦方式 badge

摘要最低要求：

- `大安 · 吉`
- `赤口 · 口舌是非`

历史页必须一眼看出最终落宫，不能只显示“小六壬”。

---

## 9. 启用门槛

以下条件全部满足之前，小六壬不得启用：

1. `cast()` 不再抛 `UnimplementedError`
2. `validateInput()` 按本文件严格校验
3. 结果对象替换 placeholder
4. `getSummary()` 输出真实业务结果
5. UI 工厂实现起卦页、结果页、历史卡片
6. `toJson()` / `fromJson()` 可逆
7. 至少有一组单元测试覆盖时间起卦与手动输入
