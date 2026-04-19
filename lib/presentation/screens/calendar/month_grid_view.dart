import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'calendar_viewmodel.dart';
import 'month_cell_info.dart';

class MonthGridView extends StatelessWidget {
  const MonthGridView({super.key});

  static const _weekdayHeaders = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final days = _buildDays(vm.displayedMonth);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: _weekdayHeaders
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w,
                            style: AppTextStyles.antiqueLabel.copyWith(
                              color: AppColors.huise,
                            )),
                      ),
                    ))
                .toList(),
          ),
        ),
        for (int row = 0; row < 6; row++)
          SizedBox(
            height: 48,
            child: Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _Cell(
                      date: days[row * 7 + col],
                      inMonth: days[row * 7 + col].month ==
                          vm.displayedMonth.month,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Returns 42 days — the current month padded to a full Sun–Sat grid.
  List<DateTime> _buildDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    // weekday: Mon=1..Sun=7; we want offset from Sunday (0..6)
    final offsetFromSunday = first.weekday % 7;
    final gridStart = first.subtract(Duration(days: offsetFromSunday));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.date, required this.inMonth});
  final DateTime date;
  final bool inMonth;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final info = MonthCellInfo.of(date);
    final today = DateTime.now();
    final isToday = _sameDay(date, today);
    final isSelected = _sameDay(date, vm.selectedDate);

    // danjinLight does not exist in AppColors — using xiangseDeep (warm parchment)
    // for today highlight; xiangseLight for selected day.
    final bg = isToday
        ? AppColors.xiangseDeep
        : isSelected
            ? AppColors.xiangseLight
            : null;
    final border = isToday
        ? Border.all(color: AppColors.dailan, width: 1.2)
        : null;

    return InkWell(
      key: const ValueKey('month-cell'),
      onTap: () => vm.selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTextStyles.antiqueSection.copyWith(
                color: inMonth ? AppColors.xuanse : AppColors.huiseLight,
              ),
            ),
            Text(
              info.label,
              style: AppTextStyles.antiqueLabel.copyWith(
                color: inMonth ? AppColors.huise : AppColors.huiseLight,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            _Dots(info: info),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.info});
  final MonthCellInfo info;

  @override
  Widget build(BuildContext context) {
    final dots = <Widget>[];
    if (info.hasJieQi) dots.add(_dot(AppColors.zhusha));
    if (info.hasMoonPhase) dots.add(_dot(AppColors.danjin));
    if (info.hasFestival) dots.add(_dot(AppColors.dailan));
    if (dots.isEmpty) return const SizedBox(height: 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final d in dots)
          Padding(padding: const EdgeInsets.all(1), child: d),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
