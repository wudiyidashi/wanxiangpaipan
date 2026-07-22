import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_tag.dart';
import 'tables/dizhi_relations.dart';

/// 旺相休囚死等级
enum WangShuaiLevel {
  wang('旺', Polarity.ji),
  xiang('相', Polarity.ji),
  xiu('休', Polarity.neutral),
  qiu('囚', Polarity.xiong),
  si('死', Polarity.xiong);

  const WangShuaiLevel(this.name, this.polarity);
  final String name;
  final Polarity polarity;
}

/// 日月旺衰分析。
///
/// 覆盖：临月建、月破、月生、月克、旺相休囚死、临日建、日生、日克、日扶。
/// 日冲的定性（暗动/日破）依赖动静与旺衰，由 DongBianService 判定。
/// 规则依据《增删卜易》。
class WangShuaiService {
  WangShuaiService._();

  /// 爻五行相对月令的旺衰等级：
  /// 当令旺、月生者相、生月者休、克月者囚、月克者死
  static WangShuaiLevel getLevel(WuXing yaoWuXing, String yueJian) {
    final yueWuXing = WuXingService.getWuXingFromBranch(yueJian)!;
    switch (WuXingService.getRelation(yaoWuXing, yueWuXing)) {
      case WuXingRelation.biHe:
        return WangShuaiLevel.wang;
      case WuXingRelation.shengWo:
        return WangShuaiLevel.xiang;
      case WuXingRelation.woSheng:
        return WangShuaiLevel.xiu;
      case WuXingRelation.woKe:
        return WangShuaiLevel.qiu;
      case WuXingRelation.keWo:
        return WangShuaiLevel.si;
    }
  }

  /// 爻是否旺相（用于暗动、真空等下游判定）
  static bool isWangXiang(Yao yao, LunarInfo lunarInfo) {
    final level = getLevel(yao.wuXing, lunarInfo.yueJian);
    if (level == WangShuaiLevel.wang || level == WangShuaiLevel.xiang) {
      return true;
    }
    // 临日建或日辰生扶亦作旺论
    if (yao.branch == lunarInfo.riZhi) return true;
    final riWuXing = WuXingService.getWuXingFromBranch(lunarInfo.riZhi)!;
    return WuXingService.isSheng(riWuXing, yao.wuXing) ||
        riWuXing == yao.wuXing;
  }

  static List<YaoAnalysisTag> analyzeYao(Yao yao, LunarInfo lunarInfo) {
    final tags = <YaoAnalysisTag>[];
    final yueJian = lunarInfo.yueJian;
    final riZhi = lunarInfo.riZhi;
    final yueWuXing = WuXingService.getWuXingFromBranch(yueJian)!;
    final riWuXing = WuXingService.getWuXingFromBranch(riZhi)!;

    // 月建
    if (yao.branch == yueJian) {
      tags.add(YaoAnalysisTag(
        term: '临月建',
        category: TagCategory.wangShuai,
        polarity: Polarity.ji,
        priority: 12,
        reason: '爻支${yao.branch}即月建',
      ));
    }
    if (DiZhiRelations.isLiuChong(yueJian, yao.branch)) {
      tags.add(YaoAnalysisTag(
        term: '月破',
        category: TagCategory.wangShuai,
        polarity: Polarity.xiong,
        priority: 2,
        reason: '月建$yueJian冲爻支${yao.branch}',
      ));
    }
    if (yao.branch != yueJian) {
      if (WuXingService.isSheng(yueWuXing, yao.wuXing)) {
        tags.add(YaoAnalysisTag(
          term: '月生',
          category: TagCategory.wangShuai,
          polarity: Polarity.ji,
          priority: 30,
          reason: '月令${yueWuXing.name}生${yao.wuXing.name}',
        ));
      } else if (WuXingService.isKe(yueWuXing, yao.wuXing)) {
        tags.add(YaoAnalysisTag(
          term: '月克',
          category: TagCategory.wangShuai,
          polarity: Polarity.xiong,
          priority: 31,
          reason: '月令${yueWuXing.name}克${yao.wuXing.name}',
        ));
      }
    }

    // 旺相休囚死
    final level = getLevel(yao.wuXing, yueJian);
    tags.add(YaoAnalysisTag(
      term: level.name,
      category: TagCategory.wangShuai,
      polarity: level.polarity,
      priority: 35,
      reason: '${yao.wuXing.name}于$yueJian月为${level.name}',
    ));

    // 日辰
    if (yao.branch == riZhi) {
      tags.add(YaoAnalysisTag(
        term: '临日建',
        category: TagCategory.wangShuai,
        polarity: Polarity.ji,
        priority: 13,
        reason: '爻支${yao.branch}即日辰',
      ));
    } else if (riWuXing == yao.wuXing) {
      tags.add(YaoAnalysisTag(
        term: '日扶',
        category: TagCategory.wangShuai,
        polarity: Polarity.ji,
        priority: 36,
        reason: '日辰$riZhi与爻同属${yao.wuXing.name}',
      ));
    } else if (WuXingService.isSheng(riWuXing, yao.wuXing)) {
      tags.add(YaoAnalysisTag(
        term: '日生',
        category: TagCategory.wangShuai,
        polarity: Polarity.ji,
        priority: 32,
        reason: '日辰${riWuXing.name}生${yao.wuXing.name}',
      ));
    } else if (WuXingService.isKe(riWuXing, yao.wuXing)) {
      tags.add(YaoAnalysisTag(
        term: '日克',
        category: TagCategory.wangShuai,
        polarity: Polarity.xiong,
        priority: 33,
        reason: '日辰${riWuXing.name}克${yao.wuXing.name}',
      ));
    }

    return tags;
  }
}
