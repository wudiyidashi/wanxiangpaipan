import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../models/xiaoliuren_result.dart';
import 'xiaoliuren_chain_view.dart';

class XiaoLiuRenResultScreen extends StatelessWidget {
  const XiaoLiuRenResultScreen({
    super.key,
    required this.result,
  });

  final XiaoLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    return DivinationResultPage(
      result: result,
      title: '小六壬排课结果',
      fallbackQuestion: result.questionId.isNotEmpty ? result.questionId : null,
      sectionSpacing: 12,
      buildSections: (context, question) => [
        ExtendedInfoSection(
          castTime: result.castTime,
          lunarInfo: result.lunarInfo,
          liuShen: const [],
        ),
        _buildQuestionSection(question),
        _buildOverviewSection(),
        _buildSourceSection(),
        _buildChainSection(),
        XiaoLiuRenPalaceInfoSection(result: result),
      ],
    );
  }

  Widget _buildQuestionSection(String question) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '占问事项'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Text(
            question.isEmpty ? '未设置' : question,
            style: AppTextStyles.antiqueBody.copyWith(
              color: question.isEmpty ? AppColors.qianhe : AppColors.xuanse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '排盘总览'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('方式', result.source.methodLabel),
          _buildInfoRow('盘式', result.palaceMode.displayName),
          _buildInfoRow(
            '第一段',
            '${result.source.firstLabel} ${result.source.firstNumber} '
                '→ ${result.monthPosition.name}',
          ),
          _buildInfoRow(
            '第二段',
            '${result.source.secondLabel} ${result.source.secondNumber} '
                '→ ${result.dayPosition.name}',
          ),
          _buildInfoRow(
            '第三段',
            '${result.source.thirdLabel} ${result.source.thirdNumber} '
                '→ ${result.hourPosition.name}',
          ),
          _buildInfoRow(
            '最终落宫',
            '${result.finalPosition.name}（${result.finalPosition.fortune}）',
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection() {
    final source = result.source;
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '起课依据'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('规则', source.rule),
          _buildInfoRow(source.firstLabel, '${source.firstNumber}'),
          _buildInfoRow(source.secondLabel, '${source.secondNumber}'),
          _buildInfoRow(source.thirdLabel, '${source.thirdNumber}'),
          if (source.hourZhi != null) _buildInfoRow('时支', source.hourZhi!),
          if (source.note != null) ...[
            const SizedBox(height: 4),
            Text(
              source.note!,
              style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChainSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '三段顺推'),
          const AntiqueDivider(),
          const SizedBox(height: 14),
          XiaoLiuRenChainView(
            firstStepLabel: result.source.firstLabel,
            firstStepNumber: result.source.firstNumber,
            firstPosition: result.monthPosition,
            secondStepLabel: result.source.secondLabel,
            secondStepNumber: result.source.secondNumber,
            secondPosition: result.dayPosition,
            thirdStepLabel: result.source.thirdLabel,
            thirdStepNumber: result.source.thirdNumber,
            thirdPosition: result.hourPosition,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.antiqueBody),
          ),
        ],
      ),
    );
  }
}

class XiaoLiuRenPalaceInfoSection extends StatefulWidget {
  const XiaoLiuRenPalaceInfoSection({
    super.key,
    required this.result,
  });

  final XiaoLiuRenResult result;

  @override
  State<XiaoLiuRenPalaceInfoSection> createState() =>
      _XiaoLiuRenPalaceInfoSectionState();
}

class _XiaoLiuRenPalaceInfoSectionState
    extends State<XiaoLiuRenPalaceInfoSection> {
  static const _defaultStepIndex = 0;

  late int _selectedStepIndex;

  @override
  void initState() {
    super.initState();
    _selectedStepIndex = _defaultStepIndex;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final selectedStep = steps[_selectedStepIndex];
    final position = selectedStep.position;

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '宫位信息'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              steps.length,
              (index) => _buildSelectorChip(
                step: steps[index],
                index: index,
                selected: index == _selectedStepIndex,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danjin),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedStep.title} · ${position.name}',
                  style: AppTextStyles.antiqueSection.copyWith(
                    color: AppColors.xuanse,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow('关键词', position.keyword),
                _buildInfoRow('吉凶', position.fortune),
                _buildInfoRow('五行', position.wuXing),
                _buildInfoRow('方位', position.direction),
                const SizedBox(height: 6),
                Text(
                  position.description,
                  style: AppTextStyles.antiqueBody.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_PalaceInfoStep> get _steps => [
        _PalaceInfoStep(title: '第一段', position: widget.result.monthPosition),
        _PalaceInfoStep(title: '第二段', position: widget.result.dayPosition),
        _PalaceInfoStep(title: '第三段', position: widget.result.hourPosition),
      ];

  Widget _buildSelectorChip({
    required _PalaceInfoStep step,
    required int index,
    required bool selected,
  }) {
    final color = selected ? AppColors.zhusha : AppColors.guhe;
    return InkWell(
      key: ValueKey('xiaoliuren-palace-step-$index'),
      onTap: () {
        setState(() {
          _selectedStepIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.zhusha.withOpacity(0.08)
              : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.zhusha.withOpacity(0.45)
                : AppColors.danjin,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: AppTextStyles.antiqueLabel.copyWith(
                color: AppColors.guhe,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.position.name,
              style: AppTextStyles.antiqueBody.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.antiqueBody),
          ),
        ],
      ),
    );
  }
}

class _PalaceInfoStep {
  const _PalaceInfoStep({
    required this.title,
    required this.position,
  });

  final String title;
  final XiaoLiuRenPosition position;
}
