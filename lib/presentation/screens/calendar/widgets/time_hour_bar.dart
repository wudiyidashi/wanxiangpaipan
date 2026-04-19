import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';

class TimeHourBar extends StatelessWidget {
  const TimeHourBar({
    super.key,
    required this.hours,
    required this.selectedZhi,
    required this.onSelect,
  });

  final List<HourAlmanac> hours;
  final String? selectedZhi;
  final void Function(String zhi) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final h = hours[i];
          final selected = h.zhi == selectedZhi;
          final luckColor = h.luck == '吉' ? AppColors.danjin : AppColors.zhusha;
          return InkWell(
            key: ValueKey('hour-${h.zhi}'),
            onTap: () => onSelect(h.zhi),
            child: Container(
              width: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? AppColors.xiangseLight : null,
                border: Border.all(
                  color: luckColor,
                  width: selected ? 1.4 : 0.8,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${h.zhi}时',
                      style: AppTextStyles.antiqueBody.copyWith(
                        color: AppColors.xuanse,
                      )),
                  Text(h.huangHei == '黄' ? '黄道' : '黑道',
                      style: AppTextStyles.antiqueLabel.copyWith(
                        color: AppColors.huise,
                        fontSize: 10,
                      )),
                  Text(h.luck,
                      style: AppTextStyles.antiqueLabel.copyWith(
                        color: luckColor,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
