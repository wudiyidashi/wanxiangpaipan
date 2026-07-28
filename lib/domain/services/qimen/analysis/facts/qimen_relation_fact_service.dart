import '../../../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class QimenRelationFactService {
  QimenRelationFactService._();

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final pairRoles = QimenRuleCatalog
        .convergenceFocusRoles[result.panParams.questionCategory]!;
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
        path: r'$.panParams.questionCategory',
        value: result.panParams.questionCategory.id,
      ),
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
    final leftDoorFavorable =
        QimenRuleCatalog.favorableConvergenceDoors.contains(leftPalace.door);
    final rightDoorFavorable =
        QimenRuleCatalog.favorableConvergenceDoors.contains(rightPalace.door);
    final leftDoorAdverse =
        QimenRuleCatalog.adverseConvergenceDoors.contains(leftPalace.door);
    final rightDoorAdverse =
        QimenRuleCatalog.adverseConvergenceDoors.contains(rightPalace.door);
    final matchedPatterns = <QimenConvergencePattern>{
      if (samePalace && (leftDoorFavorable || rightDoorFavorable))
        QimenConvergencePattern.samePalaceWithEitherFavorableDoor,
      if (rightGeneratesLeft && leftDoorFavorable && rightDoorFavorable)
        QimenConvergencePattern.matterGeneratesSelfWithBothFavorableDoors,
      if (leftControlsRight && leftDoorFavorable)
        QimenConvergencePattern.selfControlsMatterWithSelfFavorableDoor,
      if (rightControlsLeft && leftDoorAdverse)
        QimenConvergencePattern.matterControlsSelfWithSelfAdverseDoor,
      if (leftGeneratesRight && rightDoorAdverse)
        QimenConvergencePattern.selfGeneratesMatterWithMatterAdverseDoor,
    };
    final favorable =
        QimenRuleCatalog.convergenceSpec(QimenRuleCatalog.favorableConvergence)
            .patterns
            .any(matchedPatterns.contains);
    final adverse =
        QimenRuleCatalog.convergenceSpec(QimenRuleCatalog.adverseConvergence)
            .patterns
            .any(matchedPatterns.contains);
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
