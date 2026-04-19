import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FestivalBanner extends StatelessWidget {
  const FestivalBanner({super.key, required this.festivals});
  final List<String> festivals;

  @override
  Widget build(BuildContext context) {
    if (festivals.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.zhusha,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        festivals.join(' · '),
        style: AppTextStyles.antiqueSection.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
