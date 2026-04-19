// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daliuren_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DaLiuRenResultImpl _$$DaLiuRenResultImplFromJson(Map<String, dynamic> json) =>
    _$DaLiuRenResultImpl(
      id: json['id'] as String,
      castTime: DateTime.parse(json['castTime'] as String),
      castMethod: $enumDecode(_$CastMethodEnumMap, json['castMethod']),
      lunarInfo: LunarInfo.fromJson(json['lunarInfo'] as Map<String, dynamic>),
      tianPan: TianPan.fromJson(json['tianPan'] as Map<String, dynamic>),
      siKe: SiKe.fromJson(json['siKe'] as Map<String, dynamic>),
      sanChuan: SanChuan.fromJson(json['sanChuan'] as Map<String, dynamic>),
      shenJiangConfig: ShenJiangConfig.fromJson(
          json['shenJiangConfig'] as Map<String, dynamic>),
      shenShaList:
          ShenShaList.fromJson(json['shenShaList'] as Map<String, dynamic>),
      panParams:
          DaLiuRenPanParams.fromJson(json['panParams'] as Map<String, dynamic>),
      questionId: json['questionId'] as String? ?? '',
      detailId: json['detailId'] as String? ?? '',
      interpretationId: json['interpretationId'] as String? ?? '',
    );

Map<String, dynamic> _$$DaLiuRenResultImplToJson(
        _$DaLiuRenResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'castTime': instance.castTime.toIso8601String(),
      'castMethod': _$CastMethodEnumMap[instance.castMethod]!,
      'lunarInfo': instance.lunarInfo.toJson(),
      'tianPan': instance.tianPan.toJson(),
      'siKe': instance.siKe.toJson(),
      'sanChuan': instance.sanChuan.toJson(),
      'shenJiangConfig': instance.shenJiangConfig.toJson(),
      'shenShaList': instance.shenShaList.toJson(),
      'panParams': instance.panParams.toJson(),
      'questionId': instance.questionId,
      'detailId': instance.detailId,
      'interpretationId': instance.interpretationId,
    };

const _$CastMethodEnumMap = {
  CastMethod.coin: 'coin',
  CastMethod.manual: 'manual',
  CastMethod.number: 'number',
  CastMethod.reportNumber: 'reportNumber',
  CastMethod.time: 'time',
  CastMethod.computer: 'computer',
};
