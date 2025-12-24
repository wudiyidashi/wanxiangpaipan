import 'package:flutter/material.dart';

/// 节气印章组件
///
/// 使用 assets/images/jieqi/ 目录下的印章图片
/// 设计特点：
/// - 方形红色印章样式
/// - 白色篆书风格文字
/// - 支持24节气
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

  /// 节气名称到文件名的映射
  static const Map<String, String> _jieQiToFile = {
    '立春': 'lichun',
    '雨水': 'yushui',
    '惊蛰': 'jinzhe',
    '春分': 'chunfen',
    '清明': 'qingming',
    '谷雨': 'guyu',
    '立夏': 'lixia',
    '小满': 'xiaoman',
    '芒种': 'mangzhong',
    '夏至': 'xiazhi',
    '小暑': 'xiaoshu',
    '大暑': 'dashu',
    '立秋': 'liqiu',
    '处暑': 'chushu',
    '白露': 'bailu',
    '秋分': 'qiufen',
    '寒露': 'hanlu',
    '霜降': 'shuangjiang',
    '立冬': 'lidong',
    '小雪': 'xiaoxue',
    '大雪': 'daxue',
    '冬至': 'dongzhi',
    '小寒': 'xiaohan',
    '大寒': 'dahan',
  };

  String? _getImagePath() {
    final fileName = _jieQiToFile[jieQi];
    if (fileName == null) return null;
    return 'assets/images/jieqi/$fileName.png';
  }

  @override
  Widget build(BuildContext context) {
    if (jieQi.isEmpty) return const SizedBox.shrink();

    final imagePath = _getImagePath();
    if (imagePath == null) return const SizedBox.shrink();

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // 图片加载失败时显示空白
        return SizedBox(width: size, height: size);
      },
    );
  }
}
