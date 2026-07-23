import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/analysis_tag.dart';
import '../../../../presentation/widgets/antique/antique.dart';
import '../../../../presentation/widgets/yao_tag_badge.dart';
import '../../models/yao.dart';
import 'term_glossary_dialog.dart';

/// 爻详析底部弹层：按分类展示该爻全部分析标签，可设为/取消用神。
Future<void> showYaoDetailSheet(
  BuildContext context, {
  required Yao yao,
  required String liuShenName,
  required List<YaoAnalysisTag> tags,
  required bool isYongShen,
  required void Function(int position) onSelectYongShen,
  required VoidCallback onClearYongShen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.xiangse,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _YaoDetailSheet(
      yao: yao,
      liuShenName: liuShenName,
      tags: tags,
      isYongShen: isYongShen,
      onSelectYongShen: onSelectYongShen,
      onClearYongShen: onClearYongShen,
    ),
  );
}

class _YaoDetailSheet extends StatelessWidget {
  const _YaoDetailSheet({
    required this.yao,
    required this.liuShenName,
    required this.tags,
    required this.isYongShen,
    required this.onSelectYongShen,
    required this.onClearYongShen,
  });

  final Yao yao;
  final String liuShenName;
  final List<YaoAnalysisTag> tags;
  final bool isYongShen;
  final void Function(int position) onSelectYongShen;
  final VoidCallback onClearYongShen;

  static const List<String> _positionNames = [
    '初爻',
    '二爻',
    '三爻',
    '四爻',
    '五爻',
    '上爻'
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <TagCategory, List<YaoAnalysisTag>>{};
    for (final tag in tags) {
      grouped.putIfAbsent(tag.category, () => []).add(tag);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_positionNames[yao.position - 1]} · $liuShenName · '
                    '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}'
                    '${yao.isSeYao ? ' · 世' : yao.isYingYao ? ' · 应' : ''}',
                    style: AppTextStyles.antiqueBody.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AntiqueButton(
                  label: isYongShen ? '取消用神' : '设为用神',
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isYongShen) {
                      onClearYongShen();
                    } else {
                      onSelectYongShen(yao.position);
                    }
                  },
                ),
              ],
            ),
          ),
          const AntiqueDivider(),
          Expanded(
            child: tags.isEmpty
                ? Center(
                    child: Text('此爻暂无分析标注', style: AppTextStyles.antiqueBody),
                  )
                : ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final category in TagCategory.values)
                        if (grouped.containsKey(category)) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 6),
                            child: Text(
                              category.name,
                              style: AppTextStyles.antiqueLabel.copyWith(
                                color: AppColors.gutong,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          for (final tag in grouped[category]!)
                            _TagRow(tag: tag),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag});

  final YaoAnalysisTag tag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YaoTagBadge(
            tag: tag,
            dense: false,
            onTap: () => showTermGlossaryDialog(context, tag.term),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tag.relatedYao.isEmpty
                  ? tag.reason
                  : '${tag.reason}（关联：${tag.relatedYao.map((p) => '$p爻').join('、')}）',
              style: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.xuanse,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
