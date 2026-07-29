import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import '../../models/qimen_palace.dart';
import '../qimen_analysis_presentation.dart';

Future<void> showQimenPalaceDetailSheet(
  BuildContext context, {
  required QimenPalace palace,
  required QimenAnalysisReport report,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.xiangseLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => _QimenPalaceDetailSheet(
        palace: palace,
        report: report,
      ),
    );

class _QimenPalaceDetailSheet extends StatelessWidget {
  const _QimenPalaceDetailSheet({
    required this.palace,
    required this.report,
  });

  final QimenPalace palace;
  final QimenAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final facts = report.facts
        .where((fact) => fact.relatedPalaceNumbers.contains(palace.number))
        .toList();
    final focus = report.focuses
        .where((value) => value.palaceNumber == palace.number)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.danjin,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      '${palace.name} · ${palace.direction}',
                      style: AppTextStyles.antiqueTitle.copyWith(
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭宫位详情',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                _section('盘面事实', [
                  _row('宫位', '${palace.number} · ${palace.trigram}'),
                  _row('方位 / 五行', '${palace.direction} / ${palace.element}'),
                  _row(
                      '宫支',
                      palace.branches.isEmpty
                          ? '无'
                          : palace.branches.join('、')),
                  _row('地盘干', palace.earthStem),
                  _row('天盘干', palace.heavenStem),
                  _row('九星', palace.star),
                  _row('八门', palace.door ?? '中宫无门'),
                  _row('八神', palace.deity ?? '中宫无神'),
                  _row('暗干', palace.hiddenStem ?? '无'),
                ]),
                const SizedBox(height: 18),
                _section('寄宫事实', [
                  _row('寄地盘干', palace.hostedEarthStem ?? '无'),
                  _row('寄天盘干', palace.hostedHeavenStem ?? '无'),
                  _row('寄九星', palace.hostedStar ?? '无'),
                ]),
                const SizedBox(height: 18),
                _section('专业标记', [
                  _row(
                    '空亡',
                    palace.voidBranches.isEmpty
                        ? '否'
                        : '是 · ${palace.voidBranches.join('、')}',
                  ),
                  _row('驿马', palace.isHorse ? '是' : '否'),
                  _row('其他',
                      palace.marks.isEmpty ? '无' : palace.marks.join('、')),
                ]),
                if (focus.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _section(
                    '焦点',
                    focus
                        .map(
                          (item) => _paragraph(
                            '${QimenAnalysisPresentation.roleLabel(item.roleId)} · '
                            '${item.indicatorValue} · '
                            '${QimenAnalysisPresentation.focusPriorityLabel(item.priority)}\n'
                            '${QimenAnalysisPresentation.narrativeLabel(item.reason, facts: report.facts)}\n'
                            '规则 ${QimenAnalysisPresentation.ruleLabel(item.ruleId)} · '
                            '来源 ${QimenAnalysisPresentation.sourceLabels(item.sourceIds)}',
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 18),
                _section(
                  '命中规则与来源',
                  facts.isEmpty
                      ? <Widget>[_paragraph('本宫没有命中的规则事实。')]
                      : facts
                          .map(
                            (fact) => _paragraph(
                              '${QimenAnalysisPresentation.ruleLabel(fact.ruleId)} · '
                              '${QimenAnalysisPresentation.polarityLabel(fact.polarity)}\n'
                              '${QimenAnalysisPresentation.narrativeLabel(fact.reason, facts: report.facts)}\n'
                              '事实 ${QimenAnalysisPresentation.ruleLabel(fact.ruleId)}\n'
                              '来源 ${QimenAnalysisPresentation.sourceLabels(fact.sourceIds)}',
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.antiqueSection.copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.guhe,
                  fontSize: 13,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.xuanse,
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _paragraph(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.huise,
            fontSize: 13,
            height: 1.55,
            letterSpacing: 0,
          ),
        ),
      );
}
