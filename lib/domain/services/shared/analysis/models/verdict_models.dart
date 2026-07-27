import 'package:freezed_annotation/freezed_annotation.dart';

part 'verdict_models.freezed.dart';

/// 应期尺度
enum YingQiScale {
  ri('日'),
  yue('月'),
  nian('年');

  const YingQiScale(this.name);
  final String name;
}

/// 裁决趋势（四值，不做吉凶打分）
enum VerdictTrend {
  keCheng('可成'),
  nanCheng('难成'),
  daiTiaoJian('待条件'),
  buMing('趋势不明');

  const VerdictTrend(this.name);
  final String name;
}

/// 裁决因素作用方向
enum VerdictEffect {
  fu('扶'),
  yi('抑'),
  suspend('悬'),
  neutral('中');

  const VerdictEffect(this.name);
  final String name;
}

/// 裁决推理链中的单条因素记录
@freezed
class VerdictFactor with _$VerdictFactor {
  const factory VerdictFactor({
    /// 规则名，如 "日月生扶" "忌神独发"
    required String rule,
    required VerdictEffect effect,

    /// 人话理由（含爻位/地支）
    required String reason,

    /// 经文依据，如 "《增删卜易》生克章"
    required String source,
  }) = _VerdictFactor;
}

/// 未决条件：悬置状态不判凶，转为待解除条件
@freezed
class VerdictCondition with _$VerdictCondition {
  const factory VerdictCondition({
    /// 如 "待出空" "待冲开墓库"
    required String label,

    /// 关联地支（用于衔接应期候选），无明确地支时为 null
    String? branch,
    required String reason,

    /// 是否存在解救路径；false 即"真空到底""伏而受制"类
    @Default(true) bool hasRescue,
  }) = _VerdictCondition;
}

/// 裁决结果：趋势 + 条件集 + 推理链。
///
/// 由决策表首行命中产生，非加权求和；派生数据不落库。
@freezed
class VerdictJudgment with _$VerdictJudgment {
  const factory VerdictJudgment({
    required VerdictTrend trend,

    /// 细化语气，如 "先难后成" "成而有待"
    String? nuance,
    @Default(<VerdictCondition>[]) List<VerdictCondition> conditions,

    /// 推理链，按裁决顺序（受力因素在前，命中决策表行殿后）
    @Default(<VerdictFactor>[]) List<VerdictFactor> factors,

    /// 生成的总览文案（填充 AnalysisReport.verdictSummary）
    required String summary,
  }) = _VerdictJudgment;
}

/// 应期候选
@freezed
class YingQiCandidate with _$YingQiCandidate {
  const factory YingQiCandidate({
    /// 展示文案，如 "戌日（填实旬空）"
    required String label,

    /// 应期地支；仅日尺度候选用于日历按日匹配
    required String branch,
    required YingQiScale scale,
    required String reason,
    required int priority,
  }) = _YingQiCandidate;
}
