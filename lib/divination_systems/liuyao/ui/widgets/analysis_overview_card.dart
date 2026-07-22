import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/fushen_service.dart';
import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../../presentation/widgets/antique/antique.dart';
import '../../../../presentation/widgets/yao_tag_badge.dart';
import '../../models/gua.dart';
import 'term_glossary_dialog.dart';

/// 断卦总览卡：未选用神时为引导态，选定后展示用神链、状态与结论。
class AnalysisOverviewCard extends StatelessWidget {
  const AnalysisOverviewCard({
    super.key,
    required this.mainGua,
    required this.report,
    required this.yongShenPosition,
    required this.yongShenIsFuShen,
    required this.onSelectYongShen,
    required this.onClearYongShen,
    this.onViewCalendar,
  });

  final Gua mainGua;
  final AnalysisReport report;
  final int? yongShenPosition;
  final bool yongShenIsFuShen;
  final void Function(int position, {bool isFuShen}) onSelectYongShen;
  final VoidCallback onClearYongShen;
  final VoidCallback? onViewCalendar;

  static const List<String> _positionNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(
            title: '断卦总览',
            trailing: yongShenPosition == null
                ? null
                : TextButton(
                    onPressed: onClearYongShen,
                    child: const Text('取消用神'),
                  ),
          ),
          const SizedBox(height: 8),
          if (yongShenPosition == null)
            _buildGuideState(context)
          else
            _buildAnalysisState(context),
        ],
      ),
    );
  }

  Widget _buildGuideState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '点击下方爻行或此处选定用神，即可查看原神忌神、吉凶结论与应期推算。',
          style: AppTextStyles.antiqueBody.copyWith(
            color: AppColors.huise,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        AntiqueButton(
          label: '选用神',
          onPressed: () => _showYongShenPicker(context),
        ),
      ],
    );
  }

  Widget _buildAnalysisState(BuildContext context) {
    final chain = report.yongShen;
    if (chain == null) return const SizedBox.shrink();

    final yongShenTags = report
        .topTagsFor(chain.position)
        .where((t) => t.term != '用神' && t.term != '用神(伏)')
        .take(3)
        .toList();

    String roleDesc(int? position) {
      if (position == null) return '不上卦';
      final yao = mainGua.yaos[position - 1];
      return '${_positionNames[position - 1]}${yao.liuQin.name}${yao.branch}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            AntiqueTag(
              label: '用神${chain.isFuShen ? '(伏)' : ''} '
                  '${roleDesc(chain.position)}',
              color: AppColors.gutong,
            ),
            AntiqueTag(
              label: '原神 ${roleDesc(chain.yuanShenPosition)}',
              color: AppColors.jishenGreen,
            ),
            AntiqueTag(
              label: '忌神 ${roleDesc(chain.jiShenPosition)}',
              color: AppColors.zhusha,
            ),
            if (chain.chouShenPosition != null)
              AntiqueTag(
                label: '仇神 ${roleDesc(chain.chouShenPosition)}',
                color: AppColors.huise,
              ),
          ],
        ),
        if (chain.duplicatePositions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '用神两现（另见${chain.duplicatePositions.map((p) => _positionNames[p - 1]).join('、')}），已取${_positionNames[chain.position - 1]}',
            style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.huise),
          ),
        ],
        if (yongShenTags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text('用神状态：',
                  style: AppTextStyles.antiqueLabel
                      .copyWith(color: AppColors.huise)),
              const SizedBox(width: 4),
              Wrap(
                spacing: 4,
                children: [
                  for (final tag in yongShenTags)
                    YaoTagBadge(
                      tag: tag,
                      dense: false,
                      onTap: () => showTermGlossaryDialog(context, tag.term),
                    ),
                ],
              ),
            ],
          ),
        ],
        if (report.verdictSummary != null) ...[
          const SizedBox(height: 10),
          Text(
            report.verdictSummary!,
            style: AppTextStyles.antiqueBody.copyWith(height: 1.6),
          ),
        ],
        if (onViewCalendar != null &&
            (report.yingQi?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          AntiqueButton(
            label: '查看应期日历',
            onPressed: onViewCalendar!,
          ),
        ],
      ],
    );
  }

  /// 用神选择器：列出六爻六亲与伏神
  void _showYongShenPicker(BuildContext context) {
    final fuShenMap = FuShenService.calculateFuShen(mainGua);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.xiangse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('选定用神',
                  style: AppTextStyles.antiqueBody
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
            for (final yao in mainGua.yaos.reversed)
              ListTile(
                dense: true,
                title: Text(
                  '${_positionNames[yao.position - 1]}  '
                  '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}'
                  '${yao.isSeYao ? '（世）' : yao.isYingYao ? '（应）' : ''}',
                  style: AppTextStyles.antiqueBody,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelectYongShen(yao.position);
                },
              ),
            if (fuShenMap.isNotEmpty) ...[
              const AntiqueDivider(),
              for (final entry in fuShenMap.entries)
                ListTile(
                  dense: true,
                  title: Text(
                    '伏神（${_positionNames[entry.key - 1]}下）  '
                    '${entry.value.displayText}',
                    style: AppTextStyles.antiqueBody
                        .copyWith(color: AppColors.zhusha),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onSelectYongShen(entry.key, isFuShen: true);
                  },
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
