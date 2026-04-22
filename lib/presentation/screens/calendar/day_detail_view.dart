import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import 'calendar_viewmodel.dart';
import 'widgets/almanac_header.dart';
import 'widgets/four_pillars_card.dart';
import 'widgets/moon_phase_kongwang.dart';
import 'widgets/pengzu_card.dart';
import 'widgets/time_hour_bar.dart';
import 'widgets/yiji_panel.dart';

/// 日详情内容区（不包含自身滚动）。
/// 滚动由外层 CalendarScreen 的 SingleChildScrollView 统一管理，
/// 让月视图与详情作为整体一起滚动。
class DayDetailView extends StatelessWidget {
  const DayDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final almanac = vm.currentAlmanac;
    final hour = vm.currentHourAlmanac;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.danjin.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          AlmanacHeader(almanac: almanac),
          const SizedBox(height: 16),
          FourPillarsCard(almanac: almanac, hourGanZhi: hour.ganZhi),
          const SizedBox(height: 16),
          YijiPanel(yi: almanac.yi, ji: almanac.ji),
          const SizedBox(height: 16),
          TimeHourBar(
            hours: almanac.twelveHours,
            selectedZhi: vm.selectedHour ?? hour.zhi,
            onSelect: vm.selectHour,
          ),
          MoonPhaseKongwang(
            yueXiang: almanac.yueXiang,
            kongWang: almanac.kongWang,
          ),
          PengzuCard(gan: almanac.pengZuGan, zhi: almanac.pengZuZhi),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
