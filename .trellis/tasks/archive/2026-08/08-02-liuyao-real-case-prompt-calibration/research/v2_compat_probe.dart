import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/rules/liuyao_catalog.dart';

Future<void> main() async {
  final result = await LiuYaoSystem().castByManualYaoNumbers(
    const <int>[8, 8, 6, 7, 8, 6],
    castTime: DateTime(2026, 2, 28, 8),
  );
  final report = LiuYaoAnalyzer.analyze(
    result.mainGua,
    result.changingGua,
    result.lunarInfo,
    yongShenPosition: 1,
    ruleSetVersion: LiuYaoRuleCatalog.v2,
  );

  for (final tag in report.guaTags) {
    print('${tag.term}: ${tag.polarity.name}');
  }
  for (final effect in report.directedEffects.where(
    (effect) =>
        effect.fromActor.actorId == 'main:yao:3' &&
        effect.toActor.actorId == 'main:yao:1',
  )) {
    print('${effect.ruleId}: ${effect.status.name}');
  }
}
