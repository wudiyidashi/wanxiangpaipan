import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class QimenStarDoorStateService {
  QimenStarDoorStateService._();

  static const Map<String, String> _branchElements = <String, String>{
    '寅': '木',
    '卯': '木',
    '巳': '火',
    '午': '火',
    '申': '金',
    '酉': '金',
    '亥': '水',
    '子': '水',
    '辰': '土',
    '未': '土',
    '戌': '土',
    '丑': '土',
  };

  static const List<String> _starStateRuleIds = <String>[
    QimenRuleCatalog.starStateWang,
    QimenRuleCatalog.starStateXiang,
    QimenRuleCatalog.starStateXiu,
    QimenRuleCatalog.starStateQiu,
    QimenRuleCatalog.starStateFei,
  ];

  static const List<String> _doorSeasonRuleIds = <String>[
    QimenRuleCatalog.doorSeasonWang,
    QimenRuleCatalog.doorSeasonXiang,
    QimenRuleCatalog.doorSeasonXiu,
    QimenRuleCatalog.doorSeasonQiu,
    QimenRuleCatalog.doorSeasonFei,
  ];

  static const List<String> _doorRelationRuleIds = <String>[
    QimenRuleCatalog.doorStateSame,
    QimenRuleCatalog.doorGeneratesPalace,
    QimenRuleCatalog.palaceGeneratesDoor,
    QimenRuleCatalog.doorControlsPalace,
    QimenRuleCatalog.palaceControlsDoor,
  ];

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final facts = <QimenFact>[];
    final trace = <QimenTraceStep>[];
    final matchedRuleIds = <String>{};
    final monthGanZhi = result.temporalContext.monthGanZhi;
    final currentSolarTerm = result.temporalContext.currentSolarTerm;
    final monthBranch = monthGanZhi.substring(1, 2);
    final monthElement = _branchElements[monthBranch]!;
    final palaces = [...result.palaces]
      ..sort((left, right) => left.number.compareTo(right.number));

    void add(QimenFact fact) {
      facts.add(fact);
      trace.add(QimenFactSupport.matchedTrace(fact));
      matchedRuleIds.add(fact.ruleId);
    }

    for (final palace in palaces) {
      final roles = QimenFactSupport.focusRolesAt(palace.number, focuses);
      _addStarState(
        add: add,
        palaceNumber: palace.number,
        star: palace.star,
        field: 'star',
        targetSuffix: 'primary',
        monthGanZhi: monthGanZhi,
        monthBranch: monthBranch,
        monthElement: monthElement,
        currentSolarTerm: currentSolarTerm,
        focusRoles: roles,
        ruleSetVersion: ruleSetVersion,
      );
      if (palace.hostedStar != null) {
        _addStarState(
          add: add,
          palaceNumber: palace.number,
          star: palace.hostedStar!,
          field: 'hostedStar',
          targetSuffix: 'hosted',
          monthGanZhi: monthGanZhi,
          monthBranch: monthBranch,
          monthElement: monthElement,
          currentSolarTerm: currentSolarTerm,
          focusRoles: roles,
          ruleSetVersion: ruleSetVersion,
        );
      }

      final door = palace.door;
      final doorElement =
          door == null ? null : QimenFactSupport.doorElements[door];
      if (door == null || doorElement == null) continue;

      _addDoorSeasonState(
        add: add,
        palaceNumber: palace.number,
        door: door,
        doorElement: doorElement,
        monthGanZhi: monthGanZhi,
        monthBranch: monthBranch,
        monthElement: monthElement,
        focusRoles: roles,
        ruleSetVersion: ruleSetVersion,
      );

      final relation = _doorPalaceRelation(doorElement, palace.element);
      final ruleId = _doorRelationRuleId(relation);
      add(QimenFactSupport.fact(
        ruleId: ruleId,
        ruleSetVersion: ruleSetVersion,
        targetKey: 'p${palace.number}:door:palace:$door',
        category: QimenFactCategory.doorState,
        scope: QimenFactScope.palace,
        reason: '${palace.name}$door属$doorElement，宫属${palace.element}，'
            '门宫关系为${QimenRuleCatalog.rule(ruleId).displayTerm}；'
            '季令旺衰与门迫另行记录。',
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

    for (final ruleId in <String>[
      ..._starStateRuleIds,
      ..._doorSeasonRuleIds,
      ..._doorRelationRuleIds,
    ]) {
      if (matchedRuleIds.contains(ruleId)) continue;
      trace.add(QimenFactSupport.notMatchedTrace(
        ruleId: ruleId,
        targetKey: 'global',
        inputRefs: <QimenInputRef>[
          QimenInputRef(
            path: r'$.temporalContext.monthGanZhi',
            value: monthGanZhi,
          ),
        ],
        explanation: '月柱$monthGanZhi与冻结九宫未产生'
            '${QimenRuleCatalog.rule(ruleId).displayTerm}事实。',
      ));
    }
    return QimenFactSupport.batch(facts, trace);
  }

  static void _addStarState({
    required void Function(QimenFact) add,
    required int palaceNumber,
    required String star,
    required String field,
    required String targetSuffix,
    required String monthGanZhi,
    required String monthBranch,
    required String monthElement,
    required String currentSolarTerm,
    required List<String> focusRoles,
    required String ruleSetVersion,
  }) {
    final starElement = QimenFactSupport.starElements[star]!;
    final state = _starSeasonalState(starElement, monthElement);
    final ruleId = _starStateRuleId(state);
    add(QimenFactSupport.fact(
      ruleId: ruleId,
      ruleSetVersion: ruleSetVersion,
      targetKey: 'p$palaceNumber:$targetSuffix:$star',
      category: QimenFactCategory.starState,
      scope: QimenFactScope.palace,
      reason: '月柱$monthGanZhi取$monthBranch月$monthElement令，'
          '$star属$starElement，九星季令状态为$state；该事实不单独决定成败。',
      inputRefs: <QimenInputRef>[
        QimenInputRef(
          path: r'$.temporalContext.monthGanZhi',
          value: monthGanZhi,
        ),
        QimenInputRef(
          path: r'$.temporalContext.currentSolarTerm',
          value: currentSolarTerm,
        ),
        QimenInputRef(
          path: QimenFactSupport.palacePath(palaceNumber, field),
          value: star,
        ),
      ],
      palaceNumbers: <int>[palaceNumber],
      focusRoleIds: focusRoles,
    ));
  }

  static void _addDoorSeasonState({
    required void Function(QimenFact) add,
    required int palaceNumber,
    required String door,
    required String doorElement,
    required String monthGanZhi,
    required String monthBranch,
    required String monthElement,
    required List<String> focusRoles,
    required String ruleSetVersion,
  }) {
    final state = _doorSeasonalState(doorElement, monthElement);
    final ruleId = _doorSeasonRuleId(state);
    add(QimenFactSupport.fact(
      ruleId: ruleId,
      ruleSetVersion: ruleSetVersion,
      targetKey: 'p$palaceNumber:door:season:$door',
      category: QimenFactCategory.doorState,
      scope: QimenFactScope.palace,
      reason: '月柱$monthGanZhi取$monthBranch月$monthElement令，'
          '$door属$doorElement，八门季令状态为$state；门宫关系与门迫另行记录。',
      inputRefs: <QimenInputRef>[
        QimenInputRef(
          path: r'$.temporalContext.monthGanZhi',
          value: monthGanZhi,
        ),
        QimenInputRef(
          path: QimenFactSupport.palacePath(palaceNumber, 'door'),
          value: door,
        ),
      ],
      palaceNumbers: <int>[palaceNumber],
      focusRoleIds: focusRoles,
    ));
  }

  static String _starSeasonalState(String star, String month) {
    if (star == month) return '相';
    if (QimenFactSupport.generates[star] == month) return '旺';
    if (QimenFactSupport.generates[month] == star) return '废';
    if (QimenFactSupport.controls[star] == month) return '休';
    return '囚';
  }

  static String _doorSeasonalState(String door, String month) {
    if (door == month) return '旺';
    if (QimenFactSupport.generates[month] == door) return '相';
    if (QimenFactSupport.controls[month] == door) return '休';
    if (QimenFactSupport.controls[door] == month) return '囚';
    return '废';
  }

  static String _starStateRuleId(String state) => switch (state) {
        '旺' => QimenRuleCatalog.starStateWang,
        '相' => QimenRuleCatalog.starStateXiang,
        '休' => QimenRuleCatalog.starStateXiu,
        '囚' => QimenRuleCatalog.starStateQiu,
        '废' => QimenRuleCatalog.starStateFei,
        _ => throw StateError('Unknown nine-star seasonal state: $state'),
      };

  static String _doorSeasonRuleId(String state) => switch (state) {
        '旺' => QimenRuleCatalog.doorSeasonWang,
        '相' => QimenRuleCatalog.doorSeasonXiang,
        '休' => QimenRuleCatalog.doorSeasonXiu,
        '囚' => QimenRuleCatalog.doorSeasonQiu,
        '废' => QimenRuleCatalog.doorSeasonFei,
        _ => throw StateError('Unknown eight-door seasonal state: $state'),
      };

  static String _doorPalaceRelation(String door, String palace) {
    if (door == palace) return 'same';
    if (QimenFactSupport.generates[door] == palace) return 'doorGenerates';
    if (QimenFactSupport.generates[palace] == door) return 'palaceGenerates';
    if (QimenFactSupport.controls[door] == palace) return 'doorControls';
    return 'palaceControls';
  }

  static String _doorRelationRuleId(String relation) => switch (relation) {
        'same' => QimenRuleCatalog.doorStateSame,
        'doorGenerates' => QimenRuleCatalog.doorGeneratesPalace,
        'palaceGenerates' => QimenRuleCatalog.palaceGeneratesDoor,
        'doorControls' => QimenRuleCatalog.doorControlsPalace,
        _ => QimenRuleCatalog.palaceControlsDoor,
      };
}
