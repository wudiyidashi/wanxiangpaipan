# 设计：大六壬天盘与四课严格合同

## 1. Boundary And Data Flow

```text
validated month general + validated hour branch
  -> twelve-branch bijection (earth branch -> heaven branch)
  -> validated day stem/day branch
  -> four lesson upper/lower facts
  -> required heaven-branch-to-general resolver
  -> SiKe
  -> SanChuan entry reuses the same validated map
```

C03 的最小真相是“完整天盘双射”。所有查询、伏反吟判断、四课和三传入口共享同一不变量，不允许各自定义 fallback。神将解析是独立依赖：四课只要求调用方能按上神给出乘神，不在本任务决定该解析器如何从贵人和坐标表得到答案。

## 2. Heaven-Plate Map Contract

合法 `Map<String, String>` 同时满足：

1. `length == 12`；
2. `keys.toSet()` 与 `DaLiuRenConstants.diZhi.toSet()` 全等；
3. `values.toSet()` 与同一十二支全集全等；
4. 存在唯一固定偏移 `delta`，使每个地盘索引 `i` 都满足 `P(B[i]) == B[(i + delta) mod 12]`。

第三条同时排除非法值和重复值，第四条排除十二支乱序置换；十二支的 `12!` 个双射中只有 12 个固定循环位移是合法天盘。校验逻辑只实现一次，并返回基于输入快照的不可变 map，由 `TianPanService`、`SiKeService`、`SanChuanService` 的入口及 `TianPan` 模型访问路径复用。校验不能依赖 `assert`，因为 release 构建也必须拒绝非法事实，解析器也不能在校验后通过原始引用修改盘面。

### Public API behavior

- `arrangeTianPan(yueJiang, shiZhi)`：先逐项验证为合法地支，再计算偏移；构造完成后通过双射校验。
- `createTianPan(...)`：只包装已验证的排列结果。
- `getTianPanZhi(map, diPanZhi)`：校验 map 与查询支后使用必有键，不再 `?? diPanZhi`。
- `getDiPanZhi(map, tianPanZhi)`：保持 `List<String>` 返回类型以避免无价值的 API 破坏；合法双射下必须恰有一个结果。
- `TianPan.getTianPanZhi()`、`fullDisplay` 和 `fromJson`：拒绝不满足合同的模型状态，不再为缺键补同支。模型还校验合法月将/时支及 `map[shiZhi] == yueJiang`；直接构造/`copyWith` 的异常状态也会在公开读取时失败。
- `yueJiangName` 暂不作为结构校验键：旧名称和异名属于展示/历史兼容，C03 只验证可计算的支位锚点。

非法调用参数统一使用 `ArgumentError`。错误信息必须指出参数名和失败类型，但测试不依赖整段中文文案。

## 3. Four-Lesson Contract

### Inputs

`SiKeService.arrangeSiKe()` 保留日干、日支和 map，并把可选 `ShenJiangConfig?` 替换为必填解析器：

```dart
typedef ChengShenResolver = ShenJiang? Function(String tianPanZhi);

SiKe arrangeSiKe({
  required String riGan,
  required String riZhi,
  required Map<String, String> tianPanMap,
  required ChengShenResolver resolveChengShen,
});
```

选择解析器而不是强制 `ShenJiangConfig` 的原因是：`ShenJiangConfig.diZhiToShenJiang` 当前键坐标含混，C04 将把天盘乘将与地盘落将分开。C03 只声明四课需要“上神对应乘神”这一事实，避免冻结现有错误坐标。

调用方没有解析器会在编译期失败；解析器对某一上神返回 `null` 时抛 `StateError`，不得改填 `贵人`。生产系统暂以现有配置包装解析器，因此合法盘输出保持不变；C04 再替换解析器的数据来源。

### Formula

设 `G = 日干寄宫`，`P(x) = tianPanMap[x]`：

| 课 | 下神 | 上神 |
|---|---|---|
| 一课 | 日干 | `P(G)` |
| 二课 | `P(G)` | `P(P(G))` |
| 三课 | 日支 | `P(日支)` |
| 四课 | `P(日支)` | `P(P(日支))` |

日干先由既有 `getGanJiGong()` 校验，日支显式验证，并通过共享干支能力确认二者可组成六十甲子。map 通过固定循环位移合同后所有 `P(x)` 都是 total function，不再需要空值分支。

五行关系继续使用共享 `WuXingService`：下克上仅置 `isZeiKe`，上克下仅置 `isBiYong`；无克时依次表达上生下、下生上或比和。C03 不改变已锁定的取传术语，只补全直接测试。

### Existing SiKe validation

`SiKeService` 提供可复用的严格验证，让 `SanChuanService` 不必信任任意公开模型构造器。验证根据 `siKe.riGan`、`siKe.riZhi` 和同一 map 重新得到四课结构及五行事实，并逐项核对：

- `index` 恰为 1、2、3、4；
- `shangShen`、`xiaShen` 满足上表链路；
- 上下神五行、`wuXingRelation`、`hasKe`、`isZeiKe`、`isBiYong` 与共享五行服务一致；
- `chengShen` 不在 C03 重算，因为其坐标来源属于 C04。

验证只用于进入现行推导的服务边界；不修改 `SiKe.fromJson` 字段形状，也不把历史模型静默改写成当前事实。

## 4. Fu-Yin, Fan-Yin, And San-Chuan Guard

- `isFuYin` 和 `isFanYin` 先验证完整双射，再按固定十二支全集检查，消除空集合真值和部分 map 误判。
- `SanChuanService.deriveSanChuan()` 在进入九宗门 `_derive` 前取得 map 防御性副本，并调用 `SiKeService` 核对四课链和克向事实；内部 `_tianPan` 改为已证明存在的严格读取。
- 三传内部伏吟/反吟可委托公共严格谓词或在入口校验后继续遍历完整 map。不得改变任何发用、刑传或井栏射分支。

这是 C03 为维持基础不变量所需的最小下游适配。三传的乘神 resolver、贵人坐标及九宗门完整古例仍分别属于 C04/C05。

## 5. Model And Serialization Compatibility

- 只修改手写模型方法与注释，不新增、删除或改名 Freezed 字段。
- `Ke.xiaShen` 文档改为“第一课为日干，其余课为承接的地支下神”，不再一律声称地盘地支。
- `Ke`/`SiKe` 总注按表中四课公式统一。
- 合法旧 JSON 完全按原结构 round-trip；结构完整但 map 内容非法、非循环位移或月将未加临时支的记录显式反序列化/读取失败，不能伪装成同位盘。仓库既有 malformed-record 跳过策略不在 C03 扩张；若测试中的手工 fixture 自相矛盾，修正 fixture 而不放宽合同。
- 不把 `chengShen` 改为 nullable，避免 JSON schema 和所有下游消费者发生与 C03 无关的迁移。

## 6. Rule Identity And Versioning

规则证据不变：

- classic execution：`pan.003`、`pan.005` 至 `pan.008`；
- pending/non-executable：`pan.004`；
- evidence catalog：`daliuren-classics/1.0.0`。

行为合同改变：v2 对非法输入会生成伪盘或伪乘神，v3 拒绝该输入。依据 `DlrRuleSetVersions`“行为改变必须发布新值”的既有合同：

- 新增具名 `panV2 = daliuren-pan/2.0.0`；
- `panCurrent = daliuren-pan/3.0.0`；
- `castInputSchema = 2.0.0` 保持不变，因为可重放输入形状没有变化；
- 新起盘及 `DlrRuleRef.projectPan()` 自动写 v3；v2、v1、legacy 和 future 仍原样读取，只有与 current 精确相等者可判 current。

版本测试必须直接锁定 v2 为 `versionMismatch`，避免将已发布 v2 原地解释成新失败语义。

## 7. Call-Site Migration

生产调用方只有 `DaLiuRenSystem._assembleResult()`：把当前神将配置包装成必填解析器并保留查无项失败。五个直接测试 helper（san-chuan、analyzer、ke-ge、formatter、widget）必须显式传入测试解析器；测试可明确返回固定枚举值，但不得让生产服务自行伪造。

新增独立 `tianpan_service_test.dart` 与 `si_ke_service_test.dart`。既有 `san_chuan_service_test.dart` 只做必要 helper 迁移和严格 map 入口回归，不改 13 个现有期望。

## 8. Test Design

### Structural matrix

- 枚举 12 月将 x 12 时支，逐例断言长度、键集、值集、唯一性及“月将加临时支”。
- 分别构造空、缺一键、额外非法键、非法值、重复值和乱序双射 map；所有公开消费者逐类失败。
- 对可变输入 map 先构造结果再修改原 map，断言结果仍保持校验时快照；构造 `TianPan` 时断言 `map[shiZhi] == yueJiang`。
- 完整 identity map 仅伏吟为真；完整六冲 map 仅反吟为真；一个普通合法旋转两者均假。
- 以合法 map 配置错误课序、断裂上下神链和矛盾克向字段，断言三传入口拒绝。

### Independent classic cases

从已批准 fixture 固定输入与预期：

| Case | 日/时/月将 | 四课（下/上） |
|---|---|---|
| 刘退斋 | 壬寅 / 癸卯 / 巳 | 壬/丑、丑/卯、寅/辰、辰/午 |
| 冯允升 | 乙未 / 己卯 / 戌 | 乙/亥、亥/午、未/寅、寅/酉 |
| 马廉庄 | 庚寅 / 庚辰 / 寅 | 庚/午、午/辰、寅/子、子/戌 |

测试预期读取或逐字转录自 `assets/data/daliuren/classics/cases/zhinan.json`，并断言其 `expectedDerivation.usesProductionCode=false`；不在测试里复制旋转公式生成 expected。

### Compatibility and regression

- 当前 v3、v2、v1、legacy、future pan version 读取与 compatibility。
- `TianPan` JSON 合法 round-trip，以及 malformed/乱序/元数据矛盾 map 失败。
- 13 个内部三传盘、全部 DLR、共享六爻、classic validator、analyze 和全量 tests。

## 9. Risk And Rollback

- 最高兼容风险是必填 resolver 造成测试/隐藏调用方编译失败；用全仓 `rg` 和 `flutter analyze` 收口，不能恢复可选默认。
- v2 会从 current 变为 version mismatch，这是保守历史策略的预期结果；旧记录不迁移、不覆盖。
- 若独立 fixture 暴露现有寄宫表差异，只登记为 `pan.004` 待证，不在 C03 越权修改。
- 产品代码、测试、规范和版本常量作为一个 C03 提交回滚；回滚不得改写已保存 v3 记录或把 v3 冒充 v2。
