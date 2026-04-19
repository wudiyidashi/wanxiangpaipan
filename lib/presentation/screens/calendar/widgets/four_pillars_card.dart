import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';
import '../../../widgets/antique/antique.dart';

class FourPillarsCard extends StatelessWidget {
  const FourPillarsCard({
    super.key,
    required this.almanac,
    required this.hourGanZhi,
  });

  final DailyAlmanac almanac;
  final String hourGanZhi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AntiqueCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _pillar('年柱', almanac.yearGZ),
            _pillar('月柱', almanac.monthGZ),
            _pillar('日柱', almanac.dayGZ),
            _pillar('时柱', hourGanZhi, gzKey: const Key('pillar-hour-gz')),
          ],
        ),
      ),
    );
  }

  Widget _pillar(String label, String gz, {Key? gzKey}) => Column(
        children: [
          Text(label,
              style: AppTextStyles.antiqueLabel.copyWith(
                color: AppColors.huise,
              )),
          const SizedBox(height: 4),
          Text(gz,
              key: gzKey,
              style: AppTextStyles.antiqueSection.copyWith(
                color: AppColors.xuanse,
                fontWeight: FontWeight.w600,
              )),
        ],
      );
}
