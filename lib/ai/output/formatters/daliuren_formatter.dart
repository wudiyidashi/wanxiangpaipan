/// 大六壬结构化输出格式化器
///
/// 将大六壬排盘结果转换为结构化输出格式，用于 LLM 分析。
library;

import '../../../domain/divination_system.dart';
import '../../../divination_systems/daliuren/models/daliuren_result.dart';
import '../../../divination_systems/daliuren/models/chuan.dart';
import '../../../divination_systems/daliuren/daliuren_constants.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

/// 大六壬结构化输出格式化器
class DaLiuRenStructuredFormatter
    extends StructuredOutputFormatter<DaLiuRenResult> {
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  @override
  StructuredDivinationOutput format(DaLiuRenResult result, {String? question}) {
    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: _buildTemporalInfo(result),
      coreData: _buildCoreData(result),
      sections: _buildSections(result),
      userQuestion: question,
      summary: _buildSummary(result),
    );
  }

  TemporalInfo _buildTemporalInfo(DaLiuRenResult result) {
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

  Map<String, dynamic> _buildCoreData(DaLiuRenResult result) {
    return {
      'keType': result.keTypeName,
      'isFuYin': result.isFuYin,
      'isFanYin': result.isFanYin,
      'yueJiang': result.yueJiang,
      'shiZhi': result.shiZhi,
      'chuChuan': result.chuChuan,
      'zhongChuan': result.zhongChuan,
      'moChuan': result.moChuan,
      'jiShenCount': result.jiShenCount,
      'xiongShenCount': result.xiongShenCount,
    };
  }

  List<StructuredSection> _buildSections(DaLiuRenResult result) {
    final sections = <StructuredSection>[];

    // 基本信息段落
    sections.add(StructuredSection(
      key: 'basicInfo',
      title: '基本信息',
      content: _formatBasicInfo(result),
      priority: 1,
    ));

    // 天盘段落
    sections.add(StructuredSection(
      key: 'tianPan',
      title: '天盘',
      content: _formatTianPan(result),
      priority: 2,
    ));

    // 四课段落
    sections.add(StructuredSection(
      key: 'siKe',
      title: '四课',
      content: _formatSiKe(result),
      priority: 3,
    ));

    // 三传段落
    sections.add(StructuredSection(
      key: 'sanChuan',
      title: '三传',
      content: _formatSanChuan(result),
      priority: 4,
      metadata: {
        'keType': result.keTypeName,
        'isFuYin': result.isFuYin,
        'isFanYin': result.isFanYin,
      },
    ));

    // 十二神将段落
    sections.add(StructuredSection(
      key: 'shenJiang',
      title: '十二神将',
      content: _formatShenJiang(result),
      priority: 5,
    ));

    // 神煞段落
    sections.add(StructuredSection(
      key: 'shenSha',
      title: '神煞',
      content: _formatShenSha(result),
      priority: 6,
    ));

    return sections;
  }

  String _buildSummary(DaLiuRenResult result) {
    final buffer = StringBuffer();
    buffer.write('${result.keTypeName}课');
    if (result.isFuYin) {
      buffer.write('（伏吟）');
    } else if (result.isFanYin) {
      buffer.write('（反吟）');
    }
    buffer.write(' · 初传${result.chuChuan}');
    return buffer.toString();
  }

  String _formatBasicInfo(DaLiuRenResult result) {
    final buffer = StringBuffer();
    buffer.writeln('课体: ${result.keTypeName}课');
    buffer.writeln('日干支: ${result.lunarInfo.riGanZhi}');
    buffer.writeln('月建: ${result.lunarInfo.yueJian}');
    buffer.writeln('时支: ${result.shiZhi}');
    buffer.writeln('空亡: ${result.lunarInfo.kongWang.join("、")}');
    return buffer.toString();
  }

  String _formatTianPan(DaLiuRenResult result) {
    final buffer = StringBuffer();
    buffer.writeln(
        '月将: ${result.tianPan.yueJiang}（${result.tianPan.yueJiangName}）');
    buffer.writeln('描述: ${result.tianPan.yueJiangDescription}');
    buffer.writeln();
    buffer.writeln('天盘排列（月将加时支）:');

    // 显示天盘映射
    final diZhi = DaLiuRenConstants.diZhi;
    for (final zhi in diZhi) {
      final tianPanZhi = result.tianPan.tianPanMap[zhi] ?? zhi;
      buffer.writeln('  $zhi宫: $tianPanZhi');
    }

    return buffer.toString();
  }

  String _formatSiKe(DaLiuRenResult result) {
    final buffer = StringBuffer();

    for (final ke in result.siKe.allKe) {
      buffer.write('${ke.keName}: ${ke.shangShen}/${ke.xiaShen}');
      if (ke.wuXingRelation != null) {
        buffer.write(' (${ke.wuXingRelation})');
      }
      buffer.writeln();
    }

    buffer.writeln();
    if (result.siKe.hasZeiKe) {
      buffer.writeln(
          '贼克: ${result.siKe.zeiKeList.map((k) => k.keName).join("、")}');
    }
    if (result.siKe.hasBiYong) {
      buffer.writeln(
          '比用: ${result.siKe.biYongList.map((k) => k.keName).join("、")}');
    }

    return buffer.toString();
  }

  String _formatSanChuan(DaLiuRenResult result) {
    final buffer = StringBuffer();

    buffer.writeln('课体: ${result.keTypeName}');
    if (result.sanChuan.keTypeExplanation != null) {
      buffer.writeln('说明: ${result.sanChuan.keTypeExplanation}');
    }
    buffer.writeln();

    buffer.writeln('初传: ${_formatChuan(result.sanChuan.chuChuan)}');
    buffer.writeln('中传: ${_formatChuan(result.sanChuan.zhongChuan)}');
    buffer.writeln('末传: ${_formatChuan(result.sanChuan.moChuan)}');

    return buffer.toString();
  }

  String _formatChuan(Chuan chuan) {
    final buffer = StringBuffer();
    buffer.write('${chuan.diZhi}（${chuan.liuQin}）');
    buffer.write(' ${chuan.wuXing}');
    buffer.write(' 乘${chuan.chengShen.name}');
    if (chuan.isKongWang) {
      buffer.write(' [空亡]');
    }
    return buffer.toString();
  }

  String _formatShenJiang(DaLiuRenResult result) {
    final buffer = StringBuffer();

    buffer.writeln('贵人: ${result.shenJiangConfig.guiRenPosition}');
    buffer.writeln('类型: ${result.shenJiangConfig.guiRenTypeDescription}');
    buffer.writeln('布神: ${result.shenJiangConfig.directionDescription}');
    buffer.writeln();

    buffer.writeln('十二神将配置:');
    for (final pos in result.shenJiangConfig.positions) {
      buffer.writeln(
          '  ${pos.diZhi}宫: ${pos.shenJiang.name}（天盘${pos.tianPanZhi}）');
    }

    return buffer.toString();
  }

  String _formatShenSha(DaLiuRenResult result) {
    final buffer = StringBuffer();

    if (result.shenShaList.jiShen.isNotEmpty) {
      buffer.writeln('吉神（${result.jiShenCount}个）:');
      for (final shenSha in result.shenShaList.jiShen) {
        buffer.writeln('  ${shenSha.displayText}');
        buffer.writeln('    ${shenSha.description}');
      }
      buffer.writeln();
    }

    if (result.shenShaList.xiongShen.isNotEmpty) {
      buffer.writeln('凶神（${result.xiongShenCount}个）:');
      for (final shenSha in result.shenShaList.xiongShen) {
        buffer.writeln('  ${shenSha.displayText}');
        buffer.writeln('    ${shenSha.description}');
      }
      buffer.writeln();
    }

    if (result.shenShaList.zhongShen.isNotEmpty) {
      buffer.writeln('中性神煞:');
      for (final shenSha in result.shenShaList.zhongShen) {
        buffer.writeln('  ${shenSha.displayText}');
        buffer.writeln('    ${shenSha.description}');
      }
    }

    return buffer.toString();
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
