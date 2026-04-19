import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import 'history_filter.dart';

abstract class HistoryListService {
  Future<List<DivinationResult>> getAllRecords();
  Future<int> deleteRecord(String id);
}

class RepositoryHistoryListService implements HistoryListService {
  RepositoryHistoryListService(this._repository);

  final DivinationRepository _repository;

  @override
  Future<int> deleteRecord(String id) => _repository.deleteRecord(id);

  @override
  Future<List<DivinationResult>> getAllRecords() => _repository.getAllRecords();
}

class HistoryListViewModel extends ChangeNotifier {
  HistoryListViewModel({
    required HistoryListService? service,
  }) : _service = service;

  final HistoryListService? _service;

  final List<DivinationResult> _records = [];
  final List<DivinationResult> _filteredRecords = [];

  bool _isLoading = true;
  bool _initialized = false;
  bool _disposed = false;
  String? _errorMessage;
  DivinationType? _selectedSystemType;
  String _searchQuery = '';
  SortOrder _sortOrder = SortOrder.newestFirst;

  bool get serviceAvailable => _service != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DivinationType? get selectedSystemType => _selectedSystemType;
  String get searchQuery => _searchQuery;
  SortOrder get sortOrder => _sortOrder;
  UnmodifiableListView<DivinationResult> get records =>
      UnmodifiableListView(_records);
  UnmodifiableListView<DivinationResult> get filteredRecords =>
      UnmodifiableListView(_filteredRecords);

  bool get hasActiveFilter =>
      _selectedSystemType != null || _searchQuery.trim().isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await loadRecords();
  }

  Future<void> loadRecords() async {
    final service = _service;
    if (service == null) {
      _records.clear();
      _filteredRecords.clear();
      _isLoading = false;
      _errorMessage = null;
      _notify();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final records = await service.getAllRecords();
      if (_disposed) {
        return;
      }
      _records
        ..clear()
        ..addAll(records);
      _applyFilters(notify: false);
    } catch (e) {
      if (_disposed) {
        return;
      }
      _errorMessage = '加载历史记录失败: $e';
      _filteredRecords.clear();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void setSystemType(DivinationType? systemType) {
    _selectedSystemType = systemType;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSortOrder(SortOrder sortOrder) {
    if (_sortOrder == sortOrder) {
      return;
    }
    _sortOrder = sortOrder;
    _applyFilters();
  }

  void clearFilters() {
    _selectedSystemType = null;
    _searchQuery = '';
    _applyFilters();
  }

  Future<String> deleteRecord(String id) async {
    final service = _service;
    if (service == null) {
      throw StateError('历史记录服务尚未初始化完成');
    }

    try {
      await service.deleteRecord(id);
      _records.removeWhere((record) => record.id == id);
      _applyFilters(notify: false);
      _notify();
      return '记录已删除';
    } catch (e) {
      _errorMessage = '删除失败: $e';
      _notify();
      rethrow;
    }
  }

  void _applyFilters({bool notify = true}) {
    Iterable<DivinationResult> result = _records;

    if (_selectedSystemType != null) {
      result = result.where((r) => r.systemType == _selectedSystemType);
    }

    final filtered = applySearch<DivinationResult>(
      result.toList(),
      query: _searchQuery,
      extractor: (r) =>
          '${r.systemType.displayName} ${r.getSummary()} ${r.castMethod.displayName}',
    );

    final sorted = applySort<DivinationResult>(
      filtered,
      order: _sortOrder,
      timeExtractor: (r) => r.castTime,
    );

    _filteredRecords
      ..clear()
      ..addAll(sorted);

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
    super.dispose();
  }
}
