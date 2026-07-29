import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../presentation/widgets/antique/antique.dart';
import '../../daliuren_constants.dart';
import '../../models/daliuren_result.dart';

/// 宫位角度换算：子在正下方（π/2），顺时针每宫 30°。
///
/// 画布坐标 y 轴向下，角度增加即视觉顺时针。
double panDiskAngle(int branchIndex) => math.pi / 2 + branchIndex * math.pi / 6;

/// 地支 → 宫位角度（弧度）；无效地支抛 [ArgumentError]。
double panDiskAngleForBranch(String branch) {
  final index = DaLiuRenConstants.getDiZhiIndex(branch);
  if (index == -1) {
    throw ArgumentError('无效地支，无法换算宫位角度: $branch');
  }
  return panDiskAngle(index);
}

/// 求某天盘地支所落的地盘宫位（初传弦线定位用）。
///
/// [tianPanMap] 为 地盘支 → 天盘支 映射；找不到时返回 null。
String? panDiskPalaceOf(Map<String, String> tianPanMap, String tianPanZhi) {
  for (final entry in tianPanMap.entries) {
    if (entry.value == tianPanZhi) return entry.key;
  }
  return null;
}

/// Resolves the general painted at an earth-palace position on the disk.
ShenJiang? panDiskGeneralForEarthPalace(
  DaLiuRenResult result,
  String earthPalace,
) =>
    result.shenJiangConfig.generalForEarthPalace(earthPalace);

/// 天地盘圆盘图入口卡
class DaLiuRenPanDiskEntrySection extends StatelessWidget {
  const DaLiuRenPanDiskEntrySection({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.blur_circular_outlined, size: 18),
          label: const Text('天地盘圆盘图'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.zhusha,
            side: BorderSide(color: AppColors.zhusha.withOpacity(0.5)),
          ),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => DaLiuRenPanDiskDialog(result: result),
          ),
        ),
      ),
    );
  }
}

/// 天地盘圆盘图弹窗：内环地盘、中环天盘、外环天将，附三传弦线与图例。
class DaLiuRenPanDiskDialog extends StatelessWidget {
  const DaLiuRenPanDiskDialog({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final diskSize = (screenWidth - 72).clamp(240.0, 400.0);

    return Dialog(
      backgroundColor: AppColors.xiangse,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Semantics(
        label: '天地盘圆盘图',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '天地盘圆盘图',
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
                width: diskSize,
                height: diskSize,
                child: CustomPaint(
                  painter: _PanDiskPainter(result: result),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: const [
                    _LegendItem(color: AppColors.biyongBlue, label: '日支宫'),
                    _LegendItem(color: AppColors.gutong, label: '日干寄宫'),
                    _LegendItem(color: AppColors.zhusha, label: '三传之支'),
                    _LegendItem(color: AppColors.jishenGreen, label: '吉将'),
                    _LegendItem(color: AppColors.huise, label: '凶将'),
                    _LegendItem(color: AppColors.danjinDeep, label: '初→中→末弦线'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.antiqueLabel),
      ],
    );
  }
}

/// 三环盘面绘制：纯绘制逻辑，数据全部来自 [result]。
class _PanDiskPainter extends CustomPainter {
  _PanDiskPainter({required this.result});

  final DaLiuRenResult result;

  static const List<String> _chuanLabels = ['初', '中', '末'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 4;
    // 三环半径：外环天将、中环天盘、内环地盘
    final ringRadii = [outerRadius, outerRadius * 0.78, outerRadius * 0.56];
    final innerHole = outerRadius * 0.34;

    _drawRingBorders(canvas, center, ringRadii, innerHole);
    _drawSectorLines(canvas, center, ringRadii.first, innerHole);
    _highlightDiPanPalaces(canvas, center, ringRadii[2], innerHole);
    _drawDiPanRing(canvas, center, (ringRadii[2] + innerHole) / 2);
    _drawTianPanRing(canvas, center, (ringRadii[1] + ringRadii[2]) / 2);
    _drawShenJiangRing(canvas, center, (ringRadii[0] + ringRadii[1]) / 2);
    _drawChuanChords(canvas, center, (ringRadii[1] + ringRadii[2]) / 2);
  }

  void _drawRingBorders(
    Canvas canvas,
    Offset center,
    List<double> radii,
    double innerHole,
  ) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.danjinDeep.withOpacity(0.8);
    for (final radius in [...radii, innerHole]) {
      canvas.drawCircle(center, radius, borderPaint);
    }
  }

  void _drawSectorLines(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerHole,
  ) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = AppColors.danjin.withOpacity(0.7);
    // 宫界线在宫位角基础上偏移半宫（15°）
    for (var i = 0; i < 12; i++) {
      final angle = panDiskAngle(i) + math.pi / 12;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * innerHole,
        center + direction * outerRadius,
        linePaint,
      );
    }
  }

  /// 内环高亮：日支宫（比用蓝）与日干寄宫（古铜），底色扇形填充
  void _highlightDiPanPalaces(
    Canvas canvas,
    Offset center,
    double ringRadius,
    double innerHole,
  ) {
    void fillSector(String branch, Color color) {
      final index = DaLiuRenConstants.getDiZhiIndex(branch);
      if (index == -1) return;
      final startAngle = panDiskAngle(index) - math.pi / 12;
      final paint = Paint()..color = color.withOpacity(0.18);
      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: ringRadius),
          startAngle,
          math.pi / 6,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerHole),
          startAngle + math.pi / 6,
          -math.pi / 6,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    final jiGong = DaLiuRenConstants.ganJiGong[result.riGan];
    fillSector(result.riZhi, AppColors.biyongBlue);
    if (jiGong != null && jiGong != result.riZhi) {
      fillSector(jiGong, AppColors.gutong);
    }
  }

  void _drawDiPanRing(Canvas canvas, Offset center, double radius) {
    for (var i = 0; i < 12; i++) {
      final branch = DaLiuRenConstants.diZhi[i];
      _paintText(
        canvas,
        center + _direction(i) * radius,
        branch,
        style: AppTextStyles.antiqueLabel.copyWith(
          fontSize: 12,
          color: AppColors.guhe,
        ),
      );
    }
  }

  void _drawTianPanRing(Canvas canvas, Offset center, double radius) {
    final chuanZhiToLabel = <String, String>{};
    final chuanList = result.sanChuan.allChuan;
    for (var i = 0; i < chuanList.length; i++) {
      // 同支多传时保留首个（初传优先）
      chuanZhiToLabel.putIfAbsent(chuanList[i].diZhi, () => _chuanLabels[i]);
    }

    for (var i = 0; i < 12; i++) {
      final diPan = DaLiuRenConstants.diZhi[i];
      final tianPan = result.tianPan.getTianPanZhi(diPan);
      final position = center + _direction(i) * radius;
      final chuanLabel = chuanZhiToLabel[tianPan];
      final isChuan = chuanLabel != null;

      if (isChuan) {
        // 三传之支：描边圆高亮
        canvas.drawCircle(
          position,
          11,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = AppColors.zhusha,
        );
      }
      _paintText(
        canvas,
        position,
        tianPan,
        style: AppTextStyles.antiqueBody.copyWith(
          fontSize: isChuan ? 15 : 13,
          fontWeight: isChuan ? FontWeight.bold : FontWeight.w500,
          color: isChuan ? AppColors.zhusha : AppColors.xuanse,
        ),
      );
      if (isChuan) {
        // 初/中/末 小字标注在字侧
        _paintText(
          canvas,
          position + _direction(i) * 17,
          chuanLabel,
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.zhusha,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }
  }

  void _drawShenJiangRing(Canvas canvas, Offset center, double radius) {
    for (var i = 0; i < 12; i++) {
      final diPan = DaLiuRenConstants.diZhi[i];
      final shenJiang = panDiskGeneralForEarthPalace(result, diPan);
      if (shenJiang == null) continue;
      final isJi = _jiJiang.contains(shenJiang);
      _paintText(
        canvas,
        center + _direction(i) * radius,
        shenJiang.name,
        style: AppTextStyles.antiqueLabel.copyWith(
          fontSize: 10,
          color: isJi ? AppColors.jishenGreen : AppColors.huise,
        ),
      );
    }
  }

  /// 三传弦线：初传宫→中传宫→末传宫两段带箭头直线
  void _drawChuanChords(Canvas canvas, Offset center, double radius) {
    final palaces = <String>[];
    for (final chuan in result.sanChuan.allChuan) {
      final palace = panDiskPalaceOf(result.tianPan.tianPanMap, chuan.diZhi);
      if (palace == null) return;
      palaces.add(palace);
    }

    final chordPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.danjinDeep.withOpacity(0.9);

    for (var i = 0; i < 2; i++) {
      final fromIndex = DaLiuRenConstants.getDiZhiIndex(palaces[i]);
      final toIndex = DaLiuRenConstants.getDiZhiIndex(palaces[i + 1]);
      if (fromIndex == -1 || toIndex == -1) continue;
      final from = center + _direction(fromIndex) * (radius - 14);
      final to = center + _direction(toIndex) * (radius - 14);
      if ((to - from).distance < 1) continue; // 伏吟同宫不画
      canvas.drawLine(from, to, chordPaint);
      _drawArrowhead(canvas, from, to, chordPaint.color);
    }
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 7.0;
    final p1 =
        to - Offset(math.cos(angle - 0.45), math.sin(angle - 0.45)) * arrowSize;
    final p2 =
        to - Offset(math.cos(angle + 0.45), math.sin(angle + 0.45)) * arrowSize;
    canvas.drawPath(
      Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  Offset _direction(int branchIndex) {
    final angle = panDiskAngle(branchIndex);
    return Offset(math.cos(angle), math.sin(angle));
  }

  void _paintText(
    Canvas canvas,
    Offset centerPosition,
    String text, {
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centerPosition - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// 吉将集合（与分析层口径一致：贵人六合青龙太常太阴天后）
  static const Set<ShenJiang> _jiJiang = {
    ShenJiang.guiRen,
    ShenJiang.liuHe,
    ShenJiang.qingLong,
    ShenJiang.taiChang,
    ShenJiang.taiYin,
    ShenJiang.tianHou,
  };

  @override
  bool shouldRepaint(_PanDiskPainter oldDelegate) =>
      oldDelegate.result != result;
}
