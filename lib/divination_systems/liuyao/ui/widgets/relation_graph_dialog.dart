import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../../models/lunar_info.dart';
import '../../models/gua.dart';
import 'relation_edges.dart';

/// 生克关系连线图弹窗。
///
/// 固定坐标简化示意图：本卦六爻纵列 + 右侧变爻列（动爻的化变关系）+
/// 月建/日辰外部节点；爻间及日月弧线统一走左侧（短跨度在内圈），
/// 右侧仅本爻↔变爻短线，避免交叉。
Future<void> showRelationGraphDialog(
  BuildContext context, {
  required Gua mainGua,
  Gua? changingGua,
  required LunarInfo lunarInfo,
  required AnalysisReport report,
  int? yongShenPosition,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.xiangse,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RelationGraphView(
        mainGua: mainGua,
        changingGua: changingGua,
        lunarInfo: lunarInfo,
        report: report,
        yongShenPosition: yongShenPosition,
      ),
    ),
  );
}

/// 连线分组（过滤维度）：结构优先（化变/日月），其余按线型
enum EdgeGroup {
  shengFu('生扶', AppColors.jishenGreen),
  keChong('克冲刑害', AppColors.zhusha),
  he('合', AppColors.danjinDeep),
  bian('化变', AppColors.huise),
  riYue('日月', AppColors.dailan);

  const EdgeGroup(this.label, this.color);
  final String label;
  final Color color;

  static EdgeGroup of(RelationEdge edge) {
    if (edge.isBianEdge) return EdgeGroup.bian;
    if (edge.from == RelationEdge.yueNode ||
        edge.from == RelationEdge.riNode) {
      return EdgeGroup.riYue;
    }
    return switch (edge.kind) {
      RelationKind.sheng => EdgeGroup.shengFu,
      RelationKind.ke => EdgeGroup.keChong,
      RelationKind.he || RelationKind.neutral => EdgeGroup.he,
    };
  }
}

class RelationGraphView extends StatefulWidget {
  const RelationGraphView({
    super.key,
    required this.mainGua,
    this.changingGua,
    required this.lunarInfo,
    required this.report,
    this.yongShenPosition,
  });

  final Gua mainGua;
  final Gua? changingGua;
  final LunarInfo lunarInfo;
  final AnalysisReport report;
  final int? yongShenPosition;

  @override
  State<RelationGraphView> createState() => _RelationGraphViewState();
}

class _RelationGraphViewState extends State<RelationGraphView> {
  final Set<EdgeGroup> _visibleGroups = {...EdgeGroup.values};

  Gua get mainGua => widget.mainGua;
  Gua? get changingGua => widget.changingGua;
  LunarInfo get lunarInfo => widget.lunarInfo;
  int? get yongShenPosition => widget.yongShenPosition;

  @override
  Widget build(BuildContext context) {
    final movingPositions = changingGua == null
        ? const <int>{}
        : mainGua.movingYaos.map((y) => y.position).toSet();
    final allEdges = buildRelationEdges(widget.report,
        mainGua: mainGua, movingPositions: movingPositions);
    // 只提供实际存在的分组作为开关
    final availableGroups =
        allEdges.map(EdgeGroup.of).toSet().toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    final edges = allEdges
        .where((e) => _visibleGroups.contains(EdgeGroup.of(e)))
        .toList();
    final width =
        math.min(MediaQuery.of(context).size.width - 20, 430).toDouble();
    final layout = _GraphLayout(width: width);

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '生克关系图',
                    style: AppTextStyles.antiqueBody
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: AppColors.huise),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (allEdges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final group in availableGroups)
                      _buildFilterChip(group),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: width,
            height: layout.graphHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter:
                        _RelationGraphPainter(edges: edges, layout: layout),
                  ),
                ),
                _topChip('月建 ${lunarInfo.yueJian}', layout.yueCenter),
                _topChip('日辰 ${lunarInfo.riZhi}', layout.riCenter),
                for (var position = 1; position <= 6; position++)
                  _buildYaoNode(layout, position),
                if (changingGua != null)
                  for (final yao in mainGua.movingYaos)
                    _buildBianNode(layout, yao.position),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: allEdges.isEmpty
                ? Text(
                    '本卦当前无跨爻生克合冲关系',
                    style: AppTextStyles.antiqueLabel
                        .copyWith(color: AppColors.huise),
                  )
                : Text(
                    '点击上方分类可切换连线显隐',
                    style: AppTextStyles.antiqueLabel
                        .copyWith(color: AppColors.huiseLight),
                  ),
          ),
        ],
      ),
    );
  }

  /// 分类显隐开关：选中实底、未选空心置灰
  Widget _buildFilterChip(EdgeGroup group) {
    final selected = _visibleGroups.contains(group);
    return GestureDetector(
      onTap: () => setState(() {
        if (!_visibleGroups.remove(group)) _visibleGroups.add(group);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? group.color.withOpacity(0.14) : Colors.transparent,
          border: Border.all(
            color: selected
                ? group.color
                : AppColors.huiseLight.withOpacity(0.6),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          group.label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? group.color : AppColors.huiseLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _topChip(String label, Offset center) {
    return Positioned(
      left: center.dx - 40,
      top: center.dy - 14,
      child: Container(
        width: 80,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.dailan.withOpacity(0.08),
          border: Border.all(color: AppColors.dailan.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.dailan),
        ),
      ),
    );
  }

  Widget _buildYaoNode(_GraphLayout layout, int position) {
    const positionNames = ['初', '二', '三', '四', '五', '上'];
    final yao = mainGua.yaos[position - 1];
    final isYongShen = position == yongShenPosition;

    return Positioned(
      left: layout.nodeLeft,
      top: layout.yaoY(position) - 18,
      child: Container(
        width: _GraphLayout.nodeWidth,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isYongShen
              ? AppColors.danjin.withOpacity(0.25)
              : Colors.white.withOpacity(0.7),
          border: Border.all(
            color: isYongShen
                ? AppColors.gutong
                : AppColors.danjin.withOpacity(0.6),
            width: isYongShen ? 1.4 : 0.8,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${positionNames[position - 1]}爻 '
          '${yao.liuQin.name}${yao.branch}${yao.wuXing.name}'
          '${yao.isMoving ? ' ╳' : ''}'
          '${yao.isSeYao ? ' 世' : yao.isYingYao ? ' 应' : ''}'
          '${isYongShen ? ' ·用' : ''}',
          style: AppTextStyles.antiqueLabel.copyWith(
            color: yao.isMoving ? AppColors.zhusha : AppColors.xuanse,
            fontWeight: isYongShen ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBianNode(_GraphLayout layout, int position) {
    final changed = changingGua!.yaos[position - 1];
    return Positioned(
      left: layout.bianLeft,
      top: layout.yaoY(position) - 15,
      child: Container(
        width: _GraphLayout.bianWidth,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.xiangseDeep.withOpacity(0.8),
          border: Border.all(color: AppColors.qianhe.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${changed.liuQin.name}${changed.branch}${changed.wuXing.name}',
          style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
        ),
      ),
    );
  }

}

/// 固定坐标布局：本卦列偏右，左侧留弧线区，最右为变爻列
class _GraphLayout {
  const _GraphLayout({required this.width});

  final double width;

  static const double nodeWidth = 140;
  static const double bianWidth = 88;
  static const double rowHeight = 54;
  static const double topHeight = 52;

  double get bianLeft => width - 10 - bianWidth;
  double get nodeLeft => bianLeft - 18 - nodeWidth;
  double get nodeRight => nodeLeft + nodeWidth;
  double get graphHeight => topHeight + 6 * rowHeight;

  /// 爻位 1-6 → 纵坐标（上爻在最上）
  double yaoY(int position) =>
      topHeight + (6 - position) * rowHeight + rowHeight / 2;

  Offset get yueCenter => Offset(width * 0.14 + 20, topHeight / 2);
  Offset get riCenter => Offset(width * 0.14 + 110, topHeight / 2);
}

class _RelationGraphPainter extends CustomPainter {
  _RelationGraphPainter({required this.edges, required this.layout});

  final List<RelationEdge> edges;
  final _GraphLayout layout;

  /// 已放置标签的占位矩形（碰撞避让用）
  final List<Rect> _placedLabels = [];

  @override
  void paint(Canvas canvas, Size size) {
    _placedLabels.clear();
    final bianEdges = edges.where((e) => e.isBianEdge).toList();
    final leftEdges = edges.where((e) => !e.isBianEdge).toList()
      // 短跨度在内圈：先爻间边按跨度升序，日月边固定在外圈
      ..sort((a, b) {
        final aExternal = a.from > 6 ? 1 : 0;
        final bExternal = b.from > 6 ? 1 : 0;
        if (aExternal != bExternal) return aExternal - bExternal;
        return _span(a).compareTo(_span(b));
      });

    for (var lane = 0; lane < leftEdges.length; lane++) {
      final edge = leftEdges[lane];
      final color = _colorOf(edge.kind);
      final dashed = edge.kind == RelationKind.ke;
      final path = edge.from > 6
          ? _dayMonthPath(edge, lane)
          : _leftArc(edge, lane);
      _drawPath(canvas, path, color, dashed: dashed);
      if (edge.directed) _drawArrowhead(canvas, path, color);
      _drawLabelAlongPath(canvas, path, edge.term, color);
    }

    for (final edge in bianEdges) {
      final color = _colorOf(edge.kind);
      final path = _bianPath(edge);
      _drawPath(canvas, path, color,
          dashed: edge.kind == RelationKind.ke);
      if (edge.directed) _drawArrowhead(canvas, path, color);
      _drawBianLabel(canvas, edge, color);
    }
  }

  double _span(RelationEdge e) =>
      (layout.yaoY(e.from.clamp(1, 6)) - layout.yaoY(e.to.clamp(1, 6))).abs();

  Color _colorOf(RelationKind kind) => switch (kind) {
        RelationKind.sheng => AppColors.jishenGreen,
        RelationKind.ke => AppColors.zhusha,
        RelationKind.he => AppColors.danjinDeep,
        RelationKind.neutral => AppColors.huise,
      };

  /// 爻间左侧弧线；lane 递增外扩
  Path _leftArc(RelationEdge edge, int lane) {
    final y1 = layout.yaoY(edge.from);
    final y2 = layout.yaoY(edge.to);
    final x = layout.nodeLeft;
    final controlX = x - 24 - lane * 13;
    return Path()
      ..moveTo(x, y1)
      ..quadraticBezierTo(controlX, (y1 + y2) / 2, x, y2);
  }

  /// 日月节点 → 爻节点（同样走左侧，外圈）
  Path _dayMonthPath(RelationEdge edge, int lane) {
    final start = edge.from == RelationEdge.yueNode
        ? layout.yueCenter
        : layout.riCenter;
    final targetY = layout.yaoY(edge.to);
    final controlX = layout.nodeLeft - 24 - lane * 13;
    return Path()
      ..moveTo(start.dx, start.dy + 14)
      ..quadraticBezierTo(
          controlX, (start.dy + targetY) / 2, layout.nodeLeft, targetY);
  }

  /// 本爻 ↔ 变爻 短横线
  Path _bianPath(RelationEdge edge) {
    final position = (edge.from > RelationEdge.bianNodeOffset
            ? edge.from - RelationEdge.bianNodeOffset
            : edge.from)
        .clamp(1, 6);
    final y = layout.yaoY(position);
    final fromBian = edge.from > RelationEdge.bianNodeOffset;
    // 回头类从变爻指向本爻，其余从本爻指向变爻
    return fromBian
        ? (Path()
          ..moveTo(layout.bianLeft, y)
          ..lineTo(layout.nodeRight, y))
        : (Path()
          ..moveTo(layout.nodeRight, y)
          ..lineTo(layout.bianLeft, y));
  }

  void _drawPath(Canvas canvas, Path path, Color color,
      {required bool dashed}) {
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  void _drawArrowhead(Canvas canvas, Path path, Color color) {
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length - 0.5);
    if (tangent == null) return;
    final angle = tangent.angle;
    final tip = tangent.position;
    const arrowSize = 6.0;
    final p1 = tip -
        Offset(math.cos(angle - 0.45), math.sin(angle - 0.45)) * arrowSize;
    final p2 = tip -
        Offset(math.cos(angle + 0.45), math.sin(angle + 0.45)) * arrowSize;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  /// 弧线标签：沿线滑动寻找不与已放置标签重叠的位置。
  /// 每条弧形状不同，沿线滑动同时产生水平与垂直分离。
  static const List<double> _labelSlots = [
    0.5, 0.38, 0.62, 0.28, 0.72, 0.2, 0.8,
  ];

  void _drawLabelAlongPath(
      Canvas canvas, Path path, String term, Color color) {
    final metric = path.computeMetrics().first;
    final painter = _layoutText(term, color);

    Offset? fallback;
    for (final t in _labelSlots) {
      final position =
          metric.getTangentForOffset(metric.length * t)?.position;
      if (position == null) continue;
      fallback ??= position;
      final rect = Rect.fromCenter(
        center: position,
        width: painter.width + 4,
        height: painter.height + 2,
      );
      if (_placedLabels.every((placed) => !placed.overlaps(rect))) {
        _placedLabels.add(rect);
        painter.paint(canvas,
            position - Offset(painter.width / 2, painter.height / 2));
        return;
      }
    }
    // 所有槽位均冲突：退回中点绘制并占位（宁重叠不丢失）
    if (fallback != null) {
      _placedLabels.add(Rect.fromCenter(
          center: fallback,
          width: painter.width + 4,
          height: painter.height + 2));
      painter.paint(canvas,
          fallback - Offset(painter.width / 2, painter.height / 2));
    }
  }

  /// 变爻线标签：置于横线上方中点（右侧空间独立，无需避让弧线）
  void _drawBianLabel(Canvas canvas, RelationEdge edge, Color color) {
    final position = (edge.from > RelationEdge.bianNodeOffset
            ? edge.from - RelationEdge.bianNodeOffset
            : edge.from)
        .clamp(1, 6);
    final midX = (layout.nodeRight + layout.bianLeft) / 2;
    final center = Offset(midX, layout.yaoY(position) - 8);
    final painter = _layoutText(edge.term, color);
    _placedLabels.add(Rect.fromCenter(
        center: center,
        width: painter.width + 4,
        height: painter.height + 2));
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  TextPainter _layoutText(String text, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
          backgroundColor: AppColors.xiangse.withOpacity(0.9),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(_RelationGraphPainter oldDelegate) =>
      oldDelegate.edges != edges;
}

