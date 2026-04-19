import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/route_observer.dart';
import '../../../domain/divination_registry.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/antique/antique.dart';
import '../../widgets/divination_system_card.dart';
import '../../widgets/home/time_engine_card.dart';
import '../../widgets/home/quick_history_bar.dart';
import '../../widgets/home/background_decor.dart';
import '../../widgets/home/app_bottom_nav_bar.dart';
import '../history/history_list_screen.dart';

/// 应用主界面（严格匹配设计图）
///
/// 布局结构：
/// ┌─────────────────────────────────────┐
/// │ [头像]    起卦大厅    [设置]        │  顶部栏
/// ├─────────────────────────────────────┤
/// │ Time Engine 卡片                    │  时间区
/// ├─────────────────────────────────────┤
/// │ ┌───────┐ ┌───────┐                │
/// │ │六爻纳甲│ │梅花易数│                │  术数网格
/// │ └───────┘ └───────┘                │
/// │ ┌───────┐ ┌───────┐ ┌───┐          │
/// │ │小六壬 │ │大六壬 │ │ + │          │
/// │ └───────┘ └───────┘ └───┘          │
/// ├─────────────────────────────────────┤
/// │ 上次排盘：问事业发展（六爻）>        │  历史条
/// ├─────────────────────────────────────┤
/// │ 首页  历史  历法  我的              │  导航栏
/// └─────────────────────────────────────┘
/// 右侧背景：大字"辰"
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _currentNavIndex = 0;
  String? _lastQuestion;
  String? _lastSystemName;
  String? _lastRecordId;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadLastRecord();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// 从起课/结果页 pop 回首页时触发——刷新 QuickHistoryBar 等依赖历史记录的 UI。
  @override
  void didPopNext() {
    _loadLastRecord();
  }

  Future<void> _loadLastRecord() async {
    try {
      final repository = context.read<DivinationRepository>();
      final records = await repository.getRecentRecords(1);
      if (records.isNotEmpty && mounted) {
        final record = records.first;
        setState(() {
          _lastQuestion = record.getSummary();
          _lastSystemName = _getSystemName(record.systemType);
          _lastRecordId = record.id;
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  String _getSystemName(DivinationType type) {
    switch (type) {
      case DivinationType.liuYao:
        return '六爻';
      case DivinationType.meiHua:
        return '梅花易数';
      case DivinationType.xiaoLiuRen:
        return '小六壬';
      case DivinationType.daLiuRen:
        return '大六壬';
    }
  }

  String _getCurrentDayZhi() {
    final solar = Solar.fromDate(DateTime.now());
    final lunar = solar.getLunar();
    return lunar.getDayZhi();
  }

  String _getCurrentYearZhi() {
    final solar = Solar.fromDate(DateTime.now());
    final lunar = solar.getLunar();
    return lunar.getYearZhi();
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      watermarkChar: _currentNavIndex == 0 ? _getCurrentYearZhi() : null,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        switchInCurve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
        switchOutCurve: const Interval(0.8, 1.0, curve: Curves.easeInCubic),
        transitionBuilder: (child, animation) {
          final fade = animation;
          final scale = Tween<double>(begin: 0.98, end: 1.0).animate(animation);

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Stack(
          key: ValueKey(_currentNavIndex),
          children: [
            // 背景装饰大字
            if (_currentNavIndex == 0)
              BackgroundDecor(text: _getCurrentDayZhi()),
            // 主内容
            SafeArea(
              top: _currentNavIndex == 0,
              child: Column(
                children: [
                  if (_currentNavIndex == 0) _buildAppBar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部标题栏（左头像 + 中标题 + 右设置）
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 左侧：用户头像
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: AppColors.huise,
            ),
          ),
          // 中间：标题
          Expanded(
            child: Center(
              child: Text(
                '起卦大厅',
                style: AppTextStyles.antiqueTitle.copyWith(
                  color: AppColors.xuanse,
                ),
              ),
            ),
          ),
          // 右侧：设置按钮
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.settings_outlined,
                size: 22,
                color: AppColors.xuanse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const HistoryListScreen(chromeless: true);
      case 2:
        return _buildSimpleTab(
          title: '历法',
          child: _buildCalendarContent(),
        );
      case 3:
        return _buildSimpleTab(
          title: '我的',
          child: _buildProfileContent(),
        );
      default:
        return _buildHomeContent();
    }
  }

  /// 首页主内容（Bento Grid 布局）
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Time Engine 卡片
          const TimeEngineCard(),
          const SizedBox(height: 20),
          // Bento Grid 术数系统区域
          _buildBentoGrid(),
          const SizedBox(height: 20),
          // 最近记录条（胶囊样式）
          QuickHistoryBar(
            question: _lastQuestion,
            systemName: _lastSystemName,
            recordId: _lastRecordId,
            isLoading: _isLoadingHistory,
            onTap: _onQuickHistoryTap,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 术数系统网格（每行3个卡片）
  ///
  /// 布局结构：
  /// ┌───────┬───────┬───────┐
  /// │六爻纳甲│梅花易数│ 小六壬 │  第一行
  /// └───────┴───────┴───────┘
  /// ┌───────┬───────┬───────┐
  /// │ 大六壬 │   +   │       │  第二行
  /// └───────┴───────┴───────┘
  Widget _buildBentoGrid() {
    final registry = DivinationRegistry();
    final allSystems = registry.getAllSystems();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9, // 略高于正方形
        ),
        itemCount: allSystems.length + 1, // +1 为添加按钮
        itemBuilder: (context, index) {
          if (index < allSystems.length) {
            return DivinationSystemCard(
              system: allSystems[index],
              index: index,
            );
          }
          // 添加按钮
          return AddDivinationCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('更多术数系统即将推出！'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSimpleTab({required String title, required Widget child}) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              title,
              style:
                  AppTextStyles.antiqueTitle.copyWith(color: AppColors.xuanse),
            ),
          ),
          const AntiqueDivider(),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: AppColors.huiseLight),
          const SizedBox(height: 12),
          Text('历法功能',
              style:
                  AppTextStyles.antiqueBody.copyWith(color: AppColors.huise)),
          const SizedBox(height: 4),
          Text('即将推出',
              style: AppTextStyles.antiqueLabel
                  .copyWith(color: AppColors.huiseLight)),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 48, color: AppColors.huiseLight),
          const SizedBox(height: 12),
          Text('个人中心',
              style:
                  AppTextStyles.antiqueBody.copyWith(color: AppColors.huise)),
          const SizedBox(height: 4),
          Text('即将推出',
              style: AppTextStyles.antiqueLabel
                  .copyWith(color: AppColors.huiseLight)),
        ],
      ),
    );
  }

  void _onNavIndexChanged(int index) {
    setState(() => _currentNavIndex = index);
  }

  void _onQuickHistoryTap() {
    if (_lastRecordId != null) {
      Navigator.pushNamed(context, '/history');
    }
  }
}
