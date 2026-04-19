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
        _buildFinalPositionSection(),
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

  Widget _buildFinalPositionSection() {
    final finalPos = result.finalPosition;
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '最终落宫'),
          const AntiqueDivider(),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.zhusha.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.zhusha.withOpacity(0.4)),
              ),
              child: Text(
                '${finalPos.name} · ${finalPos.keyword}',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.zhusha,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('吉凶', finalPos.fortune),
          _buildInfoRow('五行', finalPos.wuXing),
          _buildInfoRow('方位', finalPos.direction),
          const SizedBox(height: 6),
          Text(
            finalPos.description,
            style: AppTextStyles.antiqueBody.copyWith(height: 1.6),
          ),
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
