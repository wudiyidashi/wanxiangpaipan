import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class CastButton extends StatelessWidget {
  const CastButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final String buttonLabel = label ?? '起卦';

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          // 按钮渐变：0xFFB0B0B0/0xFF909090=禁用灰，0xFFC84B31/0xFFA63A24=朱砂激活渐变
          // 均为CastButton专属UI渐变色，非通用token，保留内联
          gradient: onPressed == null || isLoading
              ? const LinearGradient(
                  // 禁用灰渐变，CastButton 专属域色
                  colors: [
                    Color(0xFFB0B0B0), // 禁用灰渐变起色
                    Color(0xFF909090), // 禁用灰渐变终色
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  // 朱砂激活渐变，CastButton 专属域色
                  colors: [
                    Color(0xFFC84B31), // 朱砂激活起色
                    Color(0xFFA63A24), // 朱砂激活终色
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: (onPressed != null && !isLoading)
              ? [
                  BoxShadow(
                    // 0xFFC84B31: 朱砂激活渐变起色，CastButton专属投影，保留内联
                    color: const Color(0xFFC84B31).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                buttonLabel,
                style: AppTextStyles.antiqueButton.copyWith(letterSpacing: 3),
              ),
      ),
    );
  }
}
