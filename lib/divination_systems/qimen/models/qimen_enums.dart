enum QimenJuMethod {
  chaiBu('chaiBu'),
  maoShan('maoShan'),
  zhiRun('zhiRun'),
  manual('manual');

  const QimenJuMethod(this.id);
  final String id;

  static QimenJuMethod fromId(String id) => QimenJuMethod.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门定局法: $id'),
      );
}

enum QimenTimeBasis {
  localCivil('localCivil'),
  beijing('beijing'),
  trueSolar('trueSolar');

  const QimenTimeBasis(this.id);
  final String id;

  static QimenTimeBasis fromId(String id) => QimenTimeBasis.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门时间基准: $id'),
      );
}

enum QimenDayBoundary {
  ziInitial('ziInitial'),
  midnight('midnight');

  const QimenDayBoundary(this.id);
  final String id;

  static QimenDayBoundary fromId(String id) =>
      QimenDayBoundary.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门换日规则: $id'),
      );
}

enum QimenHostingMode {
  kunTwo('kunTwo'),
  yangEightYinTwo('yangEightYinTwo');

  const QimenHostingMode(this.id);
  final String id;

  static QimenHostingMode fromId(String id) =>
      QimenHostingMode.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门寄宫规则: $id'),
      );
}

enum QimenHiddenStemMode {
  dutyDoorHourStem('dutyDoorHourStem'),
  doorOriginEarthStem('doorOriginEarthStem');

  const QimenHiddenStemMode(this.id);
  final String id;

  static QimenHiddenStemMode fromId(String id) =>
      QimenHiddenStemMode.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门暗干规则: $id'),
      );
}

enum QimenDun {
  yang('yang', '阳'),
  yin('yin', '阴');

  const QimenDun(this.id, this.label);
  final String id;
  final String label;

  static QimenDun fromId(String id) => QimenDun.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的阴阳遁: $id'),
      );
}

enum QimenYuan {
  upper('upper', '上元'),
  middle('middle', '中元'),
  lower('lower', '下元');

  const QimenYuan(this.id, this.label);
  final String id;
  final String label;

  static QimenYuan fromId(String id) => QimenYuan.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门三元: $id'),
      );
}

enum QimenQuestionCategory {
  general('general'),
  career('career'),
  wealth('wealth'),
  relationship('relationship'),
  health('health'),
  study('study'),
  travel('travel'),
  litigation('litigation');

  const QimenQuestionCategory(this.id);
  final String id;

  static QimenQuestionCategory fromId(String id) =>
      QimenQuestionCategory.values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw ArgumentError('未知的奇门问事类别: $id'),
      );
}
