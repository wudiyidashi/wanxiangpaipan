import 'package:lunar/lunar.dart';
import 'package:uuid/uuid.dart';

import '../../domain/divination_system.dart';
import '../../domain/services/shared/lunar_service.dart';
import '../../models/lunar_info.dart';
import 'models/xiaoliuren_result.dart';

/// 小六壬排盘
///
/// 当前底层收敛为三种起课方式：
/// 1. 时间起（农历月、日、时）
/// 2. 报数起（三个数字）
/// 3. 汉字笔画起（三段笔画数）
///
/// 物象声音起当前仅在全局枚举层预留，不纳入小六壬第一版契约。
/// 当前已实现六宫/九宫两种盘式，均使用“起点记 1、三段顺推”的同构规则。
class XiaoLiuRenSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.xiaoLiuRen;

  @override
  String get name => '小六壬';

  @override
  String get description => '小六壬：支持时间起、报数起、笔画起，以三段顺推落宫直断吉凶';

  @override
  bool get isEnabled => false;

  @override
  List<CastMethod> get supportedMethods => [
        CastMethod.time,
        CastMethod.reportNumber,
        CastMethod.characterStroke,
      ];

  static const Map<String, int> _hourZhiNumbers = {
    '子': 1,
    '丑': 2,
    '寅': 3,
    '卯': 4,
    '辰': 5,
    '巳': 6,
    '午': 7,
    '未': 8,
    '申': 9,
    '酉': 10,
    '戌': 11,
    '亥': 12,
  };

  static const List<XiaoLiuRenPosition> _sixPalacePositions = [
    XiaoLiuRenPosition(
      index: 1,
      name: '大安',
      fortune: '吉',
      keyword: '诸事安稳',
      description: '主安稳、平顺、可守可谋，适合按既定节奏推进。',
      wuXing: '木',
      direction: '东方',
    ),
    XiaoLiuRenPosition(
      index: 2,
      name: '留连',
      fortune: '凶',
      keyword: '迟滞反复',
      description: '主拖延、反复、牵扯，事情不宜急推，宜等时机。',
      wuXing: '水',
      direction: '北方',
    ),
    XiaoLiuRenPosition(
      index: 3,
      name: '速喜',
      fortune: '吉',
      keyword: '喜信速来',
      description: '主喜讯、效率、结果加速，利会面、回音、推进。',
      wuXing: '火',
      direction: '南方',
    ),
    XiaoLiuRenPosition(
      index: 4,
      name: '赤口',
      fortune: '凶',
      keyword: '口舌是非',
      description: '主争执、冲突、言语失和，沟通宜谨慎，忌硬碰硬。',
      wuXing: '金',
      direction: '西方',
    ),
    XiaoLiuRenPosition(
      index: 5,
      name: '小吉',
      fortune: '吉',
      keyword: '小成可望',
      description: '主小利、人和、渐成，虽非大吉，但可稳步见好。',
      wuXing: '木',
      direction: '东方',
    ),
    XiaoLiuRenPosition(
      index: 6,
      name: '空亡',
      fortune: '凶',
      keyword: '事易落空',
      description: '主空耗、落空、消息不实，宜暂缓定论，不可过信。',
      wuXing: '土',
      direction: '中央',
    ),
  ];

  static const List<XiaoLiuRenPosition> _ninePalacePositions = [
    XiaoLiuRenPosition(
      index: 1,
      name: '大安',
      fortune: '吉',
      keyword: '诸事安稳',
      description: '主安稳、平顺、可守可谋，适合按既定节奏推进。',
      wuXing: '木',
      direction: '东方',
    ),
    XiaoLiuRenPosition(
      index: 2,
      name: '留连',
      fortune: '凶',
      keyword: '迟滞反复',
      description: '主拖延、反复、牵扯，事情不宜急推，宜等时机。',
      wuXing: '水',
      direction: '北方',
    ),
    XiaoLiuRenPosition(
      index: 3,
      name: '速喜',
      fortune: '吉',
      keyword: '喜信速来',
      description: '主喜讯、效率、结果加速，利会面、回音、推进。',
      wuXing: '火',
      direction: '南方',
    ),
    XiaoLiuRenPosition(
      index: 4,
      name: '赤口',
      fortune: '凶',
      keyword: '口舌是非',
      description: '主争执、冲突、言语失和，沟通宜谨慎，忌硬碰硬。',
      wuXing: '金',
      direction: '西方',
    ),
    XiaoLiuRenPosition(
      index: 5,
      name: '小吉',
      fortune: '吉',
      keyword: '小成可望',
      description: '主小利、人和、渐成，虽非大吉，但可稳步见好。',
      wuXing: '木',
      direction: '东方',
    ),
    XiaoLiuRenPosition(
      index: 6,
      name: '空亡',
      fortune: '凶',
      keyword: '事易落空',
      description: '主空耗、落空、消息不实，宜暂缓定论，不可过信。',
      wuXing: '土',
      direction: '中央',
    ),
    XiaoLiuRenPosition(
      index: 7,
      name: '病符',
      fortune: '凶',
      keyword: '疾病隐患',
      description: '主病气、损耗、身体不宁、事务暗藏隐患，宜修养避耗。',
      wuXing: '土',
      direction: '东北',
    ),
    XiaoLiuRenPosition(
      index: 8,
      name: '桃花',
      fortune: '平',
      keyword: '人缘情缘',
      description: '主人缘、情缘、社交往来，利联络会面，亦防牵缠纠葛。',
      wuXing: '土',
      direction: '东北',
    ),
    XiaoLiuRenPosition(
      index: 9,
      name: '天德',
      fortune: '吉',
      keyword: '贵人解厄',
      description: '主贵人扶持、德助解厄、转危为安，利求人和解。',
      wuXing: '金',
      direction: '西北',
    ),
  ];

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    if (!supportedMethods.contains(method)) {
      throw UnsupportedError('小六壬不支持的起课方式: ${method.displayName}');
    }

    if (!validateInput(method, input)) {
      throw ArgumentError('输入参数无效');
    }

    final time = castTime ?? DateTime.now();
    final lunarInfo = LunarService.getLunarInfo(time);

    switch (method) {
      case CastMethod.time:
        return _castByTime(time, lunarInfo, input);
      case CastMethod.reportNumber:
        return _castByReportNumber(time, lunarInfo, input);
      case CastMethod.characterStroke:
        return _castByCharacterStroke(time, lunarInfo, input);
      default:
        throw UnsupportedError('小六壬不支持的起课方式: ${method.displayName}');
    }
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return XiaoLiuRenResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    if (!_isValidPalaceModeInput(input['palaceMode'])) {
      return false;
    }

    switch (method) {
      case CastMethod.time:
        return input.isEmpty ||
            (input.length == 1 && input.containsKey('palaceMode'));
      case CastMethod.reportNumber:
        return _hasRequiredIntKeys(
          input,
          const {'firstNumber', 'secondNumber', 'thirdNumber'},
        );
      case CastMethod.characterStroke:
        return _hasRequiredIntKeys(
          input,
          const {'firstStroke', 'secondStroke', 'thirdStroke'},
        );
      default:
        return false;
    }
  }

  XiaoLiuRenResult _castByTime(
    DateTime castTime,
    LunarInfo lunarInfo,
    Map<String, dynamic> input,
  ) {
    final lunar = Solar.fromDate(castTime).getLunar();
    final month = lunar.getMonth().abs();
    final day = lunar.getDay();
    final hourZhi = lunar.getTimeZhi();
    final hourNumber = _hourZhiNumbers[hourZhi]!;
    final palaceMode = _resolvePalaceMode(input);

    return _buildResult(
      castTime: castTime,
      castMethod: CastMethod.time,
      lunarInfo: lunarInfo,
      palaceMode: palaceMode,
      source: XiaoLiuRenSource(
        methodLabel: '时间起课',
        firstNumber: month,
        secondNumber: day,
        thirdNumber: hourNumber,
        firstLabel: '月数',
        secondLabel: '日数',
        thirdLabel: '时数',
        hourZhi: hourZhi,
        usesLunarDate: true,
        rule: '大安起月，月上起日，日上起时；各段均起点记 1 顺推',
        note: '时间起课固定取农历月、农历日与时支',
      ),
    );
  }

  XiaoLiuRenResult _castByReportNumber(
    DateTime castTime,
    LunarInfo lunarInfo,
    Map<String, dynamic> input,
  ) {
    final palaceMode = _resolvePalaceMode(input);

    return _buildResult(
      castTime: castTime,
      castMethod: CastMethod.reportNumber,
      lunarInfo: lunarInfo,
      palaceMode: palaceMode,
      source: XiaoLiuRenSource(
        methodLabel: '报数起课',
        firstNumber: input['firstNumber'] as int,
        secondNumber: input['secondNumber'] as int,
        thirdNumber: input['thirdNumber'] as int,
        firstLabel: '数一',
        secondLabel: '数二',
        thirdLabel: '数三',
        usesLunarDate: false,
        rule: '大安起第一数，首位上起第二数，次位上起第三数；各段均起点记 1 顺推',
        note: '报数起课直接以三个数字作为三段起数',
      ),
    );
  }

  XiaoLiuRenResult _castByCharacterStroke(
    DateTime castTime,
    LunarInfo lunarInfo,
    Map<String, dynamic> input,
  ) {
    final palaceMode = _resolvePalaceMode(input);

    return _buildResult(
      castTime: castTime,
      castMethod: CastMethod.characterStroke,
      lunarInfo: lunarInfo,
      palaceMode: palaceMode,
      source: XiaoLiuRenSource(
        methodLabel: '汉字笔画起',
        firstNumber: input['firstStroke'] as int,
        secondNumber: input['secondStroke'] as int,
        thirdNumber: input['thirdStroke'] as int,
        firstLabel: '首字笔画',
        secondLabel: '次字笔画',
        thirdLabel: '末字笔画',
        usesLunarDate: false,
        rule: '大安起首字笔画，首位上起次字笔画，次位上起末字笔画；各段均起点记 1 顺推',
        note: '当前底层直接接收三段笔画数；自动汉字转笔画将在上层或独立服务实现',
      ),
    );
  }

  XiaoLiuRenResult _buildResult({
    required DateTime castTime,
    required CastMethod castMethod,
    required LunarInfo lunarInfo,
    required XiaoLiuRenPalaceMode palaceMode,
    required XiaoLiuRenSource source,
  }) {
    final positions = _positionsFor(palaceMode);
    final monthPosition = _positionByStep(
      source.firstNumber,
      positions: positions,
    );
    final dayPosition = _positionFrom(
      startIndex: monthPosition.index,
      steps: source.secondNumber,
      positions: positions,
    );
    final hourPosition = _positionFrom(
      startIndex: dayPosition.index,
      steps: source.thirdNumber,
      positions: positions,
    );

    final judgement = _buildJudgement(hourPosition);
    final detail = _buildDetail(
      palaceMode: palaceMode,
      source: source,
      firstPosition: monthPosition,
      secondPosition: dayPosition,
      thirdPosition: hourPosition,
    );

    return XiaoLiuRenResult(
      id: const Uuid().v4(),
      castTime: castTime,
      castMethod: castMethod,
      lunarInfo: lunarInfo,
      palaceMode: palaceMode,
      source: source,
      monthPosition: monthPosition,
      dayPosition: dayPosition,
      hourPosition: hourPosition,
      finalPosition: hourPosition,
      judgement: judgement,
      detail: detail,
    );
  }

  List<XiaoLiuRenPosition> _positionsFor(XiaoLiuRenPalaceMode palaceMode) {
    switch (palaceMode) {
      case XiaoLiuRenPalaceMode.sixPalaces:
        return _sixPalacePositions;
      case XiaoLiuRenPalaceMode.ninePalaces:
        return _ninePalacePositions;
    }
  }

  XiaoLiuRenPosition _positionByStep(
    int step, {
    required List<XiaoLiuRenPosition> positions,
  }) {
    final index = ((step - 1) % positions.length) + 1;
    return positions[index - 1];
  }

  XiaoLiuRenPosition _positionFrom({
    required int startIndex,
    required int steps,
    required List<XiaoLiuRenPosition> positions,
  }) {
    final index = ((startIndex - 1) + (steps - 1)) % positions.length + 1;
    return positions[index - 1];
  }

  String _buildJudgement(XiaoLiuRenPosition position) {
    switch (position.name) {
      case '大安':
        return '大安，主诸事安稳，宜守正稳进。';
      case '留连':
        return '留连，主迟滞反复，宜缓不宜急。';
      case '速喜':
        return '速喜，主喜信速来，利推进与回音。';
      case '赤口':
        return '赤口，主口舌是非，宜谨言慎行。';
      case '小吉':
        return '小吉，主小成可望，利人和与渐进。';
      case '空亡':
        return '空亡，主事易落空，宜暂缓定论。';
      case '病符':
        return '病符，主疾病隐患与暗耗，宜修养避损。';
      case '桃花':
        return '桃花，主人缘情缘与来往牵动，宜明辨分寸。';
      case '天德':
        return '天德，主贵人解厄与转机，利和解求助。';
      default:
        return '${position.name}，待判。';
    }
  }

  String _buildDetail({
    required XiaoLiuRenPalaceMode palaceMode,
    required XiaoLiuRenSource source,
    required XiaoLiuRenPosition firstPosition,
    required XiaoLiuRenPosition secondPosition,
    required XiaoLiuRenPosition thirdPosition,
  }) {
    final thirdDescriptor = source.hourZhi == null
        ? '${source.thirdLabel}${source.thirdNumber}'
        : '时支${source.hourZhi}，${source.thirdLabel}${source.thirdNumber}';

    return '按${palaceMode.displayName}${source.rule}。'
        '${source.firstLabel}${source.firstNumber}落${firstPosition.name}，'
        '${source.secondLabel}${source.secondNumber}从${firstPosition.name}推至${secondPosition.name}，'
        '$thirdDescriptor从${secondPosition.name}推至${thirdPosition.name}。'
        '最终落${thirdPosition.name}，${thirdPosition.description}';
  }

  XiaoLiuRenPalaceMode _resolvePalaceMode(Map<String, dynamic> input) {
    final raw = input['palaceMode'];
    if (raw == null) {
      return XiaoLiuRenPalaceMode.sixPalaces;
    }
    if (raw is String) {
      return XiaoLiuRenPalaceMode.fromId(raw);
    }
    if (raw is XiaoLiuRenPalaceMode) {
      return raw;
    }
    throw ArgumentError('小六壬 palaceMode 参数无效');
  }

  static bool _isValidPalaceModeInput(dynamic raw) {
    if (raw == null) {
      return true;
    }
    if (raw is String) {
      return raw == XiaoLiuRenPalaceMode.sixPalaces.id ||
          raw == XiaoLiuRenPalaceMode.ninePalaces.id;
    }
    return raw is XiaoLiuRenPalaceMode;
  }

  static bool _hasRequiredIntKeys(
    Map<String, dynamic> input,
    Set<String> requiredKeys,
  ) {
    final allowedKeys = {...requiredKeys, 'palaceMode'};
    return input.keys.toSet().containsAll(requiredKeys) &&
        input.keys.every(allowedKeys.contains) &&
        requiredKeys
            .every((key) => input[key] is int && (input[key] as int) > 0);
  }
}
