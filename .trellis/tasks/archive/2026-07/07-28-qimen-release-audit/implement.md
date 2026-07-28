# 奇门发布纠偏与最终验收执行计划

## 1. 冻结审计事实

- [x] 1.1 记录 `a83647e`、`8bbe6e4`、`4016ffc`、`8138c6e` 时间线和 18 个
  analysis slice 路径，验证 Qimen 在 a836 时禁用、未注册、无 tag/远端发布。
- [x] 1.2 机械验证最终 fixture SHA-256、123 项聚焦分析测试及来源审计内容；
  不重新裁定已确认正确的公式。
- [x] 1.3 更新 analysis spec，固定首次 enabled v1 基线与后续版本不可变门槛。

## 2. 补齐输入与状态机证据

- [x] 2.1 添加真太阳时 `-180/180` 合法 payload 和茅山法提交回归。
- [x] 2.2 添加日期、时间 picker 选择后实际 castTime 回归；仅在必要时增加
  `initialCastTime` 可测试性入口。
- [x] 2.3 添加 manual 未知 solarTerm/dun/yuan 与 juNumber `0/10` 的独立拒绝测试。
- [x] 2.4 分别添加 cast 阻塞、save 阻塞时 screen 卸载不导航/不 snackbar，及
  saving 期间重复点击只保存一次的 widget 回归。
- [x] 2.5 添加首页真实奇门卡片点击经 registry 进入起局页回归。
- [x] 2.6 添加无唯一焦点诊断和规则版本选择边界的结果页回归；只有 v1 时不伪造
  不存在的 released 版本。

## 3. 完整验收映射

- [x] 3.1 逐项映射产品 PRD A1..A14；复用已有九宫响应式/详情/诊断、仓储、
  数据管理、AI、资源测试，禁止为了数字复制断言。
- [x] 3.2 运行 `DivinationType`、评分术语和 Qimen UI/formatter 排盘 service
  导入审计；任何真实命中必须修复。
- [x] 3.3 按子代理递归保护直接执行 `trellis-check`，完成父子合同复核并修复发现。

## 4. 证据与发布门

- [x] 4.1 修正归档产品 PRD A1/implement 1.3，追加本任务、混合提交 provenance、
  最终 fixture 与测试证据，不改写历史。
- [x] 4.2 运行格式、聚焦测试、全部奇门测试、`flutter analyze`、全量测试、
  `git diff --check` 和 child/parent Trellis validate。
- [x] 4.3 只暂存纠偏白名单，提交并归档本任务；复核 staged 路径不含 Daliuren/tmp。
- [ ] 4.4 回到父任务，只有全部证据成立后勾选、提交、归档并记录 journal。

## Validation Commands

```powershell
dart format --output=none --set-exit-if-changed <owned dart test/source paths>
flutter test test/unit/divination_systems/qimen/qimen_system_test.dart
flutter test test/unit/divination_systems/qimen/qimen_viewmodel_test.dart
flutter test test/widget/qimen/qimen_cast_screen_test.dart
flutter test test/widget/qimen test/unit/services/qimen test/unit/divination_systems/qimen
flutter analyze --no-pub
flutter test
python ./.trellis/scripts/task.py validate 07-28-qimen-release-audit
python ./.trellis/scripts/task.py validate 07-28-qimen-module
git diff --check
```

## Staging Guard

允许路径以实际修改为准，预期只包含本任务 Trellis 文件、Qimen spec、归档 Qimen
产品任务证据、Qimen tests，以及补测确有需要时的最小 Qimen UI source。禁止包含：

```text
.trellis/tasks/07-28-daliuren-*/
lib/**/daliuren/**
test/**/daliuren/**
tmp/**
```
