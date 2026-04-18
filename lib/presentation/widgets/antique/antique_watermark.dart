import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 仿古风小印章水印：用于历史/设置页等不需要大字水印的场景。
///
/// 与 [AppTextStyles.decorText]（200px 大字）区别：本组件默认 96px，
/// 适合作为局部装饰而非整页水印。
class AntiqueWatermark extends StatelessWidget {
  const AntiqueWatermark({
    super.key,
    required this.char,
    this.size = 96,
  });

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Text(
        char,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamilySong,
          fontSize: size,
          fontWeight: FontWeight.w100,
          color: AppColors.danjin.withOpacity(0.15),
          height: 1,
        ),
      ),
    );
  }
}
