import '../../../shared/analysis/models/verdict_models.dart';
import 'qimen_rule_catalog.dart';

enum QimenVerdictPredicate {
  invalidInputOrFocus('invalidInputOrFocus'),
  decisiveBlocker('decisiveBlocker'),
  releasableCondition('releasableCondition'),
  adverseConvergence('adverseConvergence'),
  favorableConvergence('favorableConvergence'),
  unresolvedDecisiveConflict('unresolvedDecisiveConflict'),
  conservativeFallback('conservativeFallback');

  const QimenVerdictPredicate(this.id);
  final String id;
}

class QimenVerdictRow {
  const QimenVerdictRow({
    required this.rowId,
    required this.predicate,
    required this.trend,
    required this.summary,
  });

  final String rowId;
  final QimenVerdictPredicate predicate;
  final VerdictTrend trend;
  final String summary;
}

class QimenVerdictTable {
  QimenVerdictTable._();

  static const List<QimenVerdictRow> rows = <QimenVerdictRow>[
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision00,
      predicate: QimenVerdictPredicate.invalidInputOrFocus,
      trend: VerdictTrend.buMing,
      summary: '输入或主焦点不完整，程序不作兼容性猜测。',
    ),
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision10,
      predicate: QimenVerdictPredicate.decisiveBlocker,
      trend: VerdictTrend.nanCheng,
      summary: '主焦点存在无显式解救的决定性阻断。',
    ),
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision20,
      predicate: QimenVerdictPredicate.releasableCondition,
      trend: VerdictTrend.daiTiaoJian,
      summary: '主焦点存在有明确解除路径的条件，先观察条件成熟。',
    ),
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision30,
      predicate: QimenVerdictPredicate.adverseConvergence,
      trend: VerdictTrend.nanCheng,
      summary: '类别指定焦点对命中不利收敛，且没有更高层解救。',
    ),
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision40,
      predicate: QimenVerdictPredicate.favorableConvergence,
      trend: VerdictTrend.keCheng,
      summary: '类别指定焦点对命中有利收敛，且无决定性未决反向证据。',
    ),
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision50,
      predicate: QimenVerdictPredicate.unresolvedDecisiveConflict,
      trend: VerdictTrend.buMing,
      summary: '决定性扶抑证据同层冲突且无目录化解救。',
    ),
    QimenVerdictRow(
      rowId: QimenRuleCatalog.decision60,
      predicate: QimenVerdictPredicate.conservativeFallback,
      trend: VerdictTrend.buMing,
      summary: '现有证据仅供佐证或背景，未达到决定性规则的准入条件。',
    ),
  ];
}
