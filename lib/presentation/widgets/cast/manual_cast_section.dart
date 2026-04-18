import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'cast_button.dart';

class ManualCastSection extends StatefulWidget {
  const ManualCastSection({
    super.key,
    this.onCast,
    this.isLoading = false,
  });

  final void Function(List<int> yaoNumbers, DateTime castTime)? onCast;
  final bool isLoading;

  @override
  State<ManualCastSection> createState() => _ManualCastSectionState();
}

class _ManualCastSectionState extends State<ManualCastSection> {
  DateTime _castDate = DateTime.now();
  TimeOfDay _castTime = TimeOfDay.now();
  final List<int?> _yaoValues = List.filled(6, null);

  static const List<Map<String, dynamic>> _yaoOptions = [
    {'label': '老阴', 'value': 6},
    {'label': '少阳', 'value': 7},
    {'label': '少阴', 'value': 8},
    {'label': '老阳', 'value': 9},
  ];

  static const List<String> _yaoLabels = [
    '初爻（一爻）',
    '二爻',
    '三爻',
    '四爻',
    '五爻',
    '六爻（上爻）',
  ];

  bool get _allSelected => _yaoValues.every((v) => v != null);

  DateTime get _combinedDateTime => DateTime(
        _castDate.year,
        _castDate.month,
        _castDate.day,
        _castTime.hour,
        _castTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _castDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _castDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _castTime,
    );
    if (picked != null) {
      setState(() => _castTime = picked);
    }
  }

  void _handleCast() {
    if (!_allSelected) return;
    widget.onCast?.call(
      _yaoValues.map((v) => v!).toList(),
      _combinedDateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateTimeRow(),
        const SizedBox(height: 20),
        ..._buildYaoDropdowns(),
        const SizedBox(height: 24),
        CastButton(
          onPressed: _allSelected ? _handleCast : null,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    final dateStr =
        '${_castDate.year}-${_castDate.month.toString().padLeft(2, '0')}-${_castDate.day.toString().padLeft(2, '0')}';
    final timeStr = _castTime.format(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: _buildInputContainer(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.guhe),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    // 0xFF2B4570: 阴阳爻线/卦文蓝，域色，保留内联
                    style: const TextStyle(
                      color: Color(0xFF2B4570), // 卦文蓝，域色
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: _buildInputContainer(
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.guhe),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    // 0xFF2B4570: 阴阳爻线/卦文蓝，域色，保留内联
                    style: const TextStyle(
                      color: Color(0xFF2B4570), // 卦文蓝，域色
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(color: AppColors.danjinDeep.withOpacity(0x4D / 255)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  List<Widget> _buildYaoDropdowns() {
    // 从下往上排列：上爻(index 5)在最上面，初爻(index 0)在最下面
    return List.generate(6, (i) {
      final index = 5 - i;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _yaoLabels[index],
              style: AppTextStyles.antiqueLabel,
            ),
            const SizedBox(height: 4),
            _buildInputContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _yaoValues[index],
                  hint: Text(
                    '请选择',
                    style: AppTextStyles.antiqueBody.copyWith(color: AppColors.qianhe),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  selectedItemBuilder: (context) {
                    return _yaoOptions.map((opt) {
                      return _buildYaoOptionRow(opt);
                    }).toList();
                  },
                  items: _yaoOptions.map((opt) {
                    return DropdownMenuItem<int>(
                      value: opt['value'] as int,
                      child: _buildYaoOptionRow(opt),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _yaoValues[index] = val);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildYaoOptionRow(Map<String, dynamic> opt) {
    final value = opt['value'] as int;
    final label = opt['label'] as String;
    final isYang = value == 7 || value == 9;

    return Row(
      children: [
        CustomPaint(
          size: const Size(32, 14),
          painter: _YaoLinePainter(isYang: isYang),
        ),
        const SizedBox(width: 10),
        // 0xFFB0A08E: 爻选项标签专用色，域色，保留内联
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0A08E), // 爻标签专用浅褐色，域色
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _YaoLinePainter extends CustomPainter {
  const _YaoLinePainter({required this.isYang});

  final bool isYang;

  @override
  void paint(Canvas canvas, Size size) {
    // 0xFF2B4570: 阴阳爻线专用黛蓝，域色，保留内联
    final paint = Paint()
      ..color = const Color(0xFF2B4570) // 阴阳爻线专用黛蓝，域色
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    if (isYang) {
      // 阳爻：一条实线
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      // 阴爻：中间断开的两段
      final gap = 4.0;
      final mid = size.width / 2;
      canvas.drawLine(Offset(0, y), Offset(mid - gap, y), paint);
      canvas.drawLine(Offset(mid + gap, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _YaoLinePainter oldDelegate) =>
      isYang != oldDelegate.isYang;
}
