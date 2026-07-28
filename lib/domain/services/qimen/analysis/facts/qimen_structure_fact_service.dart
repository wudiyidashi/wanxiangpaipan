import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class QimenStructureFactService {
  QimenStructureFactService._();

  static const Map<int, String> _starOrigins = <int, String>{
    1: '天蓬',
    2: '天芮',
    3: '天冲',
    4: '天辅',
    5: '天禽',
    6: '天心',
    7: '天柱',
    8: '天任',
    9: '天英',
  };

  static const Map<int, String> _doorOrigins = <int, String>{
    1: '休门',
    2: '死门',
    3: '伤门',
    4: '杜门',
    6: '开门',
    7: '惊门',
    8: '生门',
    9: '景门',
  };

  static const Map<int, int> _opposites = <int, int>{
    1: 9,
    2: 8,
    3: 7,
    4: 6,
    5: 5,
    6: 4,
    7: 3,
    8: 2,
    9: 1,
  };

  static const Set<String> _fiveNotMeetingPairs = <String>{
    '甲日庚午时',
    '乙日辛巳时',
    '丙日壬辰时',
    '丁日癸卯时',
    '戊日甲寅时',
    '己日乙丑时',
    '庚日丙子时',
    '辛日丁酉时',
    '壬日戊申时',
    '癸日己未时',
  };

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final facts = <QimenFact>[];
    final trace = <QimenTraceStep>[];
    final palaces = [...result.palaces]
      ..sort((left, right) => left.number.compareTo(right.number));
    final starRefs = <QimenInputRef>[
      for (final palace in palaces)
        QimenInputRef(
          path: QimenFactSupport.palacePath(palace.number, 'star'),
          value: palace.star,
        ),
    ];
    final doorRefs = <QimenInputRef>[
      for (final palace in palaces.where((palace) => palace.door != null))
        QimenInputRef(
          path: QimenFactSupport.palacePath(palace.number, 'door'),
          value: palace.door!,
        ),
    ];
    final allRoles =
        focuses.map((focus) => focus.roleId).toList(growable: false)..sort();

    final starsFuYin = palaces.every(
      (palace) => palace.star == _starOrigins[palace.number],
    );
    final doorsFuYin = palaces
        .where((palace) => palace.number != 5)
        .every((palace) => palace.door == _doorOrigins[palace.number]);
    final starsFanYin = palaces.every((palace) {
      final opposite = _opposites[palace.number]!;
      return palace.star == _starOrigins[opposite];
    });
    final doorsFanYin = palaces.where((palace) => palace.number != 5).every(
        (palace) => palace.door == _doorOrigins[_opposites[palace.number]!]);

    _recordStructure(
      matched: starsFuYin,
      ruleId: QimenRuleCatalog.starFuYin,
      reason: '九星主字段逐宫与本位表相同，命中九星伏吟；只记录结构迟滞背景。',
      refs: starRefs,
      focusRoles: allRoles,
      ruleSetVersion: ruleSetVersion,
      facts: facts,
      trace: trace,
    );
    _recordStructure(
      matched: doorsFuYin,
      ruleId: QimenRuleCatalog.doorFuYin,
      reason: '八门主字段逐宫与本位表相同，命中八门伏吟；只记录结构迟滞背景。',
      refs: doorRefs,
      focusRoles: allRoles,
      ruleSetVersion: ruleSetVersion,
      facts: facts,
      trace: trace,
    );
    _recordStructure(
      matched: starsFuYin && doorsFuYin,
      ruleId: QimenRuleCatalog.combinedFuYin,
      reason: '九星与八门同时伏吟，形成可待发动的星门俱伏吟条件。',
      refs: <QimenInputRef>[
        ...starRefs,
        ...doorRefs,
      ],
      focusRoles: allRoles,
      ruleSetVersion: ruleSetVersion,
      facts: facts,
      trace: trace,
    );
    _recordStructure(
      matched: starsFanYin,
      ruleId: QimenRuleCatalog.starFanYin,
      reason: '九星主字段逐宫落在本位对宫，命中九星反吟；只记录反复背景。',
      refs: starRefs,
      focusRoles: allRoles,
      ruleSetVersion: ruleSetVersion,
      facts: facts,
      trace: trace,
    );
    _recordStructure(
      matched: doorsFanYin,
      ruleId: QimenRuleCatalog.doorFanYin,
      reason: '八门主字段逐宫落在本位对宫，命中八门反吟；只记录反复背景。',
      refs: doorRefs,
      focusRoles: allRoles,
      ruleSetVersion: ruleSetVersion,
      facts: facts,
      trace: trace,
    );
    _recordStructure(
      matched: starsFanYin && doorsFanYin,
      ruleId: QimenRuleCatalog.combinedFanYin,
      reason: '九星与八门同时反吟，形成待转折观察的星门俱反吟条件。',
      refs: <QimenInputRef>[
        ...starRefs,
        ...doorRefs,
      ],
      focusRoles: allRoles,
      ruleSetVersion: ruleSetVersion,
      facts: facts,
      trace: trace,
    );

    final day = result.temporalContext.dayGanZhi;
    final hour = result.temporalContext.hourGanZhi;
    final pair = '${day.substring(0, 1)}日$hour时';
    final fiveNotMeeting = _fiveNotMeetingPairs.contains(pair);
    final refs = <QimenInputRef>[
      QimenInputRef(path: r'$.temporalContext.dayGanZhi', value: day),
      QimenInputRef(path: r'$.temporalContext.hourGanZhi', value: hour),
    ];
    if (fiveNotMeeting) {
      final fact = QimenFactSupport.fact(
        ruleId: QimenRuleCatalog.fiveNotMeeting,
        ruleSetVersion: ruleSetVersion,
        targetKey: '$day:$hour',
        category: QimenFactCategory.structure,
        scope: QimenFactScope.global,
        reason: '持久化日柱$day、时柱$hour命中五不遇时对照表；该规则无自动解救路径。',
        inputRefs: refs,
        palaceNumbers: const <int>[],
        focusRoleIds: const <String>['self', 'matter'],
      );
      facts.add(fact);
      trace.add(QimenFactSupport.matchedTrace(fact));
    } else {
      trace.add(QimenFactSupport.notMatchedTrace(
        ruleId: QimenRuleCatalog.fiveNotMeeting,
        targetKey: '$day:$hour',
        inputRefs: refs,
        explanation: '持久化日时柱未命中五不遇时对照表。',
      ));
    }

    return QimenFactSupport.batch(facts, trace);
  }

  static void _recordStructure({
    required bool matched,
    required String ruleId,
    required String reason,
    required List<QimenInputRef> refs,
    required List<String> focusRoles,
    required String ruleSetVersion,
    required List<QimenFact> facts,
    required List<QimenTraceStep> trace,
  }) {
    if (matched) {
      final fact = QimenFactSupport.fact(
        ruleId: ruleId,
        ruleSetVersion: ruleSetVersion,
        targetKey: 'global',
        category: QimenFactCategory.structure,
        scope: QimenFactScope.global,
        reason: reason,
        inputRefs: refs,
        palaceNumbers: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        focusRoleIds: focusRoles,
      );
      facts.add(fact);
      trace.add(QimenFactSupport.matchedTrace(fact));
    } else {
      trace.add(QimenFactSupport.notMatchedTrace(
        ruleId: ruleId,
        targetKey: 'global',
        inputRefs: refs,
        explanation: '冻结盘面未命中${QimenRuleCatalog.rule(ruleId).displayTerm}。',
      ));
    }
  }
}
