import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/meihua_result.dart';

/// 梅花易数卦象独立绘制组件
///
/// 刻意与六爻 `DiagramComparisonRow` 解耦：
///
/// - 不展示六亲、六神、世应、纳甲
/// - 只表达：上卦、下卦、六爻阴阳、动爻、体/用
/// - 视觉风格对齐梅花 `meihuaColor` 主题色
///
/// 约定：
///
/// - `movingLine` 仅本卦传入，`null` 表示非本卦
/// - `tiName` / `yongName` 用于在上下卦标注『体』/『用』角标，仅本卦传
class MeiHuaHexagramDiagram extends StatelessWidget {
  final String label;
  final MeiHuaHexagram hexagram;
  final int? movingLine;
  final String? tiName;
  final String? yongName;

  const MeiHuaHexagramDiagram({
    super.key,
    required this.label,
    required this.hexagram,
    this.movingLine,
    this.tiName,
    this.yongName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danjin.withOpacity(0.55)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.antiqueLabel.copyWith(
              fontSize: 11,
              color: AppColors.guhe,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hexagram.name,
            style: AppTextStyles.antiqueTitle.copyWith(
              fontSize: 15,
              color: AppColors.meihuaColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _buildTrigramHeader(hexagram.upperTrigram, _positionForUpper()),
          const SizedBox(height: 6),
          _buildYaoStack(),
          const SizedBox(height: 6),
          _buildTrigramHeader(hexagram.lowerTrigram, _positionForLower()),
        ],
      ),
    );
  }

  String? _positionForUpper() {
    if (tiName == hexagram.upperTrigram.name) return '体';
    if (yongName == hexagram.upperTrigram.name) return '用';
    return null;
  }

  String? _positionForLower() {
    if (tiName == hexagram.lowerTrigram.name) return '体';
    if (yongName == hexagram.lowerTrigram.name) return '用';
    return null;
  }

  Widget _buildTrigramHeader(MeiHuaTrigram trigram, String? bodyUseTag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${trigram.name}·${trigram.symbol}',
          style: AppTextStyles.antiqueBody.copyWith(
            fontSize: 12,
            color: AppColors.xuanse,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (bodyUseTag != null) ...[
          const SizedBox(width: 4),
          _buildBodyUseTag(bodyUseTag),
        ],
      ],
    );
  }

  Widget _buildBodyUseTag(String text) {
    final isTi = text == '体';
    final color = isTi ? AppColors.zhusha : AppColors.dailan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// 从上（6 爻）到下（1 爻）依序绘制六条爻
  Widget _buildYaoStack() {
    final reversedIndexes = List<int>.generate(6, (i) => 5 - i);
    return Column(
      children: [
        for (final index in reversedIndexes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _buildYaoLine(
              lineIndex: index,
              value: hexagram.lines[index],
            ),
          ),
      ],
    );
  }

  Widget _buildYaoLine({required int lineIndex, required int value}) {
    final isMoving = movingLine != null && (lineIndex + 1) == movingLine;
    final color = isMoving ? AppColors.meihuaColor : AppColors.xuanse;

    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: value == 1
                ? _buildYangBar(color: color)
                : _buildYinBars(color: color),
          ),
          SizedBox(
            width: 12,
            child: isMoving
                ? Icon(
                    Icons.adjust,
                    size: 10,
                    color: AppColors.meihuaColor,
                    semanticLabel: '动爻',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildYangBar({required Color color}) {
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildYinBars({required Color color}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        SizedBox(width: 8, child: const SizedBox.shrink()),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ],
    );
  }
}
