import '../../../../../divination_systems/qimen/models/qimen_enums.dart';
import '../../../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class QimenRelationFactService {
  QimenRelationFactService._();

  static const Set<String> _favorableDoors = <String>{'开门', '休门', '生门'};
  static const Set<String> _adverseDoors = <String>{'死门', '伤门', '惊门'};

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final pairRoles = _pairRoles(result.panParams.questionCategory);
    final left = _focus(focuses, pairRoles.$1);
    final right = _focus(focuses, pairRoles.$2);
    if (left == null || right == null) {
      return QimenFactSupport.batch(
        const <QimenFact>[],
        <QimenTraceStep>[
          for (final ruleId in const <String>[
            QimenRuleCatalog.favorableConvergence,
            QimenRuleCatalog.adverseConvergence,
          ])
            QimenFactSupport.notMatchedTrace(
              ruleId: ruleId,
              targetKey: result.panParams.questionCategory.id,
              inputRefs: const <QimenInputRef>[],
              explanation: '类别指定焦点对不完整，收敛规则不适用。',
              status: QimenEvaluationStatus.notApplicable,
            ),
        ],
      );
    }

    final leftPalace = _palace(result, left.palaceNumber)!;
    final rightPalace = _palace(result, right.palaceNumber)!;
    final refs = <QimenInputRef>[
      QimenInputRef(
        path: QimenFactSupport.palacePath(leftPalace.number, 'element'),
        value: leftPalace.element,
      ),
      QimenInputRef(
        path: QimenFactSupport.palacePath(rightPalace.number, 'element'),
        value: rightPalace.element,
      ),
      QimenInputRef(
        path: QimenFactSupport.palacePath(leftPalace.number, 'door'),
        value: leftPalace.door ?? 'null',
      ),
      QimenInputRef(
        path: QimenFactSupport.palacePath(rightPalace.number, 'door'),
        value: rightPalace.door ?? 'null',
      ),
    ];
    final samePalace = leftPalace.number == rightPalace.number;
    final rightGeneratesLeft =
        QimenFactSupport.generates[rightPalace.element] == leftPalace.element;
    final leftControlsRight =
        QimenFactSupport.controls[leftPalace.element] == rightPalace.element;
    final rightControlsLeft =
        QimenFactSupport.controls[rightPalace.element] == leftPalace.element;
    final leftGeneratesRight =
        QimenFactSupport.generates[leftPalace.element] == rightPalace.element;
    final leftDoorFavorable = _favorableDoors.contains(leftPalace.door);
    final rightDoorFavorable = _favorableDoors.contains(rightPalace.door);
    final leftDoorAdverse = _adverseDoors.contains(leftPalace.door);
    final rightDoorAdverse = _adverseDoors.contains(rightPalace.door);

    final favorable =
        (samePalace && (leftDoorFavorable || rightDoorFavorable)) ||
            (rightGeneratesLeft && leftDoorFavorable && rightDoorFavorable) ||
            (leftControlsRight && leftDoorFavorable);
    final adverse = (rightControlsLeft && leftDoorAdverse) ||
        (leftGeneratesRight && rightDoorAdverse);
    final facts = <QimenFact>[];
    final trace = <QimenTraceStep>[];
    final target = '${result.panParams.questionCategory.id}:'
        '${left.roleId}:${right.roleId}';

    if (favorable && !adverse) {
      final fact = QimenFactSupport.fact(
        ruleId: QimenRuleCatalog.favorableConvergence,
        ruleSetVersion: ruleSetVersion,
        targetKey: target,
        category: QimenFactCategory.relation,
        scope: QimenFactScope.focusRelation,
        reason: '${left.roleId}与${right.roleId}命中类别有利收敛的完整宫门关系；'
            '该项目规则不由标签数量触发。',
        inputRefs: refs,
        palaceNumbers: <int>[leftPalace.number, rightPalace.number],
        focusRoleIds: <String>[left.roleId, right.roleId],
      );
      facts.add(fact);
      trace.add(QimenFactSupport.matchedTrace(fact));
    } else {
      trace.add(QimenFactSupport.notMatchedTrace(
        ruleId: QimenRuleCatalog.favorableConvergence,
        targetKey: target,
        inputRefs: refs,
        explanation: '焦点对未命中类别有利收敛的完整关系式。',
      ));
    }

    if (adverse && !favorable) {
      final fact = QimenFactSupport.fact(
        ruleId: QimenRuleCatalog.adverseConvergence,
        ruleSetVersion: ruleSetVersion,
        targetKey: target,
        category: QimenFactCategory.relation,
        scope: QimenFactScope.focusRelation,
        reason: '${left.roleId}与${right.roleId}命中类别不利收敛的完整宫门关系；'
            '该项目规则不由标签数量触发。',
        inputRefs: refs,
        palaceNumbers: <int>[leftPalace.number, rightPalace.number],
        focusRoleIds: <String>[left.roleId, right.roleId],
      );
      facts.add(fact);
      trace.add(QimenFactSupport.matchedTrace(fact));
    } else {
      trace.add(QimenFactSupport.notMatchedTrace(
        ruleId: QimenRuleCatalog.adverseConvergence,
        targetKey: target,
        inputRefs: refs,
        explanation: '焦点对未命中类别不利收敛的完整关系式。',
      ));
    }
    return QimenFactSupport.batch(facts, trace);
  }

  static (String, String) _pairRoles(QimenQuestionCategory category) =>
      switch (category) {
        QimenQuestionCategory.relationship => (
            'relationshipYi',
            'relationshipGeng'
          ),
        QimenQuestionCategory.health => ('healthDisease', 'healthTreatment'),
        _ => ('self', 'matter'),
      };

  static QimenFocus? _focus(List<QimenFocus> focuses, String roleId) {
    for (final focus in focuses) {
      if (focus.roleId == roleId) return focus;
    }
    return null;
  }

  static QimenPalace? _palace(QimenResult result, int number) {
    for (final palace in result.palaces) {
      if (palace.number == number) return palace;
    }
    return null;
  }
}
