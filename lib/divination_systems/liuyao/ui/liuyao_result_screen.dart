import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/fushen_service.dart';
import '../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/screens/calendar/calendar_gua_context.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/diagram_comparison_row.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/special_relation_section.dart';
import '../liuyao_result.dart';
import '../models/gua.dart';
import '../viewmodels/liuyao_analysis_controller.dart';
import 'widgets/analysis_overview_card.dart';
import 'widgets/relation_graph_dialog.dart';
import 'widgets/yao_detail_sheet.dart';
import 'widgets/ying_qi_card.dart';

class LiuYaoResultScreen extends StatelessWidget {
  const LiuYaoResultScreen({
    super.key,
    required this.result,
  });

  final LiuYaoResult result;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiuYaoAnalysisController>(
      create: (context) => LiuYaoAnalysisController(
        result: result,
        repository: context.read<DivinationRepository>(),
      ),
      child: const _LiuYaoResultView(),
    );
  }
}

class _LiuYaoResultView extends StatelessWidget {
  const _LiuYaoResultView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LiuYaoAnalysisController>();
    final result = controller.result;
    final report = controller.report;

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
        _buildPanParamsSection(result, question),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AnalysisOverviewCard(
            mainGua: result.mainGua,
            report: report,
            yongShenPosition: controller.yongShenPosition,
            yongShenIsFuShen: controller.yongShenIsFuShen,
            onSelectYongShen: (position, {bool isFuShen = false}) =>
                controller.selectYongShen(position, isFuShen: isFuShen),
            onClearYongShen: controller.clearYongShen,
            onViewCalendar: () => _openYingQiCalendar(context, controller),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.account_tree_outlined, size: 16),
            label: const Text('生克关系图'),
            onPressed: () => showRelationGraphDialog(
              context,
              mainGua: result.mainGua,
              changingGua: result.changingGua,
              lunarInfo: result.lunarInfo,
              report: report,
              yongShenPosition: controller.yongShenPosition,
            ),
          ),
        ),
        DiagramComparisonRow(
          mainGua: result.mainGua,
          changingGua: result.changingGua,
          liuShen: result.liuShen,
          yaoTags: report.yaoTags,
          yongShenPosition: controller.yongShenPosition,
          onYaoTap: (position) => _showYaoDetail(context, controller, position),
        ),
        SpecialRelationSection(
          relationType: _getSpecialRelationType(result.mainGua),
          description: _getSpecialRelationDescription(result.mainGua),
        ),
        if (report.yingQi != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: YingQiCard(
              candidates: report.yingQi!,
              onViewCalendar: () => _openYingQiCalendar(context, controller),
            ),
          ),
      ],
    );
  }

  /// 携带卦上下文进入日历应期模式
  void _openYingQiCalendar(
    BuildContext context,
    LiuYaoAnalysisController controller,
  ) {
    final result = controller.result;
    final report = controller.report;
    final chain = report.yongShen;
    if (chain == null) return;

    final yongShenYao = chain.isFuShen
        ? FuShenService.calculateFuShen(result.mainGua)[chain.position]!.yao
        : result.mainGua.yaos[chain.position - 1];

    Navigator.of(context).pushNamed(
      '/calendar',
      arguments: CalendarGuaContext(
        title: '${result.mainGua.name} · 用神'
            '${yongShenYao.liuQin.name}${yongShenYao.branch}'
            '${yongShenYao.wuXing.name}',
        yongShenBranch: yongShenYao.branch,
        yingQiByBranch: {
          for (final candidate in report.yingQi ?? <YingQiCandidate>[])
            if (candidate.scale == YingQiScale.ri)
              candidate.branch: candidate.reason,
        },
      ),
    );
  }

  void _showYaoDetail(
    BuildContext context,
    LiuYaoAnalysisController controller,
    int position,
  ) {
    final result = controller.result;
    showYaoDetailSheet(
      context,
      yao: result.mainGua.yaos[position - 1],
      liuShenName:
          result.liuShen.length >= position ? result.liuShen[position - 1] : '',
      tags: controller.report.yaoTags[position] ?? const [],
      isYongShen: controller.yongShenPosition == position &&
          !controller.yongShenIsFuShen,
      onSelectYongShen: (p) => controller.selectYongShen(p),
      onClearYongShen: controller.clearYongShen,
    );
  }

  Widget _buildPanParamsSection(LiuYaoResult result, String question) {
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
            _buildInfoRow('干支', _buildGanZhiText(result)),
            _buildInfoRow('月日建', _buildMonthDayBuildText(result)),
          ],
        ),
      ),
    );
  }

  String _buildGanZhiText(LiuYaoResult result) {
    final hourGanZhi = result.lunarInfo.hourGanZhi ?? '';
    return '${result.lunarInfo.yearGanZhi}年　'
        '${result.lunarInfo.monthGanZhi}月　'
        '${result.lunarInfo.riGanZhi}日　'
        '$hourGanZhi时';
  }

  String _buildMonthDayBuildText(LiuYaoResult result) {
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
