import 'package:freezed_annotation/freezed_annotation.dart';

import 'analysis_tag.dart';

part 'analysis_report.freezed.dart';

/// 应期尺度
enum YingQiScale {
  ri('日'),
  yue('月'),
  nian('年');

  const YingQiScale(this.name);
  final String name;
}

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

    /// 原神爻位（可能不上卦）
    int? yuanShenPosition,

    /// 忌神爻位
    int? jiShenPosition,

    /// 仇神爻位
    int? chouShenPosition,

    /// 闲神爻位
    @Default(<int>[]) List<int> xianShenPositions,
  }) = _YongShenChain;
}

/// 应期候选
@freezed
class YingQiCandidate with _$YingQiCandidate {
  const factory YingQiCandidate({
    /// 展示文案，如 "戌日（填实旬空）"
    required String label,

    /// 应期地支（用于日历按日匹配）
    required String branch,
    required YingQiScale scale,
    required String reason,
    required int priority,
  }) = _YingQiCandidate;
}

/// 完整分析报告。
///
/// 派生数据，一律不落库；规则升级后旧卦自动获得新分析。
@freezed
class AnalysisReport with _$AnalysisReport {
  const AnalysisReport._();

  const factory AnalysisReport({
    /// 各爻标签，key 为爻位 1-6（变爻产生的化X标签挂在对应动爻上）
    required Map<int, List<YaoAnalysisTag>> yaoTags,

    /// 卦级标签（六冲卦、伏吟、卦变六合等）
    @Default(<YaoAnalysisTag>[]) List<YaoAnalysisTag> guaTags,

    /// 用神推理链；未选用神时为 null
    YongShenChain? yongShen,

    /// 应期候选；依赖用神，未选时为 null
    List<YingQiCandidate>? yingQi,

    /// 一句话结论；依赖用神，未选时为 null
    String? verdictSummary,
  }) = _AnalysisReport;

  /// 某爻按优先级排序后的前 [count] 个标签（用于爻行内联徽标）
  List<YaoAnalysisTag> topTagsFor(int position, {int count = 3}) {
    final tags = [...?yaoTags[position]]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return tags.take(count).toList();
  }
}
