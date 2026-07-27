import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../divination_systems/daliuren/models/chuan.dart';
import '../../../shared/analysis/models/polarity.dart';
import '../../../shared/analysis/models/verdict_models.dart';

part 'daliuren_analysis_models.freezed.dart';

/// 大六壬分析标签分类
enum DlrTagCategory {
  keGe('课体课格'),
  ganZhi('干支主客'),
  chuan('三传结构'),
  tianJiang('天将'),
  shenSha('神煞'),
  kongWang('空亡');

  const DlrTagCategory(this.name);
  final String name;
}

/// 大六壬单条分析标签。
///
/// 派生数据，仅在内存中使用，不做持久化。
/// [priority] 数值越小越先展示。
/// [relatedPositions] 关联位置标签："干上" "支上" "初传" "中传" "末传" "第N课"。
@freezed
class DlrAnalysisTag with _$DlrAnalysisTag {
  const factory DlrAnalysisTag({
    required String term,
    required DlrTagCategory category,
    required Polarity polarity,
    required int priority,
    required String reason,
    @Default(<String>[]) List<String> relatedPositions,
  }) = _DlrAnalysisTag;
}

/// 课格定性
@freezed
class KeGeInfo with _$KeGeInfo {
  const factory KeGeInfo({
    /// 九宗门名（贼克/比用/…）
    required String keTypeName,

    /// 传统格名（元首/重审/知一/…）
    required String geName,
    required Polarity polarity,

    /// 基调一句话
    required String reason,
  }) = _KeGeInfo;
}

/// 大六壬完整分析报告。
///
/// 派生数据，一律不落库；规则升级后旧课自动获得新分析。
@freezed
class DaLiuRenAnalysisReport with _$DaLiuRenAnalysisReport {
  const DaLiuRenAnalysisReport._();

  const factory DaLiuRenAnalysisReport({
    /// 课格定性
    required KeGeInfo keGe,

    /// 干支主客标签（含干上/支上空亡）
    @Default(<DlrAnalysisTag>[]) List<DlrAnalysisTag> ganZhiTags,

    /// 每传标签
    @Default(<ChuanPosition, List<DlrAnalysisTag>>{})
    Map<ChuanPosition, List<DlrAnalysisTag>> chuanTags,

    /// 课局级标签（递生递克/传归/三合局/伏吟迟滞…）
    @Default(<DlrAnalysisTag>[]) List<DlrAnalysisTag> juTags,

    /// 应期候选
    List<YingQiCandidate>? yingQi,

    /// 结构化裁决（趋势/条件集/推理链）
    VerdictJudgment? judgment,

    /// 裁决总览文案
    String? verdictSummary,
  }) = _DaLiuRenAnalysisReport;

  /// 某传按优先级排序后的前 [count] 个标签
  List<DlrAnalysisTag> topTagsForChuan(ChuanPosition position,
      {int count = 3}) {
    final tags = [...?chuanTags[position]]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return tags.take(count).toList();
  }
}
