import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../models/pan_params.dart';
import 'daliuren_cast_shared.dart';

class DaLiuRenCastPanParamsSection extends StatelessWidget {
  const DaLiuRenCastPanParamsSection({
    super.key,
    required this.selectedMethod,
    required this.diZhiOptions,
    required this.dayNightMode,
    required this.onDayNightModeChanged,
    required this.xunShouMode,
    required this.onXunShouModeChanged,
    required this.guiRenVerse,
    required this.onGuiRenVerseChanged,
    required this.monthGeneralMode,
    required this.onMonthGeneralModeChanged,
    required this.manualMonthGeneral,
    required this.onManualMonthGeneralChanged,
    required this.birthYearController,
    required this.showSanChuanOnTop,
    required this.onShowSanChuanOnTopChanged,
  });

  final CastMethod selectedMethod;
  final List<String> diZhiOptions;
  final DaLiuRenDayNightMode dayNightMode;
  final ValueChanged<DaLiuRenDayNightMode> onDayNightModeChanged;
  final DaLiuRenXunShouMode xunShouMode;
  final ValueChanged<DaLiuRenXunShouMode> onXunShouModeChanged;
  final DaLiuRenGuiRenVerse guiRenVerse;
  final ValueChanged<DaLiuRenGuiRenVerse> onGuiRenVerseChanged;
  final DaLiuRenMonthGeneralMode monthGeneralMode;
  final ValueChanged<DaLiuRenMonthGeneralMode> onMonthGeneralModeChanged;
  final String manualMonthGeneral;
  final ValueChanged<String> onManualMonthGeneralChanged;
  final TextEditingController birthYearController;
  final bool showSanChuanOnTop;
  final ValueChanged<bool> onShowSanChuanOnTopChanged;

  @override
  Widget build(BuildContext context) {
    final forceManualMonthGeneral = selectedMethod == CastMethod.manual;
    final effectiveMonthGeneralMode = forceManualMonthGeneral
        ? DaLiuRenMonthGeneralMode.manual
        : monthGeneralMode;

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '排盘参数'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DaLiuRenDropdownField(
                  label: '昼夜',
                  value: dayNightMode.id,
                  items: DaLiuRenDayNightMode.values.map((e) => e.id).toList(),
                  labels: const {
                    'auto': '自动',
                    'day': '昼贵',
                    'night': '夜贵',
                  },
                  onChanged: (value) {
                    if (value != null) {
                      onDayNightModeChanged(
                        DaLiuRenDayNightMode.fromId(value),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DaLiuRenDropdownField(
                  label: '旬位',
                  value: xunShouMode.id,
                  items: DaLiuRenXunShouMode.values.map((e) => e.id).toList(),
                  labels: const {
                    'day': '日柱旬遁干',
                    'hour': '时柱旬遁干',
                  },
                  onChanged: (value) {
                    if (value != null) {
                      onXunShouModeChanged(
                        DaLiuRenXunShouMode.fromId(value),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DaLiuRenDropdownField(
                  label: '贵人口诀',
                  value: guiRenVerse.id,
                  items: DaLiuRenGuiRenVerse.values.map((e) => e.id).toList(),
                  labels: const {
                    'classic': '甲戊庚牛羊',
                    'jiaDayAlt': '甲羊戊庚牛',
                  },
                  onChanged: (value) {
                    if (value != null) {
                      onGuiRenVerseChanged(
                        DaLiuRenGuiRenVerse.fromId(value),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: forceManualMonthGeneral
                    ? DaLiuRenDropdownField(
                        label: '月将',
                        value: manualMonthGeneral,
                        items: diZhiOptions,
                        onChanged: (value) {
                          if (value != null) {
                            onManualMonthGeneralChanged(value);
                          }
                        },
                      )
                    : DaLiuRenDropdownField(
                        label: '月将模式',
                        value: effectiveMonthGeneralMode.id,
                        items: DaLiuRenMonthGeneralMode.values
                            .map((e) => e.id)
                            .toList(),
                        labels: const {
                          'auto': '自动',
                          'manual': '手动',
                        },
                        onChanged: (value) {
                          if (value != null) {
                            onMonthGeneralModeChanged(
                              DaLiuRenMonthGeneralMode.fromId(value),
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
          if (!forceManualMonthGeneral &&
              effectiveMonthGeneralMode == DaLiuRenMonthGeneralMode.manual) ...[
            const SizedBox(height: 12),
            DaLiuRenDropdownField(
              label: '手动月将',
              value: manualMonthGeneral,
              items: diZhiOptions,
              onChanged: (value) {
                if (value != null) {
                  onManualMonthGeneralChanged(value);
                }
              },
            ),
          ],
          const SizedBox(height: 12),
          Text('生年', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            controller: birthYearController,
            hint: '本命占可填，时事占可留空',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: showSanChuanOnTop,
                activeColor: AppColors.zhusha,
                onChanged: (value) {
                  if (value != null) {
                    onShowSanChuanOnTopChanged(value);
                  }
                },
              ),
              const SizedBox(width: 4),
              Text('三传显示在上', style: AppTextStyles.antiqueLabel),
            ],
          ),
        ],
      ),
    );
  }
}
