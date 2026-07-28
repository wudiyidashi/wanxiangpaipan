import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/dlr_cast_time_service.dart';

void main() {
  group('DlrCivilTime', () {
    test('规范化 absolute instant 并稳定 JSON round-trip', () {
      final value = DlrCivilTime(
        instant: DateTime.parse('2022-04-20T10:24:18+08:00'),
        sourceUtcOffsetMinutes: 480,
      );
      final decoded = DlrCivilTime.fromJson(value.toJson());

      expect(value.instantUtc, DateTime.utc(2022, 4, 20, 2, 24, 18));
      expect(value.toJson()['instantUtc'], endsWith('Z'));
      expect(decoded, value);
      expect(decoded.sourceWallTime, DateTime.utc(2022, 4, 20, 10, 24, 18));
    });

    test('拒绝越界 offset 与无 zone 的权威 JSON 时刻', () {
      expect(
        () => DlrCivilTime(
          instant: DateTime.utc(2022),
          sourceUtcOffsetMinutes: 841,
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrCivilTime.fromJson(const <String, dynamic>{
          'instantUtc': '2022-04-20T10:24:18',
          'sourceUtcOffsetMinutes': 480,
        }),
        throwsArgumentError,
      );
    });
  });

  group('DlrCastTimeService', () {
    test('同一 instant 的年/月/月将不受来源 offset 影响', () {
      final instant = DateTime.utc(2022, 4, 20, 2, 24, 18);
      final results = <int, DlrResolvedCastTime>{
        for (final offset in <int>[480, 0, 330])
          offset: DlrCastTimeService.resolve(
            DlrCivilTime(
              instant: instant,
              sourceUtcOffsetMinutes: offset,
            ),
          ),
      };

      expect(results.values.map((e) => e.pillars.yearGanZhi).toSet(),
          hasLength(1));
      expect(results.values.map((e) => e.pillars.monthGanZhi).toSet(),
          hasLength(1));
      expect(
          results.values.map((e) => e.lunarInfo.yueJian).toSet(), hasLength(1));
      expect(
        results.values.map((e) => e.monthGeneralResolution.yueJiang).toSet(),
        <String>{'酉'},
      );
    });

    test('年/月柱在立春 absolute boundary 精确切换', () {
      final boundary = DateTime.utc(2026, 2, 3, 20, 2, 8);
      final before = DlrCastTimeService.resolve(
        DlrCivilTime(
          instant: boundary.subtract(const Duration(seconds: 1)),
          sourceUtcOffsetMinutes: 0,
        ),
      );
      final at = DlrCastTimeService.resolve(
        DlrCivilTime(
          instant: boundary,
          sourceUtcOffsetMinutes: 0,
        ),
      );

      expect(before.pillars.yearGanZhi, isNot(at.pillars.yearGanZhi));
      expect(before.pillars.monthGanZhi, isNot(at.pillars.monthGanZhi));
      expect(at.lunarInfo.solarTerm, '立春');
    });

    test('日柱按来源民用午夜，时干与该日干保持同一口径', () {
      final result = DlrCastTimeService.resolve(
        DlrCivilTime(
          instant: DateTime.utc(2026, 7, 7, 15, 30),
          sourceUtcOffsetMinutes: 480,
        ),
      );

      expect(result.civilTime.sourceWallTime.hour, 23);
      expect(result.pillars.hourZhi, '子');
      expect(
        result.pillars.hourGan,
        DlrPillars.expectedHourGanFor(
          dayGan: result.pillars.dayGan,
          hourZhi: '子',
        ),
      );
    });

    test('来源民用午夜整点切换日柱，子时干随新日干重算', () {
      final midnightInstant = DateTime.utc(2026, 7, 7, 16);
      final before = DlrCastTimeService.resolve(
        DlrCivilTime(
          instant: midnightInstant.subtract(const Duration(seconds: 1)),
          sourceUtcOffsetMinutes: 480,
        ),
      );
      final at = DlrCastTimeService.resolve(
        DlrCivilTime(
          instant: midnightInstant,
          sourceUtcOffsetMinutes: 480,
        ),
      );

      expect(before.civilTime.sourceWallTime.day, 7);
      expect(at.civilTime.sourceWallTime.day, 8);
      expect(before.pillars.dayGanZhi, isNot(at.pillars.dayGanZhi));
      expect(at.pillars.hourZhi, '子');
      expect(
        at.pillars.hourGan,
        DlrPillars.expectedHourGanFor(
          dayGan: at.pillars.dayGan,
          hourZhi: '子',
        ),
      );
    });
  });

  group('DlrPillars raw linkage', () {
    test('接受五虎遁与五鼠遁相符的四柱', () {
      expect(
        () => DlrPillars(
          yearGanZhi: '丙午',
          monthGanZhi: '壬辰',
          dayGanZhi: '壬戌',
          hourGanZhi: '辛亥',
        ).validateRawStemLinks(),
        returnsNormally,
      );
    });

    test('拒绝年/月或日/时干联动错误', () {
      expect(
        () => DlrPillars(
          yearGanZhi: '丙午',
          monthGanZhi: '庚辰',
          dayGanZhi: '壬戌',
          hourGanZhi: '辛亥',
        ).validateRawStemLinks(),
        throwsArgumentError,
      );
      expect(
        () => DlrPillars(
          yearGanZhi: '丙午',
          monthGanZhi: '壬辰',
          dayGanZhi: '壬戌',
          hourGanZhi: '己亥',
        ).validateRawStemLinks(),
        throwsArgumentError,
      );
    });
  });
}
