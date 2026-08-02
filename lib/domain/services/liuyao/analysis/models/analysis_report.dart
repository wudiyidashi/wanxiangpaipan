import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/analysis/models/verdict_models.dart';
import '../rules/liuyao_catalog.dart';
import 'analysis_trace.dart';
import 'analysis_tag.dart';

export '../../../shared/analysis/models/verdict_models.dart';

part 'analysis_report.freezed.dart';

/// 用神推理链（用户选定用神后由引擎推导）
@freezed
class YongShenChain with _$YongShenChain {
  const factory YongShenChain({
    /// 用神爻位（1-6）；伏神取用时为飞神所在爻位
    required int position,

    /// 用神是否为伏神
    @Default(false) bool isFuShen,

    /// 用神两现时另一爻位
    @Default(<int>[]) List<int> duplicatePositions,

    /// 元神爻位（可能不上卦）
    int? yuanShenPosition,

    /// 忌神爻位
    int? jiShenPosition,

    /// 仇神爻位
    int? chouShenPosition,

    /// 闲神爻位
    @Default(<int>[]) List<int> xianShenPositions,
  }) = _YongShenChain;
}

/// 完整分析报告。
///
/// 派生数据，一律不落库；规则升级后旧卦自动获得新分析。
@freezed
class AnalysisReport with _$AnalysisReport {
  const AnalysisReport._();

  const factory AnalysisReport({
    @Default(LiuYaoRuleCatalog.analysisSchemaVersion) int analysisSchemaVersion,
    @Default(LiuYaoRuleCatalog.ruleSetId) String ruleSetId,
    @Default(LiuYaoRuleCatalog.current) String ruleSetVersion,
    @Default(LiuYaoRuleCatalog.sourceCatalogVersion)
    String sourceCatalogVersion,
    @Default(LiuYaoAnalysisStatus.success) LiuYaoAnalysisStatus status,
    @Default(<String>[]) List<String> diagnostics,
    @Default(LiuYaoAnalysisStages.ordered) List<String> analysisStages,

    /// 各爻标签，key 为爻位 1-6（变爻产生的化X标签挂在对应动爻上）
    required Map<int, List<YaoAnalysisTag>> yaoTags,

    /// 卦级标签（六冲卦、伏吟、卦变六合等）
    @Default(<YaoAnalysisTag>[]) List<YaoAnalysisTag> guaTags,

    /// 用神推理链；未选用神时为 null
    YongShenChain? yongShen,

    /// 所选用神自身的状态标签。伏神取用时分析伏神，不复用飞神标签。
    @Default(<YaoAnalysisTag>[]) List<YaoAnalysisTag> yongShenTags,

    /// 应期候选；依赖用神，未选时为 null
    List<YingQiCandidate>? yingQi,

    /// 用神状态摘要；不根据标签数量直接判定事情成败
    String? verdictSummary,

    /// 结构化裁决（趋势/条件集/推理链）；依赖用神，未选时为 null
    VerdictJudgment? judgment,

    /// Complete role and force inventory used by the v2 verdict.
    @Default(<LiuYaoRoleOccurrence>[]) List<LiuYaoRoleOccurrence> roles,
    @Default(<ActorAvailability>[]) List<ActorAvailability> actorAvailability,
    @Default(<DirectedEffectOccurrence>[])
    List<DirectedEffectOccurrence> directedEffects,
    @Default(<LiuYaoAnalysisTraceStep>[]) List<LiuYaoAnalysisTraceStep> trace,
    @Default(<String>[]) List<String> usedSourceIds,
  }) = _AnalysisReport;

  /// 某爻按优先级排序后的前 [count] 个标签（用于爻行内联徽标）
  List<YaoAnalysisTag> topTagsFor(int position, {int count = 3}) {
    final tags = [...?yaoTags[position]]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return tags.take(count).toList();
  }
}
