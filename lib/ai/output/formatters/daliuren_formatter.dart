/// 大六壬结构化输出格式化器
///
/// 将大六壬排盘结果转换为稳定的结构化文本，
/// 用于 LLM 分析、文档比对与后续 schema 收敛。
library;

import 'package:lunar/lunar.dart';

import '../../../divination_systems/daliuren/models/chuan.dart';
import '../../../divination_systems/daliuren/models/daliuren_result.dart';
import '../../../divination_systems/daliuren/models/shen_sha.dart';
import '../../../domain/divination_system.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

/// 大六壬结构化输出格式化器
class DaLiuRenStructuredFormatter
    extends StructuredOutputFormatter<DaLiuRenResult> {
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  @override
  StructuredDivinationOutput format(DaLiuRenResult result, {String? question}) {
    final lunarDate = Lunar.fromDate(result.castTime);
    final lunarDateText = _formatLunarDate(lunarDate);

    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: _buildTemporalInfo(result, lunarDateText),
      coreData: _buildCoreData(result,
          question: question, lunarDateText: lunarDateText),
      sections: _buildSections(result, lunarDateText: lunarDateText),
      userQuestion: question,
      summary: result.getSummary(),
    );
  }

  TemporalInfo _buildTemporalInfo(DaLiuRenResult result, String lunarDateText) {
    final lunar = result.lunarInfo;
    return TemporalInfo(
      solarTime: result.castTime,
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
    required String lunarDateText,
  }) {
    return {
      'formatTitle': '大六壬完整结构化排盘',
      'overview': {
        'castTime': _formatIsoDateTime(result.castTime),
        'lunarDate': lunarDateText,
        'question': question,
        'pillars':
            '${result.lunarInfo.yearGanZhi}年 ${result.lunarInfo.monthGanZhi}月 ${result.lunarInfo.riGanZhi}日 ${result.lunarInfo.hourGanZhi ?? result.shiZhi}时',
        'dayMaster': result.riGan,
        'kongWang': result.lunarInfo.kongWang,
        'yueJiang': '${result.tianPan.yueJiang}将',
        'dayOrNight': _isDay(result) ? '昼占' : '夜占',
        'guiRen':
            '${_isDay(result) ? '昼贵' : '夜贵'}${result.shenJiangConfig.guiRenPosition}',
        'buJiang': result.shenJiangConfig.directionDescription,
        'guiRenVerse': result.panParams.guiRenVerseLabel,
        'xunShou': result.panParams.xunShouModeLabel,
        'keType': result.keTypeName,
        'sanChuan': [
          result.chuChuan,
          result.zhongChuan,
          result.moChuan,
        ],
        'yueJian': result.lunarInfo.yueJian,
        'riJian': result.riZhi,
      },
      'tianPan': result.tianPan.fullDisplay,
      'shenJiang': result.shenJiangConfig.positions
          .map((position) => {
                'name': position.name,
                'diZhi': position.diZhi,
                'tianPanZhi': position.tianPanZhi,
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
    required String lunarDateText,
  }) {
    return [
      StructuredSection(
        key: 'overview',
        title: '一、排盘总览',
        content: _formatOverview(result, lunarDateText),
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
    ];
  }

  String _formatOverview(DaLiuRenResult result, String lunarDateText) {
    final buffer = StringBuffer();
    buffer.writeln(
      '- 起课：${_formatIsoDateTime(result.castTime)}（农历$lunarDateText）',
    );
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
    buffer.writeln('- 昼夜：${_isDay(result) ? '昼占' : '夜占'}');
    buffer.writeln(
      '- 贵人：${_isDay(result) ? '昼贵' : '夜贵'}${result.shenJiangConfig.guiRenPosition}',
    );
    buffer.writeln('- 布将：${result.shenJiangConfig.directionDescription}');
    buffer.writeln('- 贵人口诀：${result.panParams.guiRenVerseLabel}');
    buffer.writeln('- 旬位：${result.panParams.xunShouModeLabel}');
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
        '- ${position.name}：${position.diZhi}（乘${position.tianPanZhi}）',
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

  String _formatIsoDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
