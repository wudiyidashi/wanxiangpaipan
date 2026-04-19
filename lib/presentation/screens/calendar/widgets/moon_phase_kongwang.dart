import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MoonPhaseKongwang extends StatelessWidget {
  const MoonPhaseKongwang({
    super.key,
    required this.yueXiang,
    required this.kongWang,
  });

  final String yueXiang;
  final List<String> kongWang;

  @override
  Widget build(BuildContext context) {
    final kw = kongWang.isEmpty ? '—' : kongWang.join('');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '月相：$yueXiang · 空亡：$kw',
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.huise),
      ),
    );
  }
}
