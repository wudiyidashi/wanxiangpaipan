import 'package:uuid/uuid.dart';
import '../../domain/divination_system.dart';
import '../../domain/services/qigua_service.dart';
import '../../domain/services/gua_calculator.dart';
import '../../domain/services/shared/lunar_service.dart';
import '../../domain/services/liushen_service.dart';
import 'liuyao_result.dart';

enum LiuYaoManualInputMode {
  yaoNumbers('yaoNumbers'),
  coinInputs('coinInputs');

  const LiuYaoManualInputMode(this.id);

  final String id;

  static LiuYaoManualInputMode fromId(String id) {
    return LiuYaoManualInputMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw ArgumentError('未知的六爻手动输入模式: $id'),
    );
  }
}

/// 六爻排盘
///
/// 实现 DivinationSystem 接口，提供六爻占卜的完整功能。
/// 支持六种起卦方式：钱币卦、爻名卦、数字卦、报数卦、时间卦、电脑卦。
class LiuYaoSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.liuYao;

  @override
  String get name => '六爻';

  @override
  String get description => '周易六爻占卜，通过摇钱法或时间起卦生成卦象，分析世应、六亲、动爻等要素进行占断';

  @override
  List<CastMethod> get supportedMethods => [
        CastMethod.coin,
        CastMethod.manual,
        CastMethod.number,
        CastMethod.reportNumber,
        CastMethod.time,
        CastMethod.computer,
      ];

  @override
  bool get isEnabled => true;

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    // 验证输入
    if (!validateInput(method, input)) {
      throw ArgumentError('输入参数无效');
    }

    final time = castTime ?? DateTime.now();

    // 1. 根据起卦方式生成爻数
    final List<int> yaoNumbers;
    switch (method) {
      case CastMethod.coin:
        yaoNumbers = QiGuaService.coinCast();
        break;

      case CastMethod.time:
        yaoNumbers = QiGuaService.timeCast(time);
        break;

      case CastMethod.manual:
        switch (_getManualInputMode(input)) {
          case LiuYaoManualInputMode.yaoNumbers:
            yaoNumbers = List<int>.from(input['yaoNumbers'] as List);
            break;
          case LiuYaoManualInputMode.coinInputs:
            final coinInputs = (input['coinInputs'] as List)
                .map((coins) => List<CoinFace>.from(coins as List))
                .toList();
            yaoNumbers = QiGuaService.manualCast(coinInputs);
            break;
        }
        break;

      case CastMethod.number:
        final number = input['number'] as int;
        yaoNumbers = QiGuaService.numberCast(number);
        break;

      case CastMethod.reportNumber:
        final upperNum = input['upperNum'] as int;
        final lowerNum = input['lowerNum'] as int;
        final movingNum = input['movingNum'] as int;
        yaoNumbers =
            QiGuaService.reportNumberCast(upperNum, lowerNum, movingNum);
        break;

      case CastMethod.computer:
        yaoNumbers = QiGuaService.computerCast();
        break;
    }

    // 2. 计算农历信息
    final lunarInfo = LunarService.getLunarInfo(time);

    // 3. 计算主卦
    final mainGua = GuaCalculator.calculateGua(yaoNumbers);

    // 4. 计算变卦（如有动爻）
    final changingGua = GuaCalculator.generateChangingGua(mainGua);

    // 5. 计算六神
    final liuShen = LiuShenService.calculateLiuShen(lunarInfo.riGan);

    // 6. 创建六爻结果
    return LiuYaoResult(
      id: const Uuid().v4(),
      castTime: time,
      castMethod: method,
      mainGua: mainGua,
      changingGua: changingGua,
      lunarInfo: lunarInfo,
      liuShen: liuShen,
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return LiuYaoResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    switch (method) {
      case CastMethod.coin:
      case CastMethod.time:
      case CastMethod.computer:
        return true;

      case CastMethod.manual:
        final manualMode = _tryGetManualInputMode(input);
        if (manualMode == null) {
          return false;
        }

        switch (manualMode) {
          case LiuYaoManualInputMode.yaoNumbers:
            final yaoNumbers = input['yaoNumbers'];
            if (yaoNumbers is! List || yaoNumbers.length != 6) {
              return false;
            }
            return yaoNumbers.every((n) => n is int && n >= 6 && n <= 9);
          case LiuYaoManualInputMode.coinInputs:
            final coinInputs = input['coinInputs'];
            if (coinInputs is! List || coinInputs.length != 6) {
              return false;
            }
            return coinInputs.every(
              (coins) =>
                  coins is List &&
                  coins.length == 3 &&
                  coins.every((coin) => coin is CoinFace),
            );
        }

      case CastMethod.number:
        return input.containsKey('number') && input['number'] is int;

      case CastMethod.reportNumber:
        return input.containsKey('upperNum') &&
            input['upperNum'] is int &&
            input.containsKey('lowerNum') &&
            input['lowerNum'] is int &&
            input.containsKey('movingNum') &&
            input['movingNum'] is int;
    }
  }

  /// 便捷方法：摇钱法起卦
  Future<LiuYaoResult> castByCoin({DateTime? castTime}) async {
    final result = await cast(
      method: CastMethod.coin,
      input: {},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：时间起卦
  Future<LiuYaoResult> castByTime({DateTime? castTime}) async {
    final result = await cast(
      method: CastMethod.time,
      input: {},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：爻名卦（手动输入爻数）
  Future<LiuYaoResult> castByManualYaoNumbers(
    List<int> yaoNumbers, {
    DateTime? castTime,
  }) async {
    final result = await cast(
      method: CastMethod.manual,
      input: {
        'manualMode': LiuYaoManualInputMode.yaoNumbers.id,
        'yaoNumbers': yaoNumbers,
      },
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：手动输入硬币正反面
  Future<LiuYaoResult> castByManualCoins(
    List<List<CoinFace>> coinInputs, {
    DateTime? castTime,
  }) async {
    final result = await cast(
      method: CastMethod.manual,
      input: {
        'manualMode': LiuYaoManualInputMode.coinInputs.id,
        'coinInputs': coinInputs,
      },
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：数字卦
  Future<LiuYaoResult> castByNumber(int number, {DateTime? castTime}) async {
    final result = await cast(
      method: CastMethod.number,
      input: {'number': number},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：报数卦
  Future<LiuYaoResult> castByReportNumber(
    int upperNum,
    int lowerNum,
    int movingNum, {
    DateTime? castTime,
  }) async {
    final result = await cast(
      method: CastMethod.reportNumber,
      input: {
        'upperNum': upperNum,
        'lowerNum': lowerNum,
        'movingNum': movingNum,
      },
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：电脑卦
  Future<LiuYaoResult> castByComputer({DateTime? castTime}) async {
    final result = await cast(
      method: CastMethod.computer,
      input: {},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  LiuYaoManualInputMode _getManualInputMode(Map<String, dynamic> input) {
    final rawMode = input['manualMode'];
    if (rawMode is! String) {
      throw ArgumentError('爻名卦需要提供 manualMode 参数');
    }

    return LiuYaoManualInputMode.fromId(rawMode);
  }

  LiuYaoManualInputMode? _tryGetManualInputMode(Map<String, dynamic> input) {
    try {
      return _getManualInputMode(input);
    } catch (_) {
      return null;
    }
  }
}
