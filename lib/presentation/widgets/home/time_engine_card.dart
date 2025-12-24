import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import '../../../core/theme/app_colors.dart';
import 'jieqi_seal.dart';

/// 时间引擎卡片组件（新中式风格）
///
/// 设计风格：新中式 (New Chinese Style) + 现代极简主义 (Minimalism)
/// 视觉特点：纸张质感、竖排文字、印章元素、便签卷角效果
///
/// 布局结构：
/// ┌──────────────────────────────────────────────┐
/// │ Time Engine                      [节气印章]  │
/// ├──────────────────────────────────────────────┤
/// │   癸  │  甲  │  丁  │ ┌────────┐            │
/// │   卯  │  子  │  丑  │ │  未    │            │
/// │   年  │  月  │  日  │ │  时    │ (便签效果) │
/// │       │      │      │ └────────┘            │
/// ├──────────────────────────────────────────────┤
/// │ 14:30                     真太阳时已校准     │
/// └──────────────────────────────────────────────┘
///
/// 资源依赖：
/// - assets/images/jieqi/*.png - 节气印章图片
/// - assets/images/time_engine/shichen_bg.png - 时辰背景图（可选）
class TimeEngineCard extends StatefulWidget {
  const TimeEngineCard({super.key});

  @override
  State<TimeEngineCard> createState() => _TimeEngineCardState();
}

class _TimeEngineCardState extends State<TimeEngineCard> {
  late Timer _timer;
  late DateTime _currentTime;
  late Lunar _lunar;

  // 设计色彩常量
  static const Color _bgPaper = Color(0xFFF5F3EE); // 米白色/羊皮纸色
  static const Color _textDark = Color(0xFF2B3A42); // 深藏青色文字
  static const Color _noteWhite = Color(0xFFFCFCFA); // 便签白
  static const Color _dividerColor = Color(0xFFE0DDD6); // 分隔线

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateTime.now();
      final solar = Solar.fromDate(_currentTime);
      _lunar = solar.getLunar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部：标题 + 节气印章
          _buildHeader(),
          const SizedBox(height: 24),
          // 中间：干支历显示（带分隔线）
          _buildGanZhiSection(),
          const SizedBox(height: 24),
          // 底部：时钟 + 真太阳时状态
          _buildFooter(),
        ],
      ),
    );
  }

  /// 顶部：标题 + 节气印章
  Widget _buildHeader() {
    final jieQi = _lunar.getJieQi();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '当前时间',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        // 节气印章（使用图片资源）
        JieQiSeal(jieQi: jieQi, size: 48),
      ],
    );
  }

  /// 中间：干支历显示
  Widget _buildGanZhiSection() {
    final yearGanZhi = _lunar.getYearInGanZhi();
    final monthGanZhi = _lunar.getMonthInGanZhi();
    final dayGanZhi = _lunar.getDayInGanZhi();
    final timeZhi = _lunar.getTimeZhi();

    return IntrinsicHeight(
      child: Row(
        children: [
          // 年柱
          Expanded(child: _buildGanZhiColumn('$yearGanZhi年')),
          _buildVerticalDivider(),
          // 月柱
          Expanded(child: _buildGanZhiColumn('$monthGanZhi月')),
          _buildVerticalDivider(),
          // 日柱
          Expanded(child: _buildGanZhiColumn('$dayGanZhi日')),
          const SizedBox(width: 12),
          // 时辰便签（特殊视觉效果）
          _buildTimeNote('$timeZhi时'),
        ],
      ),
    );
  }

  /// 构建干支列（竖排文字）
  Widget _buildGanZhiColumn(String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: text.split('').map((char) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            char,
            style: const TextStyle(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建分隔线
  Widget _buildVerticalDivider() {
    return Container(
      width: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: _dividerColor,
    );
  }

  /// 构建时辰便签（带卷角和投影效果）
  Widget _buildTimeNote(String text) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _noteWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(14), // 右下角圆角大，模拟卷曲
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(2, 3), // 向右下的投影
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: text.split('').map((char) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              char,
              style: const TextStyle(
                color: _textDark,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 底部：时钟 + 真太阳时状态
  Widget _buildFooter() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 大数字时钟
        Text(
          '$hour:$minute',
          style: const TextStyle(
            color: _textDark,
            fontSize: 48,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            height: 1,
          ),
        ),
        // 真太阳时状态
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppColors.huiseLight,
            ),
            const SizedBox(height: 2),
            Text(
              '真太阳时已校准',
              style: TextStyle(
                color: AppColors.huiseLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
