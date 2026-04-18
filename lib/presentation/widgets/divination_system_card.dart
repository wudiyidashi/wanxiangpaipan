import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/divination_system.dart';
import '../divination_ui_registry.dart';

/// 术数系统卡片组件（Bento Grid 新中式风格）
///
/// 设计风格：便当盒/宫格布局 + 新中式
/// 视觉特点：
/// - 渐变背景（从左上浅到右下深）
/// - 右下角半透明水印图
/// - 左上角文字内容
/// - 点击缩放动效
///
/// 支持两种尺寸：
/// - 大卡片（isLarge=true）：用于核心功能（六爻、梅花）
/// - 小卡片（isLarge=false）：用于次级功能（小六壬、大六壬）
class DivinationSystemCard extends StatefulWidget {
  final DivinationSystem system;
  final int index;
  final bool enableAnimation;
  final bool isLarge; // 大卡片模式

  const DivinationSystemCard({
    required this.system,
    this.index = 0,
    this.enableAnimation = true,
    this.isLarge = false,
    super.key,
  });

  @override
  State<DivinationSystemCard> createState() => _DivinationSystemCardState();
}

class _DivinationSystemCardState extends State<DivinationSystemCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    if (widget.enableAnimation) {
      Future.delayed(Duration(milliseconds: 80 * widget.index), () {
        if (mounted) _animationController.forward();
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _getBackgroundImagePath() {
    switch (widget.system.type) {
      case DivinationType.liuYao:
        return 'assets/images/screen_card/liuyao_background.png';
      case DivinationType.meiHua:
        return 'assets/images/screen_card/meihua_background.png';
      case DivinationType.xiaoLiuRen:
        return 'assets/images/screen_card/xiaoliuren_background.png';
      case DivinationType.daLiuRen:
        return 'assets/images/screen_card/daliuren_background.png';
    }
  }

  String _getSubtitle() {
    switch (widget.system.type) {
      case DivinationType.liuYao:
        return '问事、决策';
      case DivinationType.meiHua:
        return '问事、决策';
      case DivinationType.xiaoLiuRen:
        return '手王捷算';
      case DivinationType.daLiuRen:
        return '人事、运筹';
    }
  }

  String _getDisplayName() {
    switch (widget.system.type) {
      case DivinationType.liuYao:
        return '六爻纳甲';
      case DivinationType.meiHua:
        return '梅花易数';
      case DivinationType.xiaoLiuRen:
        return '小六壬';
      case DivinationType.daLiuRen:
        return '大六壬';
    }
  }

  /// 获取渐变色（从左上到右下）
  List<Color> _getGradientColors() {
    switch (widget.system.type) {
      case DivinationType.liuYao:
        return const [AppColors.xiangse, AppColors.danjin];
      case DivinationType.meiHua:
        return const [AppColors.xiangse, AppColors.danjin];
      case DivinationType.xiaoLiuRen:
        return const [AppColors.xiangse, AppColors.danjin];
      case DivinationType.daLiuRen:
        return const [AppColors.danjin, AppColors.qianhe]; // 大六壬颜色深一点
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = _getBackgroundImagePath();
    final subtitle = _getSubtitle();
    final displayName = _getDisplayName();
    final gradientColors = _getGradientColors();

    // 根据卡片大小调整尺寸
    final double titleSize = widget.isLarge ? 18.0 : 16.0;
    final double subtitleSize = widget.isLarge ? 12.0 : 11.0;
    final double padding = widget.isLarge ? 16.0 : 14.0;

    Widget card = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _handleTap(context),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.guhe.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 背景水印图（覆盖整个区域）
              if (backgroundImage != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      backgroundImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomRight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              // 文字内容（左上角）
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 系统名称
                    Text(
                      displayName,
                      style: AppTextStyles.antiqueTitle.copyWith(
                        fontSize: titleSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 副标题
                    Text(
                      subtitle,
                      style: AppTextStyles.antiqueLabel.copyWith(
                        fontSize: subtitleSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.enableAnimation) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: card,
        ),
      );
    }

    return card;
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();

    if (!widget.system.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.system.name}即将推出，敬请期待！'),
        ),
      );
      return;
    }

    final systemType = widget.system.type;
    final defaultMethod = widget.system.supportedMethods.first;
    final castScreen =
        DivinationUIRegistry().buildCastScreen(systemType, defaultMethod);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => castScreen,
      ),
    );
  }
}

/// 添加术数卡片（虚线边框 + 号按钮）
///
/// 设计特点：
/// - 虚线边框（表示"空位"或"待添加"）
/// - 透明/极淡背景
/// - 居中的灰色"+"号
class AddDivinationCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddDivinationCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.xiangse,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.danjin.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 30,
            color: AppColors.guhe.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}
