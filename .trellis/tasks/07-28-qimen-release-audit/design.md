# 奇门发布纠偏与最终验收设计

## 1. 纠偏边界

本任务不是第二次实现奇门，而是父任务最终发布门中的审计修复。代码真相保持在
`8138c6e`；本任务把混入产品提交的 analysis slice 重新归属并建立首次启用基线，
再用缺口测试证明所有用户路径。

```text
a83647e internal analysis candidate (Qimen disabled)
  -> 4016ffc source/evidence corrections mixed into unrelated archive commit
  -> 8138c6e corrected analysis + first enabled product integration
  -> qimen-release-audit provenance + missing regressions
  -> parent final acceptance
```

不重写以上历史。归档任务追加 post-archive correction，父任务引用本任务提交形成
可审计链。

## 2. v1 发布基线

`a83647e` 时不存在注册入口、启用系统、tag 或远端分支，分析 report 也不持久化，
因此没有兼容消费者需要选择该内部候选。`8138c6e` 是第一次把 Qimen 系统、UI、
formatter 和规则一起启用的提交，作为 v1 的不可变发布锚点。

spec 增加具体锚点而不改变原则：从 `8138c6e` 起，三奇得使、九遁、来源、冲突、
裁决或应期语义变化必须新增规则版本；输入诊断等非语义修复也必须保持 schema
兼容。最终 fixture 哈希固定为 D575。

## 3. 测试接口

优先使用现有公开控件 key 和 recording system/repository，不把业务逻辑暴露给测试。
若日期/时间 dialog 无法稳定驱动，可为 `QimenCastScreen` 增加与现有
`initialMethod` 同层级的可选 `initialCastTime`，只控制初始表单状态，不绕过真实
picker、ViewModel 或 system。

自动输入测试数据流：

```text
QimenCastScreen control
  -> fresh QimenPanParams
  -> QimenViewModel.submitByTime
  -> recording QimenSystem.cast(method/input/castTime)
  -> repository save
  -> registry navigation
```

异步卸载测试使用 completer 阻塞 cast 或 save；卸载 screen 后再释放 completer，
断言 registry factory 未构建、无 Flutter 异常、save 次数符合状态机。重复点击测试在
save completer 未完成时触发第二次点击，断言 cast/save 各一次。

## 4. 手动校验矩阵

直接向 `QimenSystem.validateInput(CastMethod.manual, payload)` 提交非法 wire 值，
因为 UI dropdown 本身无法构造这些值。每个字段独立变异，避免一个错误掩盖另一个：

| Field | Invalid values | Expected |
|---|---|---|
| `solarTerm` | unknown string | `false` |
| `dun` | unknown stable ID | `false` |
| `juNumber` | `0`, `10` | `false` |
| `yuan` | unknown stable ID | `false` |

## 5. 首页入口

使用真实 bootstrap 注册或最小注册 harness 构建首页，定位启用的奇门卡片并点击，
最终断言出现 `QimenCastScreen`/“奇门遁甲起局”。测试不得只渲染孤立卡片或直接调用
factory，因为那不能证明首页到 registry 的箭头。

## 6. 证据修正

归档产品 PRD 保留 A1 原始边界为“未按原流程满足”，新增 A1-R 说明由本任务完成
重新归属、来源复核和首次发布基线。归档 implement 记录 4016/8138 的时间线，并把
1.3 改为“合同测试存在并通过；无 retained red-run，不能声明历史 test-first”。

父任务在纠偏任务归档后将 children 进度更新为 4/4，再记录所有 acceptance 的
具体测试/审计证据。

## 7. 风险与回滚

- 最大风险是为任务形式维护未发布错误候选，造成双版本复杂度；因此只锚定首次
  enabled baseline，不新增虚假的旧版本。
- 若新测试暴露生产缺陷，最小修复必须留在本任务并补 regression；若只是覆盖不足，
  不改产品代码。
- 所有 staging 使用显式文件白名单；发现共享文件包含大六壬 hunk 时拆分或停止。
