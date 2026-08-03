# 当前状态与真实案例审计

## 历法复现

- `2026-07-31 08:00`：丙午年、乙未月、丙午日、壬辰时，月建未，空亡寅卯。
- `2026-02-28 08:00`：丙午年、庚寅月、癸酉日、丙辰时，月建寅，空亡戌亥。
- 用户给出的四柱精确对应第二个时间。时间错配可由卦名卦阳历 UI 未传 `_solarTime`、父页使用 `DateTime.now()` 形成。

## 投影复现

- 爻数 `[8,8,6,7,8,6]` 由生产 `GuaCalculator` 生成雷地豫之火山旅。
- unselected：`verdict=null`，但 auxiliary 同时含 `六合卦/ji/主成、主缓` 和 `卦变六合/ji/渐入佳境而成`，无 `decisionEligible=false`。
- main-1（初爻妻财未土）：月克、死；上爻另一妻财发动拱扶；三爻兄弟卯木发动克用的 occurrence 被 current v2 因卯化申回头克而整体 suppressed；裁决为 `buMing/扶抑并见`，无法表达阶段结果。
- main-6（上爻妻财戌土）：旬空同时为假空、回头生、化绝、卯戌合绊且酉日已冲开；裁决为 `daiTiaoJian/待解除后再断`。机械规则依据“动不为空”，不能把该财直接当作不存在。
- hidden-1：初爻伏神为父母子水；因素为日生、飞克伏、休，条件为 `hidden.no-release-while-suppressed` 且 `hasRescue=false`，应期为空；现行 verdict 却是 `daiTiaoJian/先难后成`。

## 用户复盘新增口径

- 主评测用神改为初爻妻财未土；伏神父母作为合同/产权/身份文书的次级观察轴，不再用它的单轴 verdict 代替整件租房事件。
- 期待综合裁决为“事必成，成而受困；合非吉兆，是套”。这里“成”只指交易/入住形成，不代表费用合理、出租权有效或租期可持续。
- 六合不是固定吉，也不是无意义中性项：其稳定语义为黏合、合住、牵绊和持续；可参与 formation/persistence 阶段，不得单独决定 outcome quality。
- current 把回头克作为即时 availability blocker，抹掉三爻兄弟在前段对世财的作用；需要 v3 阶段化表达“先作用、后受制”。
- current projection 没有稳定输出所有爻的完整状态事实，因此上财动空/化绝、应爻入动墓、六神等容易在送模前丢失或只能依赖自由文本。
- 六神、卦名和具体事件映射属于低权限解释；二房东、黑中介、跑路月份和金额是 judge-only 已知结果，不得进入 generation。

## 权限遗漏

- 上一版 design 已规定 auxiliary evidence 固定 `decisionEligible=false`，当前 `_tagToJson` 未实现。
- catalog 对 auxiliary stage 已统一 `decisionCapable=false`；VerdictService 不接收 guaTags。六合造成的成功结论只能来自模型越权。
- `liuYaoQuestionPrompt` 只注册、未装配，修改它不会影响生产请求。

## 评测与安全

- v1.6.0 后生产提示词没有新改动；`canonical-v2-r6` 只证明旧候选的局部 calibration，不是本轮生产优化。
- 当前正式 evaluator 90 秒固定 timeout 小于本地模型已观测的 115-198 秒 judge 延迟；judge response schema 也存在回显描述字段的歧义。
- 真实模型只从 ignored `eval.local.json` 或环境变量读取；不读取 `key.txt`，不使用 MuMu。
