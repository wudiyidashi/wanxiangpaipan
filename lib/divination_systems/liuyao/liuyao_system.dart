import 'package:uuid/uuid.dart';
import '../../domain/divination_system.dart';
import '../../domain/services/qigua_service.dart';
import '../../domain/services/gua_calculator.dart';
import '../../domain/services/shared/lunar_service.dart';
import '../../domain/services/liushen_service.dart';
import 'liuyao_result.dart';

/// 六爻排盘
///
/// 实现 DivinationSystem 接口，提供六爻占卜的完整功能。
/// 支持三种起卦方式：摇钱法、时间起卦、手动输入。
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
        CastMethod.time,
        CastMethod.manual,
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
        // 手动输入支持两种格式：
        // 1. 直接提供爻数数组: {'yaoNumbers': [7, 8, 9, 6, 7, 8]}
        // 2. 提供硬币正反面: {'coinInputs': [[CoinFace.front, ...], ...]}
        if (input.containsKey('yaoNumbers')) {
          yaoNumbers = List<int>.from(input['yaoNumbers'] as List);
        } else if (input.containsKey('coinInputs')) {
          final coinInputs =
              input['coinInputs'] as List<List<CoinFace>>;
          yaoNumbers = QiGuaService.manualCast(coinInputs);
        } else {
          throw ArgumentError('手动输入需要提供 yaoNumbers 或 coinInputs 参数');
        }
        break;

      default:
        throw UnsupportedError('不支持的起卦方式: $method');
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
        // 摇钱法不需要输入参数
        return true;

      case CastMethod.time:
        // 时间起卦不需要额外输入参数（使用 castTime）
        return true;

      case CastMethod.manual:
        // 手动输入需要验证参数
        if (input.containsKey('yaoNumbers')) {
          final yaoNumbers = input['yaoNumbers'];
          if (yaoNumbers is! List || yaoNumbers.length != 6) {
            return false;
          }
          // 验证每个爻数是否在 6-9 之间
          return yaoNumbers.every((n) => n is int && n >= 6 && n <= 9);
        } else if (input.containsKey('coinInputs')) {
          final coinInputs = input['coinInputs'];
          if (coinInputs is! List || coinInputs.length != 6) {
            return false;
          }
          // 验证每次投掷是否有 3 枚硬币
          return coinInputs.every((coins) =>
              coins is List<CoinFace> && coins.length == 3);
        }
        return false;

      default:
        return false;
    }
  }

  /// 便捷方法：摇钱法起卦
  ///
  /// 这是一个便捷方法，简化摇钱法起卦的调用。
  Future<LiuYaoResult> castByCoin({DateTime? castTime}) async {
    final result = await cast(
      method: CastMethod.coin,
      input: {},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：时间起卦
  ///
  /// 这是一个便捷方法，简化时间起卦的调用。
  Future<LiuYaoResult> castByTime({DateTime? castTime}) async {
    final result = await cast(
      method: CastMethod.time,
      input: {},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：手动输入爻数
  ///
  /// 这是一个便捷方法，简化手动输入的调用。
  ///
  /// [yaoNumbers] 6 个爻数（从下到上），每个爻数必须在 6-9 之间
  Future<LiuYaoResult> castByManualYaoNumbers(
    List<int> yaoNumbers, {
    DateTime? castTime,
  }) async {
    final result = await cast(
      method: CastMethod.manual,
      input: {'yaoNumbers': yaoNumbers},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }

  /// 便捷方法：手动输入硬币正反面
  ///
  /// 这是一个便捷方法，简化手动输入的调用。
  ///
  /// [coinInputs] 6 次投掷，每次 3 枚硬币的正反面
  Future<LiuYaoResult> castByManualCoins(
    List<List<CoinFace>> coinInputs, {
    DateTime? castTime,
  }) async {
    final result = await cast(
      method: CastMethod.manual,
      input: {'coinInputs': coinInputs},
      castTime: castTime,
    );
    return result as LiuYaoResult;
  }
}
