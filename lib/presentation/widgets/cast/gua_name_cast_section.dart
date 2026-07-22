import 'package:flutter/material.dart';

import '../../../core/constants/yao_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../antique/antique_dropdown.dart';
import 'cast_button.dart';

/// 卦名卦起卦区：自定月建、日干支，选择本卦与可选变卦。
///
/// 用于录入古籍卦例或他处已得之卦，动爻由本卦变卦逐位差异反推。
class GuaNameCastSection extends StatefulWidget {
  const GuaNameCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final void Function(
    String yueJian,
    String riGanZhi,
    String benGuaId,
    String? bianGuaId,
  )? onCast;
  final bool isLoading;

  @override
  State<GuaNameCastSection> createState() => _GuaNameCastSectionState();
}

class _GuaNameCastSectionState extends State<GuaNameCastSection> {
  static const String _noBianGua = 'none';

  String _yueJian = '子';
  String _riGanZhi = '甲子';
  String _benGuaId = '111111';
  String _bianGuaId = _noBianGua;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('月建', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<String>(
          value: _yueJian,
          items: [
            for (final zhi in TianGanDiZhiService.diZhi)
              AntiqueDropdownItem(value: zhi, label: '$zhi月'),
          ],
          onChanged: (v) => setState(() => _yueJian = v ?? _yueJian),
        ),
        const SizedBox(height: 16),
        const Text('日辰（干支）', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<String>(
          value: _riGanZhi,
          items: [
            for (final ganZhi in TianGanDiZhiService.liuShiJiaZi)
              AntiqueDropdownItem(value: ganZhi, label: '$ganZhi日'),
          ],
          onChanged: (v) => setState(() => _riGanZhi = v ?? _riGanZhi),
        ),
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
          '动爻由本卦与变卦逐位阴阳差异反推；月建日辰用于旺衰空亡等断卦分析',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.guhe.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        CastButton(
          onPressed: widget.onCast == null
              ? null
              : () => widget.onCast!(
                    _yueJian,
                    _riGanZhi,
                    _benGuaId,
                    _bianGuaId == _noBianGua || _bianGuaId == _benGuaId
                        ? null
                        : _bianGuaId,
                  ),
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}
