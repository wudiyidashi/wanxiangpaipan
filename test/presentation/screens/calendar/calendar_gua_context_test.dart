import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/calendar_gua_context.dart';

void main() {
  group('CalendarGuaContext.markerFor', () {
    const context = CalendarGuaContext(
      title: '测试卦 · 用神卯木',
      yongShenBranch: '卯',
      yingQiByBranch: <String, String>{'酉': '冲开待决条件'},
    );

    test('日尺度应期优先于冲、合、空关系', () {
      expect(context.markerFor('癸酉'), GuaDayMarkerType.ying);
    });

    test('依次识别冲、合、旬空，并忽略无效或无关系日期', () {
      expect(
        const CalendarGuaContext(
          title: '测试',
          yongShenBranch: '卯',
          yingQiByBranch: <String, String>{},
        ).markerFor('癸酉'),
        GuaDayMarkerType.chong,
      );
      expect(context.markerFor('甲戌'), GuaDayMarkerType.he);
      expect(
        const CalendarGuaContext(
          title: '测试',
          yongShenBranch: '戌',
          yingQiByBranch: <String, String>{},
        ).markerFor('甲子'),
        GuaDayMarkerType.kong,
      );
      expect(context.markerFor('甲子'), isNull);
      expect(context.markerFor('无效'), isNull);
    });
  });

  group('CalendarGuaContext.describeDay', () {
    test('合并日尺度应期与用神关系说明', () {
      const context = CalendarGuaContext(
        title: '测试',
        yongShenBranch: '卯',
        yingQiByBranch: <String, String>{'酉': '冲开待决条件'},
      );

      expect(
        context.describeDay('癸酉'),
        '本日酉值应期（冲开待决条件）；日辰酉冲用神卯，主动荡变化。',
      );
      expect(
        context.describeDay('丁卯'),
        '日辰卯与用神同支，用神当值。',
      );
    });

    test('说明旬空、无关系与无效日期', () {
      const context = CalendarGuaContext(
        title: '测试',
        yongShenBranch: '戌',
        yingQiByBranch: <String, String>{},
      );

      expect(
        context.describeDay('甲子'),
        '用神戌本日旬空，待出空或逢本支填实。',
      );
      expect(
        context.describeDay('戊寅'),
        '本日与用神戌无明显合冲空应关系。',
      );
      expect(context.describeDay('无效'), isEmpty);
    });
  });
}
