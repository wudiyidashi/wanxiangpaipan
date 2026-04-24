import '../../divination_systems/liuyao/models/gua.dart';
import '../../divination_systems/liuyao/models/yao.dart';
import 'gua_calculator.dart';

/// 伏神信息。
class FuShen {
  const FuShen({
    required this.position,
    required this.yao,
  });

  /// 伏于本卦第几爻。
  final int position;

  /// 来自本宫纯卦同爻位的爻。
  final Yao yao;

  String get displayText =>
      '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}';
}

/// 六爻伏神计算服务。
class FuShenService {
  FuShenService._();

  /// 计算本卦伏神。
  ///
  /// 以本卦所属八宫的本宫纯卦为来源，找出本卦未出现的六亲，
  /// 并将该六亲在本宫纯卦中的同爻位作为伏神。
  static Map<int, FuShen> calculateFuShen(Gua gua) {
    final visibleLiuQin = gua.yaos.map((yao) => yao.liuQin).toSet();
    final palaceGua = GuaCalculator.calculateGua(
      _guaIdToYaoNumbers(_pureGuaId(gua.baGong)),
      liuQinReferenceBaGong: _baGongName(gua.baGong),
    );

    return <int, FuShen>{
      for (final palaceYao in palaceGua.yaos)
        if (!visibleLiuQin.contains(palaceYao.liuQin))
          palaceYao.position: FuShen(
            position: palaceYao.position,
            yao: palaceYao,
          ),
    };
  }

  static String _pureGuaId(BaGong baGong) {
    return switch (baGong) {
      BaGong.qian => '111111',
      BaGong.kun => '000000',
      BaGong.zhen => '100100',
      BaGong.xun => '011011',
      BaGong.kan => '010010',
      BaGong.li => '101101',
      BaGong.gen => '001001',
      BaGong.dui => '110110',
    };
  }

  static String _baGongName(BaGong baGong) {
    return switch (baGong) {
      BaGong.qian => '乾',
      BaGong.kun => '坤',
      BaGong.zhen => '震',
      BaGong.xun => '巽',
      BaGong.kan => '坎',
      BaGong.li => '离',
      BaGong.gen => '艮',
      BaGong.dui => '兑',
    };
  }

  static List<int> _guaIdToYaoNumbers(String guaId) {
    return guaId
        .split('')
        .map((value) => value == '1' ? 7 : 8)
        .toList(growable: false);
  }
}
