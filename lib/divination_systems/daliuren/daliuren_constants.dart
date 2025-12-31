/// 大六壬常量定义
///
/// 包含十二神将、课体类型、天干寄宫、贵人等核心常量。
library;

/// 十二神将枚举
///
/// 大六壬中的十二位神将，按阳顺阴逆的顺序排列。
enum ShenJiang {
  guiRen('贵人', '天乙贵人，主吉庆、贵人相助'),
  tengShe('腾蛇', '腾蛇，主惊恐、怪异、虚诈'),
  zhuQue('朱雀', '朱雀，主文书、口舌、信息'),
  liuHe('六合', '六合，主和合、婚姻、交易'),
  gouChen('勾陈', '勾陈，主田土、争斗、牢狱'),
  qingLong('青龙', '青龙，主喜庆、财帛、婚姻'),
  tianKong('天空', '天空，主欺诈、空亡、虚假'),
  baiHu('白虎', '白虎，主凶丧、疾病、血光'),
  taiChang('太常', '太常，主宴会、衣冠、文书'),
  xuanWu('玄武', '玄武，主盗贼、暗昧、私情'),
  taiYin('太阴', '太阴，主阴私、暗事、女人'),
  tianHou('天后', '天后，主后宫、妇女、阴私');

  const ShenJiang(this.name, this.description);

  /// 神将名称
  final String name;

  /// 神将描述
  final String description;
}

/// 课体类型枚举
///
/// 大六壬九种课体，用于判断三传的取用方法。
enum KeType {
  zeiKe('贼克', '下贼上，取下克上者为用'),
  biYong('比用', '上克下，取与日干比者为用'),
  sheHai('涉害', '俱比俱不比，涉害深者为用'),
  yaoKe('遥克', '四课无克，遥克取之'),
  maoXing('昴星', '无遥克，昴星从位取之'),
  bieZe('别责', '阴阳不备，别责取之'),
  baZhuan('八专', '干支同位，八专法取之'),
  fuYin('伏吟', '天盘与地盘同宫'),
  fanYin('反吟', '天盘与地盘对冲');

  const KeType(this.name, this.description);

  /// 课体名称
  final String name;

  /// 课体描述
  final String description;
}

/// 神煞类型枚举
enum ShenShaType {
  ji('吉'),
  xiong('凶'),
  zhong('中');

  const ShenShaType(this.name);
  final String name;
}

/// 大六壬常量类
///
/// 包含天干寄宫、贵人位置等核心映射表。
class DaLiuRenConstants {
  DaLiuRenConstants._();

  /// 十二地支
  static const List<String> diZhi = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥'
  ];

  /// 十天干
  static const List<String> tianGan = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸'
  ];

  /// 天干寄宫表
  ///
  /// 天干无形体，需寄于地支宫位。
  /// 甲寄寅、乙寄卯、丙戊寄巳、丁己寄午、
  /// 庚寄申、辛寄酉、壬寄亥、癸寄子
  static const Map<String, String> ganJiGong = {
    '甲': '寅',
    '乙': '卯',
    '丙': '巳',
    '丁': '午',
    '戊': '巳',
    '己': '午',
    '庚': '申',
    '辛': '酉',
    '壬': '亥',
    '癸': '子',
  };

  /// 天干贵人表
  ///
  /// 第一个为阳贵（昼贵），第二个为阴贵（夜贵）
  /// 甲戊庚牛羊，乙己鼠猴乡，
  /// 丙丁猪鸡位，壬癸蛇兔藏，
  /// 六辛逢马虎，此是贵人方。
  static const Map<String, List<String>> ganGuiRen = {
    '甲': ['丑', '未'], // 甲戊庚牛羊
    '戊': ['丑', '未'],
    '庚': ['丑', '未'],
    '乙': ['子', '申'], // 乙己鼠猴乡
    '己': ['子', '申'],
    '丙': ['亥', '酉'], // 丙丁猪鸡位
    '丁': ['亥', '酉'],
    '壬': ['卯', '巳'], // 壬癸蛇兔藏
    '癸': ['卯', '巳'],
    '辛': ['午', '寅'], // 六辛逢马虎
  };

  /// 月将对照表
  ///
  /// 月建（月支）对应的月将（太阳所在宫位的对冲）
  /// 正月建寅，月将亥（登明）
  /// 二月建卯，月将戌（河魁）
  /// 以此类推...
  static const Map<String, String> yueJianToYueJiang = {
    '寅': '亥', // 正月：亥将（登明）
    '卯': '戌', // 二月：戌将（河魁）
    '辰': '酉', // 三月：酉将（从魁）
    '巳': '申', // 四月：申将（传送）
    '午': '未', // 五月：未将（小吉）
    '未': '午', // 六月：午将（胜光）
    '申': '巳', // 七月：巳将（太乙）
    '酉': '辰', // 八月：辰将（天罡）
    '戌': '卯', // 九月：卯将（太冲）
    '亥': '寅', // 十月：寅将（功曹）
    '子': '丑', // 十一月：丑将（大吉）
    '丑': '子', // 十二月：子将（神后）
  };

  /// 月将名称
  static const Map<String, String> yueJiangName = {
    '子': '神后',
    '丑': '大吉',
    '寅': '功曹',
    '卯': '太冲',
    '辰': '天罡',
    '巳': '太乙',
    '午': '胜光',
    '未': '小吉',
    '申': '传送',
    '酉': '从魁',
    '戌': '河魁',
    '亥': '登明',
  };

  /// 地支六冲
  ///
  /// 相隔六位的地支互冲
  static const Map<String, String> diZhiChong = {
    '子': '午',
    '午': '子',
    '丑': '未',
    '未': '丑',
    '寅': '申',
    '申': '寅',
    '卯': '酉',
    '酉': '卯',
    '辰': '戌',
    '戌': '辰',
    '巳': '亥',
    '亥': '巳',
  };

  /// 地支三合
  ///
  /// 三合局的地支组合
  static const Map<String, List<String>> diZhiSanHe = {
    '申': ['申', '子', '辰'], // 申子辰合水
    '子': ['申', '子', '辰'],
    '辰': ['申', '子', '辰'],
    '寅': ['寅', '午', '戌'], // 寅午戌合火
    '午': ['寅', '午', '戌'],
    '戌': ['寅', '午', '戌'],
    '巳': ['巳', '酉', '丑'], // 巳酉丑合金
    '酉': ['巳', '酉', '丑'],
    '丑': ['巳', '酉', '丑'],
    '亥': ['亥', '卯', '未'], // 亥卯未合木
    '卯': ['亥', '卯', '未'],
    '未': ['亥', '卯', '未'],
  };

  /// 地支六合
  static const Map<String, String> diZhiLiuHe = {
    '子': '丑', '丑': '子', // 子丑合土
    '寅': '亥', '亥': '寅', // 寅亥合木
    '卯': '戌', '戌': '卯', // 卯戌合火
    '辰': '酉', '酉': '辰', // 辰酉合金
    '巳': '申', '申': '巳', // 巳申合水
    '午': '未', '未': '午', // 午未合土
  };

  /// 十二神将顺序（阳顺）
  static const List<ShenJiang> shenJiangOrderYang = [
    ShenJiang.guiRen,
    ShenJiang.tengShe,
    ShenJiang.zhuQue,
    ShenJiang.liuHe,
    ShenJiang.gouChen,
    ShenJiang.qingLong,
    ShenJiang.tianKong,
    ShenJiang.baiHu,
    ShenJiang.taiChang,
    ShenJiang.xuanWu,
    ShenJiang.taiYin,
    ShenJiang.tianHou,
  ];

  /// 十二神将顺序（阴逆）
  static const List<ShenJiang> shenJiangOrderYin = [
    ShenJiang.guiRen,
    ShenJiang.tianHou,
    ShenJiang.taiYin,
    ShenJiang.xuanWu,
    ShenJiang.taiChang,
    ShenJiang.baiHu,
    ShenJiang.tianKong,
    ShenJiang.qingLong,
    ShenJiang.gouChen,
    ShenJiang.liuHe,
    ShenJiang.zhuQue,
    ShenJiang.tengShe,
  ];

  /// 阳干列表
  static const List<String> yangGan = ['甲', '丙', '戊', '庚', '壬'];

  /// 阴干列表
  static const List<String> yinGan = ['乙', '丁', '己', '辛', '癸'];

  /// 判断天干阴阳
  static bool isYangGan(String gan) => yangGan.contains(gan);

  /// 获取地支索引
  static int getDiZhiIndex(String zhi) => diZhi.indexOf(zhi);

  /// 获取天干索引
  static int getTianGanIndex(String gan) => tianGan.indexOf(gan);

  /// 根据索引获取地支
  static String getDiZhiByIndex(int index) => diZhi[index % 12];

  /// 根据索引获取天干
  static String getTianGanByIndex(int index) => tianGan[index % 10];

  /// 获取对冲地支
  static String getChongZhi(String zhi) => diZhiChong[zhi] ?? zhi;

  /// 获取天干寄宫
  static String getGanJiGong(String gan) => ganJiGong[gan] ?? '子';

  /// 获取贵人位置
  static List<String> getGuiRenPosition(String gan) =>
      ganGuiRen[gan] ?? ['丑', '未'];
}
