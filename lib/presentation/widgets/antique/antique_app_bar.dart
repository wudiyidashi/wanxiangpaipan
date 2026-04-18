import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'antique_divider.dart';

/// 仿古风 AppBar：透明底 + 衬线居中标题 + 底部 0.5px 淡金分隔线。
class AntiqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AntiqueAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(
        title,
        style: AppTextStyles.antiqueTitle.copyWith(color: AppColors.xuanse),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: AntiqueDivider(height: 1),
      ),
    );
  }
}
