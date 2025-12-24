import 'package:flutter/material.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';

/// Mock 占卜 UI 工厂（用于测试）
///
/// 提供简单的 Placeholder Widget 实现，用于单元测试和集成测试。
/// 不包含实际的 UI 逻辑，只用于验证 UI 工厂接口的正确性。
class MockDivinationUIFactory implements DivinationUIFactory {
  /// 系统类型（可自定义）
  @override
  final DivinationType systemType;

  /// 系统图标（可选）
  final IconData? _systemIcon;

  /// 系统主题色（可选）
  final Color? _systemColor;

  /// 构造函数
  MockDivinationUIFactory({
    required this.systemType,
    IconData? systemIcon,
    Color? systemColor,
  })  : _systemIcon = systemIcon,
        _systemColor = systemColor;

  @override
  Widget buildCastScreen(CastMethod method) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mock Cast Screen - ${method.displayName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 64),
            const SizedBox(height: 16),
            Text(
              'Mock Cast Screen',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '系统: ${systemType.displayName}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '起卦方式: ${method.displayName}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Result Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Mock Result Screen',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '系统: ${result.systemType.displayName}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '起卦方式: ${result.castMethod.displayName}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '摘要: ${result.getSummary()}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildHistoryCard(DivinationResult result) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text('Mock History Card - ${result.systemType.displayName}'),
        subtitle: Text(result.getSummary()),
        trailing: Text(
          '${result.castTime.year}-${result.castTime.month}-${result.castTime.day}',
        ),
      ),
    );
  }

  @override
  Widget? buildSystemCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(_systemIcon ?? Icons.auto_awesome),
        title: Text('Mock System Card - ${systemType.displayName}'),
        subtitle: const Text('这是一个 Mock 系统卡片'),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }

  @override
  IconData? getSystemIcon() => _systemIcon;

  @override
  Color? getSystemColor() => _systemColor;
}

/// Mock 六爻 UI 工厂（用于测试）
class MockLiuYaoUIFactory extends MockDivinationUIFactory {
  MockLiuYaoUIFactory()
      : super(
          systemType: DivinationType.liuYao,
          systemIcon: Icons.auto_awesome,
          systemColor: Colors.blue,
        );
}

/// Mock 大六壬 UI 工厂（用于测试）
class MockDaLiuRenUIFactory extends MockDivinationUIFactory {
  MockDaLiuRenUIFactory()
      : super(
          systemType: DivinationType.daLiuRen,
          systemIcon: Icons.stars,
          systemColor: Colors.purple,
        );
}

/// Mock 小六壬 UI 工厂（用于测试）
class MockXiaoLiuRenUIFactory extends MockDivinationUIFactory {
  MockXiaoLiuRenUIFactory()
      : super(
          systemType: DivinationType.xiaoLiuRen,
          systemIcon: Icons.star,
          systemColor: Colors.orange,
        );
}

/// Mock 梅花易数 UI 工厂（用于测试）
class MockMeiHuaUIFactory extends MockDivinationUIFactory {
  MockMeiHuaUIFactory()
      : super(
          systemType: DivinationType.meiHua,
          systemIcon: Icons.local_florist,
          systemColor: Colors.pink,
        );
}

