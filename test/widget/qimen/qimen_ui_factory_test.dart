import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_cast_screen.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_result_screen.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_ui_factory.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/presentation/widgets/history_record_card.dart';

import '../../unit/services/qimen/analysis/helpers/qimen_analysis_fixtures.dart';

class _WrongResult extends Fake implements DivinationResult {}

void main() {
  final factory = QimenUIFactory();

  test('builds only the two supported cast methods', () {
    final time = factory.buildCastScreen(CastMethod.time);
    final manual = factory.buildCastScreen(CastMethod.manual);

    expect(time, isA<QimenCastScreen>());
    expect((time as QimenCastScreen).initialMethod, CastMethod.time);
    expect(manual, isA<QimenCastScreen>());
    expect((manual as QimenCastScreen).initialMethod, CastMethod.manual);
    expect(
      () => factory.buildCastScreen(CastMethod.coin),
      throwsUnsupportedError,
    );
  });

  test('strictly rejects results from another system', () {
    final wrong = _WrongResult();

    expect(() => factory.buildResultScreen(wrong), throwsArgumentError);
    expect(() => factory.buildHistoryCard(wrong), throwsArgumentError);
  });

  test('builds result and history UI with Qimen-specific method labels', () {
    final timeResult = fixedQimenAnalysisResult();
    final manualJson = fixedQimenAnalysisPanMap()
      ..['castMethod'] = CastMethod.manual.id;
    final manualResult = QimenResult.fromJson(manualJson);

    expect(factory.buildResultScreen(timeResult), isA<QimenResultScreen>());

    final timeCard = factory.buildHistoryCard(timeResult) as HistoryRecordCard;
    final manualCard =
        factory.buildHistoryCard(manualResult) as HistoryRecordCard;
    expect(timeCard.methodLabel, '时间起局');
    expect(manualCard.methodLabel, '手动校盘');
  });
}
