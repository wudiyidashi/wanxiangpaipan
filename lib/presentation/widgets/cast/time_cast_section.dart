import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'cast_button.dart';

class TimeCastSection extends StatelessWidget {
  const TimeCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final VoidCallback? onCast;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);

    final ganZhiDate =
        '${lunar.getYearInGanZhi()}年 ${lunar.getMonthInGanZhi()}月 ${lunar.getDayInGanZhi()}日';

    final gregorianDate =
        '${now.year}年${now.month}月${now.day}日  ${lunar.getTimeZhi()}时';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '当前时辰',
          style: AppTextStyles.antiqueLabel,
        ),
        const SizedBox(height: 12),
        // 0xFF2B4570: 卦文蓝/干支文字专用色，域色，保留内联
        Text(
          ganZhiDate,
          style: const TextStyle(
            color: Color(0xFF2B4570), // 卦文蓝，域色
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          gregorianDate,
          style: AppTextStyles.antiqueBody.copyWith(color: AppColors.qianhe),
        ),
        const SizedBox(height: 32),
        CastButton(
          onPressed: onCast,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
