import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/diagram_comparison_row.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/special_relation_section.dart';
import '../liuyao_result.dart';
import '../models/gua.dart';

class LiuYaoResultScreen extends StatelessWidget {
  const LiuYaoResultScreen({
    super.key,
    required this.result,
  });

  final LiuYaoResult result;

  @override
  Widget build(BuildContext context) {
    return DivinationResultPage(
      result: result,
      title: '排盘结果',
      fallbackQuestion: result.questionId.isNotEmpty ? result.questionId : null,
      padding: const EdgeInsets.all(12),
      buildSections: (context, question) => [
        ExtendedInfoSection(
          castTime: result.castTime,
          lunarInfo: result.lunarInfo,
          liuShen: result.liuShen,
          shenShaInfo: null,
        ),
        _buildPanParamsSection(question),
        DiagramComparisonRow(
          mainGua: result.mainGua,
          changingGua: result.changingGua,
          liuShen: result.liuShen,
        ),
        SpecialRelationSection(
          relationType: _getSpecialRelationType(result.mainGua),
          description: _getSpecialRelationDescription(result.mainGua),
        ),
      ],
    );
  }

  Widget _buildPanParamsSection(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntiqueSectionTitle(title: '排盘参数'),
            const AntiqueDivider(),
            const SizedBox(height: 8),
            _buildInfoRow('占问', question.isEmpty ? '未设置' : question),
            _buildInfoRow('干支', _buildGanZhiText()),
            _buildInfoRow('月日建', _buildMonthDayBuildText()),
          ],
        ),
      ),
    );
  }

  String _buildGanZhiText() {
    final hourGanZhi = result.lunarInfo.hourGanZhi ?? '';
    return '${result.lunarInfo.yearGanZhi}年　'
        '${result.lunarInfo.monthGanZhi}月　'
        '${result.lunarInfo.riGanZhi}日　'
        '$hourGanZhi时';
  }

  String _buildMonthDayBuildText() {
    final kongWang = result.lunarInfo.kongWang.join();
    return '月建${result.lunarInfo.yueJian}　日建${result.lunarInfo.riZhi}　空亡$kongWang';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.guhe,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.antiqueBody,
            ),
          ),
        ],
      ),
    );
  }

  String? _getSpecialRelationType(Gua gua) {
    if (gua.specialType == GuaSpecialType.none) {
      return null;
    }
    return gua.specialType.name;
  }

  String? _getSpecialRelationDescription(Gua gua) {
    return switch (gua.specialType) {
      GuaSpecialType.youHun => '游魂卦，主动荡不安，事多变化。',
      GuaSpecialType.guiHun => '归魂卦，主稳定，事归本源。',
      GuaSpecialType.liuChong => '六冲卦，主冲突激烈，事难成。',
      GuaSpecialType.liuHe => '六合卦，主和谐顺利，事易成。',
      GuaSpecialType.none => null,
    };
  }
}
