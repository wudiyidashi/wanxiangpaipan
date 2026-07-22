# Implement: 六爻断卦分析引擎与三层展示

## 执行阶段（TDD：每步先测后码）

### Phase A — 基础表与模型
- [x] A1 `tables/dizhi_relations.dart`：六合/六冲/三合局/半合/三刑/相害静态表 + 测试
- [x] A2 `tables/chang_sheng_table.dart`：五行十二长生（水土同宫）+ 测试
- [x] A3 `models/analysis_tag.dart` `models/analysis_report.dart`（freezed，无 json）+ build_runner 生成

### Phase B — 分析服务（每个服务：先写正例+反例测试，再实现）
- [x] B1 wang_shuai_service（月建/月破/日建/日破/旺相休囚死/月生克/日生克/得令得扶）
- [x] B2 kong_wang_service（旬空/真空/假空/动不为空/旺不为空/冲空/填实/出空）——依赖 B1 结论
- [x] B3 mu_jue_service（入日/月/动/变墓、出墓、临绝、化绝）
- [x] B4 he_chong_service（六合/六冲/三合/半合/合住/合起/合绊/冲开/冲破/三刑/相害；刑害低 priority）
- [x] B5 dong_bian_service（动静/暗动[旺相静爻+日冲]/冲起冲实冲散冲脱/独发独静/化进退/回头生克/化空破墓绝合冲扶泄）
- [x] B6 sheng_ke_service（生克泄耗扶拱制化/贪生忘克/贪合忘生忘克/连续相生克）
- [x] B7 gua_change_service（伏吟/反吟/六合六冲卦/游魂归魂/卦变六合六冲；复用 GuaCalculator 已有判定）
- [x] B8 fu_shen_relation_service（飞伏生克/伏神得出/受制；基于既有 FuShenService）
- [x] B9 liu_qin_deduce_service（原/忌/仇/闲神推导、用神两现、伏神取用）
- [x] B10 special_service（日月入爻/合爻/冲爻、太岁入爻、三合成局、动爻生克用神、变爻反作用本爻）
- [x] B11 ying_qi_service（出空/填实/冲墓/冲开/值日/合日/冲动 → YingQiCandidate 列表）
- [x] B12 liuyao_analyzer 编排器 + 集成测试（≥3 个经典完整卦例端到端验证）

### Phase C — 模型扩展与状态层
- [x] C1 `LiuYaoResult` + `int? yongShenPosition` + `bool yongShenIsFuShen`（默认 false）→ build_runner → 全量测试回归（旧 JSON 兼容测试）
- [x] C2 `LiuYaoAnalysisController` + 单测（mocktail mock repository：选用神→updateRecord 调用→重算→notify）
- [x] C3 `LiuYaoResultScreen` 包 ChangeNotifierProvider 注入

### Phase D — 第二层 UI（徽标 + Sheet + 点选）
- [x] D1 `LiuYaoTableWidget` 加可空参数 `yaoTags` / `onYaoTap`（不传=现状，验证大六壬侧零影响）
- [x] D2 爻行内联徽标（top 2~3，三色语义）+ widget test
- [x] D3 `YaoDetailSheet`（分类分组 + 设为用神按钮）+ widget test
- [x] D4 六亲点选菜单（设为/取消用神）

### Phase E — 第一、三层 UI
- [x] E1 `models/term_glossary.dart` 词条数据（~80 条：定义/成立条件/吉凶含义）
- [x] E2 `TermGlossaryDialog` + 术语点击接线
- [x] E3 `AnalysisOverviewCard`（引导态/用神链/结论/应期入口）+ widget test

### Phase F — 应期与日历
- [x] F1 `YingQiCard` 接入结果页
- [x] F2 `GuaCalendarContext` + 路由 arguments 传递
- [x] F3 日历月视图角标（应>冲>合>空，单角标）+ 退出应期模式
- [x] F4 日详情「与本卦」区块
- [x] F5 无卦上下文回归验证（日历现状不变）

### Phase G — AI 联动
- [x] G1 PromptAssembler 注入 `{{analysis_report}}`（旧模板无变量则跳过）
- [x] G2 未选用神时"请建议用神"指令

### 收尾
- [x] 全量 `flutter analyze` + `flutter test`（283 旧测试 + 新增全部通过）
- [x] 模拟器手工验收 AC2~AC6（起卦→选用神→详析→应期日历→AI）
- [x] Conventional Commits 分阶段提交（feat(liuyao-analysis): …）

## 验证命令

```bash
flutter analyze
flutter test                                    # 全量
flutter test test/domain/services/liuyao/       # 引擎单测
dart run build_runner build --delete-conflicting-outputs  # C1/A3 后
flutter run -d emulator-5554                    # 手工验收（用户预开模拟器）
```

## 风险文件与回滚点

| 文件 | 风险 | 回滚 |
|-----|------|-----|
| `lib/divination_systems/liuyao/liuyao_result.dart`（+codegen） | freezed 字段变更影响序列化 | 字段可空，git revert 单提交即可 |
| `lib/presentation/widgets/liuyao_table_widget.dart` | 本卦/变卦双侧共用 | 新参数全可空，不传=现状 |
| `lib/presentation/screens/calendar/calendar_screen.dart` | 通用黄历回归 | context null 分支=现状，F5 兜底 |
| `lib/ai/service/prompt_assembler.dart` | 提示词结构变化 | 变量缺失即跳过注入 |

每个 Phase 独立可提交、可回退；Phase A/B 纯新增零风险，先行合入。

## 开工前检查

- [x] `git status` 干净（当前有 2 张未跟踪截图 docs/*.png，与本任务无关，不纳入提交）
- [x] `flutter test` 基线绿（283）
- [x] 用户已批准最终规划摘要 → `task.py start`
