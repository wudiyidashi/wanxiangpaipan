import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';

/// 顶部日期摘要：左列农历大字 + 公历小字；右列节日/节气 badge。
class AlmanacHeader extends StatelessWidget {
  const AlmanacHeader({super.key, required this.almanac});

  final DailyAlmanac almanac;

  @override
  Widget build(BuildContext context) {
    final d = almanac.date;
    // 保留 "YYYY年M月D日" 子串（calendar_screen_test C3 依赖）
    final solarLine = '${d.year}年${d.month}月${d.day}日 ${almanac.weekday}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  almanac.lunarDate,
                  style: AppTextStyles.antiqueTitle.copyWith(
                    fontSize: 16,
                    color: AppColors.xuanse,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  solarLine,
                  style: AppTextStyles.antiqueLabel.copyWith(
                    fontSize: 12,
                    color: AppColors.guhe,
                  ),
                ),
              ],
            ),
          ),
          _buildBadge(),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    // 优先级：节日 > 今日节气 > 距下一节气
    String? text;
    Color bg = AppColors.zhusha;
    Color fg = Colors.white;
    bool emphasize = true;

    if (almanac.festivals.isNotEmpty) {
      text = almanac.festivals.first;
    } else if (almanac.currentJieQi != null) {
      text = '今日节气·${almanac.currentJieQi}';
    } else if (almanac.nextJieQi.isNotEmpty) {
      text = '距${almanac.nextJieQi} ${almanac.nextJieQiDaysAway} 天';
      bg = AppColors.danjin.withOpacity(0.25);
      fg = AppColors.guhe;
      emphasize = false;
    }

    if (text == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: emphasize
            ? const [
                BoxShadow(
                  color: Color(0x33C94A4A),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: AppTextStyles.antiqueLabel.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
