import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_tag.freezed.dart';

/// 分析标签分类
enum TagCategory {
  wangShuai('日月旺衰'),
  kongWang('空亡'),
  muJue('墓绝'),
  heChong('合冲刑害'),
  dongBian('动变'),
  shengKe('生克'),
  liuQin('六亲'),
  fuShen('伏藏飞神'),
  special('特殊作用'),
  guaChange('卦象变化');

  const TagCategory(this.name);
  final String name;
}

/// 标签吉凶极性
enum Polarity {
  ji('吉'),
  xiong('凶'),
  neutral('中性');

  const Polarity(this.name);
  final String name;
}

/// 单条分析标签。
///
/// 派生数据，仅在内存中使用，不做持久化。
/// [priority] 数值越小越优先；爻行内联徽标取每爻前 2~3 个。
/// [relatedYao] 记录跨爻关系的关联爻位（1-6）。
@freezed
class YaoAnalysisTag with _$YaoAnalysisTag {
  const factory YaoAnalysisTag({
    required String term,
    required TagCategory category,
    required Polarity polarity,
    required int priority,
    required String reason,
    @Default(<int>[]) List<int> relatedYao,
  }) = _YaoAnalysisTag;
}
