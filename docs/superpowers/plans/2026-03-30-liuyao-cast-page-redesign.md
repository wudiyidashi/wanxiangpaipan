# 六爻起卦页合并重设计 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将六爻起卦流程从 3 次跳转简化为 2 次，合并"方式选择"和"起卦操作"为一个新中式极简风格的统一页面。

**Architecture:** 新建 `UnifiedCastScreen` 替代原有的 3 个独立起卦页面 + 1 个方式选择页面。使用 DropdownButton 切换方式，SharedPreferences 记忆上次选择。视觉风格遵循新中式极简设计理念（宣纸纹理、黛蓝/朱红/哑金配色）。

**Tech Stack:** Flutter, Provider, SharedPreferences, existing LiuYaoViewModel

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `lib/presentation/screens/cast/unified_cast_screen.dart` | 合并起卦页面（问题输入 + 方式下拉 + 动态操作区） |
| Create | `lib/presentation/widgets/cast/coin_cast_section.dart` | 摇钱法操作区 widget（铜钱 + 起卦按钮） |
| Create | `lib/presentation/widgets/cast/time_cast_section.dart` | 时间起卦操作区 widget（农历显示 + 起卦按钮） |
| Create | `lib/presentation/widgets/cast/manual_cast_section.dart` | 手动输入操作区 widget（时间选择 + 六爻下拉 + 起卦按钮） |
| Create | `lib/presentation/widgets/cast/yao_line_placeholder.dart` | 水墨风爻线占位符 widget |
| Create | `lib/presentation/widgets/cast/cast_button.dart` | 朱红起卦按钮 widget（共享样式） |
| Create | `lib/presentation/widgets/cast/compass_background.dart` | 淡金罗盘同心圆背景装饰 widget |
| Modify | `lib/presentation/widgets/divination_system_card.dart:248-251` | 导航改为直接 push UnifiedCastScreen |
| Modify | `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart:27-44` | buildCastScreen 返回 UnifiedCastScreen |
| Modify | `lib/main.dart:12,143-147` | 移除 method_selector_screen import 和路由 |
| Modify | `pubspec.yaml` | 添加 shared_preferences 依赖 |
| Delete | `lib/presentation/screens/home/method_selector_screen.dart` | 不再需要 |
| Delete | `lib/presentation/screens/cast/coin_cast_screen.dart` | 被 UnifiedCastScreen 替代 |
| Delete | `lib/presentation/screens/cast/time_cast_screen.dart` | 被 UnifiedCastScreen 替代 |
| Delete | `lib/presentation/screens/cast/manual_cast_screen.dart` | 被 UnifiedCastScreen 替代 |
| Create | `test/presentation/screens/cast/unified_cast_screen_test.dart` | 合并页面的 widget 测试 |

---

### Task 1: 添加 shared_preferences 依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加依赖**

```bash
cd D:/SelfDeveloped/11.wanxiangpaipan && flutter pub add shared_preferences
```

- [ ] **Step 2: 验证安装**

```bash
flutter pub get
```

Expected: 成功，无错误

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: 添加 shared_preferences 依赖"
```

---

### Task 2: 创建共享 UI 组件（朱红按钮 + 罗盘背景 + 爻线占位符）

**Files:**
- Create: `lib/presentation/widgets/cast/cast_button.dart`
- Create: `lib/presentation/widgets/cast/compass_background.dart`
- Create: `lib/presentation/widgets/cast/yao_line_placeholder.dart`

- [ ] **Step 1: 创建朱红起卦按钮**

```dart
// lib/presentation/widgets/cast/cast_button.dart
import 'package:flutter/material.dart';

/// 朱红渐变起卦按钮
///
/// 新中式设计：朱红渐变 + 白色宋体文字 + 圆角24 + 投影
class CastButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const CastButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label = '起卦',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC84B31), Color(0xFFA63A24)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC84B31).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          isLoading ? '排盘中...' : label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建淡金罗盘背景**

```dart
// lib/presentation/widgets/cast/compass_background.dart
import 'package:flutter/material.dart';

/// 淡金罗盘同心圆背景装饰
///
/// 2-3 个同心圆，极淡的哑金色边框，居中定位。
/// 作为 Stack 的底层使用。
class CompassBackground extends StatelessWidget {
  const CompassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCircle(260, 0.15),
            _buildCircle(210, 0.10),
            _buildCircle(160, 0.07),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.fromRGBO(183, 148, 82, opacity),
          width: 1,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建水墨风爻线占位符**

```dart
// lib/presentation/widgets/cast/yao_line_placeholder.dart
import 'package:flutter/material.dart';

/// 水墨风爻线占位符
///
/// 6 条水墨渐隐风格线条，交替阳爻（实线）和阴爻（断线），
/// 暗示卦象生成位置。底部淡色标注"卦象"。
class YaoLinePlaceholder extends StatelessWidget {
  const YaoLinePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 6 条爻线（从下到上交替阴阳样式）
          ...List.generate(6, (index) {
            // 交替使用阳爻和阴爻样式
            final isYang = index.isEven;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: isYang ? _buildYangLine() : _buildYinLine(),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '卦象',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF8B7355).withOpacity(0.4),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 阳爻：完整渐隐线
  Widget _buildYangLine() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.withOpacity(0.12),
            Colors.grey.withOpacity(0.18),
            Colors.grey.withOpacity(0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  /// 阴爻：中间断开的渐隐线
  Widget _buildYinLine() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 验证编译**

```bash
flutter analyze lib/presentation/widgets/cast/
```

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/cast/
git commit -m "feat: 添加新中式起卦页共享 UI 组件（朱红按钮、罗盘背景、爻线占位符）"
```

---

### Task 3: 创建摇钱法操作区 widget

**Files:**
- Create: `lib/presentation/widgets/cast/coin_cast_section.dart`

- [ ] **Step 1: 创建摇钱法操作区**

```dart
// lib/presentation/widgets/cast/coin_cast_section.dart
import 'package:flutter/material.dart';
import 'cast_button.dart';
import 'yao_line_placeholder.dart';

/// 摇钱法操作区
///
/// 三枚铜钱视觉元素 + 起卦按钮 + 爻线占位符。
/// 点击按钮直接计算，无动画。
class CoinCastSection extends StatelessWidget {
  final VoidCallback? onCast;
  final bool isLoading;

  const CoinCastSection({
    super.key,
    this.onCast,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // 三枚铜钱
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCoin(-15),
            const SizedBox(width: 8),
            _buildCoin(10),
            const SizedBox(width: 8),
            _buildCoin(25),
          ],
        ),
        const SizedBox(height: 20),
        // 起卦按钮
        CastButton(onPressed: onCast, isLoading: isLoading),
        const SizedBox(height: 24),
        // 爻线占位符
        const YaoLinePlaceholder(),
      ],
    );
  }

  /// 构建单个铜钱
  Widget _buildCoin(double rotationDegrees) {
    return Transform.rotate(
      angle: rotationDegrees * 3.14159 / 180,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [Color(0xFFC9A84C), Color(0xFF8B6914)],
          ),
          border: Border.all(color: const Color(0xFFA08030), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '通寶',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF3D2B00),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
flutter analyze lib/presentation/widgets/cast/coin_cast_section.dart
```

Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/cast/coin_cast_section.dart
git commit -m "feat: 添加摇钱法操作区 widget"
```

---

### Task 4: 创建时间起卦操作区 widget

**Files:**
- Create: `lib/presentation/widgets/cast/time_cast_section.dart`

- [ ] **Step 1: 创建时间起卦操作区**

需要用到 `lunar` 包获取农历信息。先检查现有代码如何获取农历。

```dart
// lib/presentation/widgets/cast/time_cast_section.dart
import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'cast_button.dart';
import 'yao_line_placeholder.dart';

/// 时间起卦操作区
///
/// 显示当前时辰的农历干支信息 + 起卦按钮 + 爻线占位符。
class TimeCastSection extends StatelessWidget {
  final VoidCallback? onCast;
  final bool isLoading;

  const TimeCastSection({
    super.key,
    this.onCast,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);

    return Column(
      children: [
        const SizedBox(height: 20),
        // 当前时辰标签
        Text(
          '当前时辰',
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        // 农历干支（大字黛蓝）
        Text(
          '${lunar.getYearInGanZhi()}年 ${lunar.getMonthInGanZhi()}月 ${lunar.getDayInGanZhi()}日',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B4570),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        // 公历日期和时辰
        Text(
          '${now.year}年${now.month}月${now.day}日 ${lunar.getTimeZhi()}时',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFA0937E),
          ),
        ),
        const SizedBox(height: 20),
        // 起卦按钮
        CastButton(onPressed: onCast, isLoading: isLoading),
        const SizedBox(height: 24),
        // 爻线占位符
        const YaoLinePlaceholder(),
      ],
    );
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
flutter analyze lib/presentation/widgets/cast/time_cast_section.dart
```

Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/cast/time_cast_section.dart
git commit -m "feat: 添加时间起卦操作区 widget"
```

---

### Task 5: 创建手动输入操作区 widget

**Files:**
- Create: `lib/presentation/widgets/cast/manual_cast_section.dart`

- [ ] **Step 1: 创建手动输入操作区**

```dart
// lib/presentation/widgets/cast/manual_cast_section.dart
import 'package:flutter/material.dart';
import 'cast_button.dart';

/// 手动输入操作区
///
/// 起卦时间选择器 + 六爻下拉选择（单列从上到下）+ 起卦按钮。
class ManualCastSection extends StatefulWidget {
  final void Function(List<int> yaoNumbers, DateTime castTime)? onCast;
  final bool isLoading;

  const ManualCastSection({
    super.key,
    this.onCast,
    this.isLoading = false,
  });

  @override
  State<ManualCastSection> createState() => _ManualCastSectionState();
}

class _ManualCastSectionState extends State<ManualCastSection> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<int?> _yaoValues = List.filled(6, null);

  bool get _allYaosSelected => _yaoValues.every((v) => v != null);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _handleCast() {
    if (!_allYaosSelected || widget.isLoading) return;
    final castTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    widget.onCast?.call(_yaoValues.cast<int>(), castTime);
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 11,
      color: Color(0xFF8B7355),
      letterSpacing: 1,
    );
    const inputBorder = Color(0x4DB79452); // rgba(183,148,82,0.3)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 起卦时间
        const Text('起卦时间', style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    border: Border.all(color: inputBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2B4570)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  border: Border.all(color: inputBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2B4570)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 六爻输入
        const Text('六爻输入（初爻 → 六爻）', style: labelStyle),
        const SizedBox(height: 4),
        ...List.generate(6, (index) {
          final yaoName = switch (index) {
            0 => '初爻（一爻）',
            5 => '六爻（上爻）',
            _ => '${['初', '二', '三', '四', '五', '六'][index]}爻',
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: inputBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _yaoValues[index],
                  isExpanded: true,
                  hint: Text(yaoName, style: const TextStyle(fontSize: 13, color: Color(0xFF2B4570))),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB79452)),
                  items: const [
                    DropdownMenuItem(value: 6, child: Text('老阴 ⚋ (6)')),
                    DropdownMenuItem(value: 7, child: Text('少阳 ⚊ (7)')),
                    DropdownMenuItem(value: 8, child: Text('少阴 ⚋ (8)')),
                    DropdownMenuItem(value: 9, child: Text('老阳 ⚊ (9)')),
                  ],
                  onChanged: (value) {
                    setState(() => _yaoValues[index] = value);
                  },
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // 起卦按钮
        Center(
          child: CastButton(
            onPressed: _allYaosSelected ? _handleCast : null,
            isLoading: widget.isLoading,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
flutter analyze lib/presentation/widgets/cast/manual_cast_section.dart
```

Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/cast/manual_cast_section.dart
git commit -m "feat: 添加手动输入操作区 widget"
```

---

### Task 6: 创建 UnifiedCastScreen 主页面

**Files:**
- Create: `lib/presentation/screens/cast/unified_cast_screen.dart`

- [ ] **Step 1: 创建合并起卦页面**

```dart
// lib/presentation/screens/cast/unified_cast_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/divination_system.dart';
import '../../../divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../widgets/cast/compass_background.dart';
import '../../widgets/cast/coin_cast_section.dart';
import '../../widgets/cast/time_cast_section.dart';
import '../../widgets/cast/manual_cast_section.dart';

/// 统一起卦页面
///
/// 合并了方式选择和起卦操作，支持摇钱法、时间起卦、手动输入三种方式。
/// 新中式极简设计：宣纸纹理背景 + 淡金罗盘装饰 + 朱红起卦按钮。
class UnifiedCastScreen extends StatefulWidget {
  const UnifiedCastScreen({super.key});

  static const String _prefsKey = 'liuyao_last_cast_method';

  @override
  State<UnifiedCastScreen> createState() => _UnifiedCastScreenState();
}

class _UnifiedCastScreenState extends State<UnifiedCastScreen> {
  CastMethod _selectedMethod = CastMethod.coin;
  bool _isProcessing = false;
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final methodId = prefs.getString(UnifiedCastScreen._prefsKey);
    if (methodId != null && mounted) {
      try {
        setState(() {
          _selectedMethod = CastMethod.fromId(methodId);
        });
      } catch (_) {
        // 无效的 method ID，保持默认
      }
    }
  }

  Future<void> _saveLastMethod(CastMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(UnifiedCastScreen._prefsKey, method.id);
  }

  Future<void> _navigateToResult() async {
    final viewModel = context.read<LiuYaoViewModel>();

    if (viewModel.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage!)),
        );
      }
      return;
    }

    if (viewModel.hasResult && mounted) {
      final result = viewModel.result!;
      final uiRegistry = DivinationUIRegistry();
      final resultScreen = uiRegistry.buildResultScreen(result);
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => resultScreen),
      );
    }
  }

  Future<void> _castByCoin() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      final question = _questionController.text.trim();
      await viewModel.castByCoin();
      if (question.isNotEmpty && viewModel.hasResult) {
        await viewModel.saveRecord(question: question);
      }
      await _navigateToResult();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _castByTime() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      final question = _questionController.text.trim();
      await viewModel.castByTime(castTime: DateTime.now());
      if (question.isNotEmpty && viewModel.hasResult) {
        await viewModel.saveRecord(question: question);
      }
      await _navigateToResult();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _castByManual(List<int> yaoNumbers, DateTime castTime) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      final question = _questionController.text.trim();
      await viewModel.castByManualYaoNumbers(
        yaoNumbers,
        castTime: castTime,
        question: question.isEmpty ? null : question,
      );
      await _navigateToResult();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 只显示六爻支持的方式
    const supportedMethods = [CastMethod.coin, CastMethod.time, CastMethod.manual];

    return Scaffold(
      appBar: AppBar(title: const Text('六爻起卦')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7F7F5), Color(0xFFF0EDE8)],
          ),
        ),
        child: Stack(
          children: [
            // 罗盘背景装饰
            const Positioned.fill(child: CompassBackground()),
            // 主内容
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 占问事项输入
                  _buildLabel('占问事项'),
                  const SizedBox(height: 4),
                  _buildInput(
                    child: TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        hintText: '请输入您想占问的事项...',
                        hintStyle: TextStyle(color: Color(0xFFA0937E), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2B4570)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 起卦方式下拉
                  _buildLabel('起卦方式'),
                  const SizedBox(height: 4),
                  _buildInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CastMethod>(
                        value: _selectedMethod,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB79452)),
                        items: supportedMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(
                              method.displayName,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF2B4570)),
                            ),
                          );
                        }).toList(),
                        onChanged: (method) {
                          if (method != null) {
                            setState(() => _selectedMethod = method);
                            _saveLastMethod(method);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 哑金分隔线
                  Container(
                    height: 1,
                    color: const Color(0x40B79452), // rgba(183,148,82,0.25)
                  ),
                  const SizedBox(height: 8),

                  // 动态操作区
                  _buildCastSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF8B7355),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInput({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(color: const Color(0x4DB79452)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _buildCastSection() {
    return switch (_selectedMethod) {
      CastMethod.coin => CoinCastSection(
          onCast: _castByCoin,
          isLoading: _isProcessing,
        ),
      CastMethod.time => TimeCastSection(
          onCast: _castByTime,
          isLoading: _isProcessing,
        ),
      CastMethod.manual => ManualCastSection(
          onCast: _castByManual,
          isLoading: _isProcessing,
        ),
      _ => const Center(child: Text('不支持的起卦方式')),
    };
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
flutter analyze lib/presentation/screens/cast/unified_cast_screen.dart
```

Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/cast/unified_cast_screen.dart
git commit -m "feat: 创建统一起卦页面 UnifiedCastScreen"
```

---

### Task 7: 更新导航和路由，删除旧文件

**Files:**
- Modify: `lib/presentation/widgets/divination_system_card.dart:248-251`
- Modify: `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart:27-44`
- Modify: `lib/main.dart:12,143-147`
- Delete: `lib/presentation/screens/home/method_selector_screen.dart`
- Delete: `lib/presentation/screens/cast/coin_cast_screen.dart`
- Delete: `lib/presentation/screens/cast/time_cast_screen.dart`
- Delete: `lib/presentation/screens/cast/manual_cast_screen.dart`

- [ ] **Step 1: 修改 divination_system_card.dart 导航逻辑**

将 `_handleTap` 方法中的 `Navigator.pushNamed('/method-selector', ...)` 改为直接 push `UnifiedCastScreen`。

在文件顶部添加 import：
```dart
import '../../presentation/screens/cast/unified_cast_screen.dart';
```

将 `_handleTap` 方法中的导航代码替换：
```dart
// 旧代码：
Navigator.pushNamed(
  context,
  '/method-selector',
  arguments: widget.system.type,
);

// 新代码：
Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => const UnifiedCastScreen(),
  ),
);
```

- [ ] **Step 2: 修改 liuyao_ui_factory.dart 的 buildCastScreen**

将 `buildCastScreen` 方法简化为始终返回 `UnifiedCastScreen`。

替换 import 区块，移除旧的 cast screen imports，添加：
```dart
import '../../../presentation/screens/cast/unified_cast_screen.dart';
```

移除以下 import：
```dart
import '../../../presentation/screens/cast/coin_cast_screen.dart';
import '../../../presentation/screens/cast/time_cast_screen.dart';
import '../../../presentation/screens/cast/manual_cast_screen.dart';
```

替换 `buildCastScreen` 方法体：
```dart
@override
Widget buildCastScreen(CastMethod method) {
  // 统一使用合并后的起卦页面
  return const UnifiedCastScreen();
}
```

- [ ] **Step 3: 修改 main.dart 移除 method-selector 路由**

移除 import：
```dart
import 'presentation/screens/home/method_selector_screen.dart';
```

移除路由中的 `/method-selector` 条目：
```dart
// 删除这段：
'/method-selector': (context) {
  final systemType =
      ModalRoute.of(context)!.settings.arguments as DivinationType;
  return MethodSelectorScreen(systemType: systemType);
},
```

- [ ] **Step 4: 删除旧文件**

```bash
git rm lib/presentation/screens/home/method_selector_screen.dart
git rm lib/presentation/screens/cast/coin_cast_screen.dart
git rm lib/presentation/screens/cast/time_cast_screen.dart
git rm lib/presentation/screens/cast/manual_cast_screen.dart
```

- [ ] **Step 5: 验证编译和分析**

```bash
flutter analyze
```

Expected: No issues found (可能有一些不相关的 warning)

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: 切换到统一起卦页面，移除旧的方式选择页和独立起卦页"
```

---

### Task 8: 修复引用和清理

**Files:**
- 可能需要修改引用了旧文件的任何地方

- [ ] **Step 1: 搜索残留引用**

```bash
cd D:/SelfDeveloped/11.wanxiangpaipan && grep -r "method_selector_screen\|coin_cast_screen\|time_cast_screen\|manual_cast_screen\|MethodSelectorScreen\|CoinCastScreen\|TimeCastScreen\|ManualCastScreen" lib/ test/ --include="*.dart" -l
```

Expected: 无结果，或仅有 unified_cast_screen.dart 本身

- [ ] **Step 2: 修复任何残留引用**

如果发现引用，逐个修复。

- [ ] **Step 3: 完整编译测试**

```bash
flutter analyze && flutter test
```

Expected: analyze 无 issue，测试全部通过

- [ ] **Step 4: Commit（如有修复）**

```bash
git add -A
git commit -m "fix: 清理旧起卦页面的残留引用"
```

---

### Task 9: 添加 widget 测试

**Files:**
- Create: `test/presentation/screens/cast/unified_cast_screen_test.dart`

- [ ] **Step 1: 编写测试**

```dart
// test/presentation/screens/cast/unified_cast_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wanxiang_paipan/presentation/screens/cast/unified_cast_screen.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/liuyao_ui_factory.dart';

class MockDivinationRepository extends Mock implements DivinationRepository {}

void main() {
  late MockDivinationRepository mockRepo;

  setUp(() {
    mockRepo = MockDivinationRepository();
    // 确保注册表已初始化
    final registry = DivinationRegistry();
    if (!registry.hasSystem(DivinationType.liuYao)) {
      registry.register(LiuYaoSystem());
    }
    final uiRegistry = DivinationUIRegistry();
    if (!uiRegistry.hasFactory(DivinationType.liuYao)) {
      uiRegistry.register(LiuYaoUIFactory());
    }
  });

  Widget buildTestWidget() {
    return ChangeNotifierProvider(
      create: (_) => LiuYaoViewModel(repository: mockRepo),
      child: const MaterialApp(
        home: UnifiedCastScreen(),
      ),
    );
  }

  group('UnifiedCastScreen', () {
    testWidgets('显示占问事项输入框', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('占问事项'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('显示起卦方式下拉选择', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('起卦方式'), findsOneWidget);
      // 默认选中摇钱法
      expect(find.text('摇钱法'), findsOneWidget);
    });

    testWidgets('默认显示摇钱法操作区', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 应该看到起卦按钮
      expect(find.text('起卦'), findsOneWidget);
    });

    testWidgets('切换到时间起卦', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 打开下拉菜单
      await tester.tap(find.text('摇钱法'));
      await tester.pumpAndSettle();

      // 选择时间起卦
      await tester.tap(find.text('时间起卦').last);
      await tester.pumpAndSettle();

      // 应该看到当前时辰标签
      expect(find.text('当前时辰'), findsOneWidget);
    });

    testWidgets('切换到手动输入', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 打开下拉菜单
      await tester.tap(find.text('摇钱法'));
      await tester.pumpAndSettle();

      // 选择手动输入
      await tester.tap(find.text('手动输入').last);
      await tester.pumpAndSettle();

      // 应该看到起卦时间和六爻输入
      expect(find.text('起卦时间'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 运行测试**

```bash
flutter test test/presentation/screens/cast/unified_cast_screen_test.dart
```

Expected: 全部通过

- [ ] **Step 3: 运行全部测试确保无回归**

```bash
flutter test
```

Expected: 全部通过（旧的 cast screen 测试如果有应该已随文件删除）

- [ ] **Step 4: Commit**

```bash
git add test/presentation/screens/cast/unified_cast_screen_test.dart
git commit -m "test: 添加统一起卦页面 widget 测试"
```

---

### Task 10: 最终验证和端到端测试

- [ ] **Step 1: 完整分析和测试**

```bash
flutter analyze && flutter test
```

Expected: 无 issue，全部测试通过

- [ ] **Step 2: 手动启动验证（可选）**

```bash
flutter run -d windows
```

验证流程：
1. 主页点击"六爻纳甲"卡片 → 直接进入合并起卦页
2. 看到占问事项输入 + 起卦方式下拉 + 摇钱法操作区
3. 切换下拉到"时间起卦" → 操作区切换为农历时辰显示
4. 切换下拉到"手动输入" → 操作区切换为日期/时间选择 + 六爻下拉
5. 点击起卦 → 跳转到结果页
6. 退出再进入 → 记住上次选择的方式

- [ ] **Step 3: Commit（如有最终修复）**

```bash
git add -A
git commit -m "chore: 六爻起卦页合并重设计完成"
```
