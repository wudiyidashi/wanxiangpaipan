import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/antique_tokens.dart';

/// 仿古风下拉选项数据。
class AntiqueDropdownItem<T> {
  const AntiqueDropdownItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// 仿古风下拉选择器：半透明白底 + 淡金边 + 朱砂下拉箭头。
class AntiqueDropdown<T> extends StatelessWidget {
  const AntiqueDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<AntiqueDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;

  String _currentLabel() {
    for (final item in items) {
      if (item.value == value) return item.label;
    }
    return items.isNotEmpty ? items.first.label : '';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '下拉选择: ${_currentLabel()}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          border: Border.all(
            color: AppColors.danjin,
            width: AntiqueTokens.borderWidthBase,
          ),
          borderRadius: BorderRadius.circular(AntiqueTokens.radiusInput),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.zhusha),
            style: const TextStyle(
              color: AppColors.xuanse,
              fontSize: 13,
            ),
            dropdownColor: AppColors.xiangseLight,
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item.value,
                      child: Text(item.label),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
