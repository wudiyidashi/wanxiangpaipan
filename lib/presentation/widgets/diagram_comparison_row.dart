import 'package:flutter/material.dart';
import '../../divination_systems/liuyao/models/gua.dart';
import '../../domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'liuyao_table_widget.dart';

/// 卦象横向对比布局组件
///
/// 将本卦和变卦横向并排展示，中间显示动爻标记，
/// 参考 React Native 版本的布局设计。
class DiagramComparisonRow extends StatelessWidget {
  /// 本卦
  final Gua mainGua;

  /// 变卦（可选）
  final Gua? changingGua;

  /// 六神列表
  final List<String> liuShen;

  /// 各爻分析徽标（透传给表格；null 时不渲染）
  final Map<int, List<YaoAnalysisTag>>? yaoTags;

  /// 点击本卦爻行回调
  final ValueChanged<int>? onYaoTap;

  /// 当前用神爻位（透传用于高亮）
  final int? yongShenPosition;

  const DiagramComparisonRow({
    super.key,
    required this.mainGua,
    this.changingGua,
    required this.liuShen,
    this.yaoTags,
    this.onYaoTap,
    this.yongShenPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LiuYaoTableWidget(
          gua: mainGua,
          secondaryGua: changingGua,
          liuShen: liuShen,
          title: '本卦',
          secondaryTitle: '变卦',
          yaoTags: yaoTags,
          onYaoTap: onYaoTap,
          yongShenPosition: yongShenPosition,
        ),
      ),
    );
  }
}
