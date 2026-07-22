import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/term_glossary.dart';
import '../../../../presentation/widgets/antique/antique.dart';

/// 术语词典弹窗：定义 + 成立条件 + 吉凶含义
Future<void> showTermGlossaryDialog(BuildContext context, String term) {
  final entry = TermGlossary.lookup(term);
  return showDialog<void>(
    context: context,
    builder: (context) => AntiqueDialog(
      title: term,
      content: entry == null
          ? Text('暂无该术语的释义', style: AppTextStyles.antiqueBody)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlossaryRow(label: '释义', text: entry.definition),
                const SizedBox(height: 8),
                _GlossaryRow(label: '条件', text: entry.condition),
                const SizedBox(height: 8),
                _GlossaryRow(label: '断法', text: entry.implication),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

class _GlossaryRow extends StatelessWidget {
  const _GlossaryRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.danjin.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: AppTextStyles.antiqueLabel.copyWith(
              color: AppColors.gutong,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTextStyles.antiqueBody),
        ),
      ],
    );
  }
}
