# 大六壬仿古风 UI 重设计 + 起课方式扩展

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将大六壬起课/结果页面重设计为红金仿古风格，新增报数起课和随机起课两种方式，统一为单页多方式切换模式（类似六爻的 UnifiedCastScreen）。

**Architecture:** 大六壬起课页面合并为一个统一页面 `DaLiuRenCastScreen`，通过下拉选择四种起课方式（正时起课/报数起课/指定干支/随机起课）。UI 采用红金色调仿古风，与主页风格一致。结果页保持现有卡片结构但换用仿古配色。

**Tech Stack:** Flutter, Provider, lunar 包, 现有 AppColors 色彩体系（朱砂红 + 淡金 + 缃色）

---

## 文件结构

| 文件 | 操作 | 职责 |
|------|------|------|
| `lib/divination_systems/daliuren/daliuren_system.dart` | 修改 | 新增 reportNumber/computer 起课方式 |
| `lib/divination_systems/daliuren/viewmodels/daliuren_viewmodel.dart` | 修改 | 新增便捷方法 |
| `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart` | 重写 | 仿古风 UI，统一起课页 + 结果页重设计 |

---

### Task 1: DaLiuRenSystem 新增起课方式

**Files:**
- Modify: `lib/divination_systems/daliuren/daliuren_system.dart`
- Modify: `lib/divination_systems/daliuren/viewmodels/daliuren_viewmodel.dart`

- [ ] **Step 1: 更新 supportedMethods**

在 `daliuren_system.dart` 中将 `supportedMethods` 从 `[time, manual]` 扩展为 `[time, reportNumber, manual, computer]`。

- [ ] **Step 2: 添加 reportNumber 和 computer 的 cast switch 分支**

```dart
case CastMethod.reportNumber:
  // 报数：用户输入数字，除12取余映射地支作为占时
  final number = input['number'] as int;
  final shiZhiIndex = ((number.abs() - 1) % 12);
  final diZhi = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
  final shiZhi = diZhi[shiZhiIndex];
  // 其余参数从当前时间推算
  return _castByTime(time, {'shiZhiOverride': shiZhi});

case CastMethod.computer:
  // 随机：系统随机生成地支
  final random = Random();
  final diZhi = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
  final shiZhi = diZhi[random.nextInt(12)];
  return _castByTime(time, {'shiZhiOverride': shiZhi});
```

注意：需要修改 `_castByTime` 支持 `shiZhiOverride` 参数覆盖时支。

- [ ] **Step 3: 更新 validateInput**

```dart
case CastMethod.reportNumber:
  return input.containsKey('number') && input['number'] is int;
case CastMethod.computer:
  return true;
```

- [ ] **Step 4: ViewModel 新增便捷方法**

```dart
Future<void> castByReportNumber(int number, {DateTime? castTime}) async {
  await cast(method: CastMethod.reportNumber, input: {'number': number}, castTime: castTime);
}
Future<void> castByComputer({DateTime? castTime}) async {
  await cast(method: CastMethod.computer, input: {}, castTime: castTime);
}
```

- [ ] **Step 5: 运行分析确认无错误**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 6: 提交**

```bash
git add lib/divination_systems/daliuren/daliuren_system.dart lib/divination_systems/daliuren/viewmodels/daliuren_viewmodel.dart
git commit -m "feat(daliuren): 新增报数起课和随机起课方式"
```

---

### Task 2: 统一起课页面（仿古风）

**Files:**
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

将原来的 `_DaLiuRenTimeCastScreen` 和 `_DaLiuRenManualCastScreen` 合并为一个统一的 `_DaLiuRenCastScreen`，采用仿古风设计。

设计规范：
- **背景**：缃色渐变 `F7F7F5 → F0EDE8`（与六爻一致）
- **装饰**：金色同心圆罗盘背景（复用 CompassBackground）
- **主色**：朱砂红 `C94A4A` 用于按钮和强调
- **辅色**：淡金 `D4B896` 用于边框和分割线
- **文字**：玄色 `2C2C2C` 主文字，`8B7355` 标签文字
- **卡片**：半透明白底 `white.withOpacity(0.6)` + 淡金边框
- **起课按钮**：朱砂红渐变，与六爻的金色按钮区分

- [ ] **Step 1: 实现统一起课页面框架**

页面结构：
```
Scaffold
  AppBar: "大六壬起课"
  body: Stack
    ├─ 缃色渐变背景
    ├─ CompassBackground 罗盘装饰
    └─ SafeArea > SingleChildScrollView
        ├─ 占问事项输入
        ├─ 起课方式下拉选择（正时/报数/指定干支/随机）
        ├─ Divider（淡金色）
        └─ 动态起课区域（根据选择切换）
```

四种起课区域：
1. **正时起课**：显示当前干支时间 + 朱砂红起课按钮
2. **报数起课**：数字输入框 + 起课按钮
3. **指定干支**：日干/日支/时支/月建下拉 + 起课按钮
4. **随机起课**：骰子图标 + 描述 + 起课按钮

- [ ] **Step 2: 实现各起课区域组件**

每个区域独立 Widget，统一风格：
- 输入框用半透明白底 + 淡金边框
- 下拉框统一样式
- 起课按钮统一用朱砂红渐变

- [ ] **Step 3: 更新 UIFactory.buildCastScreen**

```dart
@override
Widget buildCastScreen(CastMethod method) {
  return const _DaLiuRenCastScreen();  // 统一页面
}
```

- [ ] **Step 4: 运行分析确认无错误**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 5: 提交**

```bash
git commit -m "feat(daliuren): 统一起课页面，仿古风 UI"
```

---

### Task 3: 结果页面仿古风重设计

**Files:**
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

重设计 `_DaLiuRenResultScreen`，从 Material 白卡片风格改为仿古风。

设计规范：
- **背景**：同起课页缃色渐变
- **卡片**：用淡金边框 + 半透明底替代 Material Card
- **标题**：朱砂红文字 + 淡金色 Divider
- **课体名称**：大字居中，朱砂红
- **四课**：用传统格子布局，金色边框
- **三传**：横向三圆，朱砂红渐变底色
- **神将**：标签式布局，吉绿凶红
- **AI 分析**：保持现有组件

- [ ] **Step 1: 重写结果页 Scaffold 和背景**

```dart
Scaffold(
  appBar: AppBar(title: Text('排盘结果'), backgroundColor: Color(0xFFF7F7F5)),
  body: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFF7F7F5), Color(0xFFF0EDE8)],
      ),
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(children: [...]),
    ),
  ),
)
```

- [ ] **Step 2: 重设计基本信息卡片**

精简为两行（类似六爻的 ExtendedInfoSection）：
- 时间：阳历 + 农历
- 干支：年月日时 + 空亡 + 月将

- [ ] **Step 3: 重设计四课卡片**

传统风格的 2×2 格子布局：
```
┌───────┬───────┐
│ 四课  │ 三课  │
│ 上神  │ 上神  │
│ 下神  │ 下神  │
├───────┼───────┤
│ 二课  │ 一课  │
│ 上神  │ 上神  │
│ 下神  │ 下神  │
└───────┴───────┘
```
金色边框，有克的课用朱砂红高亮。

- [ ] **Step 4: 重设计三传卡片**

横排三个圆：朱砂红渐变底色 + 白色地支文字
下方标注六亲关系

- [ ] **Step 5: 保持神将和神煞卡片，换用仿古配色**

- [ ] **Step 6: 运行分析确认无错误**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 7: 提交**

```bash
git commit -m "feat(daliuren): 结果页仿古风重设计"
```

---

### Task 4: 删除旧页面 + 最终验证

**Files:**
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

- [ ] **Step 1: 删除旧的 _DaLiuRenTimeCastScreen 和 _DaLiuRenManualCastScreen**

确认已被新的 `_DaLiuRenCastScreen` 完全替代后删除。

- [ ] **Step 2: 运行全部测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: 运行分析**

Run: `flutter analyze --no-fatal-infos`
Expected: No issues found

- [ ] **Step 4: 在模拟器上验证**

检查清单：
- [ ] 首页点击大六壬进入正确的起课页面
- [ ] 四种起课方式可切换
- [ ] 正时起课功能正常
- [ ] 报数起课功能正常
- [ ] 指定干支起课功能正常
- [ ] 随机起课功能正常
- [ ] 结果页面仿古风格正确显示
- [ ] 四课/三传/神将/神煞信息完整

- [ ] **Step 5: 提交**

```bash
git commit -m "refactor(daliuren): 清理旧页面，完成仿古风重设计"
```
