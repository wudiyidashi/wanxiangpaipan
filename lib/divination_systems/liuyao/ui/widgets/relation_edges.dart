import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';

/// 连线类型（决定颜色与线型）
enum RelationKind {
  sheng, // 生/扶：青绿实线
  ke, // 克/冲/刑/害/墓：朱砂虚线
  he, // 合：金色实线
  neutral, // 中性（化空/化破/普通动变连接）：灰色细线
}

/// 关系图的边。
///
/// 节点编号：1-6 为本卦爻位，+[bianNodeOffset] 为对应变爻（11-16），
/// [yueNode] 为月建，[riNode] 为日辰。
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
  static const int bianNodeOffset = 10;

  final int from;
  final int to;
  final String term;
  final RelationKind kind;

  /// 有向边（施动方 → 受动方）绘制箭头
  final bool directed;

  /// 本爻与其变爻之间的边
  bool get isBianEdge => from > bianNodeOffset || to > bianNodeOffset;

  @override
  String toString() => '$from${directed ? '→' : '—'}$to $term';
}

/// 动爻化变关系的取舍优先级（每个动爻只画一条最关键的化变线）
const List<String> _bianPrecedence = [
  '回头克', '回头生', '化冲', '化合', '化墓', '化绝',
  '化进神', '化退神', '化泄', '化空', '化破',
];

/// 从分析报告提取关系图的边（纯函数，供弹窗绘制）。
///
/// 覆盖：爻间生克扶（有向）、合冲刑害墓（无向）、日月对爻的破冲合、
/// 动爻与变爻的化变关系（每动爻取优先级最高的一条）。
/// 贪生忘克/贪合忘生克为效果性标签不画线（信息在爻详析中）。
/// [movingPositions] 用于给无化变标签的动爻（如爻伏吟）补中性连接线。
List<RelationEdge> buildRelationEdges(
  AnalysisReport report, {
  Set<int> movingPositions = const {},
}) {
  final edges = <RelationEdge>[];
  final seen = <String>{};

  void add(RelationEdge edge) {
    final a = edge.from < edge.to ? edge.from : edge.to;
    final b = edge.from < edge.to ? edge.to : edge.from;
    if (seen.add('$a-$b-${edge.term}')) edges.add(edge);
  }

  report.yaoTags.forEach((position, tags) {
    for (final tag in tags) {
      final related =
          tag.relatedYao.isNotEmpty ? tag.relatedYao.first : null;
      switch (tag.term) {
        // ── 爻间生克（标签挂在受动方，related 首位为施动方）──
        case '动爻生':
          add(RelationEdge(
              from: related!, to: position, term: '生',
              kind: RelationKind.sheng, directed: true));
        case '动爻克':
          add(RelationEdge(
              from: related!, to: position, term: '克',
              kind: RelationKind.ke, directed: true));
        case '动爻扶':
          add(RelationEdge(
              from: related!, to: position, term: '扶',
              kind: RelationKind.sheng, directed: true));
        case '入动墓':
          add(RelationEdge(
              from: related!, to: position, term: '入墓',
              kind: RelationKind.ke, directed: true));

        // ── 爻间合冲刑害（双方各挂一条，归一去重）──
        case '合住':
        case '合起':
        case '合绊':
          add(RelationEdge(
              from: position, to: related!, term: '六合',
              kind: RelationKind.he, directed: false));
        case '相冲':
          add(RelationEdge(
              from: position, to: related!, term: '六冲',
              kind: RelationKind.ke, directed: false));
        case '冲开':
          add(RelationEdge(
              from: position, to: related!, term: '冲开',
              kind: RelationKind.ke, directed: false));
        case '相刑':
        case '相害':
          add(RelationEdge(
              from: position, to: related!, term: tag.term,
              kind: RelationKind.ke, directed: false));
        case '三合局':
        case '三合成局':
        case '半合':
          for (final other in tag.relatedYao) {
            add(RelationEdge(
                from: position, to: other, term: tag.term,
                kind: RelationKind.he, directed: false));
          }

        // ── 日月对爻 ──
        case '月破':
          add(RelationEdge(
              from: RelationEdge.yueNode, to: position, term: '月破',
              kind: RelationKind.ke, directed: true));
        case '暗动':
        case '日破':
          add(RelationEdge(
              from: RelationEdge.riNode, to: position, term: tag.term,
              kind: RelationKind.ke, directed: true));
        case '日合':
          add(RelationEdge(
              from: RelationEdge.riNode, to: position, term: '日合',
              kind: RelationKind.he, directed: true));
        case '月合':
          add(RelationEdge(
              from: RelationEdge.yueNode, to: position, term: '月合',
              kind: RelationKind.he, directed: true));
      }
    }
  });

  // ── 动爻 ↔ 变爻：每动爻取最关键的一条化变关系 ──
  report.yaoTags.forEach((position, tags) {
    final terms = tags.map((t) => t.term).toSet();
    String? picked;
    for (final candidate in _bianPrecedence) {
      if (terms.contains(candidate)) {
        picked = candidate;
        break;
      }
    }
    if (picked == null) return;
    edges.add(_bianEdge(position, picked));
  });

  // 有动爻但无任何化变标签（如爻伏吟）：补中性连接线
  for (final position in movingPositions) {
    if (edges.any((e) => e.isBianEdge &&
        (e.from == position || e.to == position ||
            e.from == position + RelationEdge.bianNodeOffset ||
            e.to == position + RelationEdge.bianNodeOffset))) {
      continue;
    }
    edges.add(RelationEdge(
        from: position,
        to: position + RelationEdge.bianNodeOffset,
        term: '化',
        kind: RelationKind.neutral,
        directed: true));
  }

  return edges;
}

RelationEdge _bianEdge(int position, String term) {
  final bian = position + RelationEdge.bianNodeOffset;
  switch (term) {
    case '回头克':
      return RelationEdge(
          from: bian, to: position, term: term,
          kind: RelationKind.ke, directed: true);
    case '回头生':
      return RelationEdge(
          from: bian, to: position, term: term,
          kind: RelationKind.sheng, directed: true);
    case '化冲':
      return RelationEdge(
          from: position, to: bian, term: term,
          kind: RelationKind.ke, directed: false);
    case '化合':
      return RelationEdge(
          from: position, to: bian, term: term,
          kind: RelationKind.he, directed: false);
    case '化墓':
    case '化绝':
    case '化退神':
    case '化泄':
      return RelationEdge(
          from: position, to: bian, term: term,
          kind: RelationKind.ke, directed: true);
    case '化进神':
      return RelationEdge(
          from: position, to: bian, term: term,
          kind: RelationKind.sheng, directed: true);
    default: // 化空 / 化破
      return RelationEdge(
          from: position, to: bian, term: term,
          kind: RelationKind.neutral, directed: true);
  }
}
