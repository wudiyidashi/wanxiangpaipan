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
          _buildAISettingsTile(context),

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

  Widget _buildAISettingsTile(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();
    final isConfigured = aiService?.hasAvailableProvider ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AntiqueCard(
        onTap: () {
          Navigator.pushNamed(context, '/ai-settings');
        },
        child: Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.zhusha, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('AI 分析设置', style: AppTextStyles.antiqueBody),
                  const SizedBox(height: 2),
                  Text(
                    isConfigured ? '已配置' : '未配置，点击设置 API Key',
                    style: AppTextStyles.antiqueLabel,
                  ),
                ],
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AntiqueCard(
        onTap: () {
          // TODO: 导航到数据管理页面
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据管理功能开发中...')),
          );
        },
        child: Row(
          children: [
            Icon(Icons.storage, color: AppColors.zhusha, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('数据管理', style: AppTextStyles.antiqueBody),
                  const SizedBox(height: 2),
                  Text('备份、恢复、清除数据', style: AppTextStyles.antiqueLabel),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.guhe, size: 20),
          ],
        ),
      ),
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
