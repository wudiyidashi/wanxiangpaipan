/// 奇门遁甲结构化输出格式化器。
///
/// 盘面来自 [QimenResult]，分析来自冻结的 v1 report/projection。这里仅做
/// 稳定排序和文本呈现，不重排九宫、不复制规则谓词，也不改写程序裁决。
library;

import '../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../divination_systems/qimen/models/qimen_result.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import '../../../domain/services/qimen/analysis/models/qimen_analysis_projection.dart';
import '../../../domain/services/qimen/analysis/models/qimen_ying_qi_models.dart';
import '../../../domain/services/qimen/analysis/qimen_analyzer.dart';
import '../structured_output.dart';
import '../structured_output_formatter.dart';

class QimenStructuredFormatter extends StructuredOutputFormatter<QimenResult> {
  static const List<int> palaceOrder = QimenResult.luoShuPalaceOrder;

  @override
  DivinationType get systemType => DivinationType.qiMen;

  @override
  StructuredDivinationOutput format(QimenResult result, {String? question}) {
    final report = QimenAnalyzer.analyze(result);
    final projection = QimenAnalysisProjection.fromReport(report);
    if (projection.status != QimenAnalysisStatus.complete) {
      final diagnostics = projection.diagnostics
          .map((diagnostic) => diagnostic.code)
          .join(', ');
      throw QimenAnalysisCompatibilityException(
        'Qimen AI formatting requires a complete projection; '
        'status=${projection.status.id}'
        '${diagnostics.isEmpty ? '' : '; diagnostics=$diagnostics'}',
      );
    }
    final palaces = _orderedPalaces(result);

    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: TemporalInfo(
        solarTime: result.castTime,
        yearGanZhi: result.temporalContext.yearGanZhi,
        monthGanZhi: result.temporalContext.monthGanZhi,
        dayGanZhi: result.temporalContext.dayGanZhi,
        hourGanZhi: result.temporalContext.hourGanZhi,
        kongWang: result.kongWangBranches,
        solarTerm: result.temporalContext.currentSolarTerm,
        yueJian: result.lunarInfo.yueJian,
      ),
      coreData: _buildCoreData(result, palaces, projection),
      sections: _buildSections(result, palaces, projection),
      userQuestion: question,
      summary: result.getSummary(),
    );
  }

  Map<String, dynamic> _buildCoreData(
    QimenResult result,
    List<QimenPalace> palaces,
    QimenAnalysisProjection projection,
  ) =>
      <String, dynamic>{
        'formatTitle': '奇门遁甲完整结构化排盘',
        'calculationBasis': <String, dynamic>{
          'panSchemaVersion': QimenResult.currentSchemaVersion,
          'analysisProjectionSchemaVersion': projection.projectionSchemaVersion,
          'analysisRuleSetId': projection.ruleSetId,
          'analysisRuleSetVersion': projection.ruleSetVersion,
          'castMethod': result.castMethod.id,
          'originalTime':
              result.temporalContext.originalTime.toUtc().toIso8601String(),
          'basisWallTime':
              result.temporalContext.basisWallTime.toIso8601String(),
          'effectivePanTime':
              result.temporalContext.effectivePanTime.toIso8601String(),
          'timeBasis': result.panParams.timeBasis.id,
          'sourceUtcOffsetMinutes':
              result.temporalContext.sourceUtcOffsetMinutes,
          'longitude': result.temporalContext.longitude,
          'totalCorrectionMinutes':
              result.temporalContext.totalCorrectionMinutes,
          'correctionAlgorithmVersion':
              result.temporalContext.correctionAlgorithmVersion,
          'dayBoundary': result.panParams.dayBoundary.id,
          'juMethod': result.juInfo.method.id,
          'dun': result.juInfo.dun.id,
          'juNumber': result.juInfo.juNumber,
          'yuan': result.juInfo.yuan.id,
          'solarTerm': result.juInfo.solarTerm,
          'effectiveSolarTerm': result.juInfo.effectiveSolarTerm,
          'hostingMode': result.panParams.hostingMode.id,
          'hiddenStemMode': result.panParams.hiddenStemMode.id,
          'questionCategory': result.panParams.questionCategory.id,
        },
        'palaces': palaces.map((palace) => palace.toJson()).toList(),
        'focusAndFacts': <String, dynamic>{
          'status': projection.status.id,
          'diagnostics':
              projection.diagnostics.map((value) => value.toJson()).toList(),
          'focuses': projection.focuses.map((value) => value.toJson()).toList(),
          'facts': projection.facts.map((value) => value.toJson()).toList(),
          'conflicts':
              projection.conflicts.map((value) => value.toJson()).toList(),
          'trace': projection.trace.map((value) => value.toJson()).toList(),
        },
        'verdict': projection.verdict.toJson(),
        'timing': <String, dynamic>{
          'candidates': projection.yingQiCandidates
              .map((value) => value.toJson())
              .toList(),
          'statement': '应期仅为程序给出的观察窗口，不保证事件发生或结论自动转吉。',
        },
        'sources': projection.sources.map((value) => value.toJson()).toList(),
        'policy': <String, dynamic>{
          'calculationOwner': projection.calculationOwner,
          'mayRecalculatePan': projection.mayRecalculatePan,
          'mayRecalculateAnalysis': projection.mayRecalculateAnalysis,
          'mayOverrideVerdict': projection.mayOverrideVerdict,
        },
      };

  List<StructuredSection> _buildSections(
    QimenResult result,
    List<QimenPalace> palaces,
    QimenAnalysisProjection projection,
  ) =>
      <StructuredSection>[
        StructuredSection(
          key: 'calculationBasis',
          title: '一、排盘口径',
          content: _formatBasis(result, projection),
          priority: 1,
        ),
        StructuredSection(
          key: 'palaces',
          title: '二、洛书九宫完整事实',
          content: palaces.map(_formatPalace).join('\n'),
          priority: 2,
        ),
        StructuredSection(
          key: 'focusAndFacts',
          title: '三、焦点与规则事实',
          content: _formatFocusAndFacts(projection),
          priority: 3,
        ),
        StructuredSection(
          key: 'verdict',
          title: '四、程序裁决与冲突',
          content: _formatVerdict(projection),
          priority: 4,
        ),
        StructuredSection(
          key: 'timing',
          title: '五、应期观察窗口',
          content: _formatTiming(projection.yingQiCandidates),
          priority: 5,
        ),
        StructuredSection(
          key: 'sourcesAndPolicy',
          title: '六、来源、版本与使用策略',
          content: _formatSourcesAndPolicy(projection),
          priority: 6,
        ),
      ];

  List<QimenPalace> _orderedPalaces(QimenResult result) {
    final byNumber = <int, QimenPalace>{
      for (final palace in result.palaces) palace.number: palace,
    };
    return palaceOrder.map((number) => byNumber[number]!).toList();
  }

  String _formatBasis(
    QimenResult result,
    QimenAnalysisProjection projection,
  ) {
    final temporal = result.temporalContext;
    final params = result.panParams;
    final ju = result.juInfo;
    return <String>[
      '- 四柱：${temporal.yearGanZhi}年 ${temporal.monthGanZhi}月 '
          '${temporal.dayGanZhi}日 ${temporal.hourGanZhi}时',
      '- 时间基准：${params.timeBasis.id}；来源时区 '
          '${temporal.sourceUtcOffsetMinutes} 分钟；校正 '
          '${_number(temporal.totalCorrectionMinutes)} 分钟 '
          '(${temporal.correctionAlgorithmVersion})',
      '- 换日：${params.dayBoundary.id}；定局：${ju.method.id}；'
          '${ju.dun.label}遁${ju.juNumber}局；${ju.yuan.label}',
      '- 节气：${ju.solarTerm}；有效节气：${ju.effectiveSolarTerm}；'
          '符头：${ju.symbolHead ?? '无'}',
      '- 寄宫：${params.hostingMode.id}；暗干：${params.hiddenStemMode.id}；'
          '问事：${params.questionCategory.id}',
      '- 值符：${result.zhiFuStar}落${result.zhiFuPalace}宫；'
          '值使：${result.zhiShiDoor}落${result.zhiShiPalace}宫；'
          '旬首${result.xunShou}遁${result.xunHiddenStem}',
      '- pan schema ${QimenResult.currentSchemaVersion}；analysis '
          '${projection.ruleSetId}/${projection.ruleSetVersion}；'
          'status ${projection.status.id}',
    ].join('\n');
  }

  String _formatPalace(QimenPalace palace) {
    final hosted = <String>[
      if (palace.hostedEarthStem != null) '寄地${palace.hostedEarthStem}',
      if (palace.hostedHeavenStem != null) '寄天${palace.hostedHeavenStem}',
      if (palace.hostedStar != null) '寄星${palace.hostedStar}',
    ];
    final states = <String>[
      if (palace.voidBranches.isNotEmpty) '空亡${palace.voidBranches.join()}',
      if (palace.isHorse) '驿马',
      ...palace.marks.where(
        (mark) =>
            !(mark == '空亡' && palace.voidBranches.isNotEmpty) &&
            !(mark == '驿马' && palace.isHorse),
      ),
    ];
    return '- ${palace.name}（${palace.direction}/${palace.element}）：'
        '地${palace.earthStem}、天${palace.heavenStem}、${palace.star}、'
        '${palace.door ?? '无门'}、${palace.deity ?? '无神'}、'
        '暗干${palace.hiddenStem ?? '无'}'
        '${hosted.isEmpty ? '' : '；${hosted.join('、')}'}'
        '${states.isEmpty ? '' : '；${states.join('、')}'}';
  }

  String _formatFocusAndFacts(QimenAnalysisProjection projection) {
    final buffer = StringBuffer();
    if (projection.diagnostics.isNotEmpty) {
      for (final diagnostic in projection.diagnostics) {
        buffer.writeln(
          '- 诊断 ${diagnostic.code} @ ${diagnostic.path}：'
          '${diagnostic.message}',
        );
      }
    }
    for (final focus in projection.focuses) {
      buffer.writeln(
        '- 焦点 ${focus.roleId}：${focus.indicatorValue}落'
        '${focus.palaceNumber}宫（原宫${focus.originPalaceNumber}，'
        '${focus.priority.id}${focus.isHosted ? '，寄宫' : ''}）'
        '；${focus.reason}',
      );
    }
    for (final fact in projection.facts) {
      buffer.writeln(
        '- 事实 ${fact.occurrenceId} / ${fact.ruleId}：'
        '${qimenPolarityId(fact.polarity)}，${fact.reason}；宫位'
        '${fact.relatedPalaceNumbers.join('、')}；焦点'
        '${fact.relatedFocusRoleIds.isEmpty ? '全局' : fact.relatedFocusRoleIds.join('、')}；'
        '来源 ${fact.sourceIds.join('、')}',
      );
    }
    return buffer.toString().trimRight();
  }

  String _formatVerdict(QimenAnalysisProjection projection) {
    final verdict = projection.verdict;
    final buffer = StringBuffer()
      ..writeln('趋势：${verdict.judgment.trend.name}')
      ..writeln('裁决行：${verdict.matchedDecisionRowId}')
      ..writeln('摘要：${verdict.judgment.summary}');
    for (final condition in verdict.conditionLinks) {
      buffer.writeln(
        '- 条件 ${condition.conditionId}：${condition.condition.label}；'
        '${condition.condition.reason}；解除触发 '
        '${condition.releaseTriggerKind}=${condition.releaseTriggerValue} '
        '(${condition.releaseScale.name})',
      );
    }
    for (final conflict in projection.conflicts) {
      buffer.writeln(
        '- 冲突 ${conflict.resolutionId} / ${conflict.policyId}：'
        '${conflict.reason}；胜出 ${conflict.winnerOccurrenceId ?? '未决'}；'
        '压制 ${conflict.suppressedOccurrenceIds.isEmpty ? '无' : conflict.suppressedOccurrenceIds.join('、')}',
      );
    }
    return buffer.toString().trimRight();
  }

  String _formatTiming(List<QimenYingQiCandidate> candidates) {
    final buffer = StringBuffer(
      '应期是程序给出的观察窗口，不保证事件发生或结论自动转吉。',
    );
    for (final candidate in candidates) {
      buffer.write(
        '\n- ${candidate.scale.name}尺度 '
        '${candidate.triggerKind.id}=${candidate.triggerValue}：'
        '${candidate.reason}；目标 ${candidate.targetFocusRoleId ?? '全局'}；'
        '来源 ${candidate.sourceIds.join('、')}',
      );
    }
    return buffer.toString();
  }

  String _formatSourcesAndPolicy(QimenAnalysisProjection projection) {
    final buffer = StringBuffer()
      ..writeln('规则：${projection.ruleSetId}/${projection.ruleSetVersion}');
    for (final source in projection.sources) {
      buffer.writeln(
        '- ${source.sourceId}：${source.title}，${source.editionOrRevision}，'
        '${source.locator}；${source.claimSummary}',
      );
    }
    buffer
      ..writeln('策略：calculationOwner=${projection.calculationOwner}')
      ..writeln('mayRecalculatePan=${projection.mayRecalculatePan}')
      ..writeln(
        'mayRecalculateAnalysis=${projection.mayRecalculateAnalysis}',
      )
      ..write('mayOverrideVerdict=${projection.mayOverrideVerdict}');
    return buffer.toString().trimRight();
  }

  String _number(double value) => value.toStringAsFixed(2);

  @override
  String render(StructuredDivinationOutput output) {
    final sections = List<StructuredSection>.from(output.sections)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final buffer = StringBuffer('【奇门遁甲完整结构化排盘】\n');
    for (final section in sections) {
      buffer
        ..writeln()
        ..writeln(section.title)
        ..writeln(section.content.trimRight());
    }
    return buffer.toString().trimRight();
  }
}
