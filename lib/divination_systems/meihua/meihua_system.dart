import 'package:lunar/lunar.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/yao_constants.dart';
import '../../domain/divination_system.dart';
import '../../domain/services/shared/lunar_service.dart';
import 'models/meihua_result.dart';

/// 梅花易数排盘
///
/// 当前实现范围：
/// 1. 时间起卦
/// 2. 数字起卦
/// 3. 手动输入
///
/// 核心排盘链、UI 工厂与 AI formatter 均已落地，第一版正式启用。
/// 第一版边界以 `docs/architecture/divination-systems/meihua.md` 为准：
/// 以体用为主、变卦与互卦为辅，不展开纳甲、六亲、六神、世应。
class MeiHuaSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.meiHua;

  @override
  String get name => '梅花易数';

  @override
  String get description => '梅花易数：以时间、数字或手动方式起卦，围绕本卦、变卦、互卦与体用关系进行占断';

  @override
  bool get isEnabled => true;

  @override
  List<CastMethod> get supportedMethods => [
        CastMethod.time,
        CastMethod.number,
        CastMethod.manual,
      ];

  static const Map<String, int> _diZhiNumbers = {
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

  static const Map<String, String> _wuXingSheng = {
    '金': '水',
    '水': '木',
    '木': '火',
    '火': '土',
    '土': '金',
  };

  static const Map<String, String> _wuXingKe = {
    '金': '木',
    '木': '土',
    '土': '水',
    '水': '火',
    '火': '金',
  };

  static const Map<int, _TrigramDefinition> _trigramByNumber = {
    1: _TrigramDefinition('qian', '乾', '天', '金', 1, [1, 1, 1]),
    2: _TrigramDefinition('dui', '兑', '泽', '金', 2, [1, 1, 0]),
    3: _TrigramDefinition('li', '离', '火', '火', 3, [1, 0, 1]),
    4: _TrigramDefinition('zhen', '震', '雷', '木', 4, [1, 0, 0]),
    5: _TrigramDefinition('xun', '巽', '风', '木', 5, [0, 1, 1]),
    6: _TrigramDefinition('kan', '坎', '水', '水', 6, [0, 1, 0]),
    7: _TrigramDefinition('gen', '艮', '山', '土', 7, [0, 0, 1]),
    8: _TrigramDefinition('kun', '坤', '地', '土', 8, [0, 0, 0]),
  };

  static final Map<String, _TrigramDefinition> _trigramByName = {
    for (final definition in _trigramByNumber.values)
      definition.name: definition,
  };

  static final Map<String, _TrigramDefinition> _trigramByCode = {
    for (final definition in _trigramByNumber.values)
      _linesToCode(definition.lines): definition,
  };

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    if (!validateInput(method, input)) {
      throw ArgumentError('输入参数无效');
    }

    final time = castTime ?? DateTime.now();
    final lunarInfo = LunarService.getLunarInfo(time);
    final seed = _buildSeed(
      method: method,
      input: input,
      castTime: time,
    );

    final benGua = _buildHexagram(
      upperTrigram: seed.upperTrigram,
      lowerTrigram: seed.lowerTrigram,
    );
    final bianGua = _deriveChangingHexagram(
      benGua: benGua,
      movingLine: seed.movingLine,
    );
    final huGua = _deriveHuHexagram(benGua);
    final bodyUse = _determineBodyUse(
      benGua: benGua,
      movingLine: seed.movingLine,
    );
    final wuXingRelation = _analyzeWuXingRelation(
      tiGua: bodyUse.tiGua,
      yongGua: bodyUse.yongGua,
    );

    return MeiHuaResult(
      id: const Uuid().v4(),
      castTime: time,
      castMethod: method,
      lunarInfo: lunarInfo,
      source: seed.source,
      benGua: benGua,
      bianGua: bianGua,
      huGua: huGua,
      movingLine: seed.movingLine,
      tiGua: bodyUse.tiGua,
      yongGua: bodyUse.yongGua,
      bodyUseRule: bodyUse.rule,
      wuXingRelation: wuXingRelation,
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return MeiHuaResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    switch (method) {
      case CastMethod.time:
        return input.isEmpty;
      case CastMethod.number:
        return _hasExactKeys(input, const {'upperNumber', 'lowerNumber'}) &&
            input['upperNumber'] is int &&
            input['lowerNumber'] is int &&
            (input['upperNumber'] as int) > 0 &&
            (input['lowerNumber'] as int) > 0;
      case CastMethod.manual:
        return _hasExactKeys(
              input,
              const {'upperTrigram', 'lowerTrigram', 'movingLine'},
            ) &&
            input['upperTrigram'] is String &&
            input['lowerTrigram'] is String &&
            _trigramByName.containsKey(input['upperTrigram']) &&
            _trigramByName.containsKey(input['lowerTrigram']) &&
            input['movingLine'] is int &&
            (input['movingLine'] as int) >= 1 &&
            (input['movingLine'] as int) <= 6;
      default:
        return false;
    }
  }

  _CastSeed _buildSeed({
    required CastMethod method,
    required Map<String, dynamic> input,
    required DateTime castTime,
  }) {
    switch (method) {
      case CastMethod.time:
        return _buildTimeSeed(castTime);
      case CastMethod.number:
        return _buildNumberSeed(
          upperInputNumber: input['upperNumber'] as int,
          lowerInputNumber: input['lowerNumber'] as int,
        );
      case CastMethod.manual:
        return _buildManualSeed(
          upperTrigramName: input['upperTrigram'] as String,
          lowerTrigramName: input['lowerTrigram'] as String,
          movingLine: input['movingLine'] as int,
        );
      default:
        throw UnsupportedError('梅花易数不支持的起卦方式: ${method.displayName}');
    }
  }

  _CastSeed _buildTimeSeed(DateTime castTime) {
    final lunar = Solar.fromDate(castTime).getLunar();
    final yearBranch = lunar.getYearZhi();
    final yearNumber = _diZhiNumbers[yearBranch];
    final monthNumber = lunar.getMonth().abs();
    final dayNumber = lunar.getDay();
    final hourBranch = lunar.getTimeZhi();
    final hourNumber = _diZhiNumbers[hourBranch];

    if (yearNumber == null || hourNumber == null) {
      throw StateError('无法识别的地支数映射: $yearBranch / $hourBranch');
    }

    final upperRawValue = yearNumber + monthNumber + dayNumber;
    final lowerRawValue = upperRawValue + hourNumber;
    final movingRawValue = lowerRawValue;

    final upperNumber = _normalizeModulo(upperRawValue, 8);
    final lowerNumber = _normalizeModulo(lowerRawValue, 8);
    final movingLine = _normalizeModulo(movingRawValue, 6);

    final upperTrigram = _trigramByNumber[upperNumber]!.toModel();
    final lowerTrigram = _trigramByNumber[lowerNumber]!.toModel();

    return _CastSeed(
      upperTrigram: upperTrigram,
      lowerTrigram: lowerTrigram,
      movingLine: movingLine,
      source: MeiHuaSource(
        methodLabel: '时间起卦',
        upperNumber: upperNumber,
        lowerNumber: lowerNumber,
        movingLineNumber: movingLine,
        upperRawValue: upperRawValue,
        lowerRawValue: lowerRawValue,
        movingRawValue: movingRawValue,
        yearBranch: yearBranch,
        yearNumber: yearNumber,
        monthNumber: monthNumber,
        dayNumber: dayNumber,
        hourBranch: hourBranch,
        hourNumber: hourNumber,
        note: '取农历年支数、月数、日数、时支数推上卦、下卦与动爻',
      ),
    );
  }

  _CastSeed _buildNumberSeed({
    required int upperInputNumber,
    required int lowerInputNumber,
  }) {
    final upperNumber = _normalizeModulo(upperInputNumber, 8);
    final lowerNumber = _normalizeModulo(lowerInputNumber, 8);
    final movingLine = _normalizeModulo(upperInputNumber + lowerInputNumber, 6);

    return _CastSeed(
      upperTrigram: _trigramByNumber[upperNumber]!.toModel(),
      lowerTrigram: _trigramByNumber[lowerNumber]!.toModel(),
      movingLine: movingLine,
      source: MeiHuaSource(
        methodLabel: '数字起卦',
        upperNumber: upperNumber,
        lowerNumber: lowerNumber,
        movingLineNumber: movingLine,
        upperRawValue: upperInputNumber,
        lowerRawValue: lowerInputNumber,
        movingRawValue: upperInputNumber + lowerInputNumber,
        upperInputNumber: upperInputNumber,
        lowerInputNumber: lowerInputNumber,
        note: '以上数取上卦，以下数取下卦，两数之和取动爻',
      ),
    );
  }

  _CastSeed _buildManualSeed({
    required String upperTrigramName,
    required String lowerTrigramName,
    required int movingLine,
  }) {
    final upperTrigram = _trigramByName[upperTrigramName]!.toModel();
    final lowerTrigram = _trigramByName[lowerTrigramName]!.toModel();

    return _CastSeed(
      upperTrigram: upperTrigram,
      lowerTrigram: lowerTrigram,
      movingLine: movingLine,
      source: MeiHuaSource(
        methodLabel: '手动输入',
        upperNumber: upperTrigram.number,
        lowerNumber: lowerTrigram.number,
        movingLineNumber: movingLine,
        manualUpperTrigram: upperTrigram.name,
        manualLowerTrigram: lowerTrigram.name,
        note: '本卦与动爻由用户直接指定',
      ),
    );
  }

  MeiHuaHexagram _buildHexagram({
    required MeiHuaTrigram upperTrigram,
    required MeiHuaTrigram lowerTrigram,
  }) {
    final lines = [...lowerTrigram.lines, ...upperTrigram.lines];
    final code = _linesToCode(lines);
    final name = YaoConstants.guaNames[code];
    if (name == null) {
      throw StateError('未定义的梅花卦编码: $code');
    }

    return MeiHuaHexagram(
      code: code,
      name: name,
      upperTrigram: upperTrigram,
      lowerTrigram: lowerTrigram,
      lines: lines,
    );
  }

  MeiHuaHexagram _deriveChangingHexagram({
    required MeiHuaHexagram benGua,
    required int movingLine,
  }) {
    final changedLines = List<int>.from(benGua.lines);
    final index = movingLine - 1;
    changedLines[index] = changedLines[index] == 1 ? 0 : 1;

    return _buildHexagram(
      upperTrigram: _trigramFromLines(changedLines.sublist(3, 6)),
      lowerTrigram: _trigramFromLines(changedLines.sublist(0, 3)),
    );
  }

  MeiHuaHexagram _deriveHuHexagram(MeiHuaHexagram benGua) {
    final lowerLines = benGua.lines.sublist(1, 4);
    final upperLines = benGua.lines.sublist(2, 5);

    return _buildHexagram(
      upperTrigram: _trigramFromLines(upperLines),
      lowerTrigram: _trigramFromLines(lowerLines),
    );
  }

  _BodyUseResult _determineBodyUse({
    required MeiHuaHexagram benGua,
    required int movingLine,
  }) {
    if (movingLine <= 3) {
      return _BodyUseResult(
        tiGua: benGua.upperTrigram,
        yongGua: benGua.lowerTrigram,
        rule: '动爻落下卦（1-3爻），下卦为用，上卦为体',
      );
    }

    return _BodyUseResult(
      tiGua: benGua.lowerTrigram,
      yongGua: benGua.upperTrigram,
      rule: '动爻落上卦（4-6爻），上卦为用，下卦为体',
    );
  }

  String _analyzeWuXingRelation({
    required MeiHuaTrigram tiGua,
    required MeiHuaTrigram yongGua,
  }) {
    if (tiGua.wuXing == yongGua.wuXing) {
      return '体用比和';
    }
    if (_wuXingSheng[tiGua.wuXing] == yongGua.wuXing) {
      return '体生用';
    }
    if (_wuXingSheng[yongGua.wuXing] == tiGua.wuXing) {
      return '用生体';
    }
    if (_wuXingKe[tiGua.wuXing] == yongGua.wuXing) {
      return '体克用';
    }
    if (_wuXingKe[yongGua.wuXing] == tiGua.wuXing) {
      return '用克体';
    }
    throw StateError('无法识别的五行关系: ${tiGua.wuXing} / ${yongGua.wuXing}');
  }

  MeiHuaTrigram _trigramFromLines(List<int> lines) {
    final definition = _trigramByCode[_linesToCode(lines)];
    if (definition == null) {
      throw StateError('未定义的三爻卦编码: ${_linesToCode(lines)}');
    }
    return definition.toModel();
  }

  static bool _hasExactKeys(
    Map<String, dynamic> input,
    Set<String> expectedKeys,
  ) {
    return input.keys.toSet().containsAll(expectedKeys) &&
        input.keys.length == expectedKeys.length;
  }

  static int _normalizeModulo(int value, int divisor) {
    final remainder = value % divisor;
    return remainder == 0 ? divisor : remainder;
  }

  static String _linesToCode(List<int> lines) => lines.join();
}

class _CastSeed {
  final MeiHuaTrigram upperTrigram;
  final MeiHuaTrigram lowerTrigram;
  final int movingLine;
  final MeiHuaSource source;

  const _CastSeed({
    required this.upperTrigram,
    required this.lowerTrigram,
    required this.movingLine,
    required this.source,
  });
}

class _BodyUseResult {
  final MeiHuaTrigram tiGua;
  final MeiHuaTrigram yongGua;
  final String rule;

  const _BodyUseResult({
    required this.tiGua,
    required this.yongGua,
    required this.rule,
  });
}

class _TrigramDefinition {
  final String key;
  final String name;
  final String symbol;
  final String wuXing;
  final int number;
  final List<int> lines;

  const _TrigramDefinition(
    this.key,
    this.name,
    this.symbol,
    this.wuXing,
    this.number,
    this.lines,
  );

  MeiHuaTrigram toModel() {
    return MeiHuaTrigram(
      key: key,
      name: name,
      symbol: symbol,
      wuXing: wuXing,
      number: number,
      lines: lines,
    );
  }
}
