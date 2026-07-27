# AI提示词与结构化输出优化

## Goal

让提示词模板与分析引擎产出的"断课分析（规则标注）"段协同：AI 以程序结论为事实基础展开解读而非自行重推；补齐应期输出结构；formatter 总览补旬首。

## 背景事实（已核实）

- `insertTemplates` 为 `insertAllOnConflictUpdate`：内置模板每次启动覆盖同 id 数据库行，改代码即生效，无需版本升级逻辑；用户自定义模板为独立行不受影响。
- 六爻与大六壬 formatter 均已输出 analysis 段（程序规则标注 + 裁决摘要 + 应期候选），但四个模板（liuYao/daLiuRen 的 system + analysis）均写于分析引擎之前，未引用该段。

## Requirements

- R1 `builtin_templates.dart` 六爻与大六壬 **system** 模板各新增"排盘数据使用约定"小节，必须包含以下三层意思（措辞可润色）：
  1. 排盘数据与"分析（规则标注）"段由程序按锁定规则计算，视为事实基础；
  2. 不得自行重推排盘结论（六爻：装卦/世应/旺衰标签；大六壬：三传取法/课体/涉害深度），解读工作是展开象意、事理与人事应对；
  3. 若自身判断与"裁决摘要"不一致，可以提出但必须显式说明分歧理由，不得默默替换结论。
- R2 两个 **analysis** 模板输出结构调整：
  - 首节措辞由"判断课体/卦性"改为"解释程序已判定的课体（格局）/卦性含义"；
  - "综合判断"节要求以裁决摘要为基准展开、结合求测问题具体化；
  - 新增"应期提示"节：基于应期候选说明各时间窗口的触发条件与含义，不得凭空另造应期。
- R3 大六壬 formatter 总览补"旬首"行（如"甲申旬"，复用 `TianGanDiZhiService.getGanZhiIndex` 按 index~/10*10 取旬首干支，参考 `daliuren_result_screen.dart._resolveXunName`）；coreData.overview 同步加 `xunShou` 干支字段（现有 `xunShou` 为取旬模式标签，新字段命名区分，如 `xunShouGanZhi`）。
- R4 模板/formatter 相关测试更新：模板内容测试（如有）断言新小节关键词；`daliuren_formatter_test.dart` 断言旬首行。
- R5 六爻侧仅改模板文本，不改 liuyao formatter 与逻辑。

## Constraints

- 模板既有 Handlebars 变量与条件块（{{structuredOutput}}、{{#if question}} 等）不得破坏。
- 简要（brief）模板本次不动。
- 不改 ai_config_manager / DAO；不引入模板版本机制（已确认不需要）。

## Acceptance Criteria

- [ ] 四个模板含新小节且 Handlebars 结构完整（渲染测试通过）。
- [ ] 大六壬 formatter 总览含"旬首：X旬"，戊子黄金例断言（甲申旬）。
- [ ] `flutter analyze` 零告警；`flutter test` 全量通过。
