# Design: 六爻断卦分析引擎与三层展示

## 架构总览

新增内容全部为**顺向扩展**，不修改任何既有接口。三个新增点：

```
lib/domain/services/liuyao/analysis/     ← 新增：分析引擎（纯函数）
lib/divination_systems/liuyao/
  ├─ liuyao_result.dart                  ← 扩展：+ int? yongShenPosition
  ├─ viewmodels/liuyao_analysis_controller.dart ← 新增：结果页状态层
  └─ ui/widgets/                         ← 新增：总览卡/徽标/详析Sheet/应期卡
lib/presentation/screens/calendar/       ← 扩展：可选卦上下文（应期模式）
```

## 分析引擎

### 目录结构

```
lib/domain/services/liuyao/analysis/
├── models/
│   ├── analysis_tag.dart        # YaoAnalysisTag + TagCategory + Polarity（freezed，无 json）
│   ├── analysis_report.dart     # AnalysisReport / YongShenChain / YingQiCandidate
│   └── term_glossary.dart       # 静态词典 Map<String, TermEntry>（~80 条）
├── tables/
│   ├── dizhi_relations.dart     # 六合/六冲/三合局/半合/三刑/相害 静态表
│   └── chang_sheng_table.dart   # 五行十二长生表（水土同宫，长生申；墓=辰戌丑未）
├── wang_shuai_service.dart
├── kong_wang_service.dart
├── mu_jue_service.dart
├── he_chong_service.dart
├── dong_bian_service.dart
├── sheng_ke_service.dart
├── liu_qin_deduce_service.dart
├── fu_shen_relation_service.dart
├── special_service.dart
├── gua_change_service.dart
├── ying_qi_service.dart
└── liuyao_analyzer.dart         # 编排器（唯一对 UI 暴露的入口）
```

所有服务为纯静态函数：输入 `Gua` / `LunarInfo` / 已算出的中间结果，输出 `List<YaoAnalysisTag>`。规则依据《增删卜易》；三刑/相害按《卜筮正宗》补充且 priority 置于最低档。

### 数据契约

```dart
enum TagCategory { wangShuai, kongWang, muJue, heChong, dongBian, shengKe,
                   liuQin, fuShen, special, guaChange }
enum Polarity { ji, xiong, neutral }        // 吉/凶/中性

class YaoAnalysisTag {   // freezed（无 json_serializable）
  String term;           // "月破"
  TagCategory category;
  Polarity polarity;
  int priority;          // 0 最高；内联徽标取每爻前 2~3 个
  String reason;         // "月建卯木冲戌土"
  List<int> relatedYao;  // 跨爻关系的关联爻位（1-6；变爻用 -position 或独立字段标记）
}

class AnalysisReport {
  Map<int, List<YaoAnalysisTag>> yaoTags;  // key: 爻位 1-6（本卦爻；化X类标签挂在动爻上）
  List<YaoAnalysisTag> guaTags;            // 卦级：六冲卦/伏吟/卦变六合…
  YongShenChain? yongShen;                 // 未选用神时为 null
  List<YingQiCandidate>? yingQi;           // 依赖用神，同上
  String? verdictSummary;                  // 一句话结论（依赖用神）
}

class YongShenChain {
  int position;                  // 用神爻位；伏神取用时记飞爻位 + isFuShen=true
  bool isFuShen;
  List<int> duplicatePositions;  // 用神两现的另一爻
  int? yuanShen; int? jiShen; int? chouShen; List<int> xianShen;
}

class YingQiCandidate {
  String label;      // "戌日（填实旬空）"
  String branch;     // 应期地支（用于日历匹配）
  YingQiScale scale; // 日/月/年
  String reason;
  int priority;
}
```

### 编排器

```dart
class LiuYaoAnalyzer {
  static AnalysisReport analyze(Gua mainGua, Gua? changingGua,
      LunarInfo lunarInfo, {int? yongShenPosition});
}
```

内部流程：卦级判定（gua_change）→ 逐爻客观分析（wang_shuai → kong_wang → mu_jue → he_chong → dong_bian → sheng_ke → fu_shen_relation → special）→ 若有 yongShenPosition：liu_qin_deduce 推原/忌/仇/闲 → 用神相关标签升 priority → ying_qi 依据用神状态生成候选 → verdictSummary。

判定依赖顺序（重要）：空亡/月破的"真假"判定依赖旺衰结论（旺不为空、动不为空），暗动依赖旺衰+静爻+日冲，应期依赖全部前序结论。编排器内按此序传递中间结果，服务间不互相调用。

### 关键规则基准（增删卜易裁决）

- 暗动：**旺相静爻**逢日辰冲 → 暗动；休囚静爻逢冲 → 日破（冲散）
- 真空：休囚无气之空为真空；旺相之空、动而空、日月生扶之空为假空，出空/填实即有用
- 贪生忘克：动爻遇可生之爻与可克之爻并存时舍克就生
- 贪合忘生/忘克：合的优先级高于生克
- 三合局：三爻齐动或二动一静(拱)成局；缺主爻(生旺墓之"旺")不成局
- 三刑/相害：仅作低优先级参考标注（卜筮正宗补充），不参与吉凶主判

## 用神选择与持久化

- `LiuYaoResult` + `int? yongShenPosition`（freezed 重新生成 .freezed/.g）；旧记录 JSON 无此键 → null，天然兼容，**无数据库迁移**
- 落库走既有 `DivinationRepositoryImpl.updateRecord()`（divination_repository_impl.dart:119）
- 伏神取用：yongShenPosition 记飞神所在爻位，另加 `bool yongShenIsFuShen`（同样可空默认 false）

## 结果页状态层

```dart
class LiuYaoAnalysisController extends ChangeNotifier {
  LiuYaoAnalysisController(this._result, this._repository) { _recompute(); }
  LiuYaoResult _result;
  AnalysisReport _report;          // 派生，不落库
  Future<void> selectYongShen(int position, {bool isFuShen = false});
  Future<void> clearYongShen();
  // select/clear: copyWith → updateRecord() → _recompute() → notifyListeners()
}
```

- 在 `LiuYaoResultScreen` 外层包 `ChangeNotifierProvider`（该屏改为注入点，区块内部用 `context.select` 订阅各自切片：总览卡订阅 yongShen+verdict，表格订阅 yaoTags，应期卡订阅 yingQi）
- 分析计算 < 10ms 量级（纯表查找），同步重算即可，无需 isolate

## UI 组件

| 组件 | 位置 | 说明 |
|-----|------|-----|
| `AnalysisOverviewCard` | 表格上方 | 引导态 / 用神链 Tag + 状态摘要 + 结论 + 应期入口 |
| 爻行徽标 | `LiuYaoTableWidget` 行内 | 每爻 top 2~3 tag；复用 `AntiqueTag` 缩小版；吉=青金/凶=朱砂/中性=墨灰（既有 token） |
| `YaoDetailSheet` | 底部弹出 | 点爻行触发；按 TagCategory 分组列出全部 tag（term 可点 → 词典）；含「设为用神」按钮 |
| 用神点选菜单 | 长按/点击六亲区域 | `showMenu` 或小型 popup：设为用神/取消 |
| `TermGlossaryDialog` | 全局 | `AntiqueDialog` 包装词条：定义/成立条件/吉凶含义 |
| `YingQiCard` | SpecialRelationSection 之后 | 候选应期列表 + 「查看应期日历」 |

注意：`LiuYaoTableWidget` 同时渲染本卦与变卦（DiagramComparisonRow 两侧），徽标与点选只作用于**本卦侧**；变卦侧保持现状。给 widget 加可空参数（`yaoTags`, `onYaoTap`），不传则行为与现状完全一致——大六壬等其他调用方零影响。

## 应期日历联动

- 新增 `GuaCalendarContext { String yongShenBranch; String yongShenWuXing; List<String> kongWang; List<YingQiCandidate> yingQi; String guaSummary; }`
- 路由：`Navigator.pushNamed('/calendar', arguments: GuaCalendarContext(...))`；CalendarScreen 读取可空 arguments，null 时与现状完全一致
- 月视图格子角标（每日仅取最高优先级 1 个）：应（命中 yingQi.branch，高亮）> 冲（日支冲用神，朱砂）> 合（日支合用神，金）> 空（日支值用神旬空标灰圈）
- 日详情「与本卦」区块：当日干支与用神的生克合冲文字描述，插在 FourPillarsCard 与 YijiPanel 之间
- 顶部显示关联卦名 + 「退出应期模式」按钮
- 性能：月视图 42 格 × 干支关系查表，同步计算可忽略

## AI 联动

- `PromptAssembler` 增加可选注入段：`AnalysisReport` 序列化为紧凑文本（每爻 tag 列表 + 用神链 + 应期候选）；未选用神时追加"请先建议用神再解卦"指令
- 模板变量新增 `{{analysis_report}}`，旧模板无此变量时跳过注入（向后兼容）

## 兼容与回滚

- 所有新增 UI 均由"数据存在与否"驱动（yaoTags 空 → 不渲染徽标；context null → 日历现状），单点可回退
- `LiuYaoResult` 字段可空 + JSON 容忍未知键，双向兼容（新版读旧记录 ✓，旧版读新记录 ✓——json_serializable 默认忽略未知键）
- 风险最高的改动：`liuyao_result.dart` codegen 与 `LiuYaoTableWidget` 签名扩展；均通过现有 283 tests 回归兜底

## 权衡记录

- freezed（无 json）用于分析模型：与项目"数据模型一律 freezed"约定一致，代价是 codegen 略增；分析模型不序列化故不加 json_serializable
- 分析同步计算不做缓存/isolate：数据量恒定（6 爻 × 表查找），过早优化无益
- 徽标只显示 top 2~3 而不是全部：信息密度决策，完整信息在 Sheet 层，避免表格行爆炸
- 日历角标只标 1 个而不是叠加：42 格小空间内多角标不可读
