import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../widgets/antique/antique.dart';

class PengzuCard extends StatelessWidget {
  const PengzuCard({super.key, required this.gan, required this.zhi});

  final String gan;
  final String zhi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AntiqueCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('彭祖百忌',
                style: AppTextStyles.antiqueSection.copyWith(
                  color: AppColors.xuanse,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(gan, style: AppTextStyles.antiqueBody),
            Text(zhi, style: AppTextStyles.antiqueBody),
          ],
        ),
      ),
    );
  }
}
