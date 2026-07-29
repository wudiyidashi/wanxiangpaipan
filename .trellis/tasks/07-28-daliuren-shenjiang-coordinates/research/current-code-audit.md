# C04 当前实现与测试审计

- Reviewer: `C04 code audit`
- Date: `2026-07-28`
- Mode: read-only

## Current Semantics

设 `P` 为地盘宫到天盘支的合法固定位移双射，`Q` 为昼夜表选出的贵人支，`J[k]` 为固定十二将次序。

- `ShenJiangService` 直接以 `Q` 作为地盘起点，没有求 `inverse(P)[Q]`。
- 夜间同时反转神将数组和地支步进，最终 `diZhiToShenJiang[Q+k] = J[k]`，所以昼夜实际都按 key 顺排。
- `isYangGui == isYangRi == isDay`，无法表达昼逆或夜顺；文案可能与 map 相反。
- 模型和圆盘把 map key 解释为地盘宫，四课/三传把相同 key 解释为天盘支。

## Confirmed Defects

1. 双坐标混用：`shen_jiang_config.dart:43-68`、`daliuren_system.dart:316-332`、`san_chuan_service.dart:601-643`、`daliuren_pan_disk_dialog.dart:332-346`。
2. position 的 `diZhi` 是从 Q 起排的伪地宫，`tianPanZhi=P(diZhi)`，合法但坐标语义错误：`shen_jiang_service.dart:49-77`。
3. 三传 config 可空且查无键时伪造贵人：`san_chuan_service.dart:45-83,601-643`。
4. 非法时支静默成为夜占，05:00-19:00 注释也把申时终点写错：`shen_jiang_service.dart:89-98`。
5. JSON 不验证十二将完整性、双射或锚点：`shen_jiang_config.g.dart:40-62`。
6. 错误乘将会进入 `ChuanAnalysisService` 的吉凶标签，影响分析而非仅展示：`chuan_analysis_service.dart:75-85`。

## Test Gaps

- 没有独立 `shen_jiang_service_test.dart`。
- `daliuren_system_test.dart:247-286` 把“阴贵卯落地盘辰、实际顺排”的旧盘锁成“夜课逆布、贵人落卯”。
- formatter 测试锁定含混“贵人巳（乘戌）”。
- 四课测试大多使用固定贵人 resolver；13 个三传例不传 config，所有乘神来自贵人 fallback。
- 圆盘测试只测角度/天盘 inverse，没有断言天将环地宫。

## Required Structure

- `selectedGuiRenTianBranch`
- `guiRenEarthPalace`
- `actualDirection`
- `tianBranchToGeneral`
- `earthPalaceToGeneral`

测试至少覆盖昼顺、昼逆、夜顺、夜逆，并同时核对两张 map、四课、三传、圆盘和 formatter。

