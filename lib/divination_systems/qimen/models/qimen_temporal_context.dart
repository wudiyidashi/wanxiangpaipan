import '../../../models/lunar_info.dart';
import 'qimen_enums.dart';

class QimenTemporalContext {
  const QimenTemporalContext({
    required this.originalTime,
    required this.basisWallTime,
    required this.effectivePanTime,
    required this.timeBasis,
    required this.sourceUtcOffsetMinutes,
    required this.longitude,
    required this.standardMeridian,
    required this.longitudeCorrectionMinutes,
    required this.equationOfTimeMinutes,
    required this.totalCorrectionMinutes,
    required this.correctionAlgorithmVersion,
    required this.dayBoundary,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.previousSolarTerm,
    required this.previousSolarTermTime,
    required this.currentSolarTerm,
    required this.currentSolarTermTime,
    required this.nextSolarTerm,
    required this.nextSolarTermTime,
  });

  /// Absolute cast instant. The JSON representation is always UTC.
  final DateTime originalTime;

  /// Wall-clock coordinates encoded in UTC fields for deterministic math.
  /// These are not absolute instants and must not be converted with [toUtc].
  final DateTime basisWallTime;
  final DateTime effectivePanTime;
  final QimenTimeBasis timeBasis;
  final int sourceUtcOffsetMinutes;
  final double? longitude;
  final double standardMeridian;
  final double longitudeCorrectionMinutes;
  final double equationOfTimeMinutes;
  final double totalCorrectionMinutes;
  final String correctionAlgorithmVersion;
  final QimenDayBoundary dayBoundary;
  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String hourGanZhi;
  final String previousSolarTerm;
  final DateTime previousSolarTermTime;
  final String currentSolarTerm;
  final DateTime currentSolarTermTime;
  final String nextSolarTerm;
  final DateTime nextSolarTermTime;

  LunarInfo toLunarInfo() => LunarInfo(
        yueJian: monthGanZhi.substring(1),
        riGan: dayGanZhi.substring(0, 1),
        riZhi: dayGanZhi.substring(1),
        riGanZhi: dayGanZhi,
        hourGanZhi: hourGanZhi,
        kongWang: const <String>[],
        yearGanZhi: yearGanZhi,
        monthGanZhi: monthGanZhi,
        solarTerm: currentSolarTerm,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'originalTime': originalTime.toUtc().toIso8601String(),
        'basisWallTime': basisWallTime.toIso8601String(),
        'effectivePanTime': effectivePanTime.toIso8601String(),
        'timeBasis': timeBasis.id,
        'sourceUtcOffsetMinutes': sourceUtcOffsetMinutes,
        'longitude': longitude,
        'standardMeridian': standardMeridian,
        'longitudeCorrectionMinutes': longitudeCorrectionMinutes,
        'equationOfTimeMinutes': equationOfTimeMinutes,
        'totalCorrectionMinutes': totalCorrectionMinutes,
        'correctionAlgorithmVersion': correctionAlgorithmVersion,
        'dayBoundary': dayBoundary.id,
        'yearGanZhi': yearGanZhi,
        'monthGanZhi': monthGanZhi,
        'dayGanZhi': dayGanZhi,
        'hourGanZhi': hourGanZhi,
        'previousSolarTerm': previousSolarTerm,
        'previousSolarTermTime': previousSolarTermTime.toIso8601String(),
        'currentSolarTerm': currentSolarTerm,
        'currentSolarTermTime': currentSolarTermTime.toIso8601String(),
        'nextSolarTerm': nextSolarTerm,
        'nextSolarTermTime': nextSolarTermTime.toIso8601String(),
      };

  factory QimenTemporalContext.fromJson(Map<String, dynamic> json) =>
      QimenTemporalContext(
        originalTime: DateTime.parse(json['originalTime'] as String).toUtc(),
        basisWallTime: DateTime.parse(json['basisWallTime'] as String),
        effectivePanTime: DateTime.parse(json['effectivePanTime'] as String),
        timeBasis: QimenTimeBasis.fromId(json['timeBasis'] as String),
        sourceUtcOffsetMinutes: json['sourceUtcOffsetMinutes'] as int,
        longitude: (json['longitude'] as num?)?.toDouble(),
        standardMeridian: (json['standardMeridian'] as num).toDouble(),
        longitudeCorrectionMinutes:
            (json['longitudeCorrectionMinutes'] as num).toDouble(),
        equationOfTimeMinutes:
            (json['equationOfTimeMinutes'] as num).toDouble(),
        totalCorrectionMinutes:
            (json['totalCorrectionMinutes'] as num).toDouble(),
        correctionAlgorithmVersion:
            json['correctionAlgorithmVersion'] as String,
        dayBoundary: QimenDayBoundary.fromId(json['dayBoundary'] as String),
        yearGanZhi: json['yearGanZhi'] as String,
        monthGanZhi: json['monthGanZhi'] as String,
        dayGanZhi: json['dayGanZhi'] as String,
        hourGanZhi: json['hourGanZhi'] as String,
        previousSolarTerm: json['previousSolarTerm'] as String,
        previousSolarTermTime:
            DateTime.parse(json['previousSolarTermTime'] as String),
        currentSolarTerm: json['currentSolarTerm'] as String,
        currentSolarTermTime:
            DateTime.parse(json['currentSolarTermTime'] as String),
        nextSolarTerm: json['nextSolarTerm'] as String,
        nextSolarTermTime: DateTime.parse(json['nextSolarTermTime'] as String),
      );
}
