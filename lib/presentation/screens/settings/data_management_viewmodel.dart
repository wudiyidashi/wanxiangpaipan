import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/divination_system.dart';
import '../../../domain/services/data_management_service.dart';

abstract class DataManagementActionsService {
  bool get isAIModuleAvailable;

  Future<DataManagementSummary> loadSummary();
  Future<int> clearHistoryBySystem(DivinationType systemType);
  Future<int> clearHistoryBefore(DateTime beforeTime);
  Future<int> clearAllHistory();
  Future<int> clearAllAIProfiles();
  Future<int> restoreDefaultPromptTemplates();
  Future<BackupExportResult> exportBackup();
  Future<BackupImportPreview> inspectBackup(File file);
  Future<BackupImportResult> importBackup(
    File file, {
    required BackupImportMode mode,
  });
}

class DefaultDataManagementActionsService
    implements DataManagementActionsService {
  DefaultDataManagementActionsService(this._service);

  final DataManagementService _service;

  @override
  bool get isAIModuleAvailable => _service.isAIModuleAvailable;

  @override
  Future<int> clearAllAIProfiles() => _service.clearAllAIProfiles();

  @override
  Future<int> clearAllHistory() => _service.clearAllHistory();

  @override
  Future<int> clearHistoryBefore(DateTime beforeTime) {
    return _service.clearHistoryBefore(beforeTime);
  }

  @override
  Future<int> clearHistoryBySystem(DivinationType systemType) {
    return _service.clearHistoryBySystem(systemType);
  }

  @override
  Future<BackupExportResult> exportBackup() => _service.exportBackup();

  @override
  Future<BackupImportPreview> inspectBackup(File file) {
    return _service.inspectBackup(file);
  }

  @override
  Future<BackupImportResult> importBackup(
    File file, {
    required BackupImportMode mode,
  }) {
    return _service.importBackup(file, mode: mode);
  }

  @override
  Future<DataManagementSummary> loadSummary() => _service.loadSummary();

  @override
  Future<int> restoreDefaultPromptTemplates() {
    return _service.restoreDefaultPromptTemplates();
  }
}

class DataManagementViewModel extends ChangeNotifier {
  DataManagementViewModel({
    required DataManagementActionsService? service,
  }) : _service = service;

  final DataManagementActionsService? _service;

  DataManagementSummary? _summary;
  bool _isLoading = true;
  bool _initialized = false;
  bool _disposed = false;
  String? _busyKey;
  String? _errorMessage;

  DataManagementActionsService? get service => _service;
  DataManagementSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get busyKey => _busyKey;
  String? get errorMessage => _errorMessage;
  bool get serviceAvailable => _service != null;
  bool get isAIModuleAvailable => _service?.isAIModuleAvailable ?? false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await loadSummary();
  }

  Future<void> loadSummary() async {
    final service = _service;
    if (service == null) {
      _summary = null;
      _isLoading = false;
      _errorMessage = null;
      _notify();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _summary = await service.loadSummary();
    } catch (e) {
      if (_disposed) {
        return;
      }
      _errorMessage = '加载数据概览失败: $e';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<String> clearHistoryBySystem(DivinationType systemType) async {
    final count = await _runCountAction(
      actionKey: 'clear_${systemType.id}',
      action: () => _requireService().clearHistoryBySystem(systemType),
    );
    return '已删除 $count 条${systemType.displayName}记录';
  }

  Future<String> clearHistoryBefore(DateTime beforeTime) async {
    final count = await _runCountAction(
      actionKey: 'clear_before_30',
      action: () => _requireService().clearHistoryBefore(beforeTime),
    );
    return '已删除 $count 条 30 天前记录';
  }

  Future<String> clearAllHistory() async {
    final count = await _runCountAction(
      actionKey: 'clear_history_all',
      action: _requireService().clearAllHistory,
    );
    return '已清空 $count 条历史记录';
  }

  Future<String> clearAllAIProfiles() async {
    final count = await _runCountAction(
      actionKey: 'clear_ai_profiles',
      action: _requireService().clearAllAIProfiles,
    );
    return '已删除 $count 套 AI 接口配置';
  }

  Future<String> restoreDefaultPromptTemplates() async {
    final count = await _runCountAction(
      actionKey: 'restore_templates',
      action: _requireService().restoreDefaultPromptTemplates,
    );
    return '已重置模板，共处理 $count 条';
  }

  Future<BackupExportResult> exportBackup() async {
    final result = await _runTask(
      actionKey: 'export_backup',
      task: _requireService().exportBackup,
    );
    await loadSummary();
    return result;
  }

  Future<BackupImportPreview> inspectBackup(File file) {
    return _requireService().inspectBackup(file);
  }

  Future<BackupImportResult> importBackup(
    File file, {
    required BackupImportMode mode,
  }) async {
    final result = await _runTask(
      actionKey: 'import_backup',
      task: () => _requireService().importBackup(file, mode: mode),
    );
    await loadSummary();
    return result;
  }

  DataManagementActionsService _requireService() {
    final service = _service;
    if (service == null) {
      throw StateError('数据服务尚未初始化完成');
    }
    return service;
  }

  Future<int> _runCountAction({
    required String actionKey,
    required Future<int> Function() action,
  }) async {
    final count = await _runTask(actionKey: actionKey, task: action);
    await loadSummary();
    return count;
  }

  Future<T> _runTask<T>({
    required String actionKey,
    required Future<T> Function() task,
  }) async {
    _busyKey = actionKey;
    _errorMessage = null;
    _notify();

    try {
      return await task();
    } catch (e) {
      if (!_disposed) {
        _errorMessage = '操作失败: $e';
      }
      rethrow;
    } finally {
      _busyKey = null;
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
