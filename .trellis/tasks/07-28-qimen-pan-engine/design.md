# 奇门遁甲排盘与历法引擎设计

## 1. 文件边界

```text
lib/divination_systems/qimen/
  qimen_system.dart
  models/
    qimen_enums.dart
    qimen_pan_params.dart
    qimen_temporal_context.dart
    qimen_ju_info.dart
    qimen_palace.dart
    qimen_result.dart

lib/domain/services/qimen/
  qimen_constants.dart
  qimen_time_service.dart
  qimen_ju_service.dart
  qimen_ju_strategy.dart
  chai_bu_ju_strategy.dart
  mao_shan_ju_strategy.dart
  zhi_run_ju_strategy.dart
  qimen_earth_plate_service.dart
  qimen_duty_service.dart
  qimen_heaven_plate_service.dart
  qimen_door_service.dart
  qimen_deity_service.dart
  qimen_hidden_stem_service.dart
  qimen_marker_service.dart
```

可在不破坏职责的前提下合并极小文件，但时间、定局策略与盘面阶段不得合成一个巨型 service。

## 2. 稳定枚举

所有 enum 自带 `id` / `fromId`，JSON 用 ID：

- `QimenJuMethod`: `chaiBu`, `maoShan`, `zhiRun`, `manual`。
- `QimenTimeBasis`: `localCivil`, `beijing`, `trueSolar`。
- `QimenDayBoundary`: `ziInitial`, `midnight`。
- `QimenHostingMode`: `kunTwo`, `yangEightYinTwo`。
- `QimenHiddenStemMode`: `dutyDoorHourStem`, `doorOriginEarthStem`。
- `QimenDun`: `yang`, `yin`。
- `QimenYuan`: `upper`, `middle`, `lower`。
- `QimenQuestionCategory`: `general`, `career`, `wealth`, `relationship`, `health`, `study`, `travel`, `litigation`。

## 3. 输入 schema

### 3.1 `CastMethod.time`

```dart
{
  'params': {
    'juMethod': 'chaiBu',
    'timeBasis': 'localCivil',
    'sourceUtcOffsetMinutes': 480,
    'longitude': 116.4, // only trueSolar
    'dayBoundary': 'ziInitial',
    'hostingMode': 'kunTwo',
    'hiddenStemMode': 'dutyDoorHourStem',
    'questionCategory': 'general',
  }
}
```

- `params` 可省略并使用上述默认值；不认识的 ID、错误类型或越界值验证失败。
- `castTime` 是一个实际瞬间；当地模式转为 `toLocal()`，北京时间转为 UTC+08:00，真太阳时先取来源民用墙上时间再校正。
- `sourceUtcOffsetMinutes` 在当地模式可由 `castTime.timeZoneOffset` 补齐；北京时间固定 480；真太阳时必须显式可得。

### 3.2 `CastMethod.manual`

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
  'params': { ...same non-ju options... }
}
```

- 四柱必须属于六十甲子，局数 `1..9`，节气属于二十四节气。
- 自动时间上下文仍用于保存显示时间、offset 与相邻节气，但排盘四柱和局数使用显式输入。
- 结果中的 `juMethod` 固定为 `manual`。

## 4. 时间模型与算法

`QimenTemporalContext` 至少包含：

- `originalTime`, `basisWallTime`, `effectivePanTime`。
- `timeBasis`, `sourceUtcOffsetMinutes`, `longitude`, `standardMeridian`。
- `longitudeCorrectionMinutes`, `equationOfTimeMinutes`, `totalCorrectionMinutes`, `correctionAlgorithmVersion`。
- 年/月/日/时柱、换日规则、前一/当前/下一节气名称与精确时刻。

`lunar` 的精确节气与 Exact 年/月柱先在北京时间钟面坐标求取；节气选择以
`originalTime` 的绝对瞬间为准，再转换为目标 offset/真太阳时坐标。日/时柱按
`effectivePanTime` 求取。绝对瞬间字段统一以 UTC wire string 序列化。

真太阳时公式固定为 v1：

```text
gamma = 2*pi/365 * (dayOfYear - 1 + (hour - 12)/24)
EoT = 229.18 * (0.000075 + 0.001868*cos(gamma)
      - 0.032077*sin(gamma) - 0.014615*cos(2*gamma)
      - 0.040849*sin(2*gamma))
longitudeCorrection = 4 * (longitude - utcOffsetHours*15)
effectivePanTime = civilWallTime + EoT + longitudeCorrection
```

- `ziInitial` 使用 `getDayInGanZhiExact()`。
- `midnight` 使用 `getDayInGanZhiExact2()`；23 时的时支仍为子，时干用选定日干按五鼠遁重算。
- 节气比较使用完整年月日时分秒，禁止调用 whole-day 模式。

## 5. 定局策略

`QimenJuStrategy.resolve(QimenTemporalContext) -> QimenJuInfo`。`QimenJuService` 按 `QimenJuMethod` 分发并拥有唯一二十四节气局数表。

### 拆补

- 从有效日干支索引回退 `index % 5` 日得到甲/己符头。
- 符头支集合决定上中下元，当前精确节气决定阴阳遁与局数。

### 茅山

- 当前节气精确时刻向下归入所在双小时支的起点。
- elapsed `<120h` 为上元，`120..<240h` 为中元，其余到下一交节为下元。

### 置闰

- 以四种上元符头（甲子、己卯、甲午、己酉）形成十五日周期，计算相对交节的超神/接气天数。
- `chaoShenDays` 按完整经过日数计；超过九日时，芒种或大雪从首个十五日周期即提前生效，第二个十五日周期标为闰；三十日后在二至新节气重新对齐。
- `QimenJuInfo` 保存 `chaoShenDays`, `isReceivingQi`, `isLeap`, `effectiveSolarTerm` 和完整说明。
- 置闰黄金用例未通过时策略抛出明确错误，不回退到拆补。

## 6. 九宫模型

`QimenPalace` 字段：

- 宫号、宫名、卦、方位、五行与所辖地支。
- `earthStem`, `hostedEarthStem?`, `heavenStem`, `hostedHeavenStem?`。
- `star`, `hostedStar?`, `door?`, `deity?`, `hiddenStem?`。
- `voidBranches`, `isHorse`, `marks`。

中五宫仍保留自身地盘干和天禽事实；寄宫目标额外保存 hosted 字段，禁止用覆盖主字段的方式丢失原盘。

## 7. 盘面流水线

1. `QimenTimeService` 生成时间上下文。
2. 定局 strategy 生成 `QimenJuInfo`，或接收 manual 信息。
3. 地盘按戊己庚辛壬癸丁丙乙，阳顺阴逆飞九宫。
4. 时柱定旬首与遁仪；遁仪地盘本位定值符星和值使门。
5. 值符随有效时干落宫；值使按旬首支到时支步数阳顺阴逆飞九宫。旬首遁仪在中五时从原始五宫计步，仅最终落五时寄宫。
6. 天盘九星和携带天盘干按外八宫转布；天禽按参数寄宫。
7. 八门按固定外八宫序转布；中宫无门。
8. 八神从值符落宫按阳顺阴逆布外八宫。
9. 暗干按所选 strategy 生成。
10. 时旬空映射宫位，时支三合局取驿马，生成基础标记。
11. 断言九宫完整且必需槽位无重复/缺失，组装 result 与 derivation trace。

## 8. 结果合同

`QimenResult`：

- 通用字段：`id`, `castTime`, `castMethod`, `lunarInfo`, `questionId/detailId/interpretationId`。
- `schemaVersion=1`, serialized `systemType=qimen`。
- `panParams`, `temporalContext`, `juInfo`, `palaces`。
- `xunShou`, `xunHiddenStem`, `zhiFuStar/palace`, `zhiShiDoor/palace`。
- `kongWangBranches`, `horseBranch/palace`, `derivationSteps`。

fromJson 先验证 `schemaVersion`、`systemType` 和九宫完整性，再构造对象。枚举统一使用 ID converter，禁止生成器默认 `enum.name`。

## 9. 测试设计

- 每个 pure service 表驱动测试；公共常量表覆盖所有合法值。
- 时间测试冻结 offset，不能依赖测试机时区。
- 黄金 fixture 使用强类型结构并记录来源元数据；端到端比较每宫全部事实。
- JSON 测试先序列化再反序列化做对象深比较，并检查实际 JSON 中全部 enum 为稳定 ID。
- 仓储使用内存 Drift + fake secure storage，覆盖保存/读取/查询。

## 10. 兼容与许可

- 只新增 enum 值和纯领域模块，不注册系统，不改变现有首页行为。
- 若从外部 MIT 项目移植实质代码，文件头注明项目、URL 与 MIT；仅参考思想则在系统文档列参考来源。
