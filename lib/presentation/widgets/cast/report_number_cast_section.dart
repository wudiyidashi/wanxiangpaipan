import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cast_button.dart';

/// 报数卦起卦区
///
/// 用户报三个数：上卦数、下卦数、动爻数。
class ReportNumberCastSection extends StatefulWidget {
  const ReportNumberCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final void Function(int upperNum, int lowerNum, int movingNum)? onCast;
  final bool isLoading;

  @override
  State<ReportNumberCastSection> createState() =>
      _ReportNumberCastSectionState();
}

class _ReportNumberCastSectionState extends State<ReportNumberCastSection> {
  final _upperController = TextEditingController();
  final _lowerController = TextEditingController();
  final _movingController = TextEditingController();

  bool get _isValid {
    final u = int.tryParse(_upperController.text.trim());
    final l = int.tryParse(_lowerController.text.trim());
    final m = int.tryParse(_movingController.text.trim());
    return u != null && u > 0 && l != null && l > 0 && m != null && m > 0;
  }

  @override
  void dispose() {
    _upperController.dispose();
    _lowerController.dispose();
    _movingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请报三个数',
          style: TextStyle(
            color: Color(0xFF8B7355),
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildNumberField('上卦数', _upperController, '如：5'),
        const SizedBox(height: 10),
        _buildNumberField('下卦数', _lowerController, '如：3'),
        const SizedBox(height: 10),
        _buildNumberField('动爻数', _movingController, '如：4'),
        const SizedBox(height: 12),
        Text(
          '上下卦数除以 8 取余确定八卦，动爻数除以 6 取余确定动爻位置',
          style: TextStyle(
            color: const Color(0xFF8B7355).withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 32),
        CastButton(
          onPressed: _isValid
              ? () => widget.onCast?.call(
                    int.parse(_upperController.text.trim()),
                    int.parse(_lowerController.text.trim()),
                    int.parse(_movingController.text.trim()),
                  )
              : null,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }

  Widget _buildNumberField(
      String label, TextEditingController controller, String hint) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B7355),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              border: Border.all(color: const Color(0x4DB79452)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Color(0xFF2B4570),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFA0937E),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ],
    );
  }
}
