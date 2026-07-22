# PRD: 六爻断卦分析引擎与三层展示

## Goal

为六爻系统补上"断卦分析层"：将 11 类约 80 个断卦概念（旺衰/空亡/墓绝/合冲刑害/动变/六亲/伏神/特殊作用/卦变/应期等）实现为确定性纯函数分析引擎，并以"三层递进披露"的 UI 展示在结果页，应期结果联动日历。用户价值：从"只排盘、断卦全靠 AI"升级为"排盘 + 确定性分析 + AI 解读"，分析结果同时注入 AI 提示词提升解卦准确率。

## Background（现状确认事实）

- 结果页 `LiuYaoResultScreen`（lib/divination_systems/liuyao/ui/liuyao_result_screen.dart:13）为 StatelessWidget 纯展示；区块：ExtendedInfoSection → 排盘参数 → DiagramComparisonRow(LiuYaoTableWidget) → SpecialRelationSection → AIAnalysisWidget
- 爻行已有标注：六神、六亲+干支+五行、世/应、动爻 ╳→、伏神（FuShenService）
- 断卦分析能力现状：**零实现**。仅有排盘层 GuaCalculator、LiuShenService、FuShenService（位于 lib/domain/services/ 根目录；大六壬服务在 lib/domain/services/daliuren/ 子目录）
- `LiuYaoResult` 为 freezed 模型（lib/divination_systems/liuyao/liuyao_result.dart），字段含 mainGua/changingGua/lunarInfo/liuShen/questionId 等
- 持久化：resultData 为 JSON 文本列（无 schema 迁移压力）；`DivinationRepositoryImpl.updateRecord()`（divination_repository_impl.dart:119）与 DAO `updateRecord()` 已存在
- 日历 `CalendarScreen` 为通用黄历（AlmanacHeader/FourPillarsCard/YijiPanel/TimeHourBar/MoonPhaseKongwang/PengzuCard），与术数系统解耦，格子无吉凶标记
- antique 组件库有 Card/Tag/Dialog/Button 等 11 个组件；**无**折叠面板/Tab 组件
- AI 层：AIAnalysisWidget 挂结果页末尾，PromptAssembler 组装提示词
- 现有 283 tests 全部通过

## Requirements

### R1 分析引擎（lib/domain/services/liuyao/analysis/，纯函数 + TDD）

服务模块与覆盖概念：

| 模块 | 概念 |
|-----|-----|
| wang_shuai | 月建/月破/日建/日破/得月令/得日扶/旺相休囚死/月生/月克/日生/日克 |
| kong_wang | 旬空/真空/假空/动不为空/旺不为空/冲空/填实/出空 |
| mu_jue | 入日墓/入月墓/入动墓/入变墓/出墓/临绝/化绝（十二长生） |
| he_chong_xing_hai | 六合/六冲/三合局/半合/合住/合起/合绊/冲开/冲破/三刑/相害 |
| dong_bian | 动爻/静爻/暗动/日冲/冲起/冲实/冲散/冲脱/独发/独静/化进神/化退神/回头生/回头克/化空/化破/化墓/化绝/化合/化冲/化扶/化泄 |
| sheng_ke | 生/克/泄/耗/扶/拱/制/化/贪生忘克/贪合忘生/连续相生/连续相克 |
| liu_qin_deduce | 用神/原神/忌神/仇神/闲神推导（输入用户选定爻位）、用神两现、用神不现（伏神取用） |
| fu_shen_relation | 飞生伏/飞克伏/伏生飞/伏克飞/伏神得出/伏神受制 |
| special | 日月入爻/日月合爻/日月冲爻/太岁入爻/三合成局/动爻生克用神/变爻反作用本爻 |
| gua_change | 伏吟/反吟/六合卦/六冲卦/游魂卦/归魂卦/卦变六合/卦变六冲 |
| ying_qi | 应期推算：出空/填实/冲墓/冲开/值日/合日/冲动等规则 → 候选应期列表（附理由） |

- 统一输出模型：`YaoAnalysisTag { term, category, polarity(吉/凶/中性), priority, reason, relatedYao }`
- 编排器：`LiuYaoAnalyzer.analyze(gua, lunarInfo, {int? yongShenPosition}) → AnalysisReport`
- yongShenPosition 为空时仅输出爻级客观分析（旺衰/空亡/墓绝/合冲/动变），不输出用神推理链与应期

### R2 用神自由点选

- 用户在结果页点击爻行六亲弹菜单「设为用神/取消用神」；总览卡提供备用入口（六亲列表含伏神）
- **不做占类自动推断**
- 未选用神：爻级客观分析照常展示，总览卡显示引导态
- 选定后联动刷新：总览卡（原/忌/仇神+结论）、爻徽标（追加[用神]等并重排优先级）、应期卡
- 用神两现：两爻均可选，选一后另一爻标「用神两现·舍此取彼」；用神不现：伏神行可选
- 持久化：`LiuYaoResult` 增加 `int? yongShenPosition`（入 resultData JSON，旧记录 null 兼容），经 `updateRecord()` 落库；换选即时重算

### R3 UI 三层递进披露

- **第一层 断卦总览卡**：置于卦象表格上方；用神/原神/忌神/仇神 AntiqueTag、用神状态摘要、吉凶结论一句话、应期提示 + 「查看应期日历」按钮；未选用神时为引导态
- **第二层 爻行徽标 + 爻详析 Sheet**：爻行内联徽标按 priority 最多 2~3 个（月破/日破/真空 > 暗动/冲起 > 化进/化退 > 泄耗扶拱）；配色：吉=青/金、凶=朱砂、中性=墨灰（沿用 13 色 token）；点击爻行弹底部 Sheet，按分类分组展示该爻全部分析（term + reason）
- **第三层 术语词典**：约 80 词条静态 Map（定义 + 成立条件 + 吉凶含义）；点击任意术语弹 AntiqueDialog
- 跨爻关系（连续相生/三合局等）在 Sheet 中以文字 + relatedYao 展示；生克关系连线图**不在本任务范围**

### R4 结果页状态层

- 新增 `LiuYaoAnalysisController extends ChangeNotifier`：持有 yongShenPosition + 派生 AnalysisReport；结果页顶部 Provider 注入；区块用 Provider.select 精确订阅
- AnalysisReport 为派生数据**一律不存**，规则升级后旧卦自动获得新分析

### R5 应期日历联动

- 结果页应期卡：候选应期列表（日期/干支 + 理由 chip）
- 「查看应期日历」→ CalendarScreen 进入应期模式（route arguments 传卦上下文，不迁移路由框架）
- 月视图格子角标：合（金）/冲（朱砂）/空（灰圈）/应（高亮，命中应期规则）—— 基于当日干支 vs 用神
- 日详情插入「与本卦」区块（FourPillarsCard 与 YijiPanel 之间）
- 可退出应期模式恢复通用黄历；日历无卦上下文时行为与现状完全一致

### R6 AI 联动

- PromptAssembler 注入 AnalysisReport 摘要 + 用户选定用神；未选时提示 AI 自行判断并建议用神

## Key Decisions

- **规则基准**：以《增删卜易》为主干裁决所有流派分歧（暗动=旺相静爻逢日冲、真空假空判定、贪生忘克边界等均从增删卜易）；增删卜易弃用但需求明确要求的概念（三刑、相害）按《卜筮正宗》补充实现，正常标注但 priority 置低。**不做流派切换配置**
- 用神由用户自由点选，不做占类自动推断
- AnalysisReport 为派生数据不落库，仅持久化 yongShenPosition

## 架构约束

- 不动 DivinationSystem 接口、数据库 schema、Repository 接口、命名路由
- 不移动 gua_calculator 等既有文件（归位留待后续任务）
- 分析服务为纯静态函数，无副作用；新引擎放 lib/domain/services/liuyao/analysis/（对齐 daliuren/ 先例）

## 实施顺序

1. 分析引擎（TDD） 2. 爻徽标 + 爻详析 Sheet + 用神点选 3. 总览卡 + 术语词典 4. 应期卡 + 日历应期模式 5.（本任务外）生克连线图

## Acceptance Criteria

- AC1 分析引擎各模块有单元测试，覆盖 R1 表中每个概念至少 1 个正例 + 1 个反例；判定规则与《增删卜易》一致，经典卦例（六冲卦、月破爻、旬空爻等）验证与手工排盘一致
- AC2 结果页未选用神时：爻行显示客观分析徽标，总览卡为引导态，无用神推理内容
- AC3 点选六亲设为用神后：总览卡出现原/忌/仇神与结论，相关爻徽标更新，应期卡出现；重开该历史记录选择仍在
- AC4 点击爻行弹出详析 Sheet，分类展示该爻全部分析项；点击术语弹词典解释
- AC5 从应期卡进入日历：格子出现合/冲/空/应角标，日详情有「与本卦」区块；直接打开日历（无卦上下文）与现状一致
- AC6 生成 AI 分析时提示词包含分析报告与用神信息（未选时含"请建议用神"指令）
- AC7 现有 283 tests 全部保持通过；旧历史记录（无 yongShenPosition）正常打开

## Out of Scope

- 生克关系连线图（后续任务）
- 占类自动推断用神
- 小六壬/梅花/大六壬的分析引擎
- 数据库 schema 变更、路由框架迁移、旧服务文件归位
- 暗黑模式适配以外的主题工作
- 流派切换配置

## Open Questions（阻塞）

（无）
