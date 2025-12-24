import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 背景装饰组件
///
/// 在页面右侧显示一个大字（如当前日支"辰"），作为装饰底纹。
/// 设计参考：UI设计指导中的"巨大的淡灰色汉字压在背景右侧"
class BackgroundDecor extends StatelessWidget {
  /// 要显示的装饰文字（通常是地支）
  final String text;

  /// 文字大小
  final double fontSize;

  /// 文字颜色透明度
  final double opacity;

  /// 水平偏移（相对于右边缘）
  final double rightOffset;

  /// 垂直偏移（相对于顶部）
  final double topOffset;

  const BackgroundDecor({
    super.key,
    required this.text,
    this.fontSize = 280,
    this.opacity = 0.04,
    this.rightOffset = -60,
    this.topOffset = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: rightOffset,
      top: topOffset,
      child: IgnorePointer(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w100,
            color: AppColors.xuanse.withOpacity(opacity),
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 带动画的背景装饰组件
///
/// 支持淡入动画效果，提升视觉体验
class AnimatedBackgroundDecor extends StatefulWidget {
  /// 要显示的装饰文字
  final String text;

  /// 文字大小
  final double fontSize;

  /// 动画时长
  final Duration animationDuration;

  const AnimatedBackgroundDecor({
    super.key,
    required this.text,
    this.fontSize = 280,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedBackgroundDecor> createState() =>
      _AnimatedBackgroundDecorState();
}

class _AnimatedBackgroundDecorState extends State<AnimatedBackgroundDecor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedBackgroundDecor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -60,
      top: 80,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w100,
                color: AppColors.xuanse.withOpacity(_fadeAnimation.value),
                height: 1,
              ),
            );
          },
        ),
      ),
    );
  }
}
