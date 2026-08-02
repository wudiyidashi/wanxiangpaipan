/// 六爻结构化输出格式化器
///
/// 将六爻排盘结果转换为结构化输出格式，用于 LLM 分析。
library;

import '../../../domain/divination_system.dart';
import '../../../divination_systems/liuyao/liuyao_result.dart';
import '../../../divination_systems/liuyao/models/gua.dart';
import '../../../divination_systems/liuyao/models/yao.dart';
import '../../../domain/services/liuyao/analysis/liuyao_analyzer.dart';
import '../../../domain/services/liuyao/analysis/models/liuyao_analysis_projection.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

/// 六爻结构化输出格式化器
class LiuYaoStructuredFormatter
    extends StructuredOutputFormatter<LiuYaoResult> {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  StructuredDivinationOutput format(LiuYaoResult result, {String? question}) {
    final report = LiuYaoAnalyzer.analyze(
      result.mainGua,
      result.changingGua,
      result.lunarInfo,
      yongShenPosition: result.yongShenPosition,
      yongShenIsFuShen: result.yongShenIsFuShen,
    );
    final projection = LiuYaoAnalysisProjection.fromReport(
      result: result,
      report: report,
    );
    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: _buildTemporalInfo(result),
      coreData: _buildCoreData(result, projection),
      sections: _buildSections(result, projection),
      userQuestion: question,
      summary: _buildSummary(result),
      analysisContract: AnalysisContractMetadata(
        analysisSchemaVersion: projection.analysisSchemaVersion.toString(),
        projectionSchemaVersion: projection.projectionSchemaVersion.toString(),
        ruleSetId: projection.ruleSetId,
        ruleSetVersion: projection.ruleSetVersion,
        sourceCatalogVersion: projection.sourceCatalogVersion,
      ),
    );
  }

  TemporalInfo _buildTemporalInfo(LiuYaoResult result) {
    final lunar = result.lunarInfo;
    return TemporalInfo(
      solarTime: result.castTime,
      yearGanZhi: lunar.yearGanZhi,
      monthGanZhi: lunar.monthGanZhi,
      dayGanZhi: lunar.riGanZhi,
      hourGanZhi: lunar.hourGanZhi,
      kongWang: lunar.kongWang,
      solarTerm: lunar.solarTerm,
      yueJian: lunar.yueJian,
    );
  }

  Map<String, dynamic> _buildCoreData(
    LiuYaoResult result,
    LiuYaoAnalysisProjection projection,
  ) {
    return {
      'mainGuaName': result.mainGua.name,
      'mainGuaPalace': result.mainGua.baGong.name,
      'changingGuaName': result.changingGua?.name,
      'hasChangingGua': result.hasChangingGua,
      'hasMovingYao': result.hasMovingYao,
      'movingYaoCount': result.movingYaos.length,
      'movingYaoPositions': result.movingYaos.map((y) => y.position).toList(),
      'specialType': result.mainGua.specialType.name,
      'seYaoPosition': result.mainGua.seYaoPosition,
      'yingYaoPosition': result.mainGua.yingYaoPosition,
      'liuShen': result.liuShen,
      'analysisSchemaVersion': projection.analysisSchemaVersion,
      'projectionSchemaVersion': projection.projectionSchemaVersion,
      'analysisRuleSetId': projection.ruleSetId,
      'analysisRuleSetVersion': projection.ruleSetVersion,
      'sourceCatalogVersion': projection.sourceCatalogVersion,
      'useSpiritMode': projection.useSpirit.toJson()['mode'],
    };
  }

  List<StructuredSection> _buildSections(
    LiuYaoResult result,
    LiuYaoAnalysisProjection projection,
  ) {
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
      content: _formatAnalysis(projection),
      priority: 7,
      metadata: <String, dynamic>{'projection': projection.toJson()},
    ));

    return sections;
  }

  /// 渲染同一份经验证 projection，不在 AI 边界重算领域规则。
  String _formatAnalysis(LiuYaoAnalysisProjection projection) {
    final buffer = StringBuffer();
    buffer
      ..writeln('计算所有权: program；本段只解释程序事实，不重算或覆盖。')
      ..writeln('版本: analysis schema ${projection.analysisSchemaVersion}；'
          '${projection.ruleSetId}/${projection.ruleSetVersion}；'
          'projection ${projection.projectionSchemaVersion}；'
          'sources ${projection.sourceCatalogVersion}')
      ..writeln('取用模式: ${projection.useSpirit.toJson()['mode']}');
    if (projection.useSpirit.mode == LiuYaoUseSpiritMode.unselected) {
      buffer.writeln('用户未选用神：只可提供明确标注的候选建议；程序裁决、条件和应期均为空。');
    } else {
      buffer.writeln('用户指定用神: '
          '${_positionName(projection.useSpirit.position!)}爻'
          '${projection.useSpirit.mode == LiuYaoUseSpiritMode.selectedHidden ? '（伏神取用）' : ''}；'
          '不得重选。');
    }
    if (projection.roles.isNotEmpty) {
      buffer.writeln('角色清单:');
      for (final role in projection.roles) {
        buffer.writeln('- ${role.role.name} ${role.actor.actorId} '
            '${role.actor.branch}；${role.reason}'
            '${role.selected ? '；用户选定' : ''}');
      }
    }
    if (projection.selectedUseSpiritFacts.isNotEmpty) {
      buffer.writeln('用神自身事实:');
      for (final fact in projection.selectedUseSpiritFacts) {
        buffer.writeln('- ${fact.ruleId} ${fact.term}: ${fact.reason}；'
            '${fact.active ? '生效' : '已压制'}');
      }
    }
    if (projection.directedEffects.isNotEmpty) {
      buffer.writeln('有向作用:');
      for (final effect in projection.directedEffects) {
        buffer.writeln('- ${effect.occurrenceId} ${effect.ruleId}: '
            '${effect.fromActor.actorId} -> ${effect.toActor.actorId}；'
            '${effect.effect.name}；${effect.status.name}；'
            'path=${effect.pathActorIds.join(' -> ')}');
      }
    }
    final verdict = projection.verdict;
    if (verdict != null) {
      buffer
        ..writeln('程序四值: ${verdict.trend.name}')
        ..writeln('细化语气: ${verdict.nuance ?? '无'}')
        ..writeln('命中裁决行: ${verdict.matchedDecisionRowId}')
        ..writeln('裁决摘要: ${verdict.summary}');
    }
    if (projection.factors.isNotEmpty) {
      buffer.writeln('全部裁决因素（程序顺序）:');
      for (final factor in projection.factors) {
        buffer.writeln('- ${factor.factorId} ${factor.ruleId} '
            '${factor.effect.name}: ${factor.reason}；'
            'sources=${factor.sourceIds.join(',')}');
      }
    }
    if (projection.conditions.isNotEmpty) {
      buffer.writeln('全部未决条件:');
      for (final condition in projection.conditions) {
        buffer.writeln('- ${condition.conditionId} '
            '${condition.conditionRuleId} ${condition.label}: '
            '${condition.reason}；hasRescue=${condition.hasRescue}；'
            'status=${condition.status}');
      }
    }
    if (projection.timingCandidates.isNotEmpty) {
      buffer.writeln('应期观察窗（不保证事件发生或自动转吉）:');
      for (final timing in projection.timingCandidates) {
        buffer.writeln('- ${timing.timingId} ${timing.label}: '
            '${timing.scale.name}尺度；${timing.reason}；'
            'conditions=${timing.upstreamConditionIds.join(',')}');
      }
    }
    if (projection.sources.isNotEmpty) {
      buffer.writeln('本盘实际来源闭包:');
      for (final source in projection.sources) {
        buffer.writeln('- ${source.sourceId} ${source.title} '
            '(${source.adoptionStatus})');
        for (final reference in source.references) {
          final quote = reference.referenceKind == 'exactQuote'
              ? '；页级核验短引“${reference.quote}”'
              : '';
          buffer.writeln('  - ${reference.ruleId}: '
              '${reference.referenceKind}/${reference.evidenceLevel}；'
              '${reference.locator}$quote；${reference.adoptionNote}');
        }
      }
    }
    buffer
      ..writeln('[LIUYAO_CANONICAL_PROJECTION]')
      ..writeln(projection.toCanonicalJson())
      ..writeln('[/LIUYAO_CANONICAL_PROJECTION]');
    return buffer.toString().trimRight();
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
