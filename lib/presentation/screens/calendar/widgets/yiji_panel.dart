import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/antique_tokens.dart';

class YijiPanel extends StatelessWidget {
  const YijiPanel({super.key, required this.yi, required this.ji});
  final List<String> yi;
  final List<String> ji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Column(
              title: '宜',
              items: yi,
              titleColor: AppColors.danjin,
              bgColor: const Color(0xFFEBE4D2), // danjinLight (light warm tone)
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Column(
              title: '忌',
              items: ji,
              titleColor: AppColors.zhusha,
              bgColor: AppColors.zhushaLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.items,
    required this.titleColor,
    required this.bgColor,
  });
  final String title;
  final List<String> items;
  final Color titleColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        border: Border.all(
          color: titleColor.withOpacity(0.3),
          width: AntiqueTokens.borderWidthBase,
        ),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.antiqueSection.copyWith(
            color: titleColor,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text('—', style: AppTextStyles.antiqueBody.copyWith(
              color: AppColors.huiseLight,
            ))
          else
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('· $e', style: AppTextStyles.antiqueBody),
                )),
        ],
      ),
    );
  }
}
