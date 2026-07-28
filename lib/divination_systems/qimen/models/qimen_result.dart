import '../../../domain/divination_system.dart';
import '../../../models/lunar_info.dart';
import 'qimen_ju_info.dart';
import 'qimen_palace.dart';
import 'qimen_pan_params.dart';
import 'qimen_temporal_context.dart';

class QimenResult implements DivinationResult {
  const QimenResult({
    required this.id,
    required this.castTime,
    required this.castMethod,
    required this.lunarInfo,
    required this.panParams,
    required this.temporalContext,
    required this.juInfo,
    required this.palaces,
    required this.xunShou,
    required this.xunHiddenStem,
    required this.zhiFuStar,
    required this.zhiFuPalace,
    required this.zhiShiDoor,
    required this.zhiShiPalace,
    required this.kongWangBranches,
    required this.horseBranch,
    required this.horsePalace,
    required this.derivationSteps,
    this.questionId = '',
    this.detailId = '',
    this.interpretationId = '',
  });

  static const int currentSchemaVersion = 1;
  static const List<int> luoShuPalaceOrder = <int>[
    4,
    9,
    2,
    3,
    5,
    7,
    8,
    1,
    6,
  ];

  @override
  final String id;
  @override
  final DateTime castTime;
  @override
  final CastMethod castMethod;
  @override
  final LunarInfo lunarInfo;
  final QimenPanParams panParams;
  final QimenTemporalContext temporalContext;
  final QimenJuInfo juInfo;
  final List<QimenPalace> palaces;
  final String xunShou;
  final String xunHiddenStem;
  final String zhiFuStar;
  final int zhiFuPalace;
  final String zhiShiDoor;
  final int zhiShiPalace;
  final List<String> kongWangBranches;
  final String horseBranch;
  final int horsePalace;
  final List<String> derivationSteps;
  final String questionId;
  final String detailId;
  final String interpretationId;

  @override
  DivinationType get systemType => DivinationType.qiMen;

  @override
  String getSummary() => '${juInfo.dun.label}遁${juInfo.juNumber}局 · '
      '$zhiFuStar值符 / $zhiShiDoor值使';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': currentSchemaVersion,
        'systemType': systemType.id,
        'id': id,
        'castTime': castTime.toUtc().toIso8601String(),
        'castMethod': castMethod.id,
        'lunarInfo': lunarInfo.toJson(),
        'panParams': panParams.toJson(),
        'temporalContext': temporalContext.toJson(),
        'juInfo': juInfo.toJson(),
        'palaces': palaces.map((palace) => palace.toJson()).toList(),
        'xunShou': xunShou,
        'xunHiddenStem': xunHiddenStem,
        'zhiFuStar': zhiFuStar,
        'zhiFuPalace': zhiFuPalace,
        'zhiShiDoor': zhiShiDoor,
        'zhiShiPalace': zhiShiPalace,
        'kongWangBranches': kongWangBranches,
        'horseBranch': horseBranch,
        'horsePalace': horsePalace,
        'derivationSteps': derivationSteps,
        'questionId': questionId,
        'detailId': detailId,
        'interpretationId': interpretationId,
      };

  factory QimenResult.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw const FormatException('不支持的奇门结果 schemaVersion');
    }
    if (json['systemType'] != DivinationType.qiMen.id) {
      throw const FormatException('奇门结果 systemType 不匹配');
    }

    try {
      final palaces = (json['palaces'] as List)
          .map((value) => QimenPalace.fromJson(
                Map<String, dynamic>.from(value as Map),
              ))
          .toList(growable: false);
      final palaceNumbers = palaces.map((palace) => palace.number).toSet();
      if (palaces.length != 9 ||
          palaceNumbers.length != 9 ||
          !palaceNumbers.containsAll(const <int>{1, 2, 3, 4, 5, 6, 7, 8, 9})) {
        throw const FormatException('奇门结果九宫不完整');
      }

      final castMethod = CastMethod.fromId(json['castMethod'] as String);
      if (castMethod != CastMethod.time && castMethod != CastMethod.manual) {
        throw const FormatException('奇门结果 castMethod 不受支持');
      }
      final juInfo = QimenJuInfo.fromJson(
        Map<String, dynamic>.from(json['juInfo'] as Map),
      );
      final zhiFuPalace = json['zhiFuPalace'] as int;
      final zhiShiPalace = json['zhiShiPalace'] as int;
      final horsePalace = json['horsePalace'] as int;
      if (juInfo.juNumber < 1 ||
          juInfo.juNumber > 9 ||
          <int>{zhiFuPalace, zhiShiPalace, horsePalace}
              .any((palace) => palace < 1 || palace > 9)) {
        throw const FormatException('奇门结果局数或落宫超出范围');
      }

      return QimenResult(
        id: json['id'] as String,
        castTime: DateTime.parse(json['castTime'] as String).toUtc(),
        castMethod: castMethod,
        lunarInfo: LunarInfo.fromJson(
          Map<String, dynamic>.from(json['lunarInfo'] as Map),
        ),
        panParams: QimenPanParams.fromJson(
          Map<String, dynamic>.from(json['panParams'] as Map),
        ),
        temporalContext: QimenTemporalContext.fromJson(
          Map<String, dynamic>.from(json['temporalContext'] as Map),
        ),
        juInfo: juInfo,
        palaces: palaces,
        xunShou: json['xunShou'] as String,
        xunHiddenStem: json['xunHiddenStem'] as String,
        zhiFuStar: json['zhiFuStar'] as String,
        zhiFuPalace: zhiFuPalace,
        zhiShiDoor: json['zhiShiDoor'] as String,
        zhiShiPalace: zhiShiPalace,
        kongWangBranches: List<String>.from(json['kongWangBranches'] as List),
        horseBranch: json['horseBranch'] as String,
        horsePalace: horsePalace,
        derivationSteps: List<String>.from(json['derivationSteps'] as List),
        questionId: json['questionId'] as String? ?? '',
        detailId: json['detailId'] as String? ?? '',
        interpretationId: json['interpretationId'] as String? ?? '',
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('奇门结果 JSON 不合法', error);
    }
  }
}
