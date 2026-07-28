import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../models/qimen_enums.dart';

String qimenJuMethodLabel(QimenJuMethod value) => switch (value) {
      QimenJuMethod.chaiBu => '拆补法',
      QimenJuMethod.maoShan => '茅山法',
      QimenJuMethod.zhiRun => '置闰法',
      QimenJuMethod.manual => '手动定局',
    };

String qimenTimeBasisLabel(QimenTimeBasis value) => switch (value) {
      QimenTimeBasis.localCivil => '当地民用时间',
      QimenTimeBasis.beijing => '北京时间',
      QimenTimeBasis.trueSolar => '真太阳时',
    };

String qimenDayBoundaryLabel(QimenDayBoundary value) => switch (value) {
      QimenDayBoundary.ziInitial => '子初换日（23:00）',
      QimenDayBoundary.midnight => '午夜换日（00:00）',
    };

String qimenHostingModeLabel(QimenHostingMode value) => switch (value) {
      QimenHostingMode.kunTwo => '中五寄坤二',
      QimenHostingMode.yangEightYinTwo => '阳遁寄艮八、阴遁寄坤二',
    };

String qimenHiddenStemModeLabel(QimenHiddenStemMode value) => switch (value) {
      QimenHiddenStemMode.dutyDoorHourStem => '值使起时干飞布',
      QimenHiddenStemMode.doorOriginEarthStem => '门本位地盘干',
    };

String qimenQuestionCategoryLabel(QimenQuestionCategory value) =>
    switch (value) {
      QimenQuestionCategory.general => '综合',
      QimenQuestionCategory.career => '事业',
      QimenQuestionCategory.wealth => '财运',
      QimenQuestionCategory.relationship => '感情',
      QimenQuestionCategory.health => '健康',
      QimenQuestionCategory.study => '学业',
      QimenQuestionCategory.travel => '出行',
      QimenQuestionCategory.litigation => '诉讼',
    };

class QimenTimeCastSection extends StatelessWidget {
  const QimenTimeCastSection({
    super.key,
    required this.castTime,
    required this.juMethod,
    required this.timeBasis,
    required this.longitudeController,
    required this.enabled,
    required this.onPickDate,
    required this.onPickTime,
    required this.onUseCurrentTime,
    required this.onJuMethodChanged,
    required this.onTimeBasisChanged,
    required this.longitudeValidator,
  });

  final DateTime castTime;
  final QimenJuMethod juMethod;
  final QimenTimeBasis timeBasis;
  final TextEditingController longitudeController;
  final bool enabled;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onUseCurrentTime;
  final ValueChanged<QimenJuMethod> onJuMethodChanged;
  final ValueChanged<QimenTimeBasis> onTimeBasisChanged;
  final FormFieldValidator<String> longitudeValidator;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AntiqueSectionTitle(
            title: '自动时间起局',
            subtitle: '按所选时间口径生成四柱、节气与局数',
          ),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Semantics(
            label: '起局时间 ${_formatDateTime(castTime)}',
            child: Text(
              _formatDateTime(castTime),
              textAlign: TextAlign.center,
              style: AppTextStyles.antiqueTitle.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                key: const Key('qimen-pick-date'),
                onPressed: enabled ? onPickDate : null,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('日期'),
              ),
              TextButton.icon(
                key: const Key('qimen-pick-time'),
                onPressed: enabled ? onPickTime : null,
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('时间'),
              ),
              TextButton.icon(
                key: const Key('qimen-use-now'),
                onPressed: enabled ? onUseCurrentTime : null,
                icon: const Icon(Icons.update, size: 16),
                label: const Text('现在'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<QimenJuMethod>(
            key: const Key('qimen-ju-method'),
            label: '定局法',
            value: juMethod,
            values: const <QimenJuMethod>[
              QimenJuMethod.chaiBu,
              QimenJuMethod.maoShan,
              QimenJuMethod.zhiRun,
            ],
            labelFor: qimenJuMethodLabel,
            enabled: enabled,
            onChanged: onJuMethodChanged,
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<QimenTimeBasis>(
            key: const Key('qimen-time-basis'),
            label: '时间基准',
            value: timeBasis,
            values: QimenTimeBasis.values,
            labelFor: qimenTimeBasisLabel,
            enabled: enabled,
            onChanged: onTimeBasisChanged,
          ),
          if (timeBasis == QimenTimeBasis.trueSolar) ...[
            const SizedBox(height: 12),
            Text('经度', style: AppTextStyles.antiqueLabel),
            const SizedBox(height: 6),
            TextFormField(
              key: const Key('qimen-longitude'),
              controller: longitudeController,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[-+0-9.]')),
              ],
              validator: longitudeValidator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: qimenInputDecoration(
                hintText: '例如 116.4074',
                helperText: '东经为正、西经为负，范围 -180 至 180',
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) =>
      '${value.year}年${_two(value.month)}月${_two(value.day)}日 '
      '${_two(value.hour)}:${_two(value.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class QimenManualCastSection extends StatelessWidget {
  const QimenManualCastSection({
    super.key,
    required this.ganZhiOptions,
    required this.solarTerms,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.solarTerm,
    required this.dun,
    required this.juNumber,
    required this.yuan,
    required this.enabled,
    required this.onYearGanZhiChanged,
    required this.onMonthGanZhiChanged,
    required this.onDayGanZhiChanged,
    required this.onHourGanZhiChanged,
    required this.onSolarTermChanged,
    required this.onDunChanged,
    required this.onJuNumberChanged,
    required this.onYuanChanged,
  });

  final List<String> ganZhiOptions;
  final List<String> solarTerms;
  final String? yearGanZhi;
  final String? monthGanZhi;
  final String? dayGanZhi;
  final String? hourGanZhi;
  final String? solarTerm;
  final QimenDun? dun;
  final int? juNumber;
  final QimenYuan? yuan;
  final bool enabled;
  final ValueChanged<String?> onYearGanZhiChanged;
  final ValueChanged<String?> onMonthGanZhiChanged;
  final ValueChanged<String?> onDayGanZhiChanged;
  final ValueChanged<String?> onHourGanZhiChanged;
  final ValueChanged<String?> onSolarTermChanged;
  final ValueChanged<QimenDun?> onDunChanged;
  final ValueChanged<int?> onJuNumberChanged;
  final ValueChanged<QimenYuan?> onYuanChanged;

  @override
  Widget build(BuildContext context) {
    final pillarFields = <Widget>[
      _NullableDropdown<String>(
        key: const Key('qimen-year-pillar'),
        label: '年柱',
        value: yearGanZhi,
        values: ganZhiOptions,
        labelFor: (value) => value,
        enabled: enabled,
        onChanged: onYearGanZhiChanged,
      ),
      _NullableDropdown<String>(
        key: const Key('qimen-month-pillar'),
        label: '月柱',
        value: monthGanZhi,
        values: ganZhiOptions,
        labelFor: (value) => value,
        enabled: enabled,
        onChanged: onMonthGanZhiChanged,
      ),
      _NullableDropdown<String>(
        key: const Key('qimen-day-pillar'),
        label: '日柱',
        value: dayGanZhi,
        values: ganZhiOptions,
        labelFor: (value) => value,
        enabled: enabled,
        onChanged: onDayGanZhiChanged,
      ),
      _NullableDropdown<String>(
        key: const Key('qimen-hour-pillar'),
        label: '时柱',
        value: hourGanZhi,
        values: ganZhiOptions,
        labelFor: (value) => value,
        enabled: enabled,
        onChanged: onHourGanZhiChanged,
      ),
    ];

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AntiqueSectionTitle(
            title: '手动校盘',
            subtitle: '四柱与定局事实必须逐项明确选择',
          ),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: _spaced(pillarFields, 12),
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: pillarFields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: pillarFields[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: pillarFields[2]),
                      const SizedBox(width: 12),
                      Expanded(child: pillarFields[3]),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _NullableDropdown<String>(
            key: const Key('qimen-solar-term'),
            label: '节气',
            value: solarTerm,
            values: solarTerms,
            labelFor: (value) => value,
            enabled: enabled,
            onChanged: onSolarTermChanged,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = <Widget>[
                _NullableDropdown<QimenDun>(
                  key: const Key('qimen-dun'),
                  label: '阴阳遁',
                  value: dun,
                  values: QimenDun.values,
                  labelFor: (value) => '${value.label}遁',
                  enabled: enabled,
                  onChanged: onDunChanged,
                ),
                _NullableDropdown<int>(
                  key: const Key('qimen-ju-number'),
                  label: '局数',
                  value: juNumber,
                  values: List<int>.generate(9, (index) => index + 1),
                  labelFor: (value) => '$value 局',
                  enabled: enabled,
                  onChanged: onJuNumberChanged,
                ),
                _NullableDropdown<QimenYuan>(
                  key: const Key('qimen-yuan'),
                  label: '三元',
                  value: yuan,
                  values: QimenYuan.values,
                  labelFor: (value) => value.label,
                  enabled: enabled,
                  onChanged: onYuanChanged,
                ),
              ];
              if (constraints.maxWidth < 500) {
                return Column(children: _spaced(fields, 12));
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < fields.length; index++) ...[
                    Expanded(child: fields[index]),
                    if (index < fields.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> children, double spacing) =>
      <Widget>[
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) SizedBox(height: spacing),
        ],
      ];
}

class QimenAdvancedOptionsSection extends StatelessWidget {
  const QimenAdvancedOptionsSection({
    super.key,
    required this.showDayBoundary,
    required this.dayBoundary,
    required this.hostingMode,
    required this.hiddenStemMode,
    required this.enabled,
    required this.onDayBoundaryChanged,
    required this.onHostingModeChanged,
    required this.onHiddenStemModeChanged,
  });

  final bool showDayBoundary;
  final QimenDayBoundary dayBoundary;
  final QimenHostingMode hostingMode;
  final QimenHiddenStemMode hiddenStemMode;
  final bool enabled;
  final ValueChanged<QimenDayBoundary> onDayBoundaryChanged;
  final ValueChanged<QimenHostingMode> onHostingModeChanged;
  final ValueChanged<QimenHiddenStemMode> onHiddenStemModeChanged;

  @override
  Widget build(BuildContext context) {
    final summary = <String>[
      if (showDayBoundary) qimenDayBoundaryLabel(dayBoundary),
      qimenHostingModeLabel(hostingMode),
      qimenHiddenStemModeLabel(hiddenStemMode),
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.48),
        border: Border.all(color: AppColors.danjin.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        key: const Key('qimen-advanced-options'),
        enabled: enabled,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('高级口径', style: AppTextStyles.antiqueSection),
        subtitle: Text(
          summary,
          style: AppTextStyles.antiqueLabel,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          if (showDayBoundary) ...[
            _LabeledDropdown<QimenDayBoundary>(
              key: const Key('qimen-day-boundary'),
              label: '换日规则',
              value: dayBoundary,
              values: QimenDayBoundary.values,
              labelFor: qimenDayBoundaryLabel,
              enabled: enabled,
              onChanged: onDayBoundaryChanged,
            ),
            const SizedBox(height: 12),
          ],
          _LabeledDropdown<QimenHostingMode>(
            key: const Key('qimen-hosting-mode'),
            label: '中五寄宫',
            value: hostingMode,
            values: QimenHostingMode.values,
            labelFor: qimenHostingModeLabel,
            enabled: enabled,
            onChanged: onHostingModeChanged,
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<QimenHiddenStemMode>(
            key: const Key('qimen-hidden-stem-mode'),
            label: '暗干口径',
            value: hiddenStemMode,
            values: QimenHiddenStemMode.values,
            labelFor: qimenHiddenStemModeLabel,
            enabled: enabled,
            onChanged: onHiddenStemModeChanged,
          ),
        ],
      ),
    );
  }
}

InputDecoration qimenInputDecoration({
  String? hintText,
  String? helperText,
  String? labelText,
}) =>
    InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.danjin),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.danjin),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.zhusha, width: 1.5),
      ),
    );

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: AntiqueDropdown<T>(
              value: value,
              items: values
                  .map(
                    (value) => AntiqueDropdownItem<T>(
                      value: value,
                      label: labelFor(value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NullableDropdown<T> extends StatelessWidget {
  const _NullableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) labelFor;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: qimenInputDecoration(labelText: label),
      hint: const Text('请选择'),
      items: values
          .map(
            (value) => DropdownMenuItem<T>(
              value: value,
              child: Text(labelFor(value), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      validator: (value) => value == null ? '请选择$label' : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: enabled ? onChanged : null,
    );
  }
}
