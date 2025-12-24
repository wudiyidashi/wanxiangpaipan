# UI 工厂使用指南

**版本**: 1.0
**创建日期**: 2025-01-15
**最后更新**: 2025-01-15
**状态**: 已完成

---

## 概述

本文档描述了如何使用 `DivinationUIFactory` 和 `DivinationUIRegistry` 来实现动态 UI 构建，支持多术数系统的可插拔 UI 架构。

## 核心概念

### DivinationUIFactory（UI 工厂接口）

每个术数系统必须实现 `DivinationUIFactory` 接口，提供三个核心方法：

1. **buildCastScreen(method)**: 构建起卦页面
2. **buildResultScreen(result)**: 构建结果详情页面
3. **buildHistoryCard(result)**: 构建历史记录卡片

### DivinationUIRegistry（UI 工厂注册表）

单例模式的注册表，管理所有已注册的 UI 工厂，提供动态 UI 构建能力。

## 快速开始

### 1. 实现 UI 工厂

```dart
// lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart

import 'package:flutter/material.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../liuyao_result.dart';
import 'screens/coin_cast_screen.dart';
import 'screens/time_cast_screen.dart';
import 'screens/manual_cast_screen.dart';
import 'screens/result_screen.dart';
import 'widgets/history_card.dart';

class LiuYaoUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  Widget buildCastScreen(CastMethod method) {
    switch (method) {
      case CastMethod.coin:
        return const LiuYaoCoinCastScreen();
      case CastMethod.time:
        return const LiuYaoTimeCastScreen();
      case CastMethod.manual:
        return const LiuYaoManualCastScreen();
      default:
        throw UnsupportedError('六爻不支持的起卦方式: ${method.displayName}');
    }
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型不匹配，期望 LiuYaoResult');
    }
    return LiuYaoResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) {
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型不匹配，期望 LiuYaoResult');
    }
    return LiuYaoHistoryCard(result: result);
  }

  @override
  Widget? buildSystemCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.blue),
        title: const Text('六爻占卜'),
        subtitle: const Text('传统六爻排盘，使用摇钱法、时间起卦或手动输入'),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }

  @override
  IconData? getSystemIcon() => Icons.auto_awesome;

  @override
  Color? getSystemColor() => Colors.blue;
}
```

### 2. 注册 UI 工厂

在 `main.dart` 中注册所有 UI 工厂：

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'domain/divination_registry.dart';
import 'presentation/divination_ui_registry.dart';
import 'divination_systems/liuyao/liuyao_system.dart';
import 'divination_systems/liuyao/ui/liuyao_ui_factory.dart';

void main() {
  // 注册 Domain 层系统
  final systemRegistry = DivinationRegistry();
  systemRegistry.register(LiuYaoSystem());

  // 注册 UI 层工厂
  final uiRegistry = DivinationUIRegistry();
  uiRegistry.registerUI(LiuYaoUIFactory());

  runApp(const MyApp());
}
```

### 3. 使用 UI 工厂构建页面

#### 方式一：直接使用工厂

```dart
// 在任何需要构建页面的地方

class SystemSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择术数系统')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('六爻占卜'),
            subtitle: const Text('摇钱法'),
            onTap: () {
              // 获取 UI 工厂
              final uiFactory = DivinationUIRegistry()
                  .getUIFactory(DivinationType.liuYao);

              // 构建起卦页面
              final castScreen = uiFactory.buildCastScreen(CastMethod.coin);

              // 导航到起卦页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => castScreen),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

#### 方式二：使用注册表便捷方法

```dart
class SystemSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uiRegistry = DivinationUIRegistry();

    return Scaffold(
      appBar: AppBar(title: const Text('选择术数系统')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('六爻占卜'),
            subtitle: const Text('摇钱法'),
            onTap: () {
              // 使用便捷方法直接构建页面
              final castScreen = uiRegistry.buildCastScreen(
                DivinationType.liuYao,
                CastMethod.coin,
              );

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => castScreen),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 4. 动态构建结果页面

```dart
class CastScreen extends StatelessWidget {
  final DivinationType systemType;
  final CastMethod method;

  const CastScreen({
    required this.systemType,
    required this.method,
    super.key,
  });

  Future<void> _performCast(BuildContext context) async {
    // 1. 获取 Domain 系统
    final system = DivinationRegistry().getSystem(systemType);

    // 2. 执行起卦
    final result = await system.cast(
      method: method,
      input: {},
    );

    // 3. 使用 UI 工厂构建结果页面
    final resultScreen = DivinationUIRegistry().buildResultScreen(result);

    // 4. 导航到结果页面
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => resultScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('起卦')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _performCast(context),
          child: const Text('开始起卦'),
        ),
      ),
    );
  }
}
```

### 5. 动态构建历史记录列表

```dart
class HistoryListScreen extends StatelessWidget {
  final List<DivinationResult> records;

  const HistoryListScreen({required this.records, super.key});

  @override
  Widget build(BuildContext context) {
    final uiRegistry = DivinationUIRegistry();

    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final result = records[index];

          // 动态构建历史记录卡片
          final historyCard = uiRegistry.buildHistoryCard(result);

          return GestureDetector(
            onTap: () {
              // 点击卡片跳转到结果详情页面
              final resultScreen = uiRegistry.buildResultScreen(result);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => resultScreen),
              );
            },
            child: historyCard,
          );
        },
      ),
    );
  }
}
```

## 高级用法

### 1. 动态显示系统列表

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final systemRegistry = DivinationRegistry();
    final uiRegistry = DivinationUIRegistry();

    // 获取所有启用的系统
    final enabledSystems = systemRegistry.getEnabledSystems();

    return Scaffold(
      appBar: AppBar(title: const Text('选择术数系统')),
      body: ListView.builder(
        itemCount: enabledSystems.length,
        itemBuilder: (context, index) {
          final system = enabledSystems[index];
          final uiFactory = uiRegistry.getUIFactory(system.type);

          // 使用 UI 工厂的自定义系统卡片
          final systemCard = uiFactory.buildSystemCard();

          if (systemCard != null) {
            return GestureDetector(
              onTap: () => _navigateToMethodSelection(context, system),
              child: systemCard,
            );
          }

          // 使用默认卡片
          return ListTile(
            leading: Icon(
              uiFactory.getSystemIcon() ?? Icons.auto_awesome,
              color: uiFactory.getSystemColor(),
            ),
            title: Text(system.name),
            subtitle: Text(system.description),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => _navigateToMethodSelection(context, system),
          );
        },
      ),
    );
  }

  void _navigateToMethodSelection(
    BuildContext context,
    DivinationSystem system,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MethodSelectionScreen(system: system),
      ),
    );
  }
}
```

### 2. 起卦方式选择页面

```dart
class MethodSelectionScreen extends StatelessWidget {
  final DivinationSystem system;

  const MethodSelectionScreen({required this.system, super.key});

  @override
  Widget build(BuildContext context) {
    final uiRegistry = DivinationUIRegistry();

    return Scaffold(
      appBar: AppBar(title: Text('${system.name} - 选择起卦方式')),
      body: ListView.builder(
        itemCount: system.supportedMethods.length,
        itemBuilder: (context, index) {
          final method = system.supportedMethods[index];

          return ListTile(
            leading: _getMethodIcon(method),
            title: Text(method.displayName),
            subtitle: _getMethodDescription(method),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // 动态构建起卦页面
              final castScreen = uiRegistry.buildCastScreen(
                system.type,
                method,
              );

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => castScreen),
              );
            },
          );
        },
      ),
    );
  }

  Icon _getMethodIcon(CastMethod method) {
    switch (method) {
      case CastMethod.coin:
        return const Icon(Icons.casino);
      case CastMethod.time:
        return const Icon(Icons.access_time);
      case CastMethod.manual:
        return const Icon(Icons.edit);
      case CastMethod.number:
        return const Icon(Icons.numbers);
      case CastMethod.random:
        return const Icon(Icons.shuffle);
    }
  }

  Text _getMethodDescription(CastMethod method) {
    switch (method) {
      case CastMethod.coin:
        return const Text('使用三枚铜钱摇六次');
      case CastMethod.time:
        return const Text('根据起卦时间计算');
      case CastMethod.manual:
        return const Text('手动输入卦象');
      case CastMethod.number:
        return const Text('输入数字起卦');
      case CastMethod.random:
        return const Text('系统随机生成');
    }
  }
}
```

### 3. 错误处理

```dart
class SafeCastScreen extends StatelessWidget {
  final DivinationType systemType;
  final CastMethod method;

  const SafeCastScreen({
    required this.systemType,
    required this.method,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // 检查 UI 工厂是否已注册
      final uiRegistry = DivinationUIRegistry();
      if (!uiRegistry.isUIRegistered(systemType)) {
        return _buildErrorScreen('UI 工厂未注册: ${systemType.displayName}');
      }

      // 获取 UI 工厂
      final uiFactory = uiRegistry.getUIFactory(systemType);

      // 构建起卦页面
      return uiFactory.buildCastScreen(method);
    } catch (e) {
      return _buildErrorScreen('构建页面失败: $e');
    }
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('错误')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
```

## 最佳实践

### 1. UI 工厂实现原则

✅ **推荐做法**:
- UI 工厂只负责构建 Widget，不包含业务逻辑
- 返回的 Widget 应该是完整的页面（包含 Scaffold）
- 使用 ViewModel 进行状态管理
- 支持类型检查，确保结果类型匹配

❌ **避免做法**:
- 在 UI 工厂中执行业务逻辑
- 返回不完整的 Widget（缺少 Scaffold）
- 在 UI 工厂中直接访问数据库
- 忽略类型检查

### 2. 注册时机

```dart
void main() {
  // ✅ 推荐：在 main() 函数中注册所有系统和 UI 工厂
  _registerSystems();
  _registerUIFactories();

  runApp(const MyApp());
}

void _registerSystems() {
  final registry = DivinationRegistry();
  registry.register(LiuYaoSystem());
  // 注册其他系统...
}

void _registerUIFactories() {
  final uiRegistry = DivinationUIRegistry();
  uiRegistry.registerUI(LiuYaoUIFactory());
  // 注册其他 UI 工厂...
}
```

### 3. 类型安全

```dart
@override
Widget buildResultScreen(DivinationResult result) {
  // ✅ 推荐：进行类型检查
  if (result is! LiuYaoResult) {
    throw ArgumentError('结果类型不匹配，期望 LiuYaoResult，实际 ${result.runtimeType}');
  }

  return LiuYaoResultScreen(result: result);
}
```

### 4. 可选方法实现

```dart
class LiuYaoUIFactory implements DivinationUIFactory {
  // ... 必需方法实现

  @override
  Widget? buildSystemCard() {
    // ✅ 推荐：提供自定义系统卡片
    return Card(
      child: ListTile(
        leading: Icon(getSystemIcon(), color: getSystemColor()),
        title: const Text('六爻占卜'),
        subtitle: const Text('传统六爻排盘'),
      ),
    );
  }

  @override
  IconData? getSystemIcon() => Icons.auto_awesome;

  @override
  Color? getSystemColor() => Colors.blue;
}
```

### 5. 测试策略

```dart
// test/unit/ui/liuyao_ui_factory_test.dart

void main() {
  group('LiuYaoUIFactory', () {
    late LiuYaoUIFactory factory;

    setUp(() {
      factory = LiuYaoUIFactory();
    });

    test('systemType 应该返回 liuYao', () {
      expect(factory.systemType, DivinationType.liuYao);
    });

    testWidgets('buildCastScreen 应该返回有效的 Widget',
        (WidgetTester tester) async {
      final castScreen = factory.buildCastScreen(CastMethod.coin);

      await tester.pumpWidget(MaterialApp(home: castScreen));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    test('buildResultScreen 应该在类型不匹配时抛出异常', () {
      final wrongResult = MockDaLiuRenResult();

      expect(
        () => factory.buildResultScreen(wrongResult),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

## 常见问题

### Q1: 如何添加新的术数系统？

**A**: 按照以下步骤：

1. 实现 `DivinationSystem` 接口
2. 实现 `DivinationUIFactory` 接口
3. 在 `main.dart` 中注册系统和 UI 工厂

```dart
// 1. 实现系统
class MeiHuaSystem implements DivinationSystem {
  // ... 实现
}

// 2. 实现 UI 工厂
class MeiHuaUIFactory implements DivinationUIFactory {
  // ... 实现
}

// 3. 注册
void main() {
  DivinationRegistry().register(MeiHuaSystem());
  DivinationUIRegistry().registerUI(MeiHuaUIFactory());
  runApp(const MyApp());
}
```

### Q2: UI 工厂未注册时会发生什么？

**A**: 调用 `getUIFactory()` 会抛出 `StateError`。建议使用 `tryGetUIFactory()` 或 `isUIRegistered()` 进行检查：

```dart
final uiRegistry = DivinationUIRegistry();

// 方式一：使用 tryGetUIFactory
final factory = uiRegistry.tryGetUIFactory(DivinationType.liuYao);
if (factory == null) {
  // 处理未注册情况
  return ErrorScreen(message: 'UI 工厂未注册');
}

// 方式二：使用 isUIRegistered
if (!uiRegistry.isUIRegistered(DivinationType.liuYao)) {
  // 处理未注册情况
  return ErrorScreen(message: 'UI 工厂未注册');
}
```

### Q3: 如何在 UI 工厂中使用 ViewModel？

**A**: 在构建的 Widget 中集成 ViewModel：

```dart
@override
Widget buildCastScreen(CastMethod method) {
  return ChangeNotifierProvider(
    create: (_) => LiuYaoCastViewModel(
      system: LiuYaoSystem(),
      repository: DivinationRepository(),
    ),
    child: const LiuYaoCoinCastScreen(),
  );
}
```

### Q4: 如何处理不支持的起卦方式？

**A**: 在 `buildCastScreen()` 中抛出 `UnsupportedError`：

```dart
@override
Widget buildCastScreen(CastMethod method) {
  switch (method) {
    case CastMethod.coin:
      return const LiuYaoCoinCastScreen();
    case CastMethod.time:
      return const LiuYaoTimeCastScreen();
    case CastMethod.manual:
      return const LiuYaoManualCastScreen();
    default:
      throw UnsupportedError('六爻不支持的起卦方式: ${method.displayName}');
  }
}
```

## 参考资料

- [DivinationSystem 接口文档](./divination-system-interface.md)
- [MVVM 架构指南](../../CLAUDE.md)
- [Flutter 状态管理](https://docs.flutter.dev/development/data-and-backend/state-mgmt)

---

**文档维护者**: James (Dev Agent)
**最后审核**: 2025-01-15
