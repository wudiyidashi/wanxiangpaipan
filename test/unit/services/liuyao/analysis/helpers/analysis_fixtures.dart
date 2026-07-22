import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

/// 按爻数（初爻到上爻）排出本卦
Gua buildGua(List<int> numbers) => GuaCalculator.calculateGua(numbers);

/// 由本卦生成变卦（无动爻返回 null）
Gua? buildChangingGua(Gua mainGua) => GuaCalculator.generateChangingGua(mainGua);

/// 构造单个爻（用于化爻变换等无需完整卦的测试）
Yao makeYao({
  int position = 1,
  required String branch,
  bool moving = false,
  bool yin = false,
  LiuQin liuQin = LiuQin.xiongDi,
}) {
  return Yao(
    position: position,
    number: moving
        ? (yin ? YaoNumber.laoYin : YaoNumber.laoYang)
        : (yin ? YaoNumber.shaoYin : YaoNumber.shaoYang),
    branch: branch,
    stem: '甲',
    liuQin: liuQin,
    wuXing: WuXingService.getWuXingFromBranch(branch)!,
    isSeYao: false,
    isYingYao: false,
  );
}

/// 构造农历测试夹具；空亡由日干支自动推算
LunarInfo buildLunar({
  String yueJian = '午',
  String riGanZhi = '甲子',
  String yearGanZhi = '丙午',
  String monthGanZhi = '庚午',
}) {
  final split = TianGanDiZhiService.splitGanZhi(riGanZhi)!;
  return LunarInfo(
    yueJian: yueJian,
    riGan: split[0],
    riZhi: split[1],
    riGanZhi: riGanZhi,
    kongWang: TianGanDiZhiService.getKongWang(riGanZhi),
    yearGanZhi: yearGanZhi,
    monthGanZhi: monthGanZhi,
  );
}
