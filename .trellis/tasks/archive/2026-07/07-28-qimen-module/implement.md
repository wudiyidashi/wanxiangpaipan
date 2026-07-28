# 奇门遁甲板块执行计划

## 实施顺序

- [x] 1. 启动并完成 `07-28-qimen-pan-engine`。
- [x] 1.1 冻结输入、结果与参数合同，先建立来源化黄金测试。
- [x] 1.2 实现时间归一化、三种定局法和分阶段转盘服务。
- [x] 1.3 完成 `QimenSystem`、JSON/仓储往返、系统级文档与 domain spec。
- [x] 1.4 运行目标测试、`flutter analyze` 与全量 `flutter test`，检查后提交并归档子任务。
- [x] 2. 启动并完成 `07-28-qimen-analysis-engine`；依赖步骤 1 的模型与黄金盘提交。
- [x] 2.1 建立事实规则表、问事焦点、裁决表与应期合同及逐规则测试。
- [x] 2.2 实现 analyzer，复用排盘黄金盘做集成测试，新增 analysis spec。
- [x] 2.3 运行质量门，检查后提交并归档子任务。
- [x] 3. 启动并完成 `07-28-qimen-product-integration`；依赖步骤 1、2 的提交。
- [x] 3.1 接入 enum、注册、Provider/ViewModel、首页、历史和数据管理。
- [x] 3.2 实现起局页、稳定九宫结果页、详情、分析与应期交互。
- [x] 3.3 创建并核验奇门卡片位图资源，接入独立系统色。
- [x] 3.4 实现 formatter、内置模板与 AI 降级路径。
- [x] 3.5 完成 widget/仓储/端到端测试，运行质量门，检查后提交并归档子任务。
- [x] 3.6 完成 `07-28-qimen-release-audit`，纠正首次启用 v1 provenance、
  补齐产品边界回归并重新映射 A1..A14。
- [x] 4. 父任务跨子任务集成复核。
- [x] 4.1 按 PRD 验收完整起局、保存、历史重开、本地分析、AI 和数据清理流程。
- [x] 4.2 搜索全部 `DivinationType` 穷举点与硬编码系统列表，确认无遗漏。
- [x] 4.3 运行代码生成、`flutter analyze`、全部奇门测试与全量 `flutter test`。
- [x] 4.4 更新父任务验收状态、发布说明与开发日志，归档父任务。

## 最终集成结果（2026-07-28）

- 排盘、分析、产品集成和发布纠偏四个子任务全部归档，父任务进度为 4/4。
- 纠偏后的分析套件 124 项、全部奇门目标 202 项、全量测试 1,207 项通过；
  `flutter analyze --no-pub` 无问题，代码生成成功。
- 评分术语与 Qimen UI/formatter 排盘 service 导入搜索零命中；fixture 与发布基线
  hash、入口状态机、历史/数据管理和 AI 降级证据统一记录在归档纠偏任务中。

## 固定验证命令

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/unit/services/qimen test/unit/divination_systems/qimen
flutter test test/widget/qimen test/presentation
flutter test
python ./.trellis/scripts/task.py validate <active-child-task>
```

实际测试目录若在子任务设计中调整，必须同步更新对应 `implement.md`，不能用不存在的路径代替验证。

## 评审门

- 排盘门：三种定局、时间边界、两种寄宫/暗干与 JSON 深比较全部通过。
- 分析门：每条规则与决策表每行有独立命中测试，来源字段非空，无数值评分。
- 产品门：九宫在窄屏/大字体无溢出，历史重开一致，AI 未配置时无异常。
- 最终门：全量测试通过且系统级文档、domain specs、README/release notes 与代码一致。

## 回滚点

- 每个子任务形成独立提交；下一子任务只依赖已通过质量门的提交。
- 若规则黄金盘暴露口径错误，回到排盘设计与 spec 修正，不在 UI 或分析层补丁式兼容。
- 若产品集成需要临时停用，撤销注册与入口，保留纯领域实现；不得发布半启用系统。
