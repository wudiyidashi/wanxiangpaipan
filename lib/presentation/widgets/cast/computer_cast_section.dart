import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'cast_button.dart';

/// 电脑卦起卦区
///
/// 系统随机生成卦象，一键起卦。
class ComputerCastSection extends StatelessWidget {
  const ComputerCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final VoidCallback? onCast;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.computer,
          size: 48,
          color: AppColors.guhe,
        ),
        const SizedBox(height: 16),
        Text(
          '由系统随机生成卦象',
          style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
        ),
        const SizedBox(height: 8),
        Text(
          '模拟六次三枚铜钱投掷',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.guhe.withOpacity(0.7),
          ),
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
