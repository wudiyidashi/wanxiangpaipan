import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import '../../../core/theme/app_colors.dart';
import 'cast_form_sections.dart';

class TimeCastSection extends StatefulWidget {
  const TimeCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final ValueChanged<DateTime>? onCast;
  final bool isLoading;

  @override
  State<TimeCastSection> createState() => _TimeCastSectionState();
}

class _TimeCastSectionState extends State<TimeCastSection> {
  late DateTime _castTime;

  @override
  void initState() {
    super.initState();
    _castTime = DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _castTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _castTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _castTime.hour,
          _castTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_castTime),
    );
    if (picked != null) {
      setState(() {
        _castTime = DateTime(
          _castTime.year,
          _castTime.month,
          _castTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _useCurrentTime() {
    setState(() => _castTime = DateTime.now());
  }

  void _handleCast() {
    widget.onCast?.call(_castTime);
  }

  @override
  Widget build(BuildContext context) {
    final lunar = Lunar.fromDate(_castTime);

    final ganZhiDate = '${lunar.getYearInGanZhi()}年 '
        '${lunar.getMonthInGanZhi()}月 '
        '${lunar.getDayInGanZhi()}日 '
        '${lunar.getTimeInGanZhi()}时';

    return CastTimeActionSection(
      title: '起卦时间',
      ganZhiText: ganZhiDate,
      dateTimeText: _formatDateTime(_castTime),
      note: '取农历年支数、月数、日数、时支数推上下卦与动爻',
      accentColor: AppColors.liuyaoColor,
      isLoading: widget.isLoading,
      onCast: widget.onCast == null ? null : _handleCast,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onUseCurrentTime: _useCurrentTime,
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}年${_two(value.month)}月${_two(value.day)}日 '
        '${_two(value.hour)}时${_two(value.minute)}分';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
