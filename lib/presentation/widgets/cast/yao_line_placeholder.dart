import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class YaoLinePlaceholder extends StatelessWidget {
  const YaoLinePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(6, (index) {
          final bool isYang = index.isEven;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: isYang ? _buildYangLine() : _buildYinLine(),
          );
        }),
        const SizedBox(height: 8),
        Text(
          '卦象',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.guhe.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildYangLine() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        // Colors.grey: 占位爻线视觉指示色（Material调色板灰），保留内联
        gradient: LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.12),
            Colors.grey.withOpacity(0.18),
            Colors.grey.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildYinLine() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.12),
                  Colors.grey.withOpacity(0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.18),
                  Colors.grey.withOpacity(0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ],
    );
  }
}
