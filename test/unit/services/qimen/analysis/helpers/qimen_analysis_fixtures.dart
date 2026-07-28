import 'dart:convert';

import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';

const qimenAnalysisPanEngineCommit = '7d226a690fa411ca1fe74f021c0fa54dca875f2c';
const qimenAnalysisPanSchemaVersion = 1;

/// Full schema-v1 result frozen from the sourced 2008 pan-engine case.
///
/// Analyzer goldens restore this JSON directly. They never recast the pan, so
/// random result IDs and later placement changes cannot move analysis output.
const fixedQimenAnalysisPanJson =
    r'''{"schemaVersion":1,"systemType":"qimen","id":"qimen-analysis-public-2008","castTime":"2008-11-04T04:30:00.000Z","castMethod":"time","lunarInfo":{"yueJian":"戌","riGan":"戊","riZhi":"申","riGanZhi":"戊申","hourGanZhi":"戊午","kongWang":["寅","卯"],"yearGanZhi":"戊子","monthGanZhi":"壬戌","solarTerm":"霜降"},"panParams":{"juMethod":"chaiBu","timeBasis":"beijing","sourceUtcOffsetMinutes":480,"longitude":null,"dayBoundary":"ziInitial","hostingMode":"kunTwo","hiddenStemMode":"dutyDoorHourStem","questionCategory":"general"},"temporalContext":{"originalTime":"2008-11-04T04:30:00.000Z","basisWallTime":"2008-11-04T12:30:00.000Z","effectivePanTime":"2008-11-04T12:30:00.000Z","timeBasis":"beijing","sourceUtcOffsetMinutes":480,"longitude":null,"standardMeridian":120.0,"longitudeCorrectionMinutes":0.0,"equationOfTimeMinutes":0.0,"totalCorrectionMinutes":0.0,"correctionAlgorithmVersion":"noaa-eot-v1","dayBoundary":"ziInitial","yearGanZhi":"戊子","monthGanZhi":"壬戌","dayGanZhi":"戊申","hourGanZhi":"戊午","previousSolarTerm":"寒露","previousSolarTermTime":"2008-10-08T05:56:38.000Z","currentSolarTerm":"霜降","currentSolarTermTime":"2008-10-23T09:08:39.000Z","nextSolarTerm":"立冬","nextSolarTermTime":"2008-11-07T09:10:34.000Z"},"juInfo":{"method":"chaiBu","dun":"yin","juNumber":2,"yuan":"lower","solarTerm":"霜降","effectiveSolarTerm":"霜降","symbolHead":"甲辰","chaoShenDays":0,"isReceivingQi":false,"isLeap":false,"derivation":["日柱戊申回退4日至符头甲辰","符头支辰定下元","精确交节后采用霜降阴遁局数表"]},"palaces":[{"number":1,"name":"坎一宫","trigram":"坎","direction":"北","element":"水","branches":["子"],"earthStem":"己","hostedEarthStem":null,"heavenStem":"乙","hostedHeavenStem":null,"star":"天冲","hostedStar":null,"door":"伤门","deity":"玄武","hiddenStem":"己","voidBranches":["子"],"isHorse":false,"marks":["空亡"]},{"number":2,"name":"坤二宫","trigram":"坤","direction":"西南","element":"土","branches":["未","申"],"earthStem":"戊","hostedEarthStem":"丁","heavenStem":"癸","hostedHeavenStem":null,"star":"天心","hostedStar":null,"door":"开门","deity":"值符","hiddenStem":"戊","voidBranches":[],"isHorse":true,"marks":["地盘寄宫","驿马"]},{"number":3,"name":"震三宫","trigram":"震","direction":"东","element":"木","branches":["卯"],"earthStem":"乙","hostedEarthStem":null,"heavenStem":"庚","hostedHeavenStem":null,"star":"天英","hostedStar":null,"door":"景门","deity":"六合","hiddenStem":"乙","voidBranches":[],"isHorse":false,"marks":[]},{"number":4,"name":"巽四宫","trigram":"巽","direction":"东南","element":"木","branches":["辰","巳"],"earthStem":"丙","hostedEarthStem":null,"heavenStem":"戊","hostedHeavenStem":"丁","star":"天芮","hostedStar":"天禽","door":"死门","deity":"太阴","hiddenStem":"丙","voidBranches":[],"isHorse":false,"marks":["天禽寄宫"]},{"number":5,"name":"中五宫","trigram":"中","direction":"中","element":"土","branches":[],"earthStem":"丁","hostedEarthStem":null,"heavenStem":"丁","hostedHeavenStem":null,"star":"天禽","hostedStar":null,"door":null,"deity":null,"hiddenStem":"丁","voidBranches":[],"isHorse":false,"marks":["中宫"]},{"number":6,"name":"乾六宫","trigram":"乾","direction":"西北","element":"金","branches":["戌","亥"],"earthStem":"癸","hostedEarthStem":null,"heavenStem":"辛","hostedHeavenStem":null,"star":"天任","hostedStar":null,"door":"生门","deity":"九地","hiddenStem":"癸","voidBranches":[],"isHorse":false,"marks":[]},{"number":7,"name":"兑七宫","trigram":"兑","direction":"西","element":"金","branches":["酉"],"earthStem":"壬","hostedEarthStem":null,"heavenStem":"己","hostedHeavenStem":null,"star":"天蓬","hostedStar":null,"door":"休门","deity":"九天","hiddenStem":"壬","voidBranches":[],"isHorse":false,"marks":[]},{"number":8,"name":"艮八宫","trigram":"艮","direction":"东北","element":"土","branches":["丑","寅"],"earthStem":"辛","hostedEarthStem":null,"heavenStem":"丙","hostedHeavenStem":null,"star":"天辅","hostedStar":null,"door":"杜门","deity":"白虎","hiddenStem":"辛","voidBranches":["丑"],"isHorse":false,"marks":["空亡"]},{"number":9,"name":"离九宫","trigram":"离","direction":"南","element":"火","branches":["午"],"earthStem":"庚","hostedEarthStem":null,"heavenStem":"壬","hostedHeavenStem":null,"star":"天柱","hostedStar":null,"door":"惊门","deity":"螣蛇","hiddenStem":"庚","voidBranches":[],"isHorse":false,"marks":[]}],"xunShou":"甲寅","xunHiddenStem":"癸","zhiFuStar":"天心","zhiFuPalace":2,"zhiShiDoor":"开门","zhiShiPalace":2,"kongWangBranches":["子","丑"],"horseBranch":"申","horsePalace":2,"derivationSteps":["生效排盘时间2008-11-04T12:30:00.000Z（beijing）","实际节气霜降，交节时刻2008-10-23T09:08:39.000Z","定局法chaiBu：有效节气霜降，阴遁2局、下元，符头甲辰，置闰否","日柱戊申回退4日至符头甲辰","符头支辰定下元","精确交节后采用霜降阴遁局数表","阴遁2局排地盘三奇六仪","中五寄2宫（kunTwo）","甲寅旬遁癸，天心值符落2宫","开门值使落2宫","暗干口径：dutyDoorHourStem","旬空子丑，驿马申落2宫"],"questionId":"","detailId":"","interpretationId":""}''';

Map<String, dynamic> fixedQimenAnalysisPanMap({
  QimenQuestionCategory category = QimenQuestionCategory.general,
}) {
  final json = Map<String, dynamic>.from(
    jsonDecode(fixedQimenAnalysisPanJson) as Map,
  );
  final params = Map<String, dynamic>.from(json['panParams'] as Map)
    ..['questionCategory'] = category.id;
  json['panParams'] = params;
  json['id'] = 'qimen-analysis-public-2008-${category.id}';
  return json;
}

QimenResult fixedQimenAnalysisResult({
  QimenQuestionCategory category = QimenQuestionCategory.general,
}) =>
    QimenResult.fromJson(fixedQimenAnalysisPanMap(category: category));

QimenResult mutatedQimenAnalysisResult(
  void Function(Map<String, dynamic> json) mutate, {
  QimenQuestionCategory category = QimenQuestionCategory.general,
}) {
  final json = fixedQimenAnalysisPanMap(category: category);
  mutate(json);
  return QimenResult.fromJson(json);
}

Map<String, dynamic> qimenAnalysisPalaceJson(
  Map<String, dynamic> json,
  int palaceNumber,
) =>
    (json['palaces'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((palace) => palace['number'] == palaceNumber);
