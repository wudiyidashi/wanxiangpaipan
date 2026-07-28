import '../../../../../divination_systems/qimen/models/qimen_enums.dart';
import '../models/qimen_analysis_models.dart';
import 'qimen_rule_catalog.dart';

enum QimenFocusLookup {
  value('value'),
  dutyStar('dutyStar'),
  dutyDoor('dutyDoor'),
  horse('horse');

  const QimenFocusLookup(this.id);
  final String id;
}

class QimenFocusIndicatorSpec {
  const QimenFocusIndicatorSpec({
    required this.roleId,
    required this.kind,
    required this.lookup,
    required this.reason,
    this.value,
  });

  final String roleId;
  final QimenIndicatorKind kind;
  final QimenFocusLookup lookup;
  final String? value;
  final String reason;
}

class QimenFocusRule {
  const QimenFocusRule({
    required this.ruleId,
    required this.indicators,
  });

  final String ruleId;
  final List<QimenFocusIndicatorSpec> indicators;
}

class QimenFocusCatalog {
  QimenFocusCatalog._();

  static const Map<QimenQuestionCategory, QimenFocusRule> byCategory =
      <QimenQuestionCategory, QimenFocusRule>{
    QimenQuestionCategory.general: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusGeneral,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'generalDutyStar',
          kind: QimenIndicatorKind.dutyStar,
          lookup: QimenFocusLookup.dutyStar,
          reason: '值符星作为综合盘势背景，不替代日干与时干。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'generalDutyDoor',
          kind: QimenIndicatorKind.dutyDoor,
          lookup: QimenFocusLookup.dutyDoor,
          reason: '值使门作为综合事态背景，不替代日干与时干。',
        ),
      ],
    ),
    QimenQuestionCategory.career: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusCareer,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'careerOpenDoor',
          kind: QimenIndicatorKind.door,
          lookup: QimenFocusLookup.value,
          value: '开门',
          reason: '事业类以开门为类别指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'careerDutyStar',
          kind: QimenIndicatorKind.dutyStar,
          lookup: QimenFocusLookup.dutyStar,
          reason: '值符星补充观察当局主导态势。',
        ),
      ],
    ),
    QimenQuestionCategory.wealth: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusWealth,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'wealthLifeDoor',
          kind: QimenIndicatorKind.door,
          lookup: QimenFocusLookup.value,
          value: '生门',
          reason: '财运类以生门为类别指标，不推断具体金额。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'wealthWu',
          kind: QimenIndicatorKind.stem,
          lookup: QimenFocusLookup.value,
          value: '戊',
          reason: '戊仪作为财务类别辅助指标。',
        ),
      ],
    ),
    QimenQuestionCategory.relationship: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusRelationship,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'relationshipYi',
          kind: QimenIndicatorKind.stem,
          lookup: QimenFocusLookup.value,
          value: '乙',
          reason: '乙奇作为关系双方之一，采用性别中立的成对观察。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'relationshipGeng',
          kind: QimenIndicatorKind.stem,
          lookup: QimenFocusLookup.value,
          value: '庚',
          reason: '庚仪作为关系双方之一，采用性别中立的成对观察。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'relationshipHarmony',
          kind: QimenIndicatorKind.deity,
          lookup: QimenFocusLookup.value,
          value: '六合',
          reason: '六合作为关系互动背景。',
        ),
      ],
    ),
    QimenQuestionCategory.health: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusHealth,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'healthDisease',
          kind: QimenIndicatorKind.star,
          lookup: QimenFocusLookup.value,
          value: '天芮',
          reason: '天芮作为疾病状态指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'healthTreatment',
          kind: QimenIndicatorKind.star,
          lookup: QimenFocusLookup.value,
          value: '天心',
          reason: '天心作为治疗与处置指标，与疾病指标分开记录。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'healthYi',
          kind: QimenIndicatorKind.stem,
          lookup: QimenFocusLookup.value,
          value: '乙',
          reason: '乙奇作为健康类别的辅助观察指标。',
        ),
      ],
    ),
    QimenQuestionCategory.study: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusStudy,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'studyAssistant',
          kind: QimenIndicatorKind.star,
          lookup: QimenFocusLookup.value,
          value: '天辅',
          reason: '天辅作为学习与辅导指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'studySceneryDoor',
          kind: QimenIndicatorKind.door,
          lookup: QimenFocusLookup.value,
          value: '景门',
          reason: '景门作为文书与呈现的类别指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'studyDing',
          kind: QimenIndicatorKind.stem,
          lookup: QimenFocusLookup.value,
          value: '丁',
          reason: '丁奇作为学业类别辅助指标。',
        ),
      ],
    ),
    QimenQuestionCategory.travel: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusTravel,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'travelOpenDoor',
          kind: QimenIndicatorKind.door,
          lookup: QimenFocusLookup.value,
          value: '开门',
          reason: '开门作为出行通达指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'travelHorse',
          kind: QimenIndicatorKind.marker,
          lookup: QimenFocusLookup.horse,
          reason: '驿马只表示发动背景，不保证出行结果。',
        ),
      ],
    ),
    QimenQuestionCategory.litigation: QimenFocusRule(
      ruleId: QimenRuleCatalog.focusLitigation,
      indicators: <QimenFocusIndicatorSpec>[
        QimenFocusIndicatorSpec(
          roleId: 'litigationAlarmDoor',
          kind: QimenIndicatorKind.door,
          lookup: QimenFocusLookup.value,
          value: '惊门',
          reason: '惊门作为争议与口舌类别指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'litigationGeng',
          kind: QimenIndicatorKind.stem,
          lookup: QimenFocusLookup.value,
          value: '庚',
          reason: '庚仪作为阻隔与对抗的辅助指标。',
        ),
        QimenFocusIndicatorSpec(
          roleId: 'litigationDutyDoor',
          kind: QimenIndicatorKind.dutyDoor,
          lookup: QimenFocusLookup.dutyDoor,
          reason: '值使门补充观察当前程序态势，不保证法律结果。',
        ),
      ],
    ),
  };
}
