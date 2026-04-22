import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/daily_almanac.dart';

/// 四柱干支板：去卡片化，顶边淡金 + 轻渐变底，干支大字居中。
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.danjin.withOpacity(0.10),
              AppColors.danjin.withOpacity(0.0),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            top: BorderSide(color: AppColors.danjin, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pillar('年', almanac.yearGZ),
            _pillar('月', almanac.monthGZ),
            _pillar('日', almanac.dayGZ),
            _pillar('时', hourGanZhi, gzKey: const Key('pillar-hour-gz')),
          ],
        ),
      ),
    );
  }

  Widget _pillar(String label, String gz, {Key? gzKey}) => Column(
        children: [
          Text(
            label,
            style: AppTextStyles.antiqueLabel.copyWith(
              fontSize: 11,
              color: AppColors.guhe,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            gz,
            key: gzKey,
            style: AppTextStyles.antiqueTitle.copyWith(
              fontSize: 18,
              color: AppColors.xuanse,
              letterSpacing: 2,
            ),
          ),
        ],
      );
}
