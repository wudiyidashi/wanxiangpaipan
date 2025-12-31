import 'package:flutter/material.dart';
import '../../../domain/divination_registry.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';

/// 起卦方式选择页面
///
/// 显示指定术数系统支持的所有起卦方式，用户选择后跳转到对应的起卦页面。
///
/// 使用示例：
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => MethodSelectorScreen(systemType: DivinationType.liuYao),
///   ),
/// );
/// ```
class MethodSelectorScreen extends StatelessWidget {
  /// 术数系统类型
  final DivinationType systemType;

  /// 构造函数
  const MethodSelectorScreen({
    required this.systemType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final registry = DivinationRegistry();
    final system = registry.getSystem(systemType);

    return Scaffold(
      appBar: AppBar(
        title: Text('${system.name} - 选择起卦方式'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 系统信息卡片
            _buildSystemInfoCard(context, system),

            // 起卦方式列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: system.supportedMethods.length,
                itemBuilder: (context, index) {
                  final method = system.supportedMethods[index];
                  return _buildMethodCard(context, method);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建系统信息卡片
  Widget _buildSystemInfoCard(BuildContext context, DivinationSystem system) {
    final uiRegistry = DivinationUIRegistry();
    final uiFactory = uiRegistry.tryGetUIFactory(system.type);
    final systemColor =
        uiFactory?.getSystemColor() ?? Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: systemColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: systemColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            uiFactory?.getSystemIcon() ?? Icons.auto_awesome,
            size: 32,
            color: systemColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  system.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: systemColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  system.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建起卦方式卡片
  Widget _buildMethodCard(BuildContext context, CastMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCastScreen(context, method),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 方式图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMethodIcon(method),
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),

              // 方式信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMethodDescription(method),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),

              // 箭头图标
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取起卦方式图标
  IconData _getMethodIcon(CastMethod method) {
    switch (method) {
      case CastMethod.coin:
        return Icons.monetization_on;
      case CastMethod.time:
        return Icons.access_time;
      case CastMethod.manual:
        return Icons.edit;
      case CastMethod.number:
        return Icons.dialpad;
      case CastMethod.random:
        return Icons.shuffle;
    }
  }

  /// 获取起卦方式描述
  String _getMethodDescription(CastMethod method) {
    switch (method) {
      case CastMethod.coin:
        return '使用三枚铜钱摇卦，传统起卦方式';
      case CastMethod.time:
        return '根据起卦时间自动生成卦象';
      case CastMethod.manual:
        return '手动输入六爻数字，适合已知卦象';
      case CastMethod.number:
        return '输入数字起卦，简单快捷';
      case CastMethod.random:
        return '随机生成卦象，快速占卜';
    }
  }

  /// 导航到起卦页面
  ///
  /// 使用 UI 工厂动态构建起卦页面。
  void _navigateToCastScreen(BuildContext context, CastMethod method) {
    try {
      // 使用 UI 工厂动态构建起卦页面
      final uiRegistry = DivinationUIRegistry();
      final uiFactory = uiRegistry.getUIFactory(systemType);
      final castScreen = uiFactory.buildCastScreen(method);

      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => castScreen),
      );
    } catch (e) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法打开起卦页面: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
