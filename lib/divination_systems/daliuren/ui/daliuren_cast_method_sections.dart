import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/antique/antique.dart';
import 'daliuren_cast_shared.dart';

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
                  DaLiuRenGanZhiItem(label: '年', ganZhi: yearGanZhi),
                  DaLiuRenGanZhiItem(label: '月', ganZhi: monthGanZhi),
                  DaLiuRenGanZhiItem(label: '日', ganZhi: dayGanZhi),
                  DaLiuRenGanZhiItem(label: '时', ganZhi: timeGanZhi),
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
        DaLiuRenPillarSelectorRow(
          label: '年柱',
          gan: yearGan,
          zhi: yearZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onYearGanChanged,
          onZhiChanged: onYearZhiChanged,
        ),
        const SizedBox(height: 12),
        DaLiuRenPillarSelectorRow(
          label: '月柱',
          gan: monthGan,
          zhi: monthZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onMonthGanChanged,
          onZhiChanged: onMonthZhiChanged,
        ),
        const SizedBox(height: 12),
        DaLiuRenPillarSelectorRow(
          label: '日柱',
          gan: dayGan,
          zhi: dayZhi,
          tianGanOptions: tianGanOptions,
          diZhiOptions: diZhiOptions,
          onGanChanged: onDayGanChanged,
          onZhiChanged: onDayZhiChanged,
        ),
        const SizedBox(height: 12),
        DaLiuRenPillarSelectorRow(
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
