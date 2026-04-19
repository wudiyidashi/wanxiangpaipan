import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../models/pan_params.dart';

class DaLiuRenCastQuestionSection extends StatelessWidget {
  const DaLiuRenCastQuestionSection({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('占问事项', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueTextField(
          controller: controller,
          hint: '请输入您想占问的事项...',
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }
}

class DaLiuRenCastMethodSelector extends StatelessWidget {
  const DaLiuRenCastMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.availableMethods,
    required this.methodNames,
    required this.onChanged,
  });

  final CastMethod selectedMethod;
  final List<CastMethod> availableMethods;
  final Map<CastMethod, String> methodNames;
  final ValueChanged<CastMethod?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('起课方式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<CastMethod>(
          value: selectedMethod,
          items: availableMethods
              .map(
                (method) => AntiqueDropdownItem<CastMethod>(
                  value: method,
                  label: methodNames[method] ?? method.displayName,
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

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
                child: _DaLiuRenDropdownField(
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
                child: _DaLiuRenDropdownField(
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
                child: _DaLiuRenDropdownField(
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
                    ? _DaLiuRenDropdownField(
                        label: '月将',
                        value: manualMonthGeneral,
                        items: diZhiOptions,
                        onChanged: (value) {
                          if (value != null) {
                            onManualMonthGeneralChanged(value);
                          }
                        },
                      )
                    : _DaLiuRenDropdownField(
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
            _DaLiuRenDropdownField(
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

class DaLiuRenTimeCastSection extends StatelessWidget {
  const DaLiuRenTimeCastSection({
    super.key,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.timeGanZhi,
    required this.isLoading,
    required this.onCast,
  });

  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String timeGanZhi;
  final bool isLoading;
  final VoidCallback? onCast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            border: Border.all(color: AppColors.danjin.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '当前干支',
                style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DaLiuRenGanZhiItem(label: '年', ganZhi: yearGanZhi),
                  _DaLiuRenGanZhiItem(label: '月', ganZhi: monthGanZhi),
                  _DaLiuRenGanZhiItem(label: '日', ganZhi: dayGanZhi),
                  _DaLiuRenGanZhiItem(label: '时', ganZhi: timeGanZhi),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: isLoading ? '起课中...' : '起课',
          onPressed: onCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }
}

class DaLiuRenReportNumberCastSection extends StatelessWidget {
  const DaLiuRenReportNumberCastSection({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onCast,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback? onCast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: AppColors.danjin),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.antiqueBody,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '请输入任意数字',
              hintStyle: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.qianhe,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '输入任意数字，除12取余映射地支',
          style: AppTextStyles.antiqueLabel,
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: isLoading ? '起课中...' : '起课',
          onPressed: onCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }
}

class DaLiuRenManualCastSection extends StatelessWidget {
  const DaLiuRenManualCastSection({
    super.key,
    required this.tianGanOptions,
    required this.diZhiOptions,
    required this.yearGan,
    required this.yearZhi,
    required this.onYearGanChanged,
    required this.onYearZhiChanged,
    required this.monthGan,
    required this.monthZhi,
    required this.onMonthGanChanged,
    required this.onMonthZhiChanged,
    required this.dayGan,
    required this.dayZhi,
    required this.onDayGanChanged,
    required this.onDayZhiChanged,
    required this.hourGan,
    required this.hourZhi,
    required this.onHourGanChanged,
    required this.onHourZhiChanged,
    required this.isLoading,
    required this.onCast,
  });

  final List<String> tianGanOptions;
  final List<String> diZhiOptions;
  final String yearGan;
  final String yearZhi;
  final ValueChanged<String> onYearGanChanged;
  final ValueChanged<String> onYearZhiChanged;
  final String monthGan;
  final String monthZhi;
  final ValueChanged<String> onMonthGanChanged;
  final ValueChanged<String> onMonthZhiChanged;
  final String dayGan;
  final String dayZhi;
  final ValueChanged<String> onDayGanChanged;
  final ValueChanged<String> onDayZhiChanged;
  final String hourGan;
  final String hourZhi;
  final ValueChanged<String> onHourGanChanged;
  final ValueChanged<String> onHourZhiChanged;
  final bool isLoading;
  final VoidCallback? onCast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DaLiuRenPillarSelectorRow(
          label: '年柱',
          gan: yearGan,
          zhi: yearZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onYearGanChanged,
          onZhiChanged: onYearZhiChanged,
        ),
        const SizedBox(height: 12),
        _DaLiuRenPillarSelectorRow(
          label: '月柱',
          gan: monthGan,
          zhi: monthZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onMonthGanChanged,
          onZhiChanged: onMonthZhiChanged,
        ),
        const SizedBox(height: 12),
        _DaLiuRenPillarSelectorRow(
          label: '日柱',
          gan: dayGan,
          zhi: dayZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onDayGanChanged,
          onZhiChanged: onDayZhiChanged,
        ),
        const SizedBox(height: 12),
        _DaLiuRenPillarSelectorRow(
          label: '时柱',
          gan: hourGan,
          zhi: hourZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onHourGanChanged,
          onZhiChanged: onHourZhiChanged,
        ),
        const SizedBox(height: 8),
        Text(
          '指定干支模式按输入四柱直接起课，月将请在上方“排盘参数”中明确指定。',
          style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: isLoading ? '起课中...' : '起课',
          onPressed: onCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }
}

class DaLiuRenComputerCastSection extends StatelessWidget {
  const DaLiuRenComputerCastSection({
    super.key,
    required this.isLoading,
    required this.onCast,
  });

  final bool isLoading;
  final VoidCallback? onCast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            border: Border.all(color: AppColors.danjin.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.casino_outlined,
                size: 48,
                color: AppColors.zhusha.withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              Text(
                '系统随机取地支作为占时',
                style: AppTextStyles.antiqueBody.copyWith(
                  color: AppColors.guhe,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: isLoading ? '起课中...' : '起课',
          onPressed: onCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _DaLiuRenDropdownField extends StatelessWidget {
  const _DaLiuRenDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labels,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Map<String, String>? labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<String>(
          value: value,
          items: items
              .map(
                (item) => AntiqueDropdownItem<String>(
                  value: item,
                  label: labels?[item] ?? item,
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DaLiuRenPillarSelectorRow extends StatelessWidget {
  const _DaLiuRenPillarSelectorRow({
    required this.label,
    required this.gan,
    required this.zhi,
    required this.tianGanOptions,
    required this.diZhiOptions,
    required this.onGanChanged,
    required this.onZhiChanged,
  });

  final String label;
  final String gan;
  final String zhi;
  final List<String> tianGanOptions;
  final List<String> diZhiOptions;
  final ValueChanged<String> onGanChanged;
  final ValueChanged<String> onZhiChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: AppTextStyles.antiqueLabel),
        ),
        Expanded(
          child: _DaLiuRenDropdownField(
            label: '天干',
            value: gan,
            items: tianGanOptions,
            onChanged: (value) {
              if (value != null) {
                onGanChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DaLiuRenDropdownField(
            label: '地支',
            value: zhi,
            items: diZhiOptions,
            onChanged: (value) {
              if (value != null) {
                onZhiChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DaLiuRenGanZhiItem extends StatelessWidget {
  const _DaLiuRenGanZhiItem({
    required this.label,
    required this.ganZhi,
  });

  final String label;
  final String ganZhi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        Text(ganZhi, style: AppTextStyles.antiqueTitle),
      ],
    );
  }
}
