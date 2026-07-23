import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/fushen_service.dart';
import '../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/screens/calendar/calendar_gua_context.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/diagram_comparison_row.dart';
import '../liuyao_result.dart';
import '../viewmodels/liuyao_analysis_controller.dart';
import 'widgets/analysis_overview_card.dart';
import 'widgets/liuyao_share_dialog.dart';
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
        _buildPanParamsSection(context, controller, result, question),
        DiagramComparisonRow(
          mainGua: result.mainGua,
          changingGua: result.changingGua,
          liuShen: result.liuShen,
          yaoTags: report.yaoTags,
          yongShenPosition: controller.yongShenPosition,
          onYaoTap: (position) => _showYaoDetail(context, controller, position),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.ios_share_outlined, size: 16),
              label: const Text('分享排盘'),
              onPressed: () => showLiuYaoShareDialog(
                context,
                result: result,
                report: report,
                question: question.isNotEmpty ? question : null,
              ),
            ),
            TextButton.icon(
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
          ],
        ),
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
          ),
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

  Widget _buildPanParamsSection(
    BuildContext context,
    LiuYaoAnalysisController controller,
    LiuYaoResult result,
    String question,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntiqueSectionTitle(title: '排盘参数'),
            const AntiqueDivider(),
            const SizedBox(height: 8),
            _buildInfoRow(
              '占问',
              question.isEmpty ? '未设置' : question,
              onSetup: () => _showQuestionEditor(context, controller, question),
            ),
            _buildInfoRow(
              '干支',
              _buildGanZhiText(result),
              onSetup: () => _showLunarEditor(context, controller, result),
            ),
            _buildInfoRow('月日建', _buildMonthDayBuildText(result)),
          ],
        ),
      ),
    );
  }

  /// 占问编辑弹窗
  void _showQuestionEditor(
    BuildContext context,
    LiuYaoAnalysisController controller,
    String current,
  ) {
    final textController = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AntiqueDialog(
        title: '设置占问',
        content: AntiqueTextField(
          controller: textController,
          hint: '请输入占问事项…',
          maxLines: 2,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.updateQuestion(textController.text.trim());
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 无时辰的哨兵值
  static const String _noHour = 'none';

  /// 取合法干支；无效时（如月干支被记为单支）取以 [fallbackZhi] 为支的
  /// 首个六十甲子，再退到甲子
  String _validGanZhiOr(String? value, {String? fallbackZhi}) {
    if (value != null && TianGanDiZhiService.isValidGanZhi(value)) {
      return value;
    }
    if (fallbackZhi != null) {
      for (final ganZhi in TianGanDiZhiService.liuShiJiaZi) {
        if (ganZhi[1] == fallbackZhi) return ganZhi;
      }
    }
    return '甲子';
  }

  /// 四柱干支编辑弹窗（改后月建/空亡/六神/太岁与全部分析自动重算）
  void _showLunarEditor(
    BuildContext context,
    LiuYaoAnalysisController controller,
    LiuYaoResult result,
  ) {
    final lunar = result.lunarInfo;
    var yearGanZhi = _validGanZhiOr(lunar.yearGanZhi);
    var monthGanZhi =
        _validGanZhiOr(lunar.monthGanZhi, fallbackZhi: lunar.yueJian);
    var riGanZhi = _validGanZhiOr(lunar.riGanZhi);
    var hourGanZhi = lunar.hourGanZhi != null &&
            TianGanDiZhiService.isValidGanZhi(lunar.hourGanZhi!)
        ? lunar.hourGanZhi!
        : _noHour;

    Widget picker({
      required String label,
      required String value,
      required ValueChanged<String?> onChanged,
      bool allowNone = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 4),
          AntiqueDropdown<String>(
            value: value,
            items: [
              if (allowNone)
                const AntiqueDropdownItem(value: _noHour, label: '不设'),
              for (final ganZhi in TianGanDiZhiService.liuShiJiaZi)
                AntiqueDropdownItem(value: ganZhi, label: ganZhi),
            ],
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AntiqueDialog(
        title: '设置四柱干支',
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                picker(
                  label: '年',
                  value: yearGanZhi,
                  onChanged: (v) =>
                      setState(() => yearGanZhi = v ?? yearGanZhi),
                ),
                picker(
                  label: '月',
                  value: monthGanZhi,
                  onChanged: (v) =>
                      setState(() => monthGanZhi = v ?? monthGanZhi),
                ),
                picker(
                  label: '日',
                  value: riGanZhi,
                  onChanged: (v) => setState(() => riGanZhi = v ?? riGanZhi),
                ),
                picker(
                  label: '时（可不设）',
                  value: hourGanZhi,
                  allowNone: true,
                  onChanged: (v) =>
                      setState(() => hourGanZhi = v ?? hourGanZhi),
                ),
                Text(
                  '月建取月支，空亡随日干支、六神随日干、太岁随年支，'
                  '保存后全部分析自动重算',
                  style: AppTextStyles.antiqueLabel
                      .copyWith(color: AppColors.huise),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.updateLunar(
                yearGanZhi: yearGanZhi,
                monthGanZhi: monthGanZhi,
                riGanZhi: riGanZhi,
                hourGanZhi: hourGanZhi == _noHour ? null : hourGanZhi,
              );
            },
            child: const Text('保存'),
          ),
        ],
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

  Widget _buildInfoRow(String label, String value, {VoidCallback? onSetup}) {
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
          if (onSetup != null)
            SizedBox(
              height: 24,
              child: TextButton(
                onPressed: onSetup,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '设置',
                  style: AppTextStyles.antiqueLabel
                      .copyWith(color: AppColors.zhusha),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
