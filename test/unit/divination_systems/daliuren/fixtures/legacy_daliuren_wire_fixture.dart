import 'dart:convert';

import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';

Map<String, dynamic> legacyShenJiangResultJson(
  DaLiuRenResult source, {
  String panRuleSetVersion = DlrRuleSetVersions.panV3,
  bool omitPanRuleSetVersion = false,
  String? id,
}) {
  final json = jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
  if (id != null) json['id'] = id;
  if (omitPanRuleSetVersion) {
    json.remove('panRuleSetVersion');
  } else {
    json['panRuleSetVersion'] = panRuleSetVersion;
  }
  final legacyConfig = legacyShenJiangConfigJson(json);
  final oldMap = (legacyConfig['diZhiToShenJiang'] as Map<String, String>);
  _rewritePersistedChengShenFacts(json, oldMap);
  _alignNestedPanRuleVersion(
    json,
    omitPanRuleSetVersion
        ? DlrRuleSetVersions.legacyUnknown
        : panRuleSetVersion,
  );
  json['shenJiangConfig'] = legacyConfig;
  return json;
}

Map<String, dynamic> legacyShenJiangConfigJson(
  Map<String, dynamic> resultJson,
) {
  final tianPan = resultJson['tianPan'] as Map<String, dynamic>;
  final tianPanMap =
      (tianPan['tianPanMap'] as Map<String, dynamic>).cast<String, dynamic>();
  final currentConfig = resultJson['shenJiangConfig'] as Map<String, dynamic>;
  final guiRenPosition = currentConfig['selectedGuiRenTianBranch'] as String;
  final isYangGui = currentConfig['isYangGui'] as bool;
  final guiRenIndex = DaLiuRenConstants.diZhi.indexOf(guiRenPosition);
  final step = isYangGui ? 1 : -1;
  final generalOrder = isYangGui ? _legacyYangOrder : _legacyYinOrder;
  final positions = <Map<String, dynamic>>[];
  final oldMap = <String, String>{};

  for (var index = 0; index < ShenJiang.values.length; index++) {
    final branch = DaLiuRenConstants.diZhi[(guiRenIndex + step * index) % 12];
    final generalId = generalOrder[index].toString().split('.').last;
    positions.add(<String, dynamic>{
      'shenJiang': generalId,
      'diZhi': branch,
      'tianPanZhi': tianPanMap[branch] as String,
    });
    oldMap[branch] = generalId;
  }

  return <String, dynamic>{
    'guiRenPosition': guiRenPosition,
    'isYangGui': isYangGui,
    'isYangRi': isYangGui,
    'positions': positions,
    'diZhiToShenJiang': oldMap,
  };
}

const List<ShenJiang> _legacyYangOrder = ShenJiang.values;

const List<ShenJiang> _legacyYinOrder = <ShenJiang>[
  ShenJiang.guiRen,
  ShenJiang.tianHou,
  ShenJiang.taiYin,
  ShenJiang.xuanWu,
  ShenJiang.taiChang,
  ShenJiang.baiHu,
  ShenJiang.tianKong,
  ShenJiang.qingLong,
  ShenJiang.gouChen,
  ShenJiang.liuHe,
  ShenJiang.zhuQue,
  ShenJiang.tengShe,
];

void _rewritePersistedChengShenFacts(
  Map<String, dynamic> resultJson,
  Map<String, String> oldMap,
) {
  final siKe = resultJson['siKe'] as Map<String, dynamic>;
  for (final key in const <String>['ke1', 'ke2', 'ke3', 'ke4']) {
    final lesson = siKe[key] as Map<String, dynamic>;
    lesson['chengShen'] = oldMap[lesson['shangShen'] as String]!;
  }

  final sanChuan = resultJson['sanChuan'] as Map<String, dynamic>;
  for (final key in const <String>['chuChuan', 'zhongChuan', 'moChuan']) {
    final transmission = sanChuan[key] as Map<String, dynamic>;
    transmission['chengShen'] = oldMap[transmission['diZhi'] as String]!;
  }
}

void _alignNestedPanRuleVersion(
  Map<String, dynamic> resultJson,
  String panRuleSetVersion,
) {
  if (!panRuleSetVersion.startsWith('daliuren-pan/')) return;
  final rawResolution = resultJson['monthGeneralResolution'];
  if (rawResolution is! Map<String, dynamic>) return;
  final rawRuleRef = rawResolution['executionRuleRef'];
  if (rawRuleRef is Map<String, dynamic>) {
    rawRuleRef['ruleSetVersion'] = panRuleSetVersion;
  }
}
