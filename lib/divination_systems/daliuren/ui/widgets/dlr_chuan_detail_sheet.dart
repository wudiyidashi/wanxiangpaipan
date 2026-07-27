import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import '../../../../presentation/widgets/antique/antique.dart';
import '../../models/chuan.dart';
import 'dlr_tag_badge.dart';

/// 传详析底部弹层：按分类展示该传全部分析标签，并附课局级标签区块。
Future<void> showDlrChuanDetailSheet(
  BuildContext context, {
  required Chuan chuan,
  required List<DlrAnalysisTag> tags,
  required List<DlrAnalysisTag> juTags,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.xiangse,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _DlrChuanDetailSheet(
      chuan: chuan,
      tags: tags,
      juTags: juTags,
    ),
  );
}

class _DlrChuanDetailSheet extends StatelessWidget {
  const _DlrChuanDetailSheet({
    required this.chuan,
    required this.tags,
    required this.juTags,
  });

  final Chuan chuan;
  final List<DlrAnalysisTag> tags;
  final List<DlrAnalysisTag> juTags;

  @override
  Widget build(BuildContext context) {
    final grouped = <DlrTagCategory, List<DlrAnalysisTag>>{};
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
                  child: Semantics(
                    header: true,
                    child: Text(
                      '${chuan.chuanName} ${chuan.diZhi}'
                      '（${chuan.liuQin}·乘${chuan.chengShenName}）'
                      '${chuan.isKongWang ? ' · 空亡' : ''}',
                      style: AppTextStyles.antiqueBody.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const AntiqueDivider(),
          Expanded(
            child: tags.isEmpty && juTags.isEmpty
                ? Center(
                    child: Text('此传暂无分析标注', style: AppTextStyles.antiqueBody),
                  )
                : ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final category in DlrTagCategory.values)
                        if (grouped.containsKey(category)) ...[
                          _CategoryHeader(title: category.name),
                          for (final tag in grouped[category]!)
                            _TagRow(tag: tag),
                        ],
                      if (juTags.isNotEmpty) ...[
                        const _CategoryHeader(title: '课局'),
                        for (final tag in juTags) _TagRow(tag: tag),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: AppTextStyles.antiqueLabel.copyWith(
            color: AppColors.gutong,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag});

  final DlrAnalysisTag tag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${tag.term}：${tag.reason}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DlrTagBadge(tag: tag, dense: false),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tag.relatedPositions.isEmpty
                    ? tag.reason
                    : '${tag.reason}（关联：${tag.relatedPositions.join('、')}）',
                style: AppTextStyles.antiqueBody.copyWith(
                  color: AppColors.xuanse,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
