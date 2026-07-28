import 'dart:math' as math;

import 'package:lunar/lunar.dart';

import '../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../divination_systems/qimen/models/qimen_pan_params.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';
import '../shared/tiangan_dizhi_service.dart';

class QimenTimeService {
  QimenTimeService._();

  static const String correctionAlgorithmVersion = 'noaa-eot-v1';
  static const int _beijingUtcOffsetMinutes = 480;

  static QimenTemporalContext resolve(
    DateTime originalTime,
    QimenPanParams params,
  ) {
    _validateParams(params);
    final offset = switch (params.timeBasis) {
      QimenTimeBasis.beijing => _beijingUtcOffsetMinutes,
      QimenTimeBasis.localCivil => params.sourceUtcOffsetMinutes ??
          originalTime.toLocal().timeZoneOffset.inMinutes,
      QimenTimeBasis.trueSolar => params.sourceUtcOffsetMinutes!,
    };
    final wallTime = _wallTimeAtOffset(originalTime, offset);
    final standardMeridian = offset / 60 * 15.0;
    final longitudeCorrection = params.timeBasis == QimenTimeBasis.trueSolar
        ? 4 * (params.longitude! - standardMeridian)
        : 0.0;
    final equationOfTime = params.timeBasis == QimenTimeBasis.trueSolar
        ? _equationOfTime(wallTime)
        : 0.0;
    final totalCorrection = longitudeCorrection + equationOfTime;
    final effectiveTime = wallTime.add(_minutes(totalCorrection));
    final beijingLunarTime = _wallTimeAtOffset(
      originalTime,
      _beijingUtcOffsetMinutes,
    );

    return _resolveWallFacts(
      originalTime: originalTime,
      wallTime: wallTime,
      effectiveTime: effectiveTime,
      beijingLunarTime: beijingLunarTime,
      params: params,
      offset: offset,
      standardMeridian: standardMeridian,
      longitudeCorrection: longitudeCorrection,
      equationOfTime: equationOfTime,
      totalCorrection: totalCorrection,
    );
  }

  static QimenTemporalContext _resolveWallFacts({
    required DateTime originalTime,
    required DateTime wallTime,
    required DateTime effectiveTime,
    required DateTime beijingLunarTime,
    required QimenPanParams params,
    required int offset,
    required double standardMeridian,
    required double longitudeCorrection,
    required double equationOfTime,
    required double totalCorrection,
  }) {
    // The lunar package publishes exact year/month and solar-term boundaries
    // in Beijing civil coordinates. Day and hour pillars remain tied to the
    // selected local/true-solar wall clock.
    final absoluteLunar = Solar.fromDate(beijingLunarTime).getLunar();
    final effectiveLunar = Solar.fromDate(effectiveTime).getLunar();
    final dayGanZhi = params.dayBoundary == QimenDayBoundary.ziInitial
        ? effectiveLunar.getDayInGanZhiExact()
        : effectiveLunar.getDayInGanZhiExact2();
    final hourGanZhi =
        _hourGanZhi(dayGanZhi.substring(0, 1), effectiveTime.hour);
    final current = absoluteLunar.getPrevJieQi(false);
    final next = absoluteLunar.getNextJieQi(false);
    final beforeCurrent = Solar.fromDate(
      _solarToBeijingWall(current.getSolar()).subtract(
        const Duration(seconds: 1),
      ),
    ).getLunar().getPrevJieQi(false);

    return QimenTemporalContext(
      originalTime: originalTime,
      basisWallTime: wallTime,
      effectivePanTime: effectiveTime,
      timeBasis: params.timeBasis,
      sourceUtcOffsetMinutes: offset,
      longitude: params.longitude,
      standardMeridian: standardMeridian,
      longitudeCorrectionMinutes: longitudeCorrection,
      equationOfTimeMinutes: equationOfTime,
      totalCorrectionMinutes: totalCorrection,
      correctionAlgorithmVersion: correctionAlgorithmVersion,
      dayBoundary: params.dayBoundary,
      yearGanZhi: absoluteLunar.getYearInGanZhiExact(),
      monthGanZhi: absoluteLunar.getMonthInGanZhiExact(),
      dayGanZhi: dayGanZhi,
      hourGanZhi: hourGanZhi,
      previousSolarTerm: beforeCurrent.getName(),
      previousSolarTermTime: _solarTermToEffectiveWall(
        beforeCurrent.getSolar(),
        params: params,
        offset: offset,
        standardMeridian: standardMeridian,
      ),
      currentSolarTerm: current.getName(),
      currentSolarTermTime: _solarTermToEffectiveWall(
        current.getSolar(),
        params: params,
        offset: offset,
        standardMeridian: standardMeridian,
      ),
      nextSolarTerm: next.getName(),
      nextSolarTermTime: _solarTermToEffectiveWall(
        next.getSolar(),
        params: params,
        offset: offset,
        standardMeridian: standardMeridian,
      ),
    );
  }

  static void _validateParams(QimenPanParams params) {
    final offset = params.sourceUtcOffsetMinutes;
    if (offset != null && (offset < -840 || offset > 840)) {
      throw ArgumentError('sourceUtcOffsetMinutes 超出合法范围');
    }
    final longitude = params.longitude;
    if (longitude != null &&
        (!longitude.isFinite || longitude < -180 || longitude > 180)) {
      throw ArgumentError('longitude 必须是 [-180, 180] 内的有限数');
    }
    if (params.timeBasis == QimenTimeBasis.trueSolar &&
        (offset == null || longitude == null)) {
      throw ArgumentError('真太阳时必须提供 offset 与经度');
    }
    if (params.timeBasis != QimenTimeBasis.trueSolar && longitude != null) {
      throw ArgumentError('longitude 仅用于真太阳时');
    }
    if (params.timeBasis == QimenTimeBasis.beijing &&
        offset != null &&
        offset != _beijingUtcOffsetMinutes) {
      throw ArgumentError('北京时间的 offset 必须为 480');
    }
  }

  static DateTime _wallTimeAtOffset(DateTime instant, int offsetMinutes) {
    final shifted = instant.toUtc().add(Duration(minutes: offsetMinutes));
    return DateTime.utc(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  static DateTime _solarTermToEffectiveWall(
    Solar solar, {
    required QimenPanParams params,
    required int offset,
    required double standardMeridian,
  }) {
    final beijingWall = _solarToBeijingWall(solar);
    final instant = beijingWall.subtract(
      const Duration(minutes: _beijingUtcOffsetMinutes),
    );
    final targetWall = _wallTimeAtOffset(instant, offset);
    if (params.timeBasis != QimenTimeBasis.trueSolar) return targetWall;

    final longitudeCorrection = 4 * (params.longitude! - standardMeridian);
    return targetWall.add(
      _minutes(longitudeCorrection + _equationOfTime(targetWall)),
    );
  }

  static DateTime _solarToBeijingWall(Solar solar) => DateTime.utc(
        solar.getYear(),
        solar.getMonth(),
        solar.getDay(),
        solar.getHour(),
        solar.getMinute(),
        solar.getSecond(),
      );

  static Duration _minutes(double value) => Duration(
        microseconds: (value * 60 * Duration.microsecondsPerSecond).round(),
      );

  static String _hourGanZhi(String dayGan, int hour) {
    final branchIndex = ((hour + 1) ~/ 2) % 12;
    final dayGanIndex = TianGanDiZhiService.getTianGanIndex(dayGan);
    if (dayGanIndex < 0) throw ArgumentError('非法日干: $dayGan');
    final stemIndex = (dayGanIndex % 5 * 2 + branchIndex) % 10;
    return '${TianGanDiZhiService.tianGan[stemIndex]}'
        '${TianGanDiZhiService.diZhi[branchIndex]}';
  }

  static double _equationOfTime(DateTime wallTime) {
    final dayOfYear =
        wallTime.difference(DateTime.utc(wallTime.year, 1, 1)).inDays + 1;
    final fractionalHour =
        wallTime.hour + wallTime.minute / 60 + wallTime.second / 3600;
    final gamma =
        2 * math.pi / 365 * (dayOfYear - 1 + (fractionalHour - 12) / 24);
    return 229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));
  }
}
