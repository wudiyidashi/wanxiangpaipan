import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/term_glossary.dart';
import '../../../../presentation/widgets/antique/antique.dart';

/// 术语词典弹窗：规则释义 + 经边界收敛的来源信息。
Future<void> showTermGlossaryDialog(
  BuildContext context,
  String term, {
  String ruleId = '',
}) {
  final detail = TermGlossary.lookupByRuleId(
    ruleId,
    fallbackTerm: term,
  );
  return showDialog<void>(
    context: context,
    builder: (context) => AntiqueDialog(
      title: detail.displayTerm,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail.entry == null)
                Text('暂无该术语的释义', style: AppTextStyles.antiqueBody)
              else ...[
                if (detail.isAlias) ...[
                  _GlossaryRow(label: '主词', text: detail.primaryTerm),
                  const SizedBox(height: 8),
                ],
                _GlossaryRow(
                  label: '释义',
                  text: detail.entry!.definition,
                ),
                const SizedBox(height: 8),
                _GlossaryRow(
                  label: '条件',
                  text: detail.entry!.condition,
                ),
                const SizedBox(height: 8),
                _GlossaryRow(
                  label: '断法',
                  text: detail.entry!.implication,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _GlossaryRow(
                label: '边界',
                text: detail.adoptionBoundary,
              ),
              for (final reference in detail.references) ...[
                const SizedBox(height: 12),
                Text(
                  '${reference.sourceType} · ${reference.sourceTitle}',
                  style: AppTextStyles.antiqueBody.copyWith(
                    color: AppColors.xuanse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _GlossaryRow(
                  label: reference.referenceLabel,
                  text: '${reference.locator}（证据 ${reference.evidenceLevel}）',
                ),
                if (reference.quote != null) ...[
                  const SizedBox(height: 6),
                  _GlossaryRow(
                    label: '短引',
                    text: '“${reference.quote}”',
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  reference.boundary,
                  style: AppTextStyles.antiqueLabel.copyWith(
                    color: AppColors.huise,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
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
