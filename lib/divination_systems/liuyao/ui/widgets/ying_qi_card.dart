import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../../presentation/widgets/antique/antique.dart';

/// 应期推算卡：候选应期列表 + 进入应期日历入口。
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
          const AntiqueSectionTitle(title: '应期推算'),
          const SizedBox(height: 8),
          for (final candidate in candidates.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  AntiqueTag(
                    label: '${candidate.branch}${candidate.scale.name}',
                    color: AppColors.gutong,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      candidate.reason,
                      style: AppTextStyles.antiqueBody
                          .copyWith(color: AppColors.xuanse),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '应期为推算参考，须结合事体缓急定日月年。',
            style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.huise),
          ),
          if (onViewCalendar != null) ...[
            const SizedBox(height: 10),
            AntiqueButton(
              label: '查看应期日历',
              onPressed: onViewCalendar!,
            ),
          ],
        ],
      ),
    );
  }
}
