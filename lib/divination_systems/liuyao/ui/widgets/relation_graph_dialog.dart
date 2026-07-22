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
/// 采用固定坐标的简化示意图（六爻纵列 + 日月外部节点），
/// 不复用真实排盘表格，连线由 [_RelationGraphPainter] 绘制。
Future<void> showRelationGraphDialog(
  BuildContext context, {
  required Gua mainGua,
  required LunarInfo lunarInfo,
  required AnalysisReport report,
  int? yongShenPosition,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.xiangse,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RelationGraphView(
        mainGua: mainGua,
        lunarInfo: lunarInfo,
        report: report,
        yongShenPosition: yongShenPosition,
      ),
    ),
  );
}

class RelationGraphView extends StatelessWidget {
  const RelationGraphView({
    super.key,
    required this.mainGua,
    required this.lunarInfo,
    required this.report,
    this.yongShenPosition,
  });

  final Gua mainGua;
  final LunarInfo lunarInfo;
  final AnalysisReport report;
  final int? yongShenPosition;

  static const double _rowHeight = 54;
  static const double _topNodesHeight = 52;
  static const double _nodeWidth = 148;

  @override
  Widget build(BuildContext context) {
    final edges = buildRelationEdges(report);
    final width =
        math.min(MediaQuery.of(context).size.width - 24, 420).toDouble();
    final graphHeight = _topNodesHeight + 6 * _rowHeight;

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
          SizedBox(
            width: width,
            height: graphHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RelationGraphPainter(
                      edges: edges,
                      layout: _GraphLayout(
                        width: width,
                        topNodesHeight: _topNodesHeight,
                        rowHeight: _rowHeight,
                        nodeWidth: _nodeWidth,
                      ),
                    ),
                  ),
                ),
                _buildTopNodes(width),
                for (var position = 1; position <= 6; position++)
                  _buildYaoNode(width, position),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: edges.isEmpty
                ? Text(
                    '本卦当前无跨爻生克合冲关系',
                    style: AppTextStyles.antiqueLabel
                        .copyWith(color: AppColors.huise),
                  )
                : _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNodes(double width) {
    final layout = _GraphLayout(
      width: width,
      topNodesHeight: _topNodesHeight,
      rowHeight: _rowHeight,
      nodeWidth: _nodeWidth,
    );
    Widget chip(String label, Offset center) => Positioned(
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
              style: AppTextStyles.antiqueLabel
                  .copyWith(color: AppColors.dailan),
            ),
          ),
        );

    return Stack(children: [
      chip('月建 ${lunarInfo.yueJian}', layout.yueCenter),
      chip('日辰 ${lunarInfo.riZhi}', layout.riCenter),
    ]);
  }

  Widget _buildYaoNode(double width, int position) {
    const positionNames = ['初', '二', '三', '四', '五', '上'];
    final yao = mainGua.yaos[position - 1];
    final isYongShen = position == yongShenPosition;
    final layout = _GraphLayout(
      width: width,
      topNodesHeight: _topNodesHeight,
      rowHeight: _rowHeight,
      nodeWidth: _nodeWidth,
    );
    final y = layout.yaoY(position);

    return Positioned(
      left: layout.nodeLeft,
      top: y - 18,
      child: Container(
        width: _nodeWidth,
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

  Widget _buildLegend() {
    Widget item(Color color, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(22, 2),
              painter: _LegendLinePainter(color: color, dashed: dashed),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: color)),
          ],
        );

    return Wrap(
      spacing: 14,
      children: [
        item(AppColors.jishenGreen, '生扶'),
        item(AppColors.zhusha, '克冲刑害', dashed: true),
        item(AppColors.danjinDeep, '合'),
      ],
    );
  }
}

/// 固定坐标布局：所有锚点由尺寸参数推得
class _GraphLayout {
  const _GraphLayout({
    required this.width,
    required this.topNodesHeight,
    required this.rowHeight,
    required this.nodeWidth,
  });

  final double width;
  final double topNodesHeight;
  final double rowHeight;
  final double nodeWidth;

  double get nodeLeft => (width - nodeWidth) / 2;
  double get nodeRight => nodeLeft + nodeWidth;

  /// 爻位 1-6 → 纵坐标（上爻在最上）
  double yaoY(int position) =>
      topNodesHeight + (6 - position) * rowHeight + rowHeight / 2;

  Offset get yueCenter => Offset(width * 0.30, topNodesHeight / 2);
  Offset get riCenter => Offset(width * 0.70, topNodesHeight / 2);
}

class _RelationGraphPainter extends CustomPainter {
  _RelationGraphPainter({required this.edges, required this.layout});

  final List<RelationEdge> edges;
  final _GraphLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    var leftLane = 0;
    var rightLane = 0;

    for (final edge in edges) {
      final color = switch (edge.kind) {
        RelationKind.sheng => AppColors.jishenGreen,
        RelationKind.ke => AppColors.zhusha,
        RelationKind.he => AppColors.danjinDeep,
      };
      final dashed = edge.kind == RelationKind.ke;

      final Path path;
      if (edge.from > 6 || edge.to > 6) {
        path = _dayMonthPath(edge);
      } else if (edge.kind == RelationKind.he) {
        path = _sideArc(edge, left: true, lane: leftLane++);
      } else {
        path = _sideArc(edge, left: false, lane: rightLane++);
      }

      _drawPath(canvas, path, color, dashed: dashed);
      if (edge.directed) _drawArrowhead(canvas, path, color);
      _drawLabel(canvas, path, edge.term, color);
    }
  }

  /// 爻-爻侧边弧线；lane 递增错开避免重叠
  Path _sideArc(RelationEdge edge, {required bool left, required int lane}) {
    final y1 = layout.yaoY(edge.from);
    final y2 = layout.yaoY(edge.to);
    final x = left ? layout.nodeLeft : layout.nodeRight;
    final bulge = 26.0 + lane * 16;
    final controlX = left ? x - bulge : x + bulge;
    return Path()
      ..moveTo(x, y1)
      ..quadraticBezierTo(controlX, (y1 + y2) / 2, x, y2);
  }

  /// 日月节点 → 爻节点连线
  Path _dayMonthPath(RelationEdge edge) {
    final isYue = edge.from == RelationEdge.yueNode;
    final start = isYue ? layout.yueCenter : layout.riCenter;
    final targetY = layout.yaoY(edge.to);
    final endX = isYue ? layout.nodeLeft : layout.nodeRight;
    final controlX = isYue ? layout.nodeLeft - 34 : layout.nodeRight + 34;
    return Path()
      ..moveTo(start.dx, start.dy + 14)
      ..quadraticBezierTo(controlX, (start.dy + targetY) / 2, endX, targetY);
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
        canvas.drawPath(
            metric.extractPath(distance, distance + 5), paint);
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

  void _drawLabel(Canvas canvas, Path path, String term, Color color) {
    final metric = path.computeMetrics().first;
    final middle = metric.getTangentForOffset(metric.length / 2)?.position;
    if (middle == null) return;
    final painter = TextPainter(
      text: TextSpan(
        text: term,
        style: TextStyle(
          fontSize: 9,
          color: color,
          backgroundColor: AppColors.xiangse.withOpacity(0.85),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, middle - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_RelationGraphPainter oldDelegate) =>
      oldDelegate.edges != edges;
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    if (!dashed) {
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(math.min(x + 4, size.width), size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}
