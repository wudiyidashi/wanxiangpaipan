# C04 神将 Wire 与历史盘兼容审计

- Reviewer: `C04 compatibility audit`
- Date: `2026-07-28`
- Mode: read-only

## Legacy Shape Meaning

- 旧 `diZhiToShenJiang` 虽名为地支/地盘 map，但四课和三传按天盘支查询，它的历史事实语义应迁为 `tianBranchToGeneral`。
- 旧 positions 的 `old.diZhi -> old.tianPanZhi` 保存完整 `P`。以 `inverse(P)` 求每个天盘支所临地宫，可无损生成 `earthPalaceToGeneral` 和新 position。
- 旧 `isYangRi` 保存的是昼夜宣称，不是实际方向。实际方向应从旧布局中贵人到螣蛇的相邻支方向推导。
- 迁移后必须保留旧 `Ke.chengShen`、`Chuan.chengShen` 和 pan version，不能以 v4 重算历史结果。

## Version Contract

- `daliuren-pan/3.0.0` 必须具名保留为 panV3；新行为使用 v4。
- 新结果写 v4 + new shape；v4 + old shape 失败。
- v1/v2/v3/legacy 继续读取，compatibility 不是 current；future 规则按现有 future 分类处理。
- result JSON 是数据库中的文本，通用表和备份外层 format 不需 migration；兼容必须在模型边界完成，否则 repository 会吞异常并让记录消失，备份导入会计为 skipped。

## Required Regression

- 真实 v3 old shape：read、write-new、read-again，四课三传和 ID 不变。
- v4 old shape 拒绝；v4 malformed new shape 拒绝。
- v3 version mismatch、legacy unknown、future 分类。
- repository 查询不丢记录；backup import 零 skipped。
- 重复/缺支、map-position 冲突、外部集合突变均失败或隔离。

