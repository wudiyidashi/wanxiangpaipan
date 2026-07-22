import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../../presentation/widgets/antique/antique.dart';

/// 应期推算卡：候选应期以胶囊排布，标题栏右侧进入应期日历。
class YingQiCard extends StatelessWidget {
  const YingQiCard({
    super.key,
    required this.candidates,
    this.onViewCalendar,
  });

  final List<YingQiCandidate> candidates;
  final VoidCallback? onViewCalendar;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(
            title: '应期推算',
            trailing: onViewCalendar == null
                ? null
                : TextButton.icon(
                    onPressed: onViewCalendar,
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: const Text('应期日历'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final candidate in candidates.take(6))
                _CandidatePill(candidate: candidate),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '应期是条件触发窗口，不代表事情必成；须结合事体缓急定日月年。',
            style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.huise),
          ),
        ],
      ),
    );
  }
}

/// 单个应期候选胶囊：日期醒目 + 理由说明
class _CandidatePill extends StatelessWidget {
  const _CandidatePill({required this.candidate});

  final YingQiCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danjin.withOpacity(0.12),
        border: Border.all(color: AppColors.danjin.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${candidate.branch}${candidate.scale.name}',
            style: AppTextStyles.antiqueBody.copyWith(
              color: AppColors.gutong,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            candidate.reason,
            style: AppTextStyles.antiqueLabel.copyWith(
              color: AppColors.guhe,
            ),
          ),
        ],
      ),
    );
  }
}
