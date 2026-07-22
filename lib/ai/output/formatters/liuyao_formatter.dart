/// 六爻结构化输出格式化器
///
/// 将六爻排盘结果转换为结构化输出格式，用于 LLM 分析。
library;

import '../../../domain/divination_system.dart';
import '../../../divination_systems/liuyao/liuyao_result.dart';
import '../../../divination_systems/liuyao/models/gua.dart';
import '../../../divination_systems/liuyao/models/yao.dart';
import '../../../domain/services/liuyao/analysis/liuyao_analyzer.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

/// 六爻结构化输出格式化器
class LiuYaoStructuredFormatter
    extends StructuredOutputFormatter<LiuYaoResult> {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  StructuredDivinationOutput format(LiuYaoResult result, {String? question}) {
    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: _buildTemporalInfo(result),
      coreData: _buildCoreData(result),
      sections: _buildSections(result),
      userQuestion: question,
      summary: _buildSummary(result),
    );
  }

  TemporalInfo _buildTemporalInfo(LiuYaoResult result) {
    final lunar = result.lunarInfo;
    return TemporalInfo(
      solarTime: result.castTime,
      yearGanZhi: lunar.yearGanZhi,
      monthGanZhi: lunar.monthGanZhi,
      dayGanZhi: lunar.riGanZhi,
      kongWang: lunar.kongWang,
      solarTerm: lunar.solarTerm,
      yueJian: lunar.yueJian,
    );
  }

  Map<String, dynamic> _buildCoreData(LiuYaoResult result) {
    return {
      'mainGuaName': result.mainGua.name,
      'mainGuaPalace': result.mainGua.baGong.name,
      'changingGuaName': result.changingGua?.name,
      'hasMovingYao': result.hasMovingYao,
      'movingYaoCount': result.movingYaos.length,
      'movingYaoPositions': result.movingYaos.map((y) => y.position).toList(),
      'specialType': result.mainGua.specialType.name,
      'seYaoPosition': result.mainGua.seYaoPosition,
      'yingYaoPosition': result.mainGua.yingYaoPosition,
      'liuShen': result.liuShen,
    };
  }

  List<StructuredSection> _buildSections(LiuYaoResult result) {
    final sections = <StructuredSection>[];

    // 本卦段落
    sections.add(StructuredSection(
      key: 'mainGua',
      title: '本卦',
      content: _formatGua(result.mainGua, result.liuShen, showLiuShen: true),
      priority: 1,
      metadata: {
        'name': result.mainGua.name,
        'palace': result.mainGua.baGong.name,
        'specialType': result.mainGua.specialType.name,
      },
    ));

    // 变卦段落（如有）
    if (result.hasChangingGua) {
      sections.add(StructuredSection(
        key: 'changingGua',
        title: '变卦',
        content: _formatGua(result.changingGua!, null, showLiuShen: false),
        priority: 2,
        metadata: {'name': result.changingGua!.name},
      ));
    }

    // 动爻分析段落
    if (result.hasMovingYao) {
      sections.add(StructuredSection(
        key: 'movingYaos',
        title: '动爻',
        content: _formatMovingYaos(result),
        priority: 3,
      ));
    }

    // 世应关系段落
    sections.add(StructuredSection(
      key: 'seYingRelation',
      title: '世应',
      content: _formatSeYingRelation(result),
      priority: 4,
    ));

    // 六神段落
    sections.add(StructuredSection(
      key: 'liuShen',
      title: '六神',
      content: _formatLiuShen(result),
      priority: 5,
    ));

    // 空亡信息
    sections.add(StructuredSection(
      key: 'kongWang',
      title: '空亡',
      content: _formatKongWang(result),
      priority: 6,
    ));

    // 客观规则分析（旺衰/空破/合冲/动变/用神链/应期候选）
    sections.add(StructuredSection(
      key: 'analysis',
      title: '断卦分析（规则标注）',
      content: _formatAnalysis(result),
      priority: 7,
    ));

    return sections;
  }

  /// 将 LiuYaoAnalyzer 的客观分析报告渲染为提示词文本
  String _formatAnalysis(LiuYaoResult result) {
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: result.yongShenPosition,
      yongShenIsFuShen: result.yongShenIsFuShen,
    );

    final buffer = StringBuffer();
    buffer.writeln(
      '以下状态由程序按既定规则标注；应期是条件候选，不可据此单独断定成败：',
    );

    if (report.guaTags.isNotEmpty) {
      buffer.writeln('卦象: ${report.guaTags.map((t) => t.term).join('、')}');
    }

    final positions = report.yaoTags.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final position in positions) {
      final yao = result.mainGua.yaos[position - 1];
      final tags = report.yaoTags[position]!
          .map((t) => '${t.term}(${t.reason})')
          .join('、');
      buffer.writeln(
          '${_positionName(position)}爻${yao.liuQin.name}${yao.branch}: $tags');
    }

    final chain = report.yongShen;
    if (chain == null) {
      buffer.writeln('用户未指定用神：请先根据所占之事建议合适的用神，再依上述分析解读。');
    } else {
      buffer.writeln('用户指定用神: ${_positionName(chain.position)}爻'
          '${chain.isFuShen ? '（伏神取用）' : ''}');
      if (report.yingQi != null && report.yingQi!.isNotEmpty) {
        buffer.writeln('应期候选: ${report.yingQi!.map((c) => c.label).join('、')}');
      }
      if (report.verdictSummary != null) {
        buffer.writeln('用神状态摘要: ${report.verdictSummary}');
      }
    }

    return buffer.toString();
  }

  String _buildSummary(LiuYaoResult result) {
    final buffer = StringBuffer();
    buffer.write('${result.mainGua.name}');
    if (result.mainGua.specialType != GuaSpecialType.none) {
      buffer.write('(${result.mainGua.specialType.name})');
    }
    if (result.hasChangingGua) {
      buffer.write(' 变 ${result.changingGua!.name}');
    }
    return buffer.toString();
  }

  String _formatGua(Gua gua, List<String>? liuShen,
      {required bool showLiuShen}) {
    final buffer = StringBuffer();
    buffer.writeln('${gua.name} (${gua.baGong.name})');
    if (gua.specialType != GuaSpecialType.none) {
      buffer.writeln('卦性: ${gua.specialType.name}');
    }
    buffer.writeln();

    // 爻位表格（从上到下，六爻到初爻）
    for (int i = 5; i >= 0; i--) {
      final yao = gua.yaos[i];
      final liuShenValue = (showLiuShen && liuShen != null) ? liuShen[i] : null;
      buffer.write(_formatYaoLine(yao, liuShenValue));
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _formatYaoLine(Yao yao, String? liuShen) {
    final buffer = StringBuffer();
    final position = _positionName(yao.position);
    final yaoSymbol = yao.isYang ? '━━━━━' : '━━ ━━';
    final moving = yao.isMoving ? '○' : '  ';
    final seYing = yao.isSeYao ? '世' : (yao.isYingYao ? '应' : '  ');

    buffer.write('$position $yaoSymbol $moving ');
    buffer.write('${yao.liuQin.name}${yao.branch}');
    buffer.write(' ${yao.wuXing.name}');
    buffer.write(' $seYing');
    if (liuShen != null && liuShen.isNotEmpty) {
      buffer.write(' $liuShen');
    }

    return buffer.toString();
  }

  String _formatMovingYaos(LiuYaoResult result) {
    final buffer = StringBuffer();
    for (final yao in result.movingYaos) {
      final changed = result.changingGua!.yaos[yao.position - 1];
      buffer.writeln(
        '${_positionName(yao.position)}爻动: '
        '${yao.liuQin.name}${yao.stem}${yao.branch}(${yao.wuXing.name}) '
        '→ ${changed.liuQin.name}${changed.stem}${changed.branch}'
        '(${changed.wuXing.name})',
      );
    }
    return buffer.toString();
  }

  String _formatSeYingRelation(LiuYaoResult result) {
    final se = result.seYao;
    final ying = result.yingYao;
    final buffer = StringBuffer();
    buffer.writeln(
      '世爻: ${_positionName(se.position)}爻 '
      '${se.liuQin.name}${se.branch}(${se.wuXing.name})',
    );
    buffer.writeln(
      '应爻: ${_positionName(ying.position)}爻 '
      '${ying.liuQin.name}${ying.branch}(${ying.wuXing.name})',
    );
    return buffer.toString();
  }

  String _formatLiuShen(LiuYaoResult result) {
    final buffer = StringBuffer();
    final names = ['初', '二', '三', '四', '五', '上'];
    for (int i = 5; i >= 0; i--) {
      buffer.writeln('${names[i]}爻: ${result.liuShen[i]}');
    }
    return buffer.toString();
  }

  String _formatKongWang(LiuYaoResult result) {
    final kongWang = result.lunarInfo.kongWang;
    final buffer = StringBuffer();
    buffer.writeln('空亡: ${kongWang.join("、")}');

    // 检查哪些爻空亡
    final kongYaos = <String>[];
    for (final yao in result.mainGua.yaos) {
      if (kongWang.contains(yao.branch)) {
        kongYaos.add('${_positionName(yao.position)}爻(${yao.branch})');
      }
    }
    if (kongYaos.isNotEmpty) {
      buffer.writeln('空亡爻: ${kongYaos.join("、")}');
    } else {
      buffer.writeln('本卦无空亡爻');
    }

    return buffer.toString();
  }

  String _positionName(int position) {
    const names = ['初', '二', '三', '四', '五', '上'];
    return names[position - 1];
  }

  @override
  String render(StructuredDivinationOutput output) {
    final buffer = StringBuffer();

    // 时间信息
    buffer.writeln(renderTemporalInfo(output.temporal));
    buffer.writeln();

    // 摘要
    if (output.summary != null) {
      buffer.writeln('【摘要】');
      buffer.writeln(output.summary);
      buffer.writeln();
    }

    // 各段落（按优先级排序）
    final sortedSections = List<StructuredSection>.from(output.sections)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final section in sortedSections) {
      buffer.writeln('【${section.title}】');
      buffer.writeln(section.content);
    }

    return buffer.toString();
  }
}
