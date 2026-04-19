/// 小六壬结构化输出格式化器
///
/// 严格对应 `docs/architecture/divination-systems/xiaoliuren.md` 的排盘输出面。
///
/// 标题固定 `【小六壬完整结构化排盘】`，4 块：
///
/// 1. 排盘总览
/// 2. 起课依据
/// 3. 三段顺推
/// 4. 最终落宫
///
/// 占断结论不出现——断语由 AI 基于结构化输出独立生成。
library;

import 'package:lunar/lunar.dart';

import '../../../divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import '../../../domain/divination_system.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

class XiaoLiuRenStructuredFormatter
    extends StructuredOutputFormatter<XiaoLiuRenResult> {
  @override
  DivinationType get systemType => DivinationType.xiaoLiuRen;

  @override
  StructuredDivinationOutput format(
    XiaoLiuRenResult result, {
    String? question,
  }) {
    final lunar = Lunar.fromDate(result.castTime);
    final lunarDateText = _formatLunarDate(lunar);

    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: _buildTemporalInfo(result, lunarDateText),
      coreData: _buildCoreData(
        result,
        question: question,
        lunarDateText: lunarDateText,
      ),
      sections: _buildSections(result, lunarDateText: lunarDateText),
      userQuestion: question,
      summary: result.getSummary(),
    );
  }

  @override
  String render(StructuredDivinationOutput output) {
    final buffer = StringBuffer();
    buffer.writeln('【小六壬完整结构化排盘】');
    buffer.writeln();

    final sorted = List<StructuredSection>.from(output.sections)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (var i = 0; i < sorted.length; i++) {
      final section = sorted[i];
      buffer.writeln(section.title);
      buffer.writeln(section.content.trimRight());
      if (i != sorted.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  // --- structured pieces -------------------------------------------------

  TemporalInfo _buildTemporalInfo(
    XiaoLiuRenResult result,
    String lunarDateText,
  ) {
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
    XiaoLiuRenResult result, {
    required String? question,
    required String lunarDateText,
  }) {
    return {
      'formatTitle': '小六壬完整结构化排盘',
      'overview': {
        'castTime': _formatIsoDateTime(result.castTime),
        'lunarDate': lunarDateText,
        'question': question,
        'method': result.castMethod.id,
        'methodLabel': result.source.methodLabel,
        'palaceMode': result.palaceMode.id,
        'palaceModeLabel': result.palaceMode.displayName,
        'pillars': _formatPillars(result),
        'first': _positionStepMap(
          label: result.source.firstLabel,
          number: result.source.firstNumber,
          position: result.monthPosition,
        ),
        'second': _positionStepMap(
          label: result.source.secondLabel,
          number: result.source.secondNumber,
          position: result.dayPosition,
        ),
        'third': _positionStepMap(
          label: result.source.thirdLabel,
          number: result.source.thirdNumber,
          position: result.hourPosition,
        ),
        'finalPosition': _positionMap(result.finalPosition),
      },
      'source': {
        'methodLabel': result.source.methodLabel,
        'rule': result.source.rule,
        'firstLabel': result.source.firstLabel,
        'firstNumber': result.source.firstNumber,
        'secondLabel': result.source.secondLabel,
        'secondNumber': result.source.secondNumber,
        'thirdLabel': result.source.thirdLabel,
        'thirdNumber': result.source.thirdNumber,
        'hourZhi': result.source.hourZhi,
        'usesLunarDate': result.source.usesLunarDate,
        'note': result.source.note,
      },
      'chain': [
        _positionStepMap(
          label: result.source.firstLabel,
          number: result.source.firstNumber,
          position: result.monthPosition,
        ),
        _positionStepMap(
          label: result.source.secondLabel,
          number: result.source.secondNumber,
          position: result.dayPosition,
        ),
        _positionStepMap(
          label: result.source.thirdLabel,
          number: result.source.thirdNumber,
          position: result.hourPosition,
        ),
      ],
    };
  }

  Map<String, dynamic> _positionStepMap({
    required String label,
    required int number,
    required XiaoLiuRenPosition position,
  }) {
    return {
      'label': label,
      'number': number,
      'position': _positionMap(position),
    };
  }

  Map<String, dynamic> _positionMap(XiaoLiuRenPosition position) {
    return {
      'index': position.index,
      'name': position.name,
      'fortune': position.fortune,
      'keyword': position.keyword,
      'wuXing': position.wuXing,
      'direction': position.direction,
      'description': position.description,
    };
  }

  List<StructuredSection> _buildSections(
    XiaoLiuRenResult result, {
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
        key: 'source',
        title: '二、起课依据',
        content: _formatSource(result),
        priority: 2,
      ),
      StructuredSection(
        key: 'chain',
        title: '三、三段顺推',
        content: _formatChain(result),
        priority: 3,
      ),
      StructuredSection(
        key: 'finalPosition',
        title: '四、最终落宫',
        content: _formatFinalPosition(result),
        priority: 4,
      ),
    ];
  }

  // --- formatters --------------------------------------------------------

  String _formatOverview(XiaoLiuRenResult result, String lunarDateText) {
    final buffer = StringBuffer();
    buffer.writeln(
      '- 起课：${_formatIsoDateTime(result.castTime)}（农历$lunarDateText）',
    );
    buffer.writeln('- 方式：${result.source.methodLabel}');
    buffer.writeln('- 盘式：${result.palaceMode.displayName}');
    buffer.writeln('- 四柱：${_formatPillars(result)}');
    buffer.writeln(
      '- 第一段：${result.source.firstLabel} ${result.source.firstNumber} -> ${result.monthPosition.name}',
    );
    buffer.writeln(
      '- 第二段：${result.source.secondLabel} ${result.source.secondNumber} -> ${result.dayPosition.name}',
    );
    buffer.writeln(
      '- 第三段：${result.source.thirdLabel} ${result.source.thirdNumber} -> ${result.hourPosition.name}',
    );
    buffer.writeln(
      '- 最终落宫：${result.finalPosition.name}（${result.finalPosition.fortune}）',
    );
    buffer.write('- 关键词：${result.finalPosition.keyword}');
    return buffer.toString();
  }

  String _formatSource(XiaoLiuRenResult result) {
    final source = result.source;
    final buffer = StringBuffer();
    buffer.writeln('- 规则：${source.rule}');
    buffer.writeln('- ${source.firstLabel}：${source.firstNumber}');
    buffer.writeln('- ${source.secondLabel}：${source.secondNumber}');
    buffer.writeln('- ${source.thirdLabel}：${source.thirdNumber}');
    if (source.hourZhi != null) {
      buffer.writeln('- 时支：${source.hourZhi}');
    }
    if (source.note != null) {
      buffer.write('- 说明：${source.note}');
    } else {
      // strip trailing newline
      return buffer.toString().trimRight();
    }
    return buffer.toString();
  }

  String _formatChain(XiaoLiuRenResult result) {
    final source = result.source;
    final buffer = StringBuffer();
    buffer.writeln(
      '- 第一段：${source.firstLabel} ${source.firstNumber} 从大安起 -> ${result.monthPosition.name}',
    );
    buffer.writeln(
      '- 第二段：${source.secondLabel} ${source.secondNumber} 从${result.monthPosition.name}推 -> ${result.dayPosition.name}',
    );
    buffer.write(
      '- 第三段：${source.thirdLabel} ${source.thirdNumber} 从${result.dayPosition.name}推 -> ${result.hourPosition.name}',
    );
    return buffer.toString();
  }

  String _formatFinalPosition(XiaoLiuRenResult result) {
    final pos = result.finalPosition;
    final buffer = StringBuffer();
    buffer.writeln('- 宫位：${pos.name}（${pos.fortune}）');
    buffer.writeln('- 关键词：${pos.keyword}');
    buffer.writeln('- 五行：${pos.wuXing}');
    buffer.writeln('- 方位：${pos.direction}');
    buffer.write('- 宫义：${pos.description}');
    return buffer.toString();
  }

  // --- helpers -----------------------------------------------------------

  String _formatPillars(XiaoLiuRenResult result) {
    final hourGanZhi = result.lunarInfo.hourGanZhi ?? '';
    return '${result.lunarInfo.yearGanZhi}年 '
        '${result.lunarInfo.monthGanZhi}月 '
        '${result.lunarInfo.riGanZhi}日 '
        '$hourGanZhi时';
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
