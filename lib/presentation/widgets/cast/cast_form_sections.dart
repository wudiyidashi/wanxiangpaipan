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
    required this.lunarText,
    required this.note,
    required this.accentColor,
    this.title = '当前时辰',
  });

  final String title;
  final String ganZhiText;
  final String lunarText;
  final String note;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: title),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Text(
            ganZhiText,
            style: AppTextStyles.antiqueTitle.copyWith(
              fontSize: 15,
              color: accentColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lunarText,
            style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
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
