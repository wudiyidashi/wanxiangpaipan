import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../models/meihua_result.dart';
import 'meihua_hexagram_diagram.dart';

class MeiHuaResultScreen extends StatelessWidget {
  const MeiHuaResultScreen({
    super.key,
    required this.result,
  });

  final MeiHuaResult result;

  @override
  Widget build(BuildContext context) {
    return DivinationResultPage(
      result: result,
      title: '梅花易数排盘结果',
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
        _buildHexagramStructureSection(),
        _buildBodyUseSection(),
        _buildWuXingSection(),
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
          _buildInfoRow('本卦', result.benGua.name),
          _buildInfoRow('变卦', result.bianGua.name),
          _buildInfoRow('互卦', result.huGua.name),
          _buildInfoRow('动爻', result.movingLineLabel),
          _buildInfoRow('体卦', '${result.tiGua.name}·${result.tiGua.symbol}'),
          _buildInfoRow(
              '用卦', '${result.yongGua.name}·${result.yongGua.symbol}'),
          _buildInfoRow('体用', result.wuXingRelation),
        ],
      ),
    );
  }

  Widget _buildSourceSection() {
    final source = result.source;
    final rows = <Widget>[
      _buildInfoRow('方式', source.methodLabel),
    ];

    switch (result.castMethod) {
      case CastMethod.time:
        rows.addAll([
          _buildInfoRow(
            '年支',
            '${source.yearBranch ?? '-'}（数 ${source.yearNumber ?? '-'}）',
          ),
          _buildInfoRow('月数', '${source.monthNumber ?? '-'}'),
          _buildInfoRow('日数', '${source.dayNumber ?? '-'}'),
          _buildInfoRow(
            '时支',
            '${source.hourBranch ?? '-'}（数 ${source.hourNumber ?? '-'}）',
          ),
          _buildInfoRow(
            '上卦',
            '${source.upperRawValue ?? '-'} % 8 = ${source.upperNumber} → '
                '${result.benGua.upperTrigram.name}',
          ),
          _buildInfoRow(
            '下卦',
            '${source.lowerRawValue ?? '-'} % 8 = ${source.lowerNumber} → '
                '${result.benGua.lowerTrigram.name}',
          ),
          _buildInfoRow(
            '动爻',
            '${source.movingRawValue ?? '-'} % 6 = ${source.movingLineNumber} → '
                '${result.movingLineLabel}',
          ),
        ]);
      case CastMethod.number:
        rows.addAll([
          _buildInfoRow('上卦数', '${source.upperInputNumber ?? '-'}'),
          _buildInfoRow('下卦数', '${source.lowerInputNumber ?? '-'}'),
          _buildInfoRow(
            '上卦',
            '${source.upperInputNumber ?? '-'} % 8 = ${source.upperNumber} → '
                '${result.benGua.upperTrigram.name}',
          ),
          _buildInfoRow(
            '下卦',
            '${source.lowerInputNumber ?? '-'} % 8 = ${source.lowerNumber} → '
                '${result.benGua.lowerTrigram.name}',
          ),
          _buildInfoRow(
            '动爻',
            '${source.movingRawValue ?? '-'} % 6 = ${source.movingLineNumber} → '
                '${result.movingLineLabel}',
          ),
        ]);
      case CastMethod.manual:
        rows.addAll([
          _buildInfoRow('上卦', source.manualUpperTrigram ?? '-'),
          _buildInfoRow('下卦', source.manualLowerTrigram ?? '-'),
          _buildInfoRow('动爻', result.movingLineLabel),
          _buildInfoRow('来源', '手动指定'),
        ]);
      default:
        break;
    }

    if (source.note != null) {
      rows.add(const SizedBox(height: 4));
      rows.add(
        Text(
          source.note!,
          style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
        ),
      );
    }

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '起卦依据'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildHexagramStructureSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '卦象结构'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MeiHuaHexagramDiagram(
                  label: '本卦',
                  hexagram: result.benGua,
                  movingLine: result.movingLine,
                  tiName: result.tiGua.name,
                  yongName: result.yongGua.name,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MeiHuaHexagramDiagram(
                  label: '变卦',
                  hexagram: result.bianGua,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MeiHuaHexagramDiagram(
                  label: '互卦',
                  hexagram: result.huGua,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyUseSection() {
    final lineSide = result.movingLine <= 3 ? '下卦' : '上卦';

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '体用关系'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('动爻位置', '$lineSide（${result.movingLineLabel}）'),
          _buildInfoRow(
            '体卦',
            '${result.tiGua.name}·${result.tiGua.symbol}（${result.tiGua.wuXing}）',
          ),
          _buildInfoRow(
            '用卦',
            '${result.yongGua.name}·${result.yongGua.symbol}（${result.yongGua.wuXing}）',
          ),
          const SizedBox(height: 4),
          Text(
            result.bodyUseRule,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildWuXingSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '五行生克'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.meihuaColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.meihuaColor.withOpacity(0.4),
                ),
              ),
              child: Text(
                result.wuXingRelation,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.meihuaColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            '体五行',
            '${result.tiGua.wuXing}（${result.tiGua.name}）',
          ),
          _buildInfoRow(
            '用五行',
            '${result.yongGua.wuXing}（${result.yongGua.name}）',
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
            width: 56,
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
