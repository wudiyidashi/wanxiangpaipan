import '../../../../../divination_systems/qimen/models/qimen_palace.dart';
import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class _FormationOccurrence {
  const _FormationOccurrence({
    required this.kind,
    required this.heavenStem,
    required this.heavenField,
    this.earthStem,
    this.earthField,
  });

  final String kind;
  final String heavenStem;
  final String heavenField;
  final String? earthStem;
  final String? earthField;
}

class QimenFormationService {
  QimenFormationService._();

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final facts = <QimenFact>[];
    final trace = <QimenTraceStep>[];
    final matchedRuleIds = <String>{};
    final dayGanZhi = result.temporalContext.dayGanZhi;
    final dayStem = dayGanZhi.substring(0, 1);
    final xunHiddenStem = result.xunHiddenStem;
    final palaces = [...result.palaces]
      ..sort((left, right) => left.number.compareTo(right.number));

    for (final palace in palaces) {
      for (final spec in QimenRuleCatalog.formationSpecs) {
        final occurrences = _occurrencesFor(palace, spec);
        for (final occurrence in occurrences) {
          if (!_matches(
            spec: spec,
            occurrence: occurrence,
            palace: palace,
            dayStem: dayStem,
            xunHiddenStem: xunHiddenStem,
          )) {
            continue;
          }
          final definition = QimenRuleCatalog.rule(spec.ruleId);
          final refs = _refs(
            palace: palace,
            occurrence: occurrence,
            spec: spec,
            dayGanZhi: dayGanZhi,
            xunHiddenStem: xunHiddenStem,
          );
          final fact = QimenFactSupport.fact(
            ruleId: spec.ruleId,
            ruleSetVersion: ruleSetVersion,
            targetKey: 'p${palace.number}:${occurrence.kind}',
            category: QimenFactCategory.formation,
            scope: QimenFactScope.palace,
            reason:
                '${palace.name}${occurrence.kind}命中${definition.displayTerm}结构；'
                '${definition.conflictTier == QimenConflictTier.corroborating ? '作为佐证，不单独决定成败。' : '按目录规则参与裁决。'}',
            inputRefs: refs,
            palaceNumbers: <int>[palace.number],
            focusRoleIds: QimenFactSupport.focusRolesAt(palace.number, focuses),
          );
          facts.add(fact);
          trace.add(QimenFactSupport.matchedTrace(fact));
          matchedRuleIds.add(spec.ruleId);
        }
      }

      for (final occurrence in _stemPairOccurrences(palace)) {
        if (QimenRuleCatalog.threeWonderDutyPairs[occurrence.heavenStem]
                ?.contains(occurrence.earthStem) ??
            false) {
          final fact = QimenFactSupport.fact(
            ruleId: QimenRuleCatalog.threeWonderDuty,
            ruleSetVersion: ruleSetVersion,
            targetKey: 'p${palace.number}:${occurrence.kind}',
            category: QimenFactCategory.formation,
            scope: QimenFactScope.palace,
            reason: '${palace.name}${occurrence.kind}天盘'
                '${occurrence.heavenStem}加地盘${occurrence.earthStem}，'
                '命中三奇得使固定仪对；若同时命中逃走、荧入太白或投江，'
                '仍由冲突层保留双方复核。',
            inputRefs: <QimenInputRef>[
              QimenInputRef(
                path: QimenFactSupport.palacePath(
                  palace.number,
                  occurrence.heavenField,
                ),
                value: occurrence.heavenStem,
              ),
              QimenInputRef(
                path: QimenFactSupport.palacePath(
                  palace.number,
                  occurrence.earthField!,
                ),
                value: occurrence.earthStem!,
              ),
            ],
            palaceNumbers: <int>[palace.number],
            focusRoleIds: QimenFactSupport.focusRolesAt(palace.number, focuses),
          );
          facts.add(fact);
          trace.add(QimenFactSupport.matchedTrace(fact));
          matchedRuleIds.add(QimenRuleCatalog.threeWonderDuty);
        }
      }
    }

    final allFormationRuleIds = <String>{
      ...QimenRuleCatalog.formationSpecs.map((value) => value.ruleId),
      QimenRuleCatalog.threeWonderDuty,
    }.toList(growable: false)
      ..sort();
    for (final ruleId in allFormationRuleIds) {
      if (!matchedRuleIds.contains(ruleId)) {
        trace.add(QimenFactSupport.notMatchedTrace(
          ruleId: ruleId,
          targetKey: 'global',
          inputRefs: const <QimenInputRef>[],
          explanation: '冻结盘面未命中${QimenRuleCatalog.rule(ruleId).displayTerm}。',
        ));
      }
    }
    trace.add(QimenFactSupport.notMatchedTrace(
      ruleId: QimenRuleCatalog.skyNet,
      targetKey: 'excluded-v1',
      inputRefs: <QimenInputRef>[
        QimenInputRef(
          path: r'$.temporalContext.hourGanZhi',
          value: result.temporalContext.hourGanZhi,
        ),
        QimenInputRef(path: r'$.zhiShiDoor', value: result.zhiShiDoor),
      ],
      explanation: '天网四张的时加癸、癸临时干与癸加癸见证存在分歧；'
          'v1 未锁定完整时干和值使谓词，因此显式不生成事实。',
      status: QimenEvaluationStatus.notApplicable,
    ));
    return QimenFactSupport.batch(facts, trace);
  }

  static List<_FormationOccurrence> _occurrencesFor(
    QimenPalace palace,
    QimenFormationSpec spec,
  ) {
    final needsEarth = spec.earthStem != null ||
        spec.earthMatchesDayStem ||
        spec.heavenMatchesDayStem ||
        spec.earthMatchesXunHiddenStem ||
        spec.heavenMatchesXunHiddenStem;
    if (!needsEarth) {
      return <_FormationOccurrence>[
        _FormationOccurrence(
          kind: 'primary',
          heavenStem: palace.heavenStem,
          heavenField: 'heavenStem',
        ),
        if (palace.hostedHeavenStem != null)
          _FormationOccurrence(
            kind: 'hostedHeaven',
            heavenStem: palace.hostedHeavenStem!,
            heavenField: 'hostedHeavenStem',
          ),
      ];
    }
    return _stemPairOccurrences(palace);
  }

  static List<_FormationOccurrence> _stemPairOccurrences(
    QimenPalace palace,
  ) =>
      <_FormationOccurrence>[
        _FormationOccurrence(
          kind: 'primary',
          heavenStem: palace.heavenStem,
          heavenField: 'heavenStem',
          earthStem: palace.earthStem,
          earthField: 'earthStem',
        ),
        if (palace.hostedHeavenStem != null)
          _FormationOccurrence(
            kind: 'hostedHeaven',
            heavenStem: palace.hostedHeavenStem!,
            heavenField: 'hostedHeavenStem',
            earthStem: palace.earthStem,
            earthField: 'earthStem',
          ),
        if (palace.hostedEarthStem != null)
          _FormationOccurrence(
            kind: 'hostedEarth',
            heavenStem: palace.heavenStem,
            heavenField: 'heavenStem',
            earthStem: palace.hostedEarthStem!,
            earthField: 'hostedEarthStem',
          ),
        if (palace.hostedHeavenStem != null && palace.hostedEarthStem != null)
          _FormationOccurrence(
            kind: 'hostedBoth',
            heavenStem: palace.hostedHeavenStem!,
            heavenField: 'hostedHeavenStem',
            earthStem: palace.hostedEarthStem!,
            earthField: 'hostedEarthStem',
          ),
      ];

  static bool _matches({
    required QimenFormationSpec spec,
    required _FormationOccurrence occurrence,
    required QimenPalace palace,
    required String dayStem,
    required String xunHiddenStem,
  }) {
    if (spec.heavenStem != null && spec.heavenStem != occurrence.heavenStem) {
      return false;
    }
    if (spec.earthStem != null && spec.earthStem != occurrence.earthStem) {
      return false;
    }
    if (spec.door != null && spec.door != palace.door) return false;
    if (spec.allowedDoors.isNotEmpty &&
        !spec.allowedDoors.contains(palace.door)) {
      return false;
    }
    if (spec.deity != null && spec.deity != palace.deity) return false;
    if (spec.palaceNumber != null && spec.palaceNumber != palace.number) {
      return false;
    }
    if (spec.heavenMatchesDayStem && occurrence.heavenStem != dayStem) {
      return false;
    }
    if (spec.earthMatchesDayStem && occurrence.earthStem != dayStem) {
      return false;
    }
    if (spec.heavenMatchesXunHiddenStem &&
        occurrence.heavenStem != xunHiddenStem) {
      return false;
    }
    if (spec.earthMatchesXunHiddenStem &&
        occurrence.earthStem != xunHiddenStem) {
      return false;
    }
    return true;
  }

  static List<QimenInputRef> _refs({
    required QimenPalace palace,
    required _FormationOccurrence occurrence,
    required QimenFormationSpec spec,
    required String dayGanZhi,
    required String xunHiddenStem,
  }) =>
      <QimenInputRef>[
        QimenInputRef(
          path: QimenFactSupport.palacePath(
            palace.number,
            occurrence.heavenField,
          ),
          value: occurrence.heavenStem,
        ),
        if (occurrence.earthField != null)
          QimenInputRef(
            path: QimenFactSupport.palacePath(
              palace.number,
              occurrence.earthField!,
            ),
            value: occurrence.earthStem!,
          ),
        if (spec.door != null || spec.allowedDoors.isNotEmpty)
          QimenInputRef(
            path: QimenFactSupport.palacePath(palace.number, 'door'),
            value: palace.door!,
          ),
        if (spec.deity != null)
          QimenInputRef(
            path: QimenFactSupport.palacePath(palace.number, 'deity'),
            value: palace.deity!,
          ),
        if (spec.heavenMatchesDayStem || spec.earthMatchesDayStem)
          QimenInputRef(
            path: r'$.temporalContext.dayGanZhi',
            value: dayGanZhi,
          ),
        if (spec.heavenMatchesXunHiddenStem || spec.earthMatchesXunHiddenStem)
          QimenInputRef(
            path: r'$.xunHiddenStem',
            value: xunHiddenStem,
          ),
      ];
}
