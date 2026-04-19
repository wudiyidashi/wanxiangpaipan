import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ai/service/ai_analysis_service.dart';
import '../../widgets/antique/antique.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
    return AntiqueScaffold(
      appBar: const AntiqueAppBar(title: '设置'),
      body: ListView(
        children: [
          // AI 设置分组
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('AI 功能', style: AppTextStyles.antiqueSection),
          ),
          _buildAIProviderSettingsTile(context),
          _buildPromptTemplateSettingsTile(context),

          const SizedBox(height: 32),

          // 显示设置分组（预留）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('显示', style: AppTextStyles.antiqueSection),
          ),
          _buildDisplaySettingsTile(context),

          const SizedBox(height: 32),

          // 数据管理分组（预留）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('数据', style: AppTextStyles.antiqueSection),
          ),
          _buildDataSettingsTile(context),

          const SizedBox(height: 32),

          // 关于分组
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('关于', style: AppTextStyles.antiqueSection),
          ),
          _buildAboutTile(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAIProviderSettingsTile(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();
    final isConfigured = aiService?.hasAvailableProvider ?? false;

    return _buildSettingsTile(
      context: context,
      title: 'AI 接口配置',
      subtitle: isConfigured ? '已配置，可切换接口、模型与密钥' : '未配置，点击新增 AI 接口配置',
      icon: Icons.smart_toy,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConfigured ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.guhe, size: 20),
        ],
      ),
      onTap: () => Navigator.pushNamed(context, '/ai-settings'),
    );
  }

  Widget _buildPromptTemplateSettingsTile(BuildContext context) {
    return _buildSettingsTile(
      context: context,
      title: '提示词模板',
      subtitle: '按术数系统管理 AI 模板内容',
      icon: Icons.edit_note,
      onTap: () => Navigator.pushNamed(context, '/prompt-template-settings'),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AntiqueCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.zhusha, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.antiqueBody),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.antiqueLabel),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.guhe,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySettingsTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AntiqueCard(
        onTap: () {
          // TODO: 导航到显示设置页面
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('显示设置功能开发中...')),
          );
        },
        child: Row(
          children: [
            Icon(Icons.palette, color: AppColors.zhusha, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('显示设置', style: AppTextStyles.antiqueBody),
                  const SizedBox(height: 2),
                  Text('主题、字体、布局', style: AppTextStyles.antiqueLabel),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.guhe, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSettingsTile(BuildContext context) {
    return _buildSettingsTile(
      context: context,
      title: '数据管理',
      subtitle: '历史、备份、恢复与清理',
      icon: Icons.storage,
      onTap: () => Navigator.pushNamed(context, '/data-management'),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AntiqueCard(
        onTap: () {
          showAboutDialog(
            context: context,
            applicationName: '万象排盘',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 万象排盘',
            children: [
              const SizedBox(height: 16),
              const Text(
                '一款支持多种术数系统的排盘应用，'
                '包括六爻、大六壬、小六壬、梅花易数等。',
              ),
            ],
          );
        },
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.zhusha, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('关于', style: AppTextStyles.antiqueBody),
                  const SizedBox(height: 2),
                  Text('版本信息、开源协议', style: AppTextStyles.antiqueLabel),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.guhe, size: 20),
          ],
        ),
      ),
    );
  }
}
