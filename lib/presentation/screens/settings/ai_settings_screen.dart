import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ai/service/ai_analysis_service.dart';
import '../../../ai/providers/gemini_provider.dart';
import '../../../ai/llm_provider.dart';

/// AI 设置页面
///
/// 配置 LLM 提供者的 API Key 和其他设置。
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();

  String _selectedModel = 'gemini-1.5-flash';
  bool _isValidating = false;
  bool _obscureApiKey = true;
  String? _validationMessage;
  bool? _validationSuccess;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final aiService = context.read<AIAnalysisService?>();
    if (aiService != null) {
      final provider = aiService.defaultProvider;
      if (provider != null) {
        final config = provider.getConfigInfo();
        if (config != null) {
          _selectedModel = config['model'] as String? ?? 'gemini-1.5-flash';
          _baseUrlController.text = config['baseUrl'] as String? ?? '';
        }
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIAnalysisService?>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
        centerTitle: true,
      ),
      body: aiService == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProviderSection(aiService),
                    const SizedBox(height: 24),
                    _buildConfigSection(),
                    const SizedBox(height: 24),
                    _buildValidationSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(aiService),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProviderSection(AIAnalysisService aiService) {
    final providers = aiService.getProvidersInfo();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LLM 提供者',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...providers.map((p) => _buildProviderTile(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(LLMProviderInfo provider) {
    final isConfigured = provider.isConfigured;
    final statusColor = switch (provider.status) {
      LLMProviderStatus.valid => Colors.green,
      LLMProviderStatus.configured => Colors.orange,
      LLMProviderStatus.invalid => Colors.red,
      _ => Colors.grey,
    };

    return ListTile(
      leading: Icon(
        Icons.smart_toy,
        color: isConfigured ? Colors.blue : Colors.grey,
      ),
      title: Text(provider.displayName),
      subtitle: Text(provider.description),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          provider.status.displayName,
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemini 配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // API Key
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: '输入 Google AI Studio API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
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
            const SizedBox(height: 16),

            // 模型选择
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: '模型',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'gemini-2.0-flash-exp',
                  child: Text('Gemini 2.0 Flash (实验版)'),
                ),
                DropdownMenuItem(
                  value: 'gemini-1.5-flash',
                  child: Text('Gemini 1.5 Flash'),
                ),
                DropdownMenuItem(
                  value: 'gemini-1.5-flash-8b',
                  child: Text('Gemini 1.5 Flash 8B'),
                ),
                DropdownMenuItem(
                  value: 'gemini-1.5-pro',
                  child: Text('Gemini 1.5 Pro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedModel = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // 自定义 API 地址（可选）
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'API 地址（可选）',
                hintText: '留空使用默认地址，或输入代理地址',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSection() {
    if (_validationMessage == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: _validationSuccess == true
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _validationSuccess == true ? Icons.check_circle : Icons.error,
              color: _validationSuccess == true ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _validationMessage!,
                style: TextStyle(
                  color: _validationSuccess == true ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(AIAnalysisService aiService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isValidating ? null : () => _validateAndSave(aiService),
          icon: _isValidating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isValidating ? '验证中...' : '保存配置'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isValidating ? null : () => _testConnection(aiService),
          icon: const Icon(Icons.science),
          label: const Text('测试连接'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _validateAndSave(AIAnalysisService aiService) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      await aiService.configureProvider(
        providerId: 'gemini',
        apiKey: _apiKeyController.text.trim(),
        config: {
          'model': _selectedModel,
          'baseUrl': _baseUrlController.text.trim().isEmpty
              ? null
              : _baseUrlController.text.trim(),
        },
      );

      final isValid = await aiService.validateProvider('gemini');

      setState(() {
        _validationSuccess = isValid;
        _validationMessage = isValid ? '配置保存成功，API 连接正常' : '配置已保存，但 API 连接失败，请检查 API Key';
      });
    } catch (e) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '保存失败: $e';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _testConnection(AIAnalysisService aiService) async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '请先输入 API Key';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      // 临时配置并测试
      await aiService.configureProvider(
        providerId: 'gemini',
        apiKey: _apiKeyController.text.trim(),
        config: {
          'model': _selectedModel,
          'baseUrl': _baseUrlController.text.trim().isEmpty
              ? null
              : _baseUrlController.text.trim(),
        },
      );

      final isValid = await aiService.validateProvider('gemini');

      setState(() {
        _validationSuccess = isValid;
        _validationMessage = isValid ? 'API 连接成功' : 'API 连接失败，请检查 API Key 或网络';
      });
    } catch (e) {
      setState(() {
        _validationSuccess = false;
        _validationMessage = '测试失败: $e';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
}
