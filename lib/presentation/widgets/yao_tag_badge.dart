import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/services/liuyao/analysis/models/analysis_tag.dart';

/// 标签极性 → 颜色：吉=靑绿、凶=朱砂、中性=灰
Color polarityColor(Polarity polarity) {
  switch (polarity) {
    case Polarity.ji:
      return AppColors.jishenGreen;
    case Polarity.xiong:
      return AppColors.zhusha;
    case Polarity.neutral:
      return AppColors.huise;
  }
}

/// 爻行分析徽标（迷你 chip）
class YaoTagBadge extends StatelessWidget {
  const YaoTagBadge({
    super.key,
    required this.tag,
    this.onTap,
    this.dense = true,
  });

  final YaoAnalysisTag tag;
  final VoidCallback? onTap;

  /// 紧凑模式用于爻行内联，false 用于详析 Sheet
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = polarityColor(tag.polarity);
    final badge = Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.5), width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        tag.term,
        style: TextStyle(
          fontSize: dense ? 9 : 12,
          height: 1.2,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
