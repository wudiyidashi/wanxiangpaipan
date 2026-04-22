import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 宜忌列表：左侧 24×24 方色块 + 右侧 chip 组，纵向两行。
class YijiPanel extends StatelessWidget {
  const YijiPanel({super.key, required this.yi, required this.ji});
  final List<String> yi;
  final List<String> ji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            label: '宜',
            items: yi,
            badgeColor: AppColors.danjinDeep,
          ),
          const SizedBox(height: 10),
          _Row(
            label: '忌',
            items: ji,
            badgeColor: AppColors.zhusha,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.items,
    required this.badgeColor,
  });

  final String label;
  final List<String> items;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamilySong,
              fontFamilyFallback: AppTextStyles.fontFamilyFallback,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '—',
                    style: AppTextStyles.antiqueBody.copyWith(
                      color: AppColors.huiseLight,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final item in items)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x08000000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamilySong,
                            fontFamilyFallback:
                                AppTextStyles.fontFamilyFallback,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.xuanse,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
