import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风文本输入框：半透明白底 + 淡金边 + 8px 圆角。
class AntiqueTextField extends StatelessWidget {
  const AntiqueTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(
          color: AppColors.danjin,
          width: AntiqueTokens.borderWidthBase,
        ),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.xuanse,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.qianhe,
            fontSize: 13,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
