import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/antique_tokens.dart';

enum AntiqueButtonVariant { primary, ghost, danger }

/// 仿古风按钮：朱砂渐变胶囊（primary）/ 透明朱砂边（ghost）/ 朱砂深变体（danger）。
class AntiqueButton extends StatelessWidget {
  const AntiqueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AntiqueButtonVariant.primary,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AntiqueButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final isGhost = variant == AntiqueButtonVariant.ghost;
    final fillGradient = isGhost
        ? null
        : (variant == AntiqueButtonVariant.danger
            ? const LinearGradient(
                colors: [Color(0xFFB23A3A), AppColors.zhusha],
              )
            : AntiqueTokens.buttonGradient);

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: fillGradient,
            color: isGhost ? Colors.transparent : null,
            border: isGhost
                ? Border.all(
                    color: AppColors.zhusha,
                    width: AntiqueTokens.borderWidthBase,
                  )
                : null,
            borderRadius: BorderRadius.circular(AntiqueTokens.radiusButton),
            boxShadow: isGhost ? null : const [AntiqueTokens.buttonShadow],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isGhost ? AppColors.zhusha : Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.antiqueButton.copyWith(
                  color: isGhost ? AppColors.zhusha : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
