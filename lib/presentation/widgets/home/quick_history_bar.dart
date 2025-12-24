import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 快捷历史入口（胶囊样式）
///
/// 设计风格：新中式胶囊按钮
/// 视觉特点：
/// - 圆润的胶囊形状（Stadium Border）
/// - 暖色调背景
/// - 富文本显示"上次排盘：xxx（系统名）"
/// - 右侧箭头指示
class QuickHistoryBar extends StatelessWidget {
  final String? question;
  final String? systemName;
  final String? recordId;
  final VoidCallback? onTap;
  final bool isLoading;

  // 设计色彩常量
  static const Color _bgColor = Color(0xFFF4F1EB);
  static const Color _textDark = Color(0xFF4A4A4A);
  static const Color _textMuted = Color(0xFF8A8A8A);
  static const Color _borderColor = Color(0xFFE0DDD6);

  const QuickHistoryBar({
    super.key,
    this.question,
    this.systemName,
    this.recordId,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 无记录时不显示
    if (!isLoading && question == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(30), // 胶囊圆角
            border: Border.all(
              color: _borderColor,
              width: 1,
            ),
          ),
          child: isLoading ? _buildLoading() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '加载中...',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      ],
    );
  }

  Widget _buildContent() {
    String displayText = question ?? '无标题';
    if (displayText.length > 12) {
      displayText = '${displayText.substring(0, 12)}...';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: _textDark),
              children: [
                const TextSpan(
                  text: '上次排盘：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: displayText),
                if (systemName != null)
                  TextSpan(
                    text: '（$systemName）',
                    style: const TextStyle(color: _textMuted),
                  ),
              ],
            ),
          ),
        ),
        const Icon(
          Icons.chevron_right,
          size: 20,
          color: _textMuted,
        ),
      ],
    );
  }
}
