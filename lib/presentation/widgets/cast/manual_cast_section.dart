import 'package:flutter/material.dart';
import 'cast_button.dart';
import 'yao_line_placeholder.dart';

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
        const SizedBox(height: 24),
        const YaoLinePlaceholder(),
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
                      size: 14, color: Color(0xFF8B7355)),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Color(0xFF2B4570),
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
                      size: 14, color: Color(0xFF8B7355)),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFF2B4570),
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
        border: Border.all(color: const Color(0x4DB79452)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  List<Widget> _buildYaoDropdowns() {
    return List.generate(6, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _yaoLabels[index],
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8B7355),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            _buildInputContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _yaoValues[index],
                  hint: const Text(
                    '请选择',
                    style: TextStyle(
                      color: Color(0xFFA0937E),
                      fontSize: 13,
                    ),
                  ),
                  isExpanded: true,
                  style: const TextStyle(
                    color: Color(0xFF2B4570),
                    fontSize: 13,
                  ),
                  dropdownColor: Colors.white,
                  items: _yaoOptions.map((opt) {
                    return DropdownMenuItem<int>(
                      value: opt['value'] as int,
                      child: Text(
                        '${opt['label']}（${opt['value']}）',
                        style: const TextStyle(
                          color: Color(0xFF2B4570),
                          fontSize: 13,
                        ),
                      ),
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
}
