import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../ai/config/ai_config_manager.dart';
import '../../../ai/template/prompt_template.dart' as tmpl;

abstract class PromptTemplateSettingsService {
  Future<List<tmpl.PromptTemplate>> getAllTemplates();
  Future<void> saveTemplate(tmpl.PromptTemplate template);
}

class AIConfigPromptTemplateSettingsService
    implements PromptTemplateSettingsService {
  AIConfigPromptTemplateSettingsService(this._configManager);

  final AIConfigManager _configManager;

  @override
  Future<List<tmpl.PromptTemplate>> getAllTemplates() {
    return _configManager.getAllTemplates();
  }

  @override
  Future<void> saveTemplate(tmpl.PromptTemplate template) {
    return _configManager.saveTemplate(template);
  }
}

class PromptTemplateSettingsViewModel extends ChangeNotifier {
  PromptTemplateSettingsViewModel({
    required PromptTemplateSettingsService? service,
  }) : _service = service;

  final PromptTemplateSettingsService? _service;
  final List<tmpl.PromptTemplate> _templates = [];

  bool _isLoading = false;
  bool _initialized = false;
  bool _disposed = false;
  String? _errorMessage;

  PromptTemplateSettingsService? get service => _service;
  bool get serviceAvailable => _service != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UnmodifiableListView<tmpl.PromptTemplate> get templates =>
      UnmodifiableListView(_templates);

  Map<String, List<tmpl.PromptTemplate>> get groupedTemplates {
    final grouped = <String, List<tmpl.PromptTemplate>>{};
    for (final template in _templates) {
      grouped.putIfAbsent(template.systemType, () => []).add(template);
    }
    return LinkedHashMap<String, List<tmpl.PromptTemplate>>.from(grouped);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await loadTemplates();
  }

  Future<void> loadTemplates() async {
    final service = _service;
    if (service == null) {
      _templates.clear();
      _errorMessage = null;
      _notify();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final templates = await service.getAllTemplates();
      if (_disposed) {
        return;
      }
      _templates
        ..clear()
        ..addAll(templates);
    } catch (e) {
      if (_disposed) {
        return;
      }
      _errorMessage = '加载模板失败: $e';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class PromptTemplateEditorViewModel extends ChangeNotifier {
  PromptTemplateEditorViewModel({
    required PromptTemplateSettingsService? service,
    required tmpl.PromptTemplate template,
  })  : _service = service,
        _template = template,
        nameController = TextEditingController(text: template.name),
        contentController = TextEditingController(text: template.content) {
    nameController.addListener(_handleFieldChanged);
    contentController.addListener(_handleFieldChanged);
  }

  final PromptTemplateSettingsService? _service;
  final tmpl.PromptTemplate _template;

  final TextEditingController nameController;
  final TextEditingController contentController;

  bool _hasChanges = false;
  bool _isSaving = false;
  bool _disposed = false;
  String? _errorMessage;

  tmpl.PromptTemplate get template => _template;
  bool get serviceAvailable => _service != null;
  bool get hasChanges => _hasChanges;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get canSave =>
      !_isSaving && _hasChanges && nameController.text.trim().isNotEmpty;

  Future<bool> save() async {
    final service = _service;
    if (service == null) {
      _setError('AI 模块尚未初始化完成');
      return false;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _setError('请输入模板名称');
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _notify();

    try {
      final updated = tmpl.PromptTemplate(
        id: _template.id,
        name: name,
        description: _template.description,
        systemType: _template.systemType,
        templateType: _template.templateType,
        content: contentController.text,
        variablesJson: _template.variablesJson,
        isBuiltIn: _template.isBuiltIn,
        isActive: _template.isActive,
        createdAt: _template.createdAt,
        updatedAt: DateTime.now(),
      );
      await service.saveTemplate(updated);
      if (_disposed) {
        return false;
      }
      _hasChanges = false;
      return true;
    } catch (e) {
      if (_disposed) {
        return false;
      }
      _setError('保存失败: $e', notify: false);
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  void _handleFieldChanged() {
    final hasChanges = nameController.text.trim() != _template.name.trim() ||
        contentController.text != _template.content;
    if (_hasChanges == hasChanges) {
      return;
    }
    _hasChanges = hasChanges;
    _notify();
  }

  void _setError(String message, {bool notify = true}) {
    _errorMessage = message;
    if (notify) {
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
