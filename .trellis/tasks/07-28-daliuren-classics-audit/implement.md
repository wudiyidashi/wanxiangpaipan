# 实施计划：大六壬完整性与古籍对照审校

## 总体规则

- 父任务只管理总需求、任务依赖和最终验收，不直接作为实现目标启动。
- 按下列阶段依次启动并完成子任务；存在依赖的子任务不得提前修改依赖方尚未稳定的契约。
- 每个子任务开始前必须具备自己的 `prd.md`、`design.md`、`implement.md` 以及已配置的 `implement.jsonl` / `check.jsonl`。
- 所有古籍引文在进入实现前回到影印页核验；OCR 和现代转载只能定位。
- 每完成一个子任务立即运行其定向质量门槛并更新父任务能力矩阵，不能把所有验证推迟到最后。

## Phase 1：证据与契约

### 1.1 古籍证据库与外部课例

- [ ] 完成 `07-28-daliuren-classics-evidence`。
- [ ] 固定馆藏版本、卷册/影印页定位和证据等级。
- [ ] 建立 source/rule/fixture schema、校验器和生成同步检查。
- [ ] 为核心排盘、神煞、九宗门、64 课经、100 毕法、类神、本命行年、断课和应期建立能力清单。
- [ ] 将《大六壬断案》《六壬存验》的可复算外部课例登记为独立预期值。

Gate：没有影印页定位或不满 B 级的条目不得以“古籍规则”进入后续实现。

### 1.2 规则来源与版本契约（C01）

- [ ] 完成路线分组 `07-28-daliuren-rule-contract-history` 下的 C01 `daliuren-rule-provenance`；该分组在 C15 完成前保持未完成。
- [ ] 引入稳定 ruleId、证据/来源、冲突和规则命中模型。
- [ ] 引入盘面版本、证据目录版本、规范化起课输入快照及来源记录关联。
- [ ] 旧 JSON 缺版本字段可读取并识别为 `legacyUnknown`；具体 UI/重排流程留给 C15/C16。

Gate：后续所有新规则必须使用稳定契约，不能继续增加中文字符串执行键。

## Phase 2：基础盘事实

### 2.1 起课、月将、天盘四课与十二天将（C02-C04）

- [ ] 完成 C02 `daliuren-cast-yuejiang`：中气精确交节、时区、手动默认、四柱模式和 replay 输入。
- [ ] 完成 C03 `daliuren-pan-sike-contracts`：天盘十二支双射、四课不变量、非法/缺失输入显式失败。
- [ ] 完成 C04 `daliuren-shenjiang-coordinates`：拆分昼夜选贵、落宫、实际顺逆及天/地盘两张神将映射。
- [ ] 覆盖月将秒级边界及昼/夜贵分别落顺区/逆区四类完整盘。
- [ ] C02-C04 全部验收后，完成路线分组 `07-28-daliuren-pan-foundation`。

### 2.2 九宗门完整分支（C05）

- [ ] 完成 C05 `daliuren-jiuzongmen-cases`。
- [ ] 以外部古例补足九宗门阴阳、多候选、多级决胜和反吟无克六日。
- [ ] 保留内部合成例作为穷举边界，但不再称其为独立古籍黄金例。

### 2.3 神煞、三传派生与本命行年（C06-C08）

- [ ] 完成 C06 `07-28-daliuren-shensha-system`：有类型位置/起例和核定底本的有限完整神煞。
- [ ] 完成 C07 `daliuren-chuan-derived-facts`：三传遁干、旺相休囚死及对日干完整关系。
- [ ] 完成 C08 `daliuren-benming-xingnian`：足量人物输入、本命、行年、unknown 降级和旧 JSON 兼容。
- [ ] C05/C07 完成后关闭路线分组 `07-28-daliuren-sanchuan-enrichment`；C08 需等 C12 后再关闭其路线分组。

Gate：基础盘、神煞和三传事实层稳定后，才允许课经、毕法和断课依赖其字段。

## Phase 3：经典知识体系

### 3.0 分析规则契约 v2（C09）

- [ ] 完成 C09 `daliuren-analysis-contract-v2`，将现有中文执行键改为 typed IDs。
- [ ] 修正六合与克身并见、first-match 压制强反证、标签排序和“无解/填实”矛盾。
- [ ] 事实、项目 v1 启发式和后续传统规则可机器区分，报告成为 UI/AI 的单一真相。

Gate：C09 未完成时，C10-C12 不得把新经典命中接入综合裁决。

### 3.1 六十四课经

- [ ] 完成 `07-28-daliuren-kejing`。
- [ ] 目录恰好 64 条；逐条包含命中条件、出处、异文、解释和 fixture。
- [ ] 输出结构化命中，不将课经长文直接作为执行逻辑。

### 3.2 毕法赋百法

- [ ] 完成 `07-28-daliuren-bifa`。
- [ ] 目录恰好 100 条；逐条包含条件、优先级、互斥/组合、出处和 fixture。
- [ ] 同盘多法命中顺序稳定，冲突有显式裁决记录。

### 3.3 占类与类神（C12）

- [ ] 完成 C12 `daliuren-class-spirit`。
- [ ] 以结构化占类选项解析类神；没有占类时明确不计算。
- [ ] 自动建议可解释、可覆盖；相同盘切换占类只改变分析上下文。
- [ ] C08 与 C12 均通过后关闭 `07-28-daliuren-leishen-mingnian` 路线分组。

Gate：64/100 数量、引用和逐条测试不完整时，经典体系阶段不能通过。

## Phase 4：断课与跨层集成

### 4.1 传统断课与应期（C13-C14）

- [ ] 完成 C13 `daliuren-traditional-judgment`。
- [ ] 以《指南》规则、课经/毕法/类神和本命行年命中重建分析输入。
- [ ] 修正“六合覆盖克身”、决策表首行吞掉反证等冲突。
- [ ] 完成 C14 `daliuren-timing-calendar`：传统应期尺度、实际日期窗口、去重排序和日历入口。
- [ ] “初末俱空”裁决与填实应期保持单一一致语义，应期不得单独翻转 verdict。

### 4.2 历史盘、UI、AI 与最终接入（C15-C16）

- [ ] 完成 C15 `daliuren-legacy-recast`：旧盘警示、重排资格、关联新记录且原记录不可变。
- [ ] 完成 C16 `07-28-daliuren-crosslayer-integration`。
- [ ] 锁定月建/月将 coreData 精确 schema，并输出完整神煞、版本、证据和冲突。
- [ ] UI、AI 文本、AI coreData 和领域报告对同一事实完全一致。
- [ ] 结果页覆盖旧盘警示、重排入口、经典命中和证据详情的窄屏/长文本状态。
- [ ] 更新 `docs/architecture/divination-systems/daliuren.md` 及用户侧能力说明。
- [ ] 输出最终完善度报告，逐项标记已验证、已修复、未实现、争议/停用。
- [ ] C09/C13/C14 完成后关闭 `07-28-daliuren-judgment-yingqi` 路线分组；C01/C15 完成后关闭规则/历史分组。

## Phase 5：父级最终验收

- [ ] 确认 C00-C16 共 17 个实施单元和 10 个路线分组均已完成并归档，父任务能力矩阵无未归属条目。
- [ ] 复核所有 A/B 级引文可以回到固定影印页，所有 C/D 级条目未被标成古籍事实。
- [ ] 运行生成器/目录校验，确认 64 课经、100 毕法、ruleId、sourceRef 和 fixture 完整。
- [ ] 运行大六壬全链定向测试，包含服务、系统、repository、formatter 和 widget。
- [ ] 运行全量静态检查和测试，确认其他术数模块无回归。
- [ ] 按 `trellis-update-spec` 更新大六壬 domain/frontend 规范，再进入提交与归档流程。

## 验证命令

具体生成命令由证据库子任务锁定；父级最低门槛为：

```powershell
dart run tool/daliuren_classics/validate.dart
flutter analyze
flutter test test/unit/services/daliuren
flutter test test/unit/divination_systems/daliuren
flutter test test/unit/ai/output/formatters/daliuren_formatter_test.dart
flutter test test/widget/daliuren
flutter test
```

如果最终文件路径与现状不同，子任务应更新本命令清单，不能静默跳过不存在的测试目录。

## 回滚点

- 证据目录/schema、版本契约、基础盘、各经典能力和跨层集成分别独立提交。
- 算法变更失败时优先回滚对应子任务提交，保留已经验证的证据目录和版本框架。
- 不执行历史记录原地批量迁移；因此回滚不需要恢复被覆盖的旧盘。
- 任何 schema 变更必须在提交前验证旧数据库和旧 JSON，失败则停止后续子任务。
