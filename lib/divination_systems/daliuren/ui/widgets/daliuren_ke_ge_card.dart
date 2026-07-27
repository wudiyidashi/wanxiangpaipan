import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import '../../../../domain/services/shared/analysis/models/verdict_models.dart';
import '../../../../presentation/widgets/antique/antique.dart';
import 'dlr_tag_badge.dart';

/// 课体断诀卡：格名 + 课体 + 基调 + 干支主客标签 + 裁决摘要 +
/// 未决条件 chips + 可展开推理链。
class DaLiuRenKeGeCard extends StatelessWidget {
  const DaLiuRenKeGeCard({
    super.key,
    required this.report,
  });

  final DaLiuRenAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final keGe = report.keGe;
    final judgment = report.judgment;
    final polarityColor = dlrPolarityColor(keGe.polarity);

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '课体断诀'),
          const AntiqueDivider(),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.ideographic,
            children: [
              Text(
                keGe.geName,
                style: AppTextStyles.antiqueTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Text(
                '${keGe.keTypeName}课',
                style: AppTextStyles.antiqueLabel.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 8),
              AntiqueTag(label: keGe.polarity.name, color: polarityColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            keGe.reason,
            style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
          ),
          if (report.ganZhiTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in report.ganZhiTags)
                  DlrTagBadge(tag: tag, dense: false),
              ],
            ),
          ],
          if (judgment != null) ...[
            const SizedBox(height: 10),
            const AntiqueDivider(),
            const SizedBox(height: 8),
            if (report.verdictSummary != null)
              Text(
                report.verdictSummary!,
                style: AppTextStyles.antiqueBody.copyWith(height: 1.6),
              ),
            if (judgment.conditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '未决条件',
                style: AppTextStyles.antiqueLabel.copyWith(
                  color: AppColors.gutong,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final condition in judgment.conditions)
                    AntiqueTag(
                      label: _conditionLabel(condition),
                      color: condition.hasRescue
                          ? AppColors.huise
                          : AppColors.zhusha,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            _FactorsExpansion(factors: judgment.factors),
          ],
        ],
      ),
    );
  }

  String _conditionLabel(VerdictCondition condition) {
    final branch = condition.branch == null ? '' : '（${condition.branch}）';
    final rescue = condition.hasRescue ? '' : '·无解';
    return '${condition.label}$branch$rescue';
  }
}

/// 推理链折叠区：factors 逐条 rule｜reason｜source
class _FactorsExpansion extends StatelessWidget {
  const _FactorsExpansion({required this.factors});

  final List<VerdictFactor> factors;

  @override
  Widget build(BuildContext context) {
    if (factors.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        iconColor: AppColors.guhe,
        collapsedIconColor: AppColors.guhe,
        title: Text(
          '推理链',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.gutong,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          for (final factor in factors) _FactorRow(factor: factor),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});

  final VerdictFactor factor;

  @override
  Widget build(BuildContext context) {
    final effectColor = switch (factor.effect) {
      VerdictEffect.fu => AppColors.jishenGreen,
      VerdictEffect.yi => AppColors.zhusha,
      VerdictEffect.suspend => AppColors.gutong,
      VerdictEffect.neutral => AppColors.huise,
    };
    return Semantics(
      label: '${factor.effect.name}：${factor.rule}，${factor.reason}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: effectColor.withOpacity(0.1),
                border: Border.all(color: effectColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                factor.effect.name,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: effectColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${factor.rule}｜${factor.reason}',
                    style: AppTextStyles.antiqueBody.copyWith(height: 1.5),
                  ),
                  Text(
                    factor.source,
                    style: AppTextStyles.antiqueLabel.copyWith(
                      color: AppColors.qianhe,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
