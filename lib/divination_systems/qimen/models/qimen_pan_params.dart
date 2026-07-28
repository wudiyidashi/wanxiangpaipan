import 'qimen_enums.dart';

class QimenPanParams {
  const QimenPanParams({
    this.juMethod = QimenJuMethod.chaiBu,
    this.timeBasis = QimenTimeBasis.localCivil,
    this.sourceUtcOffsetMinutes,
    this.longitude,
    this.dayBoundary = QimenDayBoundary.ziInitial,
    this.hostingMode = QimenHostingMode.kunTwo,
    this.hiddenStemMode = QimenHiddenStemMode.dutyDoorHourStem,
    this.questionCategory = QimenQuestionCategory.general,
  });

  final QimenJuMethod juMethod;
  final QimenTimeBasis timeBasis;
  final int? sourceUtcOffsetMinutes;
  final double? longitude;
  final QimenDayBoundary dayBoundary;
  final QimenHostingMode hostingMode;
  final QimenHiddenStemMode hiddenStemMode;
  final QimenQuestionCategory questionCategory;

  factory QimenPanParams.fromJson(Map<String, dynamic> json) {
    const allowedKeys = <String>{
      'juMethod',
      'timeBasis',
      'sourceUtcOffsetMinutes',
      'longitude',
      'dayBoundary',
      'hostingMode',
      'hiddenStemMode',
      'questionCategory',
    };
    if (json.keys.any((key) => !allowedKeys.contains(key))) {
      throw ArgumentError('奇门参数包含未知字段');
    }
    T? optional<T>(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! T) {
        throw ArgumentError('奇门参数 $key 类型不合法');
      }
      return value;
    }

    final juMethod = QimenJuMethod.fromId(
      optional<String>('juMethod') ?? QimenJuMethod.chaiBu.id,
    );
    final timeBasis = QimenTimeBasis.fromId(
      optional<String>('timeBasis') ?? QimenTimeBasis.localCivil.id,
    );
    final offset = optional<int>('sourceUtcOffsetMinutes');
    if (offset != null && (offset < -840 || offset > 840)) {
      throw ArgumentError('sourceUtcOffsetMinutes 超出合法范围');
    }
    final rawLongitude = json['longitude'];
    if (rawLongitude != null && rawLongitude is! num) {
      throw ArgumentError('奇门参数 longitude 类型不合法');
    }
    final longitude = (rawLongitude as num?)?.toDouble();
    if (longitude != null &&
        (!longitude.isFinite || longitude < -180 || longitude > 180)) {
      throw ArgumentError('longitude 必须是 [-180, 180] 内的有限数');
    }
    if (timeBasis == QimenTimeBasis.trueSolar &&
        (offset == null || longitude == null)) {
      throw ArgumentError('真太阳时必须提供 offset 与经度');
    }
    if (timeBasis != QimenTimeBasis.trueSolar && longitude != null) {
      throw ArgumentError('longitude 仅用于真太阳时');
    }
    if (timeBasis == QimenTimeBasis.beijing &&
        offset != null &&
        offset != 480) {
      throw ArgumentError('北京时间的 offset 必须为 480');
    }

    return QimenPanParams(
      juMethod: juMethod,
      timeBasis: timeBasis,
      sourceUtcOffsetMinutes: offset,
      longitude: longitude,
      dayBoundary: QimenDayBoundary.fromId(
        optional<String>('dayBoundary') ?? QimenDayBoundary.ziInitial.id,
      ),
      hostingMode: QimenHostingMode.fromId(
        optional<String>('hostingMode') ?? QimenHostingMode.kunTwo.id,
      ),
      hiddenStemMode: QimenHiddenStemMode.fromId(
        optional<String>('hiddenStemMode') ??
            QimenHiddenStemMode.dutyDoorHourStem.id,
      ),
      questionCategory: QimenQuestionCategory.fromId(
        optional<String>('questionCategory') ??
            QimenQuestionCategory.general.id,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'juMethod': juMethod.id,
        'timeBasis': timeBasis.id,
        'sourceUtcOffsetMinutes': sourceUtcOffsetMinutes,
        'longitude': longitude,
        'dayBoundary': dayBoundary.id,
        'hostingMode': hostingMode.id,
        'hiddenStemMode': hiddenStemMode.id,
        'questionCategory': questionCategory.id,
      };

  QimenPanParams copyWith({
    QimenJuMethod? juMethod,
    QimenTimeBasis? timeBasis,
    int? sourceUtcOffsetMinutes,
    double? longitude,
    QimenDayBoundary? dayBoundary,
    QimenHostingMode? hostingMode,
    QimenHiddenStemMode? hiddenStemMode,
    QimenQuestionCategory? questionCategory,
  }) =>
      QimenPanParams(
        juMethod: juMethod ?? this.juMethod,
        timeBasis: timeBasis ?? this.timeBasis,
        sourceUtcOffsetMinutes:
            sourceUtcOffsetMinutes ?? this.sourceUtcOffsetMinutes,
        longitude: longitude ?? this.longitude,
        dayBoundary: dayBoundary ?? this.dayBoundary,
        hostingMode: hostingMode ?? this.hostingMode,
        hiddenStemMode: hiddenStemMode ?? this.hiddenStemMode,
        questionCategory: questionCategory ?? this.questionCategory,
      );
}
