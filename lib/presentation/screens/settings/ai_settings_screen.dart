import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ai/service/ai_analysis_service.dart';
import '../../../ai/providers/openai_compatible_provider.dart';
import '../../../ai/llm_provider_registry.dart';
import '../../../ai/ai_bootstrap.dart';
import '../../../ai/template/prompt_template.dart' as tmpl;

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

  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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
        apiKey: _apiKeyController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '接口配置',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '支持 OpenAI、DeepSeek、通义千问、Ollama 等兼容接口',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // 预设模板
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                return ActionChip(
                  avatar: Icon(p.icon, size: 16),
                  label: Text(p.name, style: const TextStyle(fontSize: 12)),
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
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'API 地址',
                hintText: '如：https://api.deepseek.com/v1',
                border: OutlineInputBorder(),
                helperText: 'OpenAI 兼容的 API 地址',
              ),
            ),
            const SizedBox(height: 16),

            // API Key
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: '输入 API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureApiKey = !_obscureApiKey);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 API Key';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '模型选择',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isFetchingModels ? null : _fetchModels,
                  icon: _isFetchingModels
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(_isFetchingModels ? '获取中...' : '获取模型'),
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
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _availableModels.contains(_selectedModel)
                    ? _selectedModel
                    : null,
                decoration: const InputDecoration(
                  labelText: '选择模型',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _availableModels.map((model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(
                      model,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedModel = value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard() {
    final isSuccess = _validationSuccess == true;
    return Card(
      color: isSuccess
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isValidating ? null : _saveConfig,
      icon: _isValidating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(_isValidating ? '保存中...' : '保存配置'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildTemplatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '提示词模板',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '管理 AI 分析使用的提示词模板',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_templates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('暂无模板', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._templates.map((t) => _buildTemplateTile(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateTile(tmpl.PromptTemplate template) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        template.isBuiltIn ? Icons.lock_outline : Icons.edit_note,
        color: template.isActive ? Colors.blue : Colors.grey,
        size: 20,
      ),
      title: Text(
        template.name,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        template.type.displayName,
        style: const TextStyle(fontSize: 12),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑模板'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isSaving ? _save : null,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模板名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '模板名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // 类型标签
            Row(
              children: [
                Chip(
                  label: Text(widget.template.type.displayName),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                if (widget.template.isBuiltIn)
                  const Chip(
                    label: Text('内置'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '模板内容',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              '支持变量：{{variable}}，条件：{{#if}}...{{/if}}，循环：{{#each}}...{{/each}}',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // 模板内容编辑器
            Expanded(
              child: TextFormField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
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
