import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../../domain/services/liuyao/analysis/tables/dizhi_relations.dart';
import '../../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../models/gua.dart';

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

  /// 线上标注文案（具体到地支，如「卯戌合化火」「子午冲」「子生寅」）
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
/// 线上标注具体到地支与化气：六合标「卯戌合化火」、三合标「申子辰水局」、
/// 生克标「子生寅」等。贪生忘克/贪合忘生克为效果性标签不画线。
/// [movingPositions] 用于给无化变标签的动爻（如爻伏吟）补中性连接线。
List<RelationEdge> buildRelationEdges(
  AnalysisReport report, {
  required Gua mainGua,
  Set<int> movingPositions = const {},
}) {
  final edges = <RelationEdge>[];
  final seen = <String>{};

  String branch(int position) => mainGua.yaos[position - 1].branch;

  // 按地支序排列两支，保证双向标签一致以便去重
  (String, String) ordered(String a, String b) =>
      TianGanDiZhiService.getDiZhiIndex(a) <=
              TianGanDiZhiService.getDiZhiIndex(b)
          ? (a, b)
          : (b, a);

  void add(RelationEdge edge) {
    final a = edge.from < edge.to ? edge.from : edge.to;
    final b = edge.from < edge.to ? edge.to : edge.from;
    if (seen.add('$a-$b-${edge.term}')) edges.add(edge);
  }

  String heLabel(String x, String y) {
    final (a, b) = ordered(x, y);
    final hua = DiZhiRelations.getLiuHeHua(a, b);
    return hua == null ? '$a$b合' : '$a$b合化${hua.name}';
  }

  String pairLabel(String x, String y, String suffix) {
    final (a, b) = ordered(x, y);
    return '$a$b$suffix';
  }

  /// 三合局完整标注：由局内任意两支反查全局
  String sanHeLabel(String x, String y) {
    for (final entry in DiZhiRelations.sanHeJu.entries) {
      if (entry.value.contains(x) && entry.value.contains(y)) {
        return '${entry.value.join()}${entry.key.name}局';
      }
    }
    return '三合局';
  }

  report.yaoTags.forEach((position, tags) {
    for (final tag in tags) {
      final related =
          tag.relatedYao.isNotEmpty ? tag.relatedYao.first : null;
      switch (tag.term) {
        // ── 爻间生克（标签挂在受动方，related 首位为施动方）──
        case '动爻生':
          add(RelationEdge(
              from: related!, to: position,
              term: '${branch(related)}生${branch(position)}',
              kind: RelationKind.sheng, directed: true));
        case '动爻克':
          add(RelationEdge(
              from: related!, to: position,
              term: '${branch(related)}克${branch(position)}',
              kind: RelationKind.ke, directed: true));
        case '动爻扶':
          add(RelationEdge(
              from: related!, to: position,
              term: '${branch(related)}扶${branch(position)}',
              kind: RelationKind.sheng, directed: true));
        case '入动墓':
          add(RelationEdge(
              from: related!, to: position,
              term: '${branch(position)}入${branch(related)}墓',
              kind: RelationKind.ke, directed: true));

        // ── 爻间合冲刑害（双方各挂一条，标签归一去重）──
        case '合住':
        case '合起':
        case '合绊':
          add(RelationEdge(
              from: position, to: related!,
              term: heLabel(branch(position), branch(related)),
              kind: RelationKind.he, directed: false));
        case '相冲':
          add(RelationEdge(
              from: position, to: related!,
              term: pairLabel(branch(position), branch(related), '冲'),
              kind: RelationKind.ke, directed: false));
        case '冲开':
          add(RelationEdge(
              from: position, to: related!,
              term: pairLabel(branch(position), branch(related), '冲开'),
              kind: RelationKind.ke, directed: false));
        case '相刑':
          add(RelationEdge(
              from: position, to: related!,
              term: pairLabel(branch(position), branch(related), '刑'),
              kind: RelationKind.ke, directed: false));
        case '相害':
          add(RelationEdge(
              from: position, to: related!,
              term: pairLabel(branch(position), branch(related), '害'),
              kind: RelationKind.ke, directed: false));
        case '三合局':
        case '三合成局':
          for (final other in tag.relatedYao) {
            add(RelationEdge(
                from: position, to: other,
                term: sanHeLabel(branch(position), branch(other)),
                kind: RelationKind.he, directed: false));
          }
        case '半合':
          for (final other in tag.relatedYao) {
            final element = DiZhiRelations.getBanHeElement(
                branch(position), branch(other));
            add(RelationEdge(
                from: position, to: other,
                term:
                    '${pairLabel(branch(position), branch(other), '半合')}'
                    '${element?.name ?? ''}',
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
