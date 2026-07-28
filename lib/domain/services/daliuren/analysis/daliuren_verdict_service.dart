import '../../../../divination_systems/daliuren/models/chuan.dart';
import '../../../../divination_systems/daliuren/models/dlr_rule_contract.dart';
import '../../shared/analysis/models/polarity.dart';
import '../../shared/analysis/models/verdict_models.dart';
import 'models/daliuren_analysis_models.dart';

/// 大六壬裁决层：决策表首行命中产出趋势 + 条件集 + 推理链。
///
/// 规则为本项目约定（大六壬断课 v1），不做加权打分；
/// 课格基调措辞参照《大六壬指南》课体章。
class DaLiuRenVerdictService {
  DaLiuRenVerdictService._();

  static const String _source = '本项目约定（大六壬断课 v1）';
  static const String _keGeSource = '《大六壬指南》课体章（基调）';

  /// 裁决：悬置条件收集先于决策表，决策表自上而下首行命中。
  ///
  /// [chuChuanZhi]/[moChuanZhi] 初传/末传地支；
  /// [chuKongWang]/[moKongWang]/[zhongKongWang] 三传空亡状态。
  static VerdictJudgment judge({
    required KeGeInfo keGe,
    required List<DlrAnalysisTag> ganZhiTags,
    required Map<ChuanPosition, List<DlrAnalysisTag>> chuanTags,
    required List<DlrAnalysisTag> juTags,
    required String chuChuanZhi,
    required String moChuanZhi,
    required bool chuKongWang,
    required bool zhongKongWang,
    required bool moKongWang,
  }) {
    final allTags = <DlrAnalysisTag>[
      ...ganZhiTags,
      ...chuanTags.values.expand((tags) => tags),
      ...juTags,
    ];
    final executableTags = allTags
        .where((tag) => _isCurrentProjectRule(tag.ruleRef))
        .toList(growable: false);
    final ruleIds = executableTags.map((tag) => tag.ruleRef.ruleId).toSet();
    final executableKeGe = _isCurrentProjectRule(keGe.ruleRef);

    // ── 悬置条件收集（先于决策表）──
    var conditions = <VerdictCondition>[];
    if (chuKongWang) {
      conditions.add(VerdictCondition(
        label: '待发用填实',
        branch: chuChuanZhi,
        reason: '初传$chuChuanZhi落空，待$chuChuanZhi值日填实，事方能起',
      ));
    }
    if (moKongWang) {
      conditions.add(VerdictCondition(
        label: '待归宿填实',
        branch: moChuanZhi,
        reason: '末传$moChuanZhi落空，待$moChuanZhi值日填实，事方有归',
      ));
    }
    // 中传空不单独成悬置（只留标签）
    final hasSuspend = conditions.isNotEmpty;

    final chuanGuiKeShen = ruleIds.contains(
      DlrProjectRuleIds.transmissionReturnsToControlSelf,
    );
    final chuanGuiShengShen = ruleIds.contains(
      DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
    );
    final ganShangKeShen =
        ruleIds.contains(DlrProjectRuleIds.ganAboveControlsSelf);
    final faYongKeShen = ruleIds.contains(
      DlrProjectRuleIds.initialTransmissionControlsSelf,
    );
    final diKeChuanTui = ruleIds.contains(DlrProjectRuleIds.progressiveControl);
    final diShengChuanJin =
        ruleIds.contains(DlrProjectRuleIds.progressiveGeneration);
    final hasKeShenTag = chuanGuiKeShen || ganShangKeShen || faYongKeShen;
    final hasXiongTag = (executableKeGe && keGe.polarity == Polarity.xiong) ||
        executableTags.any((tag) => tag.polarity == Polarity.xiong);

    // ── 决策表（自上而下首行命中）──
    final VerdictTrend trend;
    String? nuance;
    final String rule;
    final participatingRuleIds = <String>{};

    if (chuKongWang && moKongWang) {
      // 1. 初传空 且 末传空 → 难成（首尾俱空，hasRescue=false）
      (trend, nuance, rule) = (VerdictTrend.nanCheng, '首尾俱空，事难成实', '首尾俱空');
      conditions = conditions.map((c) => c.copyWith(hasRescue: false)).toList();
    } else if (chuanGuiKeShen && ganShangKeShen) {
      // 2. 传归克身 且 干上克身 → 难成（内外交攻）
      (trend, nuance, rule) = (VerdictTrend.nanCheng, '内外交攻', '内外交攻');
      participatingRuleIds.addAll(<String>{
        DlrProjectRuleIds.transmissionReturnsToControlSelf,
        DlrProjectRuleIds.ganAboveControlsSelf,
      });
    } else if (diKeChuanTui &&
        executableKeGe &&
        keGe.polarity == Polarity.xiong) {
      // 3. 递克传退 且 课格凶 → 难成
      (trend, nuance, rule) = (VerdictTrend.nanCheng, null, '递克传退而课格凶');
      participatingRuleIds.add(DlrProjectRuleIds.progressiveControl);
    } else if (chuanGuiShengShen && !hasSuspend) {
      // 4. 传归生身 且 无悬置 → 可成
      nuance = (executableKeGe &&
              (keGe.ruleRef.ruleId == DlrProjectRuleIds.keGeSheHai ||
                  keGe.ruleRef.ruleId == DlrProjectRuleIds.keGeChongShen))
          ? '先难后成'
          : null;
      (trend, rule) = (VerdictTrend.keCheng, '传归生身而无悬置');
      participatingRuleIds.add(
        DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
      );
    } else if (chuanGuiShengShen && hasSuspend) {
      // 5. 传归生身 且 有悬置 → 待条件
      (trend, nuance, rule) = (VerdictTrend.daiTiaoJian, null, '传归生身而有悬置');
      participatingRuleIds.add(
        DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
      );
    } else if (diShengChuanJin && !hasSuspend && !hasKeShenTag) {
      // 6. 递生传进 且 无悬置 且 无克身标签 → 可成
      (trend, nuance, rule) = (VerdictTrend.keCheng, null, '递生传进而无阻');
      participatingRuleIds.add(DlrProjectRuleIds.progressiveGeneration);
    } else if (hasSuspend) {
      // 7. 有悬置 → 待条件
      (trend, nuance, rule) = (VerdictTrend.daiTiaoJian, null, '空亡悬置未决');
    } else if (chuanGuiKeShen || faYongKeShen) {
      // 8. 传归克身 或 发用克身 → 难成
      (trend, nuance, rule) = (VerdictTrend.nanCheng, null, '克身无解');
      if (chuanGuiKeShen) {
        participatingRuleIds.add(
          DlrProjectRuleIds.transmissionReturnsToControlSelf,
        );
      }
      if (faYongKeShen) {
        participatingRuleIds.add(
          DlrProjectRuleIds.initialTransmissionControlsSelf,
        );
      }
    } else if (executableKeGe && keGe.polarity == Polarity.ji && !hasXiongTag) {
      // 9. 课格 ji 且 无任何 xiong 标签 → 可成
      (trend, nuance, rule) = (VerdictTrend.keCheng, null, '课格吉而无凶象');
    } else {
      // 10. 其余 → 趋势不明
      (trend, nuance, rule) = (VerdictTrend.buMing, '吉凶交参，须参断者裁', '吉凶交参');
    }

    // ── factors：课格基调 + 参与判断标签 + 悬置 + 命中行 ──
    final factors = <VerdictFactor>[
      VerdictFactor(
        rule: '课格·${keGe.geName}',
        effect: switch (keGe.polarity) {
          Polarity.ji => VerdictEffect.fu,
          Polarity.xiong => VerdictEffect.yi,
          Polarity.neutral => VerdictEffect.neutral,
        },
        reason: keGe.reason,
        source: _keGeSource,
      ),
      for (final tag in executableTags.where(
        (tag) => participatingRuleIds.contains(tag.ruleRef.ruleId),
      ))
        VerdictFactor(
          rule: tag.term,
          effect: switch (tag.polarity) {
            Polarity.ji => VerdictEffect.fu,
            Polarity.xiong => VerdictEffect.yi,
            Polarity.neutral => VerdictEffect.neutral,
          },
          reason: tag.reason,
          source: _source,
        ),
      for (final condition in conditions)
        VerdictFactor(
          rule: condition.label,
          effect: VerdictEffect.suspend,
          reason: condition.reason,
          source: _source,
        ),
      VerdictFactor(
        rule: '裁决·$rule',
        effect: VerdictEffect.neutral,
        reason: '决策表命中：${trend.name}${nuance == null ? '' : '（$nuance）'}',
        source: _source,
      ),
    ];

    return VerdictJudgment(
      trend: trend,
      nuance: nuance,
      conditions: conditions,
      factors: factors,
      summary: _buildSummary(
        keGe: keGe,
        trend: trend,
        nuance: nuance,
        conditions: conditions,
      ),
    );
  }

  /// summary 模板："课体{keTypeName}（{geName}），断曰：{trend}。{nuance？}{条件清单}。"
  static String _buildSummary({
    required KeGeInfo keGe,
    required VerdictTrend trend,
    required String? nuance,
    required List<VerdictCondition> conditions,
  }) {
    final condText = conditions
        .map((c) => c.branch == null ? c.label : '${c.label}（${c.branch}）')
        .join('、');
    return '课体${keGe.keTypeName}（${keGe.geName}），断曰：${trend.name}。'
        '${nuance == null ? '' : '$nuance。'}'
        '${condText.isEmpty ? '' : '未决条件：$condText。'}';
  }

  static bool _isCurrentProjectRule(DlrRuleRef ruleRef) =>
      ruleRef.isExecutable &&
      ruleRef.kind == DlrRuleKind.project &&
      ruleRef.ruleSetVersion == DlrRuleSetVersions.analysisCurrent;
}
