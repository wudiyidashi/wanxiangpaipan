import 'package:flutter/material.dart';
import '../domain/divination_system.dart';

/// 占卜 UI 工厂抽象接口
///
/// 每个术数系统需要提供一个 UI 工厂实现，用于动态渲染该术数系统的界面。
/// 这是 Presentation 层的接口，依赖 Flutter。
///
/// 示例实现：
/// ```dart
/// class LiuYaoUIFactory implements DivinationUIFactory {
///   @override
///   DivinationType get systemType => DivinationType.liuYao;
///
///   @override
///   Widget buildCastScreen(CastMethod method) {
///     switch (method) {
///       case CastMethod.coin:
///         return LiuYaoCoinCastScreen();
///       case CastMethod.time:
///         return LiuYaoTimeCastScreen();
///       case CastMethod.manual:
///         return LiuYaoManualCastScreen();
///       default:
///         throw UnsupportedError('不支持的起卦方式: $method');
///     }
///   }
///
///   @override
///   Widget buildResultScreen(DivinationResult result) {
///     return LiuYaoResultScreen(result: result as LiuYaoResult);
///   }
///
///   @override
///   Widget buildHistoryCard(DivinationResult result) {
///     return LiuYaoHistoryCard(result: result as LiuYaoResult);
///   }
/// }
/// ```
abstract class DivinationUIFactory {
  /// 对应的术数系统类型
  DivinationType get systemType;

  /// 构建起卦页面
  ///
  /// 根据起卦方式返回对应的起卦界面 Widget。
  ///
  /// [method] 起卦方式
  /// 返回起卦页面 Widget
  ///
  /// 抛出 [UnsupportedError] 如果该起卦方式不支持
  ///
  /// 示例：
  /// ```dart
  /// final castScreen = uiFactory.buildCastScreen(CastMethod.coin);
  /// Navigator.push(context, MaterialPageRoute(builder: (_) => castScreen));
  /// ```
  Widget buildCastScreen(CastMethod method);

  /// 构建结果展示页面
  ///
  /// 根据占卜结果返回对应的结果展示界面 Widget。
  ///
  /// [result] 占卜结果
  /// 返回结果展示页面 Widget
  ///
  /// 示例：
  /// ```dart
  /// final resultScreen = uiFactory.buildResultScreen(result);
  /// Navigator.push(context, MaterialPageRoute(builder: (_) => resultScreen));
  /// ```
  Widget buildResultScreen(DivinationResult result);

  /// 构建历史记录卡片
  ///
  /// 用于在历史记录列表中显示该占卜记录的卡片 Widget。
  ///
  /// [result] 占卜结果
  /// 返回历史记录卡片 Widget
  ///
  /// 示例：
  /// ```dart
  /// ListView.builder(
  ///   itemBuilder: (context, index) {
  ///     final result = records[index];
  ///     final uiFactory = registry.getUIFactory(result.systemType);
  ///     return uiFactory.buildHistoryCard(result);
  ///   },
  /// )
  /// ```
  Widget buildHistoryCard(DivinationResult result);

  /// 构建系统介绍卡片（可选）
  ///
  /// 用于在主页显示该术数系统的介绍卡片。
  /// 如果返回 null，将使用默认的卡片样式。
  ///
  /// 返回系统介绍卡片 Widget，或 null 使用默认样式
  Widget? buildSystemCard() => null;

  /// 获取系统图标（可选）
  ///
  /// 返回该术数系统的图标，用于在 UI 中显示。
  /// 如果返回 null，将使用默认图标。
  IconData? getSystemIcon() => null;

  /// 获取系统主题色（可选）
  ///
  /// 返回该术数系统的主题色，用于 UI 配色。
  /// 如果返回 null，将使用默认主题色。
  Color? getSystemColor() => null;
}

/// 占卜 UI 工厂注册表（单例）
///
/// 管理所有术数系统的 UI 工厂，提供动态 UI 渲染能力。
/// 使用单例模式确保全局只有一个注册表实例。
///
/// 使用示例：
/// ```dart
/// // 注册 UI 工厂
/// final uiRegistry = DivinationUIRegistry();
/// uiRegistry.registerUI(LiuYaoUIFactory());
/// uiRegistry.registerUI(DaLiuRenUIFactory());
///
/// // 获取 UI 工厂
/// final liuyaoUIFactory = uiRegistry.getUIFactory(DivinationType.liuYao);
///
/// // 动态构建起卦页面
/// final castScreen = liuyaoUIFactory.buildCastScreen(CastMethod.coin);
/// Navigator.push(context, MaterialPageRoute(builder: (_) => castScreen));
///
/// // 动态构建结果页面
/// final resultScreen = liuyaoUIFactory.buildResultScreen(result);
/// Navigator.push(context, MaterialPageRoute(builder: (_) => resultScreen));
/// ```
class DivinationUIRegistry {
  // 私有构造函数
  DivinationUIRegistry._internal();

  // 单例实例
  static final DivinationUIRegistry _instance =
      DivinationUIRegistry._internal();

  // 工厂构造函数返回单例
  factory DivinationUIRegistry() => _instance;

  // 存储已注册的 UI 工厂
  final Map<DivinationType, DivinationUIFactory> _uiFactories = {};

  /// 注册 UI 工厂
  ///
  /// 将一个术数系统的 UI 工厂注册到注册表中。
  /// 如果该类型的 UI 工厂已存在，将被覆盖。
  ///
  /// [factory] 要注册的 UI 工厂
  ///
  /// 示例：
  /// ```dart
  /// uiRegistry.registerUI(LiuYaoUIFactory());
  /// ```
  void registerUI(DivinationUIFactory factory) {
    _uiFactories[factory.systemType] = factory;
  }

  /// 批量注册 UI 工厂
  ///
  /// [factories] 要注册的 UI 工厂列表
  void registerAllUI(List<DivinationUIFactory> factories) {
    for (final factory in factories) {
      registerUI(factory);
    }
  }

  /// 获取 UI 工厂
  ///
  /// 根据术数系统类型获取对应的 UI 工厂实例。
  ///
  /// [type] 术数系统类型
  /// 返回对应的 UI 工厂实例
  ///
  /// 抛出 [StateError] 如果 UI 工厂未注册
  ///
  /// 示例：
  /// ```dart
  /// final liuyaoUIFactory = uiRegistry.getUIFactory(DivinationType.liuYao);
  /// final castScreen = liuyaoUIFactory.buildCastScreen(CastMethod.coin);
  /// ```
  DivinationUIFactory getUIFactory(DivinationType type) {
    final factory = _uiFactories[type];
    if (factory == null) {
      throw StateError('UI 工厂未注册: ${type.displayName}');
    }
    return factory;
  }

  /// 尝试获取 UI 工厂
  ///
  /// 与 [getUIFactory] 类似，但不会抛出异常。
  ///
  /// [type] 术数系统类型
  /// 返回对应的 UI 工厂实例，如果未注册返回 null
  DivinationUIFactory? tryGetUIFactory(DivinationType type) {
    return _uiFactories[type];
  }

  /// 获取所有已注册的 UI 工厂
  ///
  /// 返回所有已注册的 UI 工厂列表
  List<DivinationUIFactory> getAllUIFactories() {
    return _uiFactories.values.toList();
  }

  /// 检查 UI 工厂是否已注册
  ///
  /// [type] 术数系统类型
  /// 返回 true 如果 UI 工厂已注册，否则返回 false
  bool isUIRegistered(DivinationType type) {
    return _uiFactories.containsKey(type);
  }

  /// 取消注册 UI 工厂
  ///
  /// 从注册表中移除指定类型的 UI 工厂。
  ///
  /// [type] 术数系统类型
  /// 返回被移除的 UI 工厂，如果 UI 工厂未注册返回 null
  DivinationUIFactory? unregisterUI(DivinationType type) {
    return _uiFactories.remove(type);
  }

  /// 清空所有已注册的 UI 工厂
  ///
  /// 警告：此操作会移除所有已注册的 UI 工厂，通常仅用于测试
  void clear() {
    _uiFactories.clear();
  }

  /// 获取已注册 UI 工厂数量
  int get count => _uiFactories.length;

  /// 获取所有已注册的系统类型
  List<DivinationType> getRegisteredTypes() {
    return _uiFactories.keys.toList();
  }

  /// 检查是否有任何 UI 工厂已注册
  bool get hasAnyUIFactory => _uiFactories.isNotEmpty;

  /// 动态构建起卦页面
  ///
  /// 这是一个便捷方法，根据系统类型和起卦方式直接构建起卦页面。
  ///
  /// [systemType] 术数系统类型
  /// [method] 起卦方式
  /// 返回起卦页面 Widget
  ///
  /// 抛出 [StateError] 如果 UI 工厂未注册
  /// 抛出 [UnsupportedError] 如果起卦方式不支持
  Widget buildCastScreen(DivinationType systemType, CastMethod method) {
    final factory = getUIFactory(systemType);
    return factory.buildCastScreen(method);
  }

  /// 动态构建结果页面
  ///
  /// 这是一个便捷方法，根据占卜结果直接构建结果页面。
  ///
  /// [result] 占卜结果
  /// 返回结果页面 Widget
  ///
  /// 抛出 [StateError] 如果 UI 工厂未注册
  Widget buildResultScreen(DivinationResult result) {
    final factory = getUIFactory(result.systemType);
    return factory.buildResultScreen(result);
  }

  /// 动态构建历史记录卡片
  ///
  /// 这是一个便捷方法，根据占卜结果直接构建历史记录卡片。
  ///
  /// [result] 占卜结果
  /// 返回历史记录卡片 Widget
  ///
  /// 抛出 [StateError] 如果 UI 工厂未注册
  Widget buildHistoryCard(DivinationResult result) {
    final factory = getUIFactory(result.systemType);
    return factory.buildHistoryCard(result);
  }

  /// 获取 UI 工厂信息摘要（用于调试）
  ///
  /// 返回所有已注册 UI 工厂的信息字符串
  String getUIFactoriesSummary() {
    if (_uiFactories.isEmpty) {
      return '没有已注册的 UI 工厂';
    }

    final buffer = StringBuffer();
    buffer.writeln('已注册的 UI 工厂 (${_uiFactories.length}):');

    for (final entry in _uiFactories.entries) {
      final type = entry.key;
      final factory = entry.value;
      buffer.writeln('  - ${type.displayName}');

      final icon = factory.getSystemIcon();
      if (icon != null) {
        buffer.writeln('    图标: ${icon.codePoint}');
      }

      final color = factory.getSystemColor();
      if (color != null) {
        buffer.writeln('    主题色: #${color.value.toRadixString(16)}');
      }
    }

    return buffer.toString();
  }
}
