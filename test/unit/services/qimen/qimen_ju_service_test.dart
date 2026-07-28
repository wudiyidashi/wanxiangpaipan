import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_temporal_context.dart';
import 'package:wanxiang_paipan/domain/services/qimen/chai_bu_ju_strategy.dart';
import 'package:wanxiang_paipan/domain/services/qimen/mao_shan_ju_strategy.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_constants.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_time_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/zhi_run_ju_strategy.dart';

QimenTemporalContext _context({
  required String solarTerm,
  required DateTime termTime,
  required DateTime effectiveTime,
  String dayGanZhi = '甲子',
  QimenDayBoundary dayBoundary = QimenDayBoundary.ziInitial,
}) =>
    QimenTemporalContext(
      originalTime: effectiveTime,
      basisWallTime: effectiveTime,
      effectivePanTime: effectiveTime,
      timeBasis: QimenTimeBasis.beijing,
      sourceUtcOffsetMinutes: 480,
      longitude: null,
      standardMeridian: 120,
      longitudeCorrectionMinutes: 0,
      equationOfTimeMinutes: 0,
      totalCorrectionMinutes: 0,
      correctionAlgorithmVersion: 'noaa-eot-v1',
      dayBoundary: dayBoundary,
      yearGanZhi: '乙巳',
      monthGanZhi: '戊子',
      dayGanZhi: dayGanZhi,
      hourGanZhi: '甲子',
      previousSolarTerm: '大雪',
      previousSolarTermTime: termTime.subtract(const Duration(days: 15)),
      currentSolarTerm: solarTerm,
      currentSolarTermTime: termTime,
      nextSolarTerm: '小寒',
      nextSolarTermTime: termTime.add(const Duration(days: 15)),
    );

void main() {
  group('ChaiBuJuStrategy', () {
    test('all 24 term rows use the one shared ju table', () {
      const strategy = ChaiBuJuStrategy();
      for (final term in QimenConstants.solarTerms) {
        final info = strategy.resolve(_context(
          solarTerm: term,
          termTime: DateTime.utc(2026, 1, 1),
          effectiveTime: DateTime.utc(2026, 1, 2),
        ));
        expect(info.yuan, QimenYuan.upper, reason: term);
        expect(
          info.juNumber,
          QimenConstants.juBySolarTerm[term]![0],
          reason: term,
        );
      }
    });

    test('symbol-head branch groups select upper, middle, and lower yuan', () {
      const cases = <String, QimenYuan>{
        '甲子': QimenYuan.upper,
        '甲寅': QimenYuan.middle,
        '甲辰': QimenYuan.lower,
      };
      for (final entry in cases.entries) {
        final info = const ChaiBuJuStrategy().resolve(_context(
          solarTerm: '冬至',
          termTime: DateTime.utc(2026, 1, 1),
          effectiveTime: DateTime.utc(2026, 1, 2),
          dayGanZhi: entry.key,
        ));
        expect(info.yuan, entry.value, reason: entry.key);
      }
    });
  });

  group('MaoShanJuStrategy', () {
    test('60-double-hour boundaries switch yuan at second precision', () {
      final start = DateTime.utc(2026, 1, 1, 11);
      const strategy = MaoShanJuStrategy();
      QimenYuan at(Duration elapsed) => strategy
          .resolve(_context(
            solarTerm: '冬至',
            termTime: start.add(const Duration(minutes: 35)),
            effectiveTime: start.add(elapsed),
          ))
          .yuan;

      expect(at(const Duration(hours: 119, minutes: 59, seconds: 59)),
          QimenYuan.upper);
      expect(at(const Duration(hours: 120)), QimenYuan.middle);
      expect(at(const Duration(hours: 239, minutes: 59, seconds: 59)),
          QimenYuan.middle);
      expect(at(const Duration(hours: 240)), QimenYuan.lower);
    });

    test('00:xx solar term starts its Mao Shan double-hour at prior 23:00', () {
      final termTime = DateTime.utc(2026, 1, 2, 0, 35);
      final info = const MaoShanJuStrategy().resolve(_context(
        solarTerm: '冬至',
        termTime: termTime,
        effectiveTime: DateTime.utc(2026, 1, 1, 23),
      ));

      expect(info.yuan, QimenYuan.upper);
      expect(info.derivation.first, contains('2026-01-01T23:00:00'));
      expect(info.derivation.last, contains('累计0小时'));
    });
  });

  group('ZhiRunJuStrategy sourced leap cycles', () {
    const strategy = ZhiRunJuStrategy();
    QimenTemporalContext context2025(int day) => QimenTimeService.resolve(
          DateTime.utc(2025, 6, day, 4),
          const QimenPanParams(timeBasis: QimenTimeBasis.beijing),
        );

    test('2025 cycle remains aligned before, during, and after leap', () {
      final before = strategy.resolve(context2025(8));
      final leap = strategy.resolve(context2025(9));
      final acrossSolstice = strategy.resolve(context2025(21));
      final after = strategy.resolve(context2025(24));

      expect(before.isLeap, false);
      expect(before.effectiveSolarTerm, '芒种');
      expect(leap.isLeap, true);
      expect(leap.effectiveSolarTerm, '芒种');
      expect(acrossSolstice.solarTerm, '夏至');
      expect(acrossSolstice.effectiveSolarTerm, '芒种');
      expect(after.isLeap, false);
      expect(after.effectiveSolarTerm, '夏至');
      expect(leap.chaoShenDays, greaterThan(9));
    });

    test('1898 sourced Daxue cycle repeats all three yuan before realignment',
        () {
      // Source: 陈炳聿按《图解详述奇门遁甲置润法定局排盘》, 2019-01-05.
      // https://www.sohu.com/a/286929542_488508 (accessed 2026-07-28).
      // The source calls Dec 7 the inclusive eleventh day; this model stores
      // ten complete elapsed days from the Nov 27 symbol-head boundary.
      void expectCase({
        required DateTime instant,
        required String solarTerm,
        required String effectiveSolarTerm,
        required QimenDun dun,
        required int juNumber,
        required QimenYuan yuan,
        required bool isLeap,
        required String symbolHead,
        required bool isReceivingQi,
        int chaoShenDays = 10,
      }) {
        final temporal = QimenTimeService.resolve(
          instant,
          const QimenPanParams(timeBasis: QimenTimeBasis.beijing),
        );
        final info = strategy.resolve(temporal);

        expect(temporal.currentSolarTerm, solarTerm, reason: '$instant');
        expect(info.effectiveSolarTerm, effectiveSolarTerm, reason: '$instant');
        expect(info.dun, dun, reason: '$instant');
        expect(info.juNumber, juNumber, reason: '$instant');
        expect(info.yuan, yuan, reason: '$instant');
        expect(info.isLeap, isLeap, reason: '$instant');
        expect(info.symbolHead, symbolHead, reason: '$instant');
        expect(info.chaoShenDays, chaoShenDays, reason: '$instant');
        expect(info.isReceivingQi, isReceivingQi, reason: '$instant');
      }

      expectCase(
        instant: DateTime.utc(1898, 11, 27, 4),
        solarTerm: '小雪',
        effectiveSolarTerm: '大雪',
        dun: QimenDun.yin,
        juNumber: 4,
        yuan: QimenYuan.upper,
        isLeap: false,
        symbolHead: '甲午',
        isReceivingQi: false,
      );
      expectCase(
        instant: DateTime.utc(1898, 12, 12, 4),
        solarTerm: '大雪',
        effectiveSolarTerm: '大雪',
        dun: QimenDun.yin,
        juNumber: 4,
        yuan: QimenYuan.upper,
        isLeap: true,
        symbolHead: '己酉',
        isReceivingQi: false,
      );
      expectCase(
        instant: DateTime.utc(1898, 12, 17, 4),
        solarTerm: '大雪',
        effectiveSolarTerm: '大雪',
        dun: QimenDun.yin,
        juNumber: 7,
        yuan: QimenYuan.middle,
        isLeap: true,
        symbolHead: '甲寅',
        isReceivingQi: false,
      );
      expectCase(
        instant: DateTime.utc(1898, 12, 22, 4),
        solarTerm: '冬至',
        effectiveSolarTerm: '大雪',
        dun: QimenDun.yin,
        juNumber: 1,
        yuan: QimenYuan.lower,
        isLeap: true,
        symbolHead: '己未',
        isReceivingQi: false,
      );
      expectCase(
        instant: DateTime.utc(1898, 12, 27, 4),
        solarTerm: '冬至',
        effectiveSolarTerm: '冬至',
        dun: QimenDun.yang,
        juNumber: 1,
        yuan: QimenYuan.upper,
        isLeap: false,
        symbolHead: '甲子',
        isReceivingQi: true,
        chaoShenDays: 0,
      );
    });

    test('zi-initial starts the sourced cycle one hour before midnight', () {
      final instant = DateTime.utc(1898, 11, 26, 15, 30);
      QimenTemporalContext context(QimenDayBoundary boundary) =>
          QimenTimeService.resolve(
            instant,
            QimenPanParams(
              timeBasis: QimenTimeBasis.beijing,
              dayBoundary: boundary,
            ),
          );

      final ziInitial = strategy.resolve(context(QimenDayBoundary.ziInitial));
      final midnight = strategy.resolve(context(QimenDayBoundary.midnight));

      expect(ziInitial.effectiveSolarTerm, '大雪');
      expect(ziInitial.yuan, QimenYuan.upper);
      expect(ziInitial.symbolHead, '甲午');
      expect(midnight.effectiveSolarTerm, '小雪');
      expect(midnight.yuan, QimenYuan.lower);
      expect(midnight.symbolHead, '己丑');
    });

    test('post-solstice leap term stays invariant across target offsets', () {
      final instant = DateTime.utc(1898, 12, 22, 4);
      for (final offset in <int>[0, 330, 480]) {
        final temporal = QimenTimeService.resolve(
          instant,
          QimenPanParams(sourceUtcOffsetMinutes: offset),
        );
        final info = strategy.resolve(temporal);

        expect(temporal.previousSolarTerm, '大雪', reason: '$offset');
        expect(info.effectiveSolarTerm, '大雪', reason: '$offset');
        expect(info.isLeap, true, reason: '$offset');
      }
    });
  });
}
