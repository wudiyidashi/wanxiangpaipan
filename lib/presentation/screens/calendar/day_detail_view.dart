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

class DayDetailView extends StatefulWidget {
  const DayDetailView({super.key});

  @override
  State<DayDetailView> createState() => _DayDetailViewState();
}

class _DayDetailViewState extends State<DayDetailView> {
  final ScrollController _scroll = ScrollController();
  DateTime? _lastSelected;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final almanac = vm.currentAlmanac;
    final hour = vm.currentHourAlmanac;

    // 选中日变了 → 滚到顶
    if (_lastSelected != vm.selectedDate) {
      _lastSelected = vm.selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }

    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
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
      ),
    );
  }
}
