import '../../../divination_systems/qimen/models/qimen_ju_info.dart';
import '../../../divination_systems/qimen/models/qimen_temporal_context.dart';

abstract interface class QimenJuStrategy {
  QimenJuInfo resolve(QimenTemporalContext context);
}
