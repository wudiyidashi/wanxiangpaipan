import 'package:flutter/material.dart';

import '../../../core/constants/yao_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/shared/lunar_service.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../antique/antique_dropdown.dart';
import 'cast_button.dart';

/// 卦名卦起卦区：选择本卦与可选变卦，月日支持两种输入方式——
/// 四柱干支一行直选，或选阳历时间自动换算干支。
/// 用于录入古籍卦例或他处已得之卦，动爻由本卦变卦逐位差异反推。
class GuaNameCastSection extends StatefulWidget {
  const GuaNameCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  /// (yearGanZhi?, monthGanZhi, riGanZhi, hourGanZhi?, benGuaId, bianGuaId?)
  final void Function(
    String? yearGanZhi,
    String monthGanZhi,
    String riGanZhi,
    String? hourGanZhi,
    String benGuaId,
    String? bianGuaId,
  )? onCast;
  final bool isLoading;

  @override
  State<GuaNameCastSection> createState() => _GuaNameCastSectionState();
}

enum _TimeInputMode { ganZhi, solar }

class _GuaNameCastSectionState extends State<GuaNameCastSection> {
  static const String _noBianGua = 'none';
  static const String _noHour = 'none';

  _TimeInputMode _mode = _TimeInputMode.ganZhi;

  String _yearGanZhi = '甲子';
  String _monthGanZhi = '丙寅';
  String _riGanZhi = '甲子';
  String _hourGanZhi = _noHour;

  DateTime _solarTime = DateTime.now();

  String _benGuaId = '111111';
  String _bianGuaId = _noBianGua;

  @override
  void initState() {
    super.initState();
    // 干支初值取当下时刻的四柱
    final lunar = LunarService.getLunarInfo(_solarTime);
    _yearGanZhi = lunar.yearGanZhi;
    if (TianGanDiZhiService.isValidGanZhi(lunar.monthGanZhi)) {
      _monthGanZhi = lunar.monthGanZhi;
    }
    _riGanZhi = lunar.riGanZhi;
    _hourGanZhi = lunar.hourGanZhi != null &&
            TianGanDiZhiService.isValidGanZhi(lunar.hourGanZhi!)
        ? lunar.hourGanZhi!
        : _noHour;
  }

  /// 阳历模式下换算出的四柱预览
  String get _solarGanZhiPreview {
    final lunar = LunarService.getLunarInfo(_solarTime);
    final hour = lunar.hourGanZhi != null ? ' ${lunar.hourGanZhi}时' : '';
    return '${lunar.yearGanZhi}年 ${lunar.monthGanZhi}月 '
        '${lunar.riGanZhi}日$hour（空 ${lunar.kongWang.join('')}）';
  }

  Future<void> _pickSolarTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _solarTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2099, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_solarTime),
    );
    setState(() {
      _solarTime = DateTime(date.year, date.month, date.day,
          time?.hour ?? _solarTime.hour, time?.minute ?? _solarTime.minute);
    });
  }

  void _handleCast() {
    if (widget.onCast == null) return;
    final String? year;
    final String month;
    final String ri;
    final String? hour;
    if (_mode == _TimeInputMode.ganZhi) {
      year = _yearGanZhi;
      month = _monthGanZhi;
      ri = _riGanZhi;
      hour = _hourGanZhi == _noHour ? null : _hourGanZhi;
    } else {
      final lunar = LunarService.getLunarInfo(_solarTime);
      year = lunar.yearGanZhi;
      month = TianGanDiZhiService.isValidGanZhi(lunar.monthGanZhi)
          ? lunar.monthGanZhi
          : lunar.yueJian;
      ri = lunar.riGanZhi;
      hour = lunar.hourGanZhi;
    }
    widget.onCast!(
      year,
      month,
      ri,
      hour,
      _benGuaId,
      _bianGuaId == _noBianGua || _bianGuaId == _benGuaId ? null : _bianGuaId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('起卦月日', style: AppTextStyles.antiqueLabel),
            const Spacer(),
            _modeChip('干支', _TimeInputMode.ganZhi),
            const SizedBox(width: 6),
            _modeChip('阳历时间', _TimeInputMode.solar),
          ],
        ),
        const SizedBox(height: 8),
        if (_mode == _TimeInputMode.ganZhi)
          _buildGanZhiRow()
        else
          _buildSolarRow(),
        const SizedBox(height: 16),
        const Text('本卦', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<String>(
          value: _benGuaId,
          items: [
            for (final entry in YaoConstants.guaNames.entries)
              AntiqueDropdownItem(value: entry.key, label: entry.value),
          ],
          onChanged: (v) => setState(() => _benGuaId = v ?? _benGuaId),
        ),
        const SizedBox(height: 16),
        const Text('变卦（可选）', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<String>(
          value: _bianGuaId,
          items: [
            const AntiqueDropdownItem(value: _noBianGua, label: '无变卦（六爻安静）'),
            for (final entry in YaoConstants.guaNames.entries)
              AntiqueDropdownItem(value: entry.key, label: entry.value),
          ],
          onChanged: (v) => setState(() => _bianGuaId = v ?? _bianGuaId),
        ),
        const SizedBox(height: 12),
        Text(
          '动爻由本卦与变卦逐位阴阳差异反推；月建取月支，空亡随日干支',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.guhe.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        CastButton(
          onPressed: widget.onCast == null ? null : _handleCast,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }

  Widget _modeChip(String label, _TimeInputMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.zhusha.withOpacity(0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.zhusha : AppColors.huiseLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? AppColors.zhusha : AppColors.huise,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 干支模式：年/月/日/时四柱一行
  Widget _buildGanZhiRow() {
    Widget pillar({
      required String label,
      required String value,
      required ValueChanged<String?> onChanged,
      bool allowNone = false,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.antiqueLabel
                      .copyWith(color: AppColors.guhe)),
              const SizedBox(height: 4),
              AntiqueDropdown<String>(
                value: value,
                items: [
                  if (allowNone)
                    const AntiqueDropdownItem(value: _noHour, label: '不设'),
                  for (final ganZhi in TianGanDiZhiService.liuShiJiaZi)
                    AntiqueDropdownItem(value: ganZhi, label: ganZhi),
                ],
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        pillar(
          label: '年',
          value: _yearGanZhi,
          onChanged: (v) => setState(() => _yearGanZhi = v ?? _yearGanZhi),
        ),
        pillar(
          label: '月',
          value: _monthGanZhi,
          onChanged: (v) => setState(() => _monthGanZhi = v ?? _monthGanZhi),
        ),
        pillar(
          label: '日',
          value: _riGanZhi,
          onChanged: (v) => setState(() => _riGanZhi = v ?? _riGanZhi),
        ),
        pillar(
          label: '时',
          value: _hourGanZhi,
          allowNone: true,
          onChanged: (v) => setState(() => _hourGanZhi = v ?? _hourGanZhi),
        ),
      ],
    );
  }

  /// 阳历模式：一行时间选择 + 换算预览
  Widget _buildSolarRow() {
    final t = _solarTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickSolarTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.danjin),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.5),
            ),
            child: Text(
              '${t.year}-${t.month.toString().padLeft(2, '0')}-'
              '${t.day.toString().padLeft(2, '0')} '
              '${t.hour.toString().padLeft(2, '0')}:'
              '${t.minute.toString().padLeft(2, '0')}　点击修改',
              style: AppTextStyles.antiqueBody,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '换算：$_solarGanZhiPreview',
          style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.gutong),
        ),
      ],
    );
  }
}
