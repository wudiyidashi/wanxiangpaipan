import '../models/qimen_rule_models.dart';
import 'qimen_source_catalog.dart';

class QimenStemResponseSpec {
  const QimenStemResponseSpec({
    required this.ruleId,
    required this.heavenStem,
    required this.earthStem,
    required this.sourceWitnessPair,
    required this.sourceTerm,
    required this.displayTerm,
    required this.claimSummary,
    required this.sourceIds,
  });

  final String ruleId;
  final String heavenStem;
  final String earthStem;
  final String sourceWitnessPair;
  final String sourceTerm;
  final String displayTerm;
  final String claimSummary;
  final List<String> sourceIds;
}

class QimenFormationSpec {
  const QimenFormationSpec({
    required this.ruleId,
    this.heavenStem,
    this.earthStem,
    this.door,
    this.allowedDoors = const <String>[],
    this.deity,
    this.palaceNumber,
    this.heavenMatchesDayStem = false,
    this.earthMatchesDayStem = false,
    this.heavenMatchesXunHiddenStem = false,
    this.earthMatchesXunHiddenStem = false,
  });

  final String ruleId;
  final String? heavenStem;
  final String? earthStem;
  final String? door;
  final List<String> allowedDoors;
  final String? deity;
  final int? palaceNumber;
  final bool heavenMatchesDayStem;
  final bool earthMatchesDayStem;
  final bool heavenMatchesXunHiddenStem;
  final bool earthMatchesXunHiddenStem;
}

class QimenRuleSet {
  QimenRuleSet({
    required this.ruleSetId,
    required this.version,
    required List<QimenRuleDefinition> rules,
  }) : rules = List<QimenRuleDefinition>.unmodifiable(rules);

  final String ruleSetId;
  final String version;
  final List<QimenRuleDefinition> rules;
}

class QimenRuleCatalog {
  QimenRuleCatalog._();

  static const String ruleSetId = 'qimen-shijia-zhuanpan-analysis';
  static const String v1 = 'v1';
  static const String current = v1;

  static const String inputIntegrity = 'QMV1-I-INTEGRITY';
  static const String focusSelf = 'QMV1-C-FOCUS-SELF';
  static const String focusMatter = 'QMV1-C-FOCUS-MATTER';
  static const String focusGeneral = 'QMV1-C-FOCUS-GENERAL';
  static const String focusCareer = 'QMV1-C-FOCUS-CAREER';
  static const String focusWealth = 'QMV1-C-FOCUS-WEALTH';
  static const String focusRelationship = 'QMV1-C-FOCUS-RELATIONSHIP';
  static const String focusHealth = 'QMV1-C-FOCUS-HEALTH';
  static const String focusStudy = 'QMV1-C-FOCUS-STUDY';
  static const String focusTravel = 'QMV1-C-FOCUS-TRAVEL';
  static const String focusLitigation = 'QMV1-C-FOCUS-LITIGATION';

  static const String starStateWang = 'QMV1-F-STAR-STATE-WANG';
  static const String starStateXiang = 'QMV1-F-STAR-STATE-XIANG';
  static const String starStateXiu = 'QMV1-F-STAR-STATE-XIU';
  static const String starStateQiu = 'QMV1-F-STAR-STATE-QIU';
  static const String starStateFei = 'QMV1-F-STAR-STATE-FEI';
  static const String doorSeasonWang = 'QMV1-F-DOOR-SEASON-WANG';
  static const String doorSeasonXiang = 'QMV1-F-DOOR-SEASON-XIANG';
  static const String doorSeasonXiu = 'QMV1-F-DOOR-SEASON-XIU';
  static const String doorSeasonQiu = 'QMV1-F-DOOR-SEASON-QIU';
  static const String doorSeasonFei = 'QMV1-F-DOOR-SEASON-FEI';
  static const String doorStateSame = 'QMV1-F-DOOR-STATE-SAME';
  static const String doorGeneratesPalace =
      'QMV1-F-DOOR-STATE-GENERATES-PALACE';
  static const String palaceGeneratesDoor =
      'QMV1-F-DOOR-STATE-PALACE-GENERATES';
  static const String doorControlsPalace = 'QMV1-F-DOOR-STATE-CONTROLS-PALACE';
  static const String palaceControlsDoor = 'QMV1-F-DOOR-STATE-PALACE-CONTROLS';

  static const String doorPressure = 'QMV1-F-DOOR-PRESSURE';
  static const String instrumentPunishment = 'QMV1-F-INSTRUMENT-PUNISHMENT';
  static const String qiYiTomb = 'QMV1-F-QIYI-TOMB';
  static const String voidState = 'QMV1-F-VOID';
  static const String horseActivation = 'QMV1-F-HORSE-ACTIVATION';

  static const String starFuYin = 'QMV1-F-STAR-FUYIN';
  static const String doorFuYin = 'QMV1-F-DOOR-FUYIN';
  static const String combinedFuYin = 'QMV1-F-COMBINED-FUYIN';
  static const String starFanYin = 'QMV1-F-STAR-FANYIN';
  static const String doorFanYin = 'QMV1-F-DOOR-FANYIN';
  static const String combinedFanYin = 'QMV1-F-COMBINED-FANYIN';
  static const String fiveNotMeeting = 'QMV1-F-FIVE-NOT-MEETING';

  static const String dragonReturns = 'QMV1-F-FORM-DRAGON-RETURNS';
  static const String birdFalls = 'QMV1-F-FORM-BIRD-FALLS';
  static const String threeWonderDuty = 'QMV1-F-FORM-THREE-WONDER-DUTY';
  static const String threeWonderYi = 'QMV1-F-FORM-THREE-WONDER-YI';
  static const String threeWonderBing = 'QMV1-F-FORM-THREE-WONDER-BING';
  static const String threeWonderDing = 'QMV1-F-FORM-THREE-WONDER-DING';

  static const String heavenDun = 'QMV1-F-DUN-HEAVEN';
  static const String earthDun = 'QMV1-F-DUN-EARTH';
  static const String humanDun = 'QMV1-F-DUN-HUMAN';
  static const String windDun = 'QMV1-F-DUN-WIND';
  static const String cloudDun = 'QMV1-F-DUN-CLOUD';
  static const String dragonDun = 'QMV1-F-DUN-DRAGON';
  static const String tigerDun = 'QMV1-F-DUN-TIGER';
  static const String spiritDun = 'QMV1-F-DUN-SPIRIT';
  static const String ghostDun = 'QMV1-F-DUN-GHOST';

  static const String greenDragonFlees = 'QMV1-F-ADVERSE-GREEN-DRAGON-FLEES';
  static const String whiteTigerRages = 'QMV1-F-ADVERSE-WHITE-TIGER-RAGES';
  static const String vermilionFallsRiver =
      'QMV1-F-ADVERSE-VERMILION-FALLS-RIVER';
  static const String snakeTwists = 'QMV1-F-ADVERSE-SNAKE-TWISTS';
  static const String fireEntersMetal = 'QMV1-F-ADVERSE-FIRE-ENTERS-METAL';
  static const String metalEntersFire = 'QMV1-F-ADVERSE-METAL-ENTERS-FIRE';
  static const String largePattern = 'QMV1-F-ADVERSE-LARGE-PATTERN';
  static const String smallPattern = 'QMV1-F-ADVERSE-SMALL-PATTERN';
  static const String punishmentPattern = 'QMV1-F-ADVERSE-PUNISHMENT-PATTERN';
  static const String flyingStemPattern = 'QMV1-F-ADVERSE-FLYING-STEM';
  static const String hiddenStemPattern = 'QMV1-F-ADVERSE-HIDDEN-STEM';
  static const String flyingPalacePattern = 'QMV1-F-ADVERSE-FLYING-PALACE';
  static const String hiddenPalacePattern = 'QMV1-F-ADVERSE-HIDDEN-PALACE';
  static const String skyNet = 'QMV1-F-ADVERSE-SKY-NET';

  static const String favorableConvergence = 'QMV1-F-CONVERGENCE-FAVORABLE';
  static const String adverseConvergence = 'QMV1-F-CONVERGENCE-ADVERSE';

  static const String conflictExplicitPair = 'QMV1-X-EXPLICIT-PAIR';
  static const String conflictFocusSpecificity = 'QMV1-X-FOCUS-SPECIFICITY';
  static const String conflictTierPrecedence = 'QMV1-X-TIER-PRECEDENCE';
  static const String conflictUnresolved = 'QMV1-X-UNRESOLVED-SAME-TIER';

  static const String decision00 = 'QMV1-D00';
  static const String decision10 = 'QMV1-D10';
  static const String decision20 = 'QMV1-D20';
  static const String decision30 = 'QMV1-D30';
  static const String decision40 = 'QMV1-D40';
  static const String decision50 = 'QMV1-D50';
  static const String decision60 = 'QMV1-D60';

  static const String yingQiConditionRelease = 'QMV1-YQ-CONDITION-RELEASE';
  static const String yingQiHorse = 'QMV1-YQ-HORSE-ACTIVATION';
  static const String yingQiFuYin = 'QMV1-YQ-FUYIN-MOVEMENT';
  static const String yingQiFanYin = 'QMV1-YQ-FANYIN-TRANSITION';
  static const String yingQiStem = 'QMV1-YQ-STEM-ARRIVAL';
  static const String yingQiSolarTerm = 'QMV1-YQ-SOLAR-TERM';

  static const List<String> qiYi = <String>[
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
    '丁',
    '丙',
    '乙',
  ];

  static const Map<String, String> stemCodes = <String, String>{
    '乙': 'YI',
    '丙': 'BING',
    '丁': 'DING',
    '戊': 'WU',
    '己': 'JI',
    '庚': 'GENG',
    '辛': 'XIN',
    '壬': 'REN',
    '癸': 'GUI',
  };

  static String stemResponseRuleId(String heavenStem, String earthStem) {
    final heaven = stemCodes[heavenStem];
    final earth = stemCodes[earthStem];
    if (heaven == null || earth == null) {
      throw ArgumentError(
          'Unsupported Qimen stem response: $heavenStem+$earthStem');
    }
    return 'QMV1-F-STEM-$heaven-$earth';
  }

  static const Map<(String, String), (String, String)> _stemResponseWitness =
      <(String, String), (String, String)>{
    ('戊', '戊'): ('青龙出地', '喜信可来，仍须门星配合。'),
    ('戊', '乙'): ('青龙入云', '三奇门交而吉，星干不利则虚名。'),
    ('戊', '丙'): ('青龙返首', '凡事亨通，门仪不合仍难成就。'),
    ('戊', '丁'): ('青龙耀明', '宜谒贵迁职，符事役凶则待词刑。'),
    ('戊', '己'): ('青龙合灵', '吉星吉门主财成事，逆则徒劳。'),
    ('戊', '庚'): ('青龙符格', '有不测之咎，即使星门顺亦宜静。'),
    ('戊', '辛'): ('青龙失惊', '门合可遂，凶星则财利倾亡。'),
    ('戊', '壬'): ('青龙网罗', '原文按阴阳人分述灾祸与不和。'),
    ('戊', '癸'): ('青龙华盖', '门星合则无害，伤死门另有戒。'),
    ('乙', '戊'): ('阴中返阳', '凶星主财人口损，仍分门与用人。'),
    ('乙', '乙'): ('日奇伏刑', '贵问失名，门合可续，门逆停丧。'),
    ('乙', '丙'): ('奇仪顺格', '吉星主迁职，婚占另有离隔语。'),
    ('乙', '丁'): ('朱雀入墓', '文书留滞，星门吉则文词得路。'),
    ('乙', '己'): ('日奇入雾', '土木混同，所求轻微且受门影响。'),
    ('乙', '庚'): ('日奇自刑', '争财入讼，星干不吉另涉关系。'),
    ('乙', '辛'): ('青龙逃走', '失财逃亡，强为难久。'),
    ('乙', '壬'): ('青龙得云', '原文残简按阴阳人、疾病分述。'),
    ('乙', '癸'): ('日入天网', '望信见恙，官事失财而事虚。'),
    ('丙', '戊'): ('飞鸟跌穴', '贵面荣迁，图谋通彻。'),
    ('丙', '乙'): ('月奇浮云', '印信可陈，公私称心。'),
    ('丙', '丙'): ('月奇勃格', '文书障格，门逆亡财，门顺亦迫。'),
    ('丙', '丁'): ('奇入朱雀', '文书可通，贵常之占分别。'),
    ('丙', '己'): ('火孛入刑', '文书与狱事受星门顺逆影响。'),
    ('丙', '庚'): ('荧入太白', '家事盗贼之象，须合门星复核。'),
    ('丙', '辛'): ('月精合佑', '病可得医，文状亦可成。'),
    ('丙', '壬'): ('孛乱来临', '文讼、流离与失名之象。'),
    ('丙', '癸'): ('华盖孛师', '有灾讼语，但原文亦载后无亏。'),
    ('丁', '戊'): ('青龙得光', '迁职得良，符星相合更美。'),
    ('丁', '乙'): ('格为人遁', '荐论改禄受权。'),
    ('丁', '丙'): ('加中复奇', '口舌跷蹊，贵常之占分别。'),
    ('丁', '丁'): ('奇入太阴', '文意可遂，近信用又名伏吟。'),
    ('丁', '己'): ('火入勾神', '文状词凶并涉私情刑名。'),
    ('丁', '庚'): ('织女寻牛', '私情或冤仇，原文主刑禁。'),
    ('丁', '辛'): ('朱雀入狱', '官常均有刑囚迟释语。'),
    ('丁', '壬'): ('五人相和', '丁壬化木，财禄文状平和。'),
    ('丁', '癸'): ('朱雀沉江', '妇人官府、公私不协。'),
    ('己', '戊'): ('伏格青龙', '门星合则财隆，逆则成空。'),
    ('己', '乙'): ('墓入不明', '星门合则平，逆则不成。'),
    ('己', '丙'): ('格名孛师', '原文按阴阳人分述赐禄与奸乱。'),
    ('己', '丁'): ('奇入墓名', '文书诉理，先得理后受惩。'),
    ('己', '己'): ('地户逢鬼', '望信难委，符门合则可来。'),
    ('己', '庚'): ('刑格之名', '原文按阴阳人分述发用与静默。'),
    ('己', '辛'): ('魂神入墓', '家中惊异，小口有灾语。'),
    ('己', '壬'): ('刑网高张', '门迫星凶时原文尤重。'),
    ('己', '癸'): ('地刑玄武', '灾病沉吟，门星扶仍成疾苦。'),
    ('庚', '戊'): ('刑青龙格', '财利与凶免取决于星门合否。'),
    ('庚', '乙'): ('日合六格', '百事可安但宜缄默，凶门仍有刑迫。'),
    ('庚', '丙'): ('太白入荧', '失物盗事，门星决定后续语境。'),
    ('庚', '丁'): ('名曰亭亭', '文状私情，符门逆则词讼难成。'),
    ('庚', '己'): ('刑格', '狱囚难伸。'),
    ('庚', '庚'): ('太白之名', '官事狱禁，原文载百日后舒。'),
    ('庚', '辛'): ('干格白虎', '道路伤亡、失伴与客主相执。'),
    ('庚', '壬'): ('蛇格之名', '迷路无信，伤死门则加重。'),
    ('庚', '癸'): ('大刑之格', '远求、疾病与离隔之象。'),
    ('辛', '戊'): ('龙困遭伤', '官财争执，门顺仍可吉。'),
    ('辛', '乙'): ('白虎猖狂', '失财破家、远行失信。'),
    ('辛', '丙'): ('干合荧惑', '文状虚词，门星不合则屈厄。'),
    ('辛', '丁'): ('狱神入奇', '经商利迟，门星不吉则关系分离。'),
    ('辛', '己'): ('刑狱之格', '欺主自刑，吉门强星亦有牵累。'),
    ('辛', '庚'): ('白虎伤格', '争情丑声，仍受星门合凶影响。'),
    ('辛', '辛'): ('狱入自刑', '原转录作“六辛加卒”；求财喜合，阴阳人分吉灾。'),
    ('辛', '壬'): ('蛇入狱刑', '争讼难停，门符合吉仍有首罚语。'),
    ('辛', '癸'): ('直格华盖', '吉门吉星时财食喜庆。'),
    ('壬', '戊'): ('蛇化为龙', '阴人喜庆，阳人所求有始无终。'),
    ('壬', '乙'): ('格名小蛇', '灾嗟与孕禄并见，须保留语境。'),
    ('壬', '丙'): ('蛇入冶炉', '词讼争端，刑禁则更不利。'),
    ('壬', '丁'): ('干合蛇刑', '文书财喜，贵常分别。'),
    ('壬', '己'): ('蛇凶入狱', '祸与不睦语并见，刑财条件复杂。'),
    ('壬', '庚'): ('太白骑蛇', '刑狱分正邪，伤死门则刑戮。'),
    ('壬', '辛'): ('螣蛇格干', '符门虽吉仍有内欺。'),
    ('壬', '壬'): ('罗网自缠', '原文按阴阳人分用，三吉不入则无缘。'),
    ('壬', '癸'): ('螣蛇飞空', '家事不和，星门吉则仍有信息。'),
    ('癸', '戊'): ('罗网青龙', '财喜姻亲，星门不合则争讼。'),
    ('癸', '乙'): ('华盖逢星', '贵人禄位，常人有怪异口舌。'),
    ('癸', '丙'): ('盖遇孛师', '贵人受官，文状可得门路。'),
    ('癸', '丁'): ('螣蛇夭矫', '文书凶兆、损财招刑。'),
    ('癸', '己'): ('华盖地户', '问夫居住，门顺逆决定后语。'),
    ('癸', '庚'): ('大格飞名', '上官握柄，公事迟、钱财争。'),
    ('癸', '辛'): ('狱入天牢', '军吏遭系，门星吉则虚禁。'),
    ('癸', '壬'): ('复见螣蛇', '绝子离家等古文语境。'),
    ('癸', '癸'): ('天网高张', '行旅失约，合逆另论。'),
  };

  static String _sourceWitnessPair(String heavenStem, String earthStem) {
    if (heavenStem == '辛' && earthStem == '辛') {
      return '辛加卒（转录位置裁为辛加辛）';
    }
    final sourceHeaven = heavenStem == '戊' ? '甲' : heavenStem;
    final sourceEarth = earthStem == '戊' ? '甲' : earthStem;
    return '$sourceHeaven加$sourceEarth';
  }

  static final List<QimenStemResponseSpec> stemResponseSpecs =
      List<QimenStemResponseSpec>.unmodifiable(<QimenStemResponseSpec>[
    for (final heaven in qiYi)
      for (final earth in qiYi)
        QimenStemResponseSpec(
          ruleId: stemResponseRuleId(heaven, earth),
          heavenStem: heaven,
          earthStem: earth,
          sourceWitnessPair: _sourceWitnessPair(heaven, earth),
          sourceTerm: _stemResponseWitness[(heaven, earth)]!.$1,
          displayTerm:
              '$heaven加$earth·${_stemResponseWitness[(heaven, earth)]!.$1}',
          claimSummary: '天盘$heaven加地盘$earth：'
              '${_stemResponseWitness[(heaven, earth)]!.$2}',
          sourceIds: const <String>[QimenSourceCatalog.baoJian],
        ),
  ]);

  static final Map<(String, String), QimenStemResponseSpec> stemResponseByPair =
      Map<(String, String), QimenStemResponseSpec>.unmodifiable(
    <(String, String), QimenStemResponseSpec>{
      for (final spec in stemResponseSpecs)
        (spec.heavenStem, spec.earthStem): spec,
    },
  );

  static QimenStemResponseSpec stemResponseSpec(
    String heavenStem,
    String earthStem,
  ) {
    final spec = stemResponseByPair[(heavenStem, earthStem)];
    if (spec == null) {
      throw ArgumentError(
        'Unsupported Qimen stem response: $heavenStem+$earthStem',
      );
    }
    return spec;
  }

  static const List<QimenFormationSpec> formationSpecs = <QimenFormationSpec>[
    QimenFormationSpec(
      ruleId: dragonReturns,
      heavenStem: '戊',
      earthStem: '丙',
    ),
    QimenFormationSpec(
      ruleId: birdFalls,
      heavenStem: '丙',
      earthStem: '戊',
    ),
    QimenFormationSpec(
      ruleId: threeWonderYi,
      heavenStem: '乙',
      palaceNumber: 3,
    ),
    QimenFormationSpec(
      ruleId: threeWonderBing,
      heavenStem: '丙',
      palaceNumber: 9,
    ),
    QimenFormationSpec(
      ruleId: threeWonderDing,
      heavenStem: '丁',
      palaceNumber: 7,
    ),
    QimenFormationSpec(
      ruleId: heavenDun,
      heavenStem: '丙',
      earthStem: '丁',
      door: '生门',
    ),
    QimenFormationSpec(
      ruleId: earthDun,
      heavenStem: '乙',
      earthStem: '己',
      door: '开门',
    ),
    QimenFormationSpec(
      ruleId: humanDun,
      heavenStem: '丁',
      door: '休门',
      deity: '太阴',
    ),
    QimenFormationSpec(
      ruleId: windDun,
      heavenStem: '乙',
      allowedDoors: <String>['开门', '休门', '生门'],
      palaceNumber: 4,
    ),
    QimenFormationSpec(
      ruleId: cloudDun,
      heavenStem: '乙',
      earthStem: '辛',
      allowedDoors: <String>['开门', '休门', '生门'],
    ),
    QimenFormationSpec(
      ruleId: dragonDun,
      heavenStem: '乙',
      allowedDoors: <String>['开门', '休门', '生门'],
      palaceNumber: 1,
    ),
    QimenFormationSpec(
      ruleId: tigerDun,
      heavenStem: '乙',
      earthStem: '辛',
      allowedDoors: <String>['开门', '休门', '生门'],
      palaceNumber: 8,
    ),
    QimenFormationSpec(
      ruleId: spiritDun,
      heavenStem: '丙',
      door: '生门',
      deity: '九天',
    ),
    QimenFormationSpec(
      ruleId: ghostDun,
      heavenStem: '丁',
      door: '杜门',
      deity: '九地',
    ),
    QimenFormationSpec(
      ruleId: greenDragonFlees,
      heavenStem: '乙',
      earthStem: '辛',
    ),
    QimenFormationSpec(
      ruleId: whiteTigerRages,
      heavenStem: '辛',
      earthStem: '乙',
    ),
    QimenFormationSpec(
      ruleId: vermilionFallsRiver,
      heavenStem: '丁',
      earthStem: '癸',
    ),
    QimenFormationSpec(
      ruleId: snakeTwists,
      heavenStem: '癸',
      earthStem: '丁',
    ),
    QimenFormationSpec(
      ruleId: fireEntersMetal,
      heavenStem: '丙',
      earthStem: '庚',
    ),
    QimenFormationSpec(
      ruleId: metalEntersFire,
      heavenStem: '庚',
      earthStem: '丙',
    ),
    QimenFormationSpec(
      ruleId: largePattern,
      heavenStem: '庚',
      earthStem: '癸',
    ),
    QimenFormationSpec(
      ruleId: smallPattern,
      heavenStem: '庚',
      earthStem: '壬',
    ),
    QimenFormationSpec(
      ruleId: punishmentPattern,
      heavenStem: '庚',
      earthStem: '己',
    ),
    QimenFormationSpec(
      ruleId: flyingStemPattern,
      earthStem: '庚',
      heavenMatchesDayStem: true,
    ),
    QimenFormationSpec(
      ruleId: hiddenStemPattern,
      heavenStem: '庚',
      earthMatchesDayStem: true,
    ),
    QimenFormationSpec(
      ruleId: flyingPalacePattern,
      earthStem: '庚',
      heavenMatchesXunHiddenStem: true,
    ),
    QimenFormationSpec(
      ruleId: hiddenPalacePattern,
      heavenStem: '庚',
      earthMatchesXunHiddenStem: true,
    ),
  ];

  static final List<QimenRuleDefinition> all =
      List<QimenRuleDefinition>.unmodifiable(<QimenRuleDefinition>[
    _rule(
      inputIntegrity,
      QimenRuleFamily.input,
      '排盘输入完整性',
      evaluator: 'QimenAnalysisInputGuard',
      tier: QimenConflictTier.decisive,
      decisionCapable: true,
    ),
    _rule(focusSelf, QimenRuleFamily.focus, '日干为求测者',
        evaluator: 'QimenFocusResolver'),
    _rule(focusMatter, QimenRuleFamily.focus, '时干为所问之事',
        evaluator: 'QimenFocusResolver'),
    for (final entry in const <(String, String)>[
      (focusGeneral, '综合问事焦点'),
      (focusCareer, '事业问事焦点'),
      (focusWealth, '财运问事焦点'),
      (focusRelationship, '感情问事焦点'),
      (focusHealth, '健康问事焦点'),
      (focusStudy, '学业问事焦点'),
      (focusTravel, '出行问事焦点'),
      (focusLitigation, '诉讼问事焦点'),
    ])
      _rule(entry.$1, QimenRuleFamily.focus, entry.$2,
          evaluator: 'QimenFocusResolver'),
    _stateRule(starStateWang, '九星旺'),
    _stateRule(starStateXiang, '九星相'),
    _stateRule(starStateXiu, '九星休', role: QimenFactRole.neutral),
    _stateRule(starStateQiu, '九星囚', role: QimenFactRole.inhibit),
    _stateRule(starStateFei, '九星废', role: QimenFactRole.inhibit),
    _doorSeasonRule(doorSeasonWang, '八门旺'),
    _doorSeasonRule(doorSeasonXiang, '八门相'),
    _doorSeasonRule(doorSeasonXiu, '八门休', role: QimenFactRole.neutral),
    _doorSeasonRule(doorSeasonQiu, '八门囚', role: QimenFactRole.inhibit),
    _doorSeasonRule(doorSeasonFei, '八门废', role: QimenFactRole.inhibit),
    _doorStateRule(
      doorStateSame,
      '门宫比和',
      role: QimenFactRole.support,
    ),
    _doorStateRule(
      doorGeneratesPalace,
      '门生宫',
      role: QimenFactRole.support,
    ),
    _doorStateRule(palaceGeneratesDoor, '宫生门'),
    _doorStateRule(
      doorControlsPalace,
      '门克宫',
      role: QimenFactRole.inhibit,
    ),
    _doorStateRule(
      palaceControlsDoor,
      '宫克门',
      role: QimenFactRole.inhibit,
    ),
    _rule(
      doorPressure,
      QimenRuleFamily.constraint,
      '门迫',
      evaluator: 'QimenConstraintFactService',
      role: QimenFactRole.suspend,
      tier: QimenConflictTier.conditional,
      scopes: const <QimenFactScope>[QimenFactScope.palace],
      decisionCapable: true,
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.tuShu707,
      ],
    ),
    _rule(
      instrumentPunishment,
      QimenRuleFamily.constraint,
      '六仪击刑',
      evaluator: 'QimenConstraintFactService',
      role: QimenFactRole.suspend,
      tier: QimenConflictTier.conditional,
      scopes: const <QimenFactScope>[QimenFactScope.palace],
      decisionCapable: true,
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.tuShu707,
      ],
    ),
    _rule(
      qiYiTomb,
      QimenRuleFamily.constraint,
      '奇仪入墓',
      evaluator: 'QimenConstraintFactService',
      role: QimenFactRole.suspend,
      tier: QimenConflictTier.conditional,
      scopes: const <QimenFactScope>[QimenFactScope.palace],
      decisionCapable: true,
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.tuShu707,
      ],
    ),
    _rule(
      voidState,
      QimenRuleFamily.constraint,
      '空亡',
      evaluator: 'QimenConstraintFactService',
      role: QimenFactRole.suspend,
      tier: QimenConflictTier.conditional,
      scopes: const <QimenFactScope>[QimenFactScope.palace],
      decisionCapable: true,
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.projectV1,
      ],
    ),
    _rule(
      horseActivation,
      QimenRuleFamily.constraint,
      '驿马发动',
      evaluator: 'QimenConstraintFactService',
      role: QimenFactRole.support,
      tier: QimenConflictTier.corroborating,
      scopes: const <QimenFactScope>[QimenFactScope.palace],
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.projectV1,
      ],
    ),
    _structureRule(
      starFuYin,
      '九星伏吟',
      tier: QimenConflictTier.conditional,
    ),
    _structureRule(
      doorFuYin,
      '八门伏吟',
      tier: QimenConflictTier.conditional,
    ),
    _structureRule(
      combinedFuYin,
      '星门俱伏吟',
      role: QimenFactRole.suspend,
      tier: QimenConflictTier.conditional,
      resolves: const <String>[starFuYin, doorFuYin],
    ),
    _structureRule(
      starFanYin,
      '九星反吟',
      tier: QimenConflictTier.conditional,
    ),
    _structureRule(
      doorFanYin,
      '八门反吟',
      tier: QimenConflictTier.conditional,
    ),
    _structureRule(
      combinedFanYin,
      '星门俱反吟',
      role: QimenFactRole.suspend,
      tier: QimenConflictTier.conditional,
      resolves: const <String>[starFanYin, doorFanYin],
    ),
    _rule(
      fiveNotMeeting,
      QimenRuleFamily.structure,
      '五不遇时',
      evaluator: 'QimenStructureFactService',
      role: QimenFactRole.inhibit,
      tier: QimenConflictTier.decisive,
      decisionCapable: true,
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.dunJiaYanYi,
      ],
    ),
    for (final spec in stemResponseSpecs)
      _rule(
        spec.ruleId,
        QimenRuleFamily.stemResponse,
        spec.displayTerm,
        evaluator: 'QimenStemResponseService',
        sources: spec.sourceIds,
        scopes: const <QimenFactScope>[QimenFactScope.palace],
      ),
    _formationRule(dragonReturns, '青龙返首'),
    _formationRule(birdFalls, '飞鸟跌穴'),
    _formationRule(threeWonderDuty, '三奇得使'),
    _formationRule(threeWonderYi, '乙奇升殿'),
    _formationRule(threeWonderBing, '丙奇升殿'),
    _formationRule(threeWonderDing, '丁奇升殿'),
    for (final entry in const <(String, String)>[
      (heavenDun, '天遁'),
      (earthDun, '地遁'),
      (humanDun, '人遁'),
      (windDun, '风遁'),
      (cloudDun, '云遁'),
      (dragonDun, '龙遁'),
      (tigerDun, '虎遁'),
      (spiritDun, '神遁'),
      (ghostDun, '鬼遁'),
    ])
      _formationRule(entry.$1, entry.$2),
    for (final entry in const <(String, String)>[
      (greenDragonFlees, '青龙逃走'),
      (whiteTigerRages, '白虎猖狂'),
      (vermilionFallsRiver, '朱雀投江'),
      (snakeTwists, '螣蛇夭矫'),
      (fireEntersMetal, '荧入太白'),
      (metalEntersFire, '太白入荧'),
      (largePattern, '大格'),
      (smallPattern, '小格'),
      (punishmentPattern, '刑格'),
      (flyingStemPattern, '飞干格'),
      (hiddenStemPattern, '伏干格'),
      (flyingPalacePattern, '飞宫格'),
      (hiddenPalacePattern, '伏宫格'),
    ])
      _formationRule(entry.$1, entry.$2,
          role: QimenFactRole.inhibit, tier: QimenConflictTier.corroborating),
    _rule(
      skyNet,
      QimenRuleFamily.formation,
      '天网四张（v1不采用癸加癸通式）',
      evaluator: 'QimenFormationService',
      tier: QimenConflictTier.contextual,
      scopes: const <QimenFactScope>[QimenFactScope.global],
      sources: const <String>[
        QimenSourceCatalog.tongZong,
        QimenSourceCatalog.projectV1,
      ],
    ),
    _rule(
      favorableConvergence,
      QimenRuleFamily.relation,
      '问事有利收敛',
      evaluator: 'QimenRelationFactService',
      role: QimenFactRole.support,
      tier: QimenConflictTier.decisive,
      scopes: const <QimenFactScope>[QimenFactScope.focusRelation],
      decisionCapable: true,
    ),
    _rule(
      adverseConvergence,
      QimenRuleFamily.relation,
      '问事不利收敛',
      evaluator: 'QimenRelationFactService',
      role: QimenFactRole.inhibit,
      tier: QimenConflictTier.decisive,
      scopes: const <QimenFactScope>[QimenFactScope.focusRelation],
      decisionCapable: true,
    ),
    for (final entry in const <(String, String)>[
      (conflictExplicitPair, '显式成对解救'),
      (conflictFocusSpecificity, '焦点特异性优先'),
      (conflictTierPrecedence, '规则层级优先'),
      (conflictUnresolved, '同层冲突未决'),
    ])
      _rule(entry.$1, QimenRuleFamily.conflict, entry.$2,
          evaluator: 'QimenConflictResolver'),
    for (final entry in const <(String, String)>[
      (decision00, '输入或焦点不完整'),
      (decision10, '决定性阻断且无解'),
      (decision20, '存在可解除条件'),
      (decision30, '类别不利收敛'),
      (decision40, '类别有利收敛'),
      (decision50, '决定性冲突未决'),
      (decision60, '证据仅供背景'),
    ])
      _rule(entry.$1, QimenRuleFamily.verdict, entry.$2,
          evaluator: 'QimenVerdictService', decisionCapable: true),
    for (final entry in const <(String, String)>[
      (yingQiConditionRelease, '条件解除观察窗'),
      (yingQiHorse, '驿马发动观察窗'),
      (yingQiFuYin, '伏吟冲动观察窗'),
      (yingQiFanYin, '反吟转折观察窗'),
      (yingQiStem, '天干到临观察窗'),
      (yingQiSolarTerm, '节气到临观察窗'),
    ])
      _rule(entry.$1, QimenRuleFamily.yingQi, entry.$2,
          evaluator: 'QimenYingQiService'),
  ]);

  static final Map<String, QimenRuleDefinition> byId =
      Map<String, QimenRuleDefinition>.unmodifiable(
    <String, QimenRuleDefinition>{for (final rule in all) rule.ruleId: rule},
  );

  static final Map<String, QimenRuleSet> released =
      Map<String, QimenRuleSet>.unmodifiable(<String, QimenRuleSet>{
    v1: QimenRuleSet(ruleSetId: ruleSetId, version: v1, rules: all),
  });

  static QimenRuleSet resolve(String version) {
    final resolved = version == 'current' ? current : version;
    final ruleSet = released[resolved];
    if (ruleSet == null) {
      throw ArgumentError(
        'Unsupported Qimen rule-set version: $version; released: '
        '${released.keys.join(', ')}',
      );
    }
    return ruleSet;
  }

  static QimenRuleDefinition rule(String ruleId) {
    final value = byId[ruleId];
    if (value == null) throw StateError('Unknown Qimen rule ID: $ruleId');
    return value;
  }

  static void validate() {
    QimenSourceCatalog.validate();
    if (byId.length != all.length) {
      throw StateError('Qimen rule catalog contains duplicate IDs');
    }
    for (final rule in all) {
      if (rule.ruleId.isEmpty ||
          rule.displayTerm.isEmpty ||
          rule.evaluatorId.isEmpty ||
          rule.sourceIds.isEmpty) {
        throw StateError('Incomplete Qimen rule: ${rule.ruleId}');
      }
      for (final sourceId in rule.sourceIds) {
        if (!QimenSourceCatalog.byId.containsKey(sourceId)) {
          throw StateError('Rule ${rule.ruleId} has unknown source $sourceId');
        }
      }
      for (final related in <String>[
        ...rule.resolvesRuleIds,
        ...rule.suppressedByRuleIds,
      ]) {
        if (!byId.containsKey(related)) {
          throw StateError(
              'Rule ${rule.ruleId} refers to unknown rule $related');
        }
      }
      if (rule.resolvesRuleIds.any(rule.suppressedByRuleIds.contains)) {
        throw StateError('Rule ${rule.ruleId} has a circular conflict pair');
      }
      if (rule.decisionCapable &&
          rule.sourceIds.length == 1 &&
          rule.sourceIds.single == QimenSourceCatalog.projectV1 &&
          QimenSourceCatalog
              .byId[QimenSourceCatalog.projectV1]!.adjudicationNote.isEmpty) {
        throw StateError(
          'Decision-capable project rule lacks adjudication: ${rule.ruleId}',
        );
      }
    }
    if (formationSpecs.map((value) => value.ruleId).toSet().length !=
        formationSpecs.length) {
      throw StateError('Qimen formation catalog contains duplicate formulas');
    }
    if (_stemResponseWitness.length != 81 ||
        stemResponseSpecs.length != 81 ||
        stemResponseByPair.length != stemResponseSpecs.length ||
        stemResponseSpecs.map((value) => value.ruleId).toSet().length !=
            stemResponseSpecs.length) {
      throw StateError('Qimen stem-response catalog must contain 81 pairs');
    }
    for (final spec in stemResponseSpecs) {
      if (spec.sourceWitnessPair.isEmpty ||
          spec.sourceTerm.isEmpty ||
          spec.displayTerm.isEmpty ||
          spec.claimSummary.isEmpty ||
          spec.sourceIds.isEmpty ||
          spec.sourceIds.any(
            (sourceId) => !QimenSourceCatalog.byId.containsKey(sourceId),
          )) {
        throw StateError('Incomplete Qimen stem response: ${spec.ruleId}');
      }
    }
  }

  static QimenRuleDefinition _rule(
    String id,
    QimenRuleFamily family,
    String term, {
    required String evaluator,
    QimenFactRole role = QimenFactRole.neutral,
    QimenConflictTier tier = QimenConflictTier.contextual,
    List<QimenFactScope> scopes = const <QimenFactScope>[
      QimenFactScope.global,
      QimenFactScope.palace,
      QimenFactScope.focusRelation,
    ],
    List<String> sources = const <String>[QimenSourceCatalog.projectV1],
    bool decisionCapable = false,
    List<String> resolves = const <String>[],
    List<String> suppressedBy = const <String>[],
  }) =>
      QimenRuleDefinition(
        ruleId: id,
        family: family,
        introducedIn: v1,
        displayTerm: term,
        factRole: role,
        conflictTier: tier,
        supportedScopes: scopes,
        sourceIds: sources,
        evaluatorId: evaluator,
        decisionCapable: decisionCapable,
        resolvesRuleIds: resolves,
        suppressedByRuleIds: suppressedBy,
      );

  static QimenRuleDefinition _stateRule(
    String id,
    String term, {
    QimenFactRole role = QimenFactRole.support,
  }) =>
      _rule(
        id,
        QimenRuleFamily.state,
        term,
        evaluator: 'QimenStarDoorStateService',
        role: role,
        tier: QimenConflictTier.contextual,
        scopes: const <QimenFactScope>[QimenFactScope.palace],
        sources: const <String>[
          QimenSourceCatalog.dunJiaYanYi,
          QimenSourceCatalog.baoJian,
        ],
      );

  static QimenRuleDefinition _doorSeasonRule(
    String id,
    String term, {
    QimenFactRole role = QimenFactRole.support,
  }) =>
      _rule(
        id,
        QimenRuleFamily.state,
        term,
        evaluator: 'QimenStarDoorStateService',
        role: role,
        tier: QimenConflictTier.contextual,
        scopes: const <QimenFactScope>[QimenFactScope.palace],
        sources: const <String>[QimenSourceCatalog.tongZong],
      );

  static QimenRuleDefinition _doorStateRule(
    String id,
    String term, {
    QimenFactRole role = QimenFactRole.neutral,
  }) =>
      _rule(
        id,
        QimenRuleFamily.state,
        term,
        evaluator: 'QimenStarDoorStateService',
        role: role,
        tier: QimenConflictTier.contextual,
        scopes: const <QimenFactScope>[QimenFactScope.palace],
        sources: const <String>[QimenSourceCatalog.tongZong],
      );

  static QimenRuleDefinition _structureRule(
    String id,
    String term, {
    QimenFactRole role = QimenFactRole.neutral,
    QimenConflictTier tier = QimenConflictTier.contextual,
    List<String> resolves = const <String>[],
    List<String> suppressedBy = const <String>[],
  }) =>
      _rule(
        id,
        QimenRuleFamily.structure,
        term,
        evaluator: 'QimenStructureFactService',
        role: role,
        tier: tier,
        sources: const <String>[
          QimenSourceCatalog.dunJiaYanYi,
          QimenSourceCatalog.projectV1,
        ],
        resolves: resolves,
        suppressedBy: suppressedBy,
      );

  static QimenRuleDefinition _formationRule(
    String id,
    String term, {
    QimenFactRole role = QimenFactRole.support,
    QimenConflictTier tier = QimenConflictTier.corroborating,
  }) =>
      _rule(
        id,
        QimenRuleFamily.formation,
        term,
        evaluator: 'QimenFormationService',
        role: role,
        tier: tier,
        scopes: const <QimenFactScope>[QimenFactScope.palace],
        sources: const <String>[
          QimenSourceCatalog.dunJiaYanYi,
          QimenSourceCatalog.tuShu707,
        ],
      );
}
