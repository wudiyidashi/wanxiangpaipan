import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/qimen_palace.dart';
import '../../models/qimen_result.dart';

class QimenNinePalaceGrid extends StatelessWidget {
  const QimenNinePalaceGrid({
    super.key,
    required this.palaces,
    required this.onPalaceTap,
  });

  static const List<int> palaceOrder = QimenResult.luoShuPalaceOrder;

  final List<QimenPalace> palaces;
  final ValueChanged<QimenPalace> onPalaceTap;

  @override
  Widget build(BuildContext context) {
    final byNumber = <int, QimenPalace>{
      for (final palace in palaces) palace.number: palace,
    };
    final ordered = palaceOrder.map((number) => byNumber[number]!).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 5.0;
        final gridWidth = math.min(constraints.maxWidth, 640.0);
        final cellWidth = (gridWidth - spacing * 2) / 3;
        final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 2.5);
        final cellHeight = 144.0 + (scale - 1) * 76.0;

        return Center(
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              key: const ValueKey('qimen-nine-palace-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ordered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: cellWidth / cellHeight,
              ),
              itemBuilder: (context, index) {
                final palace = ordered[index];
                return _QimenPalaceCell(
                  key: ValueKey('qimen-palace-${palace.number}'),
                  palace: palace,
                  textScale: scale.toDouble(),
                  onTap: () => onPalaceTap(palace),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _QimenPalaceCell extends StatelessWidget {
  const _QimenPalaceCell({
    super.key,
    required this.palace,
    required this.textScale,
    required this.onTap,
  });

  final QimenPalace palace;
  final double textScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hosted = <String>[
      if (palace.hostedEarthStem != null) '地${palace.hostedEarthStem}',
      if (palace.hostedHeavenStem != null) '天${palace.hostedHeavenStem}',
      if (palace.hostedStar != null) palace.hostedStar!,
    ];
    final status = <String>[
      if (palace.voidBranches.isNotEmpty) '空${palace.voidBranches.join()}',
      if (palace.isHorse) '马',
      ...palace.marks.where(
        (mark) =>
            !(mark == '空亡' && palace.voidBranches.isNotEmpty) &&
            !(mark == '驿马' && palace.isHorse),
      ),
    ];
    final badgeSize = 22.0 + (textScale - 1) * 14.0;
    final slotHeight = 25.0 + (textScale - 1) * 16.0;
    final statusTrackHeight = 17.0 + (textScale - 1) * 11.0;

    return Semantics(
      button: true,
      label: _semanticsLabel(hosted, status),
      hint: '点按查看完整宫位事实和规则来源',
      child: Material(
        color: palace.number == 5
            ? AppColors.danjin.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.66),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: palace.isHorse
                ? AppColors.qimenColor
                : AppColors.danjin.withValues(alpha: 0.65),
            width: palace.isHorse ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.qimenColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${palace.number}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.qimenColor,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${palace.trigram} · ${palace.direction}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.xuanse,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: _slot(
                        '天',
                        palace.heavenStem,
                        height: slotHeight,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _slot(
                        '地',
                        palace.earthStem,
                        height: slotHeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _line(
                  '${palace.star} · ${palace.door ?? '中宫无门'}',
                  emphasized: true,
                ),
                const SizedBox(height: 2),
                _line(
                    '${palace.deity ?? '中宫无神'} · 暗${palace.hiddenStem ?? '无'}'),
                const Spacer(),
                SizedBox(
                  height: statusTrackHeight,
                  child: _line(
                    hosted.isEmpty ? '主宫事实' : '寄 ${hosted.join('·')}',
                    color:
                        hosted.isEmpty ? AppColors.huiseLight : AppColors.guhe,
                  ),
                ),
                SizedBox(
                  height: statusTrackHeight,
                  child: _line(
                    status.isEmpty ? '状态：常' : status.join(' · '),
                    color: status.isEmpty
                        ? AppColors.huiseLight
                        : AppColors.zhusha,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(
    String label,
    String value, {
    required double height,
  }) =>
      Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.inkWash,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$label$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.xuanse,
            letterSpacing: 0,
          ),
        ),
      );

  Widget _line(
    String value, {
    bool emphasized = false,
    Color color = AppColors.huise,
  }) =>
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: emphasized ? 11 : 10,
          fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
          color: color,
          letterSpacing: 0,
        ),
      );

  String _semanticsLabel(List<String> hosted, List<String> status) => <String>[
        '${palace.name}，${palace.direction}，${palace.element}',
        '天盘${palace.heavenStem}，地盘${palace.earthStem}',
        '${palace.star}，${palace.door ?? '无门'}，${palace.deity ?? '无神'}',
        '暗干${palace.hiddenStem ?? '无'}',
        if (hosted.isNotEmpty) '寄宫${hosted.join('、')}',
        if (status.isNotEmpty) '状态${status.join('、')}',
      ].join('。');
}
