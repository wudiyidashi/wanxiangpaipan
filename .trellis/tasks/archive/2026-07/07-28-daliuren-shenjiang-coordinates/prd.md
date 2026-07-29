# 大六壬贵人与十二天将坐标重构

## Goal

修复十二天将把昼夜误当顺逆、把贵人天盘支误当落宫、天盘/地盘共用一张含混映射以及缺乘神时伪造贵人的问题；按已复核影印证据实现“昼夜选贵、反查落宫、落宫定顺逆、固定将序布列”的完整数据链，并保证旧盘可读而不被当前算法静默重算。

用户价值是：新排盘的贵人、十二天将、四课乘将、三传乘将、圆盘、结果页与 AI 输出使用同一组可解释坐标；历史盘仍保留原结果和原版本身份。

## Background And Confirmed Facts

- `ShenJiangService` 当前将昼夜直接等同顺逆，并在夜间同时反转将序和宫位步进，两个反转抵消，实际天盘支映射恒为顺排：`lib/domain/services/daliuren/shen_jiang_service.dart:31-85`。
- 当前服务把所选贵人支直接当作地盘宫，没有通过合法天盘映射的逆映射求贵人所临地宫：`lib/domain/services/daliuren/shen_jiang_service.dart:38-75`。
- `ShenJiangConfig.diZhiToShenJiang` 在模型/圆盘中被当作地盘宫映射，在四课、三传中却按天盘支查询：`lib/divination_systems/daliuren/models/shen_jiang_config.dart:43-68`、`lib/divination_systems/daliuren/daliuren_system.dart:316-332`、`lib/domain/services/daliuren/san_chuan_service.dart:601-643`、`lib/divination_systems/daliuren/ui/widgets/daliuren_pan_disk_dialog.dart:332-346`。
- 三传配置可省略，缺配置或查无键时会把乘神伪造成贵人；四课已在 C03 收紧为无法解析即失败：`lib/domain/services/daliuren/san_chuan_service.dart:45-83,601-643`、`lib/domain/services/daliuren/si_ke_service.dart:8-10,94-100`。
- `DaLiuRenConstants.getGuiRenPosition()` 对非法日干静默回退为丑未；自动昼夜对非法时支静默判夜：`lib/divination_systems/daliuren/daliuren_constants.dart:416-429`、`lib/domain/services/daliuren/shen_jiang_service.dart:89-98`。
- `ShenJiangConfig.fromJson` 只做类型反序列化，不校验十二将完整性、坐标双射、贵人锚点、方向或外部集合可变性：`lib/divination_systems/daliuren/models/shen_jiang_config.g.dart:40-62`。
- 旧 `diZhiToShenJiang` 的实际消费语义是“天盘支 -> 将”；旧 `positions` 中 `old.diZhi -> old.tianPanZhi` 恰好保存一张完整天盘映射，可在不重算历史四课/三传的前提下恢复双坐标。旧 `isYangRi` 只保存昼夜宣称，不能当作真实顺逆。
- 《御定六壬直指》卷上 PDF 18 / scan leaf 17 / printed leaf 七直接规定“卯至申用昼贵，酉至寅用夜贵”。
- 同书 PDF 19 / scan leaf 18 / printed leaf 八直接规定“贵人加于亥子丑寅卯辰六位则顺行，加于巳午未申酉戌六位则逆行”，并直接列出贵人、螣蛇、朱雀、六合、勾陈、青龙、天空、白虎、太常、玄武、太阴、天后的完整次序。
- 《六壬大全》卷二 PDF 58-62 交叉支持“以课之天盘起贵神”“地盘一定顺逆”及天门地户定顺逆；卷一 PDF 100 对“昼顺夜逆”明言“近不用”，不能作为现行默认。
- 《御定六壬直指》贵人表与当前表在甲、乙、丙、辛、壬五干的昼夜次序冲突。现有 `jiaDayAlt` 只交换甲日，不能代表该完整异文。
- 三张已批准《大六壬指南》课例均为昼贵，可覆盖昼顺和昼逆；尚无已批准影印课例覆盖夜贵顺、夜贵逆。因此相关古籍条目可以升 B 并采用，但完整算法暂不设 `executableApproved=true`，运行时以具名 project-pan 规则执行。

## Requirements

### C04-R1 Evidence And Variant Decisions

- 将 `dlr.source.yuding-liuren-zhizhi-candidate` 的核页状态升为 `scanVerified`，保留版本真伪未定、仅作 supplement/variant 的限制，不升为主底本或 `approved`。
- 用 PDF 18、19 的 scan locator 和 `C04 independent scan audit` 二审记录补正 `shenjiang.json`、`variants.json`、`tool/daliuren_classics/_seed_registry.dart` 及旧研究报告。
- `dlr.rule.shenjiang.001/.004/.005` 可升 B 并标记采用；`006` 也可将“古籍区分天盘起贵与地盘定向”的事实升为 B/adopted，但“两张 map”必须另列为项目数据契约。`002/.003` 贵人整表继续保持 C、pending、不可执行。
- `dlr.variant.gui-ren-direction` 采用 `landing-palace-six-zones`；《直指》的逐支明文与《六壬大全》的天门地户原则是同一方法的明文和原则，不再登记成互斥 variant。“昼顺夜逆”只保留为原书明确称“近不用”的非采用旧说。
- 本轮不得因证据升级把完整神将算法设为 classic executable；新增/修正的执行行为使用稳定 `dlr.project.pan.*` 规则身份，并把 B 级规则仅作为 attribution。
- 因 adopted/B 状态变化，将证据目录版本由 `daliuren-classics/1.0.0` 升为新版本，旧版本字符串不原地改义。

### C04-R2 Noble Selection Boundary

- 自动模式严格按卯、辰、巳、午、未、申取昼贵，酉、戌、亥、子、丑、寅取夜贵；强制昼/夜只覆盖贵人选择，不决定顺逆。
- 日干和时支必须先验证；非法值抛 `ArgumentError`，不得回退丑未或静默判夜。
- 当前默认贵人表在主底本整表二审完成前继续作为明确命名的项目基线，不得标成已批准古籍整表。
- `jiaDayAlt` 不再出现在新起课 UI，也不得用于生成 v4 新盘；旧 JSON 仍可解析并按其原版本展示，不能把单干交换改名为《直指》完整异文。

### C04-R3 Landing Palace, Direction And Two Coordinates

- 先选择贵人天盘支 `selectedGuiRenTianBranch`，再以合法天盘 `P` 的逆映射求 `guiRenEarthPalace = inverse(P)[selectedGuiRenTianBranch]`。
- 顺逆只由贵人所临地盘宫决定：亥子丑寅卯辰为顺，巳午未申酉戌为逆；不得从昼夜、日干阴阳或旧 `isYangRi` 推断。
- 十二将身份次序固定为贵人、螣蛇、朱雀、六合、勾陈、青龙、天空、白虎、太常、玄武、太阴、天后。顺排时从贵人落宫按地支正序，逆排时按反序；每一宫的天盘支必须由同一张已验证天盘读取。
- 配置必须显式保存 `selectedGuiRenTianBranch`、`guiRenEarthPalace`、`actualDirection`、`tianBranchToGeneral`、`earthPalaceToGeneral` 和十二个同时含天盘支/地盘宫的位置事实。
- 四课与三传只能按 `tianBranchToGeneral` 解析乘将；圆盘和地盘位置展示只能按 `earthPalaceToGeneral`；禁止再提供语义含混的通用 `getShenJiangByDiZhi` 作为新调用入口。

### C04-R4 Model Integrity And Failure Semantics

- 新 `ShenJiangConfig` 构造和 JSON 读取必须验证：十二地支键全集、十二将各一次、两张 map 均为双射、十二 positions 与两张 map 一致、贵人锚点一致、相邻将序与 `actualDirection` 一致、天盘/地盘位置各唯一。
- 结果模型边界还必须验证每个 position 的 `heavenBranch == tianPanMap[earthPalace]`；缺键、重复、矛盾或 current 版本搭配 legacy shape 均须失败。
- 所有 list/map 采用防御性快照或不可变视图，构造后修改调用方集合不能改变盘面。
- 三传乘神解析改为必需依赖；缺配置、缺天盘支或不完整映射显式失败，禁止默认贵人。

### C04-R5 Cross-Layer Consumers

- `DaLiuRenSystem` 对四课和三传统一注入天盘支 resolver；三传的 `Chuan.chengShen` 必须来自同一配置。
- ViewModel 拆成按天盘支与按地盘宫的明确查询 API。
- 结果页分别显示“昼贵/夜贵所选天盘支”“贵人所临地盘宫”“实际顺布/逆布”；十二将项统一显示“乘某天盘支、临某地盘宫”。
- AI human text 与 `coreData` 使用同一坐标语义，结构化字段不得继续输出含混的 `diZhi/tianPanZhi`；四课和三传乘将与神将表必须一致。
- 圆盘天将环按地盘宫绘制，并补可直接断言宫位的 widget/helper 测试。
- 修正架构文档和接口文档中“昼顺夜逆”、`jiaDayAlt` 及旧含混 wire 示例。

### C04-R6 Versioning And Legacy Read

- 将新盘规则集升为 `daliuren-pan/4.0.0`，新增具名 `panV3 = daliuren-pan/3.0.0`；v1/v2/v3/legacy 结果继续可读且 compatibility 不是 current。
- 采用 read-old/write-new：旧 config shape 只在旧/未知盘版本的 `DaLiuRenResult.fromJson` 边界迁移；v4 + old shape 必须失败，防止旧结构冒充 current。
- 旧 `diZhiToShenJiang` 按实际历史语义迁为 `tianBranchToGeneral`；由旧 positions 恢复天盘映射并反查地宫，生成 `earthPalaceToGeneral` 和新 positions。
- 旧 `actualDirection` 从贵人到螣蛇在已存布局中的相邻方向推导，不读取旧 `isYangRi`；旧 `isYangRi` 不在新 JSON 中重写或重新解释。
- 迁移只规范化嵌套神将事实，不重算或覆盖旧 `SiKe`、`SanChuan`、`Chuan.chengShen`、`panRuleSetVersion`、ID 或起课输入；数据库表和备份容器版本无需迁移。
- repository round-trip 和备份导入必须覆盖真实 v3 old shape，保证读取、重存和导入不被静默 skipped。

### C04-R7 Verification

- 新增独立 `shen_jiang_service_test.dart`，使用不复制生产判断的表驱动预期覆盖昼贵/夜贵 x 顺区/逆区四类盘。
- 三张已批准《指南》昼贵课例继续作为外部固定 oracle；夜顺/夜逆用显式标注的合成边界例，不冒充古籍 fixture。
- 对每类盘同时断言：所选贵人天盘支、贵人落宫、实际方向、两张 map、十二 positions、四课乘将、三传乘将和圆盘地宫。
- 增加 model/current JSON malformed 矩阵、外部集合可变性、v3 migration、v4 old-shape rejection、repository/backup、formatter schema、结果页和圆盘测试。
- 目录生成、catalog validator、代码生成同步、静态检查、大六壬定向测试和全量测试必须通过。

## Acceptance Criteria

- [x] C04-R1：PDF 18/19 的页级证据、二审人和版本限制已进入 source/rule/variant/seed，目录版本已提升且 validator 通过。
- [x] C04-R1：贵人整表 `002/.003` 仍未越权批准；`jiaDayAlt` 未被伪装为《直指》版本；完整神将算法仍非 classic executable。
- [x] C04-R2：自动昼夜十二支边界、强制昼夜覆盖、非法日干/时支失败均有独立测试。
- [x] C04-R3：四类交叉盘的贵人天盘支、落宫、实际顺逆、天/地两张 map 和十二位置均与固定预期一致。
- [x] C04-R4：任一缺支、重复将、map/position 矛盾、贵人锚点或方向矛盾均不能构造 current 配置；调用方后改集合不影响结果。
- [x] C04-R4：四课和三传缺少任一乘神时显式失败，不再伪造贵人。
- [x] C04-R5：同一新盘在四课、三传、结果页、AI `coreData`、human text 和圆盘中使用一致的天盘/地盘坐标。
- [x] C04-R5：新起课 UI 不再提供 `jiaDayAlt`，用户可见文案不再把昼夜写成顺逆。
- [x] C04-R6：新盘写入 `daliuren-pan/4.0.0`；v3 old shape 可读、可重存、可导入且旧四课三传不变；v4 + old shape 被拒绝。
- [x] C04-R6：v1/v2/v3/legacy/future 的 compatibility 分类测试通过，v3 不被认作 current。
- [x] C04-R7：三张批准昼贵古例和四类合成边界例通过，预期值未调用生产排将算法生成。
- [x] 相关生成、静态检查、单元测试、repository/backup、formatter、widget 均通过；全量测试为 1260 项通过、1 项受保护的既有奇门图片尺寸失败，未修改大六壬以外产品行为。

## Out Of Scope

- 不在本任务最终裁决《六壬大全》卷十一、卷十二所对应的十干昼夜贵人整表；完成影印二审后应另更新 `002/.003`，不能扩大本轮默认表声明。
- 不把《御定六壬直指》升为主底本或确认其版本真伪。
- 不寻找或补造夜贵古籍完整盘；缺失门禁以 `executableApproved=false` 和合成边界测试明确记录。
- 不重算、覆盖或批量迁移历史盘；历史盘警示和可选关联重排仍由 C15/C16 完成。
- 不修改九宗门取传、神煞、传统断课或应期规则；只修正这些层消费的乘神事实。
- 不改数据库表结构和通用备份格式。

## Deferred Risks

- 当前默认贵人整表仍是项目基线，虽有多处主底本转录线索，但五干与《直指》异文的最终裁决需独立影印二审。
- 缺少夜贵顺/逆的批准影印完整盘，所以本轮可以修复结构与项目执行算法，但不能把完整链路宣称为已批准古法。
