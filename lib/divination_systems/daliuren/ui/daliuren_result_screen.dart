import 'package:flutter/material.dart';

import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../models/daliuren_result.dart';
import '../models/pan_params.dart';
import 'daliuren_result_sections.dart';

/// 大六壬结果展示界面（仿古风）
class DaLiuRenResultScreen extends StatelessWidget {
  const DaLiuRenResultScreen({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    final upperSection = result.panParams.showSanChuanOnTop
        ? DaLiuRenSanChuanSection(result: result)
        : DaLiuRenSiKeSection(result: result);
    final lowerSection = result.panParams.showSanChuanOnTop
        ? DaLiuRenSiKeSection(result: result)
        : DaLiuRenSanChuanSection(result: result);

    return DivinationResultPage(
      result: result,
      title: '大六壬排盘结果',
      fallbackQuestion: result.questionId.isNotEmpty ? result.questionId : null,
      buildSections: (context, question) => [
        ExtendedInfoSection(
          castTime: result.castTime,
          lunarInfo: result.lunarInfo,
          liuShen: const [],
        ),
        DaLiuRenPanParamsSection(
          question: question,
          ganZhiText: _buildGanZhiText(),
          dunGanText: _buildDunGanText(),
          yueJiangText: _buildYueJiangText(),
          guiRenText: _buildGuiRenText(),
        ),
        upperSection,
        lowerSection,
        DaLiuRenTianPanSection(result: result),
        DaLiuRenShenJiangSection(result: result),
        DaLiuRenShenShaSection(result: result),
      ],
    );
  }

  String _buildGanZhiText() {
    final hourGanZhi = result.lunarInfo.hourGanZhi ?? result.shiZhi;
    return '${result.lunarInfo.yearGanZhi}年　'
        '${result.lunarInfo.monthGanZhi}月　'
        '${result.lunarInfo.riGanZhi}日　'
        '$hourGanZhi时';
  }

  String _buildDunGanText() {
    final xunTarget = result.panParams.xunShouMode == DaLiuRenXunShouMode.hour
        ? (result.lunarInfo.hourGanZhi ?? result.lunarInfo.riGanZhi)
        : result.lunarInfo.riGanZhi;
    final xunName = _resolveXunName(xunTarget);
    final kongWang = result.lunarInfo.kongWang.join();
    return '${result.panParams.xunShouModeLabel} $xunName旬 $kongWang空';
  }

  String _buildYueJiangText() {
    final modeLabel = result.panParams.usesManualMonthGeneral ? '手动指定' : '系统选将';
    return '${result.tianPan.yueJiang} 将($modeLabel)';
  }

  String _buildGuiRenText() {
    final guiRenType = result.shenJiangConfig.isYangGui ? '昼贵' : '夜贵';
    return '$guiRenType （${result.panParams.guiRenVerseLabel}）';
  }

  String _resolveXunName(String ganZhi) {
    final index = TianGanDiZhiService.getGanZhiIndex(ganZhi);
    if (index == -1) {
      return '';
    }
    final xunStartIndex = (index ~/ 10) * 10;
    return TianGanDiZhiService.getGanZhi(xunStartIndex);
  }
}
