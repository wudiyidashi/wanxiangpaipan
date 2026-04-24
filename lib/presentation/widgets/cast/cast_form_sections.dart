import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../antique/antique.dart';

class CastQuestionInputSection extends StatelessWidget {
  const CastQuestionInputSection({
    super.key,
    required this.controller,
    this.label = '占问事项',
    this.hint = '请输入您想占问的事项...',
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueTextField(
          controller: controller,
          hint: hint,
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }
}

class CastLabeledDropdown<T> extends StatelessWidget {
  const CastLabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<AntiqueDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<T>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class CastTimeSummaryCard extends StatelessWidget {
  const CastTimeSummaryCard({
    super.key,
    required this.ganZhiText,
    required this.dateTimeText,
    required this.note,
    required this.accentColor,
    this.title = '起卦时间',
    this.isLoading = false,
    this.onPickDate,
    this.onPickTime,
    this.onUseCurrentTime,
  });

  final String title;
  final String ganZhiText;
  final String dateTimeText;
  final String note;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback? onPickDate;
  final VoidCallback? onPickTime;
  final VoidCallback? onUseCurrentTime;

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onPickDate != null || onPickTime != null || onUseCurrentTime != null;
    final actionStyle = TextButton.styleFrom(
      foregroundColor: accentColor,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AntiqueSectionTitle(title: title),
          const AntiqueDivider(),
          const SizedBox(height: 10),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                ganZhiText,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.antiqueTitle.copyWith(
                  fontSize: 16,
                  color: accentColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateTimeText,
            textAlign: TextAlign.center,
            style: AppTextStyles.antiqueLabel.copyWith(
              color: AppColors.guhe,
              fontSize: 12,
            ),
          ),
          if (hasActions) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                if (onPickDate != null)
                  TextButton.icon(
                    onPressed: isLoading ? null : onPickDate,
                    style: actionStyle,
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: const Text('改日期'),
                  ),
                if (onPickTime != null)
                  TextButton.icon(
                    onPressed: isLoading ? null : onPickTime,
                    style: actionStyle,
                    icon: const Icon(Icons.access_time, size: 14),
                    label: const Text('改时间'),
                  ),
                if (onUseCurrentTime != null)
                  TextButton(
                    onPressed: isLoading ? null : onUseCurrentTime,
                    style: actionStyle,
                    child: const Text('当前'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            note,
            textAlign: TextAlign.center,
            style: AppTextStyles.antiqueLabel.copyWith(
              color: AppColors.guhe.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class CastTimeActionSection extends StatelessWidget {
  const CastTimeActionSection({
    super.key,
    required this.ganZhiText,
    required this.dateTimeText,
    required this.note,
    required this.accentColor,
    required this.isLoading,
    required this.onCast,
    required this.onPickDate,
    required this.onPickTime,
    required this.onUseCurrentTime,
    this.title = '起卦时间',
    this.buttonLabel = '起卦',
    this.loadingLabel = '起卦中...',
  });

  final String title;
  final String ganZhiText;
  final String dateTimeText;
  final String note;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback? onCast;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onUseCurrentTime;
  final String buttonLabel;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CastTimeSummaryCard(
          title: title,
          ganZhiText: ganZhiText,
          dateTimeText: dateTimeText,
          note: note,
          accentColor: accentColor,
          isLoading: isLoading,
          onPickDate: onPickDate,
          onPickTime: onPickTime,
          onUseCurrentTime: onUseCurrentTime,
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: isLoading ? loadingLabel : buttonLabel,
          onPressed: isLoading ? null : onCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }
}

class CastNumberField extends StatelessWidget {
  const CastNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = '正整数',
  });

  final String label;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: AppColors.danjin),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.antiqueBody,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.qianhe,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class CastNumberPairCard extends StatelessWidget {
  const CastNumberPairCard({
    super.key,
    required this.title,
    required this.firstLabel,
    required this.firstController,
    required this.secondLabel,
    required this.secondController,
    required this.note,
    this.hintText = '正整数',
  });

  final String title;
  final String firstLabel;
  final TextEditingController firstController;
  final String secondLabel;
  final TextEditingController secondController;
  final String note;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: title),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CastNumberField(
                  label: firstLabel,
                  controller: firstController,
                  hintText: hintText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CastNumberField(
                  label: secondLabel,
                  controller: secondController,
                  hintText: hintText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class CastNumberTripleCard extends StatelessWidget {
  const CastNumberTripleCard({
    super.key,
    required this.title,
    required this.labels,
    required this.controllers,
    required this.note,
    this.hintText = '正整数',
  })  : assert(labels.length == 3),
        assert(controllers.length == 3);

  final String title;
  final List<String> labels;
  final List<TextEditingController> controllers;
  final String note;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: title),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: CastNumberField(
                    label: labels[i],
                    controller: controllers[i],
                    hintText: hintText,
                  ),
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
