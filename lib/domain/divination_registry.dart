import 'divination_system.dart';

/// 排盘注册表（单例）
///
/// 管理所有已注册的术数系统，提供统一的访问接口。
/// 使用单例模式确保全局只有一个注册表实例。
///
/// 使用示例：
/// ```dart
/// // 注册系统
/// final registry = DivinationRegistry();
/// registry.register(LiuYaoSystem());
/// registry.register(DaLiuRenSystem());
///
/// // 获取系统
/// final liuyaoSystem = registry.getSystem(DivinationType.liuYao);
///
/// // 获取所有已注册系统
/// final allSystems = registry.getAllSystems();
///
/// // 获取所有已启用系统
/// final enabledSystems = registry.getEnabledSystems();
/// ```
class DivinationRegistry {
  // 私有构造函数
  DivinationRegistry._internal();

  // 单例实例
  static final DivinationRegistry _instance = DivinationRegistry._internal();

  // 工厂构造函数返回单例
  factory DivinationRegistry() => _instance;

  // 存储已注册的系统
  final Map<DivinationType, DivinationSystem> _systems = {};

  /// 注册术数系统
  ///
  /// 将一个术数系统注册到注册表中。
  /// 如果该类型的系统已存在，将被覆盖。
  ///
  /// [system] 要注册的术数系统
  ///
  /// 示例：
  /// ```dart
  /// registry.register(LiuYaoSystem());
  /// ```
  void register(DivinationSystem system) {
    _systems[system.type] = system;
  }

  /// 批量注册术数系统
  ///
  /// [systems] 要注册的术数系统列表
  void registerAll(List<DivinationSystem> systems) {
    for (final system in systems) {
      register(system);
    }
  }

  /// 获取术数系统
  ///
  /// 根据系统类型获取对应的术数系统实例。
  ///
  /// [type] 术数系统类型
  /// 返回对应的术数系统实例
  ///
  /// 抛出 [StateError] 如果系统未注册或已禁用
  ///
  /// 示例：
  /// ```dart
  /// final liuyaoSystem = registry.getSystem(DivinationType.liuYao);
  /// ```
  DivinationSystem getSystem(DivinationType type) {
    final system = _systems[type];
    if (system == null) {
      throw StateError('术数系统未注册: ${type.displayName}');
    }
    if (!system.isEnabled) {
      throw StateError('术数系统已禁用: ${type.displayName}');
    }
    return system;
  }

  /// 尝试获取术数系统
  ///
  /// 与 [getSystem] 类似，但不会抛出异常。
  ///
  /// [type] 术数系统类型
  /// 返回对应的术数系统实例，如果未注册返回 null
  DivinationSystem? tryGetSystem(DivinationType type) {
    return _systems[type];
  }

  /// 获取所有已注册系统
  ///
  /// 返回所有已注册的术数系统列表（包括已禁用的）
  List<DivinationSystem> getAllSystems() {
    return _systems.values.toList();
  }

  /// 获取所有已启用系统
  ///
  /// 返回所有已启用的术数系统列表（isEnabled = true）
  List<DivinationSystem> getEnabledSystems() {
    return _systems.values.where((system) => system.isEnabled).toList();
  }

  /// 检查系统是否已注册
  ///
  /// [type] 术数系统类型
  /// 返回 true 如果系统已注册，否则返回 false
  bool isRegistered(DivinationType type) {
    return _systems.containsKey(type);
  }

  /// 检查系统是否已启用
  ///
  /// [type] 术数系统类型
  /// 返回 true 如果系统已注册且已启用，否则返回 false
  bool isEnabled(DivinationType type) {
    final system = _systems[type];
    return system != null && system.isEnabled;
  }

  /// 取消注册术数系统
  ///
  /// 从注册表中移除指定类型的术数系统。
  ///
  /// [type] 术数系统类型
  /// 返回被移除的系统，如果系统未注册返回 null
  DivinationSystem? unregister(DivinationType type) {
    return _systems.remove(type);
  }

  /// 清空所有已注册系统
  ///
  /// 警告：此操作会移除所有已注册的系统，通常仅用于测试
  void clear() {
    _systems.clear();
  }

  /// 获取已注册系统数量
  int get count => _systems.length;

  /// 获取已启用系统数量
  int get enabledCount => _systems.values.where((s) => s.isEnabled).length;

  /// 获取所有已注册的系统类型
  List<DivinationType> getRegisteredTypes() {
    return _systems.keys.toList();
  }

  /// 获取所有已启用的系统类型
  List<DivinationType> getEnabledTypes() {
    return _systems.entries
        .where((entry) => entry.value.isEnabled)
        .map((entry) => entry.key)
        .toList();
  }

  /// 检查是否有任何系统已注册
  bool get hasAnySystem => _systems.isNotEmpty;

  /// 检查是否有任何系统已启用
  bool get hasAnyEnabledSystem =>
      _systems.values.any((system) => system.isEnabled);

  /// 获取系统信息摘要（用于调试）
  ///
  /// 返回所有已注册系统的信息字符串
  String getSystemsSummary() {
    if (_systems.isEmpty) {
      return '没有已注册的术数系统';
    }

    final buffer = StringBuffer();
    buffer.writeln('已注册的术数系统 (${_systems.length}):');

    for (final entry in _systems.entries) {
      final type = entry.key;
      final system = entry.value;
      final status = system.isEnabled ? '✓ 已启用' : '✗ 已禁用';
      buffer.writeln('  - ${type.displayName} ($status)');
      buffer.writeln('    名称: ${system.name}');
      buffer.writeln('    描述: ${system.description}');
      buffer.writeln(
          '    支持的起卦方式: ${system.supportedMethods.map((m) => m.displayName).join(', ')}');
    }

    return buffer.toString();
  }
}
