import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ai/ai_bootstrap.dart';
import '../../../ai/template/prompt_template.dart' as tmpl;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/antique/antique.dart';
import 'prompt_template_settings_viewmodel.dart';

class PromptTemplateSettingsScreen extends StatelessWidget {
  const PromptTemplateSettingsScreen({
    super.key,
    PromptTemplateSettingsService? service,
  }) : _service = service;

  final PromptTemplateSettingsService? _service;

  static const _systemNames = {
    'liuyao': '六爻',
    'daliuren': '大六壬',
    'meihua': '梅花易数',
    'xiaoliuren': '小六壬',
  };

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PromptTemplateSettingsViewModel>(
      create: (_) => PromptTemplateSettingsViewModel(
        service: _service ?? _buildSettingsService(),
      )..initialize(),
      child: const _PromptTemplateSettingsBody(),
    );
  }

  PromptTemplateSettingsService? _buildSettingsService() {
    if (!AIBootstrap.isInitialized) {
      return null;
    }
    return AIConfigPromptTemplateSettingsService(AIBootstrap.configManager);
  }
}

class _PromptTemplateSettingsBody extends StatelessWidget {
  const _PromptTemplateSettingsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptTemplateSettingsViewModel>(
      builder: (context, viewModel, _) {
        return AntiqueScaffold(
          appBar: AntiqueAppBar(
            title: '提示词模板',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: '刷新',
                  onPressed:
                      viewModel.isLoading ? null : viewModel.loadTemplates,
                  icon: const Icon(Icons.refresh, color: AppColors.guhe),
                ),
              ),
            ],
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!viewModel.serviceAvailable) ...[
                        _buildUnavailableCard(),
                        const SizedBox(height: 16),
                      ],
                      if (viewModel.errorMessage != null) ...[
                        _buildErrorCard(viewModel.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _buildTemplatesCard(context, viewModel),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUnavailableCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        'AI 模块尚未初始化完成，暂时无法读取或保存模板。',
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.zhusha),
      ),
    );
  }

  Widget _buildTemplatesCard(
    BuildContext context,
    PromptTemplateSettingsViewModel viewModel,
  ) {
    final grouped = viewModel.groupedTemplates;

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('模板列表', style: AppTextStyles.antiqueSection),
          const SizedBox(height: 4),
          Text(
            '按术数系统管理 AI 分析提示词，点击条目进入编辑。',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 12),
          if (grouped.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '暂无模板',
                  style: AppTextStyles.antiqueBody.copyWith(
                    color: AppColors.qianhe,
                  ),
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              final systemName =
                  PromptTemplateSettingsScreen._systemNames[entry.key] ??
                      entry.key;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      systemName,
                      style: AppTextStyles.antiqueBody.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.guhe,
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (template) => _buildTemplateTile(
                      context,
                      viewModel,
                      template,
                    ),
                  ),
                  const AntiqueDivider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTemplateTile(
    BuildContext context,
    PromptTemplateSettingsViewModel viewModel,
    tmpl.PromptTemplate template,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        template.isBuiltIn ? Icons.lock_outline : Icons.edit_note,
        color: template.isActive ? AppColors.dailan : AppColors.qianhe,
        size: 20,
      ),
      title: Text(template.name, style: AppTextStyles.antiqueBody),
      subtitle: Text(
        template.type.displayName,
        style: AppTextStyles.antiqueLabel,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (template.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '使用中',
                style: TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: () => _openTemplateEditor(context, viewModel, template),
    );
  }

  Future<void> _openTemplateEditor(
    BuildContext context,
    PromptTemplateSettingsViewModel viewModel,
    tmpl.PromptTemplate template,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<PromptTemplateEditorViewModel>(
          create: (_) => PromptTemplateEditorViewModel(
            service: viewModel.service,
            template: template,
          ),
          child: const _TemplateEditorScreen(),
        ),
      ),
    );
    if (result == true && context.mounted) {
      await viewModel.loadTemplates();
    }
  }
}

class _TemplateEditorScreen extends StatelessWidget {
  const _TemplateEditorScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptTemplateEditorViewModel>(
      builder: (context, viewModel, _) {
        final template = viewModel.template;
        return AntiqueScaffold(
          appBar: AntiqueAppBar(
            title: '编辑模板',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AntiqueButton(
                  label: viewModel.isSaving ? '保存中...' : '保存',
                  onPressed: viewModel.canSave
                      ? () => _save(context, viewModel)
                      : null,
                  variant: AntiqueButtonVariant.ghost,
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.errorMessage != null) ...[
                  _buildEditorErrorCard(viewModel.errorMessage!),
                  const SizedBox(height: 12),
                ],
                Text('模板名称', style: AppTextStyles.antiqueLabel),
                const SizedBox(height: 6),
                AntiqueTextField(
                  key: const ValueKey('template_name_field'),
                  controller: viewModel.nameController,
                  hint: '输入模板名称',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AntiqueTag(label: template.type.displayName),
                    if (template.isBuiltIn) ...[
                      const SizedBox(width: 8),
                      const AntiqueTag(label: '内置'),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text('模板内容', style: AppTextStyles.antiqueLabel),
                const SizedBox(height: 4),
                Text(
                  '支持变量：{{variable}}，条件：{{#if}}...{{/if}}，循环：{{#each}}...{{/each}}',
                  style: AppTextStyles.antiqueLabel,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AntiqueTextField(
                    key: const ValueKey('template_content_field'),
                    controller: viewModel.contentController,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      height: 1.5,
                      color: AppColors.xuanse,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditorErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.zhusha),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    PromptTemplateEditorViewModel viewModel,
  ) async {
    final saved = await viewModel.save();
    if (!context.mounted) {
      return;
    }
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? '保存失败')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('模板已保存')));
    Navigator.of(context).pop(true);
  }
}
