import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 节气印章组件（纯代码绘制，不依赖图片资源）。
///
/// 传统印章样式：朱砂底方章、内衬细白框、两字竖排白文，
/// 轻微旋转模拟手工钤印。适用于全部二十四节气及任意短词。
class JieQiSeal extends StatelessWidget {
  /// 节气名称（中文，如"冬至"）
  final String jieQi;

  /// 印章大小
  final double size;

  const JieQiSeal({
    super.key,
    required this.jieQi,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    if (jieQi.isEmpty) return const SizedBox.shrink();

    return Transform.rotate(
      angle: -3 * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.zhushaDeep,
          borderRadius: BorderRadius.circular(size * 0.14),
          boxShadow: [
            BoxShadow(
              color: AppColors.zhushaDeep.withOpacity(0.35),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        // 内衬细白框，形成传统印章的双边效果
        child: Container(
          margin: EdgeInsets.all(size * 0.07),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(size * 0.08),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final char in jieQi.split(''))
                Text(
                  char,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
