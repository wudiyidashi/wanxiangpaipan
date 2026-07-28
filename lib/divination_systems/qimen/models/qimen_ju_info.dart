import 'qimen_enums.dart';

class QimenJuInfo {
  const QimenJuInfo({
    required this.method,
    required this.dun,
    required this.juNumber,
    required this.yuan,
    required this.solarTerm,
    required this.effectiveSolarTerm,
    this.symbolHead,
    this.chaoShenDays = 0,
    this.isReceivingQi = false,
    this.isLeap = false,
    this.derivation = const <String>[],
  });

  final QimenJuMethod method;
  final QimenDun dun;
  final int juNumber;
  final QimenYuan yuan;
  final String solarTerm;
  final String effectiveSolarTerm;
  final String? symbolHead;
  final int chaoShenDays;
  final bool isReceivingQi;
  final bool isLeap;
  final List<String> derivation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method.id,
        'dun': dun.id,
        'juNumber': juNumber,
        'yuan': yuan.id,
        'solarTerm': solarTerm,
        'effectiveSolarTerm': effectiveSolarTerm,
        'symbolHead': symbolHead,
        'chaoShenDays': chaoShenDays,
        'isReceivingQi': isReceivingQi,
        'isLeap': isLeap,
        'derivation': derivation,
      };

  factory QimenJuInfo.fromJson(Map<String, dynamic> json) => QimenJuInfo(
        method: QimenJuMethod.fromId(json['method'] as String),
        dun: QimenDun.fromId(json['dun'] as String),
        juNumber: json['juNumber'] as int,
        yuan: QimenYuan.fromId(json['yuan'] as String),
        solarTerm: json['solarTerm'] as String,
        effectiveSolarTerm: json['effectiveSolarTerm'] as String,
        symbolHead: json['symbolHead'] as String?,
        chaoShenDays: json['chaoShenDays'] as int,
        isReceivingQi: json['isReceivingQi'] as bool,
        isLeap: json['isLeap'] as bool,
        derivation: List<String>.from(json['derivation'] as List),
      );
}
