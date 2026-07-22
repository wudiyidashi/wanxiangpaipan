import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';

/// 连线类型（决定颜色与线型）
enum RelationKind {
  sheng, // 生/扶：青绿实线
  ke, // 克/冲/刑/害/墓：朱砂虚线
  he, // 合：金色实线
}

/// 关系图的边。
///
/// 节点编号：1-6 为爻位，[yueNode] 为月建，[riNode] 为日辰。
class RelationEdge {
  const RelationEdge({
    required this.from,
    required this.to,
    required this.term,
    required this.kind,
    required this.directed,
  });

  static const int yueNode = 7;
  static const int riNode = 8;

  final int from;
  final int to;
  final String term;
  final RelationKind kind;

  /// 有向边（施动方 → 受动方）绘制箭头
  final bool directed;

  @override
  String toString() => '$from${directed ? '→' : '—'}$to $term';
}

/// 从分析报告提取关系图的边（纯函数，供弹窗绘制）。
///
/// 覆盖：爻间生克扶（有向）、合冲刑害墓（无向）、日月对爻的破/冲/合。
/// 引擎在关系双方各挂一条标签，此处按 (小爻位, 大爻位, 归一术语) 去重；
/// 合住/合起/合绊归一为「六合」、相冲归一为「六冲」。
List<RelationEdge> buildRelationEdges(AnalysisReport report) {
  final edges = <RelationEdge>[];
  final seen = <String>{};

  void add(RelationEdge edge) {
    final a = edge.from < edge.to ? edge.from : edge.to;
    final b = edge.from < edge.to ? edge.to : edge.from;
    final key = '$a-$b-${edge.term}';
    if (seen.add(key)) edges.add(edge);
  }

  report.yaoTags.forEach((position, tags) {
    for (final tag in tags) {
      final related =
          tag.relatedYao.isNotEmpty ? tag.relatedYao.first : null;
      switch (tag.term) {
        // ── 爻间生克（标签挂在受动方，related 首位为施动方）──
        case '动爻生':
          add(RelationEdge(
              from: related!,
              to: position,
              term: '生',
              kind: RelationKind.sheng,
              directed: true));
        case '动爻克':
          add(RelationEdge(
              from: related!,
              to: position,
              term: '克',
              kind: RelationKind.ke,
              directed: true));
        case '动爻扶':
          add(RelationEdge(
              from: related!,
              to: position,
              term: '扶',
              kind: RelationKind.sheng,
              directed: true));
        case '贪生忘克':
        case '贪合忘克':
        case '贪合忘生':
          add(RelationEdge(
              from: related!,
              to: position,
              term: tag.term,
              kind: RelationKind.he,
              directed: true));
        case '入动墓':
          add(RelationEdge(
              from: related!,
              to: position,
              term: '入墓',
              kind: RelationKind.ke,
              directed: true));

        // ── 爻间合冲刑害（双方各挂一条，归一去重）──
        case '合住':
        case '合起':
        case '合绊':
          add(RelationEdge(
              from: position,
              to: related!,
              term: '六合',
              kind: RelationKind.he,
              directed: false));
        case '相冲':
          add(RelationEdge(
              from: position,
              to: related!,
              term: '六冲',
              kind: RelationKind.ke,
              directed: false));
        case '冲开':
          add(RelationEdge(
              from: position,
              to: related!,
              term: '冲开',
              kind: RelationKind.ke,
              directed: false));
        case '相刑':
        case '相害':
          add(RelationEdge(
              from: position,
              to: related!,
              term: tag.term,
              kind: RelationKind.ke,
              directed: false));
        case '三合局':
        case '三合成局':
        case '半合':
          for (final other in tag.relatedYao) {
            add(RelationEdge(
                from: position,
                to: other,
                term: tag.term,
                kind: RelationKind.he,
                directed: false));
          }

        // ── 日月对爻 ──
        case '月破':
          add(RelationEdge(
              from: RelationEdge.yueNode,
              to: position,
              term: '月破',
              kind: RelationKind.ke,
              directed: true));
        case '暗动':
        case '日破':
          add(RelationEdge(
              from: RelationEdge.riNode,
              to: position,
              term: tag.term,
              kind: RelationKind.ke,
              directed: true));
        case '日合':
          add(RelationEdge(
              from: RelationEdge.riNode,
              to: position,
              term: '日合',
              kind: RelationKind.he,
              directed: true));
        case '月合':
          add(RelationEdge(
              from: RelationEdge.yueNode,
              to: position,
              term: '月合',
              kind: RelationKind.he,
              directed: true));
      }
    }
  });

  return edges;
}
