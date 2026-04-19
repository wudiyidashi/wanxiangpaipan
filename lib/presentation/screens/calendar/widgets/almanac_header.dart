import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';

class AlmanacHeader extends StatelessWidget {
  const AlmanacHeader({super.key, required this.almanac});

  final DailyAlmanac almanac;

  @override
  Widget build(BuildContext context) {
    final d = almanac.date;
    final primaryLine = '${d.year}年${d.month}月${d.day}日 · '
        '${almanac.weekday} · ${almanac.lunarDate}';
    final secondaryLine = almanac.currentJieQi != null
        ? '今日节气：${almanac.currentJieQi}'
        : '距${almanac.nextJieQi} ${almanac.nextJieQiDaysAway} 天';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryLine,
            style: AppTextStyles.antiqueTitle.copyWith(
              color: AppColors.xuanse,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondaryLine,
            style: AppTextStyles.antiqueBody.copyWith(
              color: AppColors.huise,
            ),
          ),
        ],
      ),
    );
  }
}
