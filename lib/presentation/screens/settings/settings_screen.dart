import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ai/service/ai_analysis_service.dart';

/// 设置主页面
///
/// 提供应用的各种设置入口，包括：
/// - AI 设置（API Key、模型选择等）
/// - 显示设置（主题、字体等）- 预留
/// - 数据管理（备份、清除等）- 预留
/// - 关于页面 - 预留
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // AI 设置分组
          _buildSectionHeader(context, 'AI 功能'),
          _buildAISettingsTile(context),

          const Divider(height: 32),

          // 显示设置分组（预留）
          _buildSectionHeader(context, '显示'),
          _buildDisplaySettingsTile(context),

          const Divider(height: 32),

          // 数据管理分组（预留）
          _buildSectionHeader(context, '数据'),
          _buildDataSettingsTile(context),

          const Divider(height: 32),

          // 关于分组
          _buildSectionHeader(context, '关于'),
          _buildAboutTile(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAISettingsTile(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();
    final isConfigured = aiService?.hasAvailableProvider ?? false;

    return ListTile(
      leading: const Icon(Icons.smart_toy),
      title: const Text('AI 分析设置'),
      subtitle: Text(isConfigured ? '已配置' : '未配置，点击设置 API Key'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConfigured ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/ai-settings');
      },
    );
  }

  Widget _buildDisplaySettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('显示设置'),
      subtitle: const Text('主题、字体、布局'),
      trailing: const Icon(Icons.chevron_right),
      enabled: false, // 暂未实现
      onTap: () {
        // TODO: 导航到显示设置页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('显示设置功能开发中...')),
        );
      },
    );
  }

  Widget _buildDataSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('数据管理'),
      subtitle: const Text('备份、恢复、清除数据'),
      trailing: const Icon(Icons.chevron_right),
      enabled: false, // 暂未实现
      onTap: () {
        // TODO: 导航到数据管理页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据管理功能开发中...')),
        );
      },
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('关于'),
      subtitle: const Text('版本信息、开源协议'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: '万象排盘',
          applicationVersion: '1.0.0',
          applicationLegalese: '© 2024 万象排盘',
          children: [
            const SizedBox(height: 16),
            const Text(
              '一款支持多种术数系统的排盘应用，'
              '包括六爻、大六壬、小六壬、梅花易数等。',
            ),
          ],
        );
      },
    );
  }
}
