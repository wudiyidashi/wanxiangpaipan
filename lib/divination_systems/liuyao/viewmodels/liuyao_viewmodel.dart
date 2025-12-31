import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/qigua_service.dart';
import '../../../domain/services/shared/liuqin_service.dart';
import '../../../domain/services/shared/wuxing_service.dart';
import '../../../viewmodels/divination_viewmodel.dart';
import '../liuyao_result.dart';
import '../liuyao_system.dart';
import '../models/gua.dart';
import '../models/yao.dart';

/// 六爻 ViewModel
///
/// 继承自 DivinationViewModel<LiuYaoResult>，提供六爻特定的功能。
/// 使用泛型确保类型安全，result 属性直接返回 LiuYaoResult 类型。
class LiuYaoViewModel extends DivinationViewModel<LiuYaoResult> {
  /// 构造函数
  LiuYaoViewModel({
    required LiuYaoSystem system,
    required DivinationRepository repository,
  }) : super(system: system, repository: repository);

  // ==================== 六爻特定的便捷属性 ====================

  /// 获取主卦
  Gua? get mainGua => result?.mainGua;

  /// 获取变卦
  Gua? get changingGua => result?.changingGua;

  /// 获取六神列表
  List<String>? get liuShen => result?.liuShen;

  /// 是否有变卦
  bool get hasChangingGua => result?.hasChangingGua ?? false;

  /// 是否有动爻
  bool get hasMovingYao => result?.hasMovingYao ?? false;

  /// 获取世爻
  Yao? get seYao => result?.seYao;

  /// 获取应爻
  Yao? get yingYao => result?.yingYao;

  /// 获取所有动爻
  List<Yao> get movingYaos => result?.movingYaos ?? [];

  /// 获取卦名
  String? get guaName => result?.mainGua.name;

  /// 获取八宫
  String? get baGong => result?.mainGua.baGong.name;

  // ==================== 六爻特定的便捷方法 ====================

  /// 摇钱法起卦
  ///
  /// 这是一个便捷方法，简化摇钱法起卦的调用。
  Future<void> castByCoin({DateTime? castTime}) async {
    await cast(
      method: CastMethod.coin,
      input: {},
      castTime: castTime,
    );
  }

  /// 时间起卦
  ///
  /// 这是一个便捷方法，简化时间起卦的调用。
  Future<void> castByTime({DateTime? castTime}) async {
    await cast(
      method: CastMethod.time,
      input: {},
      castTime: castTime,
    );
  }

  /// 手动输入爻数起卦
  ///
  /// [yaoNumbers] 6 个爻数（从下到上），每个爻数必须在 6-9 之间
  /// [question] 占问事宜（可选）
  Future<void> castByManualYaoNumbers(
    List<int> yaoNumbers, {
    DateTime? castTime,
    String? question,
  }) async {
    final input = <String, dynamic>{'yaoNumbers': yaoNumbers};

    await cast(
      method: CastMethod.manual,
      input: input,
      castTime: castTime,
    );

    // 起卦成功后保存记录和占问信息
    if (hasResult) {
      await saveRecord(question: question);
    }
  }

  /// 手动输入硬币正反面起卦
  ///
  /// [coinInputs] 6 次投掷，每次 3 枚硬币的正反面
  Future<void> castByManualCoins(
    List<List<CoinFace>> coinInputs, {
    DateTime? castTime,
  }) async {
    await cast(
      method: CastMethod.manual,
      input: {'coinInputs': coinInputs},
      castTime: castTime,
    );
  }

  // ==================== 六爻特定的分析方法 ====================

  /// 获取指定位置的爻
  ///
  /// [position] 爻位（1-6）
  /// 返回对应位置的爻，如果位置无效返回 null
  Yao? getYaoAtPosition(int position) {
    if (mainGua == null || position < 1 || position > 6) {
      return null;
    }
    return mainGua!.yaos[position - 1];
  }

  /// 获取指定六亲的所有爻
  ///
  /// [liuQin] 六亲类型
  /// 返回该六亲的所有爻列表
  List<Yao> getYaosByLiuQin(LiuQin liuQin) {
    if (mainGua == null) return [];
    return mainGua!.yaos.where((yao) => yao.liuQin == liuQin).toList();
  }

  /// 获取指定五行的所有爻
  ///
  /// [wuXing] 五行类型
  /// 返回该五行的所有爻列表
  List<Yao> getYaosByWuXing(WuXing wuXing) {
    if (mainGua == null) return [];
    return mainGua!.yaos.where((yao) => yao.wuXing == wuXing).toList();
  }

  /// 检查是否有指定六亲的动爻
  ///
  /// [liuQin] 六亲类型
  /// 返回 true 如果有该六亲的动爻
  bool hasMovingYaoWithLiuQin(LiuQin liuQin) {
    return movingYaos.any((yao) => yao.liuQin == liuQin);
  }

  /// 获取卦象摘要信息
  ///
  /// 返回包含卦名、八宫、世应位置等信息的字符串
  String getGuaSummary() {
    if (result == null) return '暂无卦象';

    final buffer = StringBuffer();
    buffer.writeln('卦名：${result!.mainGua.name}');
    buffer.writeln('八宫：${result!.mainGua.baGong.name}');
    buffer.writeln('世爻：第${result!.mainGua.seYaoPosition}爻');
    buffer.writeln('应爻：第${result!.mainGua.yingYaoPosition}爻');

    if (hasChangingGua) {
      buffer.writeln('变卦：${result!.changingGua!.name}');
    }

    if (hasMovingYao) {
      buffer
          .writeln('动爻：${movingYaos.map((y) => '第${y.position}爻').join('、')}');
    }

    return buffer.toString();
  }
}
