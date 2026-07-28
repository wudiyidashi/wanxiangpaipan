# 奇门遁甲系统说明

**状态**：Domain Engine Complete / Product Integration Pending  
**规则范围**：时家转盘奇门  
**结果 schema**：`qimen` / version `1`

## 1. 系统边界

本模块提供可独立调用、可序列化和可由通用仓储保存的奇门排盘引擎。
当前不注册到产品启动入口、不提供 Flutter 起局页或结果页；这些属于后续产品集成任务。

支持：

- 时间起局 `CastMethod.time`
- 手动校盘 `CastMethod.manual`
- 拆补、茅山、置闰三种自动定局
- 当地民用时间、北京时间、真太阳时
- 子初换日、午夜换日
- 完整九宫、三奇六仪、九星、八门、八神、暗干、旬空和驿马

不支持：飞盘、阴盘、年家、月家、日家奇门和断局分析。

## 2. 输入合同

### 时间起局

```dart
{
  'params': {
    'juMethod': 'chaiBu',
    'timeBasis': 'localCivil',
    'sourceUtcOffsetMinutes': 480,
    'longitude': 116.4,
    'dayBoundary': 'ziInitial',
    'hostingMode': 'kunTwo',
    'hiddenStemMode': 'dutyDoorHourStem',
    'questionCategory': 'general',
  }
}
```

`params` 可省略。真太阳时必须同时提供来源 offset 和经度；经度范围为
`[-180, 180]`。北京时间的 offset 固定为 `480`。

### 手动校盘

```dart
{
  'yearGanZhi': '丙午',
  'monthGanZhi': '乙未',
  'dayGanZhi': '甲子',
  'hourGanZhi': '庚午',
  'solarTerm': '小暑',
  'dun': 'yin',
  'juNumber': 8,
  'yuan': 'upper',
  'params': {
    'hostingMode': 'kunTwo',
    'hiddenStemMode': 'dutyDoorHourStem',
  }
}
```

四柱必须属于六十甲子，节气必须属于二十四节气，局数必须在 `1..9`。
任何缺失柱或旧式简化字段均验证失败，不生成静默默认四柱。

## 3. 时间与定局

结果同时保存原始瞬间、基准墙上时间、生效排盘时间、来源 offset、标准经线、
经度校正、方程时校正及算法版本。原始瞬间和 `castTime` 统一以 UTC wire string
保存；墙钟坐标单独保存。真太阳时使用 `noaa-eot-v1`。

`lunar 1.7.8` 的精确节气和 Exact 年/月柱按北京时间钟面解释，因此服务先按
原始绝对瞬间建立北京时间历法上下文，再把前一、当前、下一节气时刻转换为目标
offset。真太阳时对每个交节时刻应用当时的经度与方程时校正；日柱和时柱仍按用户
选择的有效排盘墙钟与换日规则计算。同一实际交节瞬间在不同时区会切换同一节气。

拆补以甲/己五日符头定三元；茅山以精确交节所在时辰起点划分每 60 时辰；
置闰按上元符头动态计算超神接气。超神时 `chaoShenDays` 采用完整经过日数；公开
来源按首尾包含称“十一日”的案例在结果中记为 `10`。当前周期符头晚于交节时标记
接气，此时 `chaoShenDays=0`，接气完整日数保留在推导轨迹。仅芒种/大雪且完整日数 `> 9` 时，
符头开始的首个十五日周期已提前采用该节气，第二个十五日周期标记为闰；三十日
结束后回归实际二至。`symbolHead` 保存当前五日元符头。所有策略输出同构
`QimenJuInfo` 和推导轨迹。

值使旬首遁仪落中五时，门名按寄宫取门，飞宫从原始五宫计步，最终落五才寄宫。
兼容阳遁寄艮八时，中五干随艮宫转动，但天禽仍始终随天芮转布。

## 4. 结果合同

`QimenResult` 除通用字段外包含：

- `panParams`、`temporalContext`、`juInfo`
- 九个 `QimenPalace`
- 旬首及遁仪
- 值符星/宫和值使门/宫
- 时旬空、驿马支/宫
- 完整 `derivationSteps`

每宫保留元数据、天地盘干、寄宫干/星、九星、八门、八神、暗干、空亡、
驿马和基础标记。中五原始事实与寄宫事实分别存储。

摘要固定为：

```text
阴遁8局 · 天任值符 / 生门值使
```

反序列化会拒绝未知 schema、错误 system type 和不完整九宫。

## 5. 持久化与集成

Qimen 复用 `DivinationRepository` 的 JSON 存储与查询，不增加数据库表。调用方可在
独立作用域把 `QimenSystem` 注册到 `DivinationRegistry` 后保存和读取；产品
`registry_bootstrap.dart` 在后续 UI 任务前保持不变。

## 6. 规则来源

规划和裁决基线：
`.trellis/tasks/07-28-qimen-module/research/qimen-rule-baseline.md`。

固定校验案例：

- 1898 大雪置闰周期：陈炳聿按《图解详述奇门遁甲置润法定局排盘》，
  https://www.sohu.com/a/286929542_488508，访问日期 2026-07-28。
- 2008-11-04 12:30 北京时间完整核心九宫：`3metaJun/3meta` commit
  `9be1238cbb7b0118826a689f9d3f8100284f6df3` 与 `xuanyuwang/QiMen` commit
  `c07efe2ba3c74b58e02301abce1c16b4eb9d79b1`。

两个公开代码仓的固定盘可能存在共同谱系，不作为两份独立权威；项目测试同时按
冻结的转盘规则逐宫复核。外部源码只用于交叉核验，本实现未直接移植。
