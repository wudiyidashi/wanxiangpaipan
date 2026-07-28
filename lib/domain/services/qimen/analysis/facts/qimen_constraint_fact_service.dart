import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class QimenConstraintFactService {
  QimenConstraintFactService._();

  static const Map<String, int> _punishmentPalaces = <String, int>{
    '戊': 3,
    '己': 2,
    '庚': 8,
    '辛': 9,
    '壬': 4,
    '癸': 4,
  };

  static const Map<String, int> _tombPalaces = <String, int>{
    '乙': 2,
    '丙': 6,
    '丁': 8,
    '戊': 6,
    '己': 8,
    '庚': 8,
    '辛': 4,
    '壬': 4,
    '癸': 2,
  };

  static const Map<int, String> tombBranches = <int, String>{
    2: '未',
    4: '辰',
    6: '戌',
    8: '丑',
  };

  static const Map<String, String> clashBranches = <String, String>{
    '子': '午',
    '丑': '未',
    '寅': '申',
    '卯': '酉',
    '辰': '戌',
    '巳': '亥',
    '午': '子',
    '未': '丑',
    '申': '寅',
    '酉': '卯',
    '戌': '辰',
    '亥': '巳',
  };

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final facts = <QimenFact>[];
    final trace = <QimenTraceStep>[];
    final matchedByRule = <String, int>{};
    final palaces = [...result.palaces]
      ..sort((left, right) => left.number.compareTo(right.number));

    void add(QimenFact fact) {
      facts.add(fact);
      trace.add(QimenFactSupport.matchedTrace(fact));
      matchedByRule.update(fact.ruleId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    for (final palace in palaces) {
      final roles = QimenFactSupport.focusRolesAt(palace.number, focuses);
      final door = palace.door;
      final doorElement =
          door == null ? null : QimenFactSupport.doorElements[door];
      if (door != null &&
          doorElement != null &&
          QimenFactSupport.controls[doorElement] == palace.element) {
        add(QimenFactSupport.fact(
          ruleId: QimenRuleCatalog.doorPressure,
          ruleSetVersion: ruleSetVersion,
          targetKey: 'p${palace.number}:door',
          category: QimenFactCategory.constraint,
          scope: QimenFactScope.palace,
          reason: '${palace.name}$door属$doorElement，门克宫${palace.element}形成门迫；'
              '作为可解除约束记录，不累计为凶。',
          inputRefs: <QimenInputRef>[
            QimenInputRef(
              path: QimenFactSupport.palacePath(palace.number, 'door'),
              value: door,
            ),
            QimenInputRef(
              path: QimenFactSupport.palacePath(palace.number, 'element'),
              value: palace.element,
            ),
          ],
          palaceNumbers: <int>[palace.number],
          focusRoleIds: roles,
        ));
      }

      _evaluateStem(
        palaceNumber: palace.number,
        stem: palace.heavenStem,
        field: 'heavenStem',
        targetSuffix: 'primary',
        xunHiddenStem: result.xunHiddenStem,
        zhiFuPalace: result.zhiFuPalace,
        focusRoles: roles,
        ruleSetVersion: ruleSetVersion,
        add: add,
      );
      if (palace.hostedHeavenStem != null) {
        _evaluateStem(
          palaceNumber: palace.number,
          stem: palace.hostedHeavenStem!,
          field: 'hostedHeavenStem',
          targetSuffix: 'hosted',
          xunHiddenStem: result.xunHiddenStem,
          zhiFuPalace: result.zhiFuPalace,
          focusRoles: roles,
          ruleSetVersion: ruleSetVersion,
          add: add,
        );
      }

      if (palace.voidBranches.isNotEmpty) {
        final branches = [...palace.voidBranches]..sort();
        add(QimenFactSupport.fact(
          ruleId: QimenRuleCatalog.voidState,
          ruleSetVersion: ruleSetVersion,
          targetKey: 'p${palace.number}:${branches.join()}',
          category: QimenFactCategory.constraint,
          scope: QimenFactScope.palace,
          reason: '${palace.name}承载时旬空亡${branches.join('、')}；'
              '空亡转为待填实观察条件，不直接判成败。',
          inputRefs: <QimenInputRef>[
            QimenInputRef(
              path: QimenFactSupport.palacePath(
                palace.number,
                'voidBranches',
              ),
              value: branches.join(','),
            ),
          ],
          palaceNumbers: <int>[palace.number],
          focusRoleIds: roles,
        ));
      }

      if (palace.isHorse) {
        add(QimenFactSupport.fact(
          ruleId: QimenRuleCatalog.horseActivation,
          ruleSetVersion: ruleSetVersion,
          targetKey: 'p${palace.number}:${result.horseBranch}',
          category: QimenFactCategory.activation,
          scope: QimenFactScope.palace,
          reason: '驿马${result.horseBranch}落${palace.name}，只表示相关焦点有发动窗口。',
          inputRefs: <QimenInputRef>[
            QimenInputRef(path: r'$.horseBranch', value: result.horseBranch),
            QimenInputRef(
              path: QimenFactSupport.palacePath(palace.number, 'isHorse'),
              value: 'true',
            ),
          ],
          palaceNumbers: <int>[palace.number],
          focusRoleIds: roles,
        ));
      }
    }

    for (final ruleId in const <String>[
      QimenRuleCatalog.doorPressure,
      QimenRuleCatalog.instrumentPunishment,
      QimenRuleCatalog.qiYiTomb,
      QimenRuleCatalog.voidState,
      QimenRuleCatalog.horseActivation,
    ]) {
      if (!matchedByRule.containsKey(ruleId)) {
        trace.add(QimenFactSupport.notMatchedTrace(
          ruleId: ruleId,
          targetKey: 'global',
          inputRefs: const <QimenInputRef>[],
          explanation: '冻结盘面未命中${QimenRuleCatalog.rule(ruleId).displayTerm}。',
        ));
      }
    }
    return QimenFactSupport.batch(facts, trace);
  }

  static void _evaluateStem({
    required int palaceNumber,
    required String stem,
    required String field,
    required String targetSuffix,
    required String xunHiddenStem,
    required int zhiFuPalace,
    required List<String> focusRoles,
    required String ruleSetVersion,
    required void Function(QimenFact) add,
  }) {
    final refs = <QimenInputRef>[
      QimenInputRef(
        path: QimenFactSupport.palacePath(palaceNumber, field),
        value: stem,
      ),
    ];
    if (palaceNumber == zhiFuPalace &&
        stem == xunHiddenStem &&
        _punishmentPalaces[xunHiddenStem] == palaceNumber) {
      add(QimenFactSupport.fact(
        ruleId: QimenRuleCatalog.instrumentPunishment,
        ruleSetVersion: ruleSetVersion,
        targetKey: 'p$palaceNumber:$targetSuffix:$stem',
        category: QimenFactCategory.constraint,
        scope: QimenFactScope.palace,
        reason: '时旬遁仪$xunHiddenStem落$palaceNumber宫命中六仪击刑表；'
            '主事实与寄宫事实分别保留。',
        inputRefs: <QimenInputRef>[
          QimenInputRef(path: r'$.xunHiddenStem', value: xunHiddenStem),
          QimenInputRef(path: r'$.zhiFuPalace', value: '$zhiFuPalace'),
          ...refs,
        ],
        palaceNumbers: <int>[palaceNumber],
        focusRoleIds: focusRoles,
      ));
    }
    if (_tombPalaces[stem] == palaceNumber) {
      final tombBranch = tombBranches[palaceNumber]!;
      add(QimenFactSupport.fact(
        ruleId: QimenRuleCatalog.qiYiTomb,
        ruleSetVersion: ruleSetVersion,
        targetKey: 'p$palaceNumber:$targetSuffix:$stem',
        category: QimenFactCategory.constraint,
        scope: QimenFactScope.palace,
        reason: '$stem落$palaceNumber宫入$tombBranch墓；作为待冲墓条件记录。',
        inputRefs: refs,
        palaceNumbers: <int>[palaceNumber],
        focusRoleIds: focusRoles,
      ));
    }
  }
}
