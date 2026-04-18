import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风分割线：淡金 0.5 透明度，0.5px 厚度。
class AntiqueDivider extends StatelessWidget {
  const AntiqueDivider({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.danjin.withOpacity(0.5),
      thickness: AntiqueTokens.borderWidthThin,
      height: height,
    );
  }
}
