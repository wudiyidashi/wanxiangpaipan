# 术数系统说明索引

**状态**：Current Contract  
**修订日期**：2026-04-18  
**适用范围**：术数系统实现、UI 工厂、历史记录、AI 输出装配、后续功能扩展

---

## 1. 文档定位

本目录不是灵感笔记，也不是一次性 spec。

本目录的每一份文件，都是对应术数系统的**开发依据**，明确三件事：

1. 这个系统支持哪些排盘 / 起课方法
2. 每种方法必须接收什么输入
3. 结果页、历史卡片必须显示哪些要素

如果代码行为和本目录文档不一致，以本目录为准并修代码；如果业务决定变更契约，必须先改文档，再改代码。

---

## 2. 文档优先级

优先级从高到低如下：

1. 本目录下的系统级说明
2. [`../divination-system-interface.md`](../divination-system-interface.md)
3. 历史性工程 spec / plan
4. 历史参考文档

说明：

- `docs/superpowers/` 下的 spec / plan 记录的是某次工程决策，不是长期运行时契约
- `docs/architecture.md` 是六爻单系统时代的历史快照，不可作为当前多术数系统的事实依据

---

## 3. 目录

- [`liuyao.md`](liuyao.md) — 六爻系统说明
- [`daliuren.md`](daliuren.md) — 大六壬系统说明
- [`xiaoliuren.md`](xiaoliuren.md) — 小六壬系统说明
- [`meihua.md`](meihua.md) — 梅花易数系统说明

---

## 4. 统一规则

所有系统都必须遵守以下统一规则：

1. 对外持久化使用稳定 `id`，不得把 `enum.name` 当成存储协议。
2. `supportedMethods`、`validateInput()`、`cast()` 的真实接受 payload 必须一致。
3. `DivinationResult.toJson()` 与 `resultFromJson()` 必须可逆。
4. `getSummary()` 必须可直接用于历史记录列表，不得返回调试信息。
5. `buildResultScreen()`、`buildHistoryCard()` 依赖的字段，必须在系统说明中写明。
6. 系统未达到文档规定的输入、输出、展示要求，不得启用。

---

## 5. 变更要求

后续任何涉及下列变更的 PR，都必须同步更新对应系统文档：

- 新增或删除起盘 / 起课方式
- 修改某种方式的输入字段
- 调整结果对象字段
- 修改历史摘要格式
- 调整结果页区块顺序或核心显示要素
- 启用当前仍为 placeholder 的术数系统

不满足以上要求的改动，视为不完整改动。
