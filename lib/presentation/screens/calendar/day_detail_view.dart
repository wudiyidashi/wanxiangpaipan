import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'calendar_viewmodel.dart';
import 'widgets/almanac_header.dart';
import 'widgets/festival_banner.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FestivalBanner(festivals: almanac.festivals),
        AlmanacHeader(almanac: almanac),
        FourPillarsCard(almanac: almanac, hourGanZhi: hour.ganZhi),
        YijiPanel(yi: almanac.yi, ji: almanac.ji),
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
        const SizedBox(height: 24),
      ],
    );
  }
}
