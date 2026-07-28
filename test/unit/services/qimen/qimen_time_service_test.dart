import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_pan_params.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_time_service.dart';

void main() {
  group('QimenTimeService', () {
    test('Beijing basis preserves the instant and freezes UTC+8 wall time', () {
      final original = DateTime.utc(2026, 7, 7, 0, 30);
      final context = QimenTimeService.resolve(
        original,
        const QimenPanParams(timeBasis: QimenTimeBasis.beijing),
      );

      expect(context.originalTime, original);
      expect(context.sourceUtcOffsetMinutes, 480);
      expect(context.basisWallTime.hour, 8);
      expect(context.effectivePanTime, context.basisWallTime);
      expect(context.totalCorrectionMinutes, 0);
    });

    test('local civil defaults to the input device offset and wall clock', () {
      final original = DateTime(2026, 7, 7, 10, 15, 30);
      final context = QimenTimeService.resolve(
        original,
        const QimenPanParams(),
      );

      expect(
        context.sourceUtcOffsetMinutes,
        original.timeZoneOffset.inMinutes,
      );
      expect(
        (
          context.basisWallTime.year,
          context.basisWallTime.month,
          context.basisWallTime.day,
          context.basisWallTime.hour,
          context.basisWallTime.minute,
          context.basisWallTime.second,
        ),
        (
          original.year,
          original.month,
          original.day,
          original.hour,
          original.minute,
          original.second,
        ),
      );
    });

    test('UTC input still defaults local-civil mode to the device offset', () {
      final original = DateTime.utc(2026, 7, 7, 2, 15, 30);
      final local = original.toLocal();
      final context = QimenTimeService.resolve(
        original,
        const QimenPanParams(),
      );

      expect(
        context.sourceUtcOffsetMinutes,
        local.timeZoneOffset.inMinutes,
      );
      expect(
        (
          context.basisWallTime.year,
          context.basisWallTime.month,
          context.basisWallTime.day,
          context.basisWallTime.hour,
          context.basisWallTime.minute,
          context.basisWallTime.second,
        ),
        (
          local.year,
          local.month,
          local.day,
          local.hour,
          local.minute,
          local.second,
        ),
      );
    });

    test('true solar applies longitude and versioned NOAA equation-of-time',
        () {
      final context = QimenTimeService.resolve(
        DateTime.utc(2026, 7, 7, 4),
        const QimenPanParams(
          timeBasis: QimenTimeBasis.trueSolar,
          sourceUtcOffsetMinutes: 480,
          longitude: 116.4,
        ),
      );

      expect(context.standardMeridian, 120);
      expect(context.longitudeCorrectionMinutes, closeTo(-14.4, 0.0001));
      expect(context.correctionAlgorithmVersion, 'noaa-eot-v1');
      expect(
        context.totalCorrectionMinutes,
        closeTo(
          context.longitudeCorrectionMinutes + context.equationOfTimeMinutes,
          0.0001,
        ),
      );
      expect(context.effectivePanTime, isNot(context.basisWallTime));
    });

    test('true-solar term coordinate uses the same correction at boundary', () {
      final boundary = DateTime.utc(2026, 2, 3, 20, 2, 8);
      final context = QimenTimeService.resolve(
        boundary,
        const QimenPanParams(
          timeBasis: QimenTimeBasis.trueSolar,
          sourceUtcOffsetMinutes: 330,
          longitude: 77,
        ),
      );

      expect(context.currentSolarTerm, '立春');
      expect(context.currentSolarTermTime, context.effectivePanTime);
    });

    test('23:00 uses different day pillars for zi-initial and midnight', () {
      final time = DateTime.utc(2026, 7, 7, 15, 30); // Beijing 23:30.
      final ziInitial = QimenTimeService.resolve(
        time,
        const QimenPanParams(
          timeBasis: QimenTimeBasis.beijing,
          dayBoundary: QimenDayBoundary.ziInitial,
        ),
      );
      final midnight = QimenTimeService.resolve(
        time,
        const QimenPanParams(
          timeBasis: QimenTimeBasis.beijing,
          dayBoundary: QimenDayBoundary.midnight,
        ),
      );

      expect(ziInitial.dayGanZhi, isNot(midnight.dayGanZhi));
      expect(ziInitial.hourGanZhi.substring(1), '子');
      expect(midnight.hourGanZhi.substring(1), '子');
      expect(ziInitial.hourGanZhi, isNot(midnight.hourGanZhi));
    });

    test('one absolute Li Chun boundary is invariant across target offsets',
        () {
      // lunar 1.7.8: 2026 Li Chun is 2026-02-04 04:02:08 at UTC+8.
      final boundary = DateTime.utc(2026, 2, 3, 20, 2, 8);
      final cases = <({int offset, DateTime termWall})>[
        (offset: 480, termWall: DateTime.utc(2026, 2, 4, 4, 2, 8)),
        (offset: 0, termWall: DateTime.utc(2026, 2, 3, 20, 2, 8)),
        (offset: 330, termWall: DateTime.utc(2026, 2, 4, 1, 32, 8)),
      ];
      final yearsBefore = <String>{};
      final yearsAt = <String>{};
      final monthsBefore = <String>{};
      final monthsAt = <String>{};

      for (final testCase in cases) {
        final params = QimenPanParams(
          sourceUtcOffsetMinutes: testCase.offset,
        );
        final before = QimenTimeService.resolve(
          boundary.subtract(const Duration(seconds: 1)),
          params,
        );
        final at = QimenTimeService.resolve(boundary, params);
        final after = QimenTimeService.resolve(
          boundary.add(const Duration(seconds: 1)),
          params,
        );

        expect(before.currentSolarTerm, '大寒', reason: '${testCase.offset}');
        expect(at.currentSolarTerm, '立春', reason: '${testCase.offset}');
        expect(after.currentSolarTerm, '立春', reason: '${testCase.offset}');
        expect(
          at.currentSolarTermTime,
          testCase.termWall,
          reason: '${testCase.offset}',
        );
        expect(at.yearGanZhi, isNot(before.yearGanZhi));
        expect(at.monthGanZhi, isNot(before.monthGanZhi));
        yearsBefore.add(before.yearGanZhi);
        yearsAt.add(at.yearGanZhi);
        monthsBefore.add(before.monthGanZhi);
        monthsAt.add(at.monthGanZhi);
      }

      expect(yearsBefore, hasLength(1));
      expect(yearsAt, hasLength(1));
      expect(monthsBefore, hasLength(1));
      expect(monthsAt, hasLength(1));
    });

    test('rejects non-finite true-solar longitude in typed calls', () {
      for (final longitude in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => QimenTimeService.resolve(
            DateTime.utc(2026, 7, 7),
            QimenPanParams(
              timeBasis: QimenTimeBasis.trueSolar,
              sourceUtcOffsetMinutes: 480,
              longitude: longitude,
            ),
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
