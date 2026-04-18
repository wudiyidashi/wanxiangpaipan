import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风标签：低透明色块 + 对应色边框。
///
/// 默认色为朱砂；传入 [color] 可自定义（如六亲、五行、神将等领域色）。
class AntiqueTag extends StatelessWidget {
  const AntiqueTag({
    super.key,
    required this.label,
    this.color = AppColors.zhusha,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: AntiqueTokens.borderWidthBase,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.antiqueLabel.copyWith(color: color),
      ),
    );
  }
}
