import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ai/config/ai_provider_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/antique/antique.dart';
import 'ai_settings_viewmodel.dart';

class AIPreset {
  const AIPreset(this.name, this.baseUrl, this.icon);

  final String name;
  final String baseUrl;
  final IconData icon;
}

class AISettingsBody extends StatelessWidget {
  const AISettingsBody({
    super.key,
    required this.presets,
  });

  final List<AIPreset> presets;

  @override
  Widget build(BuildContext context) {
    return Consumer<AISettingsViewModel>(
      builder: (context, viewModel, _) {
        return AntiqueScaffold(
          appBar: const AntiqueAppBar(title: 'AI 接口配置'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!viewModel.serviceAvailable) ...[
                  const AISettingsUnavailableCard(),
                  const SizedBox(height: 16),
                ],
                AISettingsProfilesCard(viewModel: viewModel),
                const SizedBox(height: 16),
                AISettingsEditorCard(
                  viewModel: viewModel,
                  presets: presets,
                ),
                const SizedBox(height: 16),
                if (viewModel.validationMessage != null) ...[
                  AISettingsValidationCard(viewModel: viewModel),
                  const SizedBox(height: 16),
                ],
                AISettingsSaveButton(viewModel: viewModel),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AISettingsUnavailableCard extends StatelessWidget {
  const AISettingsUnavailableCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        'AI 服务尚未初始化完成，当前页面可能无法保存或切换配置。',
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
      ),
    );
  }
}

class AISettingsProfilesCard extends StatelessWidget {
  const AISettingsProfilesCard({
    super.key,
    required this.viewModel,
  });

  final AISettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('接口配置集', style: AppTextStyles.antiqueSection),
              const Spacer(),
              IconButton(
                tooltip: '新增配置',
                onPressed: viewModel.startCreatingProfile,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '列表中的每一项都是一套完整的接口参数。点击即可切换并载入编辑。',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 12),
          if (viewModel.profiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danjin.withOpacity(0.6)),
              ),
              child: Text(
                '还没有保存的 AI 配置，点击右上角加号新建。',
                style: AppTextStyles.antiqueBody.copyWith(
                  color: AppColors.guhe,
                ),
              ),
            )
          else
            ...viewModel.profiles.map(
              (profile) => AISettingsProfileTile(
                viewModel: viewModel,
                profile: profile,
              ),
            ),
        ],
      ),
    );
  }
}

class AISettingsProfileTile extends StatelessWidget {
  const AISettingsProfileTile({
    super.key,
    required this.viewModel,
    required this.profile,
  });

  final AISettingsViewModel viewModel;
  final AIProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    final isActive = profile.id == viewModel.activeProfileId;
    final isEditing = profile.id == viewModel.editingProfileId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('ai_profile_tile_${profile.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: viewModel.isSaving
            ? null
            : () => viewModel.activateProfile(profile),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEditing
                ? AppColors.dailan.withOpacity(0.08)
                : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? AppColors.dailan
                  : AppColors.danjin.withOpacity(0.6),
              width: isActive ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isActive ? AppColors.dailan : AppColors.guhe,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppTextStyles.antiqueBody),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.baseUrl ?? '官方默认地址'} · ${profile.model}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.antiqueLabel,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '使用中',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ),
              IconButton(
                key: ValueKey('ai_delete_profile_${profile.id}'),
                tooltip: '删除',
                onPressed: viewModel.isSaving
                    ? null
                    : () => _confirmDelete(context, viewModel, profile),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AISettingsViewModel viewModel,
    AIProviderProfile profile,
  ) async {
    final confirmed = await showAntiqueDialog<bool>(
          context: context,
          title: '删除配置',
          content: Text(
            '确认删除「${profile.name}」吗？',
            style: AppTextStyles.antiqueBody,
          ),
          actions: [
            AntiqueButton(
              label: '取消',
              onPressed: () => Navigator.of(context).pop(false),
              variant: AntiqueButtonVariant.ghost,
            ),
            AntiqueButton(
              label: '删除',
              onPressed: () => Navigator.of(context).pop(true),
              variant: AntiqueButtonVariant.danger,
            ),
          ],
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }
    await viewModel.deleteProfile(profile);
  }
}

class AISettingsEditorCard extends StatelessWidget {
  const AISettingsEditorCard({
    super.key,
    required this.viewModel,
    required this.presets,
  });

  final AISettingsViewModel viewModel;
  final List<AIPreset> presets;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.editingProfileId == null ? '新增配置' : '编辑配置',
            style: AppTextStyles.antiqueSection,
          ),
          const SizedBox(height: 4),
          Text(
            '支持 OpenAI、DeepSeek、Gemini OpenAI 兼容层等接口。',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 12),
          Text('配置名称', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            key: const ValueKey('ai_profile_name_field'),
            controller: viewModel.profileNameController,
            hint: '例如：DeepSeek 主力 / Gemini 备用 / OpenAI 官方',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              return ActionChip(
                avatar: Icon(preset.icon, size: 16),
                label: Text(
                  preset.name,
                  style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => viewModel.applyPreset(
                  name: preset.name,
                  baseUrl: preset.baseUrl,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('API 地址', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            key: const ValueKey('ai_base_url_field'),
            controller: viewModel.baseUrlController,
            hint: '如：https://api.deepseek.com/v1',
          ),
          const SizedBox(height: 16),
          Text('API Key', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            key: const ValueKey('ai_api_key_field'),
            controller: viewModel.apiKeyController,
            hint: '输入 API Key，可直接修改',
            obscureText: viewModel.obscureApiKey,
            obscuringCharacter: '•',
            textAlignVertical: TextAlignVertical.center,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              splashRadius: 18,
              iconSize: 18,
              icon: Icon(
                viewModel.obscureApiKey
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: viewModel.toggleObscureApiKey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('模型', style: AppTextStyles.antiqueLabel),
              const Spacer(),
              InkWell(
                key: const ValueKey('ai_fetch_models_button'),
                borderRadius: BorderRadius.circular(999),
                onTap:
                    viewModel.isFetchingModels ? null : viewModel.fetchModels,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (viewModel.isFetchingModels)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.zhusha,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh,
                          size: 16,
                          color: AppColors.zhusha,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        viewModel.isFetchingModels ? '获取中' : '获取模型',
                        style: AppTextStyles.antiqueLabel.copyWith(
                          color: viewModel.isFetchingModels
                              ? AppColors.qianhe
                              : AppColors.zhusha,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AntiqueTextField(
            key: const ValueKey('ai_model_field'),
            controller: viewModel.modelController,
            hint: '如：gpt-4.1 / deepseek-chat / qwen-plus / llama3.1',
          ),
          if (viewModel.availableModels.isNotEmpty &&
              viewModel.selectedAvailableModel != null) ...[
            const SizedBox(height: 12),
            Text('快速选择', style: AppTextStyles.antiqueLabel),
            const SizedBox(height: 6),
            AntiqueDropdown<String>(
              value: viewModel.selectedAvailableModel!,
              items: viewModel.availableModels
                  .map(
                    (model) => AntiqueDropdownItem<String>(
                      value: model,
                      label: model,
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                viewModel.selectAvailableModel(value);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class AISettingsValidationCard extends StatelessWidget {
  const AISettingsValidationCard({
    super.key,
    required this.viewModel,
  });

  final AISettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isSuccess = viewModel.validationSuccess == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.validationMessage!,
              style: TextStyle(color: isSuccess ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class AISettingsSaveButton extends StatelessWidget {
  const AISettingsSaveButton({
    super.key,
    required this.viewModel,
  });

  final AISettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AntiqueButton(
      key: const ValueKey('ai_save_button'),
      label: viewModel.isSaving ? '保存中...' : '保存配置',
      onPressed: viewModel.isSaving ? null : viewModel.saveCurrentProfile,
      icon: viewModel.isSaving ? null : Icons.save,
      variant: AntiqueButtonVariant.primary,
      fullWidth: true,
    );
  }
}
