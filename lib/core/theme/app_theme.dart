import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'antique_tokens.dart';

/// 新中式主题配置
///
/// 设计主题：新中式极简 (Neo-Chinese Minimalist) + 科技秩序感
/// 视觉隐喻："书房"或"案头"
class AppTheme {
  AppTheme._();

  /// 浅色主题（默认）
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 色彩方案
      // A. ColorScheme: primary → zhusha (vermillion), outline → danjin (pale gold)
      colorScheme: const ColorScheme.light(
        primary: AppColors.zhusha,
        onPrimary: Colors.white,
        primaryContainer: AppColors.zhushaLight,
        secondary: AppColors.danjinDeep,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.danjin,
        surface: AppColors.xiangse,
        onSurface: AppColors.xuanse,
        surfaceContainerHighest: AppColors.xiangseLight,
        error: AppColors.errorDeep,
        onError: Colors.white,
        outline: AppColors.danjin,
      ),

      // 脚手架背景
      scaffoldBackgroundColor: AppColors.xiangse,

      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.xiangse,
        foregroundColor: AppColors.xuanse,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.xuanse,
          letterSpacing: 2,
          fontFamily: AppTextStyles.fontFamilySong,
          fontFamilyFallback: AppTextStyles.fontFamilyFallback,
        ), // 基于 antiqueTitle，字重改为 w600
        iconTheme: IconThemeData(
          color: AppColors.xuanse,
          size: 24,
        ),
      ),

      // B. 卡片主题: white@0.6 + danjin border + 0 elevation + radiusCard
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
          side: BorderSide(
            color: AppColors.danjin.withOpacity(0.5),
            width: AntiqueTokens.borderWidthBase,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // C. 按钮主题: backgroundColor/shadowColor → zhusha, shape → radiusButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.zhusha,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.zhusha.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AntiqueTokens.radiusButton),
          ),
          textStyle: AppTextStyles.antiqueButton.copyWith(letterSpacing: 1),
        ),
      ),

      // D. 文本按钮主题: foregroundColor → zhusha, textStyle → antiqueLabel
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.zhusha,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.antiqueLabel.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 图标按钮主题
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.xuanse,
        ),
      ),

      // E. 输入框主题: white@0.6 + danjin border + focused zhusha + radiusInput
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
          borderSide: const BorderSide(color: AppColors.danjin),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
          borderSide: const BorderSide(color: AppColors.danjin),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
          borderSide: const BorderSide(color: AppColors.zhusha, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
          borderSide: const BorderSide(color: AppColors.errorDeep),
        ),
        hintStyle: AppTextStyles.antiqueBody.copyWith(color: AppColors.qianhe),
      ),

      // F. 分割线主题: danjin@0.5 + thin width
      dividerTheme: DividerThemeData(
        color: AppColors.danjin.withOpacity(0.5),
        thickness: AntiqueTokens.borderWidthThin,
        space: 1,
      ),

      // G. 底部导航栏主题: selectedItemColor → zhusha, unselectedItemColor → guhe
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.xiangseLight,
        selectedItemColor: AppColors.zhusha,
        unselectedItemColor: AppColors.guhe,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.antiqueLabel,
        unselectedLabelStyle: AppTextStyles.antiqueLabel,
      ),

      // 文字主题
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.label,
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: AppColors.xuanse,
        size: 24,
      ),

      // H. 对话框主题: white@0.95 + danjin border + antiqueSection/Body textStyles
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.danjin,
            width: AntiqueTokens.borderWidthBase,
          ),
        ),
        titleTextStyle: AppTextStyles.antiqueSection,
        contentTextStyle: AppTextStyles.antiqueBody,
      ),

      // I. Snackbar 主题: KEEP AS IS (xuanse dark bg + white text is antique-friendly)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.xuanse,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.fixed,
      ),

      // J. 进度指示器主题: color → zhusha, circularTrackColor → danjin@0.3
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.zhusha,
        circularTrackColor: AppColors.danjin.withOpacity(0.3),
      ),

      // K. Chip 主题: selectedColor → zhusha@0.15, danjin stroke, antiqueLabel, radiusTag
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.xiangseLight,
        selectedColor: AppColors.zhusha.withOpacity(0.15),
        disabledColor: AppColors.divider,
        labelStyle: AppTextStyles.antiqueLabel,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
          side: BorderSide(color: AppColors.danjin.withOpacity(0.5)),
        ),
      ),

      // L. 列表瓦片主题: antique text styles, iconColor → guhe
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.antiqueBody,
        subtitleTextStyle: AppTextStyles.antiqueLabel,
        iconColor: AppColors.guhe,
      ),

      // M. 浮动按钮主题: UNCHANGED (already uses zhusha)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.zhusha,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // 涟漪效果
      splashFactory: InkRipple.splashFactory,
      // N. splashColor/highlightColor: dailan → zhusha
      splashColor: AppColors.zhusha.withOpacity(0.1),
      highlightColor: AppColors.zhusha.withOpacity(0.05),

      // 页面切换动效（缩放 + 淡入）
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _ScaleFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _ScaleFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _ScaleFadePageTransitionsBuilder(),
          TargetPlatform.windows: _ScaleFadePageTransitionsBuilder(),
          TargetPlatform.linux: _ScaleFadePageTransitionsBuilder(),
        },
      ),
    );
  }

  /// 深色主题（夜间模式）- 待实现
  static ThemeData get darkTheme {
    // TODO: 实现深色主题
    return lightTheme;
  }
}

class _ScaleFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _ScaleFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    final scale = Tween<double>(begin: 0.98, end: 1.0).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: child,
      ),
    );
  }
}
