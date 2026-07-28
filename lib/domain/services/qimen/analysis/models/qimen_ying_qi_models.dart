import '../../../shared/analysis/models/verdict_models.dart';

enum QimenYingQiTriggerKind {
  stem('stem'),
  branch('branch'),
  solarTerm('solarTerm'),
  conditionRelease('conditionRelease');

  const QimenYingQiTriggerKind(this.id);
  final String id;

  static QimenYingQiTriggerKind fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () =>
            throw FormatException('Unknown Qimen YingQi trigger kind: $id'),
      );
}

enum QimenYingQiOrderBand {
  conditionRelease('conditionRelease', 0),
  focusActivation('focusActivation', 1),
  contextWindow('contextWindow', 2);

  const QimenYingQiOrderBand(this.id, this.order);
  final String id;
  final int order;

  static QimenYingQiOrderBand fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () =>
            throw FormatException('Unknown Qimen YingQi order band: $id'),
      );
}

class QimenYingQiCandidate {
  QimenYingQiCandidate({
    required this.candidateId,
    required this.ruleId,
    required this.triggerKind,
    required this.triggerValue,
    required this.scale,
    required this.orderBand,
    required this.targetFocusRoleId,
    required this.reason,
    required List<String> relatedFactIds,
    required List<String> relatedConditionIds,
    required List<String> sourceIds,
  })  : relatedFactIds = List<String>.unmodifiable(relatedFactIds),
        relatedConditionIds = List<String>.unmodifiable(relatedConditionIds),
        sourceIds = List<String>.unmodifiable(sourceIds);

  final String candidateId;
  final String ruleId;
  final QimenYingQiTriggerKind triggerKind;
  final String triggerValue;
  final YingQiScale scale;
  final QimenYingQiOrderBand orderBand;
  final String? targetFocusRoleId;
  final String reason;
  final List<String> relatedFactIds;
  final List<String> relatedConditionIds;
  final List<String> sourceIds;

  String get deduplicationKey => <String>[
        qimenYingQiScaleId(scale),
        triggerKind.id,
        triggerValue,
        targetFocusRoleId ?? 'global',
      ].join('|');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'candidateId': candidateId,
        'ruleId': ruleId,
        'triggerKind': triggerKind.id,
        'triggerValue': triggerValue,
        'scale': qimenYingQiScaleId(scale),
        'orderBand': orderBand.id,
        'targetFocusRoleId': targetFocusRoleId,
        'reason': reason,
        'relatedFactIds': relatedFactIds,
        'relatedConditionIds': relatedConditionIds,
        'sourceIds': sourceIds,
      };

  factory QimenYingQiCandidate.fromJson(Map<String, dynamic> json) =>
      QimenYingQiCandidate(
        candidateId: json['candidateId'] as String,
        ruleId: json['ruleId'] as String,
        triggerKind:
            QimenYingQiTriggerKind.fromId(json['triggerKind'] as String),
        triggerValue: json['triggerValue'] as String,
        scale: qimenYingQiScaleFromId(json['scale'] as String),
        orderBand: QimenYingQiOrderBand.fromId(json['orderBand'] as String),
        targetFocusRoleId: json['targetFocusRoleId'] as String?,
        reason: json['reason'] as String,
        relatedFactIds: List<String>.from(json['relatedFactIds'] as List),
        relatedConditionIds:
            List<String>.from(json['relatedConditionIds'] as List),
        sourceIds: List<String>.from(json['sourceIds'] as List),
      );
}

String qimenYingQiScaleId(YingQiScale scale) => switch (scale) {
      YingQiScale.ri => 'ri',
      YingQiScale.yue => 'yue',
      YingQiScale.nian => 'nian',
    };

YingQiScale qimenYingQiScaleFromId(String id) => switch (id) {
      'ri' => YingQiScale.ri,
      'yue' => YingQiScale.yue,
      'nian' => YingQiScale.nian,
      _ => throw FormatException('Unknown YingQi scale: $id'),
    };
