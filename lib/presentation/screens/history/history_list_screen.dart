import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../widgets/antique/antique.dart';
import 'history_filter.dart';

/// 历史记录列表页面
///
/// 显示所有术数系统的历史记录，支持筛选和搜索。
///
/// 当 [chromeless] 为 true 时，直接返回内容区域（无 AntiqueScaffold /
/// AntiqueAppBar），适合内嵌在已有页面骨架中（如 HomeScreen Tab）。
class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key, this.chromeless = false});

  /// 无 Scaffold 模式：内嵌时设为 true，避免双重 Scaffold / AppBar。
  final bool chromeless;

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  List<DivinationResult> _records = [];
  List<DivinationResult> _filteredRecords = [];
  bool _isLoading = true;
  String? _errorMessage;
  DivinationType? _selectedSystemType;

  // 搜索状态
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // 排序状态
  SortOrder _sortOrder = SortOrder.newestFirst;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// 系统类型筛选入口（薄包装，统一调用 _applyFilters）。
  void _filterBySystemType(DivinationType? systemType) {
    _selectedSystemType = systemType;
    _applyFilters();
  }

  /// 统一应用系统筛选 + 关键字搜索 + 排序，更新 _filteredRecords。
  void _applyFilters() {
    Iterable<DivinationResult> result = _records;

    // 系统筛选
    if (_selectedSystemType != null) {
      result = result.where((r) => r.systemType == _selectedSystemType);
    }

    // 搜索
    final filtered = applySearch<DivinationResult>(
      result.toList(),
      query: _searchQuery,
      extractor: (r) =>
          '${r.systemType.displayName} ${r.getSummary()} ${r.castMethod.displayName}',
    );

    // 排序
    final sorted = applySort<DivinationResult>(
      filtered,
      order: _sortOrder,
      timeExtractor: (r) => r.castTime,
    );

    setState(() {
      _filteredRecords = sorted;
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
    final confirmed = await showAntiqueDialog<bool>(
      context: context,
      title: '确认删除',
      content: Text(
        '确定要删除这条记录吗？\n\n${record.getSummary()}',
        style: AppTextStyles.antiqueBody,
      ),
      actions: [
        AntiqueButton(
          label: '取消',
          variant: AntiqueButtonVariant.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
        AntiqueButton(
          label: '删除',
          variant: AntiqueButtonVariant.danger,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true) {
      await _deleteRecord(record.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chromeless) {
      // 内嵌模式：直接返回内容，不包裹 AntiqueScaffold / AntiqueAppBar。
      return SafeArea(child: _buildBody());
    }

    return AntiqueScaffold(
      appBar: AntiqueAppBar(
        title: '历史记录',
        actions: [
          // 筛选按钮
          PopupMenuButton<DivinationType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            onSelected: _filterBySystemType,
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
              color: AppColors.zhushaLight,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.antiqueBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AntiqueButton(
              label: '重试',
              icon: Icons.refresh,
              onPressed: _loadRecords,
              variant: AntiqueButtonVariant.ghost,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 搜索框（加载与错误之外始终显示，方便用户清除搜索）
        _buildSearchField(),

        // 排序切换
        _buildSortToggle(),

        // 筛选提示
        if (_selectedSystemType != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.xiangseDeep,
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: AppColors.guhe,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '筛选: ${_selectedSystemType!.displayName} (${_filteredRecords.length} 条)',
                    style: AppTextStyles.antiqueLabel.copyWith(
                      color: AppColors.guhe,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _filterBySystemType(null),
                  child: const Text('清除'),
                ),
              ],
            ),
          ),

        // 内容区：空状态或记录列表
        Expanded(
          child: _filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AntiqueWatermark(char: '空'),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppColors.qianhe,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '未找到匹配记录'
                            : _selectedSystemType == null
                                ? '暂无历史记录'
                                : '暂无 ${_selectedSystemType!.displayName} 记录',
                        style: AppTextStyles.antiqueSection.copyWith(
                          color: AppColors.guhe,
                        ),
                      ),
                      if (_selectedSystemType != null) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => _filterBySystemType(null),
                          child: const Text('查看全部记录'),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: _buildGroupedList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AntiqueTextField(
        controller: _searchController,
        hint: '搜索问事、卦名、术数...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildSortToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text('排序: ', style: AppTextStyles.antiqueLabel),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_sortOrder != SortOrder.newestFirst) {
                setState(() {
                  _sortOrder = SortOrder.newestFirst;
                });
                _applyFilters();
              }
            },
            child: AntiqueTag(
              label: '最新',
              color: _sortOrder == SortOrder.newestFirst
                  ? AppColors.zhusha
                  : AppColors.guhe,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_sortOrder != SortOrder.oldestFirst) {
                setState(() {
                  _sortOrder = SortOrder.oldestFirst;
                });
                _applyFilters();
              }
            },
            child: AntiqueTag(
              label: '最早',
              color: _sortOrder == SortOrder.oldestFirst
                  ? AppColors.zhusha
                  : AppColors.guhe,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final groups = groupByTime<DivinationResult>(
      _filteredRecords,
      now: DateTime.now(),
      timeExtractor: (r) => r.castTime,
    );

    final groupOrder = <TimeGroup>[
      TimeGroup.today,
      TimeGroup.lastSevenDays,
      TimeGroup.earlier,
    ];

    final sections = <Widget>[];

    for (var groupIdx = 0; groupIdx < groupOrder.length; groupIdx++) {
      final group = groupOrder[groupIdx];
      final items = groups[group]!;
      if (items.isEmpty) continue;

      // Section header
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: AntiqueSectionTitle(title: timeGroupLabel(group)),
        ),
      );

      // Records in this group
      for (final record in items) {
        sections.add(_buildHistoryCard(record));
      }

      // Divider between groups (not after the last non-empty group)
      final hasMoreGroups = groupOrder
          .sublist(groupIdx + 1)
          .any((g) => (groups[g] ?? []).isNotEmpty);
      if (hasMoreGroups) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AntiqueDivider(),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: sections,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AntiqueCard(
        onTap: () => _navigateToDetail(record),
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(
            record.getSummary(),
            style: AppTextStyles.antiqueBody,
          ),
          subtitle: Text(
            '${record.systemType.displayName} · ${_formatDateTime(record.castTime)}',
            style: AppTextStyles.antiqueLabel,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(record),
          ),
        ),
      ),
    );
  }

  /// 导航到详情页面
  void _navigateToDetail(DivinationResult record) {
    final uiRegistry = DivinationUIRegistry();
    final resultScreen = uiRegistry.buildResultScreen(record);

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => resultScreen),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
