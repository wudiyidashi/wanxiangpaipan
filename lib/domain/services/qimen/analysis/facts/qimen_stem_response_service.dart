import '../../../../../divination_systems/qimen/models/qimen_result.dart';
import '../models/qimen_analysis_models.dart';
import '../models/qimen_rule_models.dart';
import '../rules/qimen_rule_catalog.dart';
import 'qimen_fact_support.dart';

class _StemPair {
  const _StemPair({
    required this.kind,
    required this.heavenStem,
    required this.earthStem,
    required this.heavenField,
    required this.earthField,
  });

  final String kind;
  final String heavenStem;
  final String earthStem;
  final String heavenField;
  final String earthField;
}

class QimenStemResponseService {
  QimenStemResponseService._();

  static QimenFactBatch evaluate(
    QimenResult result,
    List<QimenFocus> focuses, {
    required String ruleSetVersion,
  }) {
    final facts = <QimenFact>[];
    final trace = <QimenTraceStep>[];
    final palaces = [...result.palaces]
      ..sort((left, right) => left.number.compareTo(right.number));

    for (final palace in palaces) {
      final pairs = <_StemPair>[
        _StemPair(
          kind: 'primary',
          heavenStem: palace.heavenStem,
          earthStem: palace.earthStem,
          heavenField: 'heavenStem',
          earthField: 'earthStem',
        ),
        if (palace.hostedHeavenStem != null)
          _StemPair(
            kind: 'hostedHeaven',
            heavenStem: palace.hostedHeavenStem!,
            earthStem: palace.earthStem,
            heavenField: 'hostedHeavenStem',
            earthField: 'earthStem',
          ),
        if (palace.hostedEarthStem != null)
          _StemPair(
            kind: 'hostedEarth',
            heavenStem: palace.heavenStem,
            earthStem: palace.hostedEarthStem!,
            heavenField: 'heavenStem',
            earthField: 'hostedEarthStem',
          ),
        if (palace.hostedHeavenStem != null && palace.hostedEarthStem != null)
          _StemPair(
            kind: 'hostedBoth',
            heavenStem: palace.hostedHeavenStem!,
            earthStem: palace.hostedEarthStem!,
            heavenField: 'hostedHeavenStem',
            earthField: 'hostedEarthStem',
          ),
      ];
      final roles = QimenFactSupport.focusRolesAt(palace.number, focuses);
      for (final pair in pairs) {
        final spec = QimenRuleCatalog.stemResponseSpec(
          pair.heavenStem,
          pair.earthStem,
        );
        final fact = QimenFactSupport.fact(
          ruleId: spec.ruleId,
          ruleSetVersion: ruleSetVersion,
          targetKey: 'p${palace.number}:${pair.kind}',
          category: QimenFactCategory.stemResponse,
          scope: QimenFactScope.palace,
          reason: '${palace.name}${pair.kind}：${spec.claimSummary}',
          inputRefs: <QimenInputRef>[
            QimenInputRef(
              path: QimenFactSupport.palacePath(
                palace.number,
                pair.heavenField,
              ),
              value: pair.heavenStem,
            ),
            QimenInputRef(
              path: QimenFactSupport.palacePath(
                palace.number,
                pair.earthField,
              ),
              value: pair.earthStem,
            ),
          ],
          palaceNumbers: <int>[palace.number],
          focusRoleIds: roles,
        );
        facts.add(fact);
        trace.add(QimenFactSupport.matchedTrace(fact));
      }
    }
    return QimenFactSupport.batch(facts, trace);
  }
}
