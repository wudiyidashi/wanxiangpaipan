import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/shared/almanac_service.dart';
import '../../widgets/antique/antique.dart';
import 'calendar_gua_context.dart';
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
    this.guaContext,
  });

  final bool chromeless;
  final CalendarViewModel? viewModel;
  final AlmanacService? almanacService;
  final DateTime Function()? now;

  /// 应期模式卦上下文；null 时为通用黄历（与原行为一致）
  final CalendarGuaContext? guaContext;

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
      child: _CalendarBody(
        scrollController: _scroll,
        guaContext: widget.guaContext,
      ),
    );
    if (widget.chromeless) return body;
    return AntiqueScaffold(
      appBar: AntiqueAppBar(
        title: widget.guaContext == null ? '历法' : '应期日历',
      ),
      body: body,
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.scrollController, this.guaContext});
  final ScrollController scrollController;
  final CalendarGuaContext? guaContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (guaContext != null) _GuaContextBanner(guaContext: guaContext!),
        const _Topbar(),
        const AntiqueDivider(),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                MonthGridView(guaContext: guaContext),
                const AntiqueDivider(),
                DayDetailView(guaContext: guaContext),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 应期模式横幅：关联卦信息 + 角标图例 + 退出
class _GuaContextBanner extends StatelessWidget {
  const _GuaContextBanner({required this.guaContext});
  final CalendarGuaContext guaContext;

  static const Map<GuaDayMarkerType, String> _legends = {
    GuaDayMarkerType.ying: '应期',
    GuaDayMarkerType.chong: '冲用神',
    GuaDayMarkerType.he: '合用神',
    GuaDayMarkerType.kong: '用神空',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.danjin.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guaContext.title,
                  style: AppTextStyles.antiqueLabel.copyWith(
                    color: AppColors.gutong,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final marker in GuaDayMarkerType.values)
                      Text(
                        '${marker.label}=${_legends[marker]}',
                        style: TextStyle(fontSize: 9, color: marker.color),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (Navigator.of(context).canPop())
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('退出'),
            ),
        ],
      ),
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
