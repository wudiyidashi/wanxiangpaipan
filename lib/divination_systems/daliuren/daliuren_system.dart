import 'package:lunar/lunar.dart';
import '../../domain/divination_system.dart';
import '../../domain/services/shared/lunar_service.dart';
import '../../domain/services/daliuren/tianpan_service.dart';
import '../../domain/services/daliuren/si_ke_service.dart';
import '../../domain/services/daliuren/san_chuan_service.dart';
import '../../domain/services/daliuren/shen_jiang_service.dart';
import '../../domain/services/daliuren/shen_sha_service.dart';
import 'models/daliuren_result.dart';

/// 大六壬排盘系统
///
/// 大六壬是中国古代三式之一（太乙、奇门、六壬），以天干地支、
/// 十二神将为基础，通过四课三传进行占断。
///
/// 核心算法流程：
/// 1. 获取农历信息（日干支、月建、时支）
/// 2. 计算月将，排列天盘
/// 3. 排列四课
/// 4. 推导三传（根据课体类型）
/// 5. 配置十二神将
/// 6. 计算神煞
class DaLiuRenSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.daLiuRen;

  @override
  String get name => '大六壬';

  @override
  String get description => '大六壬：中国古代三式之一，以天干地支、十二神将为基础，通过四课三传进行占断';

  @override
  bool get isEnabled => true; // 已启用

  @override
  List<CastMethod> get supportedMethods => [
        CastMethod.time, // 时间起课
        CastMethod.manual, // 手动输入
      ];

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    final time = castTime ?? DateTime.now();

    // 根据起课方式执行不同逻辑
    switch (method) {
      case CastMethod.time:
        return _castByTime(time, input);
      case CastMethod.manual:
        return _castByManual(time, input);
      default:
        throw UnsupportedError('大六壬不支持的起卦方式: ${method.displayName}');
    }
  }

  /// 时间起课
  Future<DaLiuRenResult> _castByTime(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    // 1. 获取农历信息
    final lunarInfo = LunarService.getLunarInfo(castTime);

    // 2. 获取时支
    final solar = Solar.fromDate(castTime);
    final lunar = solar.getLunar();
    final shiZhi = lunar.getTimeZhi();

    // 3. 计算天盘
    final tianPan = TianPanService.createTianPan(
      yueJian: lunarInfo.yueJian,
      shiZhi: shiZhi,
      solarTerm: lunarInfo.solarTerm,
    );

    // 4. 配置神将（需要在四课之前，因为四课需要神将信息）
    final shenJiangConfig = ShenJiangService.configureShenJiang(
      riGan: lunarInfo.riGan,
      shiZhi: shiZhi,
      tianPanMap: tianPan.tianPanMap,
    );

    // 5. 排列四课
    final siKe = SiKeService.arrangeSiKe(
      riGan: lunarInfo.riGan,
      riZhi: lunarInfo.riZhi,
      tianPanMap: tianPan.tianPanMap,
      shenJiangConfig: shenJiangConfig,
    );

    // 6. 推导三传
    final sanChuan = SanChuanService.deriveSanChuan(
      siKe: siKe,
      tianPanMap: tianPan.tianPanMap,
      shenJiangConfig: shenJiangConfig,
      kongWang: lunarInfo.kongWang,
    );

    // 7. 计算神煞
    final shenShaList = ShenShaService.calculateShenSha(
      riGan: lunarInfo.riGan,
      riZhi: lunarInfo.riZhi,
      yueJian: lunarInfo.yueJian,
      shiZhi: shiZhi,
    );

    // 8. 创建结果
    return DaLiuRenResult(
      id: _generateId(),
      castTime: castTime,
      castMethod: CastMethod.time,
      lunarInfo: lunarInfo,
      tianPan: tianPan,
      siKe: siKe,
      sanChuan: sanChuan,
      shenJiangConfig: shenJiangConfig,
      shenShaList: shenShaList,
    );
  }

  /// 手动起课
  Future<DaLiuRenResult> _castByManual(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    // 从输入中获取手动指定的参数
    final riGan = input['riGan'] as String? ?? '甲';
    final riZhi = input['riZhi'] as String? ?? '子';
    final shiZhi = input['shiZhi'] as String? ?? '子';
    final yueJian = input['yueJian'] as String? ?? '寅';

    // 获取农历信息（如果有提供特定日期，使用该日期；否则使用当前时间）
    final lunarInfo = LunarService.getLunarInfo(castTime).copyWith(
      riGan: riGan,
      riZhi: riZhi,
      riGanZhi: '$riGan$riZhi',
      yueJian: yueJian,
    );

    // 计算天盘
    final tianPan = TianPanService.createTianPan(
      yueJian: yueJian,
      shiZhi: shiZhi,
    );

    // 配置神将
    final shenJiangConfig = ShenJiangService.configureShenJiang(
      riGan: riGan,
      shiZhi: shiZhi,
      tianPanMap: tianPan.tianPanMap,
    );

    // 排列四课
    final siKe = SiKeService.arrangeSiKe(
      riGan: riGan,
      riZhi: riZhi,
      tianPanMap: tianPan.tianPanMap,
      shenJiangConfig: shenJiangConfig,
    );

    // 推导三传
    final sanChuan = SanChuanService.deriveSanChuan(
      siKe: siKe,
      tianPanMap: tianPan.tianPanMap,
      shenJiangConfig: shenJiangConfig,
      kongWang: lunarInfo.kongWang,
    );

    // 计算神煞
    final shenShaList = ShenShaService.calculateShenSha(
      riGan: riGan,
      riZhi: riZhi,
      yueJian: yueJian,
      shiZhi: shiZhi,
    );

    // 创建结果
    return DaLiuRenResult(
      id: _generateId(),
      castTime: castTime,
      castMethod: CastMethod.manual,
      lunarInfo: lunarInfo,
      tianPan: tianPan,
      siKe: siKe,
      sanChuan: sanChuan,
      shenJiangConfig: shenJiangConfig,
      shenShaList: shenShaList,
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return DaLiuRenResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    switch (method) {
      case CastMethod.time:
        // 时间起课不需要额外输入
        return true;
      case CastMethod.manual:
        // 手动输入需要验证日干、日支、时支、月建
        final riGan = input['riGan'] as String?;
        final riZhi = input['riZhi'] as String?;
        final shiZhi = input['shiZhi'] as String?;
        final yueJian = input['yueJian'] as String?;

        // 至少需要日干和日支
        if (riGan == null || riZhi == null) {
          return false;
        }

        // 验证天干地支的有效性
        const validGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
        const validZhi = [
          '子',
          '丑',
          '寅',
          '卯',
          '辰',
          '巳',
          '午',
          '未',
          '申',
          '酉',
          '戌',
          '亥'
        ];

        if (!validGan.contains(riGan)) return false;
        if (!validZhi.contains(riZhi)) return false;
        if (shiZhi != null && !validZhi.contains(shiZhi)) return false;
        if (yueJian != null && !validZhi.contains(yueJian)) return false;

        return true;
      default:
        return false;
    }
  }

  /// 生成唯一 ID
  String _generateId() {
    return 'dlr_${DateTime.now().millisecondsSinceEpoch}';
  }
}
