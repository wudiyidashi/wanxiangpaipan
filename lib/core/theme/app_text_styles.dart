import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 新中式主题字体样式
///
/// 字体选择：
/// - 标题：使用思源宋体（有书卷气）
/// - 数字和正文：使用系统默认字体（确保易读性）
/// - 干支文字：使用楷体或宋体
class AppTextStyles {
  AppTextStyles._();

  // ==================== 字体族 ====================

  /// 宋体字体族（标题、干支）
  static const String fontFamilySong = 'Noto Serif SC';

  /// 楷体字体族（装饰文字）
  static const String fontFamilyKai = 'ZCOOL KuaiLe';

  // ==================== 标题样式 ====================

  /// 页面大标题
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.xuanse,
    letterSpacing: 2,
    height: 1.4,
  );

  /// 页面标题
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.xuanse,
    letterSpacing: 1.5,
    height: 1.4,
  );

  /// 区域标题
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.xuanse,
    letterSpacing: 1,
    height: 1.4,
  );

  /// 卡片标题
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.xuanse,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// 小标题
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.xuanse,
    height: 1.4,
  );

  // ==================== 正文样式 ====================

  /// 大正文
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.xuanse,
    height: 1.6,
  );

  /// 正文
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.xuanse,
    height: 1.6,
  );

  /// 小正文
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.huise,
    height: 1.5,
  );

  // ==================== 特殊样式 ====================

  /// 时间数字样式（大号）
  static const TextStyle timeDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    color: AppColors.xuanse,
    letterSpacing: 2,
    height: 1.2,
  );

  /// 干支文字样式
  static const TextStyle ganzhiText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.xuanse,
    letterSpacing: 2,
    height: 1.8,
  );

  /// 干支标签样式（年、月、日、时）
  static const TextStyle ganzhiLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.huise,
    height: 1.4,
  );

  /// 背景装饰大字
  static const TextStyle decorText = TextStyle(
    fontSize: 200,
    fontWeight: FontWeight.w100,
    color: Color(0x08000000),
    height: 1,
  );

  /// 印章文字
  static const TextStyle sealText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  /// 导航标签
  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// 副标题/描述文字
  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.huise,
    height: 1.5,
  );

  /// 标签文字
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.huiseLight,
    letterSpacing: 0.5,
    height: 1.4,
  );
}
