# 设计：大六壬贵人与十二天将双坐标

## 1. Boundary And Data Flow

本任务只修改贵人/十二天将事实及其直接消费者。权威数据流为：

```text
riGan + shiZhi/dayNightMode + project noble table
  -> selectedGuiRenTianBranch
validated earthPalaceToHeavenBranch P
  -> inverse(P)[selectedGuiRenTianBranch]
  -> guiRenEarthPalace
  -> landing zone selects actualDirection
fixed general order + direction + P
  -> positions
  -> tianBranchToGeneral  (四课、三传)
  -> earthPalaceToGeneral (圆盘、落宫展示)
```

昼夜只进入第一步；顺逆只进入第三步。两者在模型、文案和测试中均不得复用同一布尔值。

## 2. Evidence Decision

### 2.1 Adopted Facts

- `卯辰巳午未申` 为昼贵，`酉戌亥子丑寅` 为夜贵：采用《御定六壬直指》卷上 PDF 18 的逐支明文。
- 贵人临 `亥子丑寅卯辰` 顺，临 `巳午未申酉戌` 逆：采用同书 PDF 19 的逐支明文，并以《六壬大全》卷二 PDF 59、62 的“地盘一定顺逆”和天门地户原则交叉支持。
- 十二将线性身份次序：采用《直指》PDF 19 的完整列举及《六壬大全》卷二 PDF 58 的前后将序交叉支持。
- 天盘起贵与地盘定向是两个坐标事实；显式两张 map 是项目工程合同，不表述为古籍原文。

上述条目可标 B/adopted，但由于没有批准的夜贵顺/逆完整盘，保持 `executableApproved=false`。运行时使用 `dlr.project.pan.shenjiang.landing-palace-layout`，并记录 `001/.004/.005/.006` 为 attribution。

### 2.2 Deferred Table

`002/.003` 继续 C/pending。新 v4 仍使用当前完整表作为 `project-current-baseline`，结果和 UI 不称其为已批准主底本表。`jiaDayAlt` 只保留给旧 JSON 枚举解码，不再进入新盘执行或 UI。

## 3. Domain Types

建议新增：

```dart
enum ShenJiangDirection {
  shun('shun', '顺布'),
  ni('ni', '逆布');
}

class ShenJiangPosition {
  ShenJiang shenJiang;
  String heavenBranch;
  String earthPalace;
}

class ShenJiangConfig {
  String selectedGuiRenTianBranch;
  String guiRenEarthPalace;
  bool isYangGui;
  ShenJiangDirection actualDirection;
  List<ShenJiangPosition> positions;
  Map<String, ShenJiang> tianBranchToGeneral;
  Map<String, ShenJiang> earthPalaceToGeneral;
  DlrRuleRef executionRuleRef;
  List<String> classicAttributionRuleIds;
}
```

实际命名可按现有 Dart 约定微调，但 wire 字段必须使用上述无歧义语义。新 API 为：

```dart
ShenJiang? generalForHeavenBranch(String heavenBranch);
ShenJiang? generalForEarthPalace(String earthPalace);
ShenJiangPosition? positionOf(ShenJiang general);
void validateAgainstTianPan(Map<String, String> earthToHeaven);
```

不保留可被新代码调用的含混 `getShenJiangByDiZhi()`；需要兼容的旧字段只存在于 result JSON migration，不作为 current model 字段。

模型采用 release 模式也会执行的显式校验，不依赖 `assert`。Freezed 若无法在所有构造入口执行复杂不变量，则改用经过验证的工厂/私有构造或普通不可变类；不得为了保留生成便利牺牲模型门禁。

## 4. Placement Algorithm

1. `TianPanMapContract.validate(tianPanMap)` 得到不可变 `P`。
2. 验证 `riGan`、`shiZhi`；自动或强制模式只得到 `isYangGui`。
3. 从项目默认整表取得 `Q = selectedGuiRenTianBranch`；非法干直接失败。
4. 构造 `inverseP` 并取得 `E = inverseP[Q]`；不存在时为内部状态错误。
5. `E` 属于顺区则 `step=+1`，属于逆区则 `step=-1`。
6. 对固定 `generalOrder[i]`：
   - `earth = branch[(index(E) + step * i) mod 12]`
   - `heaven = P[earth]`
   - 同时写入 position、`earthPalaceToGeneral[earth]`、`tianBranchToGeneral[heaven]`
7. 构造配置并再次验证贵人锚点、双射、位置/map/方向一致性。

不再维护一个独立反向将序；固定将序加有符号步进是唯一算法。

## 5. Cross-Layer Contract

- `SiKeService` 的 `ChengShenResolver` 继续以天盘上神为参数，系统注入 `generalForHeavenBranch`。
- `SanChuanService.deriveSanChuan` 的神将依赖改为 required；建议直接要求 `ShenJiangConfig`，以便统一校验和 resolver。若改成 required resolver，也必须保证调用边界已验证完整配置，且不得有贵人 fallback。
- 圆盘只调用 `generalForEarthPalace`。ViewModel 暴露两个具名 getter，不猜测调用者坐标。
- UI/AI 统一用 `heavenBranch`/`earthPalace`；human text 采用“某将乘 X、临 Y”。贵人摘要同时显示昼/夜、所选天盘支、所临地宫和实际方向。
- `coreData.shenJiang` 的每项改为 `name/heavenBranch/earthPalace`，overview 拆为 `selectedGuiRenTianBranch/guiRenEarthPalace/actualDirection`。旧含混键不在新输出中继续写。

## 6. Current JSON And Legacy Migration

### 6.1 New Shape

v4 只写新字段。`DaLiuRenResult.fromJson` 先读取 `panRuleSetVersion` 和 nested shape：

- v4 + new shape：严格读取并与 `result.tianPan.tianPanMap` 交叉验证。
- v4 + legacy shape：抛 `ArgumentError`。
- v1/v2/v3/legacy + new shape：允许读取，版本仍按原值分类。
- v1/v2/v3/legacy + old shape：执行一次内存迁移后读取。

### 6.2 Old Shape Conversion

旧配置迁移步骤：

1. 严格读取旧 `positions` 和 `diZhiToShenJiang`，要求十二项完整且一致。
2. 以每个 position 的 `old.diZhi -> old.tianPanZhi` 恢复旧盘 `P`，并与 result 中持久化的 `tianPanMap` 全等。
3. `selectedGuiRenTianBranch = old.guiRenPosition`。
4. `tianBranchToGeneral = old.diZhiToShenJiang`；这是旧四课/三传实际消费的历史语义。
5. 对每个天盘支 `H`，求 `earth = inverseP[H]`，生成 `earthPalaceToGeneral` 和新 position。
6. 由 `tianBranchToGeneral` 中贵人至螣蛇的相邻支方向推导 `actualDirection`；忽略旧 `isYangRi` 的方向宣称。
7. 迁移对象使用 `dlr.project.pan.shenjiang.legacy-layout-import`，其 rule-set version 保留来源盘版本；来源版本未知时明确使用 `legacyUnknown`，且不挂当前 classic attributions。
8. 新对象保留原 result 版本；不重算四课、三传或任何乘神。

若旧配置不完整或与 result 天盘矛盾，读取失败。Repository 现有吞异常行为意味着必须用真实 v3 fixture 证明正常历史记录不会消失；不为测试中的空/单项伪配置放宽生产门禁。

### 6.3 Versions

- `DlrRuleSetVersions.panV3 = daliuren-pan/3.0.0`
- `DlrRuleSetVersions.panCurrent = daliuren-pan/4.0.0`
- `DlrRuleSetVersions.evidenceCatalog = daliuren-classics/1.1.0`（最终 patch 如有现行版本冲突，按未占用的下一版本）
- snapshot 和通用数据库/备份 format 不变。

## 7. UI Choice For Unsupported Variant

新起课参数控件移除“贵人口诀”下拉；只有一个未核定的项目默认值时不展示伪选择。`DaLiuRenGuiRenVerse.jiaDayAlt` 暂保留在 enum 以解码历史 JSON，但：

- `_parsePanParams` 对新 cast 输入拒绝该值；
- 低层排将服务同样拒绝，避免绕过 UI；
- 历史结果只展示“历史甲日特例（无古籍批准）”，不重排；
- 未来若完整异文获批，应新增整表 variant，而不是复活单干交换。

## 8. Validation Strategy

### 8.1 Independent Oracles

- 三张 B 级《指南》课例固定手排值：壬寅日癸卯时贵人巳临卯顺；乙未日己卯时贵人子临巳逆；庚寅日庚辰时贵人丑临卯顺。
- 四类交叉矩阵用合法固定位移天盘和手写预期数组，测试不得调用 `ShenJiangService`、方向 helper 或生产循环生成 expected。
- 夜贵两类明确标为 synthetic boundary，不写进批准古籍 fixture。

### 8.2 Failure Matrix

- 非法干/支、空/部分/额外/重复/乱序天盘。
- map 缺支、重复将、position 重复、map-position 冲突、贵人锚点错误、方向错误。
- v4 搭配 old shape、旧 shape 与 result 天盘冲突、未知 enum、外部集合突变。
- 四课/三传 resolver 缺失和查无天盘支。

## 9. Rollback

证据目录、模型/wire、服务/消费者、UI/formatter/docs 分逻辑提交。若 v4 算法需回滚，保留已核页的 evidence catalog 修正；回退 `panCurrent` 和新盘写入路径即可，禁止删改已写出的 v4 历史记录或把 v4 字符串改义。
