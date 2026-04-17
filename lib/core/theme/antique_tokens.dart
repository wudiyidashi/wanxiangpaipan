import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 仿古风非颜色非字体的视觉常量集合
///
/// 集中管理圆角、间距、边框宽度、按钮阴影。
/// 颜色见 [AppColors]，字体样式见 [AppTextStyles]。
class AntiqueTokens {
  AntiqueTokens._();

  // ==================== 圆角 ====================

  /// 卡片圆角
  static const double radiusCard = 8;

  /// 输入框圆角（与卡片一致）
  static const double radiusInput = 8;

  /// 按钮（胶囊）圆角
  static const double radiusButton = 26;

  /// 标签（Tag）圆角
  static const double radiusTag = 12;

  // ==================== 边框 ====================

  /// 细边（分割线、卡片边）
  static const double borderWidthThin = 0.5;

  /// 标准边（输入框、按钮边）
  static const double borderWidthBase = 1.0;

  // ==================== 间距 ====================

  /// 紧凑间距（元素内）
  static const double gapTight = 8;

  /// 基础间距（元素间）
  static const double gapBase = 12;

  /// 节间距（section 之间）
  static const double gapSection = 16;

  // ==================== 阴影 ====================

  /// 主按钮阴影（朱砂色，模拟印章按下感）
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x4DC94A4A),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // ==================== 背景 ====================

  /// 仿古风页面背景渐变（缃色 → 缃色深）
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.xiangse, AppColors.xiangseDeep],
  );

  /// 主按钮渐变（朱砂 → 浅朱砂）
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [AppColors.zhusha, AppColors.zhushaLight],
  );
}
