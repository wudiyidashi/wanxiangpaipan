import 'dart:math';

import 'package:lunar/lunar.dart';
import '../../domain/divination_system.dart';
import '../../domain/services/shared/lunar_service.dart';
import '../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../domain/services/daliuren/tianpan_service.dart';
import '../../domain/services/daliuren/si_ke_service.dart';
import '../../domain/services/daliuren/san_chuan_service.dart';
import '../../domain/services/daliuren/shen_jiang_service.dart';
import '../../domain/services/daliuren/shen_sha_service.dart';
import '../../domain/services/daliuren/yue_jiang_service.dart';
import 'models/daliuren_result.dart';
import 'models/pan_params.dart';

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
        CastMethod.reportNumber, // 报数起课
        CastMethod.manual, // 手动输入
        CastMethod.computer, // 随机起课
      ];

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

    // 根据起课方式执行不同逻辑
    switch (method) {
      case CastMethod.time:
        return _castByTime(time, input);
      case CastMethod.reportNumber:
        return _castByReportNumber(time, input);
      case CastMethod.computer:
        return _castByComputer(time, input);
      case CastMethod.manual:
        return _castByManual(time, input);
      default:
        throw UnsupportedError('大六壬不支持的起卦方式: ${method.displayName}');
    }
  }

  /// 地支列表，用于报数和随机起课映射
  static const _diZhiList = [
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

  /// 时间起课
  ///
  /// [shiZhiOverride] 可选的时支覆盖值，用于报数起课和随机起课
  /// [castMethodOverride] 可选的起课方式覆盖，用于标记实际使用的方式
  Future<DaLiuRenResult> _castByTime(
    DateTime castTime,
    Map<String, dynamic> input, {
    String? shiZhiOverride,
    String? hourGanZhiOverride,
    CastMethod? castMethodOverride,
  }) async {
    final panParams = _parsePanParams(input);

    // 1. 获取农历信息
    var lunarInfo = LunarService.getLunarInfo(castTime);

    // 2. 获取时支（如果有覆盖值则使用覆盖值）
    final String shiZhi;
    final String hourGanZhi;
    if (shiZhiOverride != null) {
      shiZhi = shiZhiOverride;
      hourGanZhi = hourGanZhiOverride ??
          _buildHourGanZhi(
            dayGan: lunarInfo.riGan,
            shiZhi: shiZhiOverride,
          );
    } else {
      final solar = Solar.fromDate(castTime);
      final lunar = solar.getLunar();
      shiZhi = lunar.getTimeZhi();
      hourGanZhi = lunar.getTimeInGanZhi();
    }
    lunarInfo = lunarInfo.copyWith(
      hourGanZhi: hourGanZhi,
      kongWang: _resolveKongWang(
        dayGanZhi: lunarInfo.riGanZhi,
        hourGanZhi: hourGanZhi,
        xunShouMode: panParams.xunShouMode,
      ),
    );

    final resolvedYueJiang = _resolveYueJiang(
      params: panParams,
      yueJian: lunarInfo.yueJian,
      castTime: castTime,
    );

    // 3. 计算天盘
    final tianPan = TianPanService.createTianPan(
      yueJian: lunarInfo.yueJian,
      shiZhi: shiZhi,
      resolvedYueJiang: resolvedYueJiang,
      castTime: panParams.monthGeneralMode == DaLiuRenMonthGeneralMode.auto
          ? castTime
          : null,
      solarTerm: lunarInfo.solarTerm,
    );

    // 4. 配置神将（需要在四课之前，因为四课需要神将信息）
    final shenJiangConfig = ShenJiangService.configureShenJiang(
      riGan: lunarInfo.riGan,
      shiZhi: shiZhi,
      tianPanMap: tianPan.tianPanMap,
      dayNightMode: panParams.dayNightMode,
      guiRenVerse: panParams.guiRenVerse,
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
      castMethod: castMethodOverride ?? CastMethod.time,
      lunarInfo: lunarInfo,
      tianPan: tianPan,
      siKe: siKe,
      sanChuan: sanChuan,
      shenJiangConfig: shenJiangConfig,
      shenShaList: shenShaList,
      panParams: panParams,
    );
  }

  /// 报数起课
  ///
  /// 用户提供一个数字，映射到地支作为时支，然后按时间起课流程计算
  Future<DaLiuRenResult> _castByReportNumber(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    final number = input['number'] as int;
    final index = (number.abs() - 1) % 12;
    final shiZhi = _diZhiList[index];
    final dayGan = LunarService.getLunarInfo(castTime).riGan;

    return _castByTime(
      castTime,
      input,
      shiZhiOverride: shiZhi,
      hourGanZhiOverride: _buildHourGanZhi(dayGan: dayGan, shiZhi: shiZhi),
      castMethodOverride: CastMethod.reportNumber,
    );
  }

  /// 随机起课
  ///
  /// 系统随机选择一个地支作为时支，然后按时间起课流程计算
  Future<DaLiuRenResult> _castByComputer(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    final random = Random();
    final index = random.nextInt(12);
    final shiZhi = _diZhiList[index];
    final dayGan = LunarService.getLunarInfo(castTime).riGan;

    return _castByTime(
      castTime,
      input,
      shiZhiOverride: shiZhi,
      hourGanZhiOverride: _buildHourGanZhi(dayGan: dayGan, shiZhi: shiZhi),
      castMethodOverride: CastMethod.computer,
    );
  }

  /// 手动起课
  Future<DaLiuRenResult> _castByManual(
    DateTime castTime,
    Map<String, dynamic> input,
  ) async {
    final panParams = _parsePanParams(input);
    final pillars = _parseManualPillars(input);
    final shiZhi = pillars.hourZhi;

    final lunarInfo = LunarService.getLunarInfo(castTime).copyWith(
      riGan: pillars.dayGan,
      riZhi: pillars.dayZhi,
      riGanZhi: pillars.dayGanZhi,
      hourGanZhi: pillars.hourGanZhi,
      yearGanZhi: pillars.yearGanZhi,
      monthGanZhi: pillars.monthGanZhi,
      yueJian: pillars.monthZhi,
      kongWang: _resolveKongWang(
        dayGanZhi: pillars.dayGanZhi,
        hourGanZhi: pillars.hourGanZhi,
        xunShouMode: panParams.xunShouMode,
      ),
    );

    final resolvedYueJiang = _resolveYueJiang(
      params: panParams,
      yueJian: pillars.monthZhi,
      castTime: castTime,
    );

    // 计算天盘
    final tianPan = TianPanService.createTianPan(
      yueJian: pillars.monthZhi,
      shiZhi: shiZhi,
      resolvedYueJiang: resolvedYueJiang,
    );

    // 配置神将
    final shenJiangConfig = ShenJiangService.configureShenJiang(
      riGan: pillars.dayGan,
      shiZhi: shiZhi,
      tianPanMap: tianPan.tianPanMap,
      dayNightMode: panParams.dayNightMode,
      guiRenVerse: panParams.guiRenVerse,
    );

    // 排列四课
    final siKe = SiKeService.arrangeSiKe(
      riGan: pillars.dayGan,
      riZhi: pillars.dayZhi,
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
      riGan: pillars.dayGan,
      riZhi: pillars.dayZhi,
      yueJian: pillars.monthZhi,
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
      panParams: panParams,
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return DaLiuRenResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    final paramsValid = _tryParsePanParams(input) != null;
    if (!paramsValid) {
      return false;
    }

    switch (method) {
      case CastMethod.time:
        // 时间起课不需要额外输入
        return true;
      case CastMethod.reportNumber:
        return input.containsKey('number') && input['number'] is int;
      case CastMethod.computer:
        return true;
      case CastMethod.manual:
        return _tryParseManualPillars(input) != null;
      default:
        return false;
    }
  }

  /// 生成唯一 ID
  String _generateId() {
    return 'dlr_${DateTime.now().millisecondsSinceEpoch}';
  }

  DaLiuRenPanParams _parsePanParams(Map<String, dynamic> input) {
    final parsed = _tryParsePanParams(input);
    if (parsed == null) {
      throw ArgumentError('大六壬参数不合法');
    }
    return parsed;
  }

  DaLiuRenPanParams? _tryParsePanParams(Map<String, dynamic> input) {
    final raw = input['params'];
    if (raw == null) {
      return const DaLiuRenPanParams();
    }
    if (raw is! Map) {
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(raw);
      final monthGeneralMode = map['monthGeneralMode'] is String
          ? DaLiuRenMonthGeneralMode.fromId(
              map['monthGeneralMode'] as String,
            )
          : DaLiuRenMonthGeneralMode.auto;
      final manualMonthGeneral = map['manualMonthGeneral'] as String?;
      if (monthGeneralMode == DaLiuRenMonthGeneralMode.manual &&
          !TianGanDiZhiService.isValidDiZhi(manualMonthGeneral ?? '')) {
        return null;
      }

      final dayNightMode = map['dayNightMode'] is String
          ? DaLiuRenDayNightMode.fromId(map['dayNightMode'] as String)
          : DaLiuRenDayNightMode.auto;
      final guiRenVerse = map['guiRenVerse'] is String
          ? DaLiuRenGuiRenVerse.fromId(map['guiRenVerse'] as String)
          : DaLiuRenGuiRenVerse.classic;
      final xunShouMode = map['xunShouMode'] is String
          ? DaLiuRenXunShouMode.fromId(map['xunShouMode'] as String)
          : DaLiuRenXunShouMode.day;
      final showSanChuanOnTop = map['showSanChuanOnTop'];
      final birthYear = map['birthYear'];

      return DaLiuRenPanParams(
        birthYear: birthYear is int ? birthYear : null,
        monthGeneralMode: monthGeneralMode,
        manualMonthGeneral: manualMonthGeneral,
        dayNightMode: dayNightMode,
        guiRenVerse: guiRenVerse,
        xunShouMode: xunShouMode,
        showSanChuanOnTop: showSanChuanOnTop is bool ? showSanChuanOnTop : true,
      );
    } catch (_) {
      return null;
    }
  }

  _ManualPillars _parseManualPillars(Map<String, dynamic> input) {
    final parsed = _tryParseManualPillars(input);
    if (parsed == null) {
      throw ArgumentError('指定干支需要完整输入年柱、月柱、日柱、时柱');
    }
    return parsed;
  }

  _ManualPillars? _tryParseManualPillars(Map<String, dynamic> input) {
    final yearGanZhi = input['yearGanZhi'] as String?;
    final monthGanZhi = input['monthGanZhi'] as String?;
    final dayGanZhi = input['dayGanZhi'] as String?;
    final hourGanZhi = input['hourGanZhi'] as String?;
    if (yearGanZhi == null ||
        monthGanZhi == null ||
        dayGanZhi == null ||
        hourGanZhi == null) {
      return null;
    }

    if (!TianGanDiZhiService.isValidGanZhi(yearGanZhi) ||
        !TianGanDiZhiService.isValidGanZhi(monthGanZhi) ||
        !TianGanDiZhiService.isValidGanZhi(dayGanZhi) ||
        !TianGanDiZhiService.isValidGanZhi(hourGanZhi)) {
      return null;
    }

    final yearParts = TianGanDiZhiService.splitGanZhi(yearGanZhi);
    final monthParts = TianGanDiZhiService.splitGanZhi(monthGanZhi);
    final dayParts = TianGanDiZhiService.splitGanZhi(dayGanZhi);
    final hourParts = TianGanDiZhiService.splitGanZhi(hourGanZhi);
    if (yearParts == null ||
        monthParts == null ||
        dayParts == null ||
        hourParts == null) {
      return null;
    }

    return _ManualPillars(
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      dayGanZhi: dayGanZhi,
      hourGanZhi: hourGanZhi,
      monthZhi: monthParts[1],
      dayGan: dayParts[0],
      dayZhi: dayParts[1],
      hourZhi: hourParts[1],
    );
  }

  String _resolveYueJiang({
    required DaLiuRenPanParams params,
    required String yueJian,
    required DateTime castTime,
  }) {
    if (params.monthGeneralMode == DaLiuRenMonthGeneralMode.manual) {
      return params.manualMonthGeneral!;
    }

    return YueJiangService.getYueJiangByDateTime(
      castTime,
      fallbackYueJian: yueJian,
    );
  }

  List<String> _resolveKongWang({
    required String dayGanZhi,
    required String hourGanZhi,
    required DaLiuRenXunShouMode xunShouMode,
  }) {
    final target =
        xunShouMode == DaLiuRenXunShouMode.hour ? hourGanZhi : dayGanZhi;
    return TianGanDiZhiService.getKongWang(target);
  }

  String _buildHourGanZhi({
    required String dayGan,
    required String shiZhi,
  }) {
    final dayGanIndex = TianGanDiZhiService.getTianGanIndex(dayGan);
    final shiZhiIndex = TianGanDiZhiService.getDiZhiIndex(shiZhi);
    if (dayGanIndex == -1 || shiZhiIndex == -1) {
      throw ArgumentError('无法根据日干$dayGan和时支$shiZhi计算时柱');
    }

    final hourGanIndex = ((dayGanIndex % 5) * 2 + shiZhiIndex) % 10;
    final hourGan = TianGanDiZhiService.getTianGanByIndex(hourGanIndex);
    return '$hourGan$shiZhi';
  }
}

class _ManualPillars {
  const _ManualPillars({
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.monthZhi,
    required this.dayGan,
    required this.dayZhi,
    required this.hourZhi,
  });

  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String hourGanZhi;
  final String monthZhi;
  final String dayGan;
  final String dayZhi;
  final String hourZhi;
}
