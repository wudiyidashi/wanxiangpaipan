// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liuyao_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiuYaoResultImpl _$$LiuYaoResultImplFromJson(Map<String, dynamic> json) =>
    _$LiuYaoResultImpl(
      id: json['id'] as String,
      castTime: DateTime.parse(json['castTime'] as String),
      castMethod: $enumDecode(_$CastMethodEnumMap, json['castMethod']),
      mainGua: Gua.fromJson(json['mainGua'] as Map<String, dynamic>),
      changingGua: json['changingGua'] == null
          ? null
          : Gua.fromJson(json['changingGua'] as Map<String, dynamic>),
      lunarInfo: LunarInfo.fromJson(json['lunarInfo'] as Map<String, dynamic>),
      liuShen:
          (json['liuShen'] as List<dynamic>).map((e) => e as String).toList(),
      questionId: json['questionId'] as String? ?? '',
      detailId: json['detailId'] as String? ?? '',
      interpretationId: json['interpretationId'] as String? ?? '',
    );

Map<String, dynamic> _$$LiuYaoResultImplToJson(_$LiuYaoResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'castTime': instance.castTime.toIso8601String(),
      'castMethod': _$CastMethodEnumMap[instance.castMethod]!,
      'mainGua': instance.mainGua,
      'changingGua': instance.changingGua,
      'lunarInfo': instance.lunarInfo,
      'liuShen': instance.liuShen,
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
