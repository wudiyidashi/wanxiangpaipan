import 'package:flutter/material.dart';
import 'cast_button.dart';

/// 电脑卦起卦区
///
/// 系统随机生成卦象，一键起卦。
class ComputerCastSection extends StatelessWidget {
  const ComputerCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final VoidCallback? onCast;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.computer,
          size: 48,
          color: Color(0xFF8B7355),
        ),
        const SizedBox(height: 16),
        const Text(
          '由系统随机生成卦象',
          style: TextStyle(
            color: Color(0xFF8B7355),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '模拟六次三枚铜钱投掷',
          style: TextStyle(
            color: const Color(0xFF8B7355).withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 32),
        CastButton(
          onPressed: onCast,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
