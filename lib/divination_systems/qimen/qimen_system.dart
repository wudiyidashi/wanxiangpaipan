import 'package:uuid/uuid.dart';

import '../../domain/divination_system.dart';
import '../../domain/services/qimen/qimen_constants.dart';
import '../../domain/services/qimen/qimen_ju_service.dart';
import '../../domain/services/qimen/qimen_pan_service.dart';
import '../../domain/services/qimen/qimen_time_service.dart';
import '../../domain/services/shared/tiangan_dizhi_service.dart';
import 'models/qimen_enums.dart';
import 'models/qimen_ju_info.dart';
import 'models/qimen_pan_params.dart';
import 'models/qimen_result.dart';
import 'models/qimen_temporal_context.dart';

class QimenSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.qiMen;

  @override
  String get name => '奇门遁甲';

  @override
  String get description => '时家转盘奇门遁甲排盘与历法引擎';

  /// The domain engine is complete, but product registration belongs to the
  /// dedicated integration task.
  @override
  bool get isEnabled => false;

  @override
  List<CastMethod> get supportedMethods => const <CastMethod>[
        CastMethod.time,
        CastMethod.manual,
      ];

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    if (!validateInput(method, input)) {
      throw ArgumentError('奇门起局输入参数无效');
    }
    final originalTime = castTime ?? DateTime.now();
    var params = _parseParams(input);
    var temporalContext = QimenTimeService.resolve(originalTime, params);
    final QimenJuInfo juInfo;

    if (method == CastMethod.manual) {
      params = params.copyWith(juMethod: QimenJuMethod.manual);
      temporalContext = _applyManualPillars(temporalContext, input);
      juInfo = QimenJuService.manual(
        dun: QimenDun.fromId(input['dun'] as String),
        juNumber: input['juNumber'] as int,
        yuan: QimenYuan.fromId(input['yuan'] as String),
        solarTerm: input['solarTerm'] as String,
      );
    } else {
      juInfo = QimenJuService.resolve(params.juMethod, temporalContext);
    }

    final pan = QimenPanService.arrange(
      temporalContext: temporalContext,
      juInfo: juInfo,
      params: params,
    );
    final lunarInfo = temporalContext.toLunarInfo().copyWith(
          kongWang: TianGanDiZhiService.getKongWang(
            temporalContext.dayGanZhi,
          ),
        );
    return QimenResult(
      id: const Uuid().v4(),
      castTime: originalTime,
      castMethod: method,
      lunarInfo: lunarInfo,
      panParams: params,
      temporalContext: temporalContext,
      juInfo: juInfo,
      palaces: pan.palaces,
      xunShou: pan.duty.xunShou,
      xunHiddenStem: pan.duty.xunHiddenStem,
      zhiFuStar: pan.duty.zhiFuStar,
      zhiFuPalace: pan.duty.zhiFuPalace,
      zhiShiDoor: pan.duty.zhiShiDoor,
      zhiShiPalace: pan.duty.zhiShiPalace,
      kongWangBranches: pan.markers.kongWangBranches,
      horseBranch: pan.markers.horseBranch,
      horsePalace: pan.markers.horsePalace,
      derivationSteps: <String>[
        '生效排盘时间${temporalContext.effectivePanTime.toIso8601String()}'
            '（${params.timeBasis.id}）',
        '实际节气${temporalContext.currentSolarTerm}，交节时刻'
            '${temporalContext.currentSolarTermTime.toIso8601String()}',
        '定局法${juInfo.method.id}：有效节气${juInfo.effectiveSolarTerm}，'
            '${juInfo.dun.label}遁${juInfo.juNumber}局、${juInfo.yuan.label}，'
            '符头${juInfo.symbolHead ?? '无'}，置闰${juInfo.isLeap ? '是' : '否'}',
        ...juInfo.derivation,
        ...pan.derivationSteps,
      ],
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) =>
      QimenResult.fromJson(json);

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    if (!supportedMethods.contains(method)) return false;
    try {
      final params = _parseParams(input);
      if (method == CastMethod.time) {
        if (!_hasOnlyKeys(input, const <String>{'params'})) return false;
        return params.juMethod != QimenJuMethod.manual;
      }
      const required = <String>{
        'yearGanZhi',
        'monthGanZhi',
        'dayGanZhi',
        'hourGanZhi',
        'solarTerm',
        'dun',
        'juNumber',
        'yuan',
      };
      if (!_hasOnlyKeys(input, <String>{...required, 'params'}) ||
          !input.keys.toSet().containsAll(required)) {
        return false;
      }
      final rawParams = input['params'];
      if (rawParams is Map && rawParams.containsKey('juMethod')) {
        return false;
      }
      for (final key in const <String>[
        'yearGanZhi',
        'monthGanZhi',
        'dayGanZhi',
        'hourGanZhi',
      ]) {
        final value = input[key];
        if (value is! String || !TianGanDiZhiService.isValidGanZhi(value)) {
          return false;
        }
      }
      final solarTerm = input['solarTerm'];
      if (solarTerm is! String ||
          !QimenConstants.solarTerms.contains(solarTerm)) {
        return false;
      }
      QimenDun.fromId(input['dun'] as String);
      QimenYuan.fromId(input['yuan'] as String);
      final juNumber = input['juNumber'];
      return juNumber is int && juNumber >= 1 && juNumber <= 9;
    } catch (_) {
      return false;
    }
  }

  static bool _hasOnlyKeys(
    Map<String, dynamic> input,
    Set<String> allowed,
  ) =>
      input.keys.every(allowed.contains);

  static QimenPanParams _parseParams(Map<String, dynamic> input) {
    final raw = input['params'];
    if (raw == null) return const QimenPanParams();
    if (raw is! Map) throw ArgumentError('params 必须是对象');
    return QimenPanParams.fromJson(Map<String, dynamic>.from(raw));
  }

  static QimenTemporalContext _applyManualPillars(
    QimenTemporalContext context,
    Map<String, dynamic> input,
  ) =>
      QimenTemporalContext(
        originalTime: context.originalTime,
        basisWallTime: context.basisWallTime,
        effectivePanTime: context.effectivePanTime,
        timeBasis: context.timeBasis,
        sourceUtcOffsetMinutes: context.sourceUtcOffsetMinutes,
        longitude: context.longitude,
        standardMeridian: context.standardMeridian,
        longitudeCorrectionMinutes: context.longitudeCorrectionMinutes,
        equationOfTimeMinutes: context.equationOfTimeMinutes,
        totalCorrectionMinutes: context.totalCorrectionMinutes,
        correctionAlgorithmVersion: context.correctionAlgorithmVersion,
        dayBoundary: context.dayBoundary,
        yearGanZhi: input['yearGanZhi'] as String,
        monthGanZhi: input['monthGanZhi'] as String,
        dayGanZhi: input['dayGanZhi'] as String,
        hourGanZhi: input['hourGanZhi'] as String,
        previousSolarTerm: context.previousSolarTerm,
        previousSolarTermTime: context.previousSolarTermTime,
        currentSolarTerm: context.currentSolarTerm,
        currentSolarTermTime: context.currentSolarTermTime,
        nextSolarTerm: context.nextSolarTerm,
        nextSolarTermTime: context.nextSolarTermTime,
      );
}
