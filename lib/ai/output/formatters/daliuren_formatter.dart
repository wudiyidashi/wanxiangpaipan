/// 大六壬结构化输出格式化器
///
/// 将大六壬排盘结果转换为稳定的结构化文本，
/// 用于 LLM 分析、文档比对与后续 schema 收敛。
library;

import 'package:lunar/lunar.dart';

import '../../../divination_systems/daliuren/models/chuan.dart';
import '../../../divination_systems/daliuren/models/daliuren_result.dart';
import '../../../divination_systems/daliuren/models/dlr_cast_time.dart';
import '../../../divination_systems/daliuren/models/dlr_rule_contract.dart';
import '../../../divination_systems/daliuren/models/pan_params.dart';
import '../../../divination_systems/daliuren/models/shen_sha.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/daliuren/analysis/daliuren_analyzer.dart';
import '../../../domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import '../../../domain/services/daliuren/dlr_cast_time_service.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

/// 大六壬结构化输出格式化器
class DaLiuRenStructuredFormatter
    extends StructuredOutputFormatter<DaLiuRenResult> {
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  @override
  StructuredDivinationOutput format(DaLiuRenResult result, {String? question}) {
    final lunarDateText = _resolveLunarDateText(result);
    final report = DaLiuRenAnalyzer.analyze(result);

    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: _buildTemporalInfo(result, lunarDateText),
      coreData: _buildCoreData(result,
          question: question, lunarDateText: lunarDateText, report: report),
      sections:
          _buildSections(result, lunarDateText: lunarDateText, report: report),
      userQuestion: question,
      summary: result.getSummary(),
    );
  }

  TemporalInfo _buildTemporalInfo(
    DaLiuRenResult result,
    String? lunarDateText,
  ) {
    final lunar = result.lunarInfo;
    return TemporalInfo(
      solarTime: result.civilTime?.instantUtc ?? result.castTime,
      yearGanZhi: lunar.yearGanZhi,
      monthGanZhi: lunar.monthGanZhi,
      dayGanZhi: lunar.riGanZhi,
      hourGanZhi: lunar.hourGanZhi,
      kongWang: lunar.kongWang,
      solarTerm: lunar.solarTerm,
      lunarDate: lunarDateText,
      yueJian: lunar.yueJian,
    );
  }

  Map<String, dynamic> _buildCoreData(
    DaLiuRenResult result, {
    required String? question,
    required String? lunarDateText,
    required DaLiuRenAnalysisReport report,
  }) {
    return {
      'formatTitle': '大六壬完整结构化排盘',
      'overview': {
        'castTime': _isRawManual(result)
            ? null
            : _formatIsoDateTime(_displayWallTime(result)),
        'castInstantUtc': result.civilTime?.instantUtc.toIso8601String(),
        'sourceUtcOffsetMinutes': result.civilTime?.sourceUtcOffsetMinutes,
        'calendarValidated': result.civilTime != null,
        'lunarDate': lunarDateText,
        'solarTerm': result.lunarInfo.solarTerm,
        'question': question,
        'pillars':
            '${result.lunarInfo.yearGanZhi}年 ${result.lunarInfo.monthGanZhi}月 ${result.lunarInfo.riGanZhi}日 ${result.lunarInfo.hourGanZhi ?? result.shiZhi}时',
        'dayMaster': result.riGan,
        'kongWang': result.lunarInfo.kongWang,
        'yueJiang': '${result.tianPan.yueJiang}将',
        'dayOrNight': _isDay(result) ? '昼占' : '夜占',
        'selectedGuiRenTianBranch':
            result.shenJiangConfig.selectedGuiRenTianBranch,
        'guiRenEarthPalace': result.shenJiangConfig.guiRenEarthPalace,
        'actualDirection': result.shenJiangConfig.actualDirection.name,
        'guiRenVerse': result.panParams.guiRenVerseLabel,
        'panRuleSetVersion': result.panRuleSetVersion,
        'evidenceCatalogVersion': result.evidenceCatalogVersion,
        'analysisCompatibility': report.compatibilityStatus.name,
        'xunShou': result.panParams.xunShouModeLabel,
        'xunShouGanZhi': _resolveXunShouGanZhi(result),
        'keType': result.keTypeName,
        'sanChuan': [
          result.chuChuan,
          result.zhongChuan,
          result.moChuan,
        ],
        'yueJian': result.lunarInfo.yueJian,
        'riJian': result.riZhi,
      },
      'monthGeneralResolution': result.monthGeneralResolution?.toJson(),
      'tianPan': result.tianPan.fullDisplay,
      'shenJiang': result.shenJiangConfig.positions
          .map((position) => {
                'name': position.name,
                'heavenBranch': position.heavenBranch,
                'earthPalace': position.earthPalace,
              })
          .toList(),
      'siKe': result.siKe.allKe
          .map((ke) => {
                'index': ke.index,
                'shangShen': ke.shangShen,
                'xiaShen': ke.xiaShen,
                'tianJiang': ke.chengShenName,
                'relation': ke.wuXingRelation,
              })
          .toList(),
      'sanChuan': {
        'keType': result.keTypeName,
        'explanation': result.sanChuan.keTypeExplanation,
        'chu': _buildChuanMap(result.sanChuan.chuChuan),
        'zhong': _buildChuanMap(result.sanChuan.zhongChuan),
        'mo': _buildChuanMap(result.sanChuan.moChuan),
      },
      'keGeName': report.keGe.geName,
      'verdictTrend': report.judgment?.trend.name,
    };
  }

  Map<String, dynamic> _buildChuanMap(Chuan chuan) {
    return {
      'diZhi': chuan.diZhi,
      'liuQin': chuan.liuQin,
      'tianJiang': chuan.chengShenName,
      'isKongWang': chuan.isKongWang,
    };
  }

  List<StructuredSection> _buildSections(
    DaLiuRenResult result, {
    required String? lunarDateText,
    required DaLiuRenAnalysisReport report,
  }) {
    return [
      StructuredSection(
        key: 'overview',
        title: '一、排盘总览',
        content: _formatOverview(result, lunarDateText, report),
        priority: 1,
      ),
      StructuredSection(
        key: 'tianPan',
        title: '二、天地盘全宫（地盘→天盘）',
        content: _formatTianPan(result),
        priority: 2,
      ),
      StructuredSection(
        key: 'shenJiang',
        title: '三、十二天将完整分布',
        content: _formatShenJiang(result),
        priority: 3,
      ),
      StructuredSection(
        key: 'siKe',
        title: '四、四课（天盘/地盘/天将/生克）',
        content: _formatSiKe(result),
        priority: 4,
      ),
      StructuredSection(
        key: 'sanChuan',
        title: '五、三传',
        content: _formatSanChuan(result),
        priority: 5,
      ),
      StructuredSection(
        key: 'shenSha',
        title: '六、神煞',
        content: _formatShenSha(result),
        priority: 6,
      ),
      StructuredSection(
        key: 'analysis',
        title: '七、断课分析（规则标注）',
        content: _formatAnalysis(report),
        priority: 7,
      ),
    ];
  }

  /// 将 DaLiuRenAnalyzer 的客观分析报告渲染为提示词文本。
  ///
  /// 措辞对齐六爻 analysis section：程序按既定规则标注、
  /// 分级列出、不下断语。
  String _formatAnalysis(DaLiuRenAnalysisReport report) {
    final buffer = StringBuffer();
    buffer.writeln(
      '以下状态由程序按既定规则标注；应期是条件候选，不可据此单独断定成败：',
    );
    buffer.writeln(
      '课格：课体${report.keGe.keTypeName}，格局${report.keGe.geName}'
      '（${report.keGe.polarity.name}）：${report.keGe.reason}',
    );

    if (report.ganZhiTags.isNotEmpty) {
      buffer.writeln('干支主客：');
      for (final tag in report.ganZhiTags) {
        buffer.writeln('- ${tag.term}：${tag.reason}');
      }
    }

    buffer.writeln('三传标签：');
    for (final position in ChuanPosition.values) {
      final tags = report.chuanTags[position] ?? const <DlrAnalysisTag>[];
      final text = tags.isEmpty
          ? '无'
          : tags.map((t) => '${t.term}（${t.reason}）').join('、');
      buffer.writeln('- ${position.displayName}：$text');
    }

    if (report.juTags.isNotEmpty) {
      buffer.writeln('课局标签：');
      for (final tag in report.juTags) {
        buffer.writeln('- ${tag.term}（${tag.reason}）');
      }
    }

    final judgment = report.judgment;
    if (judgment != null) {
      buffer.writeln('裁决摘要：${report.verdictSummary ?? judgment.summary}');
      for (final condition in judgment.conditions) {
        buffer.writeln(
          '- 未决条件：${condition.label}'
          '${condition.branch == null ? '' : '（${condition.branch}）'}'
          '：${condition.reason}'
          '${condition.hasRescue ? '' : '（无解救路径）'}',
        );
      }
    }

    final yingQi = report.yingQi;
    if (yingQi != null && yingQi.isNotEmpty) {
      buffer.writeln('应期候选：');
      for (final candidate in yingQi) {
        buffer.writeln('- ${candidate.label}：${candidate.reason}');
      }
    }

    return buffer.toString().trimRight();
  }

  String _formatOverview(
    DaLiuRenResult result,
    String? lunarDateText,
    DaLiuRenAnalysisReport report,
  ) {
    final buffer = StringBuffer();
    if (_isRawManual(result)) {
      buffer.writeln('- 起课：原始四柱（未校历）');
    } else {
      buffer.writeln(
        '- 起课：${_formatIsoDateTime(_displayWallTime(result))}'
        '（农历${lunarDateText ?? '未知'}）',
      );
    }
    final civilTime = result.civilTime;
    if (civilTime != null) {
      buffer.writeln(
        '- 来源时差：${_formatUtcOffset(civilTime.sourceUtcOffsetMinutes)}',
      );
    }
    buffer.writeln(
      '- 四柱：${result.lunarInfo.yearGanZhi}年 '
      '${result.lunarInfo.monthGanZhi}月 '
      '${result.lunarInfo.riGanZhi}日 '
      '${result.lunarInfo.hourGanZhi ?? result.shiZhi}时',
    );
    buffer.writeln('- 日主：${result.riGan}');
    buffer.writeln('- 旬空：${_joinBranches(result.lunarInfo.kongWang)}空');
    buffer.writeln(
      '- 月将：${result.tianPan.yueJiang}将（${result.tianPan.yueJiang}加${result.shiZhi}时）',
    );
    final resolution = result.monthGeneralResolution;
    if (resolution != null) {
      final source = switch (resolution.mode) {
        DlrMonthGeneralResolutionMode.zhongQi =>
          '${resolution.effectiveZhongQi ?? '中气'}后自动取将',
        DlrMonthGeneralResolutionMode.manualOverride => '手动指定',
      };
      buffer.writeln('- 月将来源：$source');
    }
    buffer.writeln('- 节气：${result.lunarInfo.solarTerm ?? '未校历'}');
    buffer.writeln('- 昼夜：${_isDay(result) ? '昼占' : '夜占'}');
    buffer.writeln(
      '- 贵人：${_isDay(result) ? '昼贵' : '夜贵'}'
      '${result.shenJiangConfig.selectedGuiRenTianBranch}'
      '，临${result.shenJiangConfig.guiRenEarthPalace}宫',
    );
    buffer.writeln('- 布将：${result.shenJiangConfig.directionDescription}');
    buffer.writeln('- 盘面规则：${result.panRuleSetVersion}');
    if (report.compatibilityStatus != DlrAnalysisCompatibility.current) {
      buffer.writeln(
        '- 兼容状态：${report.compatibilityStatus.name}（历史规则盘，按原盘事实分析）',
      );
    }
    buffer.writeln('- 贵人口诀：${result.panParams.guiRenVerseLabel}');
    buffer.writeln('- 旬位：${result.panParams.xunShouModeLabel}');
    buffer.writeln('- 旬首：${_resolveXunShouGanZhi(result)}旬');
    buffer.writeln('- 课格：${result.keTypeName}课');
    buffer.writeln(
      '- 三传：${result.chuChuan} → ${result.zhongChuan} → ${result.moChuan}',
    );
    buffer.writeln('- 月建：${result.lunarInfo.yueJian}');
    buffer.write('- 日建：${result.riZhi}');
    return buffer.toString();
  }

  String _formatTianPan(DaLiuRenResult result) {
    final buffer = StringBuffer();
    for (final item in result.tianPan.fullDisplay) {
      buffer.writeln('- ${item['地盘']}→${item['天盘']}');
    }
    return buffer.toString().trimRight();
  }

  String _formatShenJiang(DaLiuRenResult result) {
    final buffer = StringBuffer();
    for (final position in result.shenJiangConfig.positions) {
      buffer.writeln(
        '- ${position.name}：乘${position.heavenBranch}，临${position.earthPalace}宫',
      );
    }
    return buffer.toString().trimRight();
  }

  String _formatSiKe(DaLiuRenResult result) {
    final ordered = [
      result.siKe.ke1,
      result.siKe.ke2,
      result.siKe.ke3,
      result.siKe.ke4,
    ];
    final names = ['一课', '二课', '三课', '四课'];
    final buffer = StringBuffer();
    for (var i = 0; i < ordered.length; i++) {
      final ke = ordered[i];
      buffer.writeln(
        '- ${names[i]}：${ke.shangShen} / ${ke.xiaShen} / ${ke.chengShenName} / ${ke.wuXingRelation ?? '未标注'}',
      );
    }
    return buffer.toString().trimRight();
  }

  String _formatSanChuan(DaLiuRenResult result) {
    final buffer = StringBuffer();
    buffer.writeln(
      '- 取传依据：${result.sanChuan.keTypeExplanation ?? '按${result.keTypeName}规则取传'}',
    );
    buffer.writeln('- 初传：${_formatChuanLine(result.sanChuan.chuChuan)}');
    buffer.writeln('- 中传：${_formatChuanLine(result.sanChuan.zhongChuan)}');
    buffer.write('- 末传：${_formatChuanLine(result.sanChuan.moChuan)}');
    return buffer.toString();
  }

  String _formatChuanLine(Chuan chuan) {
    final kongWangText = chuan.isKongWang ? ' / 空亡' : ' / 非空亡';
    return '${chuan.diZhi} / ${chuan.liuQin} / ${chuan.chengShenName}$kongWangText';
  }

  String _formatShenSha(DaLiuRenResult result) {
    final buffer = StringBuffer();
    buffer.writeln('- 吉神：${_formatShenShaGroup(result.shenShaList.jiShen)}');
    buffer.write('- 凶神：${_formatShenShaGroup(result.shenShaList.xiongShen)}');
    return buffer.toString().trimRight();
  }

  @override
  String render(StructuredDivinationOutput output) {
    final buffer = StringBuffer();
    buffer.writeln('【大六壬完整结构化排盘】');
    buffer.writeln();

    final sortedSections = List<StructuredSection>.from(output.sections)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (var i = 0; i < sortedSections.length; i++) {
      final section = sortedSections[i];
      buffer.writeln(section.title);
      buffer.writeln(section.content.trimRight());
      if (i != sortedSections.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  bool _isDay(DaLiuRenResult result) => result.shenJiangConfig.isYangGui;

  /// 解析旬首干支（如「甲申」）。
  ///
  /// 口径对齐 `daliuren_result_screen.dart._resolveXunName`：
  /// 按 [DaLiuRenXunShouMode] 取旬目标干支，索引落到所在旬的旬首。
  String _resolveXunShouGanZhi(DaLiuRenResult result) {
    final xunTarget = result.panParams.xunShouMode == DaLiuRenXunShouMode.hour
        ? (result.lunarInfo.hourGanZhi ?? result.lunarInfo.riGanZhi)
        : result.lunarInfo.riGanZhi;
    final index = TianGanDiZhiService.getGanZhiIndex(xunTarget);
    if (index == -1) {
      return '';
    }
    final xunStartIndex = (index ~/ 10) * 10;
    return TianGanDiZhiService.getGanZhi(xunStartIndex);
  }

  String _joinBranches(List<String> branches) => branches.join();

  String _formatShenShaGroup(List<ShenSha> shenShaList) {
    if (shenShaList.isEmpty) {
      return '无';
    }
    return shenShaList.map((shenSha) => shenSha.displayText).join('、');
  }

  String _formatLunarDate(Lunar lunar) {
    return '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }

  String? _resolveLunarDateText(DaLiuRenResult result) {
    if (_isRawManual(result)) {
      return null;
    }
    final civilTime = result.civilTime;
    if (civilTime != null) {
      return DlrCastTimeService.formatLunarDate(civilTime);
    }
    return _formatLunarDate(Lunar.fromDate(result.castTime));
  }

  bool _isRawManual(DaLiuRenResult result) =>
      result.civilTime == null &&
      result.monthGeneralResolution?.mode ==
          DlrMonthGeneralResolutionMode.manualOverride;

  DateTime _displayWallTime(DaLiuRenResult result) =>
      result.civilTime?.sourceWallTime ?? result.castTime;

  String _formatUtcOffset(int minutes) {
    final sign = minutes >= 0 ? '+' : '-';
    final absolute = minutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final remainder = (absolute % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$remainder';
  }

  String _formatIsoDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
