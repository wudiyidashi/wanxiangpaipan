const List<String> expectedStemResponseOrder = <String>[
  '戊',
  '乙',
  '丙',
  '丁',
  '己',
  '庚',
  '辛',
  '壬',
  '癸',
];

const Map<String, String> expectedStemResponseCodes = <String, String>{
  '戊': 'WU',
  '乙': 'YI',
  '丙': 'BING',
  '丁': 'DING',
  '己': 'JI',
  '庚': 'GENG',
  '辛': 'XIN',
  '壬': 'REN',
  '癸': 'GUI',
};

const Map<String, List<String>> expectedStemResponseTerms =
    <String, List<String>>{
  '戊': <String>[
    '青龙出地',
    '青龙入云',
    '青龙返首',
    '青龙耀明',
    '青龙合灵',
    '青龙符格',
    '青龙失惊',
    '青龙网罗',
    '青龙华盖',
  ],
  '乙': <String>[
    '阴中返阳',
    '日奇伏刑',
    '奇仪顺格',
    '朱雀入墓',
    '日奇入雾',
    '日奇自刑',
    '青龙逃走',
    '青龙得云',
    '日入天网',
  ],
  '丙': <String>[
    '飞鸟跌穴',
    '月奇浮云',
    '月奇勃格',
    '奇入朱雀',
    '火孛入刑',
    '荧入太白',
    '月精合佑',
    '孛乱来临',
    '华盖孛师',
  ],
  '丁': <String>[
    '青龙得光',
    '格为人遁',
    '加中复奇',
    '奇入太阴',
    '火入勾神',
    '织女寻牛',
    '朱雀入狱',
    '五人相和',
    '朱雀沉江',
  ],
  '己': <String>[
    '伏格青龙',
    '墓入不明',
    '格名孛师',
    '奇入墓名',
    '地户逢鬼',
    '刑格之名',
    '魂神入墓',
    '刑网高张',
    '地刑玄武',
  ],
  '庚': <String>[
    '刑青龙格',
    '日合六格',
    '太白入荧',
    '名曰亭亭',
    '刑格',
    '太白之名',
    '干格白虎',
    '蛇格之名',
    '大刑之格',
  ],
  '辛': <String>[
    '龙困遭伤',
    '白虎猖狂',
    '干合荧惑',
    '狱神入奇',
    '刑狱之格',
    '白虎伤格',
    '狱入自刑',
    '蛇入狱刑',
    '直格华盖',
  ],
  '壬': <String>[
    '蛇化为龙',
    '格名小蛇',
    '蛇入冶炉',
    '干合蛇刑',
    '蛇凶入狱',
    '太白骑蛇',
    '螣蛇格干',
    '罗网自缠',
    '螣蛇飞空',
  ],
  '癸': <String>[
    '罗网青龙',
    '华盖逢星',
    '盖遇孛师',
    '螣蛇夭矫',
    '华盖地户',
    '大格飞名',
    '狱入天牢',
    '复见螣蛇',
    '天网高张',
  ],
};

String expectedStemResponseRuleId(String heavenStem, String earthStem) =>
    'QMV1-F-STEM-${expectedStemResponseCodes[heavenStem]}-'
    '${expectedStemResponseCodes[earthStem]}';

String expectedStemResponseWitnessPair(
  String heavenStem,
  String earthStem,
) {
  if (heavenStem == '辛' && earthStem == '辛') {
    return '辛加卒（转录位置裁为辛加辛）';
  }
  return '${heavenStem == '戊' ? '甲' : heavenStem}加'
      '${earthStem == '戊' ? '甲' : earthStem}';
}
