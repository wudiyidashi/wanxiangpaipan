import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风卡片容器：半透明白底 + 淡金边框 + 8px 圆角，无阴影。
///
/// 替代页面中的 [Card] 与自定义 [Container]，统一卡片视觉。
/// 当 [onTap] 非空时，自带按压缩放反馈（Scale 0.98）。
class AntiqueCard extends StatefulWidget {
  const AntiqueCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  /// Optional a11y label used when [onTap] is non-null.
  final String? semanticsLabel;

  @override
  State<AntiqueCard> createState() => _AntiqueCardState();
}

class _AntiqueCardState extends State<AntiqueCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(
          color: AppColors.danjin.withOpacity(0.5),
          width: AntiqueTokens.borderWidthBase,
        ),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: card,
        ),
      ),
    );
  }
}
