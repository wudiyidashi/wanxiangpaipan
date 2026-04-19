/// 梅花易数结构化输出格式化器
///
/// 严格对应 `docs/architecture/divination-systems/meihua.md §11` 的模板：
///
/// 1. 排盘总览
/// 2. 起卦依据
/// 3. 卦象结构
/// 4. 体用与五行
///
/// 占断不在结构化输出里给结论，交由 `AIAnalysisWidget` 负责。
/// 标题固定为 `【梅花易数完整结构化排盘】`。
library;

import 'package:lunar/lunar.dart';

import '../../../divination_systems/meihua/models/meihua_result.dart';
import '../../../domain/divination_system.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

class MeiHuaStructuredFormatter
    extends StructuredOutputFormatter<MeiHuaResult> {
  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  StructuredDivinationOutput format(MeiHuaResult result, {String? question}) {
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

  // --- rendering ---------------------------------------------------------

  @override
  String render(StructuredDivinationOutput output) {
    final buffer = StringBuffer();
    buffer.writeln('【梅花易数完整结构化排盘】');
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

  TemporalInfo _buildTemporalInfo(MeiHuaResult result, String lunarDateText) {
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
    MeiHuaResult result, {
    required String? question,
    required String lunarDateText,
  }) {
    return {
      'formatTitle': '梅花易数完整结构化排盘',
      'overview': {
        'castTime': _formatIsoDateTime(result.castTime),
        'lunarDate': lunarDateText,
        'question': question,
        'method': result.castMethod.id,
        'methodLabel': result.source.methodLabel,
        'pillars': _formatPillars(result),
        'benGua': result.benGua.name,
        'bianGua': result.bianGua.name,
        'huGua': result.huGua.name,
        'movingLine': result.movingLineLabel,
        'tiGua': result.tiGua.name,
        'yongGua': result.yongGua.name,
        'wuXingRelation': result.wuXingRelation,
      },
      'source': {
        'methodLabel': result.source.methodLabel,
        'upperNumber': result.source.upperNumber,
        'lowerNumber': result.source.lowerNumber,
        'movingLineNumber': result.source.movingLineNumber,
        'upperRawValue': result.source.upperRawValue,
        'lowerRawValue': result.source.lowerRawValue,
        'movingRawValue': result.source.movingRawValue,
        'yearBranch': result.source.yearBranch,
        'yearNumber': result.source.yearNumber,
        'monthNumber': result.source.monthNumber,
        'dayNumber': result.source.dayNumber,
        'hourBranch': result.source.hourBranch,
        'hourNumber': result.source.hourNumber,
        'upperInputNumber': result.source.upperInputNumber,
        'lowerInputNumber': result.source.lowerInputNumber,
        'manualUpperTrigram': result.source.manualUpperTrigram,
        'manualLowerTrigram': result.source.manualLowerTrigram,
        'note': result.source.note,
      },
      'hexagrams': {
        'ben': _hexagramMap(result.benGua),
        'bian': _hexagramMap(result.bianGua),
        'hu': _hexagramMap(result.huGua),
      },
      'bodyUse': {
        'ti': {
          'name': result.tiGua.name,
          'wuXing': result.tiGua.wuXing,
        },
        'yong': {
          'name': result.yongGua.name,
          'wuXing': result.yongGua.wuXing,
        },
        'rule': result.bodyUseRule,
        'relation': result.wuXingRelation,
      },
    };
  }

  Map<String, dynamic> _hexagramMap(MeiHuaHexagram hexagram) {
    return {
      'name': hexagram.name,
      'code': hexagram.code,
      'upperTrigram': hexagram.upperTrigram.name,
      'lowerTrigram': hexagram.lowerTrigram.name,
      'lines': hexagram.lines,
    };
  }

  List<StructuredSection> _buildSections(
    MeiHuaResult result, {
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
        title: '二、起卦依据',
        content: _formatSource(result),
        priority: 2,
      ),
      StructuredSection(
        key: 'structure',
        title: '三、卦象结构',
        content: _formatStructure(result),
        priority: 3,
      ),
      StructuredSection(
        key: 'bodyUse',
        title: '四、体用与五行',
        content: _formatBodyUse(result),
        priority: 4,
      ),
    ];
  }

  // --- formatters --------------------------------------------------------

  String _formatOverview(MeiHuaResult result, String lunarDateText) {
    final buffer = StringBuffer();
    buffer.writeln(
      '- 起卦：${_formatIsoDateTime(result.castTime)}（农历$lunarDateText）',
    );
    buffer.writeln('- 方式：${result.source.methodLabel}');
    buffer.writeln('- 四柱：${_formatPillars(result)}');
    buffer.writeln('- 本卦：${result.benGua.name}');
    buffer.writeln('- 变卦：${result.bianGua.name}');
    buffer.writeln('- 互卦：${result.huGua.name}');
    buffer.writeln('- 动爻：${result.movingLineLabel}');
    buffer.writeln('- 体卦：${result.tiGua.name}');
    buffer.writeln('- 用卦：${result.yongGua.name}');
    buffer.write('- 体用关系：${result.wuXingRelation}');
    return buffer.toString();
  }

  String _formatSource(MeiHuaResult result) {
    final source = result.source;
    final buffer = StringBuffer();

    switch (result.castMethod) {
      case CastMethod.time:
        buffer.writeln(
          '- 规则：年支数 + 月数 + 日数取上卦；年支数 + 月数 + 日数 + 时支数取下卦与动爻',
        );
        buffer.writeln(
          '- 年支：${source.yearBranch ?? '-'}，数${source.yearNumber ?? '-'}',
        );
        buffer.writeln('- 月数：${source.monthNumber ?? '-'}');
        buffer.writeln('- 日数：${source.dayNumber ?? '-'}');
        buffer.writeln(
          '- 时支：${source.hourBranch ?? '-'}，数${source.hourNumber ?? '-'}',
        );
        buffer.writeln(
          '- 上卦数：${source.upperNumber} -> ${result.benGua.upperTrigram.name}',
        );
        buffer.writeln(
          '- 下卦数：${source.lowerNumber} -> ${result.benGua.lowerTrigram.name}',
        );
        buffer.write(
          '- 动爻数：${source.movingLineNumber} -> ${result.movingLineLabel}',
        );
      case CastMethod.number:
        buffer.writeln(
          '- 规则：上数取上卦，下数取下卦，上数加下数取动爻',
        );
        buffer.writeln('- 上数：${source.upperInputNumber ?? '-'}');
        buffer.writeln('- 下数：${source.lowerInputNumber ?? '-'}');
        buffer.writeln(
          '- 上卦数：${source.upperInputNumber ?? '-'} % 8 = ${source.upperNumber} -> ${result.benGua.upperTrigram.name}',
        );
        buffer.writeln(
          '- 下卦数：${source.lowerInputNumber ?? '-'} % 8 = ${source.lowerNumber} -> ${result.benGua.lowerTrigram.name}',
        );
        buffer.write(
          '- 动爻数：${source.movingRawValue ?? '-'} % 6 = ${source.movingLineNumber} -> ${result.movingLineLabel}',
        );
      case CastMethod.manual:
        buffer.writeln('- 规则：用户直接指定上卦、下卦、动爻');
        buffer.writeln('- 上卦：${source.manualUpperTrigram ?? '-'}');
        buffer.writeln('- 下卦：${source.manualLowerTrigram ?? '-'}');
        buffer.writeln('- 动爻：${result.movingLineLabel}');
        buffer.write('- 来源：手动指定');
      default:
        buffer.write('- 方式：${source.methodLabel}');
    }

    return buffer.toString();
  }

  String _formatStructure(MeiHuaResult result) {
    final buffer = StringBuffer();
    buffer.writeln(_structureLine('本卦', result.benGua));
    buffer.writeln(_structureLine('变卦', result.bianGua));
    buffer.write(_structureLine('互卦', result.huGua));
    return buffer.toString();
  }

  String _structureLine(String label, MeiHuaHexagram hexagram) {
    return '- $label：上${hexagram.upperTrigram.name}'
        '下${hexagram.lowerTrigram.name}，${hexagram.name}';
  }

  String _formatBodyUse(MeiHuaResult result) {
    final benGua = result.benGua;
    final movingSide = result.movingLine <= 3 ? '下卦' : '上卦';
    final tiSide =
        result.tiGua.name == benGua.upperTrigram.name ? '上卦' : '下卦';
    final yongSide =
        result.yongGua.name == benGua.upperTrigram.name ? '上卦' : '下卦';

    final buffer = StringBuffer();
    buffer.writeln(
      '- 动爻落$movingSide，故$tiSide为体（${result.tiGua.name}），$yongSide为用（${result.yongGua.name}）',
    );
    buffer.writeln(
      '- 体卦：${result.tiGua.name}，${result.tiGua.wuXing}',
    );
    buffer.writeln(
      '- 用卦：${result.yongGua.name}，${result.yongGua.wuXing}',
    );
    buffer.write('- 关系：${result.wuXingRelation}');
    return buffer.toString();
  }

  // --- helpers -----------------------------------------------------------

  String _formatPillars(MeiHuaResult result) {
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
