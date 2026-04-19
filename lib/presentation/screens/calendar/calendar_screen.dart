import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/shared/almanac_service.dart';
import '../../widgets/antique/antique.dart';
import 'calendar_viewmodel.dart';
import 'day_detail_view.dart';
import 'month_grid_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.chromeless = false,
    this.viewModel,
    this.almanacService,
    this.now,
  });

  final bool chromeless;
  final CalendarViewModel? viewModel;
  final AlmanacService? almanacService;
  final DateTime Function()? now;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarViewModel _vm;
  late final bool _ownsVm;
  final ScrollController _scroll = ScrollController();
  DateTime? _lastSelected;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _vm = widget.viewModel!;
      _ownsVm = false;
    } else {
      _vm = CalendarViewModel(
        service: widget.almanacService ?? const AlmanacService(),
        now: widget.now,
      );
      _ownsVm = true;
    }
    _vm.addListener(_onVmChange);
  }

  void _onVmChange() {
    if (_lastSelected != _vm.selectedDate) {
      _lastSelected = _vm.selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _scroll.dispose();
    if (_ownsVm) _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ChangeNotifierProvider<CalendarViewModel>.value(
      value: _vm,
      child: _CalendarBody(scrollController: _scroll),
    );
    if (widget.chromeless) return body;
    return AntiqueScaffold(
      appBar: const AntiqueAppBar(title: '历法'),
      body: body,
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Topbar(),
        const AntiqueDivider(),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: const Column(
              children: [
                MonthGridView(),
                AntiqueDivider(),
                DayDetailView(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final m = vm.displayedMonth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('calendar-backward'),
            icon: const Icon(Icons.chevron_left, color: AppColors.xuanse),
            onPressed: () => vm.goToMonth(
              DateTime(m.year, m.month - 1, 1),
            ),
          ),
          Expanded(
            child: Center(
              child: InkWell(
                key: const Key('calendar-month-title'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: m,
                    firstDate: DateTime(1900, 1, 1),
                    lastDate: DateTime(2099, 12, 31),
                    helpText: '选择月份',
                    fieldLabelText: '年月',
                  );
                  if (picked != null) {
                    vm.goToMonth(DateTime(picked.year, picked.month, 1));
                  }
                },
                child: Text(
                  '${m.year}年${m.month}月',
                  style: AppTextStyles.antiqueTitle.copyWith(
                    color: AppColors.xuanse,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('calendar-forward'),
            icon: const Icon(Icons.chevron_right, color: AppColors.xuanse),
            onPressed: () => vm.goToMonth(
              DateTime(m.year, m.month + 1, 1),
            ),
          ),
          if (!vm.isDisplayedMonthToday)
            TextButton(
              onPressed: vm.selectToday,
              child: const Text('今日'),
            ),
        ],
      ),
    );
  }
}
