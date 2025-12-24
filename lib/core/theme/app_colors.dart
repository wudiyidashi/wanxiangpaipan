import 'package:flutter/material.dart';

/// 新中式主题色彩体系
///
/// 基于 UI 设计指导文档，采用"新中式极简"风格：
/// - 视觉隐喻：书房/案头，用户打开 App 就像铺开一张宣纸
/// - 色彩体系：缃色背景、黛蓝主色、朱砂强调色
class AppColors {
  AppColors._();

  // ==================== 主色调 ====================

  /// 缃色（淡黄/米白）- 背景色
  static const Color xiangse = Color(0xFFF7F7F5);

  /// 墨色（深灰）- 夜间模式背景
  static const Color mose = Color(0xFF1A1A1A);

  /// 黛蓝 - 主色，用于图标/强调
  static const Color dailan = Color(0xFF2D4A7A);

  /// 朱砂 - 强调色，用于吉/重要按钮
  static const Color zhusha = Color(0xFFC94A4A);

  /// 淡金 - 辅色，用于边框或分割线
  static const Color danjin = Color(0xFFD4B896);

  // ==================== 扩展色彩 ====================

  /// 浅缃色 - 卡片背景
  static const Color xiangseLight = Color(0xFFFAFAF8);

  /// 深黛蓝 - 深色文字
  static const Color dailanDark = Color(0xFF1D3254);

  /// 浅黛蓝 - 次要元素
  static const Color dailanLight = Color(0xFF4A6A9A);

  /// 浅朱砂 - 次要强调
  static const Color zhushaLight = Color(0xFFE07070);

  /// 古铜色 - 用于装饰
  static const Color gutong = Color(0xFF8B6914);

  /// 玄色（黑）- 主要文字
  static const Color xuanse = Color(0xFF2C2C2C);

  /// 灰色 - 次要文字
  static const Color huise = Color(0xFF666666);

  /// 浅灰 - 辅助文字/边框
  static const Color huiseLight = Color(0xFFAAAAAA);

  /// 分割线颜色
  static const Color divider = Color(0xFFE8E8E6);

  // ==================== 功能色 ====================

  /// 成功色（青绿）
  static const Color success = Color(0xFF52C41A);

  /// 警告色（橙黄）
  static const Color warning = Color(0xFFFAAD14);

  /// 错误色
  static const Color error = Color(0xFFFF4D4F);

  /// 信息色
  static const Color info = Color(0xFF1890FF);

  // ==================== 术数系统专属色 ====================

  /// 六爻 - 铜钱金色
  static const Color liuyaoColor = Color(0xFF8B6914);

  /// 梅花易数 - 梅红色
  static const Color meihuaColor = Color(0xFFB85798);

  /// 小六壬 - 玉石青
  static const Color xiaoliurenColor = Color(0xFF3D8B7A);

  /// 大六壬 - 紫檀色
  static const Color daliurenColor = Color(0xFF5D3A6A);

  // ==================== 渐变色 ====================

  /// 主渐变（黛蓝渐变）
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dailan, dailanLight],
  );

  /// 强调渐变（朱砂渐变）
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [zhusha, zhushaLight],
  );

  /// 卡片背景渐变
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [xiangseLight, xiangse],
  );
}
