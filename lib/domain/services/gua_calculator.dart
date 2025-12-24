import '../../core/constants/yao_constants.dart';
import '../../divination_systems/liuyao/models/gua.dart';
import '../../divination_systems/liuyao/models/yao.dart';
import 'shared/wuxing_service.dart';
import 'shared/liuqin_service.dart';

/// 六爻卦象计算服务
class GuaCalculator {
  GuaCalculator._();

  /// 根据六个爻数计算完整卦象
  static Gua calculateGua(
    List<int> yaoNumbers, {
    String? liuQinReferenceBaGong,
  }) {
    _validateYaoNumbers(yaoNumbers);

    final guaId = _identifyGuaId(yaoNumbers);
    final guaName = YaoConstants.guaNames[guaId];
    if (guaName == null) {
      throw StateError('未定义的卦象ID：$guaId');
    }

    final baGongName = YaoConstants.guaToBaGong[guaId];
    if (baGongName == null) {
      throw StateError('未定义的八宫：$guaId');
    }
    final baGong = _stringToBaGong(baGongName);
    final seYaoPos = YaoConstants.guaToSeYaoPos[guaId];
    if (seYaoPos == null) {
      throw StateError('未定义的世爻位置：$guaId');
    }
    final yingYaoPos = _getYingYaoPosition(seYaoPos);

    final liuQinGongName = liuQinReferenceBaGong ?? baGongName;

    final yaos = List.generate(6, (i) {
      return _calculateYaoAttributes(
        position: i + 1,
        yaoNumber: yaoNumbers[i],
        guaId: guaId,
        liuQinGongName: liuQinGongName,
        seYaoPos: seYaoPos,
        yingYaoPos: yingYaoPos,
      );
    });

    final specialType = _getSpecialType(guaId);

    return Gua(
      id: guaId,
      name: guaName,
      yaos: yaos,
      baGong: baGong,
      seYaoPosition: seYaoPos,
      yingYaoPosition: yingYaoPos,
      specialType: specialType,
    );
  }

  /// 获取卦的特殊类型
  static GuaSpecialType _getSpecialType(String guaId) {
    final typeStr = YaoConstants.guaSpecialType[guaId];
    if (typeStr == null) return GuaSpecialType.none;

    switch (typeStr) {
      case '六冲':
        return GuaSpecialType.liuChong;
      case '六合':
        return GuaSpecialType.liuHe;
      case '游魂':
        return GuaSpecialType.youHun;
      case '归魂':
        return GuaSpecialType.guiHun;
      default:
        return GuaSpecialType.none;
    }
  }

  /// 识别卦象ID（二进制表示）
  static String _identifyGuaId(List<int> yaoNumbers) {
    return yaoNumbers.map((n) => n == 7 || n == 9 ? '1' : '0').join();
  }

  /// 计算应爻位置（世应相距三爻）
  static int _getYingYaoPosition(int seYaoPos) {
    return seYaoPos <= 3 ? seYaoPos + 3 : seYaoPos - 3;
  }

  /// 计算单个爻的属性
  static Yao _calculateYaoAttributes({
    required int position,
    required int yaoNumber,
    required String guaId,
    required String liuQinGongName,
    required int seYaoPos,
    required int yingYaoPos,
  }) {
    final number = _intToYaoNumber(yaoNumber);
    final branch = _getNaJiaBranch(guaId, position);
    final stem = _getNaJiaStem(guaId, position);
    final wuXing = _branchToWuXing(branch);
    final liuQin = _calculateLiuQin(liuQinGongName, wuXing);

    return Yao(
      position: position,
      number: number,
      branch: branch,
      stem: stem,
      liuQin: liuQin,
      wuXing: wuXing,
      isSeYao: position == seYaoPos,
      isYingYao: position == yingYaoPos,
    );
  }

  /// 获取纳甲地支
  static String _getNaJiaBranch(String guaId, int position) {
    final branches = YaoConstants.guaToBranches[guaId];
    if (branches == null || position > branches.length) {
      throw StateError('未找到 $guaId 的纳甲地支配置');
    }
    return branches[position - 1];
  }

  /// 获取纳甲天干
  static String _getNaJiaStem(String guaId, int position) {
    final stems = YaoConstants.guaToStems[guaId];
    if (stems == null || position > stems.length) {
      throw StateError('未找到 $guaId 的纳甲天干配置');
    }
    return stems[position - 1];
  }

  /// 地支转五行
  static WuXing _branchToWuXing(String branch) {
    return WuXingService.getWuXingFromBranch(branch) ?? WuXing.mu;
  }

  /// 计算六亲
  static LiuQin _calculateLiuQin(String baGongName, WuXing yaoWuXing) {
    return LiuQinService.calculateLiuQinByGongName(baGongName, yaoWuXing) ?? LiuQin.xiongDi;
  }

  /// 生成变卦
  static Gua? generateChangingGua(Gua mainGua) {
    if (!mainGua.hasMovingYao) return null;

    final changedYaoNumbers = mainGua.yaos.map((yao) {
      if (yao.isMoving) {
        return yao.isYin ? 7 : 8;
      }
      return yao.number.value;
    }).toList();

    final mainBaGongName = _baGongToString(mainGua.baGong);
    return calculateGua(
      changedYaoNumbers,
      liuQinReferenceBaGong: mainBaGongName,
    );
  }

  /// 辅助方法：int 转 YaoNumber
  static YaoNumber _intToYaoNumber(int value) {
    return YaoNumber.values.firstWhere((e) => e.value == value);
  }

  /// 辅助方法：String 转 BaGong
  static BaGong _stringToBaGong(String value) {
    const map = {
      '乾': BaGong.qian,
      '坤': BaGong.kun,
      '震': BaGong.zhen,
      '巽': BaGong.xun,
      '坎': BaGong.kan,
      '离': BaGong.li,
      '艮': BaGong.gen,
      '兑': BaGong.dui,
    };
    return map[value] ?? BaGong.qian;
  }

  static String _baGongToString(BaGong baGong) {
    switch (baGong) {
      case BaGong.qian:
        return '乾';
      case BaGong.kun:
        return '坤';
      case BaGong.zhen:
        return '震';
      case BaGong.xun:
        return '巽';
      case BaGong.kan:
        return '坎';
      case BaGong.li:
        return '离';
      case BaGong.gen:
        return '艮';
      case BaGong.dui:
        return '兑';
    }
  }

  static void _validateYaoNumbers(List<int> yaoNumbers) {
    if (yaoNumbers.length != 6) {
      throw ArgumentError.value(yaoNumbers.length, 'yaoNumbers', '必须提供6个爻数');
    }
    for (final value in yaoNumbers) {
      if (value < 6 || value > 9) {
        throw ArgumentError.value(value, 'yaoNumbers', '爻数必须在6到9之间');
      }
    }
  }
}
