import '../../../shared/tiangan_dizhi_service.dart';
import '../../../shared/wuxing_service.dart';

/// 十二长生阶段（顺行）
enum ChangShengStage {
  changSheng('长生'),
  muYu('沐浴'),
  guanDai('冠带'),
  linGuan('临官'),
  diWang('帝旺'),
  shuai('衰'),
  bing('病'),
  si('死'),
  mu('墓'),
  jue('绝'),
  tai('胎'),
  yang('养');

  const ChangShengStage(this.name);
  final String name;
}

/// 五行十二长生表。
///
/// 六爻以五行论长生（不分阴阳干），水土同宫：
/// 金长生巳、木长生亥、火长生寅、水土长生申，皆顺行十二支。
/// 规则依据《增删卜易》。所有方法均为纯静态函数。
class ChangShengTable {
  ChangShengTable._();

  /// 各五行长生所在地支
  static const Map<WuXing, String> changShengBranch = {
    WuXing.jin: '巳',
    WuXing.mu: '亥',
    WuXing.huo: '寅',
    WuXing.shui: '申',
    WuXing.tu: '申', // 水土同宫
  };

  /// [wuXing] 在 [branch] 上的长生阶段
  static ChangShengStage getStage(WuXing wuXing, String branch) {
    final startIndex =
        TianGanDiZhiService.getDiZhiIndex(changShengBranch[wuXing]!);
    final branchIndex = TianGanDiZhiService.getDiZhiIndex(branch);
    assert(branchIndex != -1, '无效地支: $branch');
    final offset = (branchIndex - startIndex) % 12;
    return ChangShengStage.values[offset < 0 ? offset + 12 : offset];
  }

  static String getChangShengBranch(WuXing wuXing) =>
      changShengBranch[wuXing]!;

  /// [wuXing] 的墓库地支
  static String getMuBranch(WuXing wuXing) =>
      _branchOfStage(wuXing, ChangShengStage.mu);

  /// [wuXing] 的绝地地支
  static String getJueBranch(WuXing wuXing) =>
      _branchOfStage(wuXing, ChangShengStage.jue);

  static bool isMu(WuXing wuXing, String branch) =>
      getStage(wuXing, branch) == ChangShengStage.mu;

  static bool isJue(WuXing wuXing, String branch) =>
      getStage(wuXing, branch) == ChangShengStage.jue;

  static String _branchOfStage(WuXing wuXing, ChangShengStage stage) {
    final startIndex =
        TianGanDiZhiService.getDiZhiIndex(changShengBranch[wuXing]!);
    return TianGanDiZhiService.getDiZhiByIndex(startIndex + stage.index);
  }
}
