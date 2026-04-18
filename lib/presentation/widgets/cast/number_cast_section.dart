import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../antique/antique_text_field.dart';
import 'cast_button.dart';

/// 数字卦起卦区
///
/// 用户输入一个数字，系统根据数字计算上卦、下卦和动爻。
class NumberCastSection extends StatefulWidget {
  const NumberCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final void Function(int number)? onCast;
  final bool isLoading;

  @override
  State<NumberCastSection> createState() => _NumberCastSectionState();
}

class _NumberCastSectionState extends State<NumberCastSection> {
  final TextEditingController _controller = TextEditingController();

  bool get _isValid {
    final text = _controller.text.trim();
    if (text.isEmpty) return false;
    final n = int.tryParse(text);
    return n != null && n > 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请输入一个数字',
          style: AppTextStyles.antiqueLabel,
        ),
        const SizedBox(height: 8),
        AntiqueTextField(
          controller: _controller,
          hint: '如：168',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          // 0xFF2B4570: 阴阳爻线/卦文蓝，域色，保留内联
          style: const TextStyle(
            color: Color(0xFF2B4570), // 卦文蓝，域色
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          hintStyle: const TextStyle(
            color: AppColors.qianhe,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            letterSpacing: 0,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Text(
          '系统将根据数字除以 8 取余确定上下卦，除以 6 取余确定动爻',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.guhe.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        CastButton(
          onPressed: _isValid
              ? () => widget.onCast?.call(int.parse(_controller.text.trim()))
              : null,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}
