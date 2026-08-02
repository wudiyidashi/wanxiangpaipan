import '../../../domain/services/shared/analysis/models/verdict_models.dart';
import '../../../presentation/screens/calendar/calendar_gua_context.dart';

/// Adapts Liuyao timing candidates to the calendar's string-only contract.
class LiuYaoCalendarContextMapper {
  LiuYaoCalendarContextMapper._();

  static CalendarGuaContext build({
    required String title,
    required String yongShenBranch,
    required Iterable<YingQiCandidate> candidates,
  }) {
    return CalendarGuaContext(
      title: title,
      yongShenBranch: yongShenBranch,
      yingQiByBranch: <String, String>{
        for (final candidate in candidates)
          if (candidate.scale == YingQiScale.ri)
            candidate.branch: candidate.reason,
      },
      yingQiMonthByBranch: <String, String>{
        for (final candidate in candidates)
          if (candidate.scale == YingQiScale.yue)
            candidate.branch: candidate.reason,
      },
    );
  }
}
