import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../ai/output/formatters/liuyao_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../../../../presentation/widgets/liuyao_table_widget.dart';
import '../../liuyao_result.dart';

/// 排盘分享弹窗：预览合成图（起卦信息 + 卦象表格），
/// 下方可分享图片或复制 AI 友好的全量文字排盘。
Future<void> showLiuYaoShareDialog(
  BuildContext context, {
  required LiuYaoResult result,
  required AnalysisReport report,
  String? question,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LiuYaoShareDialog(
      result: result,
      report: report,
      question: question,
    ),
  );
}

class _LiuYaoShareDialog extends StatefulWidget {
  const _LiuYaoShareDialog({
    required this.result,
    required this.report,
    this.question,
  });

  final LiuYaoResult result;
  final AnalysisReport report;
  final String? question;

  @override
  State<_LiuYaoShareDialog> createState() => _LiuYaoShareDialogState();
}

class _LiuYaoShareDialogState extends State<_LiuYaoShareDialog> {
  final GlobalKey _previewKey = GlobalKey();
  bool _busy = false;

  /// AI 友好的全量文字排盘：占问/时间/月日建空亡/排盘/动爻/引擎分析（含用神链）
  String _buildShareText() {
    final formatter = LiuYaoStructuredFormatter();
    final output =
        formatter.format(widget.result, question: widget.question);
    final buffer = StringBuffer();
    if (widget.question != null && widget.question!.isNotEmpty) {
      buffer.writeln('【占问】${widget.question}');
    }
    final t = widget.result.castTime;
    buffer.writeln(
        '【起卦时间】${t.year}-${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}');
    buffer.write(formatter.render(output));
    return buffer.toString();
  }

  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            byteData.buffer.asUint8List(),
            mimeType: 'image/png',
          ),
        ],
        fileNameOverrides: ['liuyao_paipan.png'],
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文字排盘已复制，可直接粘贴给 AI 或好友')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final lunar = result.lunarInfo;

    return Dialog(
      backgroundColor: AppColors.xiangse,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '分享排盘',
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: RepaintBoundary(
                key: _previewKey,
                child: Container(
                  color: AppColors.xiangse,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.question != null &&
                          widget.question!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('占问：${widget.question}',
                              style: AppTextStyles.antiqueBody),
                        ),
                      Text(
                        '${lunar.yearGanZhi}年 ${lunar.monthGanZhi}月 '
                        '${lunar.riGanZhi}日（空 ${lunar.kongWang.join('')}）',
                        style: AppTextStyles.antiqueLabel
                            .copyWith(color: AppColors.guhe),
                      ),
                      const SizedBox(height: 8),
                      LiuYaoTableWidget(
                        gua: result.mainGua,
                        secondaryGua: result.changingGua,
                        liuShen: result.liuShen,
                        title: '本卦',
                        secondaryTitle: '变卦',
                        yaoTags: widget.report.yaoTags,
                        yongShenPosition: result.yongShenPosition,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _shareImage,
                  icon: const Icon(Icons.image_outlined, size: 16),
                  label: Text(_busy ? '生成中…' : '分享图片'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _copyText,
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('复制文字'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
