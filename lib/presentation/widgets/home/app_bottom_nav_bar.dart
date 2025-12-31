import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// 底部导航栏（严格匹配设计图）
///
/// 设计特点：
/// - 高度 60px
/// - 选中状态：黑色实心图标 + 下方红点
/// - 未选中状态：灰色图标
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.xiangseLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, '首页', Icons.home_outlined, Icons.home),
              _buildNavItem(1, '历史', Icons.schedule_outlined, Icons.schedule),
              _buildNavItem(
                  2, '历法', Icons.calendar_today_outlined, Icons.calendar_today),
              _buildNavItem(3, '我的', Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onIndexChanged(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.xuanse : AppColors.huiseLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.xuanse : AppColors.huiseLight,
              ),
            ),
            const SizedBox(height: 2),
            // 选中指示红点
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.zhusha : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
