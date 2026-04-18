import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ai/service/ai_analysis_service.dart';
import '../../../ai/providers/openai_compatible_provider.dart';
import '../../../ai/llm_provider_registry.dart';
import '../../../ai/ai_bootstrap.dart';
import '../../../ai/template/prompt_template.dart' as tmpl;
import '../../widgets/antique/antique.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// AI 设置页面
///
/// 配置 OpenAI 兼容接口的 API 地址、Key 和模型。
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  static const _presets = [
    _Preset('OpenAI', 'https://api.openai.com/v1', Icons.cloud),
    _Preset('DeepSeek', 'https://api.deepseek.com/v1', Icons.auto_awesome),
    _Preset('Gemini', 'https://generativelanguage.googleapis.com/v1beta/openai/', Icons.diamond),
    _Preset('Ollama', 'http://localhost:11434/v1', Icons.computer),
  ];

  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();

  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isValidating = false;
  bool _isFetchingModels = false;
  bool _obscureApiKey = true;
  String? _validationMessage;
  bool? _validationSuccess;
  List<tmpl.PromptTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    if (!AIBootstrap.isInitialized) return;
    final templates = await AIBootstrap.configManager.getAllTemplates();
    setState(() => _templates = templates);
  }

  void _loadCurrentConfig() {
    final provider = LLMProviderRegistry.instance
        .getProvider('openai_compatible') as OpenAICompatibleProvider?;
    if (provider != null) {
      final config = provider.getConfigInfo();
      if (config != null) {
        _selectedModel = config['model'] as String?;
        _baseUrlController.text = config['baseUrl'] as String? ?? '';
      }
      if (provider.supportedModels.length > 1) {
        _availableModels = provider.supportedModels;
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '请先输入 API Key';
      });
      return;
    }

    setState(() {
      _isFetchingModels = true;
      _validationMessage = null;
    });

    try {
      // 创建临时 provider 获取模型
      final provider = OpenAICompatibleProvider();
      provider.updateConfig(OpenAICompatibleConfig(
        apiKey: apiKey,
        baseUrl: baseUrl.isNotEmpty ? baseUrl : null,
        model: _selectedModel ?? 'gpt-3.5-turbo',
      ));

      final models = await provider.fetchModels();

      setState(() {
        _availableModels = models;
        if (models.isNotEmpty && _selectedModel == null) {
          _selectedModel = models.first;
        }
        _validationSuccess = models.isNotEmpty;
        _validationMessage = models.isNotEmpty
            ? '获取到 ${models.length} 个模型'
            : '未获取到模型，请检查 API 地址和 Key';
      });
    } catch (e) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '获取模型失败: $e';
      });
    } finally {
      setState(() => _isFetchingModels = false);
    }
  }

  Future<void> _saveConfig() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '请输入 API Key';
      });
      return;
    }
    if (_selectedModel == null || _selectedModel!.isEmpty) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '请先获取模型列表并选择模型';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      final aiService = context.read<AIAnalysisService?>();
      if (aiService == null) return;

      final baseUrl = _baseUrlController.text.trim();

      await aiService.configureProvider(
        providerId: 'openai_compatible',
        apiKey: apiKey,
        config: {
          'model': _selectedModel,
          'baseUrl': baseUrl.isNotEmpty ? baseUrl : null,
        },
      );

      final isValid = await aiService.validateProvider('openai_compatible');

      setState(() {
        _validationSuccess = isValid;
        _validationMessage = isValid ? '配置保存成功，API 连接正常' : '配置已保存，但连接验证失败';
      });
    } catch (e) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '保存失败: $e';
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      appBar: const AntiqueAppBar(title: 'AI 设置'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConfigCard(),
            const SizedBox(height: 16),
            _buildModelCard(),
            const SizedBox(height: 16),
            if (_validationMessage != null) ...[
              _buildValidationCard(),
              const SizedBox(height: 16),
            ],
            _buildSaveButton(),
            const SizedBox(height: 24),
            _buildTemplatesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('接口配置', style: AppTextStyles.antiqueSection),
          const SizedBox(height: 4),
          Text(
            '支持 OpenAI、DeepSeek、通义千问、Ollama 等兼容接口',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 12),

          // 预设模板
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              return ActionChip(
                avatar: Icon(p.icon, size: 16),
                label: Text(p.name, style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _baseUrlController.text = p.baseUrl;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // API 地址
          Text('API 地址', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            controller: _baseUrlController,
            hint: '如：https://api.deepseek.com/v1',
          ),
          const SizedBox(height: 16),

          // API Key
          Text('API Key', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            controller: _apiKeyController,
            hint: '输入 API Key',
            obscureText: _obscureApiKey,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _obscureApiKey = !_obscureApiKey);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('模型选择', style: AppTextStyles.antiqueSection),
              const Spacer(),
              AntiqueButton(
                label: _isFetchingModels ? '获取中...' : '获取模型',
                onPressed: _isFetchingModels ? null : _fetchModels,
                icon: _isFetchingModels ? null : Icons.refresh,
                variant: AntiqueButtonVariant.ghost,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_availableModels.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '请填写 API 地址和 Key 后点击「获取模型」',
                  style: TextStyle(
                    color: AppColors.guhe,
                    fontSize: 13,
                    fontFamily: AppTextStyles.fontFamilySong,
                    fontFamilyFallback: AppTextStyles.fontFamilyFallback,
                  ),
                ),
              ),
            )
          else ...[
            Text('选择模型', style: AppTextStyles.antiqueLabel),
            const SizedBox(height: 6),
            AntiqueDropdown<String>(
              value: (_availableModels.contains(_selectedModel)
                  ? _selectedModel
                  : _availableModels.first)!,
              items: _availableModels
                  .map((model) => AntiqueDropdownItem<String>(
                        value: model,
                        label: model,
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedModel = value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationCard() {
    final isSuccess = _validationSuccess == true;
    // Semantic status colors retained inline (green = success, red = error).
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
              _validationMessage!,
              // 语义状态色：validation 成功/失败
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AntiqueButton(
      label: _isValidating ? '保存中...' : '保存配置',
      onPressed: _isValidating ? null : _saveConfig,
      icon: _isValidating ? null : Icons.save,
      variant: AntiqueButtonVariant.primary,
      fullWidth: true,
    );
  }

  Widget _buildTemplatesCard() {
    // 按系统分组
    final grouped = <String, List<tmpl.PromptTemplate>>{};
    for (final t in _templates) {
      grouped.putIfAbsent(t.systemType, () => []).add(t);
    }

    const systemNames = {
      'liuyao': '六爻',
      'daliuren': '大六壬',
      'meihua': '梅花易数',
      'xiaoliuren': '小六壬',
    };

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('提示词模板', style: AppTextStyles.antiqueSection),
          const SizedBox(height: 4),
          Text(
            '管理各术数系统的 AI 分析提示词',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 12),
          if (_templates.isEmpty)
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
              final name = systemNames[entry.key] ?? entry.key;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      name,
                      style: AppTextStyles.antiqueBody.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.guhe,
                      ),
                    ),
                  ),
                  ...entry.value.map((t) => _buildTemplateTile(t)),
                  const AntiqueDivider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTemplateTile(tmpl.PromptTemplate template) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        template.isBuiltIn ? Icons.lock_outline : Icons.edit_note,
        color: template.isActive ? AppColors.dailan : AppColors.qianhe,
        size: 20,
      ),
      title: Text(
        template.name,
        style: AppTextStyles.antiqueBody,
      ),
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
                // 语义状态色：使用中/未使用指示
                style: TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: () => _openTemplateEditor(template),
    );
  }

  Future<void> _openTemplateEditor(tmpl.PromptTemplate template) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => _TemplateEditorScreen(template: template),
      ),
    );
    if (result == true) {
      _loadTemplates();
    }
  }
}

/// 模板编辑页面
class _TemplateEditorScreen extends StatefulWidget {
  final tmpl.PromptTemplate template;

  const _TemplateEditorScreen({required this.template});

  @override
  State<_TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<_TemplateEditorScreen> {
  late TextEditingController _contentController;
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _contentController = TextEditingController(text: widget.template.content);
    _contentController.addListener(() => setState(() => _hasChanges = true));
    _nameController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _contentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = tmpl.PromptTemplate(
        id: widget.template.id,
        name: _nameController.text.trim(),
        description: widget.template.description,
        systemType: widget.template.systemType,
        templateType: widget.template.templateType,
        content: _contentController.text,
        variablesJson: widget.template.variablesJson,
        isBuiltIn: widget.template.isBuiltIn,
        isActive: widget.template.isActive,
        createdAt: widget.template.createdAt,
        updatedAt: DateTime.now(),
      );
      await AIBootstrap.configManager.saveTemplate(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已保存')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      appBar: AntiqueAppBar(
        title: '编辑模板',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AntiqueButton(
              label: _isSaving ? '保存中...' : '保存',
              onPressed: _hasChanges && !_isSaving ? _save : null,
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
            // 模板名称
            Text('模板名称', style: AppTextStyles.antiqueLabel),
            const SizedBox(height: 6),
            AntiqueTextField(
              controller: _nameController,
              hint: '输入模板名称',
            ),
            const SizedBox(height: 8),
            // 类型标签
            Row(
              children: [
                AntiqueTag(label: widget.template.type.displayName),
                if (widget.template.isBuiltIn) ...[
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
            // 模板内容编辑器（多行展开）
            Expanded(
              child: AntiqueTextField(
                controller: _contentController,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                // domain：模板代码 monospace 预览
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
  }
}

/// API 预设模板
class _Preset {
  final String name;
  final String baseUrl;
  final IconData icon;

  const _Preset(this.name, this.baseUrl, this.icon);
}
