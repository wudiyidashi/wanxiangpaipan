import 'package:flutter/material.dart';

import '../../../domain/services/daliuren/analysis/daliuren_analyzer.dart';
import '../../../domain/services/daliuren/dlr_cast_time_service.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../../presentation/divination/divination_result_page.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/ying_qi_card.dart';
import '../models/daliuren_result.dart';
import '../models/dlr_cast_time.dart';
import '../models/dlr_rule_contract.dart';
import '../models/pan_params.dart';
import 'daliuren_result_sections.dart';
import 'widgets/daliuren_ke_ge_card.dart';
import 'widgets/daliuren_pan_disk_dialog.dart';

/// 大六壬结果展示界面（仿古风）
class DaLiuRenResultScreen extends StatelessWidget {
  const DaLiuRenResultScreen({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    // 纯函数派生分析报告，不落库、不缓存
    final report = DaLiuRenAnalyzer.analyze(result);

    final upperSection = result.panParams.showSanChuanOnTop
        ? DaLiuRenSanChuanSection(result: result, report: report)
        : DaLiuRenSiKeSection(result: result);
    final lowerSection = result.panParams.showSanChuanOnTop
        ? DaLiuRenSiKeSection(result: result)
        : DaLiuRenSanChuanSection(result: result, report: report);

    return DivinationResultPage(
      result: result,
      title: '大六壬排盘结果',
      fallbackQuestion: result.questionId.isNotEmpty ? result.questionId : null,
      buildSections: (context, question) => [
        ExtendedInfoSection(
          castTime: result.castTime,
          lunarInfo: result.lunarInfo,
          liuShen: const [],
          resolvedRows: _buildExtendedInfoRows(),
        ),
        DaLiuRenPanParamsSection(
          question: question,
          ganZhiText: _buildGanZhiText(),
          dunGanText: _buildDunGanText(),
          yueJiangText: _buildYueJiangText(),
          guiRenText: _buildGuiRenText(),
          ruleVersionText:
              report.compatibilityStatus == DlrAnalysisCompatibility.current
                  ? result.panRuleSetVersion
                  : '${result.panRuleSetVersion}（历史规则盘，按原盘事实展示）',
        ),
        DaLiuRenKeGeCard(report: report),
        upperSection,
        lowerSection,
        DaLiuRenPanDiskEntrySection(result: result),
        DaLiuRenTianPanSection(result: result),
        DaLiuRenShenJiangSection(result: result),
        DaLiuRenShenShaSection(result: result),
        YingQiCard(candidates: report.yingQi ?? const []),
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
    final resolution = result.monthGeneralResolution;
    final modeLabel = switch (resolution?.mode) {
      DlrMonthGeneralResolutionMode.manualOverride => '手动指定',
      DlrMonthGeneralResolutionMode.zhongQi =>
        '${resolution?.effectiveZhongQi ?? '中气'}后系统选将',
      null => result.panParams.usesManualMonthGeneral ? '手动指定' : '系统选将',
    };
    return '${result.tianPan.yueJiang} 将($modeLabel)';
  }

  List<ExtendedInfoRow>? _buildExtendedInfoRows() {
    final civilTime = result.civilTime;
    final resolution = result.monthGeneralResolution;
    if (civilTime == null) {
      if (resolution?.mode == DlrMonthGeneralResolutionMode.manualOverride) {
        return <ExtendedInfoRow>[
          const ExtendedInfoRow(label: '历法时', value: '未校历（原始四柱）'),
          ExtendedInfoRow(
            label: '月　将',
            value: '${resolution!.yueJiang}（手动指定）',
          ),
        ];
      }
      return null;
    }

    final sourceWall = civilTime.sourceWallTime;
    final hourZhi = result.lunarInfo.hourGanZhi?.substring(1) ?? result.shiZhi;
    final rows = <ExtendedInfoRow>[
      ExtendedInfoRow(
        label: '阳历时',
        value: '${_formatDateTime(sourceWall)} '
            '(${_formatUtcOffset(civilTime.sourceUtcOffsetMinutes)})',
      ),
      ExtendedInfoRow(
        label: '农历时',
        value: '${sourceWall.year}年'
            '${DlrCastTimeService.formatLunarDate(civilTime)}$hourZhi时',
      ),
    ];

    final term = resolution?.effectiveZhongQi;
    final termInstant = resolution?.effectiveZhongQiInstantUtc;
    if (term != null && termInstant != null) {
      final beijingWall = DlrCivilTime.wallTimeAtOffset(
        termInstant,
        DlrCastTimeService.beijingUtcOffsetMinutes,
      );
      rows.add(
        ExtendedInfoRow(
          label: _formatTermLabel(term),
          value: '${_formatChineseDateTime(beijingWall)}（北京时）',
        ),
      );
    }
    return rows;
  }

  String _buildGuiRenText() {
    final guiRenType = result.shenJiangConfig.isYangGui ? '昼贵' : '夜贵';
    return '$guiRenType${result.shenJiangConfig.selectedGuiRenTianBranch}'
        '，临${result.shenJiangConfig.guiRenEarthPalace}宫，'
        '${result.shenJiangConfig.directionDescription}';
  }

  String _resolveXunName(String ganZhi) {
    final index = TianGanDiZhiService.getGanZhiIndex(ganZhi);
    if (index == -1) {
      return '';
    }
    final xunStartIndex = (index ~/ 10) * 10;
    return TianGanDiZhiService.getGanZhi(xunStartIndex);
  }

  String _formatDateTime(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _formatChineseDateTime(DateTime value) =>
      '${value.year}年${value.month.toString().padLeft(2, '0')}月'
      '${value.day.toString().padLeft(2, '0')}日'
      '${value.hour.toString().padLeft(2, '0')}时'
      '${value.minute.toString().padLeft(2, '0')}分';

  String _formatUtcOffset(int minutes) {
    final sign = minutes >= 0 ? '+' : '-';
    final absolute = minutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final remainder = (absolute % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$remainder';
  }

  String _formatTermLabel(String name) =>
      name.length == 2 ? '${name[0]}　${name[1]}' : name;
}
