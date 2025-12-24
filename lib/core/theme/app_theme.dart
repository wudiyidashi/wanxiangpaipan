import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

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
      colorScheme: const ColorScheme.light(
        primary: AppColors.dailan,
        onPrimary: Colors.white,
        primaryContainer: AppColors.dailanLight,
        secondary: AppColors.zhusha,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.zhushaLight,
        surface: AppColors.xiangse,
        onSurface: AppColors.xuanse,
        surfaceContainerHighest: AppColors.xiangseLight,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.divider,
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
        ),
        iconTheme: IconThemeData(
          color: AppColors.xuanse,
          size: 24,
        ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: AppColors.xiangseLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dailan,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.dailan.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ),

      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dailan,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
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

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.dailan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.huiseLight,
        ),
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.xiangseLight,
        selectedItemColor: AppColors.dailan,
        unselectedItemColor: AppColors.huiseLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle: AppTextStyles.navLabel,
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

      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.xiangseLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Snackbar 主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.xuanse,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.dailan,
        circularTrackColor: AppColors.divider,
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.xiangseLight,
        selectedColor: AppColors.dailan.withValues(alpha: 0.15),
        disabledColor: AppColors.divider,
        labelStyle: AppTextStyles.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),

      // 列表瓦片主题
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.titleSmall,
        subtitleTextStyle: AppTextStyles.bodySmall,
        iconColor: AppColors.huise,
      ),

      // 浮动按钮主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.zhusha,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // 涟漪效果
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.dailan.withValues(alpha: 0.1),
      highlightColor: AppColors.dailan.withValues(alpha: 0.05),
    );
  }

  /// 深色主题（夜间模式）- 待实现
  static ThemeData get darkTheme {
    // TODO: 实现深色主题
    return lightTheme;
  }
}
