/// Publicly reproducible golden fixture for the Qimen pan engine.
///
/// The cited repositories may share implementation lineage, so their output
/// must not be treated as independent agreement. The frozen 2008 case and
/// palace facts below are asserted by the pinned 3meta and xuanyuwang cases.
/// Project review checked every listed palace field against both snapshots
/// and the locked rotating-pan stage rules.
const qimenPublicGoldenTimeInput = <String, dynamic>{
  'params': <String, dynamic>{
    'timeBasis': 'beijing',
    'sourceUtcOffsetMinutes': 480,
  },
};

const qimenManualGoldenInput = <String, dynamic>{
  'yearGanZhi': '戊子',
  'monthGanZhi': '壬戌',
  'dayGanZhi': '戊申',
  'hourGanZhi': '戊午',
  'solarTerm': '霜降',
  'dun': 'yin',
  'juNumber': 2,
  'yuan': 'lower',
  'params': <String, dynamic>{
    'timeBasis': 'beijing',
    'sourceUtcOffsetMinutes': 480,
  },
};

const qimenManualGoldenSources = <Map<String, String>>[
  <String, String>{
    'repository': '3metaJun/3meta',
    'url':
        'https://github.com/3metaJun/3meta/blob/9be1238cbb7b0118826a689f9d3f8100284f6df3/src/__tests__/qimen.test.ts',
    'commit': '9be1238cbb7b0118826a689f9d3f8100284f6df3',
    'accessedAt': '2026-07-28',
    'scope': '2008-11-04 12:30 fixed case and the listed palace facts',
  },
  <String, String>{
    'repository': 'xuanyuwang/QiMen',
    'url':
        'https://github.com/xuanyuwang/QiMen/blob/c07efe2ba3c74b58e02301abce1c16b4eb9d79b1/tests/main.test.js#L129',
    'commit': 'c07efe2ba3c74b58e02301abce1c16b4eb9d79b1',
    'accessedAt': '2026-07-28',
    'scope': 'same fixed case with complete core palace assertions',
  },
];

const qimenManualGoldenLineageDisclosure =
    'The cited repositories may share implementation lineage and are not '
    'counted as two independent authorities. Every frozen field was also '
    'reviewed palace by palace against the project rotating-pan rules.';

/// Complete public core: earth/heaven stems, stars, doors and deities for all
/// outer palaces, plus the publicly stated middle-five earth stem. Hidden
/// stems and derived markers are intentionally excluded from this fixture.
const qimenManualGoldenPalaceFacts = <Map<String, dynamic>>[
  <String, dynamic>{
    'number': 1,
    'earthStem': '己',
    'heavenStem': '乙',
    'star': '天冲',
    'door': '伤门',
    'deity': '玄武',
  },
  <String, dynamic>{
    'number': 2,
    'earthStem': '戊',
    'heavenStem': '癸',
    'star': '天心',
    'door': '开门',
    'deity': '值符',
  },
  <String, dynamic>{
    'number': 3,
    'earthStem': '乙',
    'heavenStem': '庚',
    'star': '天英',
    'door': '景门',
    'deity': '六合',
  },
  <String, dynamic>{
    'number': 4,
    'earthStem': '丙',
    'heavenStem': '戊',
    'hostedHeavenStem': '丁',
    'star': '天芮',
    'hostedStar': '天禽',
    'door': '死门',
    'deity': '太阴',
  },
  <String, dynamic>{'number': 5, 'earthStem': '丁'},
  <String, dynamic>{
    'number': 6,
    'earthStem': '癸',
    'heavenStem': '辛',
    'star': '天任',
    'door': '生门',
    'deity': '九地',
  },
  <String, dynamic>{
    'number': 7,
    'earthStem': '壬',
    'heavenStem': '己',
    'star': '天蓬',
    'door': '休门',
    'deity': '九天',
  },
  <String, dynamic>{
    'number': 8,
    'earthStem': '辛',
    'heavenStem': '丙',
    'star': '天辅',
    'door': '杜门',
    'deity': '白虎',
  },
  <String, dynamic>{
    'number': 9,
    'earthStem': '庚',
    'heavenStem': '壬',
    'star': '天柱',
    'door': '惊门',
    'deity': '螣蛇',
  },
];
