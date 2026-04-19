import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/route_observer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../widgets/antique/antique.dart';
import 'history_filter.dart';
import 'history_list_viewmodel.dart';

/// 历史记录列表页面
///
/// 显示所有术数系统的历史记录，支持筛选和搜索。
///
/// 当 [chromeless] 为 true 时，直接返回内容区域（无 AntiqueScaffold /
/// AntiqueAppBar），适合内嵌在已有页面骨架中（如 HomeScreen Tab）。
class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({
    super.key,
    this.chromeless = false,
    HistoryListViewModel? viewModel,
    DivinationUIRegistry? uiRegistry,
  })  : _viewModel = viewModel,
        _uiRegistry = uiRegistry;

  /// 无 Scaffold 模式：内嵌时设为 true，避免双重 Scaffold / AppBar。
  final bool chromeless;
  final HistoryListViewModel? _viewModel;
  final DivinationUIRegistry? _uiRegistry;

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();

  HistoryListViewModel? _viewModel;
  bool _ownsViewModel = false;
  bool _routeSubscribed = false;

  DivinationUIRegistry get _uiRegistry =>
      widget._uiRegistry ?? DivinationUIRegistry();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureViewModel();

    if (widget.chromeless || _routeSubscribed) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_routeSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    if (_ownsViewModel) {
      _viewModel?.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _viewModel?.loadRecords();
  }

  void _ensureViewModel() {
    if (_viewModel != null) {
      return;
    }

    final injectedViewModel = widget._viewModel;
    if (injectedViewModel != null) {
      _viewModel = injectedViewModel;
      _ownsViewModel = false;
    } else {
      _viewModel = HistoryListViewModel(
        service: _buildService(),
      );
      _ownsViewModel = true;
    }

    _searchController.text = _viewModel!.searchQuery;
    _viewModel!.initialize();
  }

  HistoryListService? _buildService() {
    try {
      final repository = context.read<DivinationRepository>();
      return RepositoryHistoryListService(repository);
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted || Scaffold.maybeOf(context) == null) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteRecord(
    String id,
    HistoryListViewModel viewModel,
  ) async {
    try {
      final message = await viewModel.deleteRecord(id);
      _showSnackBar(message);
    } catch (_) {
      _showSnackBar(viewModel.errorMessage ?? '删除失败');
    }
  }

  Future<void> _confirmDelete(
    DivinationResult record,
    HistoryListViewModel viewModel,
  ) async {
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
      await _deleteRecord(record.id, viewModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider<HistoryListViewModel>.value(
      value: viewModel,
      child: Consumer<HistoryListViewModel>(
        builder: (context, vm, _) {
          if (widget.chromeless) {
            return Material(
              color: Colors.transparent,
              child: SafeArea(child: _buildBody(vm)),
            );
          }

          return AntiqueScaffold(
            appBar: AntiqueAppBar(
              title: '历史记录',
              actions: [
                PopupMenuButton<DivinationType?>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: '筛选',
                  onSelected: vm.setSystemType,
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
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: vm.loadRecords,
                ),
              ],
            ),
            body: _buildBody(vm),
          );
        },
      ),
    );
  }

  Widget _buildBody(HistoryListViewModel viewModel) {
    if (viewModel.isLoading) {
      return _buildLoadingState();
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.records.isEmpty) {
      return _buildEmptyHistoryState();
    }

    final statusBar = _buildFilterStatusBar(viewModel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(viewModel),
        _buildSortToggle(viewModel),
        if (statusBar != null) statusBar,
        Expanded(
          child: viewModel.filteredRecords.isEmpty && viewModel.hasActiveFilter
              ? _buildNoSearchResultsState(viewModel)
              : RefreshIndicator(
                  onRefresh: viewModel.loadRecords,
                  child: _buildGroupedList(viewModel),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            '加载中...',
            style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(HistoryListViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.zhushaLight),
            const SizedBox(height: 12),
            Text(
              viewModel.errorMessage ?? '加载失败',
              style: AppTextStyles.antiqueBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AntiqueButton(
              label: '重试',
              icon: Icons.refresh,
              variant: AntiqueButtonVariant.ghost,
              onPressed: viewModel.loadRecords,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AntiqueWatermark(char: '空'),
            const SizedBox(height: 16),
            Text('暂无历史记录', style: AppTextStyles.antiqueSection),
            const SizedBox(height: 8),
            Text(
              '去首页选一种术数起卦吧',
              style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
            ),
            const SizedBox(height: 24),
            AntiqueButton(
              label: '去起卦',
              icon: Icons.auto_awesome,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(HistoryListViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AntiqueWatermark(char: '无'),
            const SizedBox(height: 16),
            Text('没有找到相关记录', style: AppTextStyles.antiqueSection),
            const SizedBox(height: 8),
            Text(
              '试试调整筛选或关键字',
              style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
            ),
            const SizedBox(height: 24),
            AntiqueButton(
              label: '清除筛选',
              icon: Icons.clear,
              variant: AntiqueButtonVariant.ghost,
              onPressed: () {
                _searchController.clear();
                viewModel.clearFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(HistoryListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AntiqueTextField(
        controller: _searchController,
        hint: '搜索问事、卦名、术数...',
        onChanged: viewModel.setSearchQuery,
      ),
    );
  }

  Widget _buildSortToggle(HistoryListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text('排序: ', style: AppTextStyles.antiqueLabel),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => viewModel.setSortOrder(SortOrder.newestFirst),
            child: AntiqueTag(
              label: '最新',
              color: viewModel.sortOrder == SortOrder.newestFirst
                  ? AppColors.zhusha
                  : AppColors.guhe,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => viewModel.setSortOrder(SortOrder.oldestFirst),
            child: AntiqueTag(
              label: '最早',
              color: viewModel.sortOrder == SortOrder.oldestFirst
                  ? AppColors.zhusha
                  : AppColors.guhe,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFilterStatusBar(HistoryListViewModel viewModel) {
    final hasSystemFilter = viewModel.selectedSystemType != null;
    final hasSearch = viewModel.searchQuery.trim().isNotEmpty;
    if (!hasSystemFilter && !hasSearch) {
      return null;
    }

    final fragments = <String>[];
    if (hasSystemFilter) {
      fragments.add('系统: ${viewModel.selectedSystemType!.displayName}');
    }
    if (hasSearch) {
      fragments.add('关键字: "${viewModel.searchQuery.trim()}"');
    }
    fragments.add('共 ${viewModel.filteredRecords.length} 条');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fragments.join(' · '),
              style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              viewModel.clearFilters();
            },
            child: Text(
              '清除',
              style:
                  AppTextStyles.antiqueLabel.copyWith(color: AppColors.zhusha),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(HistoryListViewModel viewModel) {
    final groups = groupByTime<DivinationResult>(
      viewModel.filteredRecords.toList(),
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
      if (items.isEmpty) {
        continue;
      }

      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: AntiqueSectionTitle(title: timeGroupLabel(group)),
        ),
      );

      for (final record in items) {
        sections.add(_buildHistoryCard(record, viewModel));
      }

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

  Widget _buildHistoryCard(
    DivinationResult record,
    HistoryListViewModel viewModel,
  ) {
    final uiFactory = _uiRegistry.tryGetUIFactory(record.systemType);

    if (uiFactory == null) {
      return _buildDefaultCard(record, viewModel);
    }

    final historyCard = uiFactory.buildHistoryCard(record);

    return GestureDetector(
      onTap: () => _navigateToDetail(record),
      onLongPress: () => _confirmDelete(record, viewModel),
      child: historyCard,
    );
  }

  Widget _buildDefaultCard(
    DivinationResult record,
    HistoryListViewModel viewModel,
  ) {
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
            onPressed: () => _confirmDelete(record, viewModel),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(DivinationResult record) {
    final resultScreen = _uiRegistry.buildResultScreen(record);

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => resultScreen),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
