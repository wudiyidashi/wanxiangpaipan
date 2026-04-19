import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/antique/antique.dart';

class DaLiuRenDropdownField extends StatelessWidget {
  const DaLiuRenDropdownField({
    super.key,
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

class DaLiuRenPillarSelectorRow extends StatelessWidget {
  const DaLiuRenPillarSelectorRow({
    super.key,
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
          child: DaLiuRenDropdownField(
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
          child: DaLiuRenDropdownField(
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

class DaLiuRenGanZhiItem extends StatelessWidget {
  const DaLiuRenGanZhiItem({
    super.key,
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
