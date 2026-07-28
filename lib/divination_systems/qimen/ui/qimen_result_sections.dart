import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import '../../../domain/services/qimen/analysis/models/qimen_analysis_projection.dart';
import '../../../domain/services/qimen/analysis/models/qimen_ying_qi_models.dart';
import '../../../domain/services/shared/analysis/models/polarity.dart';
import '../../../domain/services/shared/analysis/models/verdict_models.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../models/qimen_enums.dart';
import '../models/qimen_result.dart';
import 'widgets/qimen_nine_palace_grid.dart';
import 'widgets/qimen_palace_detail_sheet.dart';

class QimenBasisSection extends StatelessWidget {
  const QimenBasisSection({
    super.key,
    required this.result,
    required this.question,
  });

  final QimenResult result;
  final String question;

  @override
  Widget build(BuildContext context) {
    final temporal = result.temporalContext;
    final params = result.panParams;
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '时间与排盘口径'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          QimenInfoRow('占问', question.isEmpty ? '未设置' : question),
          QimenInfoRow(
            '四柱',
            '${temporal.yearGanZhi}年  ${temporal.monthGanZhi}月  '
                '${temporal.dayGanZhi}日  ${temporal.hourGanZhi}时',
          ),
          QimenInfoRow('节气', temporal.currentSolarTerm),
          QimenInfoRow('时间基准', _timeBasisLabel(params.timeBasis)),
          QimenInfoRow(
            '生效时间',
            _formatDateTime(temporal.effectivePanTime),
          ),
          QimenInfoRow(
            '时区 / 校正',
            'UTC${_formatOffset(temporal.sourceUtcOffsetMinutes)} · '
                '${temporal.totalCorrectionMinutes.toStringAsFixed(2)} 分钟',
          ),
          if (temporal.longitude != null)
            QimenInfoRow(
              '经度',
              '${temporal.longitude!.toStringAsFixed(4)}° · '
                  '标准经线 ${temporal.standardMeridian.toStringAsFixed(1)}°',
            ),
          QimenInfoRow('校正算法', temporal.correctionAlgorithmVersion),
          QimenInfoRow('换日', _dayBoundaryLabel(params.dayBoundary)),
          QimenInfoRow('寄宫', _hostingLabel(params.hostingMode)),
          QimenInfoRow('暗干', _hiddenStemLabel(params.hiddenStemMode)),
          QimenInfoRow('问事类型', _questionCategoryLabel(params.questionCategory)),
        ],
      ),
    );
  }
}

class QimenDutySection extends StatelessWidget {
  const QimenDutySection({super.key, required this.result});

  final QimenResult result;

  @override
  Widget build(BuildContext context) {
    final ju = result.juInfo;
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '局数与值符值使'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          QimenInfoRow('定局',
              '${_juMethodLabel(ju.method)} · ${ju.dun.label}遁${ju.juNumber}局'),
          QimenInfoRow('三元', ju.yuan.label),
          QimenInfoRow('有效节气', ju.effectiveSolarTerm),
          QimenInfoRow('符头', ju.symbolHead ?? '无'),
          QimenInfoRow(
            '置闰状态',
            ju.isLeap
                ? '闰局'
                : ju.isReceivingQi
                    ? '接气'
                    : '常规',
          ),
          QimenInfoRow('旬首', '${result.xunShou}遁${result.xunHiddenStem}'),
          QimenInfoRow('值符', '${result.zhiFuStar} · ${result.zhiFuPalace}宫'),
          QimenInfoRow('值使', '${result.zhiShiDoor} · ${result.zhiShiPalace}宫'),
        ],
      ),
    );
  }
}

class QimenPalaceSection extends StatelessWidget {
  const QimenPalaceSection({
    super.key,
    required this.result,
    required this.report,
  });

  final QimenResult result;
  final QimenAnalysisReport report;

  @override
  Widget build(BuildContext context) => AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntiqueSectionTitle(title: '洛书九宫'),
            const AntiqueDivider(),
            const SizedBox(height: 8),
            QimenNinePalaceGrid(
              palaces: result.palaces,
              onPalaceTap: (palace) => showQimenPalaceDetailSheet(
                context,
                palace: palace,
                report: report,
              ),
            ),
          ],
        ),
      );
}

class QimenMarkersSection extends StatelessWidget {
  const QimenMarkersSection({super.key, required this.result});

  final QimenResult result;

  @override
  Widget build(BuildContext context) => AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntiqueSectionTitle(title: '关键标记与推导口径'),
            const AntiqueDivider(),
            const SizedBox(height: 8),
            QimenInfoRow('旬空', result.kongWangBranches.join('、')),
            QimenInfoRow(
                '驿马', '${result.horseBranch} · ${result.horsePalace}宫'),
            QimenInfoRow(
              '中五事实',
              '中五原盘字段保留；寄宫字段在目标宫独立展示，不覆盖主字段。',
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: Text(
                '完整推导记录（${result.derivationSteps.length}）',
                style: AppTextStyles.antiqueBody.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              children: result.derivationSteps
                  .map((step) => _BulletText(step))
                  .toList(),
            ),
          ],
        ),
      );
}

class QimenVerdictSection extends StatelessWidget {
  const QimenVerdictSection({
    super.key,
    required this.projection,
  });

  final QimenAnalysisProjection projection;

  @override
  Widget build(BuildContext context) {
    final judgment = projection.verdict.judgment;
    final color = _trendColor(judgment.trend);
    return AntiqueCard(
      child: Semantics(
        label: '程序裁决，${judgment.trend.name}。${judgment.summary}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntiqueSectionTitle(title: '规则裁决'),
            const AntiqueDivider(),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Icon(_trendIcon(judgment.trend), size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      judgment.trend.name,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Text(
                    projection.verdict.matchedDecisionRowId,
                    style: const TextStyle(
                      color: AppColors.guhe,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              judgment.summary,
              style: AppTextStyles.antiqueBody.copyWith(
                height: 1.55,
                letterSpacing: 0,
              ),
            ),
            if (projection.status != QimenAnalysisStatus.complete ||
                projection.diagnostics.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DiagnosticPanel(projection: projection),
            ],
            if (projection.verdict.conditionLinks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                '未决条件',
                style: AppTextStyles.antiqueSection.copyWith(letterSpacing: 0),
              ),
              const SizedBox(height: 6),
              ...projection.verdict.conditionLinks.map(
                (condition) => _BulletText(
                  '${condition.condition.label}：${condition.condition.reason}；'
                  '观察 ${condition.releaseScale.name}尺度 '
                  '${condition.releaseTriggerValue}',
                  icon: Icons.pending_actions_outlined,
                ),
              ),
            ],
            if (judgment.factors.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text(
                  '完整裁决因素（${judgment.factors.length}）',
                  style: AppTextStyles.antiqueBody.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                children: judgment.factors
                    .map(
                      (factor) => _BulletText(
                        '${factor.effect.name} · ${factor.rule}：'
                        '${factor.reason}（${factor.source}）',
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class QimenFactsSection extends StatelessWidget {
  const QimenFactsSection({
    super.key,
    required this.projection,
  });

  final QimenAnalysisProjection projection;

  @override
  Widget build(BuildContext context) {
    final participating = projection.verdict.participatingFactIds.toSet();
    final keyFacts = projection.facts
        .where(
          (fact) =>
              participating.contains(fact.occurrenceId) ||
              fact.affectsPrimaryFocus,
        )
        .toList();

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '焦点、事实与审计链'),
          const AntiqueDivider(),
          const SizedBox(height: 10),
          Text(
            '主焦点',
            style: AppTextStyles.antiqueSection.copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 6),
          ...projection.focuses.map(
            (focus) => _BulletText(
              '${focus.roleId} · ${focus.indicatorValue}落${focus.palaceNumber}宫'
              '${focus.isHosted ? '（原宫${focus.originPalaceNumber}，寄宫）' : ''}：'
              '${focus.reason}',
              icon: focus.priority == QimenFocusPriority.primary
                  ? Icons.center_focus_strong
                  : Icons.adjust,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '关键事实',
            style: AppTextStyles.antiqueSection.copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 6),
          if (keyFacts.isEmpty)
            const _BulletText('当前没有进入主焦点或裁决的关键事实。')
          else
            ...keyFacts.map(_factWidget),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            title: Text(
              '全部格局与宫位事实（${projection.facts.length}）',
              style: AppTextStyles.antiqueBody.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            children: projection.facts.map(_factWidget).toList(),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            title: Text(
              '冲突与压制（${projection.conflicts.length}）',
              style: AppTextStyles.antiqueBody.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            children: projection.conflicts.isEmpty
                ? const <Widget>[_BulletText('没有冲突记录。')]
                : projection.conflicts
                    .map(
                      (conflict) => _BulletText(
                        '${conflict.policyId}：${conflict.reason}\n'
                        '胜出 ${conflict.winnerOccurrenceId ?? '未决'}；'
                        '压制 ${conflict.suppressedOccurrenceIds.isEmpty ? '无' : conflict.suppressedOccurrenceIds.join('、')}',
                        icon: conflict.isUnresolved
                            ? Icons.help_outline
                            : Icons.rule,
                      ),
                    )
                    .toList(),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            title: Text(
              '完整推理 trace（${projection.trace.length}）',
              style: AppTextStyles.antiqueBody.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            children: projection.trace
                .map(
                  (trace) => _BulletText(
                    '${trace.sequence}. ${trace.stage.id} / ${trace.ruleId} / '
                    '${trace.status.id}：${trace.explanation}',
                  ),
                )
                .toList(),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            title: Text(
              '规则来源（${projection.sources.length}）',
              style: AppTextStyles.antiqueBody.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            children: projection.sources
                .map(
                  (source) => _BulletText(
                    '${source.sourceId} · ${source.title}\n'
                    '${source.editionOrRevision} · ${source.locator}\n'
                    '${source.claimSummary}',
                    icon: Icons.menu_book_outlined,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            '分析规则 ${projection.ruleSetId}/${projection.ruleSetVersion}',
            style: const TextStyle(
              color: AppColors.guhe,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factWidget(QimenFact fact) => _BulletText(
        '${fact.ruleId} · ${fact.polarity.name}：${fact.reason}\n'
        '宫位 ${fact.relatedPalaceNumbers.join('、')} · '
        '来源 ${fact.sourceIds.join('、')}',
        icon: _polarityIcon(fact.polarity),
        color: _polarityColor(fact.polarity),
      );
}

class QimenTimingSection extends StatelessWidget {
  const QimenTimingSection({
    super.key,
    required this.candidates,
  });

  final List<QimenYingQiCandidate> candidates;

  @override
  Widget build(BuildContext context) => AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntiqueSectionTitle(title: '应期观察窗口'),
            const AntiqueDivider(),
            const SizedBox(height: 8),
            Text(
              '以下仅为程序根据已命中事实和未决条件给出的观察窗口，不保证事件发生，也不表示结论自动转吉。',
              style: AppTextStyles.antiqueLabel.copyWith(
                height: 1.55,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              const _BulletText('当前规则没有生成可审计的应期候选。')
            else
              ...candidates.map(
                (candidate) => _BulletText(
                  '${candidate.scale.name}尺度 · ${candidate.triggerKind.id} '
                  '${candidate.triggerValue}：${candidate.reason}\n'
                  '目标 ${candidate.targetFocusRoleId ?? '全局'} · '
                  '来源 ${candidate.sourceIds.join('、')}',
                  icon: Icons.event_available_outlined,
                  color: AppColors.qimenColor,
                ),
              ),
          ],
        ),
      );
}

class QimenInfoRow extends StatelessWidget {
  const QimenInfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 86,
              child: Text(
                label,
                style: AppTextStyles.antiqueBody.copyWith(
                  color: AppColors.guhe,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.antiqueBody.copyWith(
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      );
}

class _BulletText extends StatelessWidget {
  const _BulletText(
    this.text, {
    this.icon = Icons.circle,
    this.color = AppColors.guhe,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child:
                  Icon(icon, size: icon == Icons.circle ? 6 : 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.huise,
                  fontSize: 13,
                  height: 1.55,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      );
}

class _DiagnosticPanel extends StatelessWidget {
  const _DiagnosticPanel({required this.projection});

  final QimenAnalysisProjection projection;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分析兼容诊断',
              style: TextStyle(
                color: AppColors.xuanse,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            ...projection.diagnostics.map(
              (item) => Text(
                '${item.code} · ${item.path}\n${item.message}',
                style: const TextStyle(
                  color: AppColors.huise,
                  fontSize: 12,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      );
}

Color _trendColor(VerdictTrend trend) => switch (trend) {
      VerdictTrend.keCheng => AppColors.jishenGreen,
      VerdictTrend.nanCheng => AppColors.zhusha,
      VerdictTrend.daiTiaoJian => AppColors.warning,
      VerdictTrend.buMing => AppColors.guhe,
    };

IconData _trendIcon(VerdictTrend trend) => switch (trend) {
      VerdictTrend.keCheng => Icons.check_circle_outline,
      VerdictTrend.nanCheng => Icons.block_outlined,
      VerdictTrend.daiTiaoJian => Icons.pending_actions_outlined,
      VerdictTrend.buMing => Icons.help_outline,
    };

Color _polarityColor(Polarity polarity) => switch (polarity) {
      Polarity.ji => AppColors.jishenGreen,
      Polarity.xiong => AppColors.zhusha,
      Polarity.neutral => AppColors.guhe,
    };

IconData _polarityIcon(Polarity polarity) => switch (polarity) {
      Polarity.ji => Icons.add_circle_outline,
      Polarity.xiong => Icons.remove_circle_outline,
      Polarity.neutral => Icons.radio_button_unchecked,
    };

String _timeBasisLabel(QimenTimeBasis value) => switch (value) {
      QimenTimeBasis.localCivil => '当地民用时间',
      QimenTimeBasis.beijing => '北京时间',
      QimenTimeBasis.trueSolar => '真太阳时',
    };

String _dayBoundaryLabel(QimenDayBoundary value) => switch (value) {
      QimenDayBoundary.ziInitial => '23:00 子初换日',
      QimenDayBoundary.midnight => '00:00 午夜换日',
    };

String _hostingLabel(QimenHostingMode value) => switch (value) {
      QimenHostingMode.kunTwo => '中五寄坤二',
      QimenHostingMode.yangEightYinTwo => '阳遁寄艮八 / 阴遁寄坤二',
    };

String _hiddenStemLabel(QimenHiddenStemMode value) => switch (value) {
      QimenHiddenStemMode.dutyDoorHourStem => '值使落宫起时干',
      QimenHiddenStemMode.doorOriginEarthStem => '门本位地盘干',
    };

String _juMethodLabel(QimenJuMethod value) => switch (value) {
      QimenJuMethod.chaiBu => '拆补',
      QimenJuMethod.maoShan => '茅山',
      QimenJuMethod.zhiRun => '置闰',
      QimenJuMethod.manual => '手动校盘',
    };

String _questionCategoryLabel(QimenQuestionCategory value) => switch (value) {
      QimenQuestionCategory.general => '综合',
      QimenQuestionCategory.career => '事业',
      QimenQuestionCategory.wealth => '财运',
      QimenQuestionCategory.relationship => '感情',
      QimenQuestionCategory.health => '健康',
      QimenQuestionCategory.study => '学业',
      QimenQuestionCategory.travel => '出行',
      QimenQuestionCategory.litigation => '诉讼',
    };

String _formatDateTime(DateTime value) {
  String pad(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${pad(value.month)}-${pad(value.day)} '
      '${pad(value.hour)}:${pad(value.minute)}';
}

String _formatOffset(int minutes) {
  final sign = minutes >= 0 ? '+' : '-';
  final absolute = minutes.abs();
  final hour = (absolute ~/ 60).toString().padLeft(2, '0');
  final minute = (absolute % 60).toString().padLeft(2, '0');
  return '$sign$hour:$minute';
}
