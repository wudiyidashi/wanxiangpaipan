# 奇门甲日分析兼容与界面中文化实施计划

## 1. 红测与版本边界

- [x] 在 catalog 测试中锁定 current=v2、v1/v2 可解析且 released 不可变。
- [x] 在 focus/analyzer 测试中新增六个甲旬矩阵；先证明 current/v2 当前失败，同时保留
  显式 v1 的原诊断断言。
- [x] 新增同截图形态的结果页测试，证明修复前 `unavailableReason` 非空且内部 ID 可见。

## 2. v2 甲日焦点

- [x] 注册 v2 并把 current 指向 v2，不修改 v1 规则集合或黄金 fixture。
- [x] 让 analyzer 把 resolved rule-set version 传入 focus resolver。
- [x] 实现由 `dayGanZhi` 推导日旬首/遁仪的纯函数分支，复用 `_addStemFocus` 和显式
  hosted heaven stem 逻辑；补齐 input refs 与 trace。
- [x] 运行 catalog、focus、analyzer、graph/wire round-trip 聚焦测试。

## 3. 结果页中文化

- [x] 建立集中 presentation label helper，覆盖全部 role/rule/source/policy/trace/
  diagnostic/yingQi 映射与未知中文兜底。
- [x] 更新结果摘要、焦点事实、冲突、trace、来源、应期和分析版本显示。
- [x] 更新九宫详情的焦点、规则、事实、来源与优先级显示。
- [x] 对 UI 可见文本做稳定 ID 负向搜索与 widget 断言；保持 wire/formatter IDs 不变。

## 4. AI 闭环

- [x] formatter 测试覆盖 v2 甲日完整输出与程序唯一计算方策略。
- [x] 结果页用已配置 fake AI service 驱动“开始分析 -> service 调用 -> 响应渲染”。
- [x] 回归显式 v1 甲日、损坏盘、未来 schema 和未配置 provider 的受控禁用状态。

## 5. 质量门与交付

- [x] 更新 qimen analysis/frontend specs，记录 v2 焦点合同与用户界面不得泄漏内部 ID。
- [x] 对本任务 Dart 文件运行 `dart format` 与 `git diff --check`。
- [x] 运行 focus/analyzer/formatter/result widget 聚焦测试、全部 Qimen 目标、
  `flutter analyze --no-pub`；共享大六壬若阻塞全量门禁，使用隔离 worktree。
- [x] 派发 `trellis-check` 独立复核数据流、v1 不可变、AI 真调用和中文化覆盖。
- [x] 显式白名单提交本任务文件，确认没有大六壬、README、资源或 `tmp/` 路径。

## Risky Files / Rollback Points

- `qimen_rule_catalog.dart`：current 切换必须与 analyzer/focus 测试同批提交。
- `qimen_focus_resolver.dart`：任何 v1 行为变化均阻断交付。
- `qimen_result_sections.dart` / `qimen_palace_detail_sheet.dart`：中文化不得改变事实选择、
  裁决或 AI payload。
- AI widget 只允许通过合法 projection 解锁，不得删除现有 compatibility gate。
