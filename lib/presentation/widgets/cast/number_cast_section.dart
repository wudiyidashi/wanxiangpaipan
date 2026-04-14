import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          style: TextStyle(
            color: Color(0xFF8B7355),
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: const Color(0x4DB79452)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Color(0xFF2B4570),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '如：168',
              hintStyle: TextStyle(
                color: Color(0xFFA0937E),
                fontSize: 16,
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
              ),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '系统将根据数字除以 8 取余确定上下卦，除以 6 取余确定动爻',
          style: TextStyle(
            color: const Color(0xFF8B7355).withOpacity(0.7),
            fontSize: 11,
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
