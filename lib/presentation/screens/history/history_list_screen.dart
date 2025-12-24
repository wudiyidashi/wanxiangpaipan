import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../presentation/divination_ui_registry.dart';

/// 历史记录列表页面
///
/// 显示所有术数系统的历史记录，支持筛选和搜索。
class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  List<DivinationResult> _records = [];
  List<DivinationResult> _filteredRecords = [];
  bool _isLoading = true;
  String? _errorMessage;
  DivinationType? _selectedSystemType;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 加载历史记录
  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<DivinationRepository>();
      final records = await repository.getAllRecords();

      setState(() {
        _records = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载历史记录失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 筛选记录
  void _filterRecords(DivinationType? systemType) {
    setState(() {
      _selectedSystemType = systemType;
      if (systemType == null) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records
            .where((record) => record.systemType == systemType)
            .toList();
      }
    });
  }

  /// 删除记录
  Future<void> _deleteRecord(String id) async {
    try {
      final repository = context.read<DivinationRepository>();
      await repository.deleteRecord(id);

      // 从列表中移除
      setState(() {
        _records.removeWhere((record) => record.id == id);
        _filteredRecords.removeWhere((record) => record.id == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 确认删除对话框
  Future<void> _confirmDelete(DivinationResult record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这条记录吗？\n\n${record.getSummary()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecord(record.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          // 筛选按钮
          PopupMenuButton<DivinationType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            onSelected: _filterRecords,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('全部'),
              ),
              const PopupMenuDivider(),
              ...DivinationType.values.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }),
            ],
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRecords,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedSystemType == null
                  ? '暂无历史记录'
                  : '暂无 ${_selectedSystemType!.displayName} 记录',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedSystemType != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _filterRecords(null),
                child: const Text('查看全部记录'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // 筛选提示
        if (_selectedSystemType != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '筛选: ${_selectedSystemType!.displayName} (${_filteredRecords.length} 条)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _filterRecords(null),
                  child: const Text('清除'),
                ),
              ],
            ),
          ),

        // 记录列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRecords,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) {
                final record = _filteredRecords[index];
                return _buildHistoryCard(record);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(DivinationResult record) {
    final uiRegistry = DivinationUIRegistry();
    final uiFactory = uiRegistry.tryGetUIFactory(record.systemType);

    if (uiFactory == null) {
      // 如果没有对应的 UI 工厂，显示默认卡片
      return _buildDefaultCard(record);
    }

    // 使用 UI 工厂构建历史卡片
    final historyCard = uiFactory.buildHistoryCard(record);

    // 包装卡片，添加点击和长按事件
    return GestureDetector(
      onTap: () => _navigateToDetail(record),
      onLongPress: () => _confirmDelete(record),
      child: historyCard,
    );
  }

  Widget _buildDefaultCard(DivinationResult record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome),
        title: Text(record.getSummary()),
        subtitle: Text(
          '${record.systemType.displayName} · ${_formatDateTime(record.castTime)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(record),
        ),
        onTap: () => _navigateToDetail(record),
      ),
    );
  }

  /// 导航到详情页面
  void _navigateToDetail(DivinationResult record) {
    final uiRegistry = DivinationUIRegistry();
    final resultScreen = uiRegistry.buildResultScreen(record);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => resultScreen),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
