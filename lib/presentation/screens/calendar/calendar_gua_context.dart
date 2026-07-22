import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/services/liuyao/analysis/tables/dizhi_relations.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';

/// 日期角标类型：应 > 冲 > 合 > 空（每日仅取最高优先级一个）
enum GuaDayMarkerType {
  ying('应', AppColors.gutong),
  chong('冲', AppColors.zhusha),
  he('合', AppColors.danjinDeep),
  kong('空', AppColors.huise);

  const GuaDayMarkerType(this.label, this.color);
  final String label;
  final Color color;
}

/// 日历应期模式的卦上下文。
///
/// 以纯字符串承载，避免日历模块依赖六爻分析模型；
/// 由六爻结果页构造后经 route arguments 传入。
class CalendarGuaContext {
  const CalendarGuaContext({
    required this.title,
    required this.yongShenBranch,
    required this.yingQiByBranch,
  });

  /// 顶部横幅标题，如「乾为天 · 用神妻财寅木」
  final String title;

  /// 用神地支
  final String yongShenBranch;

  /// 应期候选：地支 → 理由（仅日尺度参与格子标记）
  final Map<String, String> yingQiByBranch;

  /// 某日相对用神的角标；[dayGanZhi] 为该日干支（如「甲子」）
  GuaDayMarkerType? markerFor(String dayGanZhi) {
    final split = TianGanDiZhiService.splitGanZhi(dayGanZhi);
    if (split == null) return null;
    final dayBranch = split[1];

    if (yingQiByBranch.containsKey(dayBranch)) return GuaDayMarkerType.ying;
    if (DiZhiRelations.isLiuChong(dayBranch, yongShenBranch)) {
      return GuaDayMarkerType.chong;
    }
    if (DiZhiRelations.isLiuHe(dayBranch, yongShenBranch)) {
      return GuaDayMarkerType.he;
    }
    if (TianGanDiZhiService.getKongWang(dayGanZhi)
        .contains(yongShenBranch)) {
      return GuaDayMarkerType.kong;
    }
    return null;
  }

  /// 某日与用神关系的文字描述（日详情「与本卦」区块）
  String describeDay(String dayGanZhi) {
    final split = TianGanDiZhiService.splitGanZhi(dayGanZhi);
    if (split == null) return '';
    final dayBranch = split[1];
    final parts = <String>[];

    final yingQiReason = yingQiByBranch[dayBranch];
    if (yingQiReason != null) {
      parts.add('本日$dayBranch值应期（$yingQiReason）');
    }
    if (dayBranch == yongShenBranch) {
      parts.add('日辰$dayBranch与用神同支，用神当值');
    } else if (DiZhiRelations.isLiuChong(dayBranch, yongShenBranch)) {
      parts.add('日辰$dayBranch冲用神$yongShenBranch，主动荡变化');
    } else if (DiZhiRelations.isLiuHe(dayBranch, yongShenBranch)) {
      parts.add('日辰$dayBranch合用神$yongShenBranch，主和合牵绊');
    }
    if (TianGanDiZhiService.getKongWang(dayGanZhi)
        .contains(yongShenBranch)) {
      parts.add('用神$yongShenBranch本日旬空，待出空填实');
    }
    if (parts.isEmpty) {
      return '本日与用神$yongShenBranch无明显合冲空应关系。';
    }
    return '${parts.join('；')}。';
  }
}
