/// 排盘注册引导类
///
/// 集中管理所有术数系统和 UI 工厂的注册。
/// 在应用启动时调用 `registerAll()` 完成所有注册。
///
/// ## 设计原则
///
/// 1. **集中管理**: 所有注册逻辑集中在一个类中
/// 2. **一次调用**: 主函数只需调用 `registerAll()`
/// 3. **易于扩展**: 添加新系统只需在 Bootstrap 中添加一行代码
/// 4. **验证机制**: 提供注册验证方法，确保注册正确
///
/// ## 使用方式
///
/// ```dart
/// void main() {
///   // 注册所有术数系统和 UI 工厂
///   DivinationSystemBootstrap.registerAll();
///
///   // 验证注册（开发模式）
///   if (kDebugMode) {
///     final isValid = DivinationSystemBootstrap.verifyRegistration();
///     if (!isValid) {
///       throw StateError('System registration failed');
///     }
///     DivinationSystemBootstrap.printRegistrationInfo();
///   }
///
///   runApp(const WanxiangPaipanApp());
/// }
/// ```
///
/// ## 添加新系统
///
/// 1. 在 `_registerSystems()` 中添加系统注册
/// 2. 在 `_registerUIFactories()` 中添加 UI 工厂注册
/// 3. 完成！无需修改其他代码
library;

import 'package:flutter/foundation.dart';
import '../domain/divination_registry.dart';
import '../presentation/divination_ui_registry.dart';
import 'liuyao/liuyao_system.dart';
import 'liuyao/ui/liuyao_ui_factory.dart';
import 'meihua/meihua_system.dart';
import 'meihua/ui/meihua_ui_factory.dart';
import 'xiaoliuren/xiaoliuren_system.dart';
import 'xiaoliuren/ui/xiaoliuren_ui_factory.dart';
import 'daliuren/daliuren_system.dart';
import 'daliuren/ui/daliuren_ui_factory.dart';

/// 排盘注册引导类
///
/// 提供静态方法用于注册所有术数系统和 UI 工厂。
class DivinationSystemBootstrap {
  // 私有构造函数，防止实例化
  DivinationSystemBootstrap._();

  /// 注册所有术数系统和 UI 工厂
  ///
  /// 这是应用启动时的主要入口点，会依次调用：
  /// 1. `_registerSystems()` - 注册所有术数系统
  /// 2. `_registerUIFactories()` - 注册所有 UI 工厂
  ///
  /// 使用示例：
  /// ```dart
  /// void main() {
  ///   DivinationSystemBootstrap.registerAll();
  ///   runApp(const WanxiangPaipanApp());
  /// }
  /// ```
  static void registerAll() {
    _registerSystems();
    _registerUIFactories();
  }

  /// 注册所有术数系统
  ///
  /// 将所有可用的术数系统注册到 `DivinationRegistry` 中。
  /// 暂时禁用的系统可以注释掉对应的注册代码。
  static void _registerSystems() {
    final registry = DivinationRegistry();

    // 注册六爻系统
    registry.register(LiuYaoSystem());

    // 注册梅花易数系统
    registry.register(MeiHuaSystem());

    // 注册小六壬系统
    registry.register(XiaoLiuRenSystem());

    // 注册大六壬系统
    registry.register(DaLiuRenSystem());
  }

  /// 注册所有 UI 工厂
  ///
  /// 将所有可用的 UI 工厂注册到 `DivinationUIRegistry` 中。
  /// 每个术数系统都应该有对应的 UI 工厂。
  static void _registerUIFactories() {
    final uiRegistry = DivinationUIRegistry();

    // 注册六爻 UI 工厂
    uiRegistry.registerUI(LiuYaoUIFactory());

    // 注册大六壬 UI 工厂
    uiRegistry.registerUI(DaLiuRenUIFactory());

    // 注册梅花易数 UI 工厂
    uiRegistry.registerUI(MeiHuaUIFactory());

    // 注册小六壬 UI 工厂
    uiRegistry.registerUI(XiaoLiuRenUIFactory());
  }

  /// 注册六爻系统
  ///
  /// 单独注册六爻系统和对应的 UI 工厂。
  /// 可用于按需加载或动态注册。
  static void registerLiuYaoSystem() {
    final registry = DivinationRegistry();
    final uiRegistry = DivinationUIRegistry();

    registry.register(LiuYaoSystem());
    uiRegistry.registerUI(LiuYaoUIFactory());
  }

  /// 验证所有系统和 UI 工厂是否正确注册
  ///
  /// 检查所有启用的系统是否都已正确注册，包括：
  /// 1. 系统本身是否已注册到 `DivinationRegistry`
  /// 2. 对应的 UI 工厂是否已注册到 `DivinationUIRegistry`
  ///
  /// 返回：
  /// - `true`: 所有启用的系统都已正确注册
  /// - `false`: 有系统或 UI 工厂未注册
  ///
  /// 使用示例：
  /// ```dart
  /// if (kDebugMode) {
  ///   final isValid = DivinationSystemBootstrap.verifyRegistration();
  ///   if (!isValid) {
  ///     throw StateError('System registration failed');
  ///   }
  /// }
  /// ```
  static bool verifyRegistration() {
    final registry = DivinationRegistry();
    final uiRegistry = DivinationUIRegistry();

    final enabledSystems = registry.getEnabledSystems();

    if (enabledSystems.isEmpty) {
      if (kDebugMode) {
        print('⚠️  Warning: No enabled systems found');
      }
      return false;
    }

    bool allValid = true;

    for (final system in enabledSystems) {
      // 检查系统是否注册
      if (!registry.isRegistered(system.type)) {
        if (kDebugMode) {
          print('❌ System not registered: ${system.type.displayName}');
        }
        allValid = false;
      }

      // 检查 UI 工厂是否注册
      if (!uiRegistry.isUIRegistered(system.type)) {
        if (kDebugMode) {
          print('❌ UI Factory not registered: ${system.type.displayName}');
        }
        allValid = false;
      }
    }

    if (allValid && kDebugMode) {
      print('✅ All systems and UI factories are correctly registered');
    }

    return allValid;
  }

  /// 打印注册信息（用于调试）
  ///
  /// 输出所有已注册的术数系统信息，包括：
  /// - 系统名称和类型
  /// - 支持的起卦方式
  /// - 启用状态
  ///
  /// 仅在开发模式下调用此方法。
  ///
  /// 使用示例：
  /// ```dart
  /// if (kDebugMode) {
  ///   DivinationSystemBootstrap.printRegistrationInfo();
  /// }
  /// ```
  static void printRegistrationInfo() {
    if (!kDebugMode) return;

    final registry = DivinationRegistry();
    final uiRegistry = DivinationUIRegistry();
    final enabledSystems = registry.getEnabledSystems();

    print('');
    print('═══════════════════════════════════════════════════════');
    print('        Divination Systems Registration Info          ');
    print('═══════════════════════════════════════════════════════');
    print('');
    print('📊 Total enabled systems: ${enabledSystems.length}');
    print('📊 Total registered systems: ${registry.count}');
    print('📊 Total registered UI factories: ${uiRegistry.count}');
    print('');

    if (enabledSystems.isEmpty) {
      print('⚠️  No enabled systems found');
    } else {
      for (final system in enabledSystems) {
        final hasUI = uiRegistry.isUIRegistered(system.type);
        final statusIcon = hasUI ? '✅' : '❌';

        print('$statusIcon ${system.name} (${system.type.id})');
        print('   Description: ${system.description}');
        print(
            '   Supported methods: ${system.supportedMethods.map((m) => m.displayName).join(', ')}');
        print('   UI Factory: ${hasUI ? 'Registered' : 'Not registered'}');
        print('');
      }
    }

    print('═══════════════════════════════════════════════════════');
    print('');
  }

  /// 清空所有注册（仅用于测试）
  ///
  /// 清空 `DivinationRegistry` 和 `DivinationUIRegistry` 中的所有注册。
  /// 此方法仅应在单元测试中使用，确保每个测试都是独立的。
  ///
  /// ⚠️ **警告**: 不要在生产代码中调用此方法！
  ///
  /// 使用示例：
  /// ```dart
  /// setUp(() {
  ///   DivinationSystemBootstrap.clearAll();
  /// });
  /// ```
  static void clearAll() {
    DivinationRegistry().clear();
    DivinationUIRegistry().clear();
  }

  /// 获取注册摘要信息
  ///
  /// 返回一个包含注册统计信息的 Map：
  /// - `systemCount`: 已注册的系统数量
  /// - `uiFactoryCount`: 已注册的 UI 工厂数量
  /// - `enabledSystemCount`: 启用的系统数量
  /// - `allValid`: 所有系统和 UI 工厂是否都已正确注册
  ///
  /// 返回：包含注册统计信息的 Map
  static Map<String, dynamic> getRegistrationSummary() {
    final registry = DivinationRegistry();
    final uiRegistry = DivinationUIRegistry();
    final enabledSystems = registry.getEnabledSystems();

    return {
      'systemCount': registry.count,
      'uiFactoryCount': uiRegistry.count,
      'enabledSystemCount': enabledSystems.length,
      'allValid': verifyRegistration(),
    };
  }
}
