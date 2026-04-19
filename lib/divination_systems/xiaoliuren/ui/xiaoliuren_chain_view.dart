import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/xiaoliuren_result.dart';

/// 小六壬三段顺推链可视化组件
///
/// 独立自绘，不复用梅花 / 六爻的卦图组件。语义专注：
///
/// - 三胶囊横排展示 `第一段 → 第二段 → 第三段`
/// - 每胶囊显示：段位标签、落宫名、吉/凶/平 徽章
/// - 箭头连接相邻段
///
/// 颜色语义：吉（青翠）/ 凶（朱砂）/ 平（赭黄）
class XiaoLiuRenChainView extends StatelessWidget {
  final String firstStepLabel;
  final int firstStepNumber;
  final XiaoLiuRenPosition firstPosition;
  final String secondStepLabel;
  final int secondStepNumber;
  final XiaoLiuRenPosition secondPosition;
  final String thirdStepLabel;
  final int thirdStepNumber;
  final XiaoLiuRenPosition thirdPosition;

  const XiaoLiuRenChainView({
    super.key,
    required this.firstStepLabel,
    required this.firstStepNumber,
    required this.firstPosition,
    required this.secondStepLabel,
    required this.secondStepNumber,
    required this.secondPosition,
    required this.thirdStepLabel,
    required this.thirdStepNumber,
    required this.thirdPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildChip(
            stepLabel: firstStepLabel,
            stepNumber: firstStepNumber,
            position: firstPosition,
          ),
        ),
        _buildArrow(),
        Expanded(
          child: _buildChip(
            stepLabel: secondStepLabel,
            stepNumber: secondStepNumber,
            position: secondPosition,
          ),
        ),
        _buildArrow(),
        Expanded(
          child: _buildChip(
            stepLabel: thirdStepLabel,
            stepNumber: thirdStepNumber,
            position: thirdPosition,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.arrow_forward,
        size: 16,
        color: AppColors.xiaoliurenColor,
      ),
    );
  }

  Widget _buildChip({
    required String stepLabel,
    required int stepNumber,
    required XiaoLiuRenPosition position,
  }) {
    final fortuneColor = _fortuneColor(position.fortune);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danjin),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$stepLabel $stepNumber',
            style: AppTextStyles.antiqueLabel.copyWith(
              fontSize: 11,
              color: AppColors.guhe,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            position.name,
            style: AppTextStyles.antiqueTitle.copyWith(
              fontSize: 16,
              color: AppColors.xuanse,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          _buildFortuneBadge(position.fortune, fortuneColor),
        ],
      ),
    );
  }

  Widget _buildFortuneBadge(String fortune, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        fortune,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Color _fortuneColor(String fortune) {
    switch (fortune) {
      case '吉':
        return AppColors.jishenGreen;
      case '凶':
        return AppColors.zhusha;
      case '平':
        return AppColors.warning;
      default:
        return AppColors.guhe;
    }
  }
}
